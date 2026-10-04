import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/app_wordmark.dart';
import 'package:mobile_app/app/settings.dart';
import 'package:mobile_app/features/home/dhatu_index.dart';
import 'package:mobile_app/features/home/home_page.dart';
import 'package:mobile_app/features/home/recent_inputs.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A tall screen, so a whole list is on screen and needs no scrolling.
void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('Home', () {
    Future<(List<String>, RecentInputs, AppSettings)> pumpHome(
        WidgetTester tester,
        {Map<String, Object> prefs = const {}}) async {
      _tall(tester);
      SharedPreferences.setMockInitialValues(prefs);
      final settings = await AppSettings.load();
      final recent = await RecentInputs.load();
      final opened = <String>[];
      // A small list instead of the asset (loading it is tested on its own in
      // suggestions_test.dart; real I/O does not mix with the widget clock).
      final dhatus = DhatuIndex.fromKeys(['gam1_gamLz_BvAxiH_gawO']);
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: recent),
          ChangeNotifierProvider.value(value: dhatus),
        ],
        child: MaterialApp(
          home: HomePage(onOpen: (e, input, {gender}) => opened.add('${e.nameEn}|$input')),
        ),
      ));
      await tester.pumpAndSettle();
      return (opened, recent, settings);
    }

    List<String> rows(WidgetTester tester) => [
          for (final w in tester.widgetList<ListTile>(
              find.descendant(of: find.byType(Card), matching: find.byType(ListTile))))
            (w.title as Text).data!,
        ];

    testWidgets('the input box has focus and the hint', (tester) async {
      await pumpHome(tester);
      expect(find.text('Type or paste Sanskrit'), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).autofocus, isTrue);
      expect(rows(tester), isEmpty);
    });

    testWidgets('one word: Analyse, Dictionary, Noun forms', (tester) async {
      await pumpHome(tester);
      await tester.enterText(find.byType(TextField), 'rAmaH');
      await tester.pump();
      expect(rows(tester), ['Analyse a word', 'Dictionary', 'Noun forms']);
      expect(find.text('WX, 1 word'), findsOneWidget);
    });

    testWidgets('a dhatu adds Verb forms and Kṛt forms', (tester) async {
      await pumpHome(tester);
      await tester.enterText(find.byType(TextField), 'gam');
      await tester.pump();
      expect(rows(tester), [
        'Analyse a word',
        'Dictionary',
        'Noun forms',
        'Verb forms',
        'Kṛt forms',
      ]);
    });

    testWidgets('Devanagari is detected, and a dhatu is found in it',
        (tester) async {
      await pumpHome(tester);
      await tester.enterText(find.byType(TextField), 'गम्');
      await tester.pump();
      expect(find.text('Devanagari, 1 word'), findsOneWidget);
      expect(rows(tester), contains('Verb forms'));
    });

    testWidgets('two words: Split, Analyse, Join', (tester) async {
      await pumpHome(tester);
      await tester.enterText(find.byType(TextField), 'rAma AlayaH');
      await tester.pump();
      expect(rows(tester), ['Split and analyse', 'Analyse a word', 'Join two words']);
      expect(find.text('WX, 2 words'), findsOneWidget);
    });

    testWidgets('three words: Split, Analyse', (tester) async {
      await pumpHome(tester);
      await tester.enterText(find.byType(TextField), 'rāmaḥ vanaṃ gacchati');
      await tester.pump();
      expect(rows(tester), ['Split and analyse', 'Analyse a word']);
      expect(find.text('IAST, 3 words'), findsOneWidget);
    });

    testWidgets('the user can correct the detected script for this input',
        (tester) async {
      await pumpHome(tester);
      await tester.enterText(find.byType(TextField), 'rAmaH');
      await tester.pump();
      await tester.tap(find.text('WX, 1 word'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SLP1'));
      await tester.pumpAndSettle();
      expect(find.text('SLP1, 1 word'), findsOneWidget);
      // Clearing the box drops the correction.
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'rAmaH');
      await tester.pump();
      expect(find.text('WX, 1 word'), findsOneWidget);
    });

    testWidgets('the Settings input script is the fallback', (tester) async {
      await pumpHome(tester, prefs: {'settings.inputScript': 'velthuis'});
      await tester.enterText(find.byType(TextField), 'raama');
      await tester.pump();
      expect(find.text('Velthuis, 1 word'), findsOneWidget);
    });

    testWidgets('a suggestion opens its task with the input, and is remembered',
        (tester) async {
      final (opened, recent, _) = await pumpHome(tester);
      await tester.enterText(find.byType(TextField), 'rAmaH');
      await tester.pump();
      await tester.tap(find.text('Noun forms').first);
      await tester.pump();
      expect(opened, ['Noun forms|rAmaH']);
      expect(recent.items, ['rAmaH']);
    });

    testWidgets('recent inputs: tap to reuse, Clear to forget', (tester) async {
      await pumpHome(tester, prefs: {'recent.inputs': ['vanam', 'rAmaH']});
      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('vanam'), findsOneWidget);
      await tester.tap(find.text('rAmaH'));
      await tester.pump();
      expect(find.widgetWithText(TextField, 'rAmaH'), findsOneWidget);
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(find.text('Recent'), findsNothing);
    });

    testWidgets('with Keep recent inputs off nothing is stored or shown',
        (tester) async {
      final (_, recent, _) = await pumpHome(tester, prefs: {
        'settings.keepRecentInputs': false,
        'recent.inputs': ['old'],
      });
      expect(find.text('Recent'), findsNothing);
      await tester.enterText(find.byType(TextField), 'rAmaH');
      await tester.pump();
      await tester.tap(find.text('Noun forms').first);
      await tester.pump();
      expect(recent.items, ['old']);
    });

    testWidgets('no tool chips: the Tools tab lists the tools', (tester) async {
      await pumpHome(tester);
      expect(find.byType(ActionChip), findsNothing);
      expect(find.text('Tools'), findsNothing);
    });

    testWidgets('an empty box with no recent inputs offers three examples',
        (tester) async {
      await pumpHome(tester);
      expect(find.text('Try an example'), findsOneWidget);
      for (final e in ['रामः', 'रामो वनं गच्छति', 'रामालयः']) {
        expect(find.text(e), findsOneWidget);
      }
      expect(find.text('a word'), findsOneWidget);
      expect(find.text('a sentence'), findsOneWidget);
      expect(find.text('a compound'), findsOneWidget);
    });

    testWidgets('tapping an example fills the box and offers suggestions',
        (tester) async {
      await pumpHome(tester);
      await tester.tap(find.text('रामो वनं गच्छति'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'रामो वनं गच्छति'), findsOneWidget);
      expect(find.text('Devanagari, 3 words'), findsOneWidget);
      expect(rows(tester), ['Split and analyse', 'Analyse a word']);
      // The examples go once the box has text.
      expect(find.text('Try an example'), findsNothing);
    });

    testWidgets('recent inputs replace the examples', (tester) async {
      await pumpHome(tester, prefs: {'recent.inputs': ['vanam']});
      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('Try an example'), findsNothing);
    });

    testWidgets('with Keep recent inputs off the examples show', (tester) async {
      await pumpHome(tester, prefs: {
        'settings.keepRecentInputs': false,
        'recent.inputs': ['old'],
      });
      expect(find.text('Try an example'), findsOneWidget);
    });

    testWidgets('the top bar has the wordmark', (tester) async {
      await pumpHome(tester);
      expect(find.byType(AppWordmark), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });
  });
}
