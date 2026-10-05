import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../../shared/data/word_lists.dart';
import '../../shared/widgets/dhatu_picker.dart';
import '../../shared/widgets/form_sheet.dart';
import '../../shared/widgets/prefix_picker.dart';
import '../analyse_word/feature_labels.dart';
import '../task_frame/engine_set.dart';
import '../task_frame/input_parsing.dart';
import '../task_frame/outcome_view.dart';
import '../task_frame/task_controller.dart';
import '../task_frame/task_examples.dart';
import '../task_frame/task_frame.dart';
import '../tools/tool_entries.dart';
import '../tools/tools_list_page.dart';
import 'krt_group_view.dart';

/// Kṛt forms (`SCREENS.md` 5.4): a root and a prefix from their pickers and
/// the list of the root's kṛt suffixes with their forms. The engine's labels
/// for most suffixes are one place off against the forms (WEBSITE-TOOLS F12);
/// the engine layer corrects them and this screen says so. Reads only domain
/// types from the engine interface.
class KrtFormsScreen extends StatefulWidget {
  const KrtFormsScreen({
    super.key,
    this.initialInput = '',
    this.initialPrefix,
    this.onOpenTool,
  });

  /// A root typed on Home, passed by "All forms" or handed over by Verb forms
  /// (its exact key); it is turned into a dhātu of the list and looked up at
  /// once.
  final String initialInput;

  /// The prefix key when the caller knows it.
  final String? initialPrefix;

  /// Opens another tool ("Analyse this form", "All forms").
  final OpenTool? onOpenTool;

  @override
  State<KrtFormsScreen> createState() => _KrtFormsScreenState();
}

class _KrtFormsScreenState extends State<KrtFormsScreen> {
  late final EngineSet _engines;
  late final DhatuList _dhatus;
  TaskController<KrtForms>? _task;

  String? _root;
  late String? _prefix = widget.initialPrefix;

  /// What the user passed in when it is not a dhātu of the list.
  String? _unknownRoot;

  @override
  void initState() {
    super.initState();
    _engines = context.read<EngineSet>();
    _dhatus = context.read<DhatuList>();
    final available = _engines.forTask(Task.krtForms);
    if (available.isNotEmpty) {
      _task = TaskController<KrtForms>(
        available: available,
        preferred: context.read<AppSettings>().preferredEngine,
        run: (id) =>
            _engines[id]!.krtForms(VerbQuery(root: _root!, prefix: _prefix)),
      );
    }
    if (widget.initialInput.trim().isNotEmpty) {
      if (_dhatus.loaded) {
        _resolveInitial();
      } else {
        _dhatus.addListener(_onListLoaded);
      }
    }
  }

  void _onListLoaded() {
    if (!_dhatus.loaded) return;
    _dhatus.removeListener(_onListLoaded);
    if (mounted) setState(_resolveInitial);
  }

  void _resolveInitial() {
    final keys =
        rootKeysFor(widget.initialInput, _dhatus, context.read<AppSettings>());
    if (keys.isEmpty) {
      _unknownRoot = firstWord(widget.initialInput);
    } else {
      _root = keys.first;
      _task?.request();
    }
  }

  @override
  void dispose() {
    _dhatus.removeListener(_onListLoaded);
    _task?.dispose();
    super.dispose();
  }

  /// Puts the pickers back and clears the result, so the examples return.
  void _clear() {
    setState(() {
      _root = null;
      _prefix = null;
      _unknownRoot = null;
    });
    _task?.reset();
  }

  void _changed() {
    setState(() {});
    if (_root != null) _task?.request();
  }

  void _showForm(KrtGroup group, FeatureValue? gender, SanskritText form) {
    final settings = context.read<AppSettings>();
    final script = settings.displayScript.script;
    final onOpenTool = widget.onOpenTool;
    final description = [
      krtGroupTitle(group, settings),
      if (gender != null)
        featureValueLabel(gender,
            language: settings.labelLanguage, display: script),
    ].join(' · ');
    showFormSheet(
      context,
      form: form.display(script),
      description: description,
      actions: [
        if (onOpenTool != null)
          FormSheetAction(
            Icons.search,
            'Analyse this form',
            () => onOpenTool(
                entryFor(Task.analyseWord), form.display(Script.devanagari)),
          ),
        // A gendered form is a stem that can be declined.
        if (onOpenTool != null && gender != null)
          FormSheetAction(
            Icons.table_rows_outlined,
            'All forms',
            () => onOpenTool(
                entryFor(Task.nounForms), form.display(Script.devanagari),
                gender: gender),
          ),
      ],
    );
  }

  /// "Clear" under the pickers, while anything is chosen.
  Widget get _clearButton => _root == null &&
          _prefix == null &&
          _unknownRoot == null
      ? const SizedBox.shrink()
      : Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            key: const Key('clear-input'),
            onPressed: _clear,
            child: const Text('Clear'),
          ),
        );

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final task = _task;
    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: Text(Task.krtForms.nameEn)),
        body: const Center(child: Text('No engine can do this yet.')),
      );
    }

    return ListenableBuilder(
      listenable: task,
      builder: (context, _) {
        final outcome = task.outcome;
        final Widget result;
        if (_unknownRoot != null) {
          result = OutcomeView<KrtForms>(
            outcome: const NotFound(),
            engine: task.engine,
            notFoundTitle: 'No forms for $_unknownRoot',
            notFoundBody: 'Pick the root from the list.',
            onRetry: task.request,
            builder: (_, __) => const SizedBox.shrink(),
          );
        } else if (_root == null) {
          result = const SizedBox.shrink();
        } else {
          result = OutcomeView<KrtForms>(
            outcome: outcome,
            engine: task.engine,
            // The root is from the list, so all dashes means the engine has
            // nothing for this root with this prefix.
            notFoundTitle: _prefix == null
                ? '${engineNames[task.engine]} has no kṛt forms for this root.'
                : '${engineNames[task.engine]} has no kṛt forms for this root '
                    'with this prefix.',
            notFoundBody: '',
            onRetry: task.request,
            other: task.other,
            onTryOther:
                task.other == null ? null : () => task.switchTo(task.other!),
            builder: (krt, source) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final group in krt.groups)
                  KrtGroupView(
                    group: group,
                    settings: settings,
                    onTapForm: _showForm,
                  ),
                KrtLabelsNote(forms: krt, settings: settings),
              ],
            ),
          );
        }

        return TaskFrame(
          title: Task.krtForms.nameEn,
          input: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DhatuPicker(
                selectedWx: _root ?? '',
                onChanged: (key) {
                  _unknownRoot = null;
                  _root = key;
                  _changed();
                },
              ),
              const SizedBox(height: 12),
              PrefixPicker(
                selected: _prefix,
                onChanged: (key) {
                  _prefix = key;
                  _changed();
                },
              ),
              _clearButton,
            ],
          ),
          examples: [
            for (final e in krtExamples)
              TaskExample(exampleLabel(e.labelDev, e.note, settings), () {
                _unknownRoot = null;
                _root = e.root;
                _prefix = e.prefix;
                _changed();
              }),
          ],
          showExamples: _root == null &&
              _unknownRoot == null &&
              outcome == null &&
              !task.waiting,
          engines: task.available,
          selected: task.engine,
          onEngineChanged: task.switchTo,
          source: outcome is Found<KrtForms> && _unknownRoot == null
              ? outcome.source
              : null,
          result: result,
        );
      },
    );
  }
}
