import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/settings.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/engines/samsaadhanii/krt_adapter.dart';
import 'package:mobile_app/features/krt_forms/krt_forms_screen.dart';
import 'package:mobile_app/features/task_frame/engine_set.dart';
import 'package:mobile_app/sanskrit/transliteration.dart' show convert;
import 'package:mobile_app/shared/data/word_lists.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_engine.dart';

const _gam = 'gam1_gamLz_BvAxiH_gawO';
const _paT = 'paT1_paTaz_BvAxiH_vyakwAyAM_vAci';

final _dhatus = DhatuList.fromEntries([
  ListEntry(_gam, 'गम् (गम्) गतौ भ्वादिः', 'gam (gam) gatau bhvādiḥ'),
  ListEntry(_paT, 'पठ् (पठ्) व्यक्तायां वाचि भ्वादिः',
      'paṭh (paṭh) vyaktāyāṃ vāci bhvādiḥ'),
]);

final _prefixes = PrefixList.fromEntries([
  ListEntry('Af', 'आङ्', 'āṅ'),
  ListEntry('pra', 'प्र', 'pra'),
]);

ResultSource _src() => ResultSource(
    engine: EngineId.samsaadhanii,
    program: 'kqw_gen.cgi',
    time: DateTime.utc(2026, 10, 5));

/// The real answer for a root, through the real adapter.
KrtForms _answer(String fixture, {String root = _gam, String? prefix}) =>
    (parseKrt(File('test/fixtures/samsaadhanii/krt_$fixture.json').readAsStringSync(),
            VerbQuery(root: root, prefix: prefix), _src()) as Found<KrtForms>)
        .value;

Outcome<KrtForms> _found(KrtForms k) => Found(k, _src());

FakeEngine _engine({Outcome<KrtForms>? krt, Duration latency = Duration.zero}) =>
    FakeEngine(
      tasks: const {Task.analyseWord, Task.krtForms},
      krt: krt,
      latency: latency,
    );

Future<void> _pump(
  WidgetTester tester,
  FakeEngine engine, {
  String input = '',
  String? initialPrefix,
  Map<String, Object> prefs = const {},
  void Function(String)? onOpen,
  DhatuList? dhatus,
  bool settle = true,
  Size size = const Size(1000, 4000),
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
      home: KrtFormsScreen(
        initialInput: input,
        initialPrefix: initialPrefix,
        onOpenTool: onOpen == null
            ? null
            : (e, i, {gender, prefix}) => onOpen(
                '${e.nameEn}|$i${gender == null ? '' : '|${gender.name}'}'),
      ),
    ),
  ));
  settle ? await tester.pumpAndSettle() : await tester.pump();
}

Finder _inSheet(String text) =>
    find.descendant(of: find.byType(BottomSheet), matching: find.text(text));

Finder _group(String label) => find.byKey(Key('krt-$label'));

Finder _in(String label, String text) =>
    find.descendant(of: _group(label), matching: find.text(text));

Future<void> _pick(WidgetTester tester, String field, String row) async {
  await tester.tap(find.text(field));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ListTile, row));
  await tester.pumpAndSettle();
}

List<String> _calls(FakeEngine e) =>
    [for (final c in e.calls) if (c.startsWith('krtForms')) c];

const _shown = [
  'tṛc', 'tavyat', 'śatṛ_laṭ', 'śānac_laṭ_kartari', 'śānac_laṭ_karmaṇi',
  'ghañ', 'ṇvul', 'ṇyat', 'lyuṭ', 'yat', 'kta', 'ktavatu', 'anīyar', 'tumun',
  'ṇamul', 'ktvā',
];

