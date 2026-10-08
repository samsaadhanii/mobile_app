import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/settings.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/engines/samsaadhanii/dictionary_adapter.dart';
import 'package:mobile_app/features/dictionary/dictionary_screen.dart';
import 'package:mobile_app/features/dictionary/dictionary_section.dart';
import 'package:mobile_app/features/task_frame/engine_set.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_engine.dart';

ResultSource _src() => ResultSource(
    engine: EngineId.samsaadhanii,
    program: 'dict_help_json.cgi',
    time: DateTime.utc(2026, 10, 5));

/// The real answer, through the real adapter.
Outcome<List<DictionaryEntry>> _answer(String fixture) => parseDictionary(
    File('test/fixtures/samsaadhanii/dictionary_$fixture.json').readAsStringSync(),
    _src());

DictionaryEntry _entry(int standard, String body, {String word = 'वन'}) =>
    DictionaryEntry(
      dictionary: standardDictionaries[standard],
      headword: SanskritText.from(word, Script.devanagari),
      body: body,
    );

Outcome<List<DictionaryEntry>> _entries(List<DictionaryEntry> l) => Found(l, _src());

FakeEngine _engine({Outcome<List<DictionaryEntry>>? dictionary, Duration latency = Duration.zero}) =>
    FakeEngine(
      tasks: const {Task.analyseWord, Task.dictionary},
      dictionary: dictionary,
      latency: latency,
    );

Future<void> _pump(
  WidgetTester tester,
  FakeEngine engine, {
  String input = '',
  Map<String, Object> prefs = const {},
  bool settle = true,
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(1000, 6000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({'settings.displayScript': 'iast', ...prefs});
  final settings = await AppSettings.load();
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      Provider<EngineSet>.value(value: EngineSet({EngineId.samsaadhanii: engine})),
    ],
    // A new key each time, so a second pump in one test builds a new screen.
    child: MaterialApp(
      key: UniqueKey(),
      home: MediaQuery(
        data: MediaQueryData(
            size: const Size(1000, 6000), textScaler: TextScaler.linear(textScale)),
        child: DictionaryScreen(initialInput: input),
      ),
    ),
  ));
  settle ? await tester.pumpAndSettle() : await tester.pump();
}

Finder _section(String name) => find.byKey(Key('dict-$name'));
Finder _body(String name) => find.byKey(Key('dict-body-$name'));
Finder _toggle(String name) => find.byKey(Key('dict-toggle-$name'));

List<String> _calls(FakeEngine e) =>
    [for (final c in e.calls) if (c.startsWith('lookUp')) c];

/// More than six lines even at 1000 dp: long enough to collapse.
String get _long => List.generate(40, (i) => 'line number $i of a long entry').join('\n');

