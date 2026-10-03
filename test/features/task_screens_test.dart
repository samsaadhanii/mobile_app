import 'package:flutter/material.dart' hide Split;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/settings.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/features/analyse_word/analyse_word_screen.dart';
import 'package:mobile_app/features/split/split_screen.dart';
import 'package:mobile_app/features/task_frame/engine_set.dart';
import 'package:mobile_app/features/task_frame/outcome_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_engine.dart';

ResultSource _src(EngineId id) =>
    ResultSource(engine: id, program: 'p', time: DateTime.utc(2026, 10, 4));

Analysis _rama({List<Feature>? features}) => Analysis(
      lemma: const SanskritText('rAma'),
      wordClass: WordClass.noun,
      features: features ??
          const [
            Feature(FeatureKind.gender, FeatureValue.masculine, 'puM'),
            Feature(FeatureKind.vibhakti, FeatureValue.nominative, '1'),
            Feature(FeatureKind.number, FeatureValue.singular, 'eka'),
          ],
    );

Outcome<WordAnalysis> _found(EngineId id, [List<Analysis>? list]) => Found(
    WordAnalysis(const SanskritText('rAmaH'), list ?? [_rama()]), _src(id));

FakeEngine _engine(EngineId id,
        {Outcome<WordAnalysis>? analysis,
        Outcome<Segmentation>? segmentation,
        Outcome<Segmentation>? plain,
        Duration latency = Duration.zero,
        Set<Task> tasks = const {Task.analyseWord, Task.splitText}}) =>
    FakeEngine(
      id: id,
      tasks: tasks,
      analysis: analysis,
      segmentation: segmentation,
      segmentationPlain: plain,
      latency: latency,
    );

Future<void> _pump(
  WidgetTester tester,
  Widget screen,
  List<FakeEngine> engines, {
  Map<String, Object> prefs = const {},
}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final settings = await AppSettings.load();
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      Provider<EngineSet>.value(value: EngineSet({for (final e in engines) e.id: e})),
    ],
    child: MaterialApp(key: UniqueKey(), home: screen),
  ));
  await tester.pump();
}

bool _hasText(String t) => find.textContaining(t, findRichText: true).evaluate().isNotEmpty;

