import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';
import 'feature_labels.dart';
import 'feature_tag.dart';

/// One analysis (`SCREENS.md` 5.1): the lemma large, a homonym number small
/// after it, the word class, the feature tags in the fixed display order, and
/// optional actions.
class AnalysisCard extends StatelessWidget {
  const AnalysisCard({
    super.key,
    required this.analysis,
    required this.settings,
    this.ownLabels = false,
    this.actions = const [],
  });

  final Analysis analysis;
  final AppSettings settings;
  final bool ownLabels;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final script = settings.displayScript.script;
    final features = orderedFeatures(analysis);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(TextSpan(children: [
              TextSpan(
                text: analysis.lemma.display(script),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              if (analysis.homonym != null)
                TextSpan(
                  text: ' ${analysis.homonym}',
                  style: theme.textTheme.bodySmall,
                ),
            ])),
            const SizedBox(height: 4),
            Text(
                wordClassLabel(analysis.wordClass,
                    language: settings.labelLanguage, display: script),
                style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    // Sanskrit text is never below 16 sp.
                    fontSize: settings.labelLanguage == LabelLanguage.sanskrit
                        ? 16
                        : null)),
            if (analysis.base != null) ...[
              const SizedBox(height: 2),
              Text('from ${analysis.base!.display(script)}',
                  style: const TextStyle(fontSize: 16)),
            ],
            if (features.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final f in features)
                    FeatureTag(
                      featureLabel(
                        f,
                        language: settings.labelLanguage,
                        display: script,
                        ownLabels: ownLabels,
                      ),
                      sanskrit: featureIsSanskrit(f,
                          language: settings.labelLanguage,
                          ownLabels: ownLabels),
                    ),
                ],
              ),
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
