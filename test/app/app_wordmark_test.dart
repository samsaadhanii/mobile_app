import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/app_info.dart';
import 'package:mobile_app/app/app_wordmark.dart';
import 'package:mobile_app/app/engine_identity.dart';
import 'package:mobile_app/core/constants/app_theme.dart';

import 'app_theme_test.dart' show contrast;

void main() {
  Future<void> pump(WidgetTester tester, ThemeData theme, {double? width}) =>
      tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Scaffold(
          appBar: AppBar(
            title: width == null
                ? const AppWordmark()
                : SizedBox(width: width, child: const AppWordmark()),
          ),
          body: const AppWordmark(size: 28),
        ),
      ));

  test('the display name is the placeholder joint name', () {
    expect(appDisplayName, 'Saṃsādhanī Heritage');
  });

  testWidgets('shows both words and the dot', (tester) async {
    await pump(tester, AppTheme.lightTheme);
    expect(find.text('Saṃsādhanī'), findsNWidgets(2)); // bar and body
    expect(find.text('Heritage'), findsNWidgets(2));
    expect(find.text('·'), findsNWidgets(2));
    expect(find.byType(Image), findsNothing);
  });

  for (final (name, theme) in [
    ('light', AppTheme.lightTheme),
    ('dark', AppTheme.darkTheme),
  ]) {
    testWidgets('$name: each word is its engine colour and reads at 4.5 to 1',
        (tester) async {
      await pump(tester, theme);
      final scheme = theme.colorScheme;
      Color colourOf(String word) =>
          tester.widget<Text>(find.text(word).first).style!.color!;

      expect(colourOf('Saṃsādhanī'), samsaadhaniiColor(scheme));
      expect(colourOf('Heritage'), heritageColor(scheme));
      expect(samsaadhaniiColor(scheme), scheme.primary);
      expect(heritageColor(scheme), scheme.tertiary);

      // On the top bar's surface and on the page's.
      final bar = theme.appBarTheme.backgroundColor!;
      for (final bg in [bar, scheme.surface]) {
        expect(contrast(colourOf('Saṃsādhanī'), bg), greaterThanOrEqualTo(4.5));
        expect(contrast(colourOf('Heritage'), bg), greaterThanOrEqualTo(4.5));
        expect(contrast(colourOf('·'), bg), greaterThanOrEqualTo(4.5));
      }
    });
  }

  testWidgets('shrinks to fit a narrow bar and is not cut off', (tester) async {
    await pump(tester, AppTheme.lightTheme, width: 110);
    expect(tester.takeException(), isNull);
    // Both words are still laid out, inside the 110 px they were given.
    Finder inBar(String word) =>
        find.descendant(of: find.byType(AppBar), matching: find.text(word));
    final right = tester.getRect(inBar('Heritage')).right;
    final left = tester.getRect(inBar('Saṃsādhanī')).left;
    expect(right - left, lessThanOrEqualTo(110));
  });

  testWidgets('one semantic label, the display name', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, AppTheme.lightTheme);
    expect(find.bySemanticsLabel(appDisplayName), findsNWidgets(2));
    handle.dispose();
  });
}
