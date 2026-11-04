import 'package:flutter/material.dart' hide Split;

import '../../app/settings.dart';
import '../../app/word_class_colours.dart';
import '../../domain/domain.dart';
import '../analyse_word/feature_labels.dart';

/// One split as a row of tappable words (compound parts joined by a thin
/// hyphen), and under it, when the split carries analyses, one line per word.
class SplitView extends StatelessWidget {
  const SplitView({
    super.key,
    required this.split,
    required this.settings,
    this.onWordTap,
    this.withAnalyses = true,
    this.ownLabels = false,
  });

  final Split split;
  final AppSettings settings;

  /// Called with the tapped segment; null makes the words plain text.
  final ValueChanged<Segment>? onWordTap;
  final bool withAnalyses;
  final bool ownLabels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final script = settings.displayScript.script;
    final analyses = withAnalyses ? split.analyses : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final s in split.segments) ...[
              InkWell(
                onTap: onWordTap == null ? null : () => onWordTap!(s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Text(
                    s.text.display(script),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: onWordTap == null ? null : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              if (s.after == Boundary.compound)
                const Text('‐', style: TextStyle(fontSize: 20)),
            ],
          ],
        ),
        if (analyses != null)
          for (var i = 0; i < split.segments.length && i < analyses.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text.rich(TextSpan(children: [
                ..._square(context, analyses[i]),
                TextSpan(
                  text: split.segments[i].text.display(script),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const TextSpan(text: '  '),
                TextSpan(
                  text: _summary(analyses[i], script),
                  style: const TextStyle(fontSize: 16),
                ),
              ])),
            ),
      ],
    );
  }

  /// A small square in the colour of the word's class (its first reading, the
  /// one the line summarises) before the word; nothing for a class without one.
  List<InlineSpan> _square(BuildContext context, Outcome<WordAnalysis> slot) {
    if (slot is! Found<WordAnalysis> || slot.value.analyses.isEmpty) {
      return const [];
    }
    final mark = wordClassColour(
        slot.value.analyses.first.wordClass, Theme.of(context).colorScheme);
    if (mark == null) return const [];
    return [
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: SizedBox(
            width: 10,
            height: 10,
            child: ColoredBox(key: const Key('class-square'), color: mark),
          ),
        ),
      ),
    ];
  }

  String _summary(Outcome<WordAnalysis> slot, Script script) {
    switch (slot) {
      case Found<WordAnalysis>():
        final list = slot.value.analyses;
        if (list.isEmpty) return 'no analysis';
        final first = list.first;
        final parts = [
          wordClassLabel(first.wordClass,
              language: settings.labelLanguage, display: script),
          for (final f in orderedFeatures(first))
            featureLabel(f,
                language: settings.labelLanguage,
                display: script,
                ownLabels: ownLabels),
        ];
        final more = list.length > 1 ? ' (+${list.length - 1} more)' : '';
        return '${parts.join(' · ')}$more';
      case NotFound<WordAnalysis>():
        return 'no analysis';
      case Unreachable<WordAnalysis>():
        return "couldn't be analysed (no connection)";
      default:
        return "couldn't be analysed";
    }
  }
}
