import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/settings.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/features/task_frame/engine_set.dart';
import 'package:mobile_app/features/verb_forms/verb_forms_screen.dart';
import 'package:mobile_app/sanskrit/transliteration.dart' show convert;
import 'package:mobile_app/shared/data/word_lists.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_engine.dart';

const _gam = 'gam1_gamLz_BvAxiH_gawO';
const _gamCurAdi = 'gam2_gamLz_curAxiH_gawO';
const _paT = 'paT1_paT_BvAxiH_vyakwAyAM vAci';

const _third = FeatureValue.third;
const _second = FeatureValue.second;
const _sg = FeatureValue.singular;
const _du = FeatureValue.dual;

final _dhatus = DhatuList.fromEntries([
  ListEntry(_gam, 'गम् (गम्) गतौ भ्वादिः', 'gam (gam) gatau bhvādiḥ'),
  ListEntry(_gamCurAdi, 'गम् (गम्) गतौ चुरादिः', 'gam (gam) gatau curādiḥ'),
  ListEntry(_paT, 'पठ् (पठ्) व्यक्तायां वाचि भ्वादिः',
      'paṭh (paṭh) vyaktāyāṃ vāci bhvādiḥ'),
]);

final _prefixes = PrefixList.fromEntries([
  ListEntry('Af', 'आङ्', 'āṅ'),
  ListEntry('pra', 'प्र', 'pra'),
]);

ResultSource _src() => ResultSource(
    engine: EngineId.samsaadhanii,
    program: 'verb_gen.cgi',
    time: DateTime.utc(2026, 10, 5));

/// A WX form that is different for every pada, lakāra, person and number.
String _wx(int pada, int lakara, int person, int number) =>
    'ga${'kgcjtdpbnm'[lakara]}${'sr'[pada]}${'rst'[person]}${'kmn'[number]}a';

String _iast(String wx) => SanskritText(wx).display(Script.iast);

/// Both padas, ten lakāras each, with three known cells: `gacchati`, the two
/// forms of the imperative, and an empty cell (laṭ, second person, dual).
VerbParadigm _paradigm({
  List<FeatureValue> padas = const [
    FeatureValue.parasmaipada,
    FeatureValue.atmanepada
  ],
  VerbQuery query = const VerbQuery(root: _gam),
}) =>
    VerbParadigm(query, const SanskritText('gam(BvAxiH)'), [
      for (final pada in padas)
        PadaTables(pada, [
          for (var l = 0; l < lakaraOrder.length; l++)
            LakaraTable(lakaraOrder[l], {
              for (var p = 0; p < 3; p++)
                for (var n = 0; n < 3; n++)
                  (personOrder[p], numberOrder[n]): [
                    SanskritText(_wx(padaOrder.indexOf(pada), l, p, n)),
                  ],
              if (pada == FeatureValue.parasmaipada && l == 0) ...{
                (_third, _sg): [const SanskritText('gacCawi')],
                (_second, _du): <SanskritText>[],
              },
              if (pada == FeatureValue.parasmaipada && l == 4)
                (_third, _sg): [
                  const SanskritText('gacCawu'),
                  const SanskritText('gacCawAw'),
                ],
            }),
        ]),
    ]);

FakeEngine _engine({Outcome<VerbParadigm>? paradigm, Duration latency = Duration.zero}) =>
    FakeEngine(
      tasks: const {Task.analyseWord, Task.verbForms},
      verbParadigm: paradigm,
      latency: latency,
    );

Future<AppSettings> _pump(
  WidgetTester tester,
  FakeEngine engine, {
  String input = '',
  String? initialPrefix,
  Map<String, Object> prefs = const {},
  void Function(String)? onOpen,
  DhatuList? dhatus,
  bool settle = true,
  Size size = const Size(1000, 3000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final settings = await AppSettings.load();
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      Provider<EngineSet>.value(value: EngineSet({EngineId.samsaadhanii: engine})),
      ChangeNotifierProvider<DhatuList>.value(value: dhatus ?? _dhatus),
      ChangeNotifierProvider<PrefixList>.value(value: _prefixes),
    ],
    child: MaterialApp(
      home: VerbFormsScreen(
        initialInput: input,
        initialPrefix: initialPrefix,
        onOpenTool: onOpen == null
            ? null
            : (e, i, {gender, prefix}) =>
                onOpen('${e.nameEn}|$i${prefix == null ? '' : '|$prefix'}'),
      ),
    ),
  ));
  settle ? await tester.pumpAndSettle() : await tester.pump();
  return settings;
}

