import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../analyse_word/feature_labels.dart';
import '../task_frame/engine_set.dart';
import '../task_frame/input_parsing.dart';
import '../task_frame/outcome_view.dart';
import '../task_frame/task_controller.dart';
import '../task_frame/task_frame.dart';
import '../tools/tool_entries.dart';
import '../tools/tools_list_page.dart';
import 'derivation_screen.dart';
import 'form_sheet.dart';
import 'paradigm_table.dart';

const _genders = [
  FeatureValue.masculine,
  FeatureValue.feminine,
  FeatureValue.neuter,
  FeatureValue.noGender,
];

const _categories = [
  FeatureValue.plainNoun,
  FeatureValue.sarvanama,
  FeatureValue.sankhya,
  FeatureValue.sankhyeya,
  FeatureValue.purana,
];

/// Noun forms (`SCREENS.md` 5.4): a stem, its gender and category, and the
/// table of its forms. Tapping a form offers its derivation. Reads only
/// domain types from the engine interface.
class NounFormsScreen extends StatefulWidget {
  const NounFormsScreen({
    super.key,
    this.initialInput = '',
    this.initialGender,
    this.onOpenTool,
  });

  /// The stem as typed on Home or passed by "All forms"; it is looked up at
  /// once.
  final String initialInput;

  /// The gender when the caller knows it (an analysis gave one).
  final FeatureValue? initialGender;

  /// Opens another tool ("Analyse this form").
  final OpenTool? onOpenTool;

  @override
  State<NounFormsScreen> createState() => _NounFormsScreenState();
}

class _NounFormsScreenState extends State<NounFormsScreen> {
  late final TextEditingController _text;
  late final EngineSet _engines;
  TaskController<NounParadigm>? _task;

  late FeatureValue _gender;
  FeatureValue _category = FeatureValue.plainNoun;
  SanskritText _stem = const SanskritText('');

  /// The stem as the user typed it, for messages (not converted).
  String _typed = '';

  @override
  void initState() {
    super.initState();
    _engines = context.read<EngineSet>();
    final settings = context.read<AppSettings>();
    _text = TextEditingController(text: firstWord(widget.initialInput));
    _gender = _genders.contains(widget.initialGender)
        ? widget.initialGender!
        : FeatureValue.masculine;
    final available = _engines.forTask(Task.nounForms);
    if (available.isEmpty) return;
    _task = TaskController<NounParadigm>(
      available: available,
      preferred: settings.preferredEngine,
      run: (id) => _engines[id]!.declineNoun(
          NounQuery(stem: _stem, gender: _gender, category: _category)),
    );
    if (_text.text.isNotEmpty) _submit();
  }

  @override
  void dispose() {
    _task?.dispose();
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final typed = firstWord(_text.text);
    if (typed.isEmpty) return;
    _typed = typed;
    _stem = parseSanskrit(typed, context.read<AppSettings>());
    _task?.request();
  }

  /// A new gender or category looks the stem up again, if there is one.
  void _changed() {
    setState(() {});
    if (!_stem.isEmpty) _task?.request();
  }

  void _showForm(FeatureValue vibhakti, FeatureValue number, SanskritText form) {
    final settings = context.read<AppSettings>();
    final onOpenTool = widget.onOpenTool;
    showFormSheet(
      context,
      form: form,
      vibhakti: vibhakti,
      number: number,
      settings: settings,
      onDerive: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => DerivationScreen(
          title: form.display(settings.displayScript.script),
          query: DerivationQuery(
            stem: _stem,
            gender: _gender,
            vibhakti: vibhakti,
            number: number,
          ),
        ),
      )),
      onAnalyse: onOpenTool == null
          ? null
          : () => onOpenTool(entryFor(Task.analyseWord),
              form.display(Script.devanagari)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final task = _task;
    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: Text(Task.nounForms.nameEn)),
        body: const Center(child: Text('No engine can do this yet.')),
      );
    }
    String label(FeatureValue v) => featureValueLabel(v,
        language: settings.labelLanguage, display: settings.displayScript.script);
    DropdownButtonFormField<FeatureValue> menu(
      String name,
      List<FeatureValue> values,
      FeatureValue current,
      ValueChanged<FeatureValue> onChanged,
    ) =>
        DropdownButtonFormField<FeatureValue>(
          initialValue: current,
          isExpanded: true,
          decoration: InputDecoration(labelText: name),
          items: [
            for (final v in values)
              DropdownMenuItem(
                value: v,
                child: Text(label(v), style: const TextStyle(fontSize: 16)),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        );

    return ListenableBuilder(
      listenable: task,
      builder: (context, _) {
        final outcome = task.outcome;
        return TaskFrame(
          title: Task.nounForms.nameEn,
          input: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      style: const TextStyle(fontSize: 18),
                      decoration:
                          const InputDecoration(hintText: 'A noun stem'),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Show forms',
                    icon: const Icon(Icons.search),
                    onPressed: _submit,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: menu('Gender', _genders, _gender, (v) {
                      _gender = v;
                      _changed();
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: menu('Category', _categories, _category, (v) {
                      _category = v;
                      _changed();
                    }),
                  ),
                ],
              ),
            ],
          ),
          engines: task.available,
          selected: task.engine,
          onEngineChanged: task.switchTo,
          source: outcome is Found<NounParadigm> ? outcome.source : null,
          result: _stem.isEmpty && outcome == null && !task.waiting
              ? const SizedBox.shrink()
              : OutcomeView<NounParadigm>(
                  outcome: outcome,
                  engine: task.engine,
                  notFoundTitle: 'No forms for $_typed',
                  onRetry: task.request,
                  other: task.other,
                  onTryOther: task.other == null
                      ? null
                      : () => task.switchTo(task.other!),
                  builder: (paradigm, source) => ParadigmTable(
                    paradigm: paradigm,
                    settings: settings,
                    onTapForm: _showForm,
                  ),
                ),
        );
      },
    );
  }
}
