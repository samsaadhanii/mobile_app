import 'package:flutter/material.dart';

import '../../app/engine_identity.dart';
import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../analyse_word/feature_labels.dart';
import '../tools/tool_entries.dart';
import 'agreement.dart';

/// One reading the two engines share (`SCREENS.md` 5.3): the lemma and word
/// class as the heading, then a table with a row per feature kind in the
/// display order and a column per engine. A kind only one engine reports
/// shows a muted dash in the other column; a row where they differ is tinted
/// and its two values take the engines' colours. Values wrap inside their
/// cell, so it fits a 360 dp screen.
class ReadingTable extends StatelessWidget {
  const ReadingTable({
    super.key,
    required this.left,
    required this.right,
    required this.leftEngine,
    required this.rightEngine,
    required this.settings,
    this.ownLabels = false,
  });

  final Analysis left;
  final Analysis right;
  final EngineId leftEngine;
  final EngineId rightEngine;
  final AppSettings settings;
  final bool ownLabels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final script = settings.displayScript.script;
    final language = settings.labelLanguage;
    final sanskrit = language == LabelLanguage.sanskrit;
    final differing = differingKinds(left, right);
    final colors = {
      leftEngine: samsaadhaniiColor(scheme),
      rightEngine: heritageColor(scheme),
    };
    // Sanskrit text is never below 16 sp.
    final size = sanskrit || ownLabels ? 16.0 : 14.0;

    final kinds = kindsInOrder(left.wordClass, [
      for (final f in orderedFeatures(left)) f.kind,
      for (final f in orderedFeatures(right)) f.kind,
    ]);

    String values(Analysis a, FeatureKind kind) => [
          for (final f in a.features)
            if (f.kind == kind)
              featureLabel(f,
                  language: language, display: script, ownLabels: ownLabels),
        ].join(' / ');

    Widget cell(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: child);

    Widget value(String text, EngineId engine, bool marked) {
      if (text.isEmpty) {
        return cell(Text('–',
            key: const Key('no-value'),
            style: TextStyle(
                fontSize: size, color: scheme.onSurfaceVariant)));
      }
      return cell(Text(text,
          style: TextStyle(
              fontSize: size,
              fontWeight: marked ? FontWeight.w600 : null,
              color: marked ? colors[engine] : null)));
    }

    final classes = {left.wordClass, right.wordClass};
    final heading = [
      for (final c in classes)
        wordClassLabel(c, language: language, display: script),
    ].join(' / ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(TextSpan(children: [
              TextSpan(
                text: left.lemma.display(script),
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              if (left.homonym != null)
                TextSpan(
                    text: ' ${left.homonym}', style: theme.textTheme.bodySmall),
            ])),
            Text(heading,
                style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.primary, fontSize: sanskrit ? 16 : null)),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(3),
                2: FlexColumnWidth(3),
              },
              children: [
                TableRow(children: [
                  const SizedBox.shrink(),
                  for (final e in [leftEngine, rightEngine])
                    cell(Text(engineNames[e]!,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: colors[e]))),
                ]),
                for (final kind in kinds)
                  TableRow(
                    key: ValueKey('row-${kind.name}'),
                    decoration: differing.contains(kind)
                        ? BoxDecoration(
                            color: scheme.errorContainer.withValues(alpha: .4))
                        : null,
                    children: [
                      cell(Text(
                          featureKindLabel(kind,
                              language: language, display: script),
                          style: TextStyle(
                              fontSize: size,
                              color: scheme.onSurfaceVariant))),
                      value(values(left, kind), leftEngine,
                          differing.contains(kind)),
                      value(values(right, kind), rightEngine,
                          differing.contains(kind)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
