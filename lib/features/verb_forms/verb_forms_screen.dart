import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../../sanskrit/transliteration.dart' show convert;
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
import 'verb_paradigm_view.dart';

/// Verb forms (`SCREENS.md` 5.4): a root and a prefix from their pickers, a
/// voice, and the tables of the root's forms. Reads only domain types from the
/// engine interface.
class VerbFormsScreen extends StatefulWidget {
  const VerbFormsScreen({
    super.key,
    this.initialInput = '',
    this.initialPrefix,
    this.onOpenTool,
  });

  /// A root typed on Home or passed by "All forms", as text; it is turned into
  /// a dhātu of the list and looked up at once.
  final String initialInput;

  /// The prefix key when the caller knows it ("All forms" on a prefixed
  /// analysis).
  final String? initialPrefix;

  /// Opens another tool ("Analyse this form", "Kṛt forms of this root").
  final OpenTool? onOpenTool;

  @override
  State<VerbFormsScreen> createState() => _VerbFormsScreenState();
}

class _VerbFormsScreenState extends State<VerbFormsScreen> {
  late final EngineSet _engines;
  late final DhatuList _dhatus;
  TaskController<VerbParadigm>? _task;

  /// The dhātu key, the prefix key (null for none) and the voice.
  String? _root;
  late String? _prefix = widget.initialPrefix;
  VerbPrayoga _prayoga = VerbPrayoga.kartari;

  /// What the user passed in when it is not a dhātu of the list.
  String? _unknownRoot;

  @override
  void initState() {
    super.initState();
    _engines = context.read<EngineSet>();
    _dhatus = context.read<DhatuList>();
    final available = _engines.forTask(Task.verbForms);
    if (available.isNotEmpty) {
      _task = TaskController<VerbParadigm>(
        available: available,
        preferred: context.read<AppSettings>().preferredEngine,
        run: (id) => _engines[id]!.conjugateVerb(
            VerbQuery(root: _root!, prefix: _prefix, prayoga: _prayoga)),
      );
    }
    if (widget.initialInput.trim().isNotEmpty) {
      if (_dhatus.loaded) {
        _resolveInitial();
      } else {
        // The list is still being read from its asset.
        _dhatus.addListener(_onListLoaded);
      }
    }
  }

  void _onListLoaded() {
    if (!_dhatus.loaded) return;
    _dhatus.removeListener(_onListLoaded);
    if (mounted) setState(_resolveInitial);
  }

  /// A typed root becomes the first matching dhātu of the list; one that is
  /// not in the list is reported, not guessed.
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

  /// A new root, prefix or voice looks the root up again.
  void _changed() {
    setState(() {});
    if (_root != null) _task?.request();
  }

  void _showForm(FeatureValue pada, FeatureValue lakara, FeatureValue person,
      FeatureValue number, SanskritText form) {
    final settings = context.read<AppSettings>();
    final script = settings.displayScript.script;
    final onOpenTool = widget.onOpenTool;
    String label(FeatureValue v) => featureValueLabel(v,
        language: settings.labelLanguage, display: script);
    showFormSheet(
      context,
      form: form.display(script),
      description: '${label(pada)} · ${label(lakara)} · ${label(person)} · '
          '${label(number)}',
      actions: [
        if (onOpenTool != null)
          FormSheetAction(
            Icons.search,
            'Analyse this form',
            () => onOpenTool(
                entryFor(Task.analyseWord), form.display(Script.devanagari)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final task = _task;
    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: Text(Task.verbForms.nameEn)),
        body: const Center(child: Text('No engine can do this yet.')),
      );
    }
    final script = settings.displayScript.script;
    String prayogaLabel(VerbPrayoga p) => settings.labelLanguage ==
            LabelLanguage.sanskrit
        ? convert(p.iast, Script.iast, script)
        : p.english;

    return ListenableBuilder(
      listenable: task,
      builder: (context, _) {
        final outcome = task.outcome;
        final onOpenTool = widget.onOpenTool;
        final Widget result;
        if (_unknownRoot != null) {
          // The root was passed in as text and is not in the list.
          result = OutcomeView<VerbParadigm>(
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
          result = OutcomeView<VerbParadigm>(
            outcome: outcome,
            engine: task.engine,
            // The root is from the list, so an all-dash answer means the
            // engine has nothing for this root with this prefix (F13).
            notFoundTitle: _prefix == null
                ? '${engineNames[task.engine]} has no forms for this root.'
                : '${engineNames[task.engine]} has no forms for this root '
                    'with this prefix.',
            notFoundBody: '',
            onRetry: task.request,
            other: task.other,
            onTryOther:
                task.other == null ? null : () => task.switchTo(task.other!),
            builder: (paradigm, source) => VerbParadigmView(
              paradigm: paradigm,
              settings: settings,
              onTapForm: _showForm,
              onKrt: onOpenTool == null
                  ? null
                  : () => onOpenTool(entryFor(Task.krtForms), _root ?? '',
                      prefix: _prefix),
            ),
          );
        }

        return TaskFrame(
          title: Task.verbForms.nameEn,
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
              const SizedBox(height: 12),
              SegmentedButton<VerbPrayoga>(
                key: const Key('prayoga-switch'),
                segments: [
                  for (final p in VerbPrayoga.values)
                    ButtonSegment(value: p, label: Text(prayogaLabel(p))),
                ],
                selected: {_prayoga},
                onSelectionChanged: (s) {
                  _prayoga = s.first;
                  _changed();
                },
              ),
            ],
          ),
          examples: [
            for (final e in verbExamples)
              TaskExample(exampleLabel(e.labelDev, e.note, settings), () {
                _unknownRoot = null;
                _root = e.root;
                _prefix = e.prefix;
                _prayoga = e.prayoga;
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
          source: outcome is Found<VerbParadigm> && _unknownRoot == null
              ? outcome.source
              : null,
          result: result,
        );
      },
    );
  }
}
