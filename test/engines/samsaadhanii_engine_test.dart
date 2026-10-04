import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/engines/samsaadhanii/client.dart';
import 'package:mobile_app/engines/common/input.dart';
import 'package:mobile_app/engines/samsaadhanii/samsaadhanii_engine.dart';

const _dir = 'test/fixtures/samsaadhanii';

String _fixture(String name) => File('$_dir/$name').readAsStringSync();

/// Answers with the saved file for the request, or with what a test says.
class FakeClient implements SamsaadhaniiClient {
  FakeClient(this.respond);

  final ClientResponse Function(String program, Map<String, String> query)
      respond;
  final List<Map<String, String>> queries = [];

  /// Serves the captured fixtures.
  factory FakeClient.fixtures() => FakeClient((program, query) {
        if (program == morphProgram) {
          final word = query['morfword']!;
          return ClientResponse(
              200, _fixture('morph_${word.isEmpty ? 'empty' : word}.txt'));
        }
        final text = query['word']!;
        final name = text.isEmpty ? 'sent_empty' : '${query['mode']}_$text';
        return ClientResponse(200, _fixture('split_$name.txt'));
      });

  @override
  Future<ClientResponse> get(String program, Map<String, String> query) async {
    queries.add(query);
    return respond(program, query);
  }
}

final _now = DateTime.utc(2026, 10, 3, 12);

SamsaadhaniiEngine _engine(FakeClient client, {List<String>? unmapped}) {
  final e = SamsaadhaniiEngine(client: client, now: () => _now);
  if (unmapped != null) e.onUnmapped = (k, v) => unmapped.add('$k:$v');
  return e;
}

WordAnalysis _analysis(Outcome<WordAnalysis> o) {
  expect(o, isA<Found<WordAnalysis>>());
  return (o as Found<WordAnalysis>).value;
}

Feature _f(FeatureKind k, FeatureValue v, String o) => Feature(k, v, o);

