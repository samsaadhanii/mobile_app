import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import 'tool_entries.dart';

/// The engines that can answer a row, as quiet text ("Samsaadhanii ·
/// Heritage"): no outline, no fill, so it cannot be taken for a button.
class EngineMarks extends StatelessWidget {
  const EngineMarks(this.engines, {super.key, this.textAlign = TextAlign.end});

  final Set<EngineId> engines;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      [
        for (final e in EngineId.values)
          if (engines.contains(e)) engineNames[e]!,
      ].join(' · '),
      textAlign: textAlign,
      style: theme.textTheme.labelSmall
          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    );
  }
}
