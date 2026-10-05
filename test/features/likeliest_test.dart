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
import '../support/fixture_clients.dart' show SamsaadhaniiMorphFixtures;

/// Serves the captured Heritage answers: the `mode=f&fmode=n` one
/// (`likeliest_<word>.json`) for the likeliest-reading call, the analysis one
/// otherwise. Remembers the last query.
class _HeritageFixtures implements h.HeritageClient {
  Map<String, String>? query;

  @override
  Future<h.ClientResponse> get(Map<String, String> query) async {
    this.query = query;
    final kind = query['fmode'] == 'n' ? 'likeliest' : 'analysis';
    return h.ClientResponse(
        200,
        File('test/fixtures/heritage/${kind}_${query['text']}.json')
            .readAsStringSync());
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

/// The same noun in the nominative and in the accusative, and a masculine one:
/// three readings of one stem, as `vanam` has.
Analysis _vana(FeatureValue gender, FeatureValue vibhakti) => Analysis(
      lemma: const SanskritText('vana'),
      wordClass: WordClass.noun,
      features: [
        Feature(FeatureKind.gender, gender, '$gender'),
        Feature(FeatureKind.vibhakti, vibhakti, '$vibhakti'),
        const Feature(FeatureKind.number, FeatureValue.singular, 'eka'),
      ],
    );

Outcome<WordAnalysis> _found(EngineId id, List<Analysis> list) =>
    Found(WordAnalysis(const SanskritText('rAmaH'), list), _src(id));

FakeEngine _sam(List<Analysis> list) => FakeEngine(
    id: EngineId.samsaadhanii,
    tasks: {Task.analyseWord},
    analysis: _found(EngineId.samsaadhanii, list));

FakeEngine _her({
  Outcome<List<Analysis>>? likeliest,
  Duration latency = Duration.zero,
}) =>
    FakeEngine(
        id: EngineId.heritage,
        tasks: {Task.analyseWord, Task.likeliestReading},
        analysis: _found(EngineId.heritage, [_verb, _noun]),
        likeliest: likeliest,
        latency: latency);

Future<void> _pump(WidgetTester tester, List<Engine> engines,
    {Map<String, Object> prefs = const {}, String word = 'rAmaH'}) async {
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
        key: UniqueKey(), home: AnalyseWordScreen(initialInput: word)),
  ));
  await tester.pumpAndSettle();
}

/// The cards, top to bottom, as `lemma` or `lemma*` for a marked one.
List<String> _cards(WidgetTester tester) => [
      for (final c in tester.widgetList<AnalysisCard>(find.byType(AnalysisCard)))
        '${c.analysis.lemma.wx}${c.mostLikely ? '*' : ''}'
            ' ${[for (final f in c.analysis.features) f.value.name].join(' ')}',
    ];

Found<List<Analysis>> _likely(List<Analysis> list) =>
    Found(list, _src(EngineId.heritage));

HeritageEngine _heritageFixtures() =>
    HeritageEngine(client: _HeritageFixtures());

