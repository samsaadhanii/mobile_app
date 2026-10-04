import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/constants/app_theme.dart';

double _luminance(Color c) => c.computeLuminance();

/// WCAG contrast ratio of two opaque colours.
double contrast(Color a, Color b) {
  final hi = math.max(_luminance(a), _luminance(b));
  final lo = math.min(_luminance(a), _luminance(b));
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('the contrast helper agrees with known values', () {
    expect(contrast(Colors.black, Colors.white), closeTo(21, 0.01));
    // The old top bar: white on teal 200 failed.
    expect(contrast(Colors.white, const Color(0xFF80CBC4)), lessThan(2));
  });

  for (final (name, theme) in [
    ('light', AppTheme.lightTheme),
    ('dark', AppTheme.darkTheme),
  ]) {
    test('$name top bar: title and icons reach 4.5 to 1', () {
      final bar = theme.appBarTheme;
      final background = bar.backgroundColor!;
      expect(contrast(bar.foregroundColor!, background), greaterThanOrEqualTo(4.5));
      expect(contrast(bar.titleTextStyle!.color!, background),
          greaterThanOrEqualTo(4.5));
      expect(contrast(bar.iconTheme!.color!, background), greaterThanOrEqualTo(4.5));
    });

    test('$name status-bar icons contrast with the top bar', () {
      final bar = theme.appBarTheme;
      final darkBar = ThemeData.estimateBrightnessForColor(bar.backgroundColor!) ==
          Brightness.dark;
      // Light icons on a dark bar, dark icons on a light one.
      expect(bar.systemOverlayStyle!.statusBarIconBrightness,
          darkBar ? Brightness.light : Brightness.dark);
    });
  }

  test('the gradient bar and button carry white text at 4.5 to 1', () {
    expect(contrast(Colors.white, AppColors.gradientStart), greaterThanOrEqualTo(4.5));
    expect(contrast(Colors.white, AppColors.gradientEnd), greaterThanOrEqualTo(4.5));
  });

  testWidgets('the rendered top bar uses the theme colours in both themes',
      (tester) async {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(appBar: AppBar(title: const Text('Tools'))),
      ));
      final material = tester.widget<Material>(find
          .descendant(of: find.byType(AppBar), matching: find.byType(Material))
          .first);
      final title = tester.widget<DefaultTextStyle>(find
          .ancestor(of: find.text('Tools'), matching: find.byType(DefaultTextStyle))
          .first);
      expect(contrast(title.style.color!, material.color!), greaterThanOrEqualTo(4.5));
    }
  });
}
