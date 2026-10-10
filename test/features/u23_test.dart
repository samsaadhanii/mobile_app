// U23: the waiting line, the session cache, Retry, the heading's space, and
// the field labels that follow the settings.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/settings.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/engines/common/response_cache.dart';
import 'package:mobile_app/engines/samsaadhanii/client.dart';
import 'package:mobile_app/engines/samsaadhanii/samsaadhanii_engine.dart';
import 'package:mobile_app/features/analyse_word/feature_labels.dart';
import 'package:mobile_app/features/task_frame/outcome_view.dart';
import 'package:mobile_app/features/task_frame/task_controller.dart';
import 'package:mobile_app/shared/data/word_lists.dart';
import 'package:mobile_app/shared/widgets/dhatu_picker.dart';
import 'package:mobile_app/shared/widgets/prefix_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _gam = 'gam1_gamLz_BvAxiH_gawO';
const _dir = 'test/fixtures/samsaadhanii';

/// Counts what reaches the network layer; answers with a saved verb answer,
/// or fails the way a test says.
class _CountingClient implements SamsaadhaniiClient {
  _CountingClient({this.fixture = 'gam', this.unreachable = false});

  final String fixture;
  bool unreachable;
  int calls = 0;

  @override
  Future<ClientResponse> get(String program, Map<String, String> query) async {
    calls++;
    if (unreachable) throw const UnreachableException('timeout');
    return ClientResponse(
        200, File('$_dir/verb_$fixture.json').readAsStringSync());
  }
}

SamsaadhaniiEngine _engine(_CountingClient c, {ResponseCache? cache}) =>
    SamsaadhaniiEngine(
        client: c, now: () => DateTime.utc(2026, 10, 10), cache: cache);

