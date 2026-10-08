import 'package:flutter/material.dart' hide Split;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/settings.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/features/compare/compare_analysis_screen.dart';
import 'package:mobile_app/features/compare/compare_split_screen.dart';
import 'package:mobile_app/features/task_frame/engine_set.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_engine.dart';

ResultSource _src(EngineId id) =>
    ResultSource(engine: id, program: 'p', time: DateTime.utc(2026, 10, 4));

Analysis _a(String lemma, FeatureValue gender, String original) => Analysis(
      lemma: SanskritText(lemma),
      wordClass: WordClass.noun,
      features: [Feature(FeatureKind.gender, gender, original)],
    );

Outcome<WordAnalysis> _found(EngineId id, List<Analysis> list) =>
    Found(WordAnalysis(const SanskritText('w'), list), _src(id));

Future<(FakeEngine, FakeEngine)> _pump(
  WidgetTester tester,
  Widget screen, {
  Outcome<WordAnalysis>? sam,
  Outcome<WordAnalysis>? her,
  Outcome<Segmentation>? samSeg,
  Outcome<Segmentation>? herSeg,
  Map<String, Object> prefs = const {},
}) async {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'settings.displayScript': 'iast', ...prefs});
  final settings = await AppSettings.load();
  final s = FakeEngine(
      id: EngineId.samsaadhanii, analysis: sam, segmentation: samSeg);
  final h =
      FakeEngine(id: EngineId.heritage, analysis: her, segmentation: herSeg);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      Provider<EngineSet>.value(
          value: EngineSet({EngineId.samsaadhanii: s, EngineId.heritage: h})),
    ],
    child: MaterialApp(home: screen),
  ));
  await tester.pump();
  await tester.pump();
  return (s, h);
}

/// The row of the Compare table for [kind], by its key.
TableRow _row(WidgetTester tester, String kind) => tester
    .widget<Table>(find.byType(Table))
    .children
    .singleWhere((r) => r.key == ValueKey('row-$kind'));

