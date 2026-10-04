import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/settings.dart';
import 'package:mobile_app/core/constants/app_theme.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/shared/data/word_lists.dart';
import 'package:mobile_app/shared/widgets/dhatu_picker.dart';
import 'package:mobile_app/shared/widgets/prefix_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _gamKey = 'gam1_gamLz_BvAxiH_gawO';

final _dhatus = DhatuList.fromEntries([
  ListEntry(_gamKey, 'गम् (गम्) गतौ भ्वादिः', 'gam (gam) gatau bhvādiḥ'),
  ListEntry('gam2_gamLz_curAxiH_gawO', 'गम् (गम्) गतौ चुरादिः',
      'gam (gam) gatau curādiḥ'),
  ListEntry('paT1_paT_BvAxiH_vyakwAyAM vAci', 'पठ् (पठ्) व्यक्तायां वाचि भ्वादिः',
      'paṭh (paṭh) vyaktāyāṃ vāci bhvādiḥ'),
]);

final _prefixes = PrefixList.fromEntries([
  ListEntry('Af', 'आङ्', 'āṅ'),
  ListEntry('pra', 'प्र', 'pra'),
  ListEntry('aXi_ava', 'अधि_अव', 'adhi_ava'),
]);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Map<String, Object> prefs = const {},
  ThemeData? theme,
  DhatuList? dhatus,
  PrefixList? prefixes,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final settings = await AppSettings.load();
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider<DhatuList>.value(value: dhatus ?? _dhatus),
      ChangeNotifierProvider<PrefixList>.value(value: prefixes ?? _prefixes),
    ],
    child: MaterialApp(theme: theme, home: Scaffold(body: child)),
  ));
  settle ? await tester.pumpAndSettle() : await tester.pump();
}

