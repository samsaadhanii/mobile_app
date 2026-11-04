import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import 'engine_marks.dart';
import 'tool_entries.dart';

/// Called when a row is tapped; a tool opens with an empty input. [gender] and
/// [prefix] (a prefix key) are passed when the caller knows them ("All forms"
/// on an analysis), for the tools that take them.
typedef OpenTool = void Function(ToolEntry entry, String input,
    {FeatureValue? gender, String? prefix});

/// The Tools tab (`SCREENS.md` section 3): three groups under their headings,
/// each a grid of two columns of compact cards, so all eight tools fit on one
/// phone screen at the default text size. A card is the English name, the
/// Sanskrit name under it and, at the bottom, the engines that can answer it as
/// quiet text; the whole card is the tap target. The page scrolls only when the
/// text is larger.
class ToolsListPage extends StatelessWidget {
  const ToolsListPage({super.key, required this.onOpen});

  final OpenTool onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tools')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        children: [
          for (final group in ToolGroup.values) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
              child: Text(
                group.label,
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ),
            ..._rows([
              for (final entry in toolEntries.where((e) => e.group == group))
                _ToolCard(entry: entry, onTap: () => onOpen(entry, '')),
            ]),
          ],
        ],
      ),
    );
  }

  /// Two cards to a row, as tall as the taller of the two.
  List<Widget> _rows(List<Widget> cards) => [
        for (var i = 0; i < cards.length; i += 2)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[i]),
                Expanded(
                    child: i + 1 < cards.length
                        ? cards[i + 1]
                        : const SizedBox.shrink()),
              ],
            ),
          ),
      ];
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.entry, required this.onTap});

  final ToolEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.nameEn,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500, height: 1.2)),
              // The Sanskrit name is a title: always Devanagari, whatever the
              // display script. Sanskrit text is never below 16 sp.
              Text(entry.nameSa,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      height: 1.25,
                      color: theme.colorScheme.onSurfaceVariant)),
              const Spacer(),
              if (entry.engines.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: EngineMarks(entry.engines, textAlign: TextAlign.start),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
