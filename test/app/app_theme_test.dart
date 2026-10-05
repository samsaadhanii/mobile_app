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

    test('$name top bar is a teal of the scheme', () {
      final bar = theme.appBarTheme;
      final scheme = theme.colorScheme;
      final light = theme.brightness == Brightness.light;
      expect(bar.backgroundColor, light ? scheme.primary : scheme.primaryContainer);
      expect(bar.foregroundColor,
          light ? scheme.onPrimary : scheme.onPrimaryContainer);
      // The status bar takes the same colour.
      expect(bar.systemOverlayStyle!.statusBarColor, bar.backgroundColor);
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

  test('the dark theme\'s bar is dark, with light text and light status icons', () {
    final bar = AppTheme.darkTheme.appBarTheme;
    expect(ThemeData.estimateBrightnessForColor(bar.backgroundColor!),
        Brightness.dark);
    expect(bar.backgroundColor!.computeLuminance(), lessThan(0.1));
    expect(bar.foregroundColor!.computeLuminance(), greaterThan(0.5));
    expect(bar.systemOverlayStyle!.statusBarIconBrightness, Brightness.light);
    // The light theme is unchanged: a darker teal with white-ish text.
    expect(ThemeData.estimateBrightnessForColor(
            AppTheme.lightTheme.appBarTheme.backgroundColor!),
        Brightness.dark);
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
