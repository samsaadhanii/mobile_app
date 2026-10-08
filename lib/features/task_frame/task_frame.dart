import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../tools/tool_entries.dart';
import 'outcome_view.dart';
import 'task_examples.dart';

/// The frame every task screen shares (`SCREENS.md` section 4): top bar with
/// the task name, the input, the engine switch (only when more than one
/// engine can answer), the result, the credit line under a found result, and
/// the Compare button.
class TaskFrame extends StatelessWidget {
  const TaskFrame({
    super.key,
    required this.title,
    required this.input,
    required this.engines,
    required this.selected,
    required this.onEngineChanged,
    required this.result,
    this.source,
    this.onCompare,
    this.examples = const [],
    this.showExamples = false,
  });

  final String title;

  /// The task's own input fields.
  final Widget input;

  /// The engines that can answer this task; the switch shows only for two or
  /// more.
  final List<EngineId> engines;
  final EngineId selected;
  final ValueChanged<EngineId> onEngineChanged;

  /// The result area: an `OutcomeView`.
  final Widget result;

  /// Set when the result is a found one: gives the credit line and the
  /// Compare button.
  final ResultSource? source;

  /// Opens Compare; the button shows only if another engine can answer.
  final VoidCallback? onCompare;

  /// What to try, and whether to show it: the screen shows them while it has
  /// no result and nothing typed.
  final List<TaskExample> examples;
  final bool showExamples;

  @override
  Widget build(BuildContext context) {
    final others = engines.where((e) => e != selected).toList();
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        children: [
          input,
          if (showExamples && examples.isNotEmpty)
            ExamplesRow(examples: examples),
          if (engines.length > 1) ...[
            const SizedBox(height: 12),
            SegmentedButton<EngineId>(
              key: const Key('engine-switch'),
              segments: [
                for (final e in engines)
                  ButtonSegment(value: e, label: Text(engineNames[e]!)),
              ],
              selected: {selected},
              onSelectionChanged: (s) => onEngineChanged(s.first),
            ),
          ],
          const SizedBox(height: 8),
          result,
          if (source != null) ...[
            const SizedBox(height: 12),
            CreditLine(source!),
            if (onCompare != null && others.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: const Key('compare-button'),
                  icon: const Icon(Icons.compare_arrows),
                  label: Text('Compare with ${engineNames[others.first]!}'),
                  onPressed: onCompare,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
