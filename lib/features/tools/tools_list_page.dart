import 'package:flutter/material.dart';

import 'engine_chips.dart';
import 'tool_entries.dart';

/// Called when a row is tapped; a tool opens with an empty input.
typedef OpenTool = void Function(ToolEntry entry, String input);

/// The Tools tab (`SCREENS.md` section 3): three groups, each row with its
/// English name, Sanskrit name under it, and the engine chips.
class ToolsListPage extends StatelessWidget {
  const ToolsListPage({super.key, required this.onOpen});

  final OpenTool onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tools')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final group in ToolGroup.values) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
              child: Text(
                group.label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            for (final entry in toolEntries.where((e) => e.group == group))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onOpen(entry, ''),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.nameEn,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          // Sanskrit text: never below 16 sp.
                          Text(entry.nameSa,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurfaceVariant)),
                          if (entry.engines.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            EngineChips(entry.engines),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