void main() {
  group('the input', () {
    testWidgets('empty: one field, no request, no result', (tester) async {
      final e = _engine(dictionary: _answer('vana'));
      await _pump(tester, e);
      expect(find.text('One Sanskrit word'), findsOneWidget);
      expect(e.calls, isEmpty);
      expect(find.byKey(const Key('dict-headword')), findsNothing);
    });

    testWidgets('a word from Home is looked up at once, in any script',
        (tester) async {
      for (final (typed, wx) in [
        ('vana', 'vana'),
        ('वन', 'vana'),
        ('rāma', 'rAma'),
      ]) {
        final e = _engine(dictionary: _answer('vana'));
        await _pump(tester, e, input: typed);
        expect(_calls(e), ['lookUp:$wx'], reason: typed);
      }
    });

    testWidgets('only the first word is looked up', (tester) async {
      final e = _engine(dictionary: _answer('vana'));
      await _pump(tester, e, input: 'vana rAma');
      expect(_calls(e), ['lookUp:vana']);
    });

    testWidgets('typing a word and pressing the button looks it up',
        (tester) async {
      final e = _engine(dictionary: _answer('vana'));
      await _pump(tester, e);
      await tester.enterText(find.byType(TextField), 'vana');
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(_calls(e), ['lookUp:vana']);
    });

    testWidgets('the keyboard action looks it up too', (tester) async {
      final e = _engine(dictionary: _answer('vana'));
      await _pump(tester, e);
      await tester.enterText(find.byType(TextField), 'vana');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(_calls(e), ['lookUp:vana']);
    });

    testWidgets('an empty field looks nothing up', (tester) async {
      final e = _engine(dictionary: _answer('vana'));
      await _pump(tester, e);
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(e.calls, isEmpty);
    });

    testWidgets('no engine switch and no Compare', (tester) async {
      await _pump(tester, _engine(dictionary: _answer('vana')), input: 'vana');
      expect(find.byKey(const Key('engine-switch')), findsNothing);
      expect(find.byKey(const Key('compare-button')), findsNothing);
    });
  });

  group('the sections', () {
    testWidgets('one per dictionary, in the server order, each with name and language',
        (tester) async {
      await _pump(tester, _engine(dictionary: _answer('vana')), input: 'vana');
      final names = ['Apte', 'Monier-Williams', 'Heritage', 'Cappeller'];
      final languages = ['Hindi', 'English', 'French', 'German'];
      for (var i = 0; i < 4; i++) {
        expect(find.descendant(of: _section(names[i]), matching: find.text('${names[i]} · ${languages[i]}')),
            findsOneWidget, reason: names[i]);
      }
      final tops = [for (final n in names) tester.getTopLeft(_section(n)).dy];
      expect(tops, [...tops]..sort());
      expect(tops.toSet().length, 4);
    });

    testWidgets('the headword is shown in the display script', (tester) async {
      await _pump(tester, _engine(dictionary: _answer('vana')), input: 'vana');
      expect(tester.widget<Text>(find.byKey(const Key('dict-headword'))).data, 'vana');
      await _pump(tester, _engine(dictionary: _answer('vana')),
          input: 'vana', prefs: {'settings.displayScript': 'devanagari'});
      expect(tester.widget<Text>(find.byKey(const Key('dict-headword'))).data, 'वन');
    });

    testWidgets('the body is shown as given: decoded references, prose in place',
        (tester) async {
      await _pump(tester, _engine(dictionary: _answer('vana')), input: 'vana');
      final mw = tester.widget<SelectableText>(_body('Monier-Williams')).data!;
      expect(mw, contains('[ vana ] [ vána ]'));
      final de = tester.widget<SelectableText>(_body('Cappeller')).data!;
      expect(de, contains('wünschen'));
      final fr = tester.widget<SelectableText>(_body('Heritage')).data!;
      expect(fr, contains('forêt'));
    });

    testWidgets("Apte's senses are on separate lines", (tester) async {
      await _pump(tester, _engine(dictionary: _answer('vana')), input: 'vana');
      final apte = tester.widget<SelectableText>(_body('Apte')).data!;
      final lines = apte.split('\n');
      expect(lines.length, greaterThan(5));
      expect(lines[1], startsWith('1. अरण्य'));
      expect(lines[2], startsWith('2. गुल्म'));
    });

    testWidgets('the text is selectable', (tester) async {
      await _pump(tester, _engine(dictionary: _answer('vana')), input: 'vana');
      expect(find.byType(SelectableText), findsNWidgets(4));
    });

    testWidgets('the text is at least 16 sp', (tester) async {
      await _pump(tester, _engine(dictionary: _answer('vana')), input: 'vana');
      for (final w in tester.widgetList<SelectableText>(find.byType(SelectableText))) {
        expect(w.style!.fontSize, greaterThanOrEqualTo(16));
      }
    });

    testWidgets('the credit line', (tester) async {
      await _pump(tester, _engine(dictionary: _answer('vana')), input: 'vana');
      expect(find.text('From Samsaadhanii'), findsOneWidget);
    });
  });

  group('"Show all"', () {
    testWidgets('a long entry shows six lines and "Show all"', (tester) async {
      await _pump(tester, _engine(dictionary: _entries([_entry(0, _long)])),
          input: 'vana');
      final body = tester.widget<SelectableText>(_body('Apte'));
      expect(body.maxLines, dictionaryCollapsedLines);
      expect(_toggle('Apte'), findsOneWidget);
      expect(find.text('Show all'), findsOneWidget);
    });

    testWidgets('Show all expands it, Show less folds it again', (tester) async {
      await _pump(tester, _engine(dictionary: _entries([_entry(0, _long)])),
          input: 'vana');
      final folded = tester.getSize(_body('Apte')).height;
      await tester.tap(_toggle('Apte'));
      await tester.pumpAndSettle();
      expect(tester.widget<SelectableText>(_body('Apte')).maxLines, isNull);
      expect(find.text('Show less'), findsOneWidget);
      expect(tester.getSize(_body('Apte')).height, greaterThan(folded * 3));
      await tester.tap(_toggle('Apte'));
      await tester.pumpAndSettle();
      expect(tester.widget<SelectableText>(_body('Apte')).maxLines, dictionaryCollapsedLines);
      expect(tester.getSize(_body('Apte')).height, folded);
    });

    testWidgets('the folded body fades at its bottom edge; expanded it does not',
        (tester) async {
      await _pump(tester, _engine(dictionary: _entries([_entry(0, _long)])),
          input: 'vana');
      final fade = find.byKey(const Key('dict-fade-Apte'));
      expect(fade, findsOneWidget);
      expect(tester.widget<ShaderMask>(fade).blendMode, BlendMode.dstIn);
      // The text under it is the same selectable text, with its six lines.
      expect(find.descendant(of: fade, matching: find.byType(SelectableText)),
          findsOneWidget);
      expect(tester.widget<SelectableText>(_body('Apte')).maxLines,
          dictionaryCollapsedLines);
      await tester.tap(_toggle('Apte'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dict-fade-Apte')), findsNothing);
      expect(_body('Apte'), findsOneWidget);
      await tester.tap(_toggle('Apte'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dict-fade-Apte')), findsOneWidget);
    });

    testWidgets('a short entry has no fade either', (tester) async {
      await _pump(tester, _engine(dictionary: _entries([_entry(1, 'a forest')])),
          input: 'vana');
      expect(find.byKey(const Key('dict-fade-Monier-Williams')), findsNothing);
    });

    testWidgets('the last visible line is faded to the background, the first is not',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: RepaintBoundary(
            key: key,
            child: Container(
              color: Colors.white,
              width: 400,
              child: DictionarySection(entry: _entry(0, _long)),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      // Where the text is, in the picture.
      final body = tester.getRect(_body('Apte'));
      final box = tester.getRect(find.byKey(key));
      final image = await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        return boundary.toImage();
      });
      final bytes = (await tester.runAsync(
              () => image!.toByteData(format: ui.ImageByteFormat.rawRgba)))!;
      int luminance(double x, double y) {
        final i = ((y.round()) * image!.width + x.round()) * 4;
        return (bytes.getUint8(i) + bytes.getUint8(i + 1) + bytes.getUint8(i + 2)) ~/ 3;
      }

      // The test font draws solid squares, so a line is as dark as can be.
      // Darkest pixel across a line's height, to be sure to hit the glyphs.
      int darkest(double top, double bottom) {
        var d = 255;
        for (var y = top; y < bottom; y += 1) {
          for (var x = body.left - box.left + 1; x < body.left - box.left + 200; x += 2) {
            d = d < luminance(x, y) ? d : luminance(x, y);
          }
        }
        return d;
      }

      final line = body.height / dictionaryCollapsedLines;
      final top = body.top - box.top;
      final first = darkest(top + 2, top + line - 2);
      final last = darkest(top + body.height - 4, top + body.height - 1);
      expect(first, lessThan(60), reason: 'the first line is solid');
      expect(last, greaterThan(200), reason: 'the bottom edge has faded to white');
    });

    testWidgets('a short entry has no toggle and no limit', (tester) async {
      await _pump(tester, _engine(dictionary: _entries([_entry(1, 'a forest')])),
          input: 'vana');
      expect(_toggle('Monier-Williams'), findsNothing);
      expect(tester.widget<SelectableText>(_body('Monier-Williams')).maxLines, isNull);
      expect(find.text('Show all'), findsNothing);
    });

    testWidgets('exactly six lines are not collapsed; seven are', (tester) async {
      String lines(int n) => List.generate(n, (i) => 'row $i').join('\n');
      await _pump(tester, _engine(dictionary: _entries([_entry(0, lines(6))])),
          input: 'vana');
      expect(_toggle('Apte'), findsNothing);
      await _pump(tester, _engine(dictionary: _entries([_entry(0, lines(7))])),
          input: 'vana');
      expect(_toggle('Apte'), findsOneWidget);
    });

    testWidgets('each section folds on its own', (tester) async {
      await _pump(tester,
          _engine(dictionary: _entries([_entry(0, _long), _entry(1, _long)])),
          input: 'vana');
      await tester.tap(_toggle('Apte'));
      await tester.pumpAndSettle();
      expect(tester.widget<SelectableText>(_body('Apte')).maxLines, isNull);
      expect(tester.widget<SelectableText>(_body('Monier-Williams')).maxLines,
          dictionaryCollapsedLines);
    });

    testWidgets('the real entries of वन are long enough to fold', (tester) async {
      await _pump(tester, _engine(dictionary: _answer('vana')), input: 'vana');
      expect(_toggle('Apte'), findsOneWidget);
      expect(_toggle('Cappeller'), findsOneWidget);
    });

    testWidgets('large text makes a short entry fold', (tester) async {
      final body = List.generate(5, (i) => 'row $i of the entry').join('\n');
      await _pump(tester, _engine(dictionary: _entries([_entry(0, body)])),
          input: 'vana');
      expect(_toggle('Apte'), findsNothing);
      await _pump(tester, _engine(dictionary: _entries([_entry(0, '$body ${'word ' * 400}')])),
          input: 'vana', textScale: 1.6);
      expect(_toggle('Apte'), findsOneWidget);
    });
  });

  group('the dictionaries that had no entry', () {
    testWidgets('none missing: no line', (tester) async {
      await _pump(tester, _engine(dictionary: _answer('vana')), input: 'vana');
      expect(find.byKey(const Key('dict-missing')), findsNothing);
    });

    testWidgets('two missing are named, in the standard order', (tester) async {
      await _pump(tester,
          _engine(dictionary: _entries([_entry(1, 'forest'), _entry(3, 'Wald')])),
          input: 'vana');
      expect(tester.widget<Text>(find.byKey(const Key('dict-missing'))).data,
          'No entry in Apte and Heritage.');
    });

    testWidgets('one missing, and three missing', (tester) async {
      await _pump(tester,
          _engine(dictionary: _entries([
            _entry(0, 'a'), _entry(1, 'b'), _entry(3, 'd'),
          ])),
          input: 'vana');
      expect(tester.widget<Text>(find.byKey(const Key('dict-missing'))).data,
          'No entry in Heritage.');
      await _pump(tester, _engine(dictionary: _entries([_entry(1, 'b')])),
          input: 'vana');
      expect(tester.widget<Text>(find.byKey(const Key('dict-missing'))).data,
          'No entry in Apte, Heritage and Cappeller.');
    });

    testWidgets('the line is at the end, below the last section', (tester) async {
      await _pump(tester, _engine(dictionary: _entries([_entry(1, 'forest')])),
          input: 'vana');
      expect(tester.getTopLeft(find.byKey(const Key('dict-missing'))).dy,
          greaterThan(tester.getBottomLeft(_section('Monier-Williams')).dy - 1));
    });

    test('namesList', () {
      expect(namesList(['A']), 'A');
      expect(namesList(['A', 'B']), 'A and B');
      expect(namesList(['A', 'B', 'C']), 'A, B and C');
      expect(namesList(const []), '');
    });
  });

  group('every result state', () {
    testWidgets('waiting', (tester) async {
      final e = _engine(
          dictionary: _answer('vana'), latency: const Duration(seconds: 1));
      await _pump(tester, e, input: 'vana', settle: false);
      expect(find.byKey(const Key('state-waiting')), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.byKey(const Key('state-waiting')), findsNothing);
      expect(_section('Apte'), findsOneWidget);
    });

    testWidgets('not found: "No entry for ...", never an empty page',
        (tester) async {
      await _pump(tester, _engine(dictionary: const NotFound()), input: 'xyzq');
      expect(find.byKey(const Key('state-notFound')), findsOneWidget);
      expect(find.text('No entry for xyzq'), findsOneWidget);
      expect(find.byKey(const Key('dict-headword')), findsNothing);
    });

    testWidgets('bad input', (tester) async {
      await _pump(tester, _engine(dictionary: const BadInput('Enter a word')),
          input: 'vana');
      expect(find.byKey(const Key('state-badInput')), findsOneWidget);
      expect(find.textContaining('Enter a word'), findsOneWidget);
    });

    testWidgets('server fault, with Retry, and no server text', (tester) async {
      final e = _engine(dictionary: const ServerFault('/var/www/html does not exist'));
      await _pump(tester, e, input: 'vana');
      expect(find.byKey(const Key('state-serverFault')), findsOneWidget);
      expect(find.textContaining('/var/www'), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(_calls(e).length, 2);
    });

    testWidgets('unreachable, with Retry', (tester) async {
      await _pump(tester, _engine(dictionary: const Unreachable('timeout')),
          input: 'vana');
      expect(find.byKey(const Key('state-unreachable')), findsOneWidget);
      expect(find.text("Can't reach Samsaadhanii."), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
