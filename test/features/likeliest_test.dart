import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/settings.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/engines/heritage/client.dart' as h;
import 'package:mobile_app/engines/heritage/heritage_engine.dart';
import 'package:mobile_app/engines/samsaadhanii/samsaadhanii_engine.dart';
import 'package:mobile_app/features/analyse_word/analyse_word_screen.dart';
import 'package:mobile_app/features/analyse_word/analysis_card.dart';
import 'package:mobile_app/features/task_frame/engine_set.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_engine.dart';

/// Serves the captured `mode=f&fmode=n` answer and remembers the query.
class _LikeliestFixture implements h.HeritageClient {
  Map<String, String>? query;
  final String file;

  _LikeliestFixture([this.file = 'likeliest_rAmaH']);

  @override
  Future<h.ClientResponse> get(Map<String, String> query) async {
    this.query = query;
    return h.ClientResponse(
        200, File('test/fixtures/heritage/$file.json').readAsStringSync());
  }
}

ResultSource _src(EngineId id) =>
    ResultSource(engine: id, program: 'p', time: DateTime.utc(2026, 10, 5));

const _verb = Analysis(
  lemma: SanskritText('rA'),
  wordClass: WordClass.verb,
  features: [
    Feature(FeatureKind.lakara, FeatureValue.lat, 'pr.'),
    Feature(FeatureKind.number, FeatureValue.plural, 'pl.'),
  ],
);

const _noun = Analysis(
  lemma: SanskritText('rAma'),
  wordClass: WordClass.noun,
  features: [
    Feature(FeatureKind.gender, FeatureValue.masculine, 'puM'),
    Feature(FeatureKind.vibhakti, FeatureValue.nominative, '1'),
    Feature(FeatureKind.number, FeatureValue.singular, 'eka'),
  ],
);

const _other = Analysis(lemma: SanskritText('kqzNa'), wordClass: WordClass.noun);

Outcome<WordAnalysis> _found(EngineId id, List<Analysis> list) =>
    Found(WordAnalysis(const SanskritText('rAmaH'), list), _src(id));

FakeEngine _sam(List<Analysis> list) => FakeEngine(
    id: EngineId.samsaadhanii,
    tasks: {Task.analyseWord},
    analysis: _found(EngineId.samsaadhanii, list));

FakeEngine _her({
  Outcome<Analysis>? likeliest,
  Duration latency = Duration.zero,
}) =>
    FakeEngine(
        id: EngineId.heritage,
        tasks: {Task.analyseWord, Task.likeliestReading},
        analysis: _found(EngineId.heritage, [_verb, _noun]),
        likeliest: likeliest,
        latency: latency);

Future<void> _pump(WidgetTester tester, List<FakeEngine> engines,
    {Map<String, Object> prefs = const {}}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final settings = await AppSettings.load();
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      Provider<EngineSet>.value(
          value: EngineSet({for (final e in engines) e.id: e})),
    ],
    child: MaterialApp(
        key: UniqueKey(),
        home: const AnalyseWordScreen(initialInput: 'rAmaH')),
  ));
  await tester.pump();
  await tester.pump();
}

/// The lemmas of the cards, top to bottom.
List<String> _lemmas(WidgetTester tester) => [
      for (final c in tester.widgetList<AnalysisCard>(find.byType(AnalysisCard)))
        c.analysis.lemma.wx,
    ];

