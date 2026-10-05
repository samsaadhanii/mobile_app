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
                ? const AppWordmark(onBar: true)
                : SizedBox(width: width, child: const AppWordmark(onBar: true)),
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
    Color colourOf(WidgetTester tester, Finder where, String word) => tester
        .widget<Text>(
            find.descendant(of: where, matching: find.text(word)).first)
        .style!
        .color!;

    testWidgets('$name: on the page each word is its engine colour at 4.5 to 1',
        (tester) async {
      await pump(tester, theme);
      final scheme = theme.colorScheme;
      final inBody = find
          .byWidgetPredicate((w) => w is AppWordmark && !w.onBar);
      expect(inBody, findsOneWidget);
      Color page(String word) => tester
          .widget<Text>(
              find.descendant(of: inBody, matching: find.text(word)))
          .style!
          .color!;
      expect(page('Saṃsādhanī'), samsaadhaniiColor(scheme));
      expect(page('Heritage'), heritageColor(scheme));
      expect(samsaadhaniiColor(scheme), scheme.primary);
      expect(heritageColor(scheme), scheme.tertiary);
      for (final w in ['Saṃsādhanī', 'Heritage', '·']) {
        expect(contrast(page(w), scheme.surface), greaterThanOrEqualTo(4.5),
            reason: w);
      }
    });

    testWidgets('$name: on the teal bar the words are two tints that read at '
        '4.5 to 1', (tester) async {
      await pump(tester, theme);
      final bar = find.byType(AppBar);
      final background = theme.appBarTheme.backgroundColor!;
      final sam = colourOf(tester, bar, 'Saṃsādhanī');
      final her = colourOf(tester, bar, 'Heritage');
      final dot = colourOf(tester, bar, '·');
      expect(sam, isNot(her), reason: 'two different tints');
      for (final (word, c) in [('Saṃsādhanī', sam), ('Heritage', her), ('·', dot)]) {
        expect(contrast(c, background), greaterThanOrEqualTo(4.5), reason: word);
      }
      // Not the plain engine colours: those would vanish on the bar.
      expect(contrast(samsaadhaniiColor(theme.colorScheme), background),
          lessThan(4.5));
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
