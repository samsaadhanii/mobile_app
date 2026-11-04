import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/engine_identity.dart' show contrastRatio;
import 'package:mobile_app/app/settings.dart';
import 'package:mobile_app/core/constants/app_theme.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/features/tools/tool_entries.dart';
import 'package:mobile_app/features/tools/tools_list_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/roboto.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // The real Roboto, so a name wraps or not as it would on a phone; the
    // default test font draws every glyph as a full-width square.
    expect(await loadRoboto(), isTrue);
  });

  Future<List<String>> pumpTools(WidgetTester tester,
      {Map<String, Object> prefs = const {},
      Size size = const Size(360, 536),
      double textScale = 1,
      ThemeData? theme}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(prefs);
    final settings = await AppSettings.load();
    final opened = <String>[];
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: settings,
      child: MaterialApp(
        theme: theme,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!),
        home: ToolsListPage(onOpen: (e, input, {gender, prefix}) => opened.add('${e.nameEn}|$input')),
      ),
    ));
    await tester.pumpAndSettle();
    return opened;
  }

  // The page sits between the status bar and the bottom bar (80 dp), and has
  // its own 56 dp top bar: a 360 x 640 phone leaves 536 dp for the page, an
  // iPhone SE (375 x 667) 567 dp.
  for (final (name, size) in [
    ('360 x 640 dp', const Size(360, 640 - 24 - 80)),
    ('iPhone SE 375 x 667', const Size(375, 667 - 20 - 80)),
  ]) {
    testWidgets('all eight cards and three headings fit without scrolling, '
        '$name', (tester) async {
      await pumpTools(tester, size: size);
      for (final e in toolEntries) {
        final card = find.ancestor(
            of: find.text(e.nameEn), matching: find.byType(Card));
        expect(card, findsOneWidget, reason: e.nameEn);
        expect(tester.getRect(card).bottom, lessThanOrEqualTo(size.height),
            reason: e.nameEn);
      }
      expect(toolEntries.length, 8);
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      expect(scrollable.position.maxScrollExtent, 0);
      expect(tester.takeException(), isNull);
      // The height one card needs (for the report).
      final heights = {
        for (final c in tester.widgetList<Card>(find.byType(Card)))
          tester.getSize(find.byWidget(c)).height.round()
      };
      debugPrint('$name: card heights $heights');
    });
  }

  testWidgets('eight cards in three groups, two columns, in the order of '
      'SCREENS.md section 3', (tester) async {
    await pumpTools(tester);
    expect(find.byType(Card), findsNWidgets(8));
    final order = [for (final e in toolEntries) e.nameEn];
    expect(order.first, 'Analyse a word');
    final tops = [
      for (final n in order)
        tester.getTopLeft(find.ancestor(
            of: find.text(n), matching: find.byType(Card)))
    ];
    // Down the page group by group, left to right in a row.
    for (var i = 0; i < 8; i++) {
      expect(tops[i].dx, i.isEven ? lessThan(180) : greaterThanOrEqualTo(180), reason: order[i]);
      if (i > 0) {
        expect(tops[i].dy, greaterThanOrEqualTo(tops[i - 1].dy), reason: order[i]);
      }
    }
    // Headings sit above the first card of their group.
    double y(String t) => tester.getTopLeft(find.text(t)).dy;
    expect(y('Analysis'), lessThan(tops[0].dy));
    expect(y('Generation'), allOf(greaterThan(tops[1].dy), lessThan(tops[2].dy)));
    expect(y('Reference'), allOf(greaterThan(tops[5].dy), lessThan(tops[6].dy)));
    // Two columns: the four generation cards make two rows.
    expect(tops[2].dy, tops[3].dy);
    expect(tops[4].dy, tops[5].dy);
    expect(tops[4].dy, greaterThan(tops[2].dy));
  });

  testWidgets('at Larger text the page may scroll, and nothing overflows',
      (tester) async {
    await pumpTools(tester, textScale: 1.3);
    expect(tester.takeException(), isNull);
    expect(find.byType(Card), findsNWidgets(8));
  });

  for (final t in {'light': AppTheme.lightTheme, 'dark': AppTheme.darkTheme}.entries) {
    testWidgets('every text on a card is 4.5 to 1 on the card, ${t.key}',
        (tester) async {
      await pumpTools(tester, theme: t.value);
      final card = t.value.colorScheme.surfaceContainerLow;
      final material = tester.widget<Material>(find
          .descendant(of: find.byType(Card).first, matching: find.byType(Material))
          .first);
      expect(material.color, card);
      final texts = tester.widgetList<Text>(find.descendant(
          of: find.byType(Card), matching: find.byType(Text)));
      expect(texts.length, greaterThanOrEqualTo(8 * 2));
      for (final x in texts) {
        final colour = x.style?.color ?? t.value.colorScheme.onSurface;
        expect(contrastRatio(colour, card), greaterThanOrEqualTo(4.5),
            reason: '${x.data} ${t.key}');
      }
    });
  }

  for (final display in DisplayScriptSetting.values) {
    testWidgets('Sanskrit names are Devanagari with ${display.label} display',
        (tester) async {
      await pumpTools(tester,
          prefs: {'settings.displayScript': display.name});
      for (final e in toolEntries) {
        expect(find.text(e.nameSa), findsOneWidget, reason: e.nameSa);
      }
      expect(find.text('धातुपाठः'), findsOneWidget);
      expect(find.text('dhātupāṭhaḥ'), findsNothing);
    });
  }

  testWidgets('group headings are in sentence case', (tester) async {
    await pumpTools(tester);
    for (final g in ['Analysis', 'Generation', 'Reference']) {
      expect(find.text(g), findsOneWidget);
    }
    expect(find.text('ANALYSIS'), findsNothing);
  });

  testWidgets('engines are quiet text, not chips', (tester) async {
    await pumpTools(tester);
    expect(find.byType(Chip), findsNothing);
    expect(find.byType(ActionChip), findsNothing);
    expect(find.byType(FilterChip), findsNothing);
    // Both engines for the two analysis rows, one for the rest but Dhātupāṭha.
    expect(find.text('Samsaadhanii · Heritage'), findsNWidgets(2));
    expect(find.text('Samsaadhanii'), findsNWidgets(5));
  });

  testWidgets('a card opens its tool with an empty input', (tester) async {
    final opened = await pumpTools(tester);
    await tester.tap(find.text(Task.dictionary.nameEn));
    expect(opened, ['${Task.dictionary.nameEn}|']);
  });
}