void main() {
  group('Heritage: the likeliest reading', () {
    test('asks with mode=f and fmode=n, and returns the one analysis', () async {
      final client = _LikeliestFixture();
      final outcome = await HeritageEngine(client: client)
          .likeliestReading(const SanskritText('rAmaH'));
      expect(client.query, containsPair('mode', 'f'));
      expect(client.query, containsPair('fmode', 'n'));
      expect(client.query, containsPair('text', 'rAmaH'));
      expect(client.query, containsPair('t', 'WX'));
      final a = (outcome as Found<Analysis>).value;
      expect(a.lemma.wx, 'rAma');
      expect(a.wordClass, WordClass.noun);
      expect([for (final f in a.features) f.value], [
        FeatureValue.masculine,
        FeatureValue.singular,
        FeatureValue.nominative,
      ]);
      expect(outcome.source.engine, EngineId.heritage);
    });

    test('an answer with no reading is NotFound', () async {
      final outcome = await HeritageEngine(client: _LikeliestFixture('analysis_xyzq'))
          .likeliestReading(const SanskritText('xyzq'));
      expect(outcome, isA<NotFound<Analysis>>());
    });

    test('Heritage offers the task; Samsaadhanii answers Unsupported', () async {
      expect(HeritageEngine().tasks, contains(Task.likeliestReading));
      expect(SamsaadhaniiEngine().tasks, isNot(contains(Task.likeliestReading)));
      expect(
          await SamsaadhaniiEngine()
              .likeliestReading(const SanskritText('rAmaH')),
          isA<Unsupported<Analysis>>());
    });
  });

  group('Analyse a word marks the likeliest reading', () {
    testWidgets('the agreeing card moves to the top, is tagged, and a line '
        'says where it comes from', (tester) async {
      final her = _her(likeliest: Found(_noun, _src(EngineId.heritage)));
      await _pump(tester, [_sam([_verb, _noun, _other]), her]);
      expect(her.calls, contains('likeliestReading:rAmaH'));
      // Samsaadhanii's order was rA, rAma, kqzNa.
      expect(_lemmas(tester), ['rAma', 'rA', 'kqzNa']);
      expect(find.text('Most likely'), findsOneWidget);
      expect(
          tester.widget<AnalysisCard>(find.byType(AnalysisCard).first).mostLikely,
          isTrue);
      expect(find.byKey(const Key('likeliest-note')), findsOneWidget);
      expect(find.text("Most likely reading according to Heritage's frequency data."),
          findsOneWidget);
    });

    testWidgets('it works when Heritage itself is the selected engine',
        (tester) async {
      final her = _her(likeliest: Found(_noun, _src(EngineId.heritage)));
      await _pump(tester, [_sam([_verb, _noun]), her],
          prefs: {'settings.preferredEngine': 'heritage'});
      expect(_lemmas(tester), ['rAma', 'rA']);
      expect(find.text('Most likely'), findsOneWidget);
    });

    testWidgets('it never delays the results', (tester) async {
      final her = _her(
          likeliest: Found(_noun, _src(EngineId.heritage)),
          latency: const Duration(seconds: 5));
      await _pump(tester, [_sam([_verb, _noun]), her]);
      // Samsaadhanii's answer is on screen, unmarked, while Heritage waits.
      expect(_lemmas(tester), ['rA', 'rAma']);
      expect(find.text('Most likely'), findsNothing);
      await tester.pump(const Duration(seconds: 6));
      expect(_lemmas(tester), ['rAma', 'rA']);
      expect(find.text('Most likely'), findsOneWidget);
    });

    testWidgets('nothing is marked or said when Heritage does not answer',
        (tester) async {
      for (final outcome in <Outcome<Analysis>>[
        const Unreachable('timeout'),
        const ServerFault('bad'),
        const NotFound(),
      ]) {
        await _pump(tester, [_sam([_verb, _noun]), _her(likeliest: outcome)]);
        expect(_lemmas(tester), ['rA', 'rAma']);
        expect(find.text('Most likely'), findsNothing);
        expect(find.byKey(const Key('likeliest-note')), findsNothing);
      }
    });

    testWidgets('nothing is marked when no card agrees', (tester) async {
      await _pump(tester, [
        _sam([_verb, _noun]),
        _her(likeliest: Found(_other, _src(EngineId.heritage))),
      ]);
      expect(_lemmas(tester), ['rA', 'rAma']);
      expect(find.text('Most likely'), findsNothing);
      expect(find.byKey(const Key('likeliest-note')), findsNothing);
    });

    testWidgets('nothing happens without Heritage', (tester) async {
      await _pump(tester, [_sam([_verb, _noun])]);
      expect(_lemmas(tester), ['rA', 'rAma']);
      expect(find.text('Most likely'), findsNothing);
    });
  });
}
