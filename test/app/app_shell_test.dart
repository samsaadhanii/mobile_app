import 'package:flutter/cupertino.dart' show CupertinoApp, CupertinoTabScaffold;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/app.dart';
import 'package:mobile_app/app/app_info.dart';
import 'package:mobile_app/app/settings.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/features/task_frame/engine_set.dart';
import 'package:mobile_app/features/home/recent_inputs.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_engine.dart';

/// A tall screen, so a whole list is on screen and needs no scrolling.
void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _pumpApp(WidgetTester tester,
    [Map<String, Object> prefs = const {}, EngineSet? engines]) async {
  _tall(tester);
  SharedPreferences.setMockInitialValues(prefs);
  final settings = await AppSettings.load();
  final recent = await RecentInputs.load();
  await tester.pumpWidget(SamApp(settings: settings, recent: recent, engines: engines));
  // The app reads its asset lists at start; that is real I/O, so give it real
  // time to finish before the test ends.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pumpAndSettle();
}

void main() {
  group('shell', () {
    testWidgets('opens on Home, with a bar of exactly Home, Tools, Settings',
        (tester) async {
      await _pumpApp(tester);
      expect(find.byType(NavigationBar), findsOneWidget);
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.destinations.length, 3);
      expect(bar.selectedIndex, 0);
      for (final label in ['Home', 'Tools', 'Settings']) {
        expect(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
            findsOneWidget);
      }
      // Home: the display name in the top bar, the input box and its hint.
      expect(find.text(appDisplayName), findsOneWidget);
      expect(find.text('Type or paste Sanskrit'), findsOneWidget);
    });

    testWidgets('each tab keeps its place when the user switches tabs',
        (tester) async {
      await _pumpApp(tester);
      await tester.enterText(find.byType(TextField), 'rAmaH vanam');
      await tester.pump();
      expect(find.text('Split and analyse'), findsWidgets);

      await tester.tap(find.descendant(
          of: find.byType(NavigationBar), matching: find.text('Tools')));
      await tester.pumpAndSettle();
      expect(find.text('ANALYSIS'), findsOneWidget);

      await tester.tap(find.descendant(
          of: find.byType(NavigationBar), matching: find.text('Settings')));
      await tester.pumpAndSettle();
      expect(find.text('Input script'), findsOneWidget);

      await tester.tap(find.descendant(
          of: find.byType(NavigationBar), matching: find.text('Home')));
      await tester.pumpAndSettle();
      expect(find.text('rAmaH vanam'), findsOneWidget); // typed text is still there
      expect(find.text('Split and analyse'), findsWidgets);
    });

    testWidgets('is one Material 3 interface, with no Cupertino shell',
        (tester) async {
      await _pumpApp(tester);
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(CupertinoApp), findsNothing);
      expect(find.byType(CupertinoTabScaffold), findsNothing);
      expect(Theme.of(tester.element(find.byType(NavigationBar))).useMaterial3,
          isTrue);
    });

    testWidgets('Tools lists the three groups and the engine chips',
        (tester) async {
      await _pumpApp(tester);
      await tester.tap(find.descendant(
          of: find.byType(NavigationBar), matching: find.text('Tools')));
      await tester.pumpAndSettle();
      for (final g in ['ANALYSIS', 'GENERATION', 'REFERENCE']) {
        expect(find.text(g), findsOneWidget);
      }
      expect(find.text('Heritage'), findsNWidgets(2)); // analyse and split
      expect(find.text('धातुपाठः'), findsOneWidget);
    });

    testWidgets('a Tools row without a screen opens a placeholder',
        (tester) async {
      await _pumpApp(tester);
      await tester.tap(find.descendant(
          of: find.byType(NavigationBar), matching: find.text('Tools')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dhātupāṭhaḥ'));
      await tester.pumpAndSettle();
      expect(find.textContaining('is being rebuilt'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  group('the new task screens', () {
    testWidgets('Home passes the input to Analyse a word, which runs it',
        (tester) async {
      final sam = FakeEngine(id: EngineId.samsaadhanii);
      await _pumpApp(tester, const {}, EngineSet({EngineId.samsaadhanii: sam}));
      await tester.enterText(find.byType(TextField), 'rAmaH');
      await tester.pump();
      await tester.tap(find.widgetWithText(ListTile, 'Analyse a word'));
      await tester.pumpAndSettle();
      expect(sam.calls, ['analyseWord:rAmaH']);
      expect(find.widgetWithText(TextField, 'rAmaH'), findsOneWidget);
    });

    testWidgets('a sentence opens Split and analyse with the text',
        (tester) async {
      final sam = FakeEngine(id: EngineId.samsaadhanii);
      await _pumpApp(tester, const {}, EngineSet({EngineId.samsaadhanii: sam}));
      await tester.enterText(find.byType(TextField), 'rAmaH vanam');
      await tester.pump();
      await tester.tap(find.widgetWithText(ListTile, 'Split and analyse'));
      await tester.pumpAndSettle();
      expect(sam.calls, ['segment:rAmaH vanam:analyse']);
    });

    testWidgets('the Tools rows open the new screens, empty', (tester) async {
      final sam = FakeEngine(id: EngineId.samsaadhanii);
      await _pumpApp(tester, const {}, EngineSet({EngineId.samsaadhanii: sam}));
      await tester.tap(find.descendant(
          of: find.byType(NavigationBar), matching: find.text('Tools')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Analyse a word'));
      await tester.pumpAndSettle();
      expect(find.text('One Sanskrit word'), findsOneWidget);
      expect(sam.calls, isEmpty);
    });
  });
}
