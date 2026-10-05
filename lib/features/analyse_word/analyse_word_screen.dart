import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../compare/agreement.dart';
import '../compare/compare_analysis_screen.dart';
import '../task_frame/engine_set.dart';
import '../task_frame/input_parsing.dart';
import '../task_frame/outcome_view.dart';
import '../task_frame/task_controller.dart';
import '../task_frame/task_examples.dart';
import '../task_frame/task_frame.dart';
import '../tools/tool_entries.dart';
import '../tools/tools_list_page.dart';
import 'analysis_card.dart';

/// Analyse a word (`SCREENS.md` 5.1). Reads only domain types from the engine
/// interface.
class AnalyseWordScreen extends StatefulWidget {
  const AnalyseWordScreen({super.key, this.initialInput = '', this.onOpenTool});

  /// What the user typed on Home, if they came from there; it is analysed at
  /// once.
  final String initialInput;

  /// Opens another tool (All forms, Dictionary, Split).
  final OpenTool? onOpenTool;

  @override
  State<AnalyseWordScreen> createState() => _AnalyseWordScreenState();
}

class _AnalyseWordScreenState extends State<AnalyseWordScreen> {
  late final TextEditingController _text;
  TaskController<WordAnalysis>? _task;
  late final EngineSet _engines;
  SanskritText _word = const SanskritText('');

  /// Heritage's likeliest reading of the current word, once it has answered;
  /// null until then and when it has none. [_likelyFor] numbers the request so
  /// a late answer for an earlier word is dropped.
  Analysis? _likeliest;
  int _likelyFor = 0;

  /// The word as the user typed it, for messages (not converted).
  String _typed = '';

  @override
  void initState() {
    super.initState();
    _engines = context.read<EngineSet>();
    final settings = context.read<AppSettings>();
    _text = TextEditingController(text: firstWord(widget.initialInput));
    final available = _engines.forTask(Task.analyseWord);
    if (available.isEmpty) return;
    _task = TaskController<WordAnalysis>(
      available: available,
      preferred: settings.preferredEngine,
      run: (id) => _engines[id]!.analyseWord(_word),
    );
    _text.addListener(_onText);
    if (_text.text.isNotEmpty) _submit();
  }

  @override
  void dispose() {
    _task?.dispose();
    _text.dispose();
    super.dispose();
  }

  /// Clearing the input clears the result, and the examples come back.
  void _onText() {
    if (_text.text.trim().isNotEmpty) return;
    _word = const SanskritText('');
    _likelyFor++;
    _likeliest = null;
    _task?.reset();
  }

  void _submit() {
    final typed = firstWord(_text.text);
    if (typed.isEmpty) return;
    _typed = typed;
    _word = parseSanskrit(typed, context.read<AppSettings>());
    _task?.request();
    _loadLikeliest(_word);
  }

  /// Asks Heritage, whichever engine is selected, for the likeliest reading.
  /// It runs beside the main request and never holds it up; if Heritage does
  /// not answer, nothing is marked.
  Future<void> _loadLikeliest(SanskritText word) async {
    final mine = ++_likelyFor;
    _likeliest = null;
    final heritage = _engines[EngineId.heritage];
    if (heritage == null || !heritage.tasks.contains(Task.likeliestReading)) {
      return;
    }
    Outcome<Analysis> result;
    try {
      result = await heritage.likeliestReading(word);
    } catch (_) {
      return;
    }
    if (!mounted || mine != _likelyFor) return;
    final found = result;
    if (found is Found<Analysis>) setState(() => _likeliest = found.value);
  }

