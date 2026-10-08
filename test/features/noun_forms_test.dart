import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/settings.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/features/noun_forms/noun_forms_screen.dart';
import 'package:mobile_app/features/task_frame/engine_set.dart';
import 'package:mobile_app/sanskrit/transliteration.dart' show convert;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_engine.dart';

const _nom = FeatureValue.nominative;
const _acc = FeatureValue.accusative;
const _inst = FeatureValue.instrumental;
const _dat = FeatureValue.dative;
const _sg = FeatureValue.singular;
const _du = FeatureValue.dual;

ResultSource _src() => ResultSource(
    engine: EngineId.samsaadhanii,
    program: 'noun_gen.cgi',
    time: DateTime.utc(2026, 10, 5));

const _query = NounQuery(
    stem: SanskritText('rAma'), gender: FeatureValue.masculine);

/// A full table with a few known cells: `rAmaH`, `rAmeNa`, the two forms of
/// asmad's accusative, and one empty cell (dative dual).
NounParadigm _paradigm() => NounParadigm(_query, {
      for (var v = 0; v < vibhaktiOrder.length; v++)
        for (var n = 0; n < numberOrder.length; n++)
          (vibhaktiOrder[v], numberOrder[n]): [
            SanskritText('ra${'kgcjtdpb'[v]}${'sdm'[n]}a'),
          ],
      (_nom, _sg): [const SanskritText('rAmaH')],
      (_inst, _sg): [const SanskritText('rAmeNa')],
      (_acc, _sg): [const SanskritText('mAm'), const SanskritText('mA')],
      (_dat, _du): <SanskritText>[],
    });

Derivation _derivation() => const Derivation('रामेण', [
      DerivationStep(
        sutra: '1-2-45',
        sutraText: 'अर्थवत् अधातुः अप्रत्ययः प्रातिपदिकम्',
        label: 'प्रातिपदिक',
        state: ['राम(तृतीया, पुं, एकवचन, प्रातिपदिक, root(राम), अकारान्त)'],
      ),
      DerivationStep(
        sutra: '7-1-12',
        sutraText: 'टाङसिङसाम् इनात्स्याः',
        label: 'अङ्ग_विधि',
        considered: [
          ConsideredRule('6-1-87', 'आद् गुणः'),
          ConsideredRule('6-1-101', 'अकः सवर्णे दीर्घः'),
          ConsideredRule('7-1-12', 'टाङसिङसाम् इनात्स्याः'),
        ],
        state: ['राम(तृतीया, पुं)+ इन(सुप्, आदेश(इन), विभक्ति)'],
      ),
      DerivationStep(
        sutra: '8-4-2',
        sutraText: 'अट्कुप्वाङ्नुम्व्यवाये अपि',
        label: 'त्रिपादी',
        state: ['रामेण(पद,अवसान)( रामेण(तृतीया))'],
      ),
    ]);

FakeEngine _engine({
  Outcome<NounParadigm>? paradigm,
  Outcome<Derivation>? derivation,
  Duration latency = Duration.zero,
}) =>
    FakeEngine(
      tasks: const {Task.analyseWord, Task.nounForms, Task.derivation},
      paradigm: paradigm,
      derivation: derivation,
      latency: latency,
    );

Future<void> _pump(
  WidgetTester tester,
  FakeEngine engine, {
  String input = '',
  FeatureValue? gender,
  Map<String, Object> prefs = const {},
  void Function(String)? onOpen,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'settings.displayScript': 'iast', ...prefs});
  final settings = await AppSettings.load();
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      Provider<EngineSet>.value(value: EngineSet({EngineId.samsaadhanii: engine})),
    ],
    child: MaterialApp(
      home: NounFormsScreen(
        initialInput: input,
        initialGender: gender,
        onOpenTool: onOpen == null
            ? null
            : (e, i, {gender, prefix}) => onOpen('${e.nameEn}|$i'),
      ),
    ),
  ));
  settle ? await tester.pumpAndSettle() : await tester.pump();
}

Finder _inSheet(String text) =>
    find.descendant(of: find.byType(BottomSheet), matching: find.text(text));

