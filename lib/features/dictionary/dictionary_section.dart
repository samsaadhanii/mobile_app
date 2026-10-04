import 'package:flutter/material.dart';

import '../../domain/domain.dart';

/// How many lines of an entry show before "Show all".
const dictionaryCollapsedLines = 6;

/// One dictionary's entry (`SCREENS.md` 5.4 and U14): the dictionary's name and
/// the language of its definitions as the heading, and the body, selectable,
/// cut after the first six lines with "Show all" when it is longer. The body is
/// prose in another language with Sanskrit inside it and is shown as given.
class DictionarySection extends StatefulWidget {
  const DictionarySection({super.key, required this.entry});

  final DictionaryEntry entry;

  @override
  State<DictionarySection> createState() => _DictionarySectionState();
}

class _DictionarySectionState extends State<DictionarySection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = widget.entry.dictionary;
    final name = info.name;
    // Sanskrit inside the prose is never smaller than 16 sp.
    final style = DefaultTextStyle.of(context)
        .style
        .merge(const TextStyle(fontSize: 16, height: 1.4));
    final text = widget.entry.paragraphs.join('\n');
    final heading = info.language == DictionaryLanguage.other
        ? name
        : '$name · ${info.language.label}';

    return Card(
      key: Key('dict-$name'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(builder: (context, constraints) {
          // Does the whole text need more than six lines at this width?
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: TextDirection.ltr,
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: dictionaryCollapsedLines,
          )..layout(maxWidth: constraints.maxWidth);
          final longer = painter.didExceedMaxLines;
          painter.dispose();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(heading,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: theme.colorScheme.primary)),
              const SizedBox(height: 8),
              SelectableText(
                text,
                key: Key('dict-body-$name'),
                style: style,
                maxLines: longer && !_expanded ? dictionaryCollapsedLines : null,
              ),
              if (longer)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: Key('dict-toggle-$name'),
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(_expanded ? 'Show less' : 'Show all'),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}
