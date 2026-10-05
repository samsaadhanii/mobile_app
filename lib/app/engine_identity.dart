import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The two engines' identity colours, defined once so every screen that needs
/// to tell them apart uses the same pair. They come from the colour scheme
/// (primary and tertiary), so they meet 4.5 to 1 on the surface in light and
/// dark.
Color samsaadhaniiColor(ColorScheme scheme) => scheme.primary;

Color heritageColor(ColorScheme scheme) => scheme.tertiary;

/// WCAG contrast ratio of two opaque colours.
double contrastRatio(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

/// [tint] moved toward [toward] until it reaches [minimum] to 1 on
/// [background]; unchanged if it already does.
Color readableOn(Color tint, Color background, Color toward,
    {double minimum = 4.5}) {
  var c = tint;
  for (var i = 0; i < 20 && contrastRatio(c, background) < minimum; i++) {
    c = Color.lerp(c, toward, 0.1)!;
  }
  return c;
}

/// The two engine colours as tints for the teal top bar, where the plain
/// colours (the bar's own `primary`, and `tertiary`) would vanish: the
/// scheme's two container tints, moved toward the bar's text colour if
/// needed, each at 4.5 to 1 on [bar]. Still two different colours.
(Color, Color) engineTintsOnBar(ColorScheme scheme, Color bar) => (
      readableOn(scheme.primaryContainer, bar, scheme.onPrimary),
      readableOn(scheme.tertiaryContainer, bar, scheme.onPrimary),
    );
