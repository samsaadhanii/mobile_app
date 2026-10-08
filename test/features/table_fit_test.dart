import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/settings.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/engines/samsaadhanii/noun_adapter.dart';
import 'package:mobile_app/engines/samsaadhanii/verb_adapter.dart';
import 'package:mobile_app/features/analyse_word/feature_heading.dart';
import 'package:mobile_app/features/noun_forms/paradigm_table.dart';
import 'package:mobile_app/features/verb_forms/lakara_table_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/roboto.dart';

/// The rule: a form table never scrolls sideways and never breaks a word. It
/// is checked at 360 dp and 320 dp (328 and 288 dp of content inside the 16 dp
/// gutters) on every verb and noun table in the fixtures, in both label
/// languages, with the real Roboto from the Flutter SDK: the default test font
/// makes every glyph a full-width square and says nothing about a phone.
/// Devanagari is not measured, because Roboto has no Devanagari glyphs; it is
/// only checked to lay out.

final _src = ResultSource(
    engine: EngineId.samsaadhanii, program: 'p', time: DateTime.utc(2026, 10, 5));

String _fixture(String name) =>
    File('test/fixtures/samsaadhanii/$name').readAsStringSync();

VerbParadigm _verb(String name) => (parseVerb(_fixture('verb_$name.json'),
        const VerbQuery(root: 'x'), _src) as Found<VerbParadigm>)
    .value;

NounParadigm _noun(String name) => (parseNoun(
        _fixture('noun_$name.json'),
        const NounQuery(stem: SanskritText('x'), gender: FeatureValue.masculine),
        _src) as Found<NounParadigm>)
    .value;

const _verbFixtures = ['gam', 'karmaNi', 'nic_parasmE', 'nic_Awmane'];
const _nounFixtures = ['rAma', 'vana', 'naxI', 'asmax'];
const _widths = [360.0, 320.0];

const _grid = Key('forms-grid');
const _lines = Key('forms-lines');

Future<AppSettings> _settings(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues({'settings.displayScript': 'iast', ...prefs});
  return AppSettings.load();
}

/// A page of [width] dp with the app's 16 dp gutters.
Future<void> _page(WidgetTester tester, double width, Widget child,
    {double textScale = 1}) async {
  tester.view.physicalSize = Size(width, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
          size: Size(width, 6000), textScaler: TextScaler.linear(textScale)),
      child: Scaffold(
        body: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(16), child: child)),
      ),
    ),
  ));
}

/// Checks one table on the page and says which layout it chose. Exactly one
/// layout; nothing scrolls sideways; every text lies within the table; no
/// form is broken onto a second line.
bool _checkOne(WidgetTester tester, {String? reason}) {
  final grids = find.byKey(_grid).evaluate().length;
  final lines = find.byKey(_lines).evaluate().length;
  expect(grids + lines, 1, reason: 'exactly one layout, $reason');
  final root = find.byKey(grids == 1 ? _grid : _lines);
  final box = tester.getRect(root);

  // The only scrollable is the page's own, which goes down.
  for (final s in tester.widgetList<Scrollable>(find.byType(Scrollable))) {
    expect(s.axis, Axis.vertical, reason: 'no sideways scroll, $reason');
  }
  expect(tester.takeException(), isNull, reason: reason);

  final paragraphs = tester.renderObjectList<RenderParagraph>(
      find.descendant(of: root, matching: find.byType(RichText)));
  expect(paragraphs, isNotEmpty);
  for (final p in paragraphs) {
    final left = p.localToGlobal(Offset.zero).dx;
    final text = p.text.toPlainText();
    expect(left + p.getMaxIntrinsicWidth(double.infinity),
        lessThanOrEqualTo(box.right + 0.5),
        reason: '"$text" is wider than the table, $reason');
    // One line: no taller than the same text laid out with all the room.
    final oneLine = TextPainter(
        text: p.text,
        textDirection: TextDirection.ltr,
        textScaler: p.textScaler)
      ..layout();
    expect(p.size.height, lessThanOrEqualTo(oneLine.height + 1),
        reason: '"$text" is broken onto more than one line, $reason');
  }
  return grids == 1;
}

Widget _lakara(LakaraTable t, AppSettings s) =>
    LakaraTableView(table: t, settings: s, onTapForm: (a, b, c, d) {});

