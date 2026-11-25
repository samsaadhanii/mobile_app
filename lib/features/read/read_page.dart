import 'package:flutter/material.dart';

import '../gita_page/gita_page_screen.dart';

/// One book on the Read tab: its names, the quiet bottom line (whose work it
/// is) and the screen it opens.
class ReadBook {
  const ReadBook({
    required this.nameEn,
    required this.nameSa,
    required this.credit,
    required this.open,
  });

  final String nameEn;
  final String nameSa;
  final String credit;
  final WidgetBuilder open;
}

/// The books on the Read tab, in order. Today the one Gītā page (D6); the
/// native Reader's books are added here (D7).
List<ReadBook> readBooks({GitaPageViewFactory? gitaViewFactory}) => [
      ReadBook(
        nameEn: 'Bhagavad Gītā',
        nameSa: 'भगवद्गीता',
        credit: gitaPageCredit,
        open: (_) => gitaViewFactory == null
            ? const GitaPageScreen()
            : GitaPageScreen(viewFactory: gitaViewFactory),
      ),
    ];

/// The Read tab (D7): a top bar and the books as cards, two to a row, drawn
/// like the cards on Tools.
class ReadPage extends StatelessWidget {
  const ReadPage({super.key, this.gitaViewFactory});

  /// Stands in for the WebView in tests.
  final GitaPageViewFactory? gitaViewFactory;

  @override
  Widget build(BuildContext context) {
    final books = readBooks(gitaViewFactory: gitaViewFactory);
    final cards = [
      for (final b in books)
        _BookCard(
          book: b,
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: b.open)),
        ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Read')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        children: [
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
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book, required this.onTap});

  final ReadBook book;
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
              Text(book.nameEn,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w500, height: 1.2)),
              // A title: always Devanagari, never below 16 sp.
              Text(book.nameSa,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      height: 1.25,
                      color: theme.colorScheme.onSurfaceVariant)),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(book.credit,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
