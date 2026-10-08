import 'package:flutter/material.dart';

/// The frame of a Compare screen (`SCREENS.md` 5.3): a banner, the toggle for
/// each engine's own labels, and two columns.
class CompareLayout extends StatelessWidget {
  const CompareLayout({
    super.key,
    required this.title,
    required this.banner,
    required this.bannerKey,
    this.leftTitle,
    this.rightTitle,
    this.left,
    this.right,
    this.body,
    required this.ownLabels,
    required this.onOwnLabels,
  }) : assert((body != null) != (left != null && right != null),
            'two columns or one body');

  final String title;
  final String banner;

  /// `agree`, `differ` or `partial`, for tests and styling.
  final String bannerKey;
  final String? leftTitle;
  final String? rightTitle;
  final Widget? left;
  final Widget? right;

  /// Instead of two columns: one body under the toggle (Compare an analysis,
  /// which sets the engines side by side in a table).
  final Widget? body;
  final bool ownLabels;
  final ValueChanged<bool> onOwnLabels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (background, foreground) = switch (bannerKey) {
      'agree' => (colors.primaryContainer, colors.onPrimaryContainer),
      'differ' => (colors.errorContainer, colors.onErrorContainer),
      _ => (colors.surfaceContainerHighest, colors.onSurface),
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            key: Key('banner-$bannerKey'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(banner,
                style: theme.textTheme.titleMedium?.copyWith(color: foreground)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("Show each engine's own labels"),
            value: ownLabels,
            onChanged: onOwnLabels,
          ),
          if (body != null)
            body!
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _column(theme, leftTitle!, left!)),
                const SizedBox(width: 8),
                Expanded(child: _column(theme, rightTitle!, right!)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _column(ThemeData theme, String title, Widget body) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          body,
        ],
      );
}