Widget _nounTable(NounParadigm p, AppSettings s) =>
    ParadigmTable(paradigm: p, settings: s, onTapForm: (a, b, c) {});

/// An independent measure of the rule "a table whose forms all fit in a third
/// of the width is a grid": the widest form or heading, plus the cell padding,
/// against a third of what the row headings leave.
bool _fitsInThirds(
    {required double width,
    required List<String> rowLabels,
    required List<String> columnLabels,
    required List<String> forms}) {
  double w(String text, FontWeight weight) {
    final p = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: weight)),
      textDirection: TextDirection.ltr,
    )..layout();
    return p.width;
  }

  final head = rowLabels.map((l) => w(l, FontWeight.w600)).fold<double>(0, math.max) + 14;
  final widest = [
    ...columnLabels.map((l) => w(l, FontWeight.w600)),
    ...forms.map((f) => w(f, FontWeight.w400)),
  ].fold<double>(0, math.max);
  return widest + 14 <= (width - head) / 3;
}

void main() {
  late bool haveFont;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    haveFont = await loadRoboto();
  });

  test('the SDK fonts are there to measure with', () {
    // Without them a "fit" would be measured in full-width squares. FLUTTER_ROOT
    // is set by `flutter test`.
    expect(haveFont, isTrue,
        reason: 'FLUTTER_ROOT/bin/cache/artifacts/material_fonts/Roboto-*.ttf');
  });

  group('every verb table, at 360 and 320 dp', () {
    for (final width in _widths) {
      for (final (name, prefs) in [
        ('Sanskrit labels', <String, Object>{}),
        ('English labels', {'settings.labelLanguage': 'english'}),
      ]) {
        testWidgets('${width.round()} dp, $name: never wider than its table, no word broken',
            (tester) async {
          final settings = await _settings(prefs);
          var grids = 0, lines = 0;
          for (final fixture in _verbFixtures) {
            for (final pada in _verb(fixture).padas) {
              for (final t in pada.lakaras) {
                await _page(tester, width, _lakara(t, settings));
                final isGrid = _checkOne(tester,
                    reason: '$fixture ${pada.pada.name} ${t.lakara.name}');
                isGrid ? grids++ : lines++;
              }
            }
          }
          // Both layouts occur: this is not one layout passing by luck.
          expect(grids + lines, 40);
          expect(lines, greaterThan(0));
        });
      }
    }
  });

  group('every noun table, at 360 and 320 dp', () {
    for (final width in _widths) {
      for (final (name, prefs) in [
        ('Sanskrit labels', <String, Object>{}),
        ('English labels', {'settings.labelLanguage': 'english'}),
      ]) {
        testWidgets('${width.round()} dp, $name: never wider than its table, no word broken',
            (tester) async {
          final settings = await _settings(prefs);
          for (final fixture in _nounFixtures) {
            await _page(tester, width, _nounTable(_noun(fixture), settings));
            _checkOne(tester, reason: 'noun $fixture');
          }
        });
      }
    }
  });

  group('which layout', () {
    testWidgets('a table whose forms all fit in a third of the width is a grid',
        (tester) async {
      final settings = await _settings({});
      var thirds = 0;
      for (final width in _widths) {
        for (final fixture in _verbFixtures) {
          for (final pada in _verb(fixture).padas) {
            for (final t in pada.lakaras) {
              final fits = _fitsInThirds(
                width: width - 32,
                rowLabels: [for (final p in personOrder) p.shortIast!],
                columnLabels: [for (final n in numberOrder) n.shortIast!],
                forms: [
                  for (final p in personOrder)
                    for (final n in numberOrder)
                      for (final f in t.forms(p, n)) f.display(Script.iast),
                ],
              );
              await _page(tester, width, _lakara(t, settings));
              final isGrid = _checkOne(tester);
              if (fits) {
                thirds++;
                expect(isGrid, isTrue,
                    reason: '${width.round()} $fixture ${t.lakara.name} fits in thirds');
              }
            }
          }
        }
        for (final fixture in _nounFixtures) {
          final p = _noun(fixture);
          final fits = _fitsInThirds(
            width: width - 32,
            rowLabels: [for (final v in vibhaktiOrder) v.shortIast!],
            columnLabels: [for (final n in numberOrder) n.shortIast!],
            forms: [
              for (final v in vibhaktiOrder)
                for (final n in numberOrder)
                  for (final f in p.forms(v, n)) f.display(Script.iast),
            ],
          );
          await _page(tester, width, _nounTable(p, settings));
          if (fits) {
            thirds++;
            expect(_checkOne(tester), isTrue, reason: 'noun $fixture');
          }
        }
      }
      expect(thirds, greaterThan(0));
    });

    testWidgets('the ordinary active lakāras of gam, liṭ and luṭ, are grids at 360 dp',
        (tester) async {
      final settings = await _settings({});
      final tables = _verb('gam').padas.single.lakaras;
      for (final l in [FeatureValue.lit, FeatureValue.lut]) {
        await _page(tester, 360, _lakara(tables.firstWhere((t) => t.lakara == l), settings));
        expect(_checkOne(tester, reason: l.name), isTrue, reason: l.name);
      }
    });

    testWidgets('the causative perfect, three alternatives in a cell, is lines',
        (tester) async {
      final settings = await _settings({});
      for (final fixture in ['nic_parasmE', 'nic_Awmane']) {
        final lit = _verb(fixture).padas.single.lakaras
            .firstWhere((t) => t.lakara == FeatureValue.lit);
        for (final width in _widths) {
          await _page(tester, width, _lakara(lit, settings));
          expect(_checkOne(tester, reason: fixture), isFalse,
              reason: '$fixture at ${width.round()}');
        }
      }
    });

    testWidgets('rāma and vana are grids at 360 dp, in IAST', (tester) async {
      final settings = await _settings({});
      for (final fixture in ['rAma', 'vana']) {
        await _page(tester, 360, _nounTable(_noun(fixture), settings));
        expect(_checkOne(tester, reason: fixture), isTrue, reason: fixture);
      }
    });

    testWidgets('a long stem falls back to lines, by the same rule',
        (tester) async {
      final settings = await _settings({});
      // A stem whose forms do not fit in a grid at 360 dp.
      final long = NounParadigm(
        const NounQuery(stem: SanskritText('x'), gender: FeatureValue.masculine),
        {
          for (final v in vibhaktiOrder)
            for (final n in numberOrder)
              (v, n): [const SanskritText('mahAbAhuBizagvaraBiH')],
        },
      );
      await _page(tester, 360, _nounTable(long, settings));
      expect(_checkOne(tester), isFalse);
    });

    testWidgets('each table on a page chooses for itself', (tester) async {
      final settings = await _settings({});
      final gam = _verb('gam').padas.single.lakaras[1]; // liṭ: a grid
      final lit = _verb('nic_parasmE').padas.single.lakaras[1]; // lines
      await _page(
          tester,
          360,
          Column(children: [_lakara(gam, settings), _lakara(lit, settings)]));
      expect(find.byKey(_grid), findsOneWidget);
      expect(find.byKey(_lines), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('large text turns a grid into lines instead of overflowing',
        (tester) async {
      final settings = await _settings({});
      final lit = _verb('gam').padas.single.lakaras[1];
      await _page(tester, 360, _lakara(lit, settings));
      expect(_checkOne(tester), isTrue);
      await _page(tester, 360, _lakara(lit, settings), textScale: 1.6);
      expect(find.byKey(_grid), findsNothing);
      expect(find.byKey(_lines), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the lines layout', () {
    testWidgets('a block per person, three labelled lines, alternatives under one label',
        (tester) async {
      final settings = await _settings({});
      final lit = _verb('nic_parasmE').padas.single.lakaras[1];
      await _page(tester, 360, _lakara(lit, settings));
      expect(find.byKey(_lines), findsOneWidget);
      // Three persons, three numbers each: nine labels, one per cell.
      for (final label in ['eka.', 'dvi.', 'bahu.']) {
        expect(find.descendant(of: find.byKey(_lines), matching: find.text(label)),
            findsNWidgets(3), reason: label);
      }
      for (final head in ['pra.', 'ma.', 'u.']) {
        expect(find.descendant(of: find.byKey(_lines), matching: find.text(head)),
            findsOneWidget, reason: head);
      }
      // The first person's singular has three alternatives, stacked, aligned,
      // and the label is not repeated for them.
      final forms = lit.forms(FeatureValue.third, FeatureValue.singular);
      expect(forms.length, 3);
      final rects = [
        // The same word can open another person's cell too; the first person
        // comes first in the tree.
        for (final f in forms)
          tester.getRect(find.text(f.display(Script.iast)).first),
      ];
      for (var i = 1; i < rects.length; i++) {
        expect(rects[i].top, greaterThan(rects[i - 1].bottom - 1));
        expect((rects[i].left - rects[0].left).abs(), lessThan(1));
      }
      // The form has the whole width to itself, to the right of its label.
      final label = tester.getRect(find
          .descendant(of: find.byKey(_lines), matching: find.text('eka.'))
          .first);
      expect(rects.first.left, greaterThanOrEqualTo(label.right));
    });

    testWidgets('headings are the short names with the full ones for a screen reader',
        (tester) async {
      final handle = tester.ensureSemantics();
      final settings = await _settings({});
      final lit = _verb('nic_parasmE').padas.single.lakaras[1];
      await _page(tester, 360, _lakara(lit, settings));
      expect(find.byKey(_lines), findsOneWidget);
      for (final full in ['prathamapuruṣaḥ', 'madhyamapuruṣaḥ', 'uttamapuruṣaḥ']) {
        expect(find.bySemanticsLabel(full), findsOneWidget, reason: full);
      }
      for (final full in ['ekavacanam', 'dvivacanam', 'bahuvacanam']) {
        expect(find.bySemanticsLabel(full), findsNWidgets(3), reason: full);
      }
      handle.dispose();
    });

    testWidgets('a form in lines is tappable and an empty cell is a dash',
        (tester) async {
      final settings = await _settings({});
      final lit = _verb('nic_parasmE').padas.single.lakaras[1];
      final tapped = <String>[];
      await _page(
          tester,
          360,
          LakaraTableView(
              table: LakaraTable(lit.lakara, {
                ...lit.cells,
                (FeatureValue.second, FeatureValue.dual): <SanskritText>[],
              }),
              settings: settings,
              onTapForm: (l, p, n, f) => tapped.add('${p.name}/${n.name}/${f.wx}')));
      expect(find.byKey(_lines), findsOneWidget);
      expect(find.text('–'), findsOneWidget);
      final first = lit.forms(FeatureValue.third, FeatureValue.singular).first;
      await tester.tap(find.text(first.display(Script.iast)).first);
      expect(tapped, ['third/singular/${first.wx}']);
    });
  });

  group('the headings', () {
    testWidgets('are short: none wider than 48 dp, in both languages',
        (tester) async {
      for (final prefs in [
        <String, Object>{},
        {'settings.labelLanguage': 'english'},
      ]) {
        final settings = await _settings(prefs);
        await _page(tester, 360,
            _lakara(_verb('gam').padas.single.lakaras.first, settings));
        for (final h in tester.widgetList<FeatureHeading>(find.byType(FeatureHeading))) {
          final paragraph = tester.renderObject<RenderParagraph>(find.descendant(
              of: find.byWidget(h), matching: find.byType(RichText)));
          expect(paragraph.getMaxIntrinsicWidth(double.infinity), lessThan(48),
              reason: '${h.value}');
        }
      }
    });

    testWidgets('the noun table has short case names too, full ones for a reader',
        (tester) async {
      final handle = tester.ensureSemantics();
      final settings = await _settings({});
      await _page(tester, 360, _nounTable(_noun('rAma'), settings));
      for (final short in ['pra.', 'dvi.', 'tṛ.', 'ca.', 'pa.', 'ṣa.', 'sa.', 'saṃ.']) {
        expect(find.text(short), findsWidgets, reason: short);
      }
      for (final full in ['prathamā', 'tṛtīyā', 'sambodhanam']) {
        expect(find.bySemanticsLabel(full), findsOneWidget, reason: full);
      }
      handle.dispose();
    });
  });

  group('Devanagari lays out in either layout', () {
    testWidgets('every table at 360 dp, without an exception', (tester) async {
      final settings = await _settings({'settings.displayScript': 'devanagari'});
      for (final fixture in _verbFixtures) {
        for (final pada in _verb(fixture).padas) {
          for (final t in pada.lakaras) {
            await _page(tester, 360, _lakara(t, settings));
            final grids = find.byKey(_grid).evaluate().length;
            final lines = find.byKey(_lines).evaluate().length;
            expect(grids + lines, 1);
            expect(tester.takeException(), isNull);
          }
        }
      }
      for (final fixture in _nounFixtures) {
        await _page(tester, 360, _nounTable(_noun(fixture), settings));
        expect(tester.takeException(), isNull);
      }
    });
  });
}
