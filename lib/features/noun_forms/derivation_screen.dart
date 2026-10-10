import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../task_frame/engine_set.dart';
import '../task_frame/outcome_view.dart';
import '../task_frame/task_controller.dart';
import '../tools/tool_entries.dart' show engineNames;

/// How a form is derived (`SCREENS.md` 5.4): the form as the title, then the
/// rules in order. The engine's text is shown exactly as sent, in Devanagari,
/// whatever the display script (the state lines mix Sanskrit with Latin
/// markers, so they are never converted); a note says so when the display
/// script is not Devanagari.
class DerivationScreen extends StatefulWidget {
  const DerivationScreen({super.key, required this.query, required this.title});

  final DerivationQuery query;

  /// The form the user tapped, in the display script.
  final String title;

  @override
  State<DerivationScreen> createState() => _DerivationScreenState();
}

class _DerivationScreenState extends State<DerivationScreen> {
  TaskController<Derivation>? _task;

  @override
  void initState() {
    super.initState();
    final engines = context.read<EngineSet>();
    final available = engines.forTask(Task.derivation);
    if (available.isEmpty) return;
    _task = TaskController<Derivation>(
      available: available,
      preferred: context.read<AppSettings>().preferredEngine,
      run: (id) => engines[id]!.derive(widget.query),
    )..request();
  }

  @override
  void dispose() {
    _task?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final task = _task;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: task == null
          ? const Center(child: Text('No engine can do this yet.'))
          : ListenableBuilder(
              listenable: task,
              builder: (context, _) {
                final outcome = task.outcome;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (settings.displayScript.script != Script.devanagari)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Shown in Devanagari as Samsaadhanii provides it.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                    OutcomeView<Derivation>(
                      outcome: outcome,
                      engine: task.engine,
                      // The form came from a found table, so the spelling hint
                      // does not apply: the engine just has nothing for it.
                      notFoundTitle:
                          '${engineNames[task.engine]} has no derivation for '
                          'this form.',
                      notFoundBody: '',
                      onRetry: task.retry,
                      builder: (derivation, source) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < derivation.steps.length; i++)
                            _StepTile(number: i + 1, step: derivation.steps[i]),
                          const SizedBox(height: 12),
                          CreditLine(source),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.number, required this.step});

  final int number;
  final DerivationStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    // Sanskrit text is never smaller than 16 sp: the state lines are set
    // apart by colour and indent, not by size.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Text('$number.',
                style: theme.textTheme.titleSmall?.copyWith(color: muted)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(TextSpan(children: [
                  TextSpan(
                    text: step.sutra,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: '  ${step.sutraText}'),
                ]), style: const TextStyle(fontSize: 18)),
                if (step.label.isNotEmpty)
                  Text(step.label,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary)),
                if (step.considered.isNotEmpty)
                  _Considered(step.considered),
                for (final line in step.state)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 8),
                    child: Text(line,
                        softWrap: true,
                        style: TextStyle(fontSize: 16, color: muted)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "3 rules considered", folded.
class _Considered extends StatelessWidget {
  const _Considered(this.rules);

  final List<ConsideredRule> rules;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final n = rules.length;
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 8, bottom: 4),
        dense: true,
        visualDensity: VisualDensity.compact,
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: Text(n == 1 ? '1 rule considered' : '$n rules considered',
            style: theme.textTheme.labelLarge?.copyWith(color: muted)),
        children: [
          for (final r in rules)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('${r.sutra}  ${r.sutraText}',
                  style: TextStyle(fontSize: 16, color: muted)),
            ),
        ],
      ),
    );
  }
}
