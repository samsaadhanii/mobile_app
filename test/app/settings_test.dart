import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/settings.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/features/home/recent_inputs.dart';
import 'package:mobile_app/features/settings/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _prefs([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

void main() {
  group('AppSettings', () {
    test('defaults, SCREENS.md section 6', () async {
      final s = await AppSettings.load(await _prefs());
      expect(s.inputScript, InputScriptSetting.automatic);
      expect(s.displayScript, DisplayScriptSetting.iast);
      expect(s.labelLanguage, LabelLanguage.sanskrit);
      expect(s.preferredEngine, EngineId.samsaadhanii);
      expect(s.keepRecentInputs, isTrue);
      // Chosen on the Join words screen, not a row of the Settings page.
      expect(s.learnerLevel, LearnerLevel.basic);
    });

    test('all five settings survive a restart', () async {
      final prefs = await _prefs();
      final s = await AppSettings.load(prefs);
      await s.setInputScript(InputScriptSetting.slp1);
      await s.setDisplayScript(DisplayScriptSetting.devanagari);
      await s.setLabelLanguage(LabelLanguage.english);
      await s.setPreferredEngine(EngineId.heritage);
      await s.setKeepRecentInputs(false);

      final again = await AppSettings.load(prefs);
      expect(again.inputScript, InputScriptSetting.slp1);
      expect(again.displayScript, DisplayScriptSetting.devanagari);
      expect(again.labelLanguage, LabelLanguage.english);
      expect(again.preferredEngine, EngineId.heritage);
      expect(again.keepRecentInputs, isFalse);
    });

    test('the learner level is remembered, and notifies', () async {
      final prefs = await _prefs();
      final s = await AppSettings.load(prefs);
      var calls = 0;
      s.addListener(() => calls++);
      await s.setLearnerLevel(LearnerLevel.advanced);
      expect(calls, 1);
      expect(prefs.getString('settings.learnerLevel'), 'advanced');
      expect((await AppSettings.load(prefs)).learnerLevel, LearnerLevel.advanced);
      await s.setLearnerLevel(LearnerLevel.intermediate);
      expect((await AppSettings.load(prefs)).learnerLevel, LearnerLevel.intermediate);
    });

    test('a stored level that no longer exists is Basic', () async {
      final s = await AppSettings.load(
          await _prefs({'settings.learnerLevel': 'expert'}));
      expect(s.learnerLevel, LearnerLevel.basic);
    });

    test('the three levels, in order', () {
      expect(LearnerLevel.values.map((l) => l.label),
          ['Basic', 'Intermediate', 'Advanced']);
    });

    test('a change notifies listeners after it is written', () async {
      final prefs = await _prefs();
      final s = await AppSettings.load(prefs);
      var calls = 0;
      String? seen;
      s.addListener(() {
        calls++;
        seen = prefs.getString('settings.labelLanguage');
      });
      await s.setLabelLanguage(LabelLanguage.english);
      expect(calls, 1);
      expect(seen, 'english');
    });

    test('a stored value that no longer exists falls back to the default',
        () async {
      final s = await AppSettings.load(await _prefs({
        'settings.inputScript': 'gone',
        'settings.preferredEngine': 'nobody',
      }));
      expect(s.inputScript, InputScriptSetting.automatic);
      expect(s.preferredEngine, EngineId.samsaadhanii);
    });

    test('Automatic has no script; the others do', () {
      expect(InputScriptSetting.automatic.script, isNull);
      expect(InputScriptSetting.itrans.script, Script.itrans);
      expect(InputScriptSetting.values.length, 8);
    });
  });

  group('RecentInputs', () {
    test('newest first, no duplicates, at most ten, survives a restart',
        () async {
      final prefs = await _prefs();
      final r = await RecentInputs.load(prefs);
      for (var i = 0; i < 12; i++) {
        await r.add('w$i');
      }
      await r.add('w5');
      await r.add('  ');
      expect(r.items.length, 10);
      expect(r.items.first, 'w5');
      expect(r.items.where((e) => e == 'w5').length, 1);
      expect((await RecentInputs.load(prefs)).items, r.items);
      await r.clear();
      expect(r.items, isEmpty);
      expect((await RecentInputs.load(prefs)).items, isEmpty);
    });
  });

  group('Settings page', () {
    Future<(AppSettings, RecentInputs, SharedPreferences)> pump(
        WidgetTester tester, Map<String, Object> values) async {
      final prefs = await _prefs(values);
      final settings = await AppSettings.load(prefs);
      final recent = await RecentInputs.load(prefs);
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: recent),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ));
      return (settings, recent, prefs);
    }

    testWidgets('shows the five settings with their values', (tester) async {
      await pump(tester, {});
      for (final t in [
        'Input script',
        'Display script',
        'Grammar labels',
        'Preferred engine',
        'Keep recent inputs',
      ]) {
        expect(find.text(t), findsOneWidget);
      }
      expect(find.text('Automatic'), findsOneWidget);
      expect(find.text('IAST'), findsOneWidget);
      expect(find.text('Sanskrit'), findsOneWidget);
      expect(find.text('Samsaadhanii'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Contributors'), findsOneWidget);
    });

    testWidgets('choosing a value is saved on the phone', (tester) async {
      final (settings, _, prefs) = await pump(tester, {});
      await tester.tap(find.text('Grammar labels'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(settings.labelLanguage, LabelLanguage.english);
      expect(prefs.getString('settings.labelLanguage'), 'english');
      expect(find.text('English'), findsOneWidget); // the subtitle now

      await tester.tap(find.text('Preferred engine'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Heritage'));
      await tester.pumpAndSettle();
      expect(prefs.getString('settings.preferredEngine'), 'heritage');
    });

    testWidgets('"Keep recent inputs" off forgets what was kept',
        (tester) async {
      final (settings, recent, prefs) =
          await pump(tester, {'recent.inputs': ['rAmaH']});
      expect(recent.items, ['rAmaH']);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(settings.keepRecentInputs, isFalse);
      expect(prefs.getBool('settings.keepRecentInputs'), isFalse);
      expect(recent.items, isEmpty);
    });

    testWidgets('Clear recent inputs', (tester) async {
      final (_, recent, _) = await pump(tester, {'recent.inputs': ['a', 'b']});
      await tester.tap(find.text('Clear recent inputs'));
      await tester.pumpAndSettle();
      expect(recent.items, isEmpty);
    });

    testWidgets('About and Contributors open as native pages', (tester) async {
      await pump(tester, {});
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();
      expect(find.text('Sanskrit Heritage Platform'), findsOneWidget);
      expect(find.textContaining('Text to come'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Contributors'));
      await tester.pumpAndSettle();
      expect(find.textContaining('We thank the following'), findsOneWidget);
    });
  });
}
