import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/settings.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/engines/samsaadhanii/sandhi_adapter.dart';
import 'package:mobile_app/features/join_words/join_words_screen.dart';
import 'package:mobile_app/features/task_frame/engine_set.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_engine.dart';

ResultSource _src() => ResultSource(
    engine: EngineId.samsaadhanii,
    program: 'sandhi_json.cgi',
    time: DateTime.utc(2026, 10, 5));

/// The real answer for two words, through the real adapter.
SandhiResult _answer(String fixture, String l, String r) => (parseSandhi(
        File('test/fixtures/samsaadhanii/sandhi_$fixture.json').readAsStringSync(),
        SanskritText(l),
        SanskritText(r),
        _src()) as Found<SandhiResult>)
    .value;

Outcome<SandhiResult> _rama() => Found(_answer('rAmaH_AlayaH', 'rAmaH', 'AlayaH'), _src());

Outcome<SandhiResult> _laksmi() => Found(
    _answer('lakRmIvAn_SuBalakRaNaH', 'lakRmIvAn', 'SuBalakRaNaH'), _src());

Outcome<SandhiResult> _ayam() => Found(_answer('rAma_ayam', 'rAma', 'ayam'), _src());

FakeEngine _engine({Outcome<SandhiResult>? sandhi, Duration latency = Duration.zero}) =>
    FakeEngine(
      tasks: const {Task.analyseWord, Task.joinWords},
      sandhi: sandhi,
      latency: latency,
    );

Future<AppSettings> _pump(
  WidgetTester tester,
  FakeEngine engine, {
  String input = '',
  Map<String, Object> prefs = const {},
  void Function(String)? onOpen,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(1000, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final settings = await AppSettings.load();
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      Provider<EngineSet>.value(value: EngineSet({EngineId.samsaadhanii: engine})),
    ],
    child: MaterialApp(
      home: JoinWordsScreen(
        initialInput: input,
        onOpenTool: onOpen == null
            ? null
            : (e, i, {gender, prefix}) => onOpen('${e.nameEn}|$i'),
      ),
    ),
  ));
  settle ? await tester.pumpAndSettle() : await tester.pump();
  return settings;
}

Finder _inSheet(String text) =>
    find.descendant(of: find.byType(BottomSheet), matching: find.text(text));

Finder _option(int i) => find.byKey(Key('sandhi-option-$i'));

Finder _within(int i, Key key) =>
    find.descendant(of: _option(i), matching: find.byKey(key));

String _text(WidgetTester tester, Finder f) => tester.widget<Text>(f).data!;

List<String> _calls(FakeEngine e) =>
    [for (final c in e.calls) if (c.startsWith('joinSandhi')) c];

Future<void> _level(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(
      of: find.byKey(const Key('level-switch')), matching: find.text(label)));
  await tester.pumpAndSettle();
}

