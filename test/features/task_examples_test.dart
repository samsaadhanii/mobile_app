import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/settings.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/features/analyse_word/analyse_word_screen.dart';
import 'package:mobile_app/features/dictionary/dictionary_screen.dart';
import 'package:mobile_app/features/join_words/join_words_screen.dart';
import 'package:mobile_app/features/krt_forms/krt_forms_screen.dart';
import 'package:mobile_app/features/noun_forms/noun_forms_screen.dart';
import 'package:mobile_app/features/split/split_screen.dart';
import 'package:mobile_app/features/task_frame/engine_set.dart';
import 'package:mobile_app/features/task_frame/task_examples.dart';
import 'package:mobile_app/features/verb_forms/verb_forms_screen.dart';
import 'package:mobile_app/shared/data/word_lists.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_engine.dart';

const _gam = 'gam1_gamLz_BvAxiH_gawO';
const _kr = 'kq3_dukqF_wanAxiH_karaNe';
const _paTh = 'paT1_paTaz_BvAxiH_vyakwAyAM_vAci';

final _dhatus = DhatuList.fromEntries([
  ListEntry(_gam, 'गम् (गम्) गतौ भ्वादिः', 'gam (gam) gatau bhvādiḥ'),
  ListEntry(_kr, 'कृ (डुकृञ्) करणे तनादिः', 'kṛ (ḍukṛñ) karaṇe tanādiḥ'),
  ListEntry(_paTh, 'पठ् (पठ्) व्यक्तायां वाचि भ्वादिः',
      'paṭh (paṭh) vyaktāyāṃ vāci bhvādiḥ'),
]);

final _prefixes = PrefixList.fromEntries([
  ListEntry('Af', 'आङ्', 'āṅ'),
  ListEntry('pra', 'प्र', 'pra'),
]);

final _allTasks = Task.values.toSet();

Future<FakeEngine> _pump(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final settings = await AppSettings.load();
  final engine = FakeEngine(tasks: _allTasks);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: _dhatus),
      ChangeNotifierProvider.value(value: _prefixes),
      Provider<EngineSet>.value(value: EngineSet({engine.id: engine})),
    ],
    child: MaterialApp(key: UniqueKey(), home: screen),
  ));
  await tester.pump();
  return engine;
}

Finder get _chips => find.descendant(
    of: find.byKey(const Key('examples')), matching: find.byType(ActionChip));

Finder get _examples => find.byKey(const Key('examples'));

/// One screen under test: how to open it, how many examples it offers, the
/// engine call the first example must make, and how to clear its input.
class _Case {
  const _Case(this.name, this.screen, this.count, this.firstCall,
      {this.fields = 1});

  final String name;
  final Widget screen;
  final int count;
  final String firstCall;
  final int fields;
}

final _cases = <_Case>[
  const _Case('Analyse a word', AnalyseWordScreen(), 5, 'analyseWord:rAmaH'),
  const _Case('Split and analyse', SplitScreen(), 3,
      'segment:rAmo vanaM gacCawi:analyse'),
  const _Case('Noun forms', NounFormsScreen(), 4,
      'declineNoun:rAma:masculine:plainNoun'),
  const _Case('Join words', JoinWordsScreen(), 3, 'joinSandhi:rAmaH:AlayaH',
      fields: 2),
  const _Case('Dictionary', DictionaryScreen(), 3, 'lookUp:vana'),
];

