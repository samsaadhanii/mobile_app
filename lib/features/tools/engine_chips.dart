import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import 'tool_entries.dart';

/// The small chips naming the engines that can answer a row.
class EngineChips extends StatelessWidget {
  const EngineChips(this.engines, {super.key});

  final Set<EngineId> engines;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final e in EngineId.values)
          if (engines.contains(e))
            Chip(
              label: Text(engineNames[e]!),
              visualDensity: VisualDensity.compact,
              labelStyle: Theme.of(context).textTheme.labelSmall,
              padding: EdgeInsets.zero,
            ),
      ],
    );
  }
}