void main() {
  group('Compare an analysis', () {
    testWidgets('both engines are called, and agree', (tester) async {
      final one = _a('rAma', FeatureValue.masculine, 'puM');
      final (s, h) = await _pump(
        tester,
        const CompareAnalysisScreen(word: SanskritText('rAmaH')),
        sam: _found(EngineId.samsaadhanii, [one]),
        her: _found(EngineId.heritage, [_a('rAma', FeatureValue.masculine, 'm.')]),
      );
      expect(s.calls, ['analyseWord:rAmaH']);
      expect(h.calls, ['analyseWord:rAmaH']);
      expect(find.byKey(const Key('banner-agree')), findsOneWidget);
      expect(find.text('Both engines agree'), findsOneWidget);
      expect(find.text('Samsaadhanii'), findsOneWidget);
      expect(find.text('Heritage'), findsOneWidget);
      expect(find.text('From Samsaadhanii'), findsOneWidget);
      expect(find.text('From the Sanskrit Heritage Platform'), findsOneWidget);
    });

    testWidgets('they differ: the banner, a block for the shared reading, '
        'the rest under "Only in Heritage"', (tester) async {
      await _pump(
        tester,
        const CompareAnalysisScreen(word: SanskritText('gamyawe')),
        sam: _found(EngineId.samsaadhanii, [_a('gam', FeatureValue.masculine, 'puM')]),
        her: _found(EngineId.heritage, [
          _a('gam', FeatureValue.masculine, 'm.'),
          _a('gamyawA', FeatureValue.feminine, 'f.'),
        ]),
      );
      expect(find.byKey(const Key('banner-differ')), findsOneWidget);
      expect(find.text('The engines differ'), findsOneWidget);
      expect(find.byType(Table), findsOneWidget);
      expect(find.text('Only in Heritage'), findsOneWidget);
      expect(find.text('Only in Samsaadhanii'), findsNothing);
      expect(find.text('gamyawA'), findsNothing);
      expect(find.text('gamyatā'), findsOneWidget);
    });

    testWidgets('the same lemma with a different value is one block with the '
        'row marked', (tester) async {
      await _pump(
        tester,
        const CompareAnalysisScreen(word: SanskritText('x')),
        sam: _found(EngineId.samsaadhanii, [_a('a', FeatureValue.masculine, 'puM')]),
        her: _found(EngineId.heritage, [_a('a', FeatureValue.neuter, 'n.')]),
      );
      expect(find.text('The engines differ'), findsOneWidget);
      expect(find.byType(Table), findsOneWidget);
      expect(find.textContaining('Only in'), findsNothing);
      expect(_row(tester, 'gender').decoration, isNotNull);
    });

    testWidgets("the toggle shows each engine's own labels", (tester) async {
      await _pump(
        tester,
        const CompareAnalysisScreen(word: SanskritText('rAmaH')),
        sam: _found(EngineId.samsaadhanii, [_a('rAma', FeatureValue.masculine, 'puṃ')]),
        her: _found(EngineId.heritage, [_a('rAma', FeatureValue.masculine, 'm.')]),
      );
      // Both columns in the Settings label language first.
      expect(find.text('puṃliṅgam'), findsNWidgets(2));
      expect(find.text('m.'), findsNothing);
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(find.text('puṃ'), findsOneWidget);
      expect(find.text('m.'), findsOneWidget);
      expect(find.text('puṃliṅgam'), findsNothing);
    });

    testWidgets('labels follow the label language in both columns',
        (tester) async {
      await _pump(
        tester,
        const CompareAnalysisScreen(word: SanskritText('rAmaH')),
        sam: _found(EngineId.samsaadhanii, [_a('rAma', FeatureValue.masculine, 'puṃ')]),
        her: _found(EngineId.heritage, [_a('rAma', FeatureValue.masculine, 'm.')]),
        prefs: {'settings.labelLanguage': 'english'},
      );
      expect(find.text('masculine'), findsNWidgets(2));
    });

    testWidgets('neither found: said plainly', (tester) async {
      await _pump(tester, const CompareAnalysisScreen(word: SanskritText('xyzq')));
      expect(find.text('Neither engine found an analysis'), findsOneWidget);
    });

    testWidgets('one engine failed: no verdict, its state shown, Retry there',
        (tester) async {
      final (s, _) = await _pump(
        tester,
        const CompareAnalysisScreen(word: SanskritText('x')),
        sam: const Unreachable('timeout'),
        her: _found(EngineId.heritage, [_a('a', FeatureValue.masculine, 'm.')]),
      );
      expect(find.textContaining("Can't compare"), findsOneWidget);
      expect(find.text("Can't reach Samsaadhanii."), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();
      expect(s.calls.length, 2);
    });
  });

  group('Compare a split', () {
    Outcome<Segmentation> seg(List<Segment> s, EngineId id) =>
        Found(Segmentation(const SanskritText('x'), [Split(s)]), _src(id));

    const a = Segment(SanskritText('rAmaH'), Boundary.word);
    const b = Segment(SanskritText('vanam'), Boundary.end);

    testWidgets('the same cut agrees', (tester) async {
      final (s, h) = await _pump(
        tester,
        const CompareSplitScreen(text: SanskritText('rAmovanam')),
        samSeg: seg(const [a, b], EngineId.samsaadhanii),
        herSeg: seg(const [a, b], EngineId.heritage),
      );
      expect(s.calls, ['segment:rAmovanam:analyse']);
      expect(h.calls.first, 'segment:rAmovanam:analyse');
      expect(find.text('Both engines agree'), findsOneWidget);
      expect(find.text('rāmaḥ'), findsNWidgets(2));
    });

    testWidgets('a different cut differs', (tester) async {
      await _pump(
        tester,
        const CompareSplitScreen(text: SanskritText('rAmovanam')),
        samSeg: seg(const [a, b], EngineId.samsaadhanii),
        herSeg: seg(const [Segment(SanskritText('rAmovanam'), Boundary.end)],
            EngineId.heritage),
      );
      expect(find.text('The engines differ'), findsOneWidget);
    });
  });
}
