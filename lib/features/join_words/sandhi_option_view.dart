import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';

/// One way to join two words, at a learner level (`SCREENS.md` 5.4):
///
/// - **Basic:** the two words, the letters that meet drawn large
///   (`ḥ + ā → ā`), and the joined form; "Show spelling" adds the two words
///   spelt out letter by letter.
/// - **Intermediate:** adds the name of the sandhi, its steps joined by arrows.
/// - **Advanced:** adds each sūtra with its number, or says that the engine
///   gives none for this way.
///
/// Every Sanskrit text is in the display script and never below 16 sp.
class SandhiOptionView extends StatelessWidget {
  const SandhiOptionView({
    super.key,
    required this.result,
    required this.option,
    required this.level,
    required this.showSpelling,
    required this.settings,
    required this.onTapJoined,
    this.label,
  });

  final SandhiResult result;
  final SandhiOption option;
  final LearnerLevel level;
  final bool showSpelling;
  final AppSettings settings;
  final VoidCallback onTapJoined;

  /// "Way 2", when there is more than one.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final script = settings.displayScript.script;
    final muted = theme.colorScheme.onSurfaceVariant;
    String d(SanskritText t) => t.display(script);
    const sanskrit = TextStyle(fontSize: 16);

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 2),
          child: Text(text,
              style: theme.textTheme.labelLarge?.copyWith(color: muted)),
        );

    Widget word(SanskritText w) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(d(w),
              style: TextStyle(
                  fontSize: 18, color: theme.colorScheme.onSecondaryContainer)),
        );

    String spelled(List<SanskritText> letters) => letters.map(d).join(' ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(label!,
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: theme.colorScheme.primary)),
              ),
            // The two words.
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                word(result.left),
                Text('+', style: TextStyle(fontSize: 18, color: muted)),
                word(result.right),
              ],
            ),
            if (showSpelling) ...[
              const SizedBox(height: 10),
              Text(spelled(option.leftLetters),
                  key: const Key('sandhi-spelling-left'),
                  style: sanskrit.copyWith(color: muted)),
              Text(spelled(option.rightLetters),
                  key: const Key('sandhi-spelling-right'),
                  style: sanskrit.copyWith(color: muted)),
            ],
            // The letters that meet, large.
            const SizedBox(height: 12),
            Text(
              '${d(option.lastLetter)} + ${d(option.firstLetter)}  →  '
              '${d(option.modifiedLetter)}',
              key: const Key('sandhi-letters'),
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary),
            ),
            // The joined form.
            heading('Joined'),
            InkWell(
              key: const Key('sandhi-joined'),
              onTap: onTapJoined,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(d(option.joined),
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w600)),
              ),
            ),
            if (level != LearnerLevel.basic && option.steps.isNotEmpty) ...[
              heading('Sandhi'),
              Text(option.steps.map(d).join('  →  '),
                  key: const Key('sandhi-steps'), style: sanskrit),
            ],
            if (level == LearnerLevel.advanced && option.sutras.isEmpty) ...[
              heading('Sūtras'),
              Text('Samsaadhanii gives no sūtra for this way.',
                  key: const Key('sandhi-no-sutra'),
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted)),
            ],
            if (level == LearnerLevel.advanced && option.sutras.isNotEmpty) ...[
              heading('Sūtras'),
              for (final s in option.sutras)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text.rich(
                    TextSpan(children: [
                      if (s.number != null)
                        TextSpan(
                            text: '${s.number}  ',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary)),
                      TextSpan(text: d(s.text)),
                    ]),
                    key: const Key('sandhi-sutra'),
                    style: sanskrit,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
