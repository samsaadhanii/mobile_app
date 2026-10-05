import 'package:flutter/material.dart' hide Split;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/settings.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/engines/heritage/heritage_engine.dart';
import 'package:mobile_app/engines/samsaadhanii/samsaadhanii_engine.dart';
import 'package:mobile_app/features/analyse_word/analyse_word_screen.dart';
import 'package:mobile_app/features/analyse_word/feature_labels.dart';
import 'package:mobile_app/features/analyse_word/feature_tag.dart';
import 'package:mobile_app/features/compare/compare_analysis_screen.dart';
import 'package:mobile_app/features/join_words/join_words_screen.dart';
import 'package:mobile_app/features/krt_forms/krt_forms_screen.dart';
import 'package:mobile_app/features/task_frame/engine_set.dart';
import 'package:mobile_app/features/verb_forms/verb_forms_screen.dart';
import 'package:mobile_app/shared/data/word_lists.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_engine.dart';
import '../support/fixture_clients.dart';

const _gam = 'gam1_gamLz_BvAxiH_gawO';

SamsaadhaniiEngine _sam() => SamsaadhaniiEngine(client: SamsaadhaniiMorphFixtures());
HeritageEngine _her() => HeritageEngine(client: HeritageAnalysisFixtures());

Future<List<Analysis>> _analyses(Engine e, String word) async =>
    ((await e.analyseWord(SanskritText(word))) as Found<WordAnalysis>)
        .value
        .analyses;

Future<void> _pump(
  WidgetTester tester,
  Widget screen,
  List<Engine> engines, {
  Size size = const Size(800, 3000),
  Map<String, Object> prefs = const {},
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final settings = await AppSettings.load();
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(
          value: DhatuList.fromEntries([ListEntry(_gam, 'गम्', 'gam')])),
      ChangeNotifierProvider.value(value: PrefixList.fromEntries([])),
      Provider<EngineSet>.value(
          value: EngineSet({for (final e in engines) e.id: e})),
    ],
    child: MaterialApp(key: UniqueKey(), home: screen),
  ));
  await tester.pumpAndSettle();
}

/// The Compare table's rows by feature kind.
Map<String, TableRow> _rows(WidgetTester tester) => {
      for (final table in tester.widgetList<Table>(find.byType(Table)))
        for (final r in table.children)
          if (r.key is ValueKey) (r.key as ValueKey).value as String: r,
    };

List<String> _tagTexts(WidgetTester tester) => [
      for (final t in tester.widgetList<FeatureTag>(find.byType(FeatureTag)))
        t.label,
    ];

