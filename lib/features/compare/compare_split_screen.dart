import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../split/split_screen.dart' show SplitResult, loadSplit;
import '../split/split_view.dart';
import '../task_frame/engine_set.dart';
import '../task_frame/outcome_view.dart';
import '../tools/tool_entries.dart';
import 'agreement.dart';
import 'compare_layout.dart';

/// Compare for Split and analyse: the two engines' best splits side by side.
class CompareSplitScreen extends StatefulWidget {
  const CompareSplitScreen({super.key, required this.text});

  final SanskritText text;

  @override
  State<CompareSplitScreen> createState() => _CompareSplitScreenState();
}

class _CompareSplitScreenState extends State<CompareSplitScreen> {
  late final EngineSet _engines;
  late final List<EngineId> _ids;
  final Map<EngineId, Outcome<SplitResult>?> _outcomes = {};
  bool _ownLabels = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _engines = context.read<EngineSet>();
    _ids = _engines.forTask(Task.splitText);
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
    Outcome<SplitResult> result;
    try {
      result = await loadSplit(_engines[id]!, widget.text);
    } catch (e) {
      result = ServerFault('unexpected error: $e');
    }
    if (_disposed) return;
    setState(() => _outcomes[id] = result);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final left = _ids.isNotEmpty ? _ids[0] : EngineId.samsaadhanii;
    final right = _ids.length > 1 ? _ids[1] : EngineId.heritage;
    final lo = _outcomes[left], ro = _outcomes[right];

    String banner;
    String key;
    if (lo is Found<SplitResult> && ro is Found<SplitResult>) {
      final agree = splitsAgree(
          lo.value.main.candidates.first, ro.value.main.candidates.first);
      key = agree ? 'agree' : 'differ';
      banner = agree ? 'Both engines agree' : 'The engines differ';
    } else if (lo is NotFound<SplitResult> && ro is NotFound<SplitResult>) {
      key = 'agree';
      banner = 'Neither engine found a split';
    } else if (lo == null || ro == null) {
      key = 'partial';
      banner = 'Asking both engines…';
    } else {
      key = 'partial';
      banner = "Can't compare: not both engines gave a split";
    }

    Widget column(EngineId id) => OutcomeView<SplitResult>(
          outcome: _outcomes[id],
          engine: id,
          notFoundTitle: 'No split from ${engineNames[id]}',
          onRetry: () => _load(id),
          builder: (result, source) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SplitView(
                split: result.main.candidates.first,
                settings: settings,
                ownLabels: _ownLabels,
              ),
              const SizedBox(height: 8),
              CreditLine(source),
            ],
          ),
        );

    return CompareLayout(
      title: 'Compare: ${widget.text.display(settings.displayScript.script)}',
      banner: banner,
      bannerKey: key,
      leftTitle: engineNames[left]!,
      rightTitle: engineNames[right]!,
      left: column(left),
      right: column(right),
      ownLabels: _ownLabels,
      onOwnLabels: (v) => setState(() => _ownLabels = v),
    );
  }
}
