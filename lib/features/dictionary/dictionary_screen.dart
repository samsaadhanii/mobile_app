import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../task_frame/engine_set.dart';
import '../task_frame/input_parsing.dart';
import '../task_frame/outcome_view.dart';
import '../task_frame/task_controller.dart';
import '../task_frame/task_examples.dart';
import '../task_frame/task_frame.dart';
import 'dictionary_section.dart';

/// "Apte", "Apte and Heritage", "Apte, Heritage and Cappeller".
String namesList(List<String> names) {
  if (names.length < 2) return names.join();
  return '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
}

/// Dictionary (`SCREENS.md` 5.4): one word looked up in every dictionary that
/// has it, a section for each. Reads only domain types from the engine
/// interface.
class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key, this.initialInput = ''});

  /// The word passed from Home, an analysis card or a table; it is looked up at
  /// once.
  final String initialInput;

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  late final TextEditingController _text;
  late final EngineSet _engines;
  TaskController<List<DictionaryEntry>>? _task;

  SanskritText _word = const SanskritText('');

  /// The word as the user typed it, for messages (not converted).
  String _typed = '';

  @override
  void initState() {
    super.initState();
    _engines = context.read<EngineSet>();
    _text = TextEditingController(text: firstWord(widget.initialInput));
    final available = _engines.forTask(Task.dictionary);
    if (available.isNotEmpty) {
      _task = TaskController<List<DictionaryEntry>>(
        available: available,
        preferred: context.read<AppSettings>().preferredEngine,
        run: (id) => _engines[id]!.lookUp(_word),
      );
      _text.addListener(_onText);
      if (_text.text.isNotEmpty) _submit();
    }
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
    _task?.reset();
  }

  void _submit() {
    final typed = firstWord(_text.text);
    if (typed.isEmpty) return;
    _typed = typed;
    _word = parseSanskrit(typed, context.read<AppSettings>());
    _task?.request();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final theme = Theme.of(context);
    final task = _task;
    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: Text(Task.dictionary.nameEn)),
        body: const Center(child: Text('No engine can do this yet.')),
      );
    }

    return ListenableBuilder(
      listenable: Listenable.merge([task, _text]),
      builder: (context, _) {
        final outcome = task.outcome;
        return TaskFrame(
          title: Task.dictionary.nameEn,
          input: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _text,
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(hintText: 'One Sanskrit word'),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              IconButton(
                tooltip: 'Look up',
                icon: const Icon(Icons.search),
                onPressed: _submit,
              ),
            ],
          ),
          examples: [
            for (final e in dictionaryExamples)
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
          source: outcome is Found<List<DictionaryEntry>> ? outcome.source : null,
          result: _word.isEmpty && outcome == null && !task.waiting
              ? const SizedBox.shrink()
              : OutcomeView<List<DictionaryEntry>>(
                  outcome: outcome,
                  engine: task.engine,
                  notFoundTitle: 'No entry for $_typed',
                  onRetry: task.request,
                  other: task.other,
                  onTryOther: task.other == null
                      ? null
                      : () => task.switchTo(task.other!),
                  builder: (entries, source) {
                    final missing = missingDictionaries(entries);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            entries.first.headword
                                .display(settings.displayScript.script),
                            key: const Key('dict-headword'),
                            style: const TextStyle(
                                fontSize: 28, fontWeight: FontWeight.w600),
                          ),
                        ),
                        for (final e in entries) DictionarySection(entry: e),
                        if (missing.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'No entry in ${namesList([for (final d in missing) d.name])}.',
                              key: const Key('dict-missing'),
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
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
