import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../../shared/widgets/form_sheet.dart';
import '../task_frame/engine_set.dart';
import '../task_frame/input_parsing.dart';
import '../task_frame/outcome_view.dart';
import '../task_frame/task_controller.dart';
import '../task_frame/task_frame.dart';
import '../tools/tool_entries.dart';
import '../tools/tools_list_page.dart';
import 'sandhi_option_view.dart';

/// Join words (`SCREENS.md` 5.4): two words, a learner level, and the ways they
/// can join. Reads only domain types from the engine interface.
class JoinWordsScreen extends StatefulWidget {
  const JoinWordsScreen({super.key, this.initialInput = '', this.onOpenTool});

  /// What was typed on Home. Exactly two words fill both fields and are joined
  /// at once; one word fills the first.
  final String initialInput;

  /// Opens another tool ("Analyse this form", "Split it again").
  final OpenTool? onOpenTool;

  @override
  State<JoinWordsScreen> createState() => _JoinWordsScreenState();
}

class _JoinWordsScreenState extends State<JoinWordsScreen> {
  final _first = TextEditingController();
  final _second = TextEditingController();
  late final EngineSet _engines;
  TaskController<SandhiResult>? _task;

  SanskritText _left = const SanskritText('');
  SanskritText _right = const SanskritText('');

  /// The words as typed, for messages (not converted).
  String _typedLeft = '';
  String _typedRight = '';

  bool _submitted = false;
  bool _spelling = false;

  @override
  void initState() {
    super.initState();
    _engines = context.read<EngineSet>();
    final words = widget.initialInput.trim().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.isNotEmpty) _first.text = words[0];
    if (words.length == 2) _second.text = words[1];
    final available = _engines.forTask(Task.joinWords);
    if (available.isNotEmpty) {
      _task = TaskController<SandhiResult>(
        available: available,
        preferred: context.read<AppSettings>().preferredEngine,
        run: (id) => _engines[id]!.joinSandhi(_left, _right),
      );
    }
    if (words.length == 2) _submit();
  }

  @override
  void dispose() {
    _task?.dispose();
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  /// An empty word is sent too: the engine answers `BadInput` ("Enter two
  /// words") without a request, and the screen says so.
  void _submit() {
    final settings = context.read<AppSettings>();
    _typedLeft = _first.text.trim();
    _typedRight = _second.text.trim();
    _left = parseSanskrit(_typedLeft, settings);
    _right = parseSanskrit(_typedRight, settings);
    setState(() => _submitted = true);
    _task?.request();
  }

  void _showJoined(SandhiOption option) {
    final settings = context.read<AppSettings>();
    final script = settings.displayScript.script;
    final onOpenTool = widget.onOpenTool;
    final joined = option.joined.display(Script.devanagari);
    showFormSheet(
      context,
      form: option.joined.display(script),
      description:
          '${_left.display(script)} + ${_right.display(script)}',
      actions: [
        // Analyse a word takes one word: a joined form that stayed in two
        // (`rāma ālayaḥ`) is for Split and analyse.
        if (onOpenTool != null && !option.joined.wx.contains(' '))
          FormSheetAction(Icons.search, 'Analyse this form',
              () => onOpenTool(entryFor(Task.analyseWord), joined)),
        if (onOpenTool != null)
          FormSheetAction(Icons.call_split, 'Split it again',
              () => onOpenTool(entryFor(Task.splitText), joined)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final task = _task;
    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: Text(Task.joinWords.nameEn)),
        body: const Center(child: Text('No engine can do this yet.')),
      );
    }

    return ListenableBuilder(
      listenable: task,
      builder: (context, _) {
        final outcome = task.outcome;
        return TaskFrame(
          title: Task.joinWords.nameEn,
          input: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _first,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(hintText: 'First word'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _second,
                      style: const TextStyle(fontSize: 18),
                      decoration:
                          const InputDecoration(hintText: 'Second word'),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Join',
                    icon: const Icon(Icons.search),
                    onPressed: _submit,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Learner level',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              SegmentedButton<LearnerLevel>(
                key: const Key('level-switch'),
                segments: [
                  for (final l in LearnerLevel.values)
                    ButtonSegment(value: l, label: Text(l.label)),
                ],
                selected: {settings.learnerLevel},
                onSelectionChanged: (s) => settings.setLearnerLevel(s.first),
              ),
            ],
          ),
          engines: task.available,
          selected: task.engine,
          onEngineChanged: task.switchTo,
          source: outcome is Found<SandhiResult> ? outcome.source : null,
          result: !_submitted
              ? const SizedBox.shrink()
              : OutcomeView<SandhiResult>(
                  outcome: outcome,
                  engine: task.engine,
                  notFoundTitle: 'No sandhi forms for $_typedLeft + $_typedRight',
                  onRetry: task.request,
                  other: task.other,
                  onTryOther: task.other == null
                      ? null
                      : () => task.switchTo(task.other!),
                  builder: (result, source) {
                    final many = result.options.length > 1;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (many)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('${result.options.length} ways to join',
                                key: const Key('sandhi-count'),
                                style:
                                    Theme.of(context).textTheme.titleMedium),
                          ),
                        SwitchListTile(
                          key: const Key('spelling-switch'),
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Show spelling'),
                          value: _spelling,
                          onChanged: (v) => setState(() => _spelling = v),
                        ),
                        for (var i = 0; i < result.options.length; i++)
                          KeyedSubtree(
                            key: Key('sandhi-option-$i'),
                            child: SandhiOptionView(
                              result: result,
                              option: result.options[i],
                              level: settings.learnerLevel,
                              showSpelling: _spelling,
                              settings: settings,
                              label: many ? 'Way ${i + 1}' : null,
                              onTapJoined: () => _showJoined(result.options[i]),
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
}
