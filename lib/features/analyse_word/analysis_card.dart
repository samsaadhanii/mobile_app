import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';
import 'feature_labels.dart';

/// One analysis (`SCREENS.md` 5.1): the lemma large, a homonym number small
/// after it, the word-class tag, feature chips, and optional actions.
/// [compact] is the smaller style of the Compare columns; [mismatch] marks a
/// card with no agreeing partner on the other side.
class AnalysisCard extends StatelessWidget {
  const AnalysisCard({
    super.key,
    required this.analysis,
    required this.settings,
    this.compact = false,
    this.ownLabels = false,
    this.mismatch = false,
    this.actions = const [],
  });

  final Analysis analysis;
  final AppSettings settings;
  final bool compact;
  final bool ownLabels;
  final bool mismatch;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final script = settings.displayScript.script;
    // Sanskrit text is never smaller than 16 sp.
    final lemmaSize = compact ? 18.0 : 24.0;

    return Card(
      shape: mismatch
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.error, width: 1.5),
            )
          : null,
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(TextSpan(children: [
              TextSpan(
                text: analysis.lemma.display(script),
                style: TextStyle(fontSize: lemmaSize, fontWeight: FontWeight.w600),
              ),
              if (analysis.homonym != null)
                TextSpan(
                  text: ' ${analysis.homonym}',
                  style: theme.textTheme.bodySmall,
                ),
            ])),
            const SizedBox(height: 4),
            Text(wordClassLabel(analysis.wordClass),
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: theme.colorScheme.primary)),
            if (analysis.base != null) ...[
              const SizedBox(height: 2),
              Text('from ${analysis.base!.display(script)}',
                  style: const TextStyle(fontSize: 16)),
            ],
            if (analysis.features.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final f in analysis.features)
                    Chip(
                      label: Text(featureLabel(
                        f,
                        language: settings.labelLanguage,
                        display: script,
                        ownLabels: ownLabels,
                      )),
                      visualDensity: VisualDensity.compact,
                      labelStyle: const TextStyle(fontSize: 16),
                    ),
                ],
              ),
            ],
            if (mismatch) ...[
              const SizedBox(height: 6),
              Text('No match in the other engine',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.error)),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}