void main() {
  group('the order of feature tags', () {
    test('is the same for both engines on rAmaH', () async {
      for (final word in ['rAmaH', 'gamyawe']) {
        for (final e in [_sam(), _her()]) {
          for (final a in await _analyses(e, word)) {
            final kinds = [for (final f in orderedFeatures(a)) f.kind];
            final order = featureKindOrder(a.wordClass);
            final ranks = [for (final k in kinds) order.indexOf(k)];
            expect(ranks, orderedEquals([...ranks]..sort()),
                reason: '$word ${e.id.name} ${a.lemma.wx}: $kinds');
          }
        }
      }
      // The verb reading of rAmaH, as each engine sends it.
      final sam = (await _analyses(_sam(), 'rAmaH')).first;
      final her = (await _analyses(_her(), 'rAmaH')).first;
      expect([for (final f in sam.features) f.kind],
          isNot([for (final f in her.features) f.kind]));
      List<FeatureKind> shared(Analysis a) => [
            for (final f in orderedFeatures(a))
              if (f.kind != FeatureKind.prayoga) f.kind,
          ];
      expect(shared(sam), shared(her));
      expect(shared(sam), [
        FeatureKind.lakara,
        FeatureKind.person,
        FeatureKind.number,
        FeatureKind.pada,
        FeatureKind.gana,
      ]);
      // The noun: gender, case, number.
      final noun = (await _analyses(_her(), 'rAmaH')).last;
      expect([for (final f in orderedFeatures(noun)) f.kind],
          [FeatureKind.gender, FeatureKind.vibhakti, FeatureKind.number]);
    });

    test('verbs, participles and unknown kinds', () {
      Feature f(FeatureKind k) => Feature(k, FeatureValue.unknown, '$k');
      List<FeatureKind> order(WordClass c, List<FeatureKind> kinds) => [
            for (final x in orderedFeatures(
                Analysis(lemma: const SanskritText('x'), wordClass: c,
                    features: [for (final k in kinds) f(k)])))
              x.kind,
          ];
      expect(
          order(WordClass.verb, [
            FeatureKind.gana,
            FeatureKind.pada,
            FeatureKind.unknown,
            FeatureKind.number,
            FeatureKind.person,
            FeatureKind.lakara,
            FeatureKind.prayoga,
            FeatureKind.sanadi,
          ]),
          [
            FeatureKind.sanadi,
            FeatureKind.prayoga,
            FeatureKind.lakara,
            FeatureKind.person,
            FeatureKind.number,
            FeatureKind.pada,
            FeatureKind.gana,
            FeatureKind.unknown,
          ]);
      expect(
          order(WordClass.participle, [
            FeatureKind.number,
            FeatureKind.vibhakti,
            FeatureKind.gender,
            FeatureKind.prayoga,
            FeatureKind.krtPratyaya,
          ]),
          [
            FeatureKind.krtPratyaya,
            FeatureKind.prayoga,
            FeatureKind.gender,
            FeatureKind.vibhakti,
            FeatureKind.number,
          ]);
    });

    test('the model keeps the engine\'s order', () async {
      final her = (await _analyses(_her(), 'rAmaH')).last;
      expect(her.features.first.kind, FeatureKind.gender);
      expect([for (final f in her.features) f.kind],
          [FeatureKind.gender, FeatureKind.number, FeatureKind.vibhakti]);
    });

    testWidgets('on screen, a card shows the same tags for both engines',
        (tester) async {
      Future<List<String>> tags(Engine e) async {
        await _pump(
            tester, const AnalyseWordScreen(initialInput: 'rAmaH'), [e],
            prefs: {'settings.preferredEngine': e.id.name});
        return _tagTexts(tester);
      }

      final sam = await tags(_sam());
      final her = await tags(_her());
      // The noun reading's tags are the same, in the same order.
      final nounTags = ['puṃliṅgam', 'prathamā', 'ekavacanam'];
      for (final tags in [sam, her]) {
        final at = tags.indexOf('puṃliṅgam');
        expect(tags.sublist(at, at + 3), nounTags);
      }
    });
  });

  group('feature tags look like tags, not buttons', () {
    testWidgets('no outline, no chip, a fill, Sanskrit not below 16 sp',
        (tester) async {
      await _pump(tester, const AnalyseWordScreen(initialInput: 'rAmaH'),
          [_sam()]);
      expect(find.byType(Chip), findsNothing);
      expect(find.byType(ActionChip), findsNothing);
      final tags = find.byType(FeatureTag);
      expect(tags, findsWidgets);
      for (final box in tester.widgetList<DecoratedBox>(
          find.descendant(of: tags, matching: find.byType(DecoratedBox)))) {
        final d = box.decoration as BoxDecoration;
        expect(d.border, isNull);
        expect(d.color, isNotNull);
        expect(d.borderRadius, isNot(BorderRadius.circular(100)));
      }
      for (final t in tester.widgetList<Text>(
          find.descendant(of: tags, matching: find.byType(Text)))) {
        expect(t.style!.fontSize, greaterThanOrEqualTo(16));
      }
    });
  });

  group('the word class follows the label language', () {
    test('Sanskrit names, shown in the display script', () {
      String sanskrit(WordClass c, Script s) =>
          wordClassLabel(c, language: LabelLanguage.sanskrit, display: s);
      expect(sanskrit(WordClass.noun, Script.devanagari), 'नाम');
      expect(sanskrit(WordClass.verb, Script.devanagari), 'क्रिया');
      expect(sanskrit(WordClass.participle, Script.devanagari), 'कृदन्तम्');
      expect(sanskrit(WordClass.indeclinable, Script.devanagari), 'अव्ययम्');
      expect(sanskrit(WordClass.compoundMember, Script.devanagari),
          'समासपदम्');
      expect(sanskrit(WordClass.verb, Script.iast), 'kriyā');
      expect(sanskrit(WordClass.other, Script.devanagari), 'other');
    });

    test('English names never convert', () {
      for (final c in WordClass.values) {
        expect(
            wordClassLabel(c,
                language: LabelLanguage.english, display: Script.devanagari),
            c.english);
      }
      expect(WordClass.compoundMember.english, 'compound member');
    });

    testWidgets('on a card, in both languages', (tester) async {
      await _pump(tester, const AnalyseWordScreen(initialInput: 'rAmaH'),
          [_sam()]);
      expect(find.text('nāma'), findsOneWidget);
      expect(find.text('kriyā'), findsOneWidget);
      await _pump(tester, const AnalyseWordScreen(initialInput: 'rAmaH'),
          [_sam()],
          prefs: {'settings.labelLanguage': 'english'});
      expect(find.text('noun'), findsOneWidget);
      expect(find.text('verb'), findsOneWidget);
    });
  });

  group('Compare is a table per reading', () {
    testWidgets('rAmaH: two blocks; the prayoga row has a dash under '
        'Heritage; no row is marked', (tester) async {
      await _pump(tester, const CompareAnalysisScreen(word: SanskritText('rAmaH')),
          [_sam(), _her()]);
      expect(find.byType(Table), findsNWidgets(2));
      expect(find.textContaining('Only in'), findsNothing);
      expect(find.byKey(const Key('banner-agree')), findsOneWidget);

      final rows = tester.widgetList<Table>(find.byType(Table)).expand((t) => t.children);
      final marked = rows.where((r) => r.decoration != null);
      expect(marked, isEmpty);

      final prayoga = _rows(tester)['row-prayoga']!;
      final cells = prayoga.children;
      expect((cells[1] as Padding).child, isA<Text>());
      expect(((cells[1] as Padding).child as Text).data, 'kartari');
      expect(((cells[2] as Padding).child as Text).data, '–');
      expect(find.byKey(const Key('no-value')), findsWidgets);

      // The rows follow the fixed order, with a heading row first.
      final kinds = [
        for (final r in tester.widgetList<Table>(find.byType(Table)).first.children)
          if (r.key != null) (r.key as ValueKey).value,
      ];
      expect(kinds, [
        'row-prayoga',
        'row-lakara',
        'row-person',
        'row-number',
        'row-pada',
        'row-gana',
      ]);
      expect(find.text('From Samsaadhanii, University of Hyderabad'),
          findsOneWidget);
      expect(find.text('From the Sanskrit Heritage Platform, Inria'),
          findsOneWidget);
    });

    testWidgets('gamyawe: the unpaired Heritage readings are under "Only in '
        'Heritage"', (tester) async {
      await _pump(tester, const CompareAnalysisScreen(word: SanskritText('gamyawe')),
          [_sam(), _her()]);
      expect(find.byKey(const Key('banner-differ')), findsOneWidget);
      expect(find.byType(Table), findsOneWidget);
      expect(find.text('Only in Heritage'), findsOneWidget);
      expect(find.text('Only in Samsaadhanii'), findsNothing);
      // The other verb reading (a causative) and the four noun readings.
      expect(find.byType(Card), findsNWidgets(1 + 5));
      expect(find.text('gamyatā'), findsNWidgets(4));
    });

    testWidgets('own labels show each engine\'s original text', (tester) async {
      await _pump(tester, const CompareAnalysisScreen(word: SanskritText('rAmaH')),
          [_sam(), _her()]);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('puṃ'), findsOneWidget);
      expect(find.text('m.'), findsOneWidget);
    });

    for (final width in [360.0, 320.0]) {
      testWidgets('fits $width dp: no overflow, nothing wider than the screen',
          (tester) async {
        await _pump(
            tester,
            const CompareAnalysisScreen(word: SanskritText('rAmaH')),
            [_sam(), _her()],
            size: Size(width, 2400),
            prefs: {'settings.displayScript': 'devanagari'});
        expect(tester.takeException(), isNull);
        for (final t in tester.widgetList<Table>(find.byType(Table))) {
          expect(tester.getSize(find.byWidget(t)).width, lessThanOrEqualTo(width));
        }
        expect(find.byType(Scrollable).evaluate().length, 1); // vertical only
      });
    }
  });

  group('a clear action on every tool', () {
    testWidgets('a text screen: the x clears the input and the result, and '
        'the examples return', (tester) async {
      final engine = FakeEngine(tasks: {Task.analyseWord});
      await _pump(tester, const AnalyseWordScreen(), [engine]);
      expect(find.byTooltip('Clear'), findsNothing);
      await tester.enterText(find.byType(TextField), 'rAmaH');
      await tester.pump();
      expect(find.byTooltip('Clear'), findsOneWidget);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('examples')), findsNothing);
      await tester.tap(find.byTooltip('Clear'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty);
      expect(find.byKey(const Key('examples')), findsOneWidget);
      expect(find.byTooltip('Clear'), findsNothing);
      expect(find.textContaining('No analysis'), findsNothing);
    });

    testWidgets('Verb forms: Clear puts the pickers back and the examples '
        'return', (tester) async {
      final engine = FakeEngine(tasks: {Task.verbForms});
      await _pump(tester, const VerbFormsScreen(), [engine]);
      expect(find.byKey(const Key('clear-input')), findsNothing);
      await tester.tap(find.byType(ActionChip).first);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('examples')), findsNothing);
      expect(find.byKey(const Key('clear-input')), findsOneWidget);
      await tester.tap(find.byKey(const Key('clear-input')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('examples')), findsOneWidget);
      expect(find.byKey(const Key('clear-input')), findsNothing);
      expect(find.text('Select a dhātu…'), findsOneWidget);
    });

    testWidgets('Kṛt forms: Clear does the same', (tester) async {
      final engine = FakeEngine(tasks: {Task.krtForms});
      await _pump(tester, const KrtFormsScreen(), [engine]);
      await tester.tap(find.byType(ActionChip).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('clear-input')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('examples')), findsOneWidget);
    });

    testWidgets('Join words: Clear empties both fields', (tester) async {
      final engine = FakeEngine(tasks: {Task.joinWords});
      await _pump(tester, const JoinWordsScreen(), [engine]);
      await tester.tap(find.byType(ActionChip).first);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('examples')), findsNothing);
      await tester.tap(find.byKey(const Key('clear-input')));
      await tester.pumpAndSettle();
      for (final f in tester.widgetList<TextField>(find.byType(TextField))) {
        expect(f.controller!.text, isEmpty);
      }
      expect(find.byKey(const Key('examples')), findsOneWidget);
    });
  });
}