void main() {
  group('word analysis from fixtures', () {
    late SamsaadhaniiEngine engine;
    late FakeClient client;
    final unmapped = <String>[];

    setUp(() {
      client = FakeClient.fixtures();
      engine = _engine(client, unmapped: unmapped);
    });

    test('rAmaH: a verb (rā) and a noun (rāma), in the server order',
        () async {
      final a = _analysis(await engine.analyseWord(const SanskritText('rAmaH')));
      expect(a.input, const SanskritText('rAmaH'));
      expect(a.analyses.length, 2);
      expect(
        a.analyses[0],
        Analysis(
          lemma: const SanskritText('rA'),
          homonym: 1,
          wordClass: WordClass.verb,
          features: [
            _f(FeatureKind.prayoga, FeatureValue.kartari, 'kartari'),
            _f(FeatureKind.lakara, FeatureValue.lat, 'laṭ'),
            _f(FeatureKind.person, FeatureValue.first, 'u'),
            _f(FeatureKind.number, FeatureValue.plural, 'bahu'),
            _f(FeatureKind.pada, FeatureValue.parasmaipada, 'parasmaipadī'),
            _f(FeatureKind.gana, FeatureValue.adadi, 'adādiḥ'),
          ],
        ),
      );
      expect(
        a.analyses[1],
        Analysis(
          lemma: const SanskritText('rAma'),
          wordClass: WordClass.noun,
          features: [
            _f(FeatureKind.gender, FeatureValue.masculine, 'puṃ'),
            _f(FeatureKind.vibhakti, FeatureValue.nominative, '1'),
            _f(FeatureKind.number, FeatureValue.singular, 'eka'),
          ],
        ),
      );
    });

    test('rAmeNa: the same stem as masculine and as neuter', () async {
      final a =
          _analysis(await engine.analyseWord(const SanskritText('rAmeNa')));
      expect(a.analyses.map((x) => x.features.first.value),
          [FeatureValue.masculine, FeatureValue.neuter]);
      expect(a.analyses.every((x) => x.lemma.wx == 'rAma'), isTrue);
      expect(a.analyses[0].features[1].value, FeatureValue.instrumental);
    });

    test('vanam: nominative and accusative, neuter', () async {
      final a = _analysis(await engine.analyseWord(const SanskritText('vanam')));
      expect(a.analyses.map((x) => x.features[1].value),
          [FeatureValue.nominative, FeatureValue.accusative]);
    });

    test('gacCawi: a verb and participle analyses', () async {
      final a =
          _analysis(await engine.analyseWord(const SanskritText('gacCawi')));
      expect(a.analyses.first.wordClass, WordClass.verb);
      expect(a.analyses.first.lemma, const SanskritText('gam'));
      expect(a.analyses.first.homonym, 1);
      expect(a.analyses.any((x) => x.wordClass == WordClass.participle), isTrue);
    });

    test('gacCan: participle, stem gacCaw, pratyaya śatṛ, lakāra laṭ, base gamLz',
        () async {
      final a = _analysis(await engine.analyseWord(const SanskritText('gacCan')));
      expect(a.analyses.length, 2);
      final first = a.analyses.first;
      expect(first.wordClass, WordClass.participle);
      expect(first.lemma, const SanskritText('gacCaw'));
      expect(first.base, const SanskritText('gamLz')); // dhātuḥ:gamḷṁ
      expect(first.homonym, 1);
      expect(first.derivation, 'śatṛ_laṭ');
      expect(first.features, [
        Feature(FeatureKind.krtPratyaya, FeatureValue.openClass, 'śatṛ',
            text: const SanskritText('Sawq')),
        _f(FeatureKind.lakara, FeatureValue.lat, 'laṭ'),
        // prayogaḥ:dh is not documented: it stays unknown, shown as given.
        _f(FeatureKind.prayoga, FeatureValue.unknown, 'dh'),
        _f(FeatureKind.gana, FeatureValue.bhvadi, 'bhvādiḥ'),
        _f(FeatureKind.gender, FeatureValue.masculine, 'puṃ'),
        _f(FeatureKind.vibhakti, FeatureValue.nominative, '1'),
        _f(FeatureKind.number, FeatureValue.singular, 'eka'),
      ]);
      // dhātuḥ is the root, not a feature.
      expect(first.features.any((f) => f.original.contains('gamḷṁ')), isFalse);
      // vibhaktiḥ 8 is the vocative.
      expect(a.analyses[1].features.any((f) => f.value == FeatureValue.vocative),
          isTrue);
    });

    test('ca: indeclinable', () async {
      final a = _analysis(await engine.analyseWord(const SanskritText('ca')));
      expect(a.analyses.single.wordClass, WordClass.indeclinable);
      expect(a.analyses.single.lemma, const SanskritText('ca'));
      // vargaḥ:avy only says "indeclinable", which APP already gives.
      expect(a.analyses.single.features, isEmpty);
      expect(_fixture('morph_ca.txt'), contains('vargaḥ:avy'));
    });

    test('xyzq and the empty word are NotFound', () async {
      expect(await engine.analyseWord(const SanskritText('xyzq')),
          isA<NotFound<WordAnalysis>>());
      expect(await engine.analyseWord(const SanskritText('')),
          isA<NotFound<WordAnalysis>>());
    });

    test('Found carries the source', () async {
      final o = await engine.analyseWord(const SanskritText('vanam'))
          as Found<WordAnalysis>;
      expect(
          o.source,
          ResultSource(
              engine: EngineId.samsaadhanii, program: 'morph.cgi', time: _now));
    });

    test('the request is WX in, IAST out, JSON', () async {
      await engine.analyseWord(const SanskritText('vanam'));
      expect(client.queries.single, {
        'morfword': 'vanam',
        'encoding': 'WX',
        'outencoding': 'IAST',
        'mode': 'json',
      });
    });

    test('keys and values that mapped to unknown (for the report)', () {
      expect(unmapped.toSet().toList()..sort(), ['prayogaḥ:dh']);
    });
  });

  group('pronouns, passive, causative', () {
    final unmapped = <String>[];
    late SamsaadhaniiEngine engine;

    setUp(() {
      unmapped.clear();
      engine = _engine(FakeClient.fixtures(), unmapped: unmapped);
    });

    test('aham: asmad has gender a = noGender, original kept', () async {
      final a = _analysis(await engine.analyseWord(const SanskritText('aham')));
      final x = a.analyses.single;
      expect(x.wordClass, WordClass.noun);
      expect(x.lemma, const SanskritText('asmax')); // asmad in WX
      expect(x.features, [
        _f(FeatureKind.nominalCategory, FeatureValue.sarvanama, 'sarva'),
        _f(FeatureKind.gender, FeatureValue.noGender, 'a'),
        _f(FeatureKind.vibhakti, FeatureValue.nominative, '1'),
        _f(FeatureKind.number, FeatureValue.singular, 'eka'),
      ]);
      // vargaḥ:sarva is the pronoun mark; the word class stays noun.
      expect(unmapped, isEmpty);
    });

    test('gamyawe: one reading, passive', () async {
      final a = _analysis(await engine.analyseWord(const SanskritText('gamyawe')));
      expect(a.analyses.length, 1);
      final f = a.analyses.single.features;
      expect(f.first, _f(FeatureKind.prayoga, FeatureValue.karmani, 'karmaṇi'));
      expect(f.any((x) => x.value == FeatureValue.atmanepada), isTrue);
      expect(f.any((x) => x.kind == FeatureKind.sanadi), isFalse);
    });

    test('gamayawi: sanādi_pratyayaḥ ṇic is the causative, root in base',
        () async {
      final a = _analysis(await engine.analyseWord(const SanskritText('gamayawi')));
      final x = a.analyses.single;
      expect(x.features.first,
          _f(FeatureKind.sanadi, FeatureValue.nic, 'ṇic'));
      expect(x.features[1].value, FeatureValue.kartari);
      expect(x.base, const SanskritText('gamLz'));
      expect(unmapped, isEmpty);
    });

    test('a prayoga value starting with Nic is the causative plus the prayoga',
        () async {
      final e = _engine(FakeClient((_, __) => const ClientResponse(200,
          '[{"APP":"verb","RT":"gam","rt":"gam1","ANS":"{prayogaḥ:Nickarwari}{prayogaḥ:Nickartari}{prayogaḥ:Nicxx}"}]')));
      final f = _analysis(await e.analyseWord(const SanskritText('x')))
          .analyses
          .single
          .features;
      expect(f, [
        _f(FeatureKind.sanadi, FeatureValue.nic, 'Nic'),
        _f(FeatureKind.prayoga, FeatureValue.kartari, 'karwari'),
        _f(FeatureKind.sanadi, FeatureValue.nic, 'Nic'),
        _f(FeatureKind.prayoga, FeatureValue.kartari, 'kartari'),
        _f(FeatureKind.sanadi, FeatureValue.nic, 'Nic'),
        _f(FeatureKind.prayoga, FeatureValue.unknown, 'xx'),
      ]);
    });
  });

  group('word analysis, other answers', () {
    Future<Outcome<WordAnalysis>> run(String body) => _engine(
            FakeClient((_, __) => ClientResponse(200, body)))
        .analyseWord(const SanskritText('x'));

    test('malformed JSON is a ServerFault', () async {
      expect(await run('[{"ANS": '), isA<ServerFault<WordAnalysis>>());
      expect(await run('<html>oops</html>'), isA<ServerFault<WordAnalysis>>());
      expect(await run(''), isA<ServerFault<WordAnalysis>>());
    });

    test('a single object where a list is expected is accepted', () async {
      final o = await run(
          '{"APP":"noun","rt":"rAma","RT":"rāma","ANS":"{liṅgam:puṃ}{vibhaktiḥ:1}{vacanam:eka}"}');
      expect(_analysis(o).analyses.length, 1);
    });

    test('an entry without ANS is a ServerFault', () async {
      expect(await run('[{"APP":"noun"}]'), isA<ServerFault<WordAnalysis>>());
      expect(await run('[]'), isA<ServerFault<WordAnalysis>>());
    });

    test('unknown keys and values are kept, not dropped', () async {
      final seen = <String>[];
      final e = _engine(
          FakeClient((_, __) => const ClientResponse(
              200,
              '[{"APP":"widget","RT":"foo2","rt":"foo","ANS":"{liṅgam:zzz}{newkey:v1}{vibhaktiḥ:9}"}]')),
          unmapped: seen);
      final a = _analysis(await e.analyseWord(const SanskritText('foo')));
      final x = a.analyses.single;
      expect(x.wordClass, WordClass.other);
      expect(x.homonym, 2);
      expect(x.lemma, const SanskritText('foo'));
      expect(x.features, [
        _f(FeatureKind.gender, FeatureValue.unknown, 'zzz'),
        _f(FeatureKind.unknown, FeatureValue.unknown, 'newkey:v1'),
        _f(FeatureKind.vibhakti, FeatureValue.unknown, '9'),
      ]);
      expect(seen, ['liṅgam:zzz', 'newkey:v1', 'vibhaktiḥ:9', 'APP:widget']);
    });
  });

  group('splitting from fixtures', () {
    late SamsaadhaniiEngine engine;
    late FakeClient client;

    setUp(() {
      client = FakeClient.fixtures();
      engine = _engine(client);
    });

    Segmentation seg(Outcome<Segmentation> o) {
      expect(o, isA<Found<Segmentation>>());
      return (o as Found<Segmentation>).value;
    }

    test('a sentence: spaces are word boundaries', () async {
      final s = seg(await engine.segment(const SanskritText('rAmovanafgacCawi')));
      expect(s.input, const SanskritText('rAmovanafgacCawi'));
      expect(s.candidates.single.segments, const [
        Segment(SanskritText('rAmaH'), Boundary.word),
        Segment(SanskritText('vanam'), Boundary.word),
        Segment(SanskritText('gacCawi'), Boundary.end),
      ]);
      expect(client.queries.single, {
        'word': 'rAmovanafgacCawi',
        'encoding': 'WX',
        'outencoding': 'I',
        'mode': 'sent',
        'disp_mode': 'json',
      });
    });

    test('a compound: hyphens are compound boundaries', () async {
      // The fixture was captured in word mode; the fake serves it for the
      // matching request, which the engine does not make, so feed it directly.
      final e = _engine(FakeClient(
          (_, __) => ClientResponse(200, _fixture('split_word_rAmAlayaH.txt'))));
      final s = seg(await e.segment(const SanskritText('rAmAlayaH')));
      expect(s.candidates.single.segments, const [
        Segment(SanskritText('rAma'), Boundary.compound),
        Segment(SanskritText('AlayaH'), Boundary.end),
      ]);
    });

    test('xyzq: a segmentation starting with ? is NotFound', () async {
      expect(await engine.segment(const SanskritText('xyzq')),
          isA<NotFound<Segmentation>>());
    });

    test('empty input: "No Output Found" is NotFound', () async {
      expect(await engine.segment(const SanskritText('')),
          isA<NotFound<Segmentation>>());
    });

    test('an empty map is a ServerFault; malformed JSON too', () async {
      Future<Outcome<Segmentation>> run(String body) =>
          _engine(FakeClient((_, __) => ClientResponse(200, body)))
              .segment(const SanskritText('x'));
      expect(await run('{}'), isA<ServerFault<Segmentation>>());
      expect(await run('{"input":" x"'), isA<ServerFault<Segmentation>>());
      expect(await run('{"input":" x","segmentation":[]}'),
          isA<ServerFault<Segmentation>>());
    });

    test('several candidates are kept in order, "?" ones dropped', () async {
      final e = _engine(FakeClient((_, __) => const ClientResponse(200,
          '{"input":" x","segmentation":["a-b c","?zz","d e"]}')));
      final s = seg(await e.segment(const SanskritText('x')));
      expect(s.candidates.length, 2);
      expect(s.candidates[0].segments.map((x) => x.after),
          [Boundary.compound, Boundary.word, Boundary.end]);
      expect(s.candidates[1].segments.map((x) => x.after),
          [Boundary.word, Boundary.end]);
    });

    test('analyseWords gives one outcome per segment, NotFound included',
        () async {
      final split = const Split([
        Segment(SanskritText('vanam'), Boundary.word),
        Segment(SanskritText('xyzq'), Boundary.end),
      ]);
      final out = await engine.analyseWords(split);
      expect(out[0], isA<Found<WordAnalysis>>());
      expect(out[1], isA<NotFound<WordAnalysis>>());
    });

    // Splitter answers in word mode for the compound; morph from fixtures.
    FakeClient compoundClient() => FakeClient((program, query) {
          if (program == splitterProgram) {
            return ClientResponse(200, _fixture('split_word_rAmAlayaH.txt'));
          }
          return FakeClient.fixtures().respond(program, query);
        });

    test('segment(analyse: true): a compound gives a member slot and an '
        'analysed last word', () async {
      final client = compoundClient();
      final s = seg(await _engine(client)
          .segment(const SanskritText('rAmAlayaH'), analyse: true));
      final split = s.candidates.single;
      final slots = split.analyses!;
      expect(slots.length, split.segments.length);
      // rAma- : a member, one analysis, no features, not sent to morph.cgi
      final member = _analysis(slots[0]);
      expect(member.input, const SanskritText('rAma'));
      expect(member.analyses, const [
        Analysis(
            lemma: SanskritText('rAma'), wordClass: WordClass.compoundMember),
      ]);
      // AlayaH: analysed normally
      final last = _analysis(slots[1]);
      expect(last.analyses.first.lemma, const SanskritText('Ali'));
      expect(last.analyses.first.wordClass, WordClass.noun);
      expect(client.queries.where((q) => q.containsKey('morfword')).single['morfword'],
          'AlayaH');
    });

    test('segment(analyse: true): one unknown word is NotFound in its slot only',
        () async {
      final e = _engine(FakeClient((program, query) {
        if (program == splitterProgram) {
          return const ClientResponse(
              200, '{"input":" vanam xyzq","segmentation":["vanam xyzq"]}');
        }
        return FakeClient.fixtures().respond(program, query);
      }));
      final s = seg(await e.segment(const SanskritText('vanam xyzq'), analyse: true));
      final slots = s.candidates.single.analyses!;
      expect(slots[0], isA<Found<WordAnalysis>>());
      expect(slots[1], isA<NotFound<WordAnalysis>>());
    });

    test('segment(analyse: true): a word that cannot be reached does not fail '
        'the split', () async {
      final e = _engine(FakeClient((program, query) {
        if (program == splitterProgram) {
          return const ClientResponse(
              200, '{"input":" vanam","segmentation":["vanam"]}');
        }
        throw const UnreachableException('timeout');
      }));
      final s = seg(await e.segment(const SanskritText('vanam'), analyse: true));
      expect(s.candidates.single.analyses!.single,
          const Unreachable<WordAnalysis>('timeout'));
    });

    test('without analyse the analyses stay null and morph is not called',
        () async {
      final client = compoundClient();
      final s = seg(await _engine(client).segment(const SanskritText('rAmAlayaH')));
      expect(s.candidates.single.analyses, isNull);
      expect(client.queries.length, 1);
    });
  });

  group('failures', () {
    test('a timeout from the client is Unreachable', () async {
      final e = _engine(FakeClient(
          (_, __) => throw const UnreachableException('timeout after 20 s')));
      expect(await e.analyseWord(const SanskritText('rAmaH')),
          const Unreachable<WordAnalysis>('timeout after 20 s'));
      expect(await e.segment(const SanskritText('rAmaH')),
          const Unreachable<Segmentation>('timeout after 20 s'));
    });

    test('a non-200 status is a ServerFault', () async {
      final e = _engine(FakeClient((_, __) => const ClientResponse(500, 'x')));
      expect(await e.analyseWord(const SanskritText('rAmaH')),
          isA<ServerFault<WordAnalysis>>());
      expect(await e.segment(const SanskritText('rAmaH')),
          isA<ServerFault<Segmentation>>());
    });

    test('an unexpected client error is a ServerFault', () async {
      final e = _engine(FakeClient((_, __) => throw StateError('boom')));
      expect(await e.analyseWord(const SanskritText('rAmaH')),
          isA<ServerFault<WordAnalysis>>());
    });
  });

  group('engine identity', () {
    test('tasks, id and credit', () {
      final e = SamsaadhaniiEngine(client: FakeClient.fixtures());
      expect(e.id, EngineId.samsaadhanii);
      expect(e.tasks, {
        Task.analyseWord,
        Task.splitText,
        Task.nounForms,
        Task.derivation,
        Task.verbForms,
        Task.krtForms,
        Task.joinWords,
        Task.dictionary,
      });
      expect(e.credit.name, 'Samsaadhanii');
    });
  });

  group('input cleaning', () {
    String clean(String wx) => cleanForServer(SanskritText(wx));

    test('removes danda, double danda and verse numbers', () {
      expect(clean('rAmaH vanam gacCawi ।'), 'rAmaH vanam gacCawi');
      expect(clean('rAmaH ॥ 12 ॥'), 'rAmaH');
      expect(clean('rAmaH 1.2.3 vanam'), 'rAmaH vanam');
      expect(clean('  rAmaH   vanam  '), 'rAmaH vanam');
    });

    test('digits inside words and plain text are left alone', () {
      expect(clean('rA1 vanam'), 'rA1 vanam');
      expect(clean('rAmaH'), 'rAmaH');
    });

    test('the engine sends the cleaned text', () async {
      final client = FakeClient.fixtures();
      await _engine(client).analyseWord(const SanskritText('vanam ।'));
      expect(client.queries.single['morfword'], 'vanam');
    });
  });

  group('the prefix of an analysis (upasarga)', () {
    Future<List<Analysis>> analyses(String fixture) async {
      final o = await _engine(
              FakeClient((_, __) => ClientResponse(200, _fixture(fixture))))
          .analyseWord(const SanskritText('x'));
      return (o as Found<WordAnalysis>).value.analyses;
    }

    test('a prefixed verb and its participles carry the key', () async {
      final list = await analyses('morph_AgacCawi.txt');
      expect(list.length, 4);
      for (final a in list) {
        expect(a.prefix, const SanskritText('Af'), reason: a.toString());
      }
      // The lemma keeps the prefix, as the server writes it.
      final verb = list.firstWhere((a) => a.wordClass == WordClass.verb);
      expect(verb.lemma.display(Script.iast), 'āṅ_gam');
      // A participle's root is its base, without the prefix.
      final part = list.firstWhere((a) => a.wordClass == WordClass.participle);
      expect(part.base!.wx, 'gamLz');
    });

    test('"-" is no prefix', () async {
      for (final a in await analyses('morph_gacCawi.txt')) {
        expect(a.prefix, isNull, reason: a.toString());
      }
    });

    test('nouns, which the server sends with "-", have none', () async {
      for (final a in await analyses('morph_rAmaH.txt')) {
        expect(a.prefix, isNull);
      }
    });

    test('an entry with no upasarga at all has none', () async {
      final o = await _engine(FakeClient((_, __) => ClientResponse(
              200,
              '[{"APP":"noun","RT":"rāma","ANS":"{liṅgam:puṃ}{vibhaktiḥ:1}'
              '{vacanam:eka}"}]')))
          .analyseWord(const SanskritText('rAmaH'));
      expect((o as Found<WordAnalysis>).value.analyses.single.prefix, isNull);
    });

    test('equality looks at the prefix', () {
      const a = Analysis(
          lemma: SanskritText('gam'), wordClass: WordClass.verb);
      const b = Analysis(
          lemma: SanskritText('gam'),
          wordClass: WordClass.verb,
          prefix: SanskritText('Af'));
      expect(a, isNot(b));
      expect(b, b);
      expect(b.toString(), contains('prefix: Af'));
    });
  });
}