void main() {
  group('every result state of the task frame', () {
    testWidgets('waiting, then found, with the credit line', (tester) async {
      final sam = _engine(EngineId.samsaadhanii,
          analysis: _found(EngineId.samsaadhanii),
          latency: const Duration(seconds: 1));
      await _pump(tester, const AnalyseWordScreen(initialInput: 'rAmaH'), [sam]);
      expect(find.byKey(const Key('state-waiting')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.byKey(const Key('state-waiting')), findsNothing);
      expect(_hasText('rāma'), isTrue);
      expect(find.text('From Samsaadhanii, University of Hyderabad'), findsOneWidget);
    });

    testWidgets('not found: the wording, a hint, and the way on', (tester) async {
      final sam = _engine(EngineId.samsaadhanii);
      final heritage = _engine(EngineId.heritage, analysis: _found(EngineId.heritage));
      await _pump(tester, const AnalyseWordScreen(initialInput: 'xyzq'), [sam, heritage]);
      await tester.pump();
      expect(find.byKey(const Key('state-notFound')), findsOneWidget);
      expect(find.text('No analysis for xyzq'), findsOneWidget);
      expect(find.textContaining('Check the spelling'), findsOneWidget);
      expect(find.text('Try Heritage'), findsOneWidget);
      // No "Split it as a phrase" without a way to open another tool.
      expect(find.text('Split it as a phrase'), findsNothing);
    });

    testWidgets('not found offers "Split it as a phrase" and opens it',
        (tester) async {
      final opened = <String>[];
      await _pump(
          tester,
          AnalyseWordScreen(
              initialInput: 'xyzq',
              onOpenTool: (e, input) => opened.add('${e.nameEn}|$input')),
          [_engine(EngineId.samsaadhanii)]);
      await tester.pump();
      await tester.tap(find.text('Split it as a phrase'));
      expect(opened, ['Split and analyse|xyzq']);
    });

    testWidgets('bad input: what was wrong and what to change', (tester) async {
      final sam = _engine(EngineId.samsaadhanii,
          analysis: const BadInput('Wrong input  - Empty sanskrit input'));
      await _pump(tester, const AnalyseWordScreen(initialInput: 'rAmaH'), [sam]);
      await tester.pump();
      expect(find.byKey(const Key('state-badInput')), findsOneWidget);
      expect(find.text("Samsaadhanii can't use this input."), findsOneWidget);
      expect(find.textContaining('Empty sanskrit input'), findsOneWidget);
      expect(find.textContaining('Change the input and try again'), findsOneWidget);
    });

    testWidgets('server fault: wording, Retry asks again', (tester) async {
      final sam = _engine(EngineId.samsaadhanii,
          analysis: const ServerFault('bad json'));
      await _pump(tester, const AnalyseWordScreen(initialInput: 'rAmaH'), [sam]);
      await tester.pump();
      expect(find.byKey(const Key('state-serverFault')), findsOneWidget);
      expect(find.text("Samsaadhanii sent an answer the app can't read."),
          findsOneWidget);
      expect(sam.calls.length, 1);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();
      expect(sam.calls.length, 2);
    });

    testWidgets('unreachable: wording, Retry, and the other engine',
        (tester) async {
      final sam = _engine(EngineId.samsaadhanii,
          analysis: const Unreachable('timeout'));
      final heritage = _engine(EngineId.heritage, analysis: _found(EngineId.heritage));
      await _pump(tester, const AnalyseWordScreen(initialInput: 'rAmaH'), [sam, heritage]);
      await tester.pump();
      expect(find.byKey(const Key('state-unreachable')), findsOneWidget);
      expect(find.text("Can't reach Samsaadhanii."), findsOneWidget);
      expect(find.text('Check your connection.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Try Heritage'));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('state-unreachable')), findsNothing);
      expect(find.text('From the Sanskrit Heritage Platform, Inria'), findsOneWidget);
    });

    testWidgets('unsupported is worded, never blank', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OutcomeView<int>(
            outcome: const Unsupported(EngineId.heritage, Task.nounForms),
            engine: EngineId.heritage,
            notFoundTitle: 'x',
            builder: (_, __) => const SizedBox(),
            onRetry: () {},
          ),
        ),
      ));
      expect(find.byKey(const Key('state-unsupported')), findsOneWidget);
      expect(find.text("Heritage can't do this."), findsOneWidget);
    });

    testWidgets('no engine can answer: a message, not an empty screen',
        (tester) async {
      await _pump(tester, const AnalyseWordScreen(),
          [_engine(EngineId.heritage, tasks: const {Task.splitText})]);
      expect(find.text('No engine can do this yet.'), findsOneWidget);
    });
  });

  group('the engine switch', () {
    testWidgets('hidden when one engine can answer', (tester) async {
      await _pump(tester, const AnalyseWordScreen(initialInput: 'rAmaH'),
          [_engine(EngineId.samsaadhanii, analysis: _found(EngineId.samsaadhanii))]);
      await tester.pump();
      expect(find.byKey(const Key('engine-switch')), findsNothing);
      expect(find.byKey(const Key('compare-button')), findsNothing);
    });

    testWidgets('hidden when the other engine lacks the task', (tester) async {
      await _pump(tester, const AnalyseWordScreen(initialInput: 'rAmaH'), [
        _engine(EngineId.samsaadhanii, analysis: _found(EngineId.samsaadhanii)),
        _engine(EngineId.heritage, tasks: const {Task.splitText}),
      ]);
      await tester.pump();
      expect(find.byKey(const Key('engine-switch')), findsNothing);
    });

    testWidgets('shown for two, starts on the preferred engine, switching '
        're-runs', (tester) async {
      final sam = _engine(EngineId.samsaadhanii, analysis: _found(EngineId.samsaadhanii));
      final her = _engine(EngineId.heritage, analysis: _found(EngineId.heritage));
      await _pump(tester, const AnalyseWordScreen(initialInput: 'rAmaH'), [sam, her],
          prefs: {'settings.preferredEngine': 'heritage'});
      await tester.pump();
      expect(find.byKey(const Key('engine-switch')), findsOneWidget);
      expect(her.calls, ['analyseWord:rAmaH']);
      expect(sam.calls, isEmpty);
      expect(find.text('From the Sanskrit Heritage Platform, Inria'), findsOneWidget);

      await tester.tap(find.descendant(
          of: find.byKey(const Key('engine-switch')),
          matching: find.text('Samsaadhanii')));
      await tester.pump();
      await tester.pump();
      expect(sam.calls, ['analyseWord:rAmaH']);
      expect(find.text('From Samsaadhanii, University of Hyderabad'), findsOneWidget);
    });

    testWidgets('the Compare button names the other engine', (tester) async {
      await _pump(tester, const AnalyseWordScreen(initialInput: 'rAmaH'), [
        _engine(EngineId.samsaadhanii, analysis: _found(EngineId.samsaadhanii)),
        _engine(EngineId.heritage, analysis: _found(EngineId.heritage)),
      ]);
      await tester.pump();
      expect(find.text('Compare with Heritage'), findsOneWidget);
    });
  });

  group('Analyse a word', () {
    testWidgets('the Home input is analysed at once, in any script',
        (tester) async {
      final sam = _engine(EngineId.samsaadhanii, analysis: _found(EngineId.samsaadhanii));
      await _pump(tester, const AnalyseWordScreen(initialInput: 'रामः'), [sam]);
      await tester.pump();
      expect(sam.calls, ['analyseWord:rAmaH']);
      expect(find.widgetWithText(TextField, 'रामः'), findsOneWidget);
    });

    testWidgets('IAST input is read as IAST; only the first word is used',
        (tester) async {
      final sam = _engine(EngineId.samsaadhanii);
      await _pump(tester, const AnalyseWordScreen(initialInput: 'rāmaḥ vanam'), [sam]);
      await tester.pump();
      expect(sam.calls, ['analyseWord:rAmaH']);
    });

    testWidgets('typing and submitting runs a request', (tester) async {
      final sam = _engine(EngineId.samsaadhanii, analysis: _found(EngineId.samsaadhanii));
      await _pump(tester, const AnalyseWordScreen(), [sam]);
      expect(sam.calls, isEmpty);
      await tester.enterText(find.byType(TextField), 'vanam');
      await tester.tap(find.byTooltip('Analyse'));
      await tester.pump();
      expect(sam.calls, ['analyseWord:vanam']);
    });

    testWidgets('a card: lemma, homonym, word class, feature chips',
        (tester) async {
      final a = Analysis(
        lemma: const SanskritText('rA'),
        homonym: 1,
        wordClass: WordClass.participle,
        base: const SanskritText('gam'),
        features: const [Feature(FeatureKind.number, FeatureValue.plural, 'pl.')],
      );
      await _pump(tester, const AnalyseWordScreen(initialInput: 'x'),
          [_engine(EngineId.samsaadhanii, analysis: _found(EngineId.samsaadhanii, [a]))]);
      await tester.pump();
      expect(_hasText('rā 1'), isTrue);
      expect(find.text('participle'), findsOneWidget);
      expect(find.text('from gam'), findsOneWidget);
      expect(find.text('ekavacanam'), findsNothing);
      expect(find.text('bahuvacanam'), findsOneWidget);
    });

    testWidgets('labels follow the Settings label language', (tester) async {
      final sam = _engine(EngineId.samsaadhanii, analysis: _found(EngineId.samsaadhanii));
      await _pump(tester, const AnalyseWordScreen(initialInput: 'rAmaH'), [sam]);
      await tester.pump();
      for (final t in ['puṃliṅgam', 'prathamā', 'ekavacanam']) {
        expect(find.text(t), findsOneWidget);
      }
      expect(find.text('masculine'), findsNothing);

      await _pump(tester, const AnalyseWordScreen(initialInput: 'rAmaH'),
          [_engine(EngineId.samsaadhanii, analysis: _found(EngineId.samsaadhanii))],
          prefs: {'settings.labelLanguage': 'english'});
      await tester.pump();
      for (final t in ['masculine', 'nominative', 'singular']) {
        expect(find.text(t), findsOneWidget);
      }
      expect(find.text('puṃliṅgam'), findsNothing);
    });

    testWidgets('text follows the Settings display script', (tester) async {
      await _pump(tester, const AnalyseWordScreen(initialInput: 'rAmaH'),
          [_engine(EngineId.samsaadhanii, analysis: _found(EngineId.samsaadhanii))],
          prefs: {'settings.displayScript': 'devanagari'});
      await tester.pump();
      expect(_hasText('राम'), isTrue);
      expect(_hasText('rāma'), isFalse);
    });

    testWidgets('an unmapped label is shown as the engine wrote it',
        (tester) async {
      final a = _rama(features: const [
        Feature(FeatureKind.prayoga, FeatureValue.unknown, 'dh'),
        Feature(FeatureKind.unknown, FeatureValue.unknown, 'newkey:v'),
        Feature(FeatureKind.krtPratyaya, FeatureValue.openClass, 'śatṛ',
            text: SanskritText('Sawq')),
      ]);
      await _pump(tester, const AnalyseWordScreen(initialInput: 'x'),
          [_engine(EngineId.samsaadhanii, analysis: _found(EngineId.samsaadhanii, [a]))]);
      await tester.pump();
      expect(find.text('dh'), findsOneWidget);
      expect(find.text('newkey:v'), findsOneWidget);
      expect(find.text('śatṛ'), findsOneWidget);
    });

    testWidgets('actions: All forms and Dictionary open other tools',
        (tester) async {
      final opened = <String>[];
      await _pump(
          tester,
          AnalyseWordScreen(
              initialInput: 'rAmaH',
              onOpenTool: (e, input) => opened.add('${e.nameEn}|$input')),
          [_engine(EngineId.samsaadhanii, analysis: _found(EngineId.samsaadhanii))]);
      await tester.pump();
      await tester.tap(find.text('All forms'));
      await tester.tap(find.text('Dictionary'));
      expect(opened, ['Noun forms|राम', 'Dictionary|राम']);
    });
  });

  group('Split and analyse', () {
    Outcome<Segmentation> seg(List<Segment> segments,
            {List<Outcome<WordAnalysis>>? analyses, List<Split> more = const []}) =>
        Found(
          Segmentation(const SanskritText('x'),
              [Split(segments, analyses: analyses), ...more]),
          _src(EngineId.samsaadhanii),
        );

    const rama = Segment(SanskritText('rAma'), Boundary.compound);
    const alaya = Segment(SanskritText('AlayaH'), Boundary.end);

    testWidgets('the split as a row of words, compound parts joined by a '
        'hyphen, one analysis line per word', (tester) async {
      final analyses = <Outcome<WordAnalysis>>[
        Found(
            const WordAnalysis(SanskritText('rAma'), [
              Analysis(
                  lemma: SanskritText('rAma'), wordClass: WordClass.compoundMember),
            ]),
            _src(EngineId.samsaadhanii)),
        Found(
            WordAnalysis(const SanskritText('AlayaH'), [_rama(), _rama()]),
            _src(EngineId.samsaadhanii)),
      ];
      final sam = _engine(EngineId.samsaadhanii,
          segmentation: seg(const [rama, alaya], analyses: analyses));
      await _pump(tester, const SplitScreen(initialInput: 'rAmAlayaH'), [sam]);
      await tester.pump();
      expect(sam.calls, ['segment:rAmAlayaH:analyse']);
      expect(find.text('rāma'), findsOneWidget);
      expect(find.text('ālayaḥ'), findsOneWidget);
      expect(find.text('‐'), findsOneWidget);
      expect(_hasText('compound member'), isTrue);
      expect(_hasText('noun · puṃliṅgam · prathamā · ekavacanam (+1 more)'), isTrue);
      expect(find.text('From Samsaadhanii, University of Hyderabad'), findsOneWidget);
    });

    testWidgets('a word with no analysis says so, the rest are unaffected',
        (tester) async {
      const a = Segment(SanskritText('vanam'), Boundary.word);
      const b = Segment(SanskritText('xyzq'), Boundary.end);
      final sam = _engine(EngineId.samsaadhanii,
          segmentation: seg(const [a, b], analyses: [
            Found(WordAnalysis(const SanskritText('vanam'), [_rama()]),
                _src(EngineId.samsaadhanii)),
            const NotFound(),
            ]));
      await _pump(tester, const SplitScreen(initialInput: 'vanam xyzq'), [sam]);
      await tester.pump();
      expect(_hasText('no analysis'), isTrue);
      expect(_hasText('noun'), isTrue);
    });

    testWidgets('tapping a word opens Analyse a word for it', (tester) async {
      final opened = <String>[];
      final sam = _engine(EngineId.samsaadhanii,
          segmentation: seg(const [rama, alaya]));
      await _pump(
          tester,
          SplitScreen(
              initialInput: 'rAmAlayaH',
              onOpenTool: (e, input) => opened.add('${e.nameEn}|$input')),
          [sam]);
      await tester.pump();
      await tester.tap(find.text('ālayaḥ'));
      expect(opened, ['Analyse a word|आलयः']);
    });

    testWidgets('Heritage: "N other ways to split", folded, each its own row',
        (tester) async {
      const other1 = Split([
        Segment(SanskritText('rAma'), Boundary.word),
        Segment(SanskritText('AlayaH'), Boundary.end),
      ]);
      const other2 = Split([
        Segment(SanskritText('rAmA'), Boundary.word),
        Segment(SanskritText('layaH'), Boundary.end),
      ]);
      const best = Split([rama, alaya]);
      final her = _engine(EngineId.heritage,
          segmentation: Found(
              const Segmentation(SanskritText('x'), [best]), _src(EngineId.heritage)),
          plain: Found(
              const Segmentation(SanskritText('x'), [best, other1, other2]),
              _src(EngineId.heritage)));
      await _pump(tester, const SplitScreen(initialInput: 'rAmAlayaH'), [her]);
      await tester.pump();
      expect(her.calls, ['segment:rAmAlayaH:analyse', 'segment:rAmAlayaH']);
      expect(find.text('2 other ways to split'), findsOneWidget);
      expect(find.text('rāmā'), findsNothing); // folded
      await tester.tap(find.text('2 other ways to split'));
      await tester.pumpAndSettle();
      expect(find.text('rāmā'), findsOneWidget);
      expect(find.text('layaḥ'), findsOneWidget);
    });

    testWidgets('Samsaadhanii has no "other ways" and makes one call',
        (tester) async {
      final sam = _engine(EngineId.samsaadhanii,
          segmentation: seg(const [rama, alaya]));
      await _pump(tester, const SplitScreen(initialInput: 'rAmAlayaH'), [sam]);
      await tester.pump();
      expect(find.byKey(const Key('other-splits')), findsNothing);
      expect(sam.calls.length, 1);
    });

    testWidgets('failures use the same states', (tester) async {
      final sam = _engine(EngineId.samsaadhanii,
          segmentation: const Unreachable('timeout'));
      await _pump(tester, const SplitScreen(initialInput: 'x'), [sam]);
      await tester.pump();
      expect(find.byKey(const Key('state-unreachable')), findsOneWidget);
      final nf = _engine(EngineId.samsaadhanii);
      await _pump(tester, const SplitScreen(initialInput: 'xyzq'), [nf]);
      await tester.pump();
      expect(find.text('No split for xyzq'), findsOneWidget);
    });
  });
}
