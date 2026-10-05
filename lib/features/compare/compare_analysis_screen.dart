import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../analyse_word/analysis_card.dart';
import '../task_frame/engine_set.dart';
import '../task_frame/outcome_view.dart';
import '../tools/tool_entries.dart';
import 'agreement.dart';
import 'compare_layout.dart';
import 'reading_table.dart';

/// Compare for Analyse a word: both engines are asked at once and shown side
/// by side, with a banner saying whether they agree.
class CompareAnalysisScreen extends StatefulWidget {
  const CompareAnalysisScreen({super.key, required this.word});

  final SanskritText word;

  @override
  State<CompareAnalysisScreen> createState() => _CompareAnalysisScreenState();
}

class _CompareAnalysisScreenState extends State<CompareAnalysisScreen> {
  late final EngineSet _engines;
  late final List<EngineId> _ids;
  final Map<EngineId, Outcome<WordAnalysis>?> _outcomes = {};
  bool _ownLabels = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _engines = context.read<EngineSet>();
    _ids = _engines.forTask(Task.analyseWord);
    for (final id in _ids) {
      _load(id);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _load(EngineId id) async {
    setState(() => _outcomes[id] = null);
    Outcome<WordAnalysis> result;
    try {
      result = await _engines[id]!.analyseWord(widget.word);
    } catch (e) {
      result = ServerFault('unexpected error: $e');
    }
    if (_disposed) return;
    setState(() => _outcomes[id] = result);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final leftId = _ids.isNotEmpty ? _ids[0] : EngineId.samsaadhanii;
    final rightId = _ids.length > 1 ? _ids[1] : EngineId.heritage;
    final lo = _outcomes[leftId], ro = _outcomes[rightId];

    String banner;
    String key;
    if (lo is Found<WordAnalysis> && ro is Found<WordAnalysis>) {
      final comparison = compareAnalyses(lo.value.analyses, ro.value.analyses);
      key = comparison.agree ? 'agree' : 'differ';
      banner = comparison.agree ? 'Both engines agree' : 'The engines differ';
    } else if (lo is NotFound<WordAnalysis> && ro is NotFound<WordAnalysis>) {
      key = 'agree';
      banner = 'Neither engine found an analysis';
    } else if (lo == null || ro == null) {
      key = 'partial';
      banner = 'Asking both engines…';
    } else {
      key = 'partial';
      banner = "Can't compare: not both engines gave an analysis";
    }

    /// One engine's readings as ordinary cards, with its state when it has no
    /// readings (waiting, not found, unreachable, with Retry).
    Widget section(EngineId id, {List<int>? only, String? title}) =>
        OutcomeView<WordAnalysis>(
          outcome: _outcomes[id],
          engine: id,
          notFoundTitle: 'No analysis from ${engineNames[id]}',
          onRetry: () => _load(id),
          builder: (analysis, source) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < analysis.analyses.length; i++)
                if (only == null || only.contains(i))
                  AnalysisCard(
                    analysis: analysis.analyses[i],
                    settings: settings,
                    ownLabels: _ownLabels,
                  ),
              if (only == null) CreditLine(source),
            ],
          ),
        );

    final theme = Theme.of(context);
    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(text, style: theme.textTheme.titleSmall),
        );

    final Widget body;
    if (lo is Found<WordAnalysis> && ro is Found<WordAnalysis>) {
      final left = lo.value.analyses, right = ro.value.analyses;
      final pairing = pairReadings(left, right);
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, j) in pairing.pairs)
            ReadingTable(
              left: left[i],
              right: right[j],
              leftEngine: leftId,
              rightEngine: rightId,
              settings: settings,
              ownLabels: _ownLabels,
            ),
          if (pairing.leftOnly.isNotEmpty) ...[
            heading('Only in ${engineNames[leftId]}'),
            for (final i in pairing.leftOnly)
              AnalysisCard(
                  analysis: left[i], settings: settings, ownLabels: _ownLabels),
          ],
          if (pairing.rightOnly.isNotEmpty) ...[
            heading('Only in ${engineNames[rightId]}'),
            for (final j in pairing.rightOnly)
              AnalysisCard(
                  analysis: right[j],
                  settings: settings,
                  ownLabels: _ownLabels),
          ],
          const SizedBox(height: 4),
          CreditLine(lo.source),
          const SizedBox(height: 4),
          CreditLine(ro.source),
        ],
      );
    } else {
      // No table without both answers: each engine's own state, as before.
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heading(engineNames[leftId]!),
          section(leftId),
          heading(engineNames[rightId]!),
          section(rightId),
        ],
      );
    }

    return CompareLayout(
      title: 'Compare: ${widget.word.display(settings.displayScript.script)}',
      banner: banner,
      bannerKey: key,
      body: body,
      ownLabels: _ownLabels,
      onOwnLabels: (v) => setState(() => _ownLabels = v),
    );
  }
}