  void _open(Task task, String input,
      {FeatureValue? gender, String? prefix}) {
    widget.onOpenTool
        ?.call(entryFor(task), input, gender: gender, prefix: prefix);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final task = _task;
    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: Text(Task.analyseWord.nameEn)),
        body: const Center(child: Text('No engine can do this yet.')),
      );
    }
    return ListenableBuilder(
      listenable: Listenable.merge([task, _text]),
      builder: (context, _) {
        final outcome = task.outcome;
        return TaskFrame(
          title: Task.analyseWord.nameEn,
          input: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _text,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'One Sanskrit word',
                    suffixIcon: _text.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.close),
                            onPressed: _text.clear,
                          ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              IconButton(
                tooltip: 'Analyse',
                icon: const Icon(Icons.search),
                onPressed: _submit,
              ),
            ],
          ),
          examples: [
            for (final e in analyseExamples)
              TaskExample(exampleLabel(e.labelDev, e.note, settings), () {
                _text.text = e.words.first;
                _submit();
              }),
          ],
          showExamples:
              _text.text.trim().isEmpty && outcome == null && !task.waiting,
          engines: task.available,
          selected: task.engine,
          onEngineChanged: task.switchTo,
          source: outcome is Found<WordAnalysis> ? outcome.source : null,
          onCompare: _word.isEmpty
              ? null
              : () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => CompareAnalysisScreen(word: _word),
                  )),
          result: _word.isEmpty && outcome == null && !task.waiting
              ? const SizedBox.shrink()
              : OutcomeView<WordAnalysis>(
                  outcome: outcome,
                  engine: task.engine,
                  notFoundTitle: 'No analysis for $_typed',
                  onRetry: task.request,
                  other: task.other,
                  onTryOther: task.other == null
                      ? null
                      : () => task.switchTo(task.other!),
                  notFoundActions: [
                    if (widget.onOpenTool != null)
                      OutlinedButton(
                        onPressed: () => _open(Task.splitText, _text.text),
                        child: const Text('Split it as a phrase'),
                      ),
                  ],
                  builder: (analysis, source) {
                    // The card that agrees with Heritage's likeliest reading
                    // (the Compare rule) goes first and is tagged; the others
                    // keep the engine's order.
                    final list = analysis.analyses;
                    final likely = _likeliest;
                    final top = likely == null
                        ? -1
                        : list.indexWhere((a) => analysesAgree(a, likely));
                    final ordered = [
                      if (top >= 0) list[top],
                      for (var i = 0; i < list.length; i++)
                        if (i != top) list[i],
                    ];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final a in ordered)
                          AnalysisCard(
                            analysis: a,
                            settings: settings,
                            mostLikely: top >= 0 && identical(a, list[top]),
                            actions: _actions(a),
                          ),
                        if (top >= 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "Most likely reading according to Heritage's "
                              'frequency data.',
                              key: const Key('likeliest-note'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                            ),
                          ),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }

  /// The text "All forms" hands to the generator: the lemma for a noun; for
  /// a verb or a participle the root without its prefix (a prefixed analysis
  /// has the prefix in its lemma, `Af_gam`, and a participle's root is its
  /// base), so the generator can look the root up.
  String _formsInput(Analysis a) {
    var wx = switch (a.wordClass) {
      WordClass.participle => (a.base ?? a.lemma).wx,
      _ => a.lemma.wx,
    };
    final prefix = a.prefix?.wx;
    if (prefix != null && wx.startsWith('${prefix}_')) {
      wx = wx.substring(prefix.length + 1);
    }
    return SanskritText(wx).display(Script.devanagari);
  }

  /// The headword for the dictionary: the lemma, without the prefix of a
  /// prefixed verb (`Af_gam` is looked up as `gam`).
  String _dictionaryInput(Analysis a) {
    var wx = a.lemma.wx;
    final prefix = a.prefix?.wx;
    if (prefix != null && wx.startsWith('${prefix}_')) {
      wx = wx.substring(prefix.length + 1);
    }
    return SanskritText(wx).display(Script.devanagari);
  }

  List<Widget> _actions(Analysis a) {
    if (widget.onOpenTool == null) return const [];
    final lemma = a.lemma.display(Script.devanagari);
    final forms = switch (a.wordClass) {
      WordClass.noun => Task.nounForms,
      WordClass.verb => Task.verbForms,
      WordClass.participle => Task.krtForms,
      _ => null,
    };
    final gender = [
      for (final f in a.features)
        if (f.kind == FeatureKind.gender && f.value != FeatureValue.unknown)
          f.value,
    ].firstOrNull;
    return [
      if (forms != null)
        TextButton(
          onPressed: () => _open(forms, forms == Task.nounForms ? lemma : _formsInput(a),
              gender: gender, prefix: a.prefix?.wx),
          child: const Text('All forms'),
        ),
      TextButton(
        onPressed: () => _open(Task.dictionary, _dictionaryInput(a)),
        child: const Text('Dictionary'),
      ),
    ];
  }
}