void main() {
  group('the inputs', () {
    testWidgets('empty: two fields, the level, no request, no result',
        (tester) async {
      final e = _engine(sandhi: _rama());
      await _pump(tester, e);
      expect(find.text('First word'), findsOneWidget);
      expect(find.text('Second word'), findsOneWidget);
      expect(find.text('Learner level'), findsOneWidget);
      for (final l in ['Basic', 'Intermediate', 'Advanced']) {
        expect(find.text(l), findsOneWidget, reason: l);
      }
      expect(e.calls, isEmpty);
      expect(find.byKey(const Key('sandhi-option-0')), findsNothing);
    });

    testWidgets('exactly two words from Home fill both fields and join at once',
        (tester) async {
      final e = _engine(sandhi: _rama());
      await _pump(tester, e, input: 'rAmaH AlayaH');
      expect(_calls(e), ['joinSandhi:rAmaH:AlayaH']);
      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields[0].controller!.text, 'rAmaH');
      expect(fields[1].controller!.text, 'AlayaH');
      expect(_option(0), findsOneWidget);
    });

    testWidgets('Devanagari words are read as Devanagari', (tester) async {
      final e = _engine(sandhi: _rama());
      await _pump(tester, e, input: 'रामः आलयः');
      expect(_calls(e), ['joinSandhi:rAmaH:AlayaH']);
    });

    testWidgets('one word fills the first field and waits', (tester) async {
      final e = _engine(sandhi: _rama());
      await _pump(tester, e, input: 'rAmaH');
      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields[0].controller!.text, 'rAmaH');
      expect(fields[1].controller!.text, '');
      expect(e.calls, isEmpty);
    });

    testWidgets('typing two words and pressing the button joins them',
        (tester) async {
      final e = _engine(sandhi: _rama());
      await _pump(tester, e);
      await tester.enterText(find.byType(TextField).first, 'rAmaH');
      await tester.enterText(find.byType(TextField).last, 'AlayaH');
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(_calls(e), ['joinSandhi:rAmaH:AlayaH']);
    });

    testWidgets('the keyboard action on the second field joins too',
        (tester) async {
      final e = _engine(sandhi: _rama());
      await _pump(tester, e);
      await tester.enterText(find.byType(TextField).first, 'rAmaH');
      await tester.enterText(find.byType(TextField).last, 'AlayaH');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(_calls(e), ['joinSandhi:rAmaH:AlayaH']);
    });

    testWidgets('an empty second word says "Enter two words"', (tester) async {
      final e = _engine(sandhi: _rama());
      await _pump(tester, e);
      await tester.enterText(find.byType(TextField).first, 'rAmaH');
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('state-badInput')), findsOneWidget);
      expect(find.textContaining('Enter two words'), findsOneWidget);
      expect(find.byKey(const Key('sandhi-option-0')), findsNothing);
    });

    testWidgets('no engine switch and no Compare', (tester) async {
      await _pump(tester, _engine(sandhi: _rama()), input: 'rAmaH AlayaH');
      expect(find.byKey(const Key('engine-switch')), findsNothing);
      expect(find.byKey(const Key('compare-button')), findsNothing);
    });
  });

  group('the learner levels', () {
    testWidgets('Basic: the words, the letters that meet, the joined form',
        (tester) async {
      await _pump(tester, _engine(sandhi: _rama()), input: 'rAmaH AlayaH');
      expect(find.text('Basic'), findsOneWidget);
      // The two words, in the display script (IAST).
      expect(find.descendant(of: _option(0), matching: find.text('rāmaḥ')),
          findsOneWidget);
      expect(find.descendant(of: _option(0), matching: find.text('ālayaḥ')),
          findsOneWidget);
      // The letters that meet, large.
      final letters = _within(0, const Key('sandhi-letters'));
      expect(_text(tester, letters), 'ḥ + ā  →  ā');
      expect(tester.widget<Text>(letters).style!.fontSize, greaterThanOrEqualTo(24));
      // The joined form, with its space.
      expect(
          _text(
              tester,
              find.descendant(
                  of: _within(0, const Key('sandhi-joined')),
                  matching: find.byType(Text))),
          'rāma ālayaḥ');
      // Nothing more.
      expect(find.byKey(const Key('sandhi-steps')), findsNothing);
      expect(find.byKey(const Key('sandhi-sutra')), findsNothing);
      expect(find.byKey(const Key('sandhi-spelling-left')), findsNothing);
    });

    testWidgets('"Show spelling" reveals each word letter by letter',
        (tester) async {
      await _pump(tester, _engine(sandhi: _rama()), input: 'rAmaH AlayaH');
      expect(find.text('Show spelling'), findsOneWidget);
      await tester.tap(find.byKey(const Key('spelling-switch')));
      await tester.pumpAndSettle();
      expect(_text(tester, _within(0, const Key('sandhi-spelling-left'))), 'r ā m a ḥ');
      expect(_text(tester, _within(0, const Key('sandhi-spelling-right'))), 'ā l a y a ḥ');
      // For every option.
      expect(_within(1, const Key('sandhi-spelling-left')), findsOneWidget);
      await tester.tap(find.byKey(const Key('spelling-switch')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sandhi-spelling-left')), findsNothing);
    });

    testWidgets('a letter such as bh is one letter in the spelling',
        (tester) async {
      await _pump(tester, _engine(sandhi: _laksmi()), input: 'lakRmIvAn SuBalakRaNaH');
      await tester.tap(find.byKey(const Key('spelling-switch')));
      await tester.pumpAndSettle();
      expect(_text(tester, _within(0, const Key('sandhi-spelling-right'))),
          startsWith('ś u bh a l a'));
    });

    testWidgets('Intermediate adds the name of the sandhi, its steps joined by arrows',
        (tester) async {
      await _pump(tester, _engine(sandhi: _rama()),
          input: 'rAmaH AlayaH', prefs: {'settings.learnerLevel': 'intermediate'});
      expect(_text(tester, _within(0, const Key('sandhi-steps'))),
          'rutva  →  yatva  →  lopa');
      expect(_text(tester, _within(1, const Key('sandhi-steps'))), 'rutva  →  yatva');
      expect(find.byKey(const Key('sandhi-sutra')), findsNothing);
      // Still has the Basic content.
      expect(_within(0, const Key('sandhi-letters')), findsOneWidget);
    });

    testWidgets('Advanced adds each sūtra with its number', (tester) async {
      await _pump(tester, _engine(sandhi: _rama()),
          input: 'rAmaH AlayaH', prefs: {'settings.learnerLevel': 'advanced'});
      final first = find.descendant(of: _option(0), matching: find.byKey(const Key('sandhi-sutra')));
      expect(first, findsNWidgets(3));
      final plain = [
        for (final t in tester.widgetList<Text>(first)) t.textSpan!.toPlainText(),
      ];
      expect(plain, [
        '8.2.66  sasajuṣo ruḥ',
        "8.3.17  bhobhago agho apūrvasya yo'śi",
        '8.3.19  lopaḥ śākalyasya',
      ]);
      // And the steps and the Basic content.
      expect(_within(0, const Key('sandhi-steps')), findsOneWidget);
      expect(_within(0, const Key('sandhi-letters')), findsOneWidget);
    });

    testWidgets('a sūtra with no number is shown by its text alone',
        (tester) async {
      await _pump(tester, _engine(sandhi: _laksmi()),
          input: 'lakRmIvAn SuBalakRaNaH', prefs: {'settings.learnerLevel': 'advanced'});
      // The second option's sūtras are names with no brackets.
      final second = find.descendant(of: _option(1), matching: find.byKey(const Key('sandhi-sutra')));
      expect(second, findsNWidgets(5));
      final plain = [
        for (final t in tester.widgetList<Text>(second)) t.textSpan!.toPlainText(),
      ];
      expect(plain, ['tugāgama', 'ścutva', 'cartva', 'chatva', 'lopābhāvaḥ']);
    });

    testWidgets('changing the level changes the screen and is remembered',
        (tester) async {
      final prefs = <String, Object>{};
      final settings = await _pump(tester, _engine(sandhi: _rama()),
          input: 'rAmaH AlayaH', prefs: prefs);
      expect(find.byKey(const Key('sandhi-steps')), findsNothing);
      await _level(tester, 'Intermediate');
      expect(find.byKey(const Key('sandhi-steps')), findsNWidgets(2));
      expect(find.byKey(const Key('sandhi-sutra')), findsNothing);
      await _level(tester, 'Advanced');
      expect(find.byKey(const Key('sandhi-sutra')), findsNWidgets(5));
      await _level(tester, 'Basic');
      expect(find.byKey(const Key('sandhi-steps')), findsNothing);
      // Stored with the settings.
      await _level(tester, 'Advanced');
      expect(settings.learnerLevel, LearnerLevel.advanced);
      final stored = await SharedPreferences.getInstance();
      expect(stored.getString('settings.learnerLevel'), 'advanced');
    });

    testWidgets('the stored level is the one the screen opens on', (tester) async {
      await _pump(tester, _engine(sandhi: _rama()),
          input: 'rAmaH AlayaH', prefs: {'settings.learnerLevel': 'advanced'});
      final switchWidget = tester.widget<SegmentedButton<LearnerLevel>>(
          find.byKey(const Key('level-switch')));
      expect(switchWidget.selected, {LearnerLevel.advanced});
      expect(find.byKey(const Key('sandhi-sutra')), findsNWidgets(5));
    });

    testWidgets('a level is not asked for again when the words change',
        (tester) async {
      await _pump(tester, _engine(sandhi: _ayam()),
          input: 'rAma ayam', prefs: {'settings.learnerLevel': 'intermediate'});
      expect(_text(tester, _within(0, const Key('sandhi-steps'))), 'savarṇadīrgha');
    });
  });

  group('one option or several', () {
    testWidgets('one option: no heading and no "Way 1"', (tester) async {
      await _pump(tester, _engine(sandhi: _ayam()), input: 'rAma ayam');
      expect(find.byKey(const Key('sandhi-count')), findsNothing);
      expect(find.textContaining('Way '), findsNothing);
      expect(_option(0), findsOneWidget);
      expect(_option(1), findsNothing);
    });

    testWidgets('two options: "2 ways to join" and a block each, in order',
        (tester) async {
      await _pump(tester, _engine(sandhi: _rama()), input: 'rAmaH AlayaH');
      expect(find.text('2 ways to join'), findsOneWidget);
      expect(find.text('Way 1'), findsOneWidget);
      expect(find.text('Way 2'), findsOneWidget);
      final joined = find.byKey(const Key('sandhi-joined'));
      final texts = [
        for (final w in tester.widgetList<Text>(
            find.descendant(of: joined, matching: find.byType(Text))))
          w.data,
      ];
      expect(texts, ['rāma ālayaḥ', 'rāmayālayaḥ']);
      // Top to bottom, as the server sent them.
      expect(tester.getTopLeft(_option(0)).dy, lessThan(tester.getTopLeft(_option(1)).dy));
    });

    testWidgets('four options', (tester) async {
      await _pump(tester, _engine(sandhi: _laksmi()), input: 'lakRmIvAn SuBalakRaNaH');
      expect(find.text('4 ways to join'), findsOneWidget);
      for (var i = 0; i < 4; i++) {
        expect(_option(i), findsOneWidget);
      }
      expect(_text(tester, _within(3, const Key('sandhi-letters'))), 'n + ś  →  ñś');
    });
  });

  group('the display script', () {
    testWidgets('Devanagari: words, letters, joined form, steps, sūtras, spelling',
        (tester) async {
      await _pump(tester, _engine(sandhi: _rama()),
          input: 'rAmaH AlayaH',
          prefs: {
            'settings.displayScript': 'devanagari',
            'settings.learnerLevel': 'advanced',
          });
      expect(find.descendant(of: _option(0), matching: find.text('रामः')), findsOneWidget);
      expect(_text(tester, _within(0, const Key('sandhi-letters'))), 'ः + आ  →  आ');
      expect(find.text('राम आलयः'), findsOneWidget);
      expect(_text(tester, _within(0, const Key('sandhi-steps'))), 'रुत्व  →  यत्व  →  लोप');
      final sutra = tester
          .widget<Text>(find
              .descendant(of: _option(0), matching: find.byKey(const Key('sandhi-sutra')))
              .first)
          .textSpan!
          .toPlainText();
      expect(sutra, '8.2.66  ससजुषो रुः');
      await tester.tap(find.byKey(const Key('spelling-switch')));
      await tester.pumpAndSettle();
      expect(_text(tester, _within(0, const Key('sandhi-spelling-right'))), startsWith('आ ल'));
    });

    testWidgets('every Sanskrit text is at least 16 sp', (tester) async {
      await _pump(tester, _engine(sandhi: _rama()),
          input: 'rAmaH AlayaH', prefs: {'settings.learnerLevel': 'advanced'});
      await tester.tap(find.byKey(const Key('spelling-switch')));
      await tester.pumpAndSettle();
      for (final key in [
        'sandhi-letters', 'sandhi-joined', 'sandhi-steps',
        'sandhi-spelling-left', 'sandhi-spelling-right',
      ]) {
        for (final w in tester.widgetList<Text>(find.descendant(
            of: find.byKey(const Key('sandhi-option-0')),
            matching: key == 'sandhi-joined'
                ? find.descendant(of: find.byKey(Key(key)), matching: find.byType(Text))
                : find.byKey(Key(key))))) {
          expect(w.style!.fontSize, greaterThanOrEqualTo(16), reason: key);
        }
      }
      for (final w in tester.widgetList<Text>(find.byKey(const Key('sandhi-sutra')))) {
        expect(w.style!.fontSize, greaterThanOrEqualTo(16));
      }
    });
  });

  group('the joined form', () {
    Future<void> open(WidgetTester tester, {void Function(String)? onOpen}) async {
      await _pump(tester, _engine(sandhi: _rama()),
          input: 'rAmaH AlayaH', onOpen: onOpen);
    }

    testWidgets('a single word: the words in the description, Analyse and Split',
        (tester) async {
      await open(tester, onOpen: (_) {});
      await tester.tap(find.descendant(
          of: _within(1, const Key('sandhi-joined')), matching: find.byType(Text)));
      await tester.pumpAndSettle();
      expect(_inSheet('rāmayālayaḥ'), findsOneWidget);
      expect(_inSheet('rāmaḥ + ālayaḥ'), findsOneWidget);
      expect(_inSheet('Analyse this form'), findsOneWidget);
      expect(_inSheet('Split it again'), findsOneWidget);
    });

    testWidgets('a form that stayed in two words is for Split only',
        (tester) async {
      await open(tester, onOpen: (_) {});
      await tester.tap(find.descendant(
          of: _within(0, const Key('sandhi-joined')), matching: find.byType(Text)));
      await tester.pumpAndSettle();
      expect(_inSheet('rāma ālayaḥ'), findsOneWidget);
      expect(_inSheet('Analyse this form'), findsNothing);
      expect(_inSheet('Split it again'), findsOneWidget);
    });

    testWidgets('"Analyse this form" opens Analyse a word with the form',
        (tester) async {
      final opened = <String>[];
      await open(tester, onOpen: opened.add);
      await tester.tap(find.descendant(
          of: _within(1, const Key('sandhi-joined')), matching: find.byType(Text)));
      await tester.pumpAndSettle();
      await tester.tap(_inSheet('Analyse this form'));
      await tester.pumpAndSettle();
      expect(opened, ['Analyse a word|रामयालयः']);
    });

    testWidgets('"Split it again" opens Split and analyse with the form',
        (tester) async {
      final opened = <String>[];
      await open(tester, onOpen: opened.add);
      await tester.tap(find.descendant(
          of: _within(0, const Key('sandhi-joined')), matching: find.byType(Text)));
      await tester.pumpAndSettle();
      await tester.tap(_inSheet('Split it again'));
      await tester.pumpAndSettle();
      expect(opened, ['Split and analyse|राम आलयः']);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('without a way to open tools the sheet has no actions',
        (tester) async {
      await open(tester);
      await tester.tap(find.descendant(
          of: _within(1, const Key('sandhi-joined')), matching: find.byType(Text)));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(_inSheet('Split it again'), findsNothing);
      expect(_inSheet('Analyse this form'), findsNothing);
    });
  });

  group('every result state', () {
    testWidgets('waiting', (tester) async {
      final e = _engine(sandhi: _rama(), latency: const Duration(seconds: 1));
      await _pump(tester, e, input: 'rAmaH AlayaH', settle: false);
      expect(find.byKey(const Key('state-waiting')), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.byKey(const Key('state-waiting')), findsNothing);
      expect(_option(0), findsOneWidget);
    });

    testWidgets('the credit line', (tester) async {
      await _pump(tester, _engine(sandhi: _rama()), input: 'rAmaH AlayaH');
      expect(find.text('From Samsaadhanii, University of Hyderabad'), findsOneWidget);
    });

    testWidgets('not found names the two words', (tester) async {
      await _pump(tester, _engine(sandhi: const NotFound()), input: 'xyzq abc');
      expect(find.byKey(const Key('state-notFound')), findsOneWidget);
      expect(find.text('No sandhi forms for xyzq + abc'), findsOneWidget);
      expect(find.byKey(const Key('sandhi-option-0')), findsNothing);
    });

    testWidgets('server fault, with Retry', (tester) async {
      final e = _engine(sandhi: const ServerFault('bad json'));
      await _pump(tester, e, input: 'rAmaH AlayaH');
      expect(find.byKey(const Key('state-serverFault')), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(_calls(e).length, 2);
    });

    testWidgets('unreachable, with Retry', (tester) async {
      await _pump(tester, _engine(sandhi: const Unreachable('timeout')),
          input: 'rAmaH AlayaH');
      expect(find.byKey(const Key('state-unreachable')), findsOneWidget);
      expect(find.text("Can't reach Samsaadhanii."), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