Finder _inSheet(String text) =>
    find.descendant(of: find.byType(BottomSheet), matching: find.text(text));

Future<void> _pick(WidgetTester tester, String field, String row) async {
  await tester.tap(find.text(field));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ListTile, row));
  await tester.pumpAndSettle();
}

List<String> _verbCalls(FakeEngine e) =>
    [for (final c in e.calls) if (c.startsWith('conjugateVerb')) c];

void main() {
  group('the inputs', () {
    testWidgets('empty: two pickers and the voice, no request, no result',
        (tester) async {
      final e = _engine(paradigm: Found(_paradigm(), _src()));
      await _pump(tester, e);
      expect(find.text('Dhātu'), findsOneWidget);
      expect(find.text('Select a dhātu…'), findsOneWidget);
      expect(find.text('Prefix'), findsOneWidget);
      expect(find.text('No prefix'), findsOneWidget);
      expect(find.byKey(const Key('prayoga-switch')), findsOneWidget);
      for (final p in ['kartari', 'karmaṇi', 'ṇijanta']) {
        expect(find.text(p), findsOneWidget, reason: p);
      }
      expect(e.calls, isEmpty);
      expect(find.byType(Table), findsNothing);
    });

    testWidgets('voices in English, and in Devanagari', (tester) async {
      await _pump(tester, _engine(), prefs: {'settings.labelLanguage': 'english'});
      for (final p in ['active', 'passive', 'causative']) {
        expect(find.text(p), findsOneWidget, reason: p);
      }
      await _pump(tester, _engine(),
          prefs: {'settings.displayScript': 'devanagari'});
      expect(find.text(convert('ṇijanta', Script.iast, Script.devanagari)),
          findsOneWidget);
    });

    testWidgets('a root typed on Home becomes the first dhātu of the list',
        (tester) async {
      final e = _engine(paradigm: Found(_paradigm(), _src()));
      await _pump(tester, e, input: 'gam');
      expect(_verbCalls(e), ['conjugateVerb:$_gam:-:kartari']);
      expect(find.text('gam (gam) gatau bhvādiḥ'), findsOneWidget);
    });

    testWidgets('a Devanagari root is read as Devanagari', (tester) async {
      final e = _engine(paradigm: Found(_paradigm(), _src()));
      await _pump(tester, e, input: 'गम्');
      expect(_verbCalls(e), ['conjugateVerb:$_gam:-:kartari']);
    });

    testWidgets('a root that is not in the list is said so, and not guessed',
        (tester) async {
      final e = _engine(paradigm: Found(_paradigm(), _src()));
      await _pump(tester, e, input: 'xyzq');
      expect(e.calls, isEmpty);
      expect(find.byKey(const Key('state-notFound')), findsOneWidget);
      expect(find.text('No forms for xyzq'), findsOneWidget);
      expect(find.text('Pick the root from the list.'), findsOneWidget);
      expect(find.textContaining('Check the spelling'), findsNothing);
      expect(find.textContaining('From Samsaadhanii'), findsNothing);
    });

    testWidgets('picking a root after that clears the message and looks it up',
        (tester) async {
      final e = _engine(paradigm: Found(_paradigm(), _src()));
      await _pump(tester, e, input: 'xyzq');
      await _pick(tester, 'Dhātu', 'paṭh (paṭh) vyaktāyāṃ vāci bhvādiḥ');
      expect(_verbCalls(e), ['conjugateVerb:$_paT:-:kartari']);
      expect(find.text('No forms for xyzq'), findsNothing);
      expect(find.byType(Table), findsNWidgets(10));
    });

    testWidgets('a prefix passed in is selected and used for the first lookup',
        (tester) async {
      final e = _engine(paradigm: Found(_paradigm(), _src()));
      await _pump(tester, e, input: 'gam', initialPrefix: 'Af');
      expect(_verbCalls(e), ['conjugateVerb:$_gam:Af:kartari']);
      expect(find.text('āṅ'), findsOneWidget); // the prefix picker shows it
      expect(find.text('No prefix'), findsNothing);
    });

    testWidgets('an exact dhātu key is taken as it is, spaces and all',
        (tester) async {
      final e = _engine(paradigm: Found(_paradigm(), _src()));
      await _pump(tester, e, input: _paT);
      expect(_verbCalls(e), ['conjugateVerb:$_paT:-:kartari']);
    });

    testWidgets('a list that is still loading is waited for', (tester) async {
      final late = DhatuList();
      final e = _engine(paradigm: Found(_paradigm(), _src()));
      await _pump(tester, e, input: 'gam', dhatus: late, settle: false);
      expect(e.calls, isEmpty);
      await tester.runAsync(late.load);
      await tester.pumpAndSettle();
      expect(_verbCalls(e).single, startsWith('conjugateVerb:gam'));
      expect(find.byType(Table), findsNWidgets(10));
    });

    testWidgets('picking a root, a prefix, "No prefix" and a voice each look it up',
        (tester) async {
      final e = _engine(paradigm: Found(_paradigm(), _src()));
      await _pump(tester, e);
      await _pick(tester, 'Dhātu', 'gam (gam) gatau bhvādiḥ');
      await _pick(tester, 'Prefix', 'āṅ');
      await _pick(tester, 'Prefix', 'No prefix');
      await tester.tap(find.text('karmaṇi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ṇijanta'));
      await tester.pumpAndSettle();
      expect(_verbCalls(e), [
        'conjugateVerb:$_gam:-:kartari',
        'conjugateVerb:$_gam:Af:kartari',
        'conjugateVerb:$_gam:-:kartari',
        'conjugateVerb:$_gam:-:karmani',
        'conjugateVerb:$_gam:-:nijanta',
      ]);
    });

    testWidgets('a prefix or a voice without a root looks nothing up',
        (tester) async {
      final e = _engine(paradigm: Found(_paradigm(), _src()));
      await _pump(tester, e);
      await _pick(tester, 'Prefix', 'pra');
      await tester.tap(find.text('karmaṇi'));
      await tester.pumpAndSettle();
      expect(e.calls, isEmpty);
      // The choices are kept for when the root comes.
      await _pick(tester, 'Dhātu', 'gam (gam) gatau bhvādiḥ');
      expect(_verbCalls(e), ['conjugateVerb:$_gam:pra:karmani']);
    });

    testWidgets('no engine switch and no Compare while one engine answers',
        (tester) async {
      await _pump(tester, _engine(paradigm: Found(_paradigm(), _src())),
          input: 'gam');
      expect(find.byKey(const Key('engine-switch')), findsNothing);
      expect(find.byKey(const Key('compare-button')), findsNothing);
    });
  });

  group('the result', () {
    testWidgets('the heading, a credit line, ten lakāras as 3 by 3 tables',
        (tester) async {
      await _pump(tester, _engine(paradigm: Found(_paradigm(), _src())),
          input: 'gam');
      expect(find.text('gam(bhvādiḥ)'), findsOneWidget);
      expect(find.text('From Samsaadhanii, University of Hyderabad'),
          findsOneWidget);
      final tables = tester.widgetList<Table>(find.byType(Table)).toList();
      expect(tables.length, 10);
      for (final t in tables) {
        expect(t.children.length, 4); // number headings and three persons
        expect(t.children.every((r) => r.children.length == 4), isTrue);
      }
      for (final l in lakaraOrder) {
        expect(find.byKey(Key('lakara-${l.name}')), findsOneWidget, reason: l.name);
      }
    });

    testWidgets('headings in Sanskrit by default', (tester) async {
      await _pump(tester, _engine(paradigm: Found(_paradigm(), _src())),
          input: 'gam');
      for (final h in ['pra.', 'ma.', 'u.', 'eka.', 'dvi.', 'bahu.']) {
        expect(find.text(h), findsNWidgets(10), reason: h);
      }
      // A chip and a title for each lakāra.
      expect(find.text('laṭ'), findsNWidgets(2));
      expect(find.text('vidhiliṅ'), findsNWidgets(2));
      expect(find.text('āśīrliṅ'), findsNWidgets(2));
    });

    testWidgets('a screen reader gets the full name of each short heading',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _engine(paradigm: Found(_paradigm(), _src())),
          input: 'gam');
      for (final full in [
        'prathamapuruṣaḥ', 'madhyamapuruṣaḥ', 'uttamapuruṣaḥ', //
        'ekavacanam', 'dvivacanam', 'bahuvacanam',
      ]) {
        expect(find.bySemanticsLabel(full), findsNWidgets(10), reason: full);
      }
      handle.dispose();
    });

    testWidgets('the full names are announced in English too', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _engine(paradigm: Found(_paradigm(), _src())),
          input: 'gam', prefs: {'settings.labelLanguage': 'english'});
      expect(find.bySemanticsLabel('third person'), findsNWidgets(10));
      expect(find.bySemanticsLabel('singular'), findsNWidgets(10));
      handle.dispose();
    });

    testWidgets('headings in English when the labels are English',
        (tester) async {
      await _pump(tester, _engine(paradigm: Found(_paradigm(), _src())),
          input: 'gam', prefs: {'settings.labelLanguage': 'english'});
      for (final h in ['3rd', '2nd', '1st', 'sg.', 'du.', 'pl.']) {
        expect(find.text(h), findsNWidgets(10), reason: h);
      }
      expect(find.text('present'), findsNWidgets(2));
      expect(find.text('optative'), findsNWidgets(2));
      expect(find.text('laṭ'), findsNothing);
    });

    testWidgets('headings and forms follow the display script', (tester) async {
      await _pump(tester, _engine(paradigm: Found(_paradigm(), _src())),
          input: 'gam', prefs: {'settings.displayScript': 'devanagari'});
      expect(find.text('गम्(भ्वादिः)'), findsOneWidget);
      expect(find.text('गच्छति'), findsOneWidget);
      expect(find.text('gacchati'), findsNothing);
      for (final h in ['प्र.', 'म.', 'उ.', 'एक.', 'द्वि.', 'बहु.']) {
        expect(find.text(h), findsNWidgets(10), reason: h);
      }
    });

    testWidgets('the pada switch shows when two padas have forms and picks one',
        (tester) async {
      await _pump(tester, _engine(paradigm: Found(_paradigm(), _src())),
          input: 'gam');
      expect(find.byKey(const Key('pada-switch')), findsOneWidget);
      expect(find.text('parasmaipadam'), findsOneWidget);
      expect(find.text('ātmanepadam'), findsOneWidget);
      // Parasmaipada first.
      expect(find.text('gacchati'), findsOneWidget);
      expect(find.text(_iast(_wx(1, 0, 0, 0))), findsNothing);
      await tester.tap(find.text('ātmanepadam'));
      await tester.pumpAndSettle();
      expect(find.text('gacchati'), findsNothing);
      expect(find.text(_iast(_wx(1, 0, 0, 0))), findsOneWidget);
      expect(find.byType(Table), findsNWidgets(10));
    });

    testWidgets('no pada switch when only one pada has forms', (tester) async {
      await _pump(
          tester,
          _engine(
              paradigm: Found(
                  _paradigm(padas: const [FeatureValue.atmanepada]), _src())),
          input: 'gam');
      expect(find.byKey(const Key('pada-switch')), findsNothing);
      expect(find.byType(Table), findsNWidgets(10));
      expect(find.text(_iast(_wx(1, 0, 0, 0))), findsOneWidget);
    });

    testWidgets('a cell with alternatives shows each, one under the other',
        (tester) async {
      await _pump(tester, _engine(paradigm: Found(_paradigm(), _src())),
          input: 'gam');
      final first = tester.getRect(find.text('gacchatu'));
      final second = tester.getRect(find.text('gacchatāt'));
      expect(second.top, greaterThan(first.bottom - 1));
      expect((second.left - first.left).abs(), lessThan(1));
    });

    testWidgets('an empty cell is a muted dash and does nothing', (tester) async {
      await _pump(tester, _engine(paradigm: Found(_paradigm(), _src())),
          input: 'gam');
      expect(find.text('–'), findsOneWidget);
      await tester.tap(find.text('–'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('Sanskrit in the tables is never below 16 sp', (tester) async {
      await _pump(tester, _engine(paradigm: Found(_paradigm(), _src())),
          input: 'gam');
      final texts = tester.widgetList<Text>(find.descendant(
          of: find.byType(Table), matching: find.byType(Text)));
      expect(texts.length, greaterThan(90));
      for (final t in texts) {
        expect(t.style!.fontSize, greaterThanOrEqualTo(16));
      }
    });

    testWidgets('a lakāra chip scrolls to its table', (tester) async {
      await _pump(tester, _engine(paradigm: Found(_paradigm(), _src())),
          input: 'gam', size: const Size(1000, 700));
      final title = find.byKey(const Key('lakara-lan'));
      expect(tester.getTopLeft(title).dy, greaterThan(700)); // below the fold
      await tester.tap(find.widgetWithText(ActionChip, 'laṅ'));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(title).dy, lessThan(300));
    });

    testWidgets('there is a chip for each of the ten lakāras', (tester) async {
      await _pump(tester, _engine(paradigm: Found(_paradigm(), _src())),
          input: 'gam');
      expect(find.byType(ActionChip), findsNWidgets(10));
    });
  });

  group('the form sheet and the links', () {
    Future<void> open(WidgetTester tester,
        {void Function(String)? onOpen,
        Map<String, Object> prefs = const {}}) async {
      await _pump(tester, _engine(paradigm: Found(_paradigm(), _src())),
          input: 'gam', onOpen: onOpen, prefs: prefs);
    }

    testWidgets('names the form, pada, lakāra, person and number',
        (tester) async {
      await open(tester, onOpen: (_) {});
      await tester.tap(find.text('gacchati'));
      await tester.pumpAndSettle();
      expect(_inSheet('gacchati'), findsOneWidget);
      expect(_inSheet('parasmaipadam · laṭ · prathamapuruṣaḥ · ekavacanam'),
          findsOneWidget);
      expect(_inSheet('Analyse this form'), findsOneWidget);
    });

    testWidgets('in English the sheet is in English', (tester) async {
      await open(tester,
          onOpen: (_) {}, prefs: {'settings.labelLanguage': 'english'});
      await tester.tap(find.text('gacchati'));
      await tester.pumpAndSettle();
      expect(_inSheet('parasmaipada · present · third person · singular'),
          findsOneWidget);
    });

    testWidgets('a form in the ātmanepada names that pada', (tester) async {
      await open(tester, onOpen: (_) {});
      await tester.tap(find.text('ātmanepadam'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_iast(_wx(1, 0, 0, 0))));
      await tester.pumpAndSettle();
      expect(_inSheet('ātmanepadam · laṭ · prathamapuruṣaḥ · ekavacanam'),
          findsOneWidget);
    });

    testWidgets('"Analyse this form" opens Analyse a word with the form',
        (tester) async {
      final opened = <String>[];
      await open(tester, onOpen: opened.add);
      await tester.tap(find.text('gacchati'));
      await tester.pumpAndSettle();
      await tester.tap(_inSheet('Analyse this form'));
      await tester.pumpAndSettle();
      expect(opened, ['Analyse a word|गच्छति']);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('each alternative opens its own sheet', (tester) async {
      await open(tester, onOpen: (_) {});
      await tester.tap(find.text('gacchatāt'));
      await tester.pumpAndSettle();
      expect(_inSheet('gacchatāt'), findsOneWidget);
      expect(_inSheet('parasmaipadam · loṭ · prathamapuruṣaḥ · ekavacanam'),
          findsOneWidget);
    });

    testWidgets('without a way to open tools there is no Analyse action and no link',
        (tester) async {
      await open(tester);
      expect(find.text('Kṛt forms of this root'), findsNothing);
      await tester.tap(find.text('gacchati'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(_inSheet('Analyse this form'), findsNothing);
    });

    testWidgets('"Kṛt forms of this root" is the last thing and opens Kṛt forms',
        (tester) async {
      final opened = <String>[];
      await open(tester, onOpen: opened.add);
      final link = find.text('Kṛt forms of this root');
      expect(link, findsOneWidget);
      // After the last lakāra table.
      expect(tester.getTopLeft(link).dy,
          greaterThan(tester.getBottomLeft(find.byType(Table).last).dy - 1));
      await tester.tap(link);
      // The root's key goes with it, so Kṛt forms starts on the same root.
      expect(opened, ['Kṛt forms|$_gam']);
    });

    testWidgets('the link carries the chosen prefix too', (tester) async {
      final opened = <String>[];
      await open(tester, onOpen: opened.add);
      await _pick(tester, 'Prefix', 'pra');
      await tester.tap(find.text('Kṛt forms of this root'));
      expect(opened, ['Kṛt forms|$_gam|pra']);
    });
  });

  group('every result state', () {
    testWidgets('waiting', (tester) async {
      final e = _engine(
          paradigm: Found(_paradigm(), _src()),
          latency: const Duration(seconds: 1));
      await _pump(tester, e, input: 'gam', settle: false);
      expect(find.byKey(const Key('state-waiting')), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.byKey(const Key('state-waiting')), findsNothing);
      expect(find.byType(Table), findsNWidgets(10));
    });

    testWidgets('all dashes with a prefix: the engine has nothing for the pair',
        (tester) async {
      final e = _engine(paradigm: const NotFound());
      await _pump(tester, e);
      await _pick(tester, 'Dhātu', 'gam (gam) gatau bhvādiḥ');
      await _pick(tester, 'Prefix', 'pra');
      expect(find.byKey(const Key('state-notFound')), findsOneWidget);
      expect(find.text('Samsaadhanii has no forms for this root with this prefix.'),
          findsOneWidget);
      // Not the "unknown root" wording, and no spelling hint.
      expect(find.textContaining('No forms for'), findsNothing);
      expect(find.textContaining('Check the spelling'), findsNothing);
      expect(find.byType(Table), findsNothing);
      expect(find.text('–'), findsNothing);
    });

    testWidgets('all dashes with no prefix says "for this root"', (tester) async {
      await _pump(tester, _engine(paradigm: const NotFound()), input: 'gam');
      expect(find.text('Samsaadhanii has no forms for this root.'),
          findsOneWidget);
    });

    testWidgets('bad input', (tester) async {
      await _pump(tester, _engine(paradigm: const BadInput('no such voice')),
          input: 'gam');
      expect(find.byKey(const Key('state-badInput')), findsOneWidget);
      expect(find.textContaining('no such voice'), findsOneWidget);
    });

    testWidgets('server fault, with Retry', (tester) async {
      final e = _engine(paradigm: const ServerFault('bad json'));
      await _pump(tester, e, input: 'gam');
      expect(find.byKey(const Key('state-serverFault')), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(_verbCalls(e).length, 2);
    });

    testWidgets('unreachable, with Retry', (tester) async {
      await _pump(tester, _engine(paradigm: const Unreachable('timeout')),
          input: 'gam');
      expect(find.byKey(const Key('state-unreachable')), findsOneWidget);
      expect(find.text("Can't reach Samsaadhanii."), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('changing the pada keeps working after a new answer',
        (tester) async {
      final e = _engine(paradigm: Found(_paradigm(), _src()));
      await _pump(tester, e, input: 'gam');
      await tester.tap(find.text('ātmanepadam'));
      await tester.pumpAndSettle();
      // A new voice gives a one-pada answer; the view must not break.
      await tester.tap(find.text('karmaṇi'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Table), findsNWidgets(10));
    });
  });
}
