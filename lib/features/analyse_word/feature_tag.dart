import 'package:flutter/material.dart';

/// A feature of an analysis as a quiet tag: a faint fill, no outline, square
/// corners. It does nothing. Anything outlined and pill-shaped in the app can
/// be tapped; this is deliberately not that. [sanskrit] text is never below
/// 16 sp.
class FeatureTag extends StatelessWidget {
  const FeatureTag(this.label,
      {super.key, required this.sanskrit, this.emphasis = false});

  final String label;
  final bool sanskrit;

  /// A tag that says something about the reading as a whole ("Most likely")
  /// rather than being one of its features: a tinted fill, still no outline.
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: emphasis ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(label,
            style: TextStyle(
                fontSize: sanskrit ? 16 : 14,
                color: emphasis ? scheme.onPrimaryContainer : scheme.onSurface)),
      ),
    );
  }
}