void main() {
  for (final c in _cases) {
    group('${c.name}: examples', () {
      testWidgets('are shown while the screen is empty', (tester) async {
        await _pump(tester, c.screen);
        expect(_examples, findsOneWidget);
        expect(find.text('Try'), findsOneWidget);
        expect(_chips, findsNWidgets(c.count));
      });

      testWidgets('tapping the first fills the inputs and runs the request',
          (tester) async {
        final engine = await _pump(tester, c.screen);
        await tester.tap(_chips.first);
        await tester.pumpAndSettle();
        expect(engine.calls, [c.firstCall]);
        final filled = [
          for (final f in tester.widgetList<TextField>(find.byType(TextField)))
            f.controller!.text,
        ];
        expect(filled.where((t) => t.isNotEmpty), hasLength(c.fields));
      });

      testWidgets('go on a result and return when the input is cleared',
          (tester) async {
        await _pump(tester, c.screen);
        await tester.tap(_chips.first);
        await tester.pumpAndSettle();
        expect(_examples, findsNothing);

        for (final f in tester.widgetList<TextField>(find.byType(TextField))) {
          f.controller!.clear();
        }
        await tester.pumpAndSettle();
        expect(_examples, findsOneWidget);
        expect(_chips, findsNWidgets(c.count));
      });

      testWidgets('go when the user types', (tester) async {
        await _pump(tester, c.screen);
        await tester.enterText(find.byType(TextField).first, 'x');
        await tester.pump();
        expect(_examples, findsNothing);
        await tester.enterText(find.byType(TextField).first, '');
        await tester.pump();
        expect(_examples, findsOneWidget);
      });
    });
  }

  group('Analyse a word: every example', () {
    testWidgets('asks the engine for its own word', (tester) async {
      const wx = ['rAmaH', 'gacCawi', 'gacCan', 'aham', 'gamyawe'];
      for (var i = 0; i < wx.length; i++) {
        final engine = await _pump(tester, const AnalyseWordScreen());
        await tester.tap(_chips.at(i));
        await tester.pumpAndSettle();
        expect(engine.calls, ['analyseWord:${wx[i]}']);
      }
    });
  });

  group('Noun forms: examples set gender and category', () {
    testWidgets('a pronoun with no gender is a sarvanāma', (tester) async {
      final engine = await _pump(tester, const NounFormsScreen());
      await tester.tap(_chips.at(3));
      await tester.pumpAndSettle();
      expect(engine.calls, ['declineNoun:asmax:noGender:sarvanama']);
    });

    testWidgets('a feminine stem', (tester) async {
      final engine = await _pump(tester, const NounFormsScreen());
      await tester.tap(_chips.at(1));
      await tester.pumpAndSettle();
      expect(engine.calls, ['declineNoun:naxI:feminine:plainNoun']);
    });
  });

  group('Verb forms: examples set root, prefix and voice', () {
    testWidgets('shown while nothing is picked', (tester) async {
      await _pump(tester, const VerbFormsScreen());
      expect(_chips, findsNWidgets(5));
    });

    testWidgets('each example makes its own request', (tester) async {
      const expected = [
        'conjugateVerb:$_gam:-:kartari',
        'conjugateVerb:$_gam:Af:kartari',
        'conjugateVerb:$_kr:-:kartari',
        'conjugateVerb:$_gam:-:karmani',
        'conjugateVerb:$_gam:-:nijanta',
      ];
      for (var i = 0; i < expected.length; i++) {
        final engine = await _pump(tester, const VerbFormsScreen());
        await tester.tap(_chips.at(i));
        await tester.pumpAndSettle();
        expect(engine.calls, [expected[i]]);
        expect(_examples, findsNothing);
      }
    });
  });

  group('Kṛt forms: examples set root and prefix', () {
    testWidgets('each example makes its own request', (tester) async {
      const expected = [
        'krtForms:$_gam:-',
        'krtForms:$_kr:-',
        'krtForms:$_paTh:-',
        'krtForms:$_gam:pra',
      ];
      for (var i = 0; i < expected.length; i++) {
        final engine = await _pump(tester, const KrtFormsScreen());
        expect(_chips, findsNWidgets(4));
        await tester.tap(_chips.at(i));
        await tester.pumpAndSettle();
        expect(engine.calls, [expected[i]]);
        expect(_examples, findsNothing);
      }
    });
  });

  test('every dhātu and prefix key used by an example is in the bundled lists',
      () {
    final dhatus = {
      for (final e in jsonDecode(File('assets/verblist.json').readAsStringSync())
          as List)
        (e as Map)['wx'],
    };
    final prefixes = {
      for (final e
          in jsonDecode(File('assets/prefix_list.json').readAsStringSync())
              as List)
        (e as Map)['wx'],
    };
    for (final e in [...verbExamples, ...krtExamples]) {
      expect(dhatus, contains(e.root), reason: e.labelDev);
      if (e.prefix != null) {
        expect(prefixes, contains(e.prefix), reason: e.labelDev);
      }
    }
  });
}
