import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import 'engine_marks.dart';
import 'tool_entries.dart';

/// Called when a row is tapped; a tool opens with an empty input. [gender] and
/// [prefix] (a prefix key) are passed when the caller knows them ("All forms"
/// on an analysis), for the tools that take them.
typedef OpenTool = void Function(ToolEntry entry, String input,
    {FeatureValue? gender, String? prefix});

/// The Tools tab (`SCREENS.md` section 3): three groups of compact rows with
/// hairline dividers, so all eight tools fit on one phone screen. Each row is
/// the English name, the Sanskrit name under it, and the engines that can
/// answer it as quiet text at the right.
class ToolsListPage extends StatelessWidget {
  const ToolsListPage({super.key, required this.onOpen});

  final OpenTool onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tools')),
      body: ListView(
        children: [
          for (final group in ToolGroup.values) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
              child: Text(
                group.label,
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ),
            for (final entry in toolEntries.where((e) => e.group == group)) ...[
              const Divider(height: 1, thickness: 0.5),
              _ToolRow(entry: entry, onTap: () => onOpen(entry, '')),
            ],
            const Divider(height: 1, thickness: 0.5),
          ],
        ],
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({required this.entry, required this.onTap});

  final ToolEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.nameEn,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500, height: 1.2)),
                  // The Sanskrit name is a title: always Devanagari, whatever
                  // the display script. Sanskrit text is never below 16 sp.
                  Text(entry.nameSa,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          height: 1.25,
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (entry.engines.isNotEmpty) ...[
              const SizedBox(width: 12),
              EngineMarks(entry.engines),
            ],
          ],
        ),
      ),
    );
  }
}
