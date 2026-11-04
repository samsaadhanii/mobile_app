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
      expect(find.text('Most frequent'), findsNWidgets(2));
      expect(find.text("Most frequent according to Heritage's data."),
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
      expect(find.text('Most frequent'), findsNothing);
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
      expect(find.text('Most frequent'), findsNothing);
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
      expect(find.text('Most frequent'), findsNothing);
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
        expect(find.text('Most frequent'), findsNothing);
        expect(find.byKey(const Key('likeliest-note')), findsNothing);
      }
    });

    testWidgets('nothing is marked when no card agrees', (tester) async {
      await _pump(tester, [
        _sam([_verb, _noun]),
        _her(likeliest: _likely([_other])),
      ]);
      expect(find.text('Most frequent'), findsNothing);
      expect(find.byKey(const Key('likeliest-note')), findsNothing);
    });

    testWidgets('nothing happens without Heritage', (tester) async {
      await _pump(tester, [_sam([_verb, _noun])]);
      expect(find.text('Most frequent'), findsNothing);
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
        expect(find.text('Most frequent'), findsNothing);
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
      expect(find.text('Most frequent'), findsNothing);
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

  group('a compound typed into Analyse a word (U29)', () {
    // The ways Heritage split rAmAlayaH, in its order.
    const ways = [
      ['rAma', 'AlayaH'],
      ['rAma', 'alayaH'],
      ['rAmA', 'AlayaH'],
      ['rAmA', 'layaH'],
      ['rAmA', 'alayaH'],
    ];

    Future<WordAnalysis> heritage(String word) async {
      final o = await _heritageFixtures().analyseWord(SanskritText(word));
      expect(o, isA<Found<WordAnalysis>>(), reason: word);
      return (o as Found<WordAnalysis>).value;
    }

    test('Heritage: five ways to split, in its order, each part with readings',
        () async {
      final c = (await heritage('rAmAlayaH')).compound!;
      expect([
        for (final s in c.candidates) [for (final g in s.segments) g.text.wx]
      ], ways);
      for (final s in c.candidates) {
        expect(s.segments.first.after, Boundary.compound);
        expect(s.segments.last.after, Boundary.end);
        expect(s.analyses, hasLength(2));
        // Every part has readings: no slot is empty.
        expect(s.analyses!.every((a) => a is Found<WordAnalysis>), isTrue);
      }
      // rAma-AlayaH: rAma as a compound member, AlayaH as Alaya and as Ali.
      final first = c.candidates.first.analyses!;
      expect((first[0] as Found<WordAnalysis>).value.analyses.single.wordClass,
          WordClass.compoundMember);
      expect([
        for (final a in (first[1] as Found<WordAnalysis>).value.analyses)
          a.lemma.wx
      ], ['Alaya', 'Ali', 'Ali']);
      // alayaH (rAma-alayaH) has the readings of ali.
      final second = c.candidates[1].analyses!;
      expect(
          (second[1] as Found<WordAnalysis>)
              .value
              .analyses
              .every((a) => a.lemma.wx == 'ali'),
          isTrue);
    });

    test('the flat list of readings is still there', () async {
      final a = await heritage('rAmAlayaH');
      expect(a.analyses.length, 9);
    });

    test('one segment: no compound (rAmaH)', () async {
      final a = await heritage('rAmaH');
      expect(a.compound, isNull);
      expect(a.alsoWhole, isFalse);
    });

    test('rAmAlayaH: every way splits, so the cards are the flat list (U29b)',
        () async {
      final a = await heritage('rAmAlayaH');
      expect(a.alsoWhole, isFalse);
      expect(a.analyses.length, 9);
    });

    test('gamayawi: read whole and split (U29b)', () async {
      final a = await heritage('gamayawi');
      expect(a.alsoWhole, isTrue);
      // The whole-word readings only: no compound member, no yawi.
      expect(a.analyses.map((x) => x.wordClass),
          isNot(contains(WordClass.compoundMember)));
      expect(a.analyses.map((x) => x.lemma.wx).toSet(), {'gam', 'gamayaw'});
      // One way below them.
      final ways = a.compound!.candidates;
      expect([for (final s in ways) [for (final g in s.segments) g.text.wx]],
          [
        ['gama', 'yawi']
      ]);
      final parts = ways.single.analyses!;
      expect(
          (parts[0] as Found<WordAnalysis>).value.analyses.single.wordClass,
          WordClass.compoundMember);
      expect((parts[1] as Found<WordAnalysis>).value.analyses, isNotEmpty);
    });

    test('agacCaw: the whole word and one way, aga-Caw (U29b)', () async {
      final a = await heritage('agacCaw');
      expect(a.alsoWhole, isTrue);
      expect(a.analyses, hasLength(1));
      expect(a.compound!.candidates, hasLength(1));
    });

    test('Samsaadhanii gives nothing for rAmAlayaH today', () async {
      final o = await SamsaadhaniiEngine(client: SamsaadhaniiMorphFixtures())
          .analyseWord(const SanskritText('rAmAlayaH'));
      expect(o, isA<NotFound<WordAnalysis>>());
    });

    Future<void> open(WidgetTester tester, String word,
        {List<String>? opened, Map<String, Object> prefs = const {}}) async {
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({
        'settings.preferredEngine': 'heritage',
        'settings.displayScript': 'iast',
        ...prefs,
      });
      final settings = await AppSettings.load();
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          Provider<EngineSet>.value(
              value: EngineSet({
            EngineId.samsaadhanii:
                SamsaadhaniiEngine(client: SamsaadhaniiMorphFixtures()),
            EngineId.heritage: HeritageEngine(client: _HeritageFixtures()),
          })),
        ],
        child: MaterialApp(
            home: AnalyseWordScreen(
                initialInput: word,
                onOpenTool: opened == null
                    ? null
                    : (e, input, {gender, prefix}) => opened.add(input))),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('five rows under the compound heading, not nine cards',
        (tester) async {
      final opened = <String>[];
      await open(tester, 'rAmAlayaH', opened: opened);
      expect(find.byType(AnalysisCard), findsNothing);
      expect(find.text('samāsaḥ'), findsOneWidget);
      for (var i = 0; i < 5; i++) {
        expect(find.byKey(Key('compound-way-$i')), findsOneWidget);
      }
      expect(find.byKey(const Key('compound-way-5')), findsNothing);
      // The thin hyphen joins the parts of a row, as in Split.
      expect(find.text('‐'), findsNWidgets(5));
      // Tappable as in Split: a part opens Analyse a word on it.
      await tester.tap(find.descendant(
          of: find.byKey(const Key('compound-way-0')),
          matching: find.text('rāma').first));
      expect(opened, ['राम']);
    });

    testWidgets('"Read as a compound" with English labels', (tester) async {
      await open(tester, 'rAmAlayaH',
          prefs: {'settings.labelLanguage': 'english'});
      expect(find.text('Read as a compound'), findsOneWidget);
    });

    testWidgets('which way is tagged follows Heritage\'s likeliest reading',
        (tester) async {
      await open(tester, 'rAmAlayaH');
      // Recorded as it is today: see the report.
      final tagged = [
        for (var i = 0; i < 5; i++)
          if (find
              .descendant(
                  of: find.byKey(Key('compound-way-$i')),
                  matching: find.text('Most frequent'))
              .evaluate()
              .isNotEmpty)
            i
      ];
      expect(tagged, [0]);
    });

    testWidgets('gamayawi: the whole-word cards, then one way below them',
        (tester) async {
      await open(tester, 'gamayawi');
      // Cards for the whole word only: no compound-member card.
      final cards = tester.widgetList<AnalysisCard>(find.byType(AnalysisCard));
      expect(cards, isNotEmpty);
      expect(cards.every((c) => c.analysis.wordClass != WordClass.compoundMember),
          isTrue);
      expect(find.text('Can also be read as a compound'), findsNothing);
      expect(find.text('samāsarūpeṇāpi paṭhyate'), findsOneWidget);
      expect(find.byKey(const Key('compound-way-0')), findsOneWidget);
      expect(find.byKey(const Key('compound-way-1')), findsNothing);
      // The way is below the cards.
      expect(tester.getTopLeft(find.byKey(const Key('compound-way-0'))).dy,
          greaterThan(tester.getBottomLeft(find.byType(AnalysisCard).last).dy));
      // The word-class border and the hyphen join, as in U29.
      expect(find.text('‐'), findsOneWidget);
    });

    testWidgets('gamayawi with English labels: "Can also be read as a compound"',
        (tester) async {
      await open(tester, 'gamayawi',
          prefs: {'settings.labelLanguage': 'english'});
      expect(find.text('Can also be read as a compound'), findsOneWidget);
    });

    testWidgets('rAmAlayaH is unchanged: the compound view only, no cards',
        (tester) async {
      await open(tester, 'rAmAlayaH');
      expect(find.byType(AnalysisCard), findsNothing);
      expect(find.text('samāsaḥ'), findsOneWidget);
      expect(find.byKey(const Key('compound-way-4')), findsOneWidget);
    });

    testWidgets('rAmaH on Heritage is as before: cards', (tester) async {
      await open(tester, 'rAmaH');
      expect(find.byKey(const Key('compound-heading')), findsNothing);
      expect(find.byType(AnalysisCard), findsWidgets);
    });
  });
}