void main() {
  group('the inputs', () {
    testWidgets('empty: two pickers, no voice, no request, no result',
        (tester) async {
      final e = _engine(krt: _found(_answer('gam')));
      await _pump(tester, e);
      expect(find.text('Dhātu'), findsOneWidget);
      expect(find.text('Prefix'), findsOneWidget);
      expect(find.byKey(const Key('prayoga-switch')), findsNothing);
      expect(e.calls, isEmpty);
      expect(find.textContaining('Suffix names'), findsNothing);
    });

    testWidgets('a root typed on Home is looked up at once', (tester) async {
      final e = _engine(krt: _found(_answer('gam')));
      await _pump(tester, e, input: 'gam');
      expect(_calls(e), ['krtForms:$_gam:-']);
      expect(find.text('gam (gam) gatau bhvādiḥ'), findsOneWidget);
    });

    testWidgets('the exact key Verb forms hands over, with its prefix',
        (tester) async {
      final e = _engine(krt: _found(_answer('gam_pra', prefix: 'pra')));
      await _pump(tester, e, input: _paT, initialPrefix: 'pra');
      expect(_calls(e), ['krtForms:$_paT:pra']);
      expect(find.text('pra'), findsOneWidget); // the prefix picker
    });

    testWidgets('a Devanagari root is read as Devanagari', (tester) async {
      final e = _engine(krt: _found(_answer('gam')));
      await _pump(tester, e, input: 'गम्');
      expect(_calls(e), ['krtForms:$_gam:-']);
    });

    testWidgets('a root not in the list is said so and not guessed',
        (tester) async {
      final e = _engine(krt: _found(_answer('gam')));
      await _pump(tester, e, input: 'xyzq');
      expect(e.calls, isEmpty);
      expect(find.text('No forms for xyzq'), findsOneWidget);
      expect(find.text('Pick the root from the list.'), findsOneWidget);
    });

    testWidgets('picking a root, a prefix and "No prefix" looks it up each time',
        (tester) async {
      final e = _engine(krt: _found(_answer('gam')));
      await _pump(tester, e);
      await _pick(tester, 'Dhātu', 'gam (gam) gatau bhvādiḥ');
      await _pick(tester, 'Prefix', 'pra');
      await _pick(tester, 'Prefix', 'No prefix');
      expect(_calls(e), [
        'krtForms:$_gam:-',
        'krtForms:$_gam:pra',
        'krtForms:$_gam:-',
      ]);
    });

    testWidgets('a prefix without a root looks nothing up', (tester) async {
      final e = _engine(krt: _found(_answer('gam')));
      await _pump(tester, e);
      await _pick(tester, 'Prefix', 'pra');
      expect(e.calls, isEmpty);
    });

    testWidgets('a list that is still loading is waited for', (tester) async {
      final late = DhatuList();
      final e = _engine(krt: _found(_answer('gam')));
      await _pump(tester, e, input: 'gam', dhatus: late, settle: false);
      expect(e.calls, isEmpty);
      await tester.runAsync(late.load);
      await tester.pumpAndSettle();
      expect(_calls(e).single, startsWith('krtForms:gam'));
    });

    testWidgets('no engine switch and no Compare', (tester) async {
      await _pump(tester, _engine(krt: _found(_answer('gam'))), input: 'gam');
      expect(find.byKey(const Key('engine-switch')), findsNothing);
      expect(find.byKey(const Key('compare-button')), findsNothing);
    });
  });

  group('the list of groups', () {
    testWidgets('sixteen groups in the server order, with the corrected names',
        (tester) async {
      await _pump(tester, _engine(krt: _found(_answer('gam'))), input: 'gam');
      final keys = tester
          .widgetList<Padding>(find.byWidgetPredicate(
              (w) => w is Padding && w.key is Key && '${w.key}'.contains('krt-')))
          .map((w) => ((w.key as ValueKey).value as String).substring(4))
          .toList();
      expect(keys, _shown);
    });

    testWidgets('the suffix name in the display script, lakāra and prayoga in the label language',
        (tester) async {
      await _pump(tester, _engine(krt: _found(_answer('gam'))), input: 'gam');
      expect(_in('kta', 'kta'), findsOneWidget);
      expect(_in('śatṛ_laṭ', 'śatṛ · laṭ'), findsOneWidget);
      expect(_in('śānac_laṭ_kartari', 'śānac · laṭ · kartari'), findsOneWidget);
      expect(_in('śānac_laṭ_karmaṇi', 'śānac · laṭ · karmaṇi'), findsOneWidget);
    });

    testWidgets('English labels for the lakāra and prayoga; the suffix stays Sanskrit',
        (tester) async {
      await _pump(tester, _engine(krt: _found(_answer('gam'))),
          input: 'gam', prefs: {'settings.labelLanguage': 'english'});
      expect(_in('śānac_laṭ_karmaṇi', 'śānac · present · passive'),
          findsOneWidget);
      expect(_in('kta', 'kta'), findsOneWidget);
    });

    testWidgets('Devanagari display', (tester) async {
      await _pump(tester, _engine(krt: _found(_answer('gam'))),
          input: 'gam', prefs: {'settings.displayScript': 'devanagari'});
      expect(_in('kta', convert('kta', Script.iast, Script.devanagari)),
          findsOneWidget);
      // puṃ and napuṃ have the same form.
      expect(_in('kta', 'गत'), findsNWidgets(2));
      expect(find.text('gata'), findsNothing);
    });

    testWidgets('a gendered group shows three small headings and its forms',
        (tester) async {
      await _pump(tester, _engine(krt: _found(_answer('gam'))), input: 'gam');
      for (final h in ['puṃ', 'strī', 'napuṃ']) {
        expect(_in('kta', h), findsOneWidget, reason: h);
      }
      expect(_in('kta', 'gata'), findsNWidgets(2)); // puṃ and napuṃ alike
      expect(_in('kta', 'gatā'), findsOneWidget);
      expect(_in('ktavatu', 'gatavat'), findsNWidgets(2)); // puṃ and napuṃ
      expect(_in('ktavatu', 'gatavatī'), findsOneWidget);
      expect(_in('anīyar', 'gamanīya'), findsNWidgets(2)); // puṃ and napuṃ
      // The right form under the right (corrected) suffix.
      expect(_in('śatṛ_laṭ', 'gacchat'), findsNWidgets(2)); // puṃ and napuṃ
    });

    testWidgets('gender headings in English', (tester) async {
      await _pump(tester, _engine(krt: _found(_answer('gam'))),
          input: 'gam', prefs: {'settings.labelLanguage': 'english'});
      for (final h in ['m.', 'f.', 'n.']) {
        expect(_in('kta', h), findsOneWidget, reason: h);
      }
    });

    testWidgets('a screen reader gets the full gender name', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _engine(krt: _found(_answer('gam'))), input: 'gam');
      for (final full in ['puṃliṅgam', 'strīliṅgam', 'napuṃsakaliṅgam']) {
        expect(find.bySemanticsLabel(full), findsNWidgets(13), reason: full);
      }
      handle.dispose();
    });

    testWidgets('indeclinables show their form or forms and no gender headings',
        (tester) async {
      await _pump(tester, _engine(krt: _found(_answer('gam'))), input: 'gam');
      expect(_in('tumun', 'gantum'), findsOneWidget);
      expect(_in('tumun', 'puṃ'), findsNothing);
      expect(_in('ṇamul', 'gāmam'), findsOneWidget);
      expect(_in('ṇamul', 'gāmaṃ'), findsOneWidget);
      expect(_in('ktvā', 'gatvā'), findsOneWidget);
      expect(_in('ktvā', 'gattvā'), findsOneWidget);
      // Alternatives one under the other.
      final a = tester.getRect(_in('ktvā', 'gatvā'));
      final b = tester.getRect(_in('ktvā', 'gattvā'));
      expect(b.top, greaterThan(a.bottom - 1));
    });

    testWidgets('empty groups are shown muted, not hidden', (tester) async {
      await _pump(tester, _engine(krt: _found(_answer('gam'))), input: 'gam');
      // gam has no śānac kartari: three dashes, and the name is still there.
      expect(_group('śānac_laṭ_kartari'), findsOneWidget);
      expect(_in('śānac_laṭ_kartari', '–'), findsNWidgets(3));
      final title = tester.widget<Text>(_in('śānac_laṭ_kartari', 'śānac · laṭ · kartari'));
      final scheme = Theme.of(tester.element(_group('kta'))).colorScheme;
      expect(title.style!.color, scheme.onSurfaceVariant);
      // A group with forms is in the primary colour instead.
      final full = tester.widget<Text>(_in('kta', 'kta'));
      expect(full.style!.color, scheme.primary);
    });

    testWidgets('the list reads the same with a prefix: lyap in place of ktvā',
        (tester) async {
      await _pump(tester, _engine(krt: _found(_answer('gam_pra', prefix: 'pra'))),
          input: 'gam', initialPrefix: 'pra');
      expect(find.byKey(const Key('krt-lyap')), findsOneWidget);
      expect(find.byKey(const Key('krt-ktvā')), findsNothing);
      expect(_in('lyap', 'pragamya'), findsOneWidget);
      expect(_in('lyap', 'pragatya'), findsOneWidget);
      // tumun and ṇamul are there, muted.
      expect(_in('tumun', '–'), findsOneWidget);
      expect(_in('ṇamul', '–'), findsOneWidget);
      expect(_group('kta'), findsOneWidget);
    });

    testWidgets('the credit line', (tester) async {
      await _pump(tester, _engine(krt: _found(_answer('gam'))), input: 'gam');
      expect(find.text('From Samsaadhanii, University of Hyderabad'),
          findsOneWidget);
    });

    testWidgets('a 360 dp phone: the gendered cells wrap, nothing overflows or scrolls sideways',
        (tester) async {
      await _pump(tester, _engine(krt: _found(_answer('kq'))),
          input: 'gam', size: const Size(360, 6000));
      expect(tester.takeException(), isNull);
      expect(find.byType(Wrap), findsWidgets);
      // Every form is within the screen.
      for (final t in tester.widgetList<Text>(find.descendant(
          of: find.byType(Wrap), matching: find.byType(Text)))) {
        final box = tester.getRect(find.byWidget(t));
        expect(box.right, lessThanOrEqualTo(360), reason: t.data);
      }
    });

    testWidgets('Sanskrit in the groups is never below 16 sp', (tester) async {
      await _pump(tester, _engine(krt: _found(_answer('gam'))), input: 'gam');
      final texts = tester.widgetList<Text>(find.descendant(
          of: find.byWidgetPredicate(
              (w) => w is Padding && '${w.key}'.contains('krt-')),
          matching: find.byType(Text)));
      expect(texts.length, greaterThan(40));
      for (final t in texts) {
        expect(t.style!.fontSize, greaterThanOrEqualTo(16), reason: t.data);
      }
    });
  });

  group('the correction note', () {
    testWidgets('says the names were corrected, and shows what was sent on tapping',
        (tester) async {
      await _pump(tester, _engine(krt: _found(_answer('gam'))), input: 'gam');
      expect(find.text('Suffix names corrected by the app.'), findsOneWidget);
      expect(find.textContaining('→'), findsNothing); // folded
      await tester.tap(find.byKey(const Key('krt-corrected')));
      await tester.pumpAndSettle();
      expect(find.text('yak  →  śatṛ_laṭ'), findsOneWidget);
      expect(find.text('śatṛ_laṭ  →  śānac_laṭ_kartari'), findsOneWidget);
      expect(find.text('ktavatu  →  anīyar'), findsOneWidget);
      // Eleven groups were relabelled, and only those are listed (and the
      // column header has the arrow too).
      expect(find.textContaining('  →  '), findsNWidgets(11 + 1));
      await tester.tap(find.byKey(const Key('krt-corrected')));
      await tester.pumpAndSettle();
      expect(find.textContaining('  →  '), findsNothing);
    });

    testWidgets('the sent labels follow the display script', (tester) async {
      await _pump(tester, _engine(krt: _found(_answer('gam'))),
          input: 'gam', prefs: {'settings.displayScript': 'devanagari'});
      await tester.tap(find.byKey(const Key('krt-corrected')));
      await tester.pumpAndSettle();
      final yak = convert('yak', Script.iast, Script.devanagari);
      final sat = convert('śatṛ_laṭ', Script.iast, Script.devanagari);
      expect(find.text('$yak  →  $sat'), findsOneWidget);
    });

    testWidgets('no note when the server already sends the right names',
        (tester) async {
      final fixed = (parseKrt(
              File('test/fixtures/samsaadhanii/krt_gam_fixed.json').readAsStringSync(),
              const VerbQuery(root: _gam),
              _src()) as Found<KrtForms>)
          .value;
      expect(fixed.labels, KrtLabels.asSent);
      await _pump(tester, _engine(krt: _found(fixed)), input: 'gam');
      expect(find.byKey(const Key('krt-corrected')), findsNothing);
      expect(find.byKey(const Key('krt-unverified')), findsNothing);
      // The groups are the same ones.
      expect(_in('kta', 'gata'), findsNWidgets(2));
    });

    testWidgets('a warning when the labels could not be checked',
        (tester) async {
      final k = _answer('gam');
      final unverified = KrtForms(k.query, k.groups, KrtLabels.unverified);
      await _pump(tester, _engine(krt: _found(unverified)), input: 'gam');
      expect(find.byKey(const Key('krt-unverified')), findsOneWidget);
      expect(find.textContaining('could not be checked'), findsOneWidget);
      expect(find.byKey(const Key('krt-corrected')), findsNothing);
    });
  });

  group('the form sheet', () {
    Future<void> open(WidgetTester tester,
        {void Function(String)? onOpen,
        Map<String, Object> prefs = const {}}) async {
      await _pump(tester, _engine(krt: _found(_answer('gam'))),
          input: 'gam', onOpen: onOpen, prefs: prefs);
    }

    testWidgets('a gendered form: its suffix and gender, Analyse and All forms',
        (tester) async {
      await open(tester, onOpen: (_) {});
      await tester.tap(_in('kta', 'gata').first);
      await tester.pumpAndSettle();
      expect(_inSheet('gata'), findsOneWidget);
      expect(_inSheet('kta · puṃliṅgam'), findsOneWidget);
      expect(_inSheet('Analyse this form'), findsOneWidget);
      expect(_inSheet('All forms'), findsOneWidget);
    });

    testWidgets('the description carries the lakāra and prayoga too',
        (tester) async {
      await open(tester, onOpen: (_) {});
      await tester.tap(_in('śānac_laṭ_karmaṇi', 'gamyamāna').first);
      await tester.pumpAndSettle();
      expect(_inSheet('śānac · laṭ · karmaṇi · puṃliṅgam'), findsOneWidget);
    });

    testWidgets('in English', (tester) async {
      await open(tester, onOpen: (_) {}, prefs: {'settings.labelLanguage': 'english'});
      await tester.tap(_in('kta', 'gatā'));
      await tester.pumpAndSettle();
      expect(_inSheet('kta · feminine'), findsOneWidget);
    });

    testWidgets('"Analyse this form" opens Analyse a word with the form',
        (tester) async {
      final opened = <String>[];
      await open(tester, onOpen: opened.add);
      await tester.tap(_in('kta', 'gata').first);
      await tester.pumpAndSettle();
      await tester.tap(_inSheet('Analyse this form'));
      await tester.pumpAndSettle();
      expect(opened, ['Analyse a word|गत']);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('"All forms" opens Noun forms with the form as the stem and its gender',
        (tester) async {
      final opened = <String>[];
      await open(tester, onOpen: opened.add);
      await tester.tap(_in('kta', 'gatā'));
      await tester.pumpAndSettle();
      await tester.tap(_inSheet('All forms'));
      await tester.pumpAndSettle();
      expect(opened, ['Noun forms|गता|feminine']);
    });

    testWidgets('a neuter form passes the neuter gender', (tester) async {
      final opened = <String>[];
      await open(tester, onOpen: opened.add);
      await tester.tap(_in('lyuṭ', 'gamana'));
      await tester.pumpAndSettle();
      await tester.tap(_inSheet('All forms'));
      await tester.pumpAndSettle();
      expect(opened, ['Noun forms|गमन|neuter']);
    });

    testWidgets('an indeclinable has no gender and no "All forms"',
        (tester) async {
      await open(tester, onOpen: (_) {});
      await tester.tap(_in('tumun', 'gantum'));
      await tester.pumpAndSettle();
      expect(_inSheet('gantum'), findsOneWidget);
      expect(_inSheet('tumun'), findsOneWidget);
      expect(_inSheet('Analyse this form'), findsOneWidget);
      expect(_inSheet('All forms'), findsNothing);
    });

    testWidgets('without a way to open tools the sheet has no actions',
        (tester) async {
      await open(tester);
      await tester.tap(_in('kta', 'gata').first);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(_inSheet('Analyse this form'), findsNothing);
      expect(_inSheet('All forms'), findsNothing);
    });

    testWidgets('an empty cell does nothing when tapped', (tester) async {
      await open(tester, onOpen: (_) {});
      await tester.tap(_in('śānac_laṭ_kartari', '–').first);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('every result state', () {
    testWidgets('waiting', (tester) async {
      final e = _engine(
          krt: _found(_answer('gam')), latency: const Duration(seconds: 1));
      await _pump(tester, e, input: 'gam', settle: false);
      expect(find.byKey(const Key('state-waiting')), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.byKey(const Key('state-waiting')), findsNothing);
      expect(_group('kta'), findsOneWidget);
    });

    testWidgets('all dashes: the engine has nothing for this root',
        (tester) async {
      await _pump(tester, _engine(krt: const NotFound()), input: 'gam');
      expect(find.byKey(const Key('state-notFound')), findsOneWidget);
      expect(find.text('Samsaadhanii has no kṛt forms for this root.'),
          findsOneWidget);
      expect(find.textContaining('Check the spelling'), findsNothing);
      expect(find.text('–'), findsNothing);
    });

    testWidgets('all dashes with a prefix says "with this prefix"',
        (tester) async {
      await _pump(tester, _engine(krt: const NotFound()),
          input: 'gam', initialPrefix: 'pra');
      expect(
          find.text('Samsaadhanii has no kṛt forms for this root with this prefix.'),
          findsOneWidget);
    });

    testWidgets('bad input', (tester) async {
      await _pump(tester, _engine(krt: const BadInput('no such root')),
          input: 'gam');
      expect(find.byKey(const Key('state-badInput')), findsOneWidget);
      expect(find.textContaining('no such root'), findsOneWidget);
    });

    testWidgets('server fault, with Retry', (tester) async {
      final e = _engine(krt: const ServerFault('bad json'));
      await _pump(tester, e, input: 'gam');
      expect(find.byKey(const Key('state-serverFault')), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(_calls(e).length, 2);
    });

    testWidgets('unreachable, with Retry', (tester) async {
      await _pump(tester, _engine(krt: const Unreachable('timeout')),
          input: 'gam');
      expect(find.byKey(const Key('state-unreachable')), findsOneWidget);
      expect(find.text("Can't reach Samsaadhanii."), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
