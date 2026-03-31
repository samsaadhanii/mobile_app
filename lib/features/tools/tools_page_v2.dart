import 'package:flutter/material.dart';

import '../../core/models/tool_config.dart';
import '../../core/models/tool_registry.dart';
import 'screens/morph_analyser_screen.dart';

// Dispatches to the correct v2 screen for a given tool id.
// Add a new case here each time a new tool screen is ready.
void _navigateTo(BuildContext context, ToolConfig tool) {
  switch (tool.id) {
    case 'morph_analyser':
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MorphAnalyserScreen()),
      );
    default:
      debugPrint('navigate to ${tool.id} — screen not yet built');
  }
}

/// v2 tools listing page — groups all registered tools by category.
class ToolsPageV2 extends StatelessWidget {
  const ToolsPageV2({super.key});

  // Explicit ordering so categories always render in the same sequence.
  static const _orderedCategories = [
    ToolCategory.analysis,
    ToolCategory.generation,
    ToolCategory.reference,
  ];

  static const _categoryLabels = {
    ToolCategory.analysis: 'Analysis tools',
    ToolCategory.generation: 'Generation tools',
    ToolCategory.reference: 'Reference',
  };

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Samsaadhanii Tools'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final category in _orderedCategories) ...[
            _SectionHeader(label: _categoryLabels[category]!),
            for (final tool in ToolRegistry.byCategory(category))
              _ToolCard(tool: tool, isIOS: isIOS),
          ],
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
      ),
    );
  }
}

// ── Tool card ──────────────────────────────────────────────────────────────

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool, required this.isIOS});

  final ToolConfig tool;
  final bool isIOS;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        // InkWell inside Card so the ripple clips to the rounded corners.
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateTo(context, tool),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Name row: English (bold) + Sanskrit (smaller) ──
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Text(
                            tool.nameEn,
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            tool.nameSa,
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // ── Description ────────────────────────────────────
                      Text(
                        tool.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Platform-adaptive trailing icon.
                Icon(
                  isIOS
                      ? Icons.arrow_forward_ios_rounded
                      : Icons.chevron_right_rounded,
                  size: isIOS ? 16 : 22,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}