void main() {
  group('DhatuList.keysFor', () {
    test('the key itself', () {
      expect(_dhatus.keysFor(_gamKey), [_gamKey]);
    });

    test('a root without its number, or with its markers', () {
      expect(_dhatus.keysFor('gam'), [_gamKey, 'gam2_gamLz_curAxiH_gawO']);
      expect(_dhatus.keysFor('gamLz'), [_gamKey, 'gam2_gamLz_curAxiH_gawO']);
      expect(_dhatus.keysFor('paT'), ['paT1_paT_BvAxiH_vyakwAyAM vAci']);
    });

    test('nothing for a word that is not a dhātu, or an empty one', () {
      expect(_dhatus.keysFor('xyzq'), isEmpty);
      expect(_dhatus.keysFor(''), isEmpty);
      // Not a prefix of a key.
      expect(_dhatus.keysFor('ga'), isEmpty);
    });

    test('entryFor finds a key, or null', () {
      expect(_dhatus.entryFor(_gamKey)!.rom, startsWith('gam'));
      expect(_dhatus.entryFor('nope'), isNull);
      expect(_prefixes.entryFor('Af')!.dev, 'आङ्');
    });

    test('the bundled assets load: every entry has a key and both forms',
        () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final dhatus = DhatuList();
      final prefixes = PrefixList();
      expect(dhatus.loaded, isFalse);
      await dhatus.load();
      await prefixes.load();
      expect(dhatus.loaded, isTrue);
      expect(dhatus.entries.length, greaterThan(2000));
      expect(prefixes.entries.length, greaterThan(50));
      for (final e in [...dhatus.entries, ...prefixes.entries]) {
        expect(e.wx, isNotEmpty);
        expect(e.dev, isNotEmpty, reason: e.wx);
        expect(e.rom, isNotEmpty, reason: e.wx);
      }
      // The two prefixes the server's own list has and the app's was missing.
      expect(prefixes.entryFor('nis'), isNotNull);
      expect(prefixes.entryFor('xus'), isNotNull);
      expect(dhatus.keysFor('gam'), isNotEmpty);
    });
  });

  group('the prefix picker', () {
    testWidgets('closed: "No prefix" when none is chosen', (tester) async {
      await _pump(tester, PrefixPicker(selected: null, onChanged: (_) {}));
      expect(find.text('Prefix'), findsOneWidget);
      expect(find.text('No prefix'), findsOneWidget);
    });

    testWidgets('closed: the chosen prefix in the display script',
        (tester) async {
      await _pump(tester, PrefixPicker(selected: 'Af', onChanged: (_) {}));
      expect(find.text('āṅ'), findsOneWidget); // IAST by default
      await _pump(tester, PrefixPicker(selected: 'Af', onChanged: (_) {}),
          prefs: {'settings.displayScript': 'devanagari'});
      expect(find.text('आङ्'), findsOneWidget);
    });

    testWidgets('open: "No prefix" first, then each row in both scripts',
        (tester) async {
      await _pump(tester, PrefixPicker(selected: null, onChanged: (_) {}));
      await tester.tap(find.text('Prefix'));
      await tester.pumpAndSettle();
      final titles = [
        for (final t in tester.widgetList<ListTile>(find.byType(ListTile)))
          (t.title as Text).data,
      ];
      expect(titles.first, 'No prefix');
      expect(titles.skip(1), ['āṅ', 'pra', 'adhi_ava']);
      // Each row shows the other script under it.
      expect(find.text('आङ्'), findsOneWidget);
      expect(find.text('अधि_अव'), findsOneWidget);
    });

    testWidgets('open with a Devanagari display: Devanagari first, roman under',
        (tester) async {
      await _pump(tester, PrefixPicker(selected: null, onChanged: (_) {}),
          prefs: {'settings.displayScript': 'devanagari'});
      await tester.tap(find.text('Prefix'));
      await tester.pumpAndSettle();
      final tile = tester.widget<ListTile>(
          find.widgetWithText(ListTile, 'आङ्'));
      expect((tile.subtitle as Text).data, 'āṅ');
    });

    testWidgets('search narrows the list; "No prefix" stays first only when it matches',
        (tester) async {
      await _pump(tester, PrefixPicker(selected: null, onChanged: (_) {}));
      await tester.tap(find.text('Prefix'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'pra');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'pra'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'āṅ'), findsNothing);
      expect(find.widgetWithText(ListTile, 'No prefix'), findsNothing);
      // Devanagari and WX are searched too.
      await tester.enterText(find.byType(TextField), 'आङ्');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'āṅ'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'aXi');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'adhi_ava'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'no');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'No prefix'), findsOneWidget);
    });

    testWidgets('picking a prefix gives its key; "No prefix" gives null',
        (tester) async {
      final picked = <String?>[];
      await _pump(tester, PrefixPicker(selected: 'Af', onChanged: picked.add));
      await tester.tap(find.text('Prefix'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'pra'));
      await tester.pumpAndSettle();
      expect(picked, ['pra']);
      await tester.tap(find.text('Prefix'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'No prefix'));
      await tester.pumpAndSettle();
      expect(picked, ['pra', null]);
    });

    testWidgets('the current choice is marked in the list', (tester) async {
      await _pump(tester, PrefixPicker(selected: 'pra', onChanged: (_) {}));
      await tester.tap(find.text('Prefix'));
      await tester.pumpAndSettle();
      final marked = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .where((t) => t.selected)
          .map((t) => (t.title as Text).data);
      expect(marked, ['pra']);
    });
  });

  group('the dhātu picker', () {
    testWidgets('closed: a prompt, then the chosen root', (tester) async {
      await _pump(tester, DhatuPicker(selectedWx: '', onChanged: (_) {}));
      expect(find.text('Select a dhātu…'), findsOneWidget);
      await _pump(tester, DhatuPicker(selectedWx: _gamKey, onChanged: (_) {}));
      expect(find.text('gam (gam) gatau bhvādiḥ'), findsOneWidget);
    });

    testWidgets('open: rows in both scripts, search, pick', (tester) async {
      final picked = <String>[];
      await _pump(tester, DhatuPicker(selectedWx: '', onChanged: picked.add));
      await tester.tap(find.text('Dhātu'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNWidgets(3));
      expect(find.text('पठ् (पठ्) व्यक्तायां वाचि भ्वादिः'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'curādiḥ');
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();
      expect(picked, ['gam2_gamLz_curAxiH_gawO']);
    });

    testWidgets('no "No prefix" row in the dhātu list', (tester) async {
      await _pump(tester, DhatuPicker(selectedWx: '', onChanged: (_) {}));
      await tester.tap(find.text('Dhātu'));
      await tester.pumpAndSettle();
      expect(find.text('No prefix'), findsNothing);
    });

    testWidgets('while the list is loading it says so and does not open',
        (tester) async {
      await _pump(tester, DhatuPicker(selectedWx: '', onChanged: (_) {}),
          dhatus: DhatuList(), settle: false);
      expect(find.text('Loading…'), findsOneWidget);
      await tester.tap(find.text('Dhātu'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('both pickers follow the theme and keep Sanskrit at 16 sp', () {
    for (final (name, theme) in [
      ('light', AppTheme.lightTheme),
      ('dark', AppTheme.darkTheme),
    ]) {
      testWidgets('$name: colours come from the colour scheme', (tester) async {
        await _pump(tester, DhatuPicker(selectedWx: _gamKey, onChanged: (_) {}),
            theme: theme);
        final scheme = theme.colorScheme;
        final box = tester.widget<Container>(find
            .descendant(of: find.byType(InkWell), matching: find.byType(Container))
            .first);
        expect((box.decoration as BoxDecoration).border!.top.color, scheme.outline);

        await tester.tap(find.text('Dhātu'));
        await tester.pumpAndSettle();
        final tile = tester.widget<ListTile>(find.byType(ListTile).first);
        expect((tile.subtitle as Text).style!.color, scheme.onSurfaceVariant);
        // No fixed grey anywhere: nothing in the sheet is a Colors.grey shade.
        for (final t in tester.widgetList<Text>(find.descendant(
            of: find.byType(ListTile), matching: find.byType(Text)))) {
          final c = t.style?.color;
          expect(c == null || c == scheme.onSurfaceVariant, isTrue);
        }
      });
    }

    testWidgets('row text is at least 16 sp', (tester) async {
      await _pump(tester, PrefixPicker(selected: 'Af', onChanged: (_) {}));
      await tester.tap(find.text('Prefix'));
      await tester.pumpAndSettle();
      for (final t in tester.widgetList<ListTile>(find.byType(ListTile))) {
        expect((t.title as Text).style!.fontSize, greaterThanOrEqualTo(16));
        final sub = t.subtitle;
        if (sub != null) {
          expect((sub as Text).style!.fontSize, greaterThanOrEqualTo(16));
        }
      }
    });
  });

  test('Task.verbForms is something an engine can say it does', () {
    expect(Task.verbForms.nameEn, 'Verb forms');
  });
}