void main() {
  group('the screen and its inputs', () {
    testWidgets('empty: the inputs, no request, no result', (tester) async {
      final e = _engine(paradigm: Found(_paradigm(), _src()));
      await _pump(tester, e);
      expect(find.text('A noun stem'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(e.calls, isEmpty);
      expect(find.byType(Table), findsNothing);
    });

    testWidgets('a stem from Home is looked up at once, masculine by default',
        (tester) async {
      final e = _engine(paradigm: Found(_paradigm(), _src()));
      await _pump(tester, e, input: 'rAma');
      expect(e.calls, ['declineNoun:rAma:masculine:plainNoun']);
      expect(find.widgetWithText(TextField, 'rAma'), findsOneWidget);
    });

    testWidgets('a Devanagari stem is read as Devanagari', (tester) async {
      final e = _engine(paradigm: Found(_paradigm(), _src()));
      await _pump(tester, e, input: 'राम');
      expect(e.calls, ['declineNoun:rAma:masculine:plainNoun']);
    });

    testWidgets('a gender from "All forms" is pre-selected', (tester) async {
      final e = _engine(paradigm: Found(_paradigm(), _src()));
      await _pump(tester, e, input: 'naxI', gender: FeatureValue.feminine);
      expect(e.calls, ['declineNoun:naxI:feminine:plainNoun']);
      expect(find.text('strīliṅgam'), findsOneWidget);
    });

    testWidgets('only the four genders and five categories are offered',
        (tester) async {
      await _pump(tester, _engine());
      await tester.tap(find.text('puṃliṅgam'));
      await tester.pumpAndSettle();
      for (final g in [
        'puṃliṅgam', 'strīliṅgam', 'napuṃsakaliṅgam', 'aliṅgam',
      ]) {
        expect(find.text(g), findsWidgets, reason: g);
      }
      await tester.tap(find.text('aliṅgam').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('nāma'));
      await tester.pumpAndSettle();
      for (final c in ['sarvanāma', 'saṅkhyā', 'saṅkhyeya', 'pūraṇa']) {
        expect(find.text(c), findsWidgets, reason: c);
      }
    });

    testWidgets('changing gender or category looks the stem up again',
        (tester) async {
      final e = _engine(paradigm: Found(_paradigm(), _src()));
      await _pump(tester, e, input: 'asmax');
      await tester.tap(find.text('puṃliṅgam'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('aliṅgam').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('nāma'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('sarvanāma').last);
      await tester.pumpAndSettle();
      expect(e.calls, [
        'declineNoun:asmax:masculine:plainNoun',
        'declineNoun:asmax:noGender:plainNoun',
        'declineNoun:asmax:noGender:sarvanama',
      ]);
    });

    testWidgets('typing a stem and submitting looks it up', (tester) async {
      final e = _engine(paradigm: Found(_paradigm(), _src()));
      await _pump(tester, e);
      await tester.enterText(find.byType(TextField), 'vana');
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(e.calls, ['declineNoun:vana:masculine:plainNoun']);
    });

    testWidgets('no engine switch and no Compare while one engine answers',
        (tester) async {
      await _pump(tester, _engine(paradigm: Found(_paradigm(), _src())),
          input: 'rAma');
      expect(find.byKey(const Key('engine-switch')), findsNothing);
      expect(find.byKey(const Key('compare-button')), findsNothing);
      expect(find.text('Heritage'), findsNothing);
    });
  });

  group('the table', () {
    testWidgets('eight rows by three columns, headings in Sanskrit by default',
        (tester) async {
      await _pump(tester, _engine(paradigm: Found(_paradigm(), _src())),
          input: 'rAma');
      // The case names are short too; `dvi.` is both the accusative and the
      // dual.
      for (final h in [
        'pra.', 'tṛ.', 'ca.', 'pa.', 'ṣa.', 'sa.', 'saṃ.', //
        'eka.', 'bahu.',
      ]) {
        expect(find.text(h), findsOneWidget, reason: h);
      }
      expect(find.text('dvi.'), findsNWidgets(2));
      final table = tester.widget<Table>(find.byType(Table));
      expect(table.children.length, 9); // heading row and eight cases
      expect(table.children.every((r) => r.children.length == 4), isTrue);
      // The sambodhana row is last.
      final order = [
        for (final r in table.children.skip(1))
          tester
              .widget<Text>(find.descendant(
                  of: find.byWidget(r.children.first),
                  matching: find.byType(Text)))
              .data,
      ];
      expect(order, ['pra.', 'dvi.', 'tṛ.', 'ca.', 'pa.', 'ṣa.', 'sa.', 'saṃ.']);
    });

    testWidgets('headings in English when the labels are English',
        (tester) async {
      await _pump(tester, _engine(paradigm: Found(_paradigm(), _src())),
          input: 'rAma', prefs: {'settings.labelLanguage': 'english'});
      for (final h in [
        'nom.', 'acc.', 'ins.', 'dat.', 'abl.', 'gen.', 'loc.', 'voc.', //
        'sg.', 'du.', 'pl.',
      ]) {
        expect(find.text(h), findsOneWidget, reason: h);
      }
      expect(find.text('pra.'), findsNothing);
      expect(find.text('nominative'), findsNothing);
    });

    testWidgets('headings and forms follow the display script', (tester) async {
      await _pump(tester, _engine(paradigm: Found(_paradigm(), _src())),
          input: 'rAma', prefs: {'settings.displayScript': 'devanagari'});
      for (final h in ['प्र.', 'तृ.', 'च.', 'प.', 'ष.', 'स.', 'सं.']) {
        expect(find.text(h), findsOneWidget, reason: h);
      }
      expect(find.text('द्वि.'), findsNWidgets(2)); // accusative and dual
      expect(find.text('प्रथमा'), findsNothing);
      expect(find.text(convert('eka.', Script.iast, Script.devanagari)),
          findsOneWidget);
      expect(find.text('एक.'), findsOneWidget);
      expect(find.text('रामः'), findsOneWidget);
      expect(find.text('rāmaḥ'), findsNothing);
    });

    testWidgets('a screen reader gets the full case and number names',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _engine(paradigm: Found(_paradigm(), _src())),
          input: 'rAma');
      for (final full in [
        'prathamā', 'dvitīyā', 'tṛtīyā', 'caturthī', 'pañcamī', 'ṣaṣṭhī',
        'saptamī', 'sambodhanam', 'ekavacanam', 'dvivacanam', 'bahuvacanam',
      ]) {
        expect(find.bySemanticsLabel(full), findsOneWidget, reason: full);
      }
      handle.dispose();
    });

    testWidgets('forms in IAST by default', (tester) async {
      await _pump(tester, _engine(paradigm: Found(_paradigm(), _src())),
          input: 'rAma');
      expect(find.text('rāmaḥ'), findsOneWidget);
      expect(find.text('rāmeṇa'), findsOneWidget);
    });

    testWidgets('a cell with two forms shows both, one under the other',
        (tester) async {
      await _pump(tester, _engine(paradigm: Found(_paradigm(), _src())),
          input: 'rAma');
      final first = tester.getRect(find.text('mām'));
      final second = tester.getRect(find.text('mā'));
      expect(second.top, greaterThan(first.bottom - 1));
      expect((second.left - first.left).abs(), lessThan(1));
    });

    testWidgets('an empty cell shows a thin dash and does nothing',
        (tester) async {
      await _pump(tester, _engine(paradigm: Found(_paradigm(), _src())),
          input: 'rAma');
      expect(find.text('–'), findsOneWidget);
      await tester.tap(find.text('–'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('the credit line is under the table', (tester) async {
      await _pump(tester, _engine(paradigm: Found(_paradigm(), _src())),
          input: 'rAma');
      expect(find.text('From Samsaadhanii'),
          findsOneWidget);
    });

    testWidgets('Sanskrit in the table is never below 16 sp', (tester) async {
      await _pump(tester, _engine(paradigm: Found(_paradigm(), _src())),
          input: 'rAma');
      final texts = tester.widgetList<Text>(find.descendant(
          of: find.byType(Table), matching: find.byType(Text)));
      expect(texts.length, greaterThan(24));
      for (final t in texts) {
        expect(t.style!.fontSize, greaterThanOrEqualTo(16));
      }
    });
  });

  group('every result state', () {
    testWidgets('waiting', (tester) async {
      final e = _engine(
          paradigm: Found(_paradigm(), _src()),
          latency: const Duration(seconds: 1));
      await _pump(tester, e, input: 'rAma', settle: false);
      expect(find.byKey(const Key('state-waiting')), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.byKey(const Key('state-waiting')), findsNothing);
      expect(find.byType(Table), findsOneWidget);
    });

    testWidgets('not found: a message, never a table of dashes',
        (tester) async {
      await _pump(tester, _engine(paradigm: const NotFound()), input: 'xyzq');
      expect(find.byKey(const Key('state-notFound')), findsOneWidget);
      expect(find.text('No forms for xyzq'), findsOneWidget);
      expect(find.byType(Table), findsNothing);
      expect(find.text('–'), findsNothing);
    });

    testWidgets('bad input', (tester) async {
      await _pump(tester, _engine(paradigm: const BadInput('no such gender')),
          input: 'rAma');
      expect(find.byKey(const Key('state-badInput')), findsOneWidget);
      expect(find.textContaining('no such gender'), findsOneWidget);
    });

    testWidgets('server fault, with Retry', (tester) async {
      final e = _engine(paradigm: const ServerFault('bad json'));
      await _pump(tester, e, input: 'rAma');
      expect(find.byKey(const Key('state-serverFault')), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(e.calls.length, 2);
    });

    testWidgets('unreachable, with Retry', (tester) async {
      await _pump(tester, _engine(paradigm: const Unreachable('timeout')),
          input: 'rAma');
      expect(find.byKey(const Key('state-unreachable')), findsOneWidget);
      expect(find.text("Can't reach Samsaadhanii."), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('the form sheet', () {
    Future<FakeEngine> open(WidgetTester tester,
        {void Function(String)? onOpen,
        Map<String, Object> prefs = const {}}) async {
      final e = _engine(
          paradigm: Found(_paradigm(), _src()),
          derivation: Found(_derivation(), _src()));
      await _pump(tester, e, input: 'rAma', onOpen: onOpen, prefs: prefs);
      return e;
    }

    testWidgets('names the form, its case and number, with two actions',
        (tester) async {
      await open(tester, onOpen: (_) {});
      await tester.tap(find.text('rāmeṇa'));
      await tester.pumpAndSettle();
      expect(_inSheet('rāmeṇa'), findsOneWidget);
      expect(_inSheet('tṛtīyā · ekavacanam'), findsOneWidget);
      expect(_inSheet('Show derivation'), findsOneWidget);
      expect(_inSheet('Analyse this form'), findsOneWidget);
      // No "Why this form?" and no placeholder for it.
      expect(find.textContaining('Why this form'), findsNothing);
    });

    testWidgets('in English and Devanagari the sheet follows the settings',
        (tester) async {
      await open(tester, prefs: {
        'settings.labelLanguage': 'english',
        'settings.displayScript': 'devanagari',
      });
      await tester.tap(find.text('रामेण'));
      await tester.pumpAndSettle();
      expect(_inSheet('रामेण'), findsOneWidget);
      expect(_inSheet('instrumental · singular'), findsOneWidget);
    });

    testWidgets('a cell with two forms: each form opens its own sheet',
        (tester) async {
      await open(tester, onOpen: (_) {});
      await tester.tap(find.text('mā'));
      await tester.pumpAndSettle();
      expect(_inSheet('mā'), findsOneWidget);
      expect(_inSheet('dvitīyā · ekavacanam'), findsOneWidget);
    });

    testWidgets('"Analyse this form" opens Analyse a word with the form',
        (tester) async {
      final opened = <String>[];
      await open(tester, onOpen: opened.add);
      await tester.tap(find.text('rāmeṇa'));
      await tester.pumpAndSettle();
      await tester.tap(_inSheet('Analyse this form'));
      await tester.pumpAndSettle();
      expect(opened, ['Analyse a word|रामेण']);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('without a way to open tools, there is no Analyse action',
        (tester) async {
      await open(tester);
      await tester.tap(find.text('rāmeṇa'));
      await tester.pumpAndSettle();
      expect(_inSheet('Show derivation'), findsOneWidget);
      expect(_inSheet('Analyse this form'), findsNothing);
    });
  });

  group('the derivation page', () {
    Future<FakeEngine> openDerivation(WidgetTester tester,
        {Outcome<Derivation>? derivation,
        Map<String, Object> prefs = const {},
        String form = 'rāmeṇa'}) async {
      final e = _engine(
          paradigm: Found(_paradigm(), _src()),
          derivation: derivation ?? Found(_derivation(), _src()));
      await _pump(tester, e, input: 'rAma', prefs: prefs);
      await tester.tap(find.text(form));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show derivation'));
      await tester.pumpAndSettle();
      return e;
    }

    testWidgets('asks for the stem and the cell, not the form', (tester) async {
      final e = await openDerivation(tester);
      expect(e.calls.last, 'derive:rAma:masculine:instrumental:singular');
    });

    testWidgets('the form is the title; the steps are numbered in order',
        (tester) async {
      await openDerivation(tester);
      expect(find.descendant(of: find.byType(AppBar), matching: find.text('rāmeṇa')),
          findsOneWidget);
      expect(find.text('1.'), findsOneWidget);
      expect(find.text('2.'), findsOneWidget);
      expect(find.text('3.'), findsOneWidget);
      final first = tester.getTopLeft(find.text('1.')).dy;
      final second = tester.getTopLeft(find.text('2.')).dy;
      final third = tester.getTopLeft(find.text('3.')).dy;
      expect(first, lessThan(second));
      expect(second, lessThan(third));
    });

    testWidgets('each step shows number, rule text, label and state',
        (tester) async {
      await openDerivation(tester);
      expect(find.textContaining('1-2-45', findRichText: true), findsOneWidget);
      expect(find.textContaining('अर्थवत् अधातुः', findRichText: true),
          findsOneWidget);
      expect(find.text('प्रातिपदिक'), findsOneWidget);
      expect(find.text('त्रिपादी'), findsOneWidget);
      // The state lines are the engine's raw text, Latin markers and all.
      expect(find.textContaining('root(राम)'), findsOneWidget);
      expect(find.text('रामेण(पद,अवसान)( रामेण(तृतीया))'), findsOneWidget);
    });

    testWidgets('the engine text stays Devanagari under the IAST display',
        (tester) async {
      await openDerivation(tester);
      expect(find.textContaining('rāma'), findsNothing); // title is rāmeṇa only
      expect(find.text('Shown in Devanagari as Samsaadhanii provides it.'),
          findsOneWidget);
    });

    testWidgets('no note when the display script is Devanagari', (tester) async {
      await openDerivation(tester,
          prefs: {'settings.displayScript': 'devanagari'}, form: 'रामेण');
      expect(find.text('Shown in Devanagari as Samsaadhanii provides it.'),
          findsNothing);
    });

    testWidgets('considered rules are folded: "3 rules considered"',
        (tester) async {
      await openDerivation(tester);
      expect(find.text('3 rules considered'), findsOneWidget);
      expect(find.textContaining('6-1-101'), findsNothing);
      await tester.tap(find.text('3 rules considered'));
      await tester.pumpAndSettle();
      expect(find.text('6-1-87  आद् गुणः'), findsOneWidget);
      expect(find.text('6-1-101  अकः सवर्णे दीर्घः'), findsOneWidget);
    });

    testWidgets('a step with nothing considered shows no fold', (tester) async {
      await openDerivation(tester);
      expect(find.textContaining('considered'), findsOneWidget);
    });

    testWidgets('long state lines wrap and are not cut off', (tester) async {
      tester.view.physicalSize = const Size(400, 3000);
      final long = 'राम(${List.filled(30, 'तृतीया').join(', ')})';
      final e = _engine(
          paradigm: Found(_paradigm(), _src()),
          derivation: Found(
              Derivation('रामेण', [
                DerivationStep(
                    sutra: '1-2-45', sutraText: 'x', label: 'y', state: [long]),
              ]),
              _src()));
      await _pump(tester, e, input: 'rAma');
      tester.view.physicalSize = const Size(1000, 3000);
      await tester.tap(find.text('rāmeṇa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show derivation'));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(400, 3000);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final box = tester.getRect(find.text(long));
      expect(box.right, lessThanOrEqualTo(400));
      expect(box.height, greaterThan(40)); // several lines
    });

    testWidgets('the credit line is under the steps', (tester) async {
      await openDerivation(tester);
      expect(find.text('From Samsaadhanii'),
          findsOneWidget);
    });

    testWidgets('nothing found for the derivation is a message, not a blank',
        (tester) async {
      await openDerivation(tester, derivation: const NotFound());
      expect(find.byKey(const Key('state-notFound')), findsOneWidget);
      expect(find.text('Samsaadhanii has no derivation for this form.'),
          findsOneWidget);
      // No spelling hint: the form came from a table that was found.
      expect(find.textContaining('Check the spelling'), findsNothing);
      expect(find.textContaining('No derivation for'), findsNothing);
    });

    testWidgets('unreachable, with Retry', (tester) async {
      final e = await openDerivation(tester,
          derivation: const Unreachable('timeout'));
      expect(find.byKey(const Key('state-unreachable')), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(e.calls.where((c) => c.startsWith('derive:')).length, 2);
    });

    testWidgets('back returns to the table', (tester) async {
      await openDerivation(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(Table), findsOneWidget);
    });
  });
}