void main() {
  group('the session cache', () {
    const query = VerbQuery(root: _gam);

    test('a second identical request makes no network call', () async {
      final client = _CountingClient();
      final engine = _engine(client);
      final first = await engine.conjugateVerb(query);
      final second = await engine.conjugateVerb(query);
      expect(first, isA<Found<VerbParadigm>>());
      expect(second, first);
      expect(client.calls, 1);
    });

    test('another query is another entry', () async {
      final client = _CountingClient();
      final engine = _engine(client);
      await engine.conjugateVerb(query);
      await engine.conjugateVerb(const VerbQuery(root: _gam, prefix: 'Af'));
      expect(client.calls, 2);
    });

    test('Retry (runFresh) always goes to the server, and replaces the entry',
        () async {
      final client = _CountingClient();
      final engine = _engine(client);
      await engine.conjugateVerb(query);
      await runFresh(() => engine.conjugateVerb(query));
      expect(client.calls, 2);
      await engine.conjugateVerb(query); // kept again
      expect(client.calls, 2);
    });

    test('a failure is not kept', () async {
      final client = _CountingClient(unreachable: true);
      final engine = _engine(client);
      expect(await engine.conjugateVerb(query), isA<Unreachable<VerbParadigm>>());
      client.unreachable = false;
      expect(await engine.conjugateVerb(query), isA<Found<VerbParadigm>>());
      expect(client.calls, 2);
    });

    test('NotFound is not kept', () async {
      final client = _CountingClient(fixture: 'xyzq');
      final engine = _engine(client);
      const q = VerbQuery(root: 'xyzq');
      expect(await engine.conjugateVerb(q), isA<NotFound<VerbParadigm>>());
      await engine.conjugateVerb(q);
      expect(client.calls, 2);
    });

    test('the key is engine, program and the whole query', () {
      final a = ResponseCache.keyFor(
          EngineId.samsaadhanii, 'verb_gen.cgi', {'a': '1', 'b': '2'});
      expect(
          ResponseCache.keyFor(
              EngineId.samsaadhanii, 'verb_gen.cgi', {'b': '2', 'a': '1'}),
          a);
      expect(
          ResponseCache.keyFor(
              EngineId.heritage, 'verb_gen.cgi', {'a': '1', 'b': '2'}),
          isNot(a));
      expect(
          ResponseCache.keyFor(
              EngineId.samsaadhanii, 'morph.cgi', {'a': '1', 'b': '2'}),
          isNot(a));
      expect(
          ResponseCache.keyFor(
              EngineId.samsaadhanii, 'verb_gen.cgi', {'a': '1', 'b': '3'}),
          isNot(a));
    });

    test('the 61st entry drops the oldest; a read keeps an entry young', () {
      final cache = ResponseCache();
      final source = ResultSource(
          engine: EngineId.samsaadhanii,
          program: 'p',
          time: DateTime.utc(2026));
      for (var i = 0; i < 60; i++) {
        cache.put('k$i', Found<int>(i, source));
      }
      expect(cache.length, 60);
      expect(cache.get<int>('k0'), isNotNull); // k0 is now the youngest
      cache.put('k60', Found<int>(60, source));
      expect(cache.length, 60);
      expect(cache.get<int>('k1'), isNull); // the oldest went
      expect(cache.get<int>('k0'), isNotNull);
      expect(cache.get<int>('k60'), isNotNull);
    });

    test('the heading has a space before the bracket, in every script',
        () async {
      final o = await _engine(_CountingClient()).conjugateVerb(query);
      final heading = (o as Found<VerbParadigm>).value.heading;
      expect(heading.display(Script.iast), 'gam (bhvādiḥ)');
      expect(heading.display(Script.devanagari), 'गम् (भ्वादिः)');
    });
  });

  group('Retry through the controller', () {
    test('request() may use the cache; retry() asks for a fresh answer',
        () async {
      final seen = <bool>[];
      final task = TaskController<int>(
        available: const [EngineId.samsaadhanii],
        preferred: EngineId.samsaadhanii,
        run: (id) async {
          seen.add(isFreshRequest);
          return Found(
              1,
              ResultSource(
                  engine: id, program: 'p', time: DateTime.utc(2026)));
        },
      );
      await task.request();
      await task.retry();
      expect(seen, [false, true]);
      task.dispose();
    });
  });

  group('the waiting line', () {
    Widget view(Outcome<int>? outcome) => MaterialApp(
          home: Scaffold(
            body: OutcomeView<int>(
              outcome: outcome,
              engine: EngineId.samsaadhanii,
              notFoundTitle: 'none',
              onRetry: () {},
              builder: (v, s) => Text('found $v'),
            ),
          ),
        );

    testWidgets('appears after four seconds, not before, and goes with the '
        'answer', (tester) async {
      await tester.pumpWidget(view(null));
      expect(find.byKey(const Key('state-waiting')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 3900));
      expect(find.byKey(const Key('waiting-slow')), findsNothing);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Samsaadhanii is taking longer than usual.'),
          findsOneWidget);

      await tester.pumpWidget(view(Found(
          7,
          ResultSource(
              engine: EngineId.samsaadhanii,
              program: 'p',
              time: DateTime.utc(2026)))));
      expect(find.byKey(const Key('waiting-slow')), findsNothing);
      expect(find.text('found 7'), findsOneWidget);
    });

    testWidgets('goes with a failure too', (tester) async {
      await tester.pumpWidget(view(null));
      await tester.pump(const Duration(seconds: 5));
      expect(find.byKey(const Key('waiting-slow')), findsOneWidget);
      await tester.pumpWidget(view(const Unreachable('x')));
      expect(find.byKey(const Key('waiting-slow')), findsNothing);
      expect(find.byKey(const Key('state-unreachable')), findsOneWidget);
    });
  });

  group('field labels', () {
    String label(ToolField f, LabelLanguage l, Script s) =>
        toolFieldLabel(f, language: l, display: s);

    test('Sanskrit with IAST, Sanskrit with Devanagari, English', () {
      const sk = LabelLanguage.sanskrit, en = LabelLanguage.english;
      expect([
        for (final f in ToolField.values) label(f, sk, Script.iast),
      ], ['dhātuḥ', 'upasargaḥ', 'liṅgam', 'prakāraḥ']);
      expect([
        for (final f in ToolField.values) label(f, sk, Script.devanagari),
      ], ['धातुः', 'उपसर्गः', 'लिङ्गम्', 'प्रकारः']);
      expect([
        for (final f in ToolField.values) label(f, en, Script.devanagari),
      ], ['Root', 'Prefix', 'Gender', 'Category']);
      expect(label(ToolField.dhatu, en, Script.iast), 'Root');
    });

    Future<void> pumpPickers(
        WidgetTester tester, Map<String, Object> prefs) async {
      SharedPreferences.setMockInitialValues(prefs);
      final settings = await AppSettings.load();
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider<DhatuList>.value(
              value: DhatuList.fromEntries(const [])),
          ChangeNotifierProvider<PrefixList>.value(
              value: PrefixList.fromEntries(const [])),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Column(children: [
              DhatuPicker(selectedWx: '', onChanged: (_) {}),
              PrefixPicker(selected: null, onChanged: (_) {}),
            ]),
          ),
        ),
      ));
      await tester.pump();
    }

    testWidgets('the pickers: Sanskrit in Devanagari', (tester) async {
      await pumpPickers(tester, {'settings.displayScript': 'devanagari'});
      expect(find.text('धातुः'), findsOneWidget);
      expect(find.text('उपसर्गः'), findsOneWidget);
      expect(find.text('Select…'), findsOneWidget);
      expect(find.text('None'), findsOneWidget);
    });

    testWidgets('the pickers: Sanskrit in IAST', (tester) async {
      await pumpPickers(tester, {'settings.displayScript': 'iast'});
      expect(find.text('dhātuḥ'), findsOneWidget);
      expect(find.text('upasargaḥ'), findsOneWidget);
    });

    testWidgets('the pickers: English', (tester) async {
      await pumpPickers(tester, {
        'settings.displayScript': 'devanagari',
        'settings.labelLanguage': 'english',
      });
      expect(find.text('Root'), findsOneWidget);
      expect(find.text('Prefix'), findsOneWidget);
    });
  });
}
