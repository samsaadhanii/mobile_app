import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/settings.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/engines/samsaadhanii/samsaadhanii_engine.dart';
import 'package:mobile_app/features/dictionary/dictionary_screen.dart';
import 'package:mobile_app/features/krt_forms/krt_forms_screen.dart';
import 'package:mobile_app/features/noun_forms/noun_forms_screen.dart';
import 'package:mobile_app/features/task_frame/engine_set.dart';
import 'package:mobile_app/features/verb_forms/verb_forms_screen.dart';
import 'package:mobile_app/shared/data/word_lists.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_engine.dart';
import '../support/fixture_clients.dart';

/// "Did you mean …?" (U28). The analyses are the real Samsaadhanii answers
/// captured from the server (test/fixtures/samsaadhanii/morph_*.txt), read by
/// the real adapter.
const _gam = 'gam1_gamLz_BvAxiH_gawO';
const _gamCur = 'gam2_gamLz_curAxiH_gawO';

final _dhatus = DhatuList.fromEntries([
  ListEntry(_gam, 'गम् (गम्) गतौ भ्वादिः', 'gam (gam) gatau bhvādiḥ'),
  ListEntry(_gamCur, 'गम् (गम्) गतौ चुरादिः', 'gam (gam) gatau curādiḥ'),
]);
final _prefixes = PrefixList.fromEntries([ListEntry('Af', 'आङ्', 'āṅ')]);

Future<Outcome<WordAnalysis>> _analysis(String wx) =>
    SamsaadhaniiEngine(client: SamsaadhaniiMorphFixtures())
        .analyseWord(SanskritText(wx));

Future<void> _pump(WidgetTester tester, EngineSet engines, Widget screen) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'settings.displayScript': 'devanagari'});
  final settings = await AppSettings.load();
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      Provider<EngineSet>.value(value: engines),
      ChangeNotifierProvider<DhatuList>.value(value: _dhatus),
      ChangeNotifierProvider<PrefixList>.value(value: _prefixes),
    ],
    child: MaterialApp(home: screen),
  ));
  await tester.pumpAndSettle();
}

Future<FakeEngine> _sam(String wx, Set<Task> tasks) async =>
    FakeEngine(tasks: {Task.analyseWord, ...tasks}, analysis: await _analysis(wx));