void main() {
  group('Heritage: the likeliest readings', () {
    test('asks with mode=f and fmode=n', () async {
      final client = _HeritageFixtures();
      await HeritageEngine(client: client)
          .likeliestReading(const SanskritText('rAmaH'));
      expect(client.query, containsPair('mode', 'f'));
      expect(client.query, containsPair('fmode', 'n'));
      expect(client.query, containsPair('text', 'rAmaH'));
      expect(client.query, containsPair('t', 'WX'));
      expect(client.query, containsPair('st', 'f'));
    });

    Future<List<Analysis>> likely(String word) async {
      final o = await _heritageFixtures().likeliestReading(SanskritText(word));
      expect(o, isA<Found<List<Analysis>>>(), reason: word);
      return (o as Found<List<Analysis>>).value;
    }

    test('rAmaH: one analysis', () async {
      final a = await likely('rAmaH');
      expect([for (final x in a) x.lemma.wx], ['rAma']);
    });

    test('vanam: both cases of the one stem, in the server\'s order', () async {
      final a = await likely('vanam');
      expect([for (final x in a) x.lemma.wx], ['vana', 'vana']);
      expect([
        for (final x in a)
          [for (final f in x.features) f.value]
      ], [
        [FeatureValue.neuter, FeatureValue.singular, FeatureValue.accusative],
        [FeatureValue.neuter, FeatureValue.singular, FeatureValue.nominative],
      ]);
      expect(a.every((x) => x.wordClass == WordClass.noun), isTrue);
    });

    test('ucyawe: analyses from two stems', () async {
      final a = await likely('ucyawe');
      expect([for (final x in a) x.lemma.wx], ['uc', 'vac']);
      expect(a.every((x) => x.wordClass == WordClass.verb), isTrue);
    });

    test('gamyawe: the stem gamyawA, not the passive of gam', () async {
      final a = await likely('gamyawe');
      expect([for (final x in a) x.lemma.wx], ['gamyawA', 'gamyawA']);
    });

    test('labhawe, not a word, is NotFound', () async {
      expect(
          await _heritageFixtures()
              .likeliestReading(const SanskritText('labhawe')),
          isA<NotFound<List<Analysis>>>());
    });

    test('Heritage offers the task; Samsaadhanii answers Unsupported', () async {
      expect(HeritageEngine().tasks, contains(Task.likeliestReading));
      expect(SamsaadhaniiEngine().tasks, isNot(contains(Task.likeliestReading)));
      expect(
          await SamsaadhaniiEngine()
              .likeliestReading(const SanskritText('rAmaH')),
          isA<Unsupported<List<Analysis>>>());
    });
  });

  group('Analyse a word marks the likeliest readings', () {
    final acc = _vana(FeatureValue.neuter, FeatureValue.accusative);
    final nom = _vana(FeatureValue.neuter, FeatureValue.nominative);
    final masc = _vana(FeatureValue.masculine, FeatureValue.nominative);

    testWidgets('a set: every card that agrees is marked and goes first, in '
        'the engine\'s order; the rest follow', (tester) async {
      // A third reading exists, and comes first from the engine.
      final her = _her(likeliest: _likely([acc, nom]));
      await _pump(tester, [_sam([masc, nom, acc]), her]);
      expect(her.calls, contains('likeliestReading:rAmaH'));
      expect(_cards(tester), [
        'vana* neuter nominative singular',
        'vana* neuter accusative singular',
        'vana masculine nominative singular',
      ]);
      expect(find.text('Most likely'), findsNWidgets(2));
      expect(find.text("Most likely according to Heritage's frequency data."),
          findsOneWidget);
    });

    testWidgets('a card from either of two stems is marked', (tester) async {
      const uc = Analysis(
          lemma: SanskritText('uc'),
          wordClass: WordClass.verb,
          features: [Feature(FeatureKind.number, FeatureValue.singular, 'sg')]);
      const vac = Analysis(
          lemma: SanskritText('vac'),
          wordClass: WordClass.verb,
          features: [Feature(FeatureKind.number, FeatureValue.singular, 'sg')]);
      await _pump(tester, [
        _sam([_other, vac, uc]),
        _her(likeliest: _likely([uc, vac])),
      ]);
      expect(_cards(tester).map((c) => c.split(' ').first),
          ['vac*', 'uc*', 'kqzNa']);
    });

    testWidgets('the engine\'s own order is kept when the selected engine is '
        'Heritage', (tester) async {
      final her = _her(likeliest: _likely([_noun]));
      await _pump(tester, [_sam([_verb, _noun]), her],
          prefs: {'settings.preferredEngine': 'heritage'});
      expect(_cards(tester).map((c) => c.split(' ').first), ['rAma*', 'rA']);
    });

    testWidgets('all cards agreeing: no tag and no note', (tester) async {
      await _pump(tester, [
        _sam([acc, nom]),
        _her(likeliest: _likely([acc, nom])),
      ]);
      expect(find.text('Most likely'), findsNothing);
      expect(find.byKey(const Key('likeliest-note')), findsNothing);
      expect(_cards(tester), [
        'vana neuter accusative singular',
        'vana neuter nominative singular',
      ]);
    });

    testWidgets('one card: no tag and no note', (tester) async {
      await _pump(tester, [
        _sam([_noun]),
        _her(likeliest: _likely([_noun])),
      ]);
      expect(_cards(tester).length, 1);
      expect(find.text('Most likely'), findsNothing);
      expect(find.byKey(const Key('likeliest-note')), findsNothing);
    });

    testWidgets('it never delays the results', (tester) async {
      final her = FakeEngine(
          id: EngineId.heritage,
          tasks: {Task.analyseWord, Task.likeliestReading},
          likeliest: _likely([_noun]),
          latency: const Duration(seconds: 5));
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final settings = await AppSettings.load();
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          Provider<EngineSet>.value(
              value: EngineSet({
            EngineId.samsaadhanii: _sam([_verb, _noun]),
            EngineId.heritage: her,
          })),
        ],
        child: const MaterialApp(home: AnalyseWordScreen(initialInput: 'rAmaH')),
      ));
      await tester.pump();
      await tester.pump();
      expect(_cards(tester).map((c) => c.split(' ').first), ['rA', 'rAma']);
      expect(find.text('Most likely'), findsNothing);
      await tester.pump(const Duration(seconds: 6));
      expect(_cards(tester).map((c) => c.split(' ').first), ['rAma*', 'rA']);
    });

    testWidgets('nothing is marked or said when Heritage does not answer',
        (tester) async {
      for (final outcome in <Outcome<List<Analysis>>>[
        const Unreachable('timeout'),
        const ServerFault('bad'),
        const NotFound(),
      ]) {
        await _pump(tester, [_sam([_verb, _noun]), _her(likeliest: outcome)]);
        expect(_cards(tester).map((c) => c.split(' ').first), ['rA', 'rAma']);
        expect(find.text('Most likely'), findsNothing);
        expect(find.byKey(const Key('likeliest-note')), findsNothing);
      }
    });

    testWidgets('nothing is marked when no card agrees', (tester) async {
      await _pump(tester, [
        _sam([_verb, _noun]),
        _her(likeliest: _likely([_other])),
      ]);
      expect(find.text('Most likely'), findsNothing);
      expect(find.byKey(const Key('likeliest-note')), findsNothing);
    });

    testWidgets('nothing happens without Heritage', (tester) async {
      await _pump(tester, [_sam([_verb, _noun])]);
      expect(find.text('Most likely'), findsNothing);
    });
  });

  group('the captured answers, on each engine', () {
    // Which cards end up marked (`*`), by lemma, with the card's own features.
    Future<List<String>> cards(WidgetTester tester, String word,
        EngineId selected) async {
      await _pump(
          tester,
          [
            SamsaadhaniiEngine(client: SamsaadhaniiMorphFixtures()),
            HeritageEngine(client: _HeritageFixtures()),
          ],
          word: word,
          prefs: {'settings.preferredEngine': selected.name});
      return [for (final c in _cards(tester)) c.split(' ').first];
    }

    testWidgets('vanam: both of its readings agree with Heritage, so none is '
        'marked, on either engine', (tester) async {
      for (final e in EngineId.values) {
        expect(await cards(tester, 'vanam', e), ['vana', 'vana'], reason: e.name);
        expect(find.text('Most likely'), findsNothing);
        expect(find.byKey(const Key('likeliest-note')), findsNothing);
      }
    });

    testWidgets('ucyawe: uc and vac are marked and go first, on either engine',
        (tester) async {
      expect(await cards(tester, 'ucyawe', EngineId.samsaadhanii),
          ['uc*', 'vac*', 'brU', 'ucyaw', 'ucyaw']);
      expect(await cards(tester, 'ucyawe', EngineId.heritage),
          ['uc*', 'vac*', 'ucyaw', 'ucyaw']);
    });

    testWidgets('gamyawe: Samsaadhanii has one card, so none is marked; with '
        'Heritage the two gamyawA readings are', (tester) async {
      expect(await cards(tester, 'gamyawe', EngineId.samsaadhanii), ['gam']);
      expect(find.text('Most likely'), findsNothing);
      expect(await cards(tester, 'gamyawe', EngineId.heritage), [
        'gamyawA*',
        'gamyawA*',
        'gam',
        'gam',
        'gamyawA',
        'gamyawA',
      ]);
    });
  });
}