void main() {
  group('Dictionary', () {
    testWidgets('रामः offers राम, and tapping it looks that up', (tester) async {
      final sam = await _sam('rAmaH', {Task.dictionary});
      await _pump(tester, EngineSet({EngineId.samsaadhanii: sam}),
          const DictionaryScreen(initialInput: 'रामः'));
      expect(find.text('No entry for रामः'), findsOneWidget);
      expect(find.text('Did you mean:'), findsOneWidget);
      expect(find.descendant(
          of: find.byKey(const Key('did-you-mean')), matching: find.text('राम')),
          findsOneWidget);
      await tester.tap(find.descendant(
          of: find.byKey(const Key('did-you-mean')), matching: find.text('राम')));
      await tester.pumpAndSettle();
      expect(sam.calls, contains('lookUp:rAma'));
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'राम');
    });

    testWidgets('the analysis is asked for only after a NotFound',
        (tester) async {
      final sam = FakeEngine(tasks: const {Task.analyseWord, Task.dictionary});
      await _pump(tester, EngineSet({EngineId.samsaadhanii: sam}),
          const DictionaryScreen());
      expect(sam.calls, isEmpty);
      await tester.enterText(find.byType(TextField), 'xyzq');
      await tester.tap(find.byTooltip('Look up'));
      await tester.pumpAndSettle();
      // Looked up first, analysed after; nothing found, so the plain state.
      expect(sam.calls, ['lookUp:xyzq', 'analyseWord:xyzq']);
      expect(find.byKey(const Key('state-notFound')), findsOneWidget);
      expect(find.text('Did you mean:'), findsNothing);
    });

    testWidgets('Heritage is asked only when Samsaadhanii finds nothing',
        (tester) async {
      final sam = FakeEngine(tasks: const {Task.analyseWord, Task.dictionary});
      final her = await _sam('rAmaH', {});
      final heritage = FakeEngine(
          id: EngineId.heritage,
          tasks: const {Task.analyseWord},
          analysis: her.analysis);
      await _pump(
          tester,
          EngineSet({EngineId.samsaadhanii: sam, EngineId.heritage: heritage}),
          const DictionaryScreen(initialInput: 'रामः'));
      expect(heritage.calls, ['analyseWord:rAmaH']);
      expect(find.text('Did you mean:'), findsOneWidget);
    });
  });

  group('Noun forms', () {
    testWidgets('रामः offers राम, masculine, preselected', (tester) async {
      final sam = await _sam('rAmaH', {Task.nounForms});
      await _pump(tester, EngineSet({EngineId.samsaadhanii: sam}),
          const NounFormsScreen(initialInput: 'रामः'));
      expect(find.text('Did you mean:'), findsOneWidget);
      final row = find.descendant(
          of: find.byKey(const Key('did-you-mean')), matching: find.byType(ListTile));
      // Only the noun: the verb reading rA is not a stem to decline.
      expect(row, findsOneWidget);
      expect(find.descendant(of: row, matching: find.text('राम')), findsOneWidget);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(sam.calls, contains('declineNoun:rAma:masculine:plainNoun'));
    });

    testWidgets('a word the analyser does not know shows the plain state',
        (tester) async {
      final sam = FakeEngine(tasks: const {Task.analyseWord, Task.nounForms});
      await _pump(tester, EngineSet({EngineId.samsaadhanii: sam}),
          const NounFormsScreen(initialInput: 'xyzq'));
      expect(find.byKey(const Key('state-notFound')), findsOneWidget);
      expect(find.text('Did you mean:'), findsNothing);
    });
  });

  group('the dhātu search', () {
    Future<void> search(WidgetTester tester, String text) async {
      await tester.tap(find.text('Select…'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, text);
      // Nothing is asked while typing; after a pause it is.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    }

    testWidgets('गच्छति offers गम्, and choosing it selects the root',
        (tester) async {
      final sam = await _sam('gacCawi', {Task.verbForms});
      await _pump(tester, EngineSet({EngineId.samsaadhanii: sam}),
          const VerbFormsScreen());
      await search(tester, 'गच्छति');
      expect(sam.calls, ['analyseWord:gacCawi']);
      expect(find.text('Did you mean:'), findsOneWidget);
      expect(find.text('गच्छति → गम् (गम्) गतौ भ्वादिः'), findsOneWidget);
      await tester.tap(find.text('गच्छति → गम् (गम्) गतौ भ्वादिः'));
      await tester.pumpAndSettle();
      expect(sam.calls.last, 'conjugateVerb:$_gam:-:kartari');
    });

    testWidgets('आगच्छति offers गम् with आङ्, and both are selected',
        (tester) async {
      final sam = await _sam('AgacCawi', {Task.verbForms});
      await _pump(tester, EngineSet({EngineId.samsaadhanii: sam}),
          const VerbFormsScreen());
      await search(tester, 'आगच्छति');
      // One row for each gaṇa of the root in the list, both with the prefix.
      expect(find.text('with prefix आङ्'), findsNWidgets(2));
      await tester.tap(find.text('आगच्छति → गम् (गम्) गतौ भ्वादिः'));
      await tester.pumpAndSettle();
      expect(sam.calls.last, 'conjugateVerb:$_gam:Af:kartari');
    });

    testWidgets('the same offer in Kṛt forms', (tester) async {
      final sam = await _sam('AgacCawi', {Task.krtForms});
      await _pump(tester, EngineSet({EngineId.samsaadhanii: sam}),
          const KrtFormsScreen());
      await search(tester, 'आगच्छति');
      await tester.tap(find.text('आगच्छति → गम् (गम्) गतौ भ्वादिः'));
      await tester.pumpAndSettle();
      expect(sam.calls.last, 'krtForms:$_gam:Af');
    });

    testWidgets('nothing is asked while the search still matches a root',
        (tester) async {
      final sam = await _sam('gacCawi', {Task.verbForms});
      await _pump(tester, EngineSet({EngineId.samsaadhanii: sam}),
          const VerbFormsScreen());
      await search(tester, 'gam');
      expect(sam.calls, isEmpty);
      expect(find.text('Did you mean:'), findsNothing);
    });

    testWidgets('a word the analyser does not know offers nothing',
        (tester) async {
      final sam = FakeEngine(tasks: const {Task.analyseWord, Task.verbForms});
      await _pump(tester, EngineSet({EngineId.samsaadhanii: sam}),
          const VerbFormsScreen());
      await search(tester, 'xyzq');
      expect(sam.calls, ['analyseWord:xyzq']);
      expect(find.text('Did you mean:'), findsNothing);
    });
  });
}
