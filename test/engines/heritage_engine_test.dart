import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/engines/heritage/client.dart';
import 'package:mobile_app/engines/heritage/heritage_engine.dart';
import 'package:mobile_app/engines/common/input.dart';

const _dir = 'test/fixtures/heritage';

String _fixture(String name) => File('$_dir/$name.json').readAsStringSync();

/// Answers with the saved file chosen by the request, or what a test says.
class FakeClient implements HeritageClient {
  FakeClient(this.respond);

  final ClientResponse Function(Map<String, String> query) respond;
  final List<Map<String, String>> queries = [];

  /// Serves the captured fixtures, picking the file from the request.
  factory FakeClient.fixtures() => FakeClient((q) {
        final text = q['text']!.replaceAll(' ', '_');
        final name = q['st'] == 'f'
            ? 'analysis_${text.isEmpty ? 'empty' : text}'
            : q['stemmer'] == 't'
                ? 'split_analyse_$text'
                : 'split_$text';
        return ClientResponse(200, _fixture(name));
      });

  @override
  Future<ClientResponse> get(Map<String, String> query) async {
    queries.add(query);
    return respond(query);
  }
}

final _now = DateTime.utc(2026, 10, 4, 9);

HeritageEngine _engine(FakeClient client, {List<String>? unmapped}) {
  final e = HeritageEngine(client: client, now: () => _now);
  if (unmapped != null) e.onUnmapped = unmapped.add;
  return e;
}

WordAnalysis _analysis(Outcome<WordAnalysis> o) {
  expect(o, isA<Found<WordAnalysis>>());
  return (o as Found<WordAnalysis>).value;
}

Segmentation _seg(Outcome<Segmentation> o) {
  expect(o, isA<Found<Segmentation>>());
  return (o as Found<Segmentation>).value;
}

Feature _f(FeatureKind k, FeatureValue v, String o) => Feature(k, v, o);

void main() {
  group('word analysis from fixtures', () {
    late HeritageEngine engine;
    late FakeClient client;
    final unmapped = <String>[];

    setUp(() {
      client = FakeClient.fixtures();
      engine = _engine(client, unmapped: unmapped);
    });

    test('rAmaH: rA#1 as a verb (homonym 1) and rAma as a noun', () async {
      final a = _analysis(await engine.analyseWord(const SanskritText('rAmaH')));
      expect(a.analyses, [
        Analysis(
          lemma: const SanskritText('rA'),
          homonym: 1,
          wordClass: WordClass.verb,
          features: [
            _f(FeatureKind.lakara, FeatureValue.lat, 'pr.'),
            _f(FeatureKind.gana, FeatureValue.adadi, '[2]'),
            _f(FeatureKind.pada, FeatureValue.parasmaipada, 'ac.'),
            _f(FeatureKind.number, FeatureValue.plural, 'pl.'),
            _f(FeatureKind.person, FeatureValue.first, '1'),
          ],
        ),
        Analysis(
          lemma: const SanskritText('rAma'),
          wordClass: WordClass.noun,
          features: [
            _f(FeatureKind.gender, FeatureValue.masculine, 'm.'),
            _f(FeatureKind.number, FeatureValue.singular, 'sg.'),
            _f(FeatureKind.vibhakti, FeatureValue.nominative, 'nom.'),
          ],
        ),
      ]);
    });

    test('vanam: one Analysis per inflectional_morphs entry (acc, then nom)',
        () async {
      final a = _analysis(await engine.analyseWord(const SanskritText('vanam')));
      expect(a.analyses.length, 2);
      expect(a.analyses.map((x) => x.lemma.wx), ['vana', 'vana']);
      expect(a.analyses.map((x) => x.features.last.value),
          [FeatureValue.accusative, FeatureValue.nominative]);
    });

    test('gacCawi: a verb, and a participle with a base and a derivation',
        () async {
      final a =
          _analysis(await engine.analyseWord(const SanskritText('gacCawi')));
      expect(a.analyses.length, 3);
      final verb = a.analyses.first;
      expect(verb.lemma, const SanskritText('gam'));
      expect(verb.wordClass, WordClass.verb);
      expect(verb.features[1], _f(FeatureKind.gana, FeatureValue.bhvadi, '[1]'));
      expect(verb.features.last, _f(FeatureKind.person, FeatureValue.third, '3'));
      final ppr = a.analyses[1];
      expect(ppr.wordClass, WordClass.participle);
      expect(ppr.lemma, const SanskritText('gacCaw'));
      expect(ppr.base, const SanskritText('gam'));
      expect(ppr.derivation, 'ppr. [1] ac.');
      expect(ppr.features.map((f) => f.value),
          [FeatureValue.neuter, FeatureValue.singular, FeatureValue.locative]);
      expect(a.analyses[2].features.first.value, FeatureValue.masculine);
    });

    test('kqwam: base kq#1 keeps its stem, derivation pp.', () async {
      final a = _analysis(await engine.analyseWord(const SanskritText('kqwam')));
      expect(a.analyses.first.base, const SanskritText('kq'));
      expect(a.analyses.first.derivation, 'pp.');
      expect(a.analyses.first.wordClass, WordClass.participle);
    });

    test('agacCaw: iic. is a compound member', () async {
      final a =
          _analysis(await engine.analyseWord(const SanskritText('agacCaw')));
      expect(a.analyses.first.wordClass, WordClass.verb);
      expect(a.analyses.first.features.first,
          _f(FeatureKind.lakara, FeatureValue.lan, 'impft.'));
      final iic = a.analyses[1];
      expect(iic.wordClass, WordClass.compoundMember);
      expect(iic.lemma, const SanskritText('aga'));
      expect(iic.features, isEmpty);
      // Cax#2: homonym 2
      expect(a.analyses[2].homonym, 2);
    });

    test('xyzq: "?" is NotFound', () async {
      expect(await engine.analyseWord(const SanskritText('xyzq')),
          isA<NotFound<WordAnalysis>>());
    });

    test('empty input: the server\'s error is BadInput with its message',
        () async {
      expect(await engine.analyseWord(const SanskritText('')),
          const BadInput<WordAnalysis>('Wrong input  - Empty sanskrit input'));
    });

    test('Found carries the source', () async {
      final o = await engine.analyseWord(const SanskritText('vanam'))
          as Found<WordAnalysis>;
      expect(
          o.source,
          ResultSource(
              engine: EngineId.heritage, program: 'sktgraph2.cgi', time: _now));
    });

    test('the request: WX, MW, all analyses of a word', () async {
      await engine.analyseWord(const SanskritText('vanam'));
      expect(client.queries.single, {
        'text': 'vanam',
        't': 'WX',
        'lex': 'MW',
        'st': 'f',
        'stemmer': 't',
        'mode': 'b',
        'fmode': 'w',
      });
    });

    test('labels that were not mapped (for the report)', () {
      // Every label in the captured answers is mapped.
      expect(unmapped, isEmpty);
    });
  });

  group('pronouns, passive, causative', () {
    late HeritageEngine engine;

    setUp(() => engine = _engine(FakeClient.fixtures()));

    test('aham and wvam: * is noGender, asmax and yuRmax are nouns', () async {
      for (final (word, stem) in [('aham', 'asmax'), ('wvam', 'yuRmax')]) {
        final a = _analysis(await engine.analyseWord(SanskritText(word)));
        final x = a.analyses.single;
        expect(x.wordClass, WordClass.noun);
        expect(x.lemma, SanskritText(stem));
        expect(x.features.first,
            _f(FeatureKind.gender, FeatureValue.noGender, '*'));
      }
    });

    test('gamyawe: passive, causative passive, and noun readings', () async {
      final a = _analysis(await engine.analyseWord(const SanskritText('gamyawe')));
      expect(a.analyses.length, 6);
      expect(a.analyses[0].features.first.value, FeatureValue.lat);
      expect(a.analyses[0].features.any((f) => f.value == FeatureValue.karmani),
          isTrue);
      expect(a.analyses[0].features.any((f) => f.kind == FeatureKind.sanadi),
          isFalse);
      expect(a.analyses[1].features.first,
          _f(FeatureKind.sanadi, FeatureValue.nic, 'ca.'));
      expect(a.analyses[1].wordClass, WordClass.verb);
      expect(a.analyses.skip(2).map((x) => x.lemma.wx), List.filled(4, 'gamyawA'));
    });

    test('gamayawi: the first reading is the causative present', () async {
      final a = _analysis(await engine.analyseWord(const SanskritText('gamayawi')));
      final x = a.analyses.first;
      expect(x.lemma, const SanskritText('gam'));
      expect(x.features.first, _f(FeatureKind.sanadi, FeatureValue.nic, 'ca.'));
      expect(x.features[1].value, FeatureValue.lat);
      // The causative participle keeps "ca. ppr. ac." as its derivation.
      final ppr = a.analyses.firstWhere((y) => y.wordClass == WordClass.participle);
      expect(ppr.derivation, 'ca. ppr. ac.');
      expect(ppr.base, const SanskritText('gam'));
    });

    test('des. and int. are the desiderative and the intensive', () async {
      final e = _engine(FakeClient((_) => const ClientResponse(200,
          '{"input":"x","segmentation":["x"],"morph":[{"word":"x","derived_stem":"gam","base":"","derivational_morph":"","inflectional_morphs":["des. pr. ac. sg. 3","int. pr. ac. sg. 3"]}]}')));
      final a = _analysis(await e.analyseWord(const SanskritText('x')));
      expect(a.analyses.map((x) => x.features.first.value),
          [FeatureValue.san, FeatureValue.yan]);
    });
  });

  group('labels', () {
    final unmapped = <String>[];
    Future<Analysis> one(String label) async {
      final e = _engine(
          FakeClient((_) => ClientResponse(200,
              '{"input":"x","segmentation":["x"],"morph":[{"word":"x","derived_stem":"x","base":"","derivational_morph":"","inflectional_morphs":["$label"]}]}')),
          unmapped: unmapped);
      return _analysis(await e.analyseWord(const SanskritText('x'))).analyses.single;
    }

    test('every case, number and gender label', () async {
      for (final (label, value) in [
        ('nom.', FeatureValue.nominative),
        ('acc.', FeatureValue.accusative),
        ('i.', FeatureValue.instrumental),
        ('dat.', FeatureValue.dative),
        ('abl.', FeatureValue.ablative),
        ('g.', FeatureValue.genitive),
        ('loc.', FeatureValue.locative),
        ('voc.', FeatureValue.vocative),
        ('sg.', FeatureValue.singular),
        ('du.', FeatureValue.dual),
        ('pl.', FeatureValue.plural),
        ('m.', FeatureValue.masculine),
        ('f.', FeatureValue.feminine),
        ('n.', FeatureValue.neuter),
        ('ac.', FeatureValue.parasmaipada),
        ('md.', FeatureValue.atmanepada),
        ('mo.', FeatureValue.atmanepada),
        ('ps.', FeatureValue.karmani),
      ]) {
        final a = await one(label);
        expect(a.features.single.value, value, reason: label);
        expect(a.features.single.original, label);
      }
    });

    test('verb: tense, class in brackets, voice, number, person digit',
        () async {
      final a = await one('opt. [4] md. du. 2');
      expect(a.wordClass, WordClass.verb);
      expect(a.features.map((f) => f.value), [
        FeatureValue.vidhiling,
        FeatureValue.divadi,
        FeatureValue.atmanepada,
        FeatureValue.dual,
        FeatureValue.second,
      ]);
    });

    test('ind. is an indeclinable', () async {
      final a = await one('ind.');
      expect(a.wordClass, WordClass.indeclinable);
      expect(a.features, isEmpty);
    });

    test('an unknown label stays unknown with its text, and is reported',
        () async {
      unmapped.clear();
      final a = await one('m. xx. sg. [14]');
      expect(a.features, [
        _f(FeatureKind.gender, FeatureValue.masculine, 'm.'),
        _f(FeatureKind.unknown, FeatureValue.unknown, 'xx.'),
        _f(FeatureKind.number, FeatureValue.singular, 'sg.'),
        _f(FeatureKind.gana, FeatureValue.unknown, '[14]'),
      ]);
      expect(unmapped, ['xx.', '[14]']);
    });
  });

  group('splitting from fixtures', () {
    late HeritageEngine engine;
    late FakeClient client;

    setUp(() {
      client = FakeClient.fixtures();
      engine = _engine(client);
    });

    test('rAmAlayaH: ten candidates, best first as given', () async {
      final s = _seg(await engine.segment(const SanskritText('rAmAlayaH')));
      expect(s.candidates.length, 10);
      expect(s.candidates.first.segments, const [
        Segment(SanskritText('rAma'), Boundary.compound),
        Segment(SanskritText('AlayaH'), Boundary.end),
      ]);
      expect(s.candidates[2].segments, const [
        Segment(SanskritText('rAma'), Boundary.word),
        Segment(SanskritText('AlayaH'), Boundary.end),
      ]);
      expect(s.candidates.every((c) => c.analyses == null), isTrue);
      expect(client.queries.single, {
        'text': 'rAmAlayaH',
        't': 'WX',
        'lex': 'MW',
        'st': 't',
        'pipeline': 't',
        'mode': 'l',
        'fmode': 'w',
      });
    });

    test('a sentence: spaces are word boundaries', () async {
      final s =
          _seg(await engine.segment(const SanskritText('rAmovanafgacCawi')));
      expect(s.candidates.single.segments, const [
        Segment(SanskritText('rAmaH'), Boundary.word),
        Segment(SanskritText('vanam'), Boundary.word),
        Segment(SanskritText('gacCawi'), Boundary.end),
      ]);
    });

    test('xyzq: a segmentation starting with ? is NotFound', () async {
      expect(await engine.segment(const SanskritText('xyzq')),
          isA<NotFound<Segmentation>>());
    });

    test('analyse: true asks for the best segmentation with analyses, once',
        () async {
      await engine.segment(const SanskritText('rAmovanafgacCawi'), analyse: true);
      expect(client.queries.single, {
        'text': 'rAmovanafgacCawi',
        't': 'WX',
        'lex': 'MW',
        'st': 't',
        'stemmer': 't',
        'mode': 'f',
        'fmode': 'w',
      });
    });

    test('analyse: true on a sentence groups the flat morph list by word',
        () async {
      final s = _seg(await engine.segment(
          const SanskritText('rAmovanafgacCawi'), analyse: true));
      final slots = s.candidates.single.analyses!;
      expect(slots.length, 3);
      final rama = _analysis(slots[0]);
      expect(rama.input, const SanskritText('rAmaH'));
      expect(rama.analyses.map((a) => a.lemma.wx), ['rA', 'rAma']);
      final vanam = _analysis(slots[1]);
      expect(vanam.analyses.length, 2);
      final gacCawi = _analysis(slots[2]);
      expect(gacCawi.analyses.map((a) => a.wordClass),
          [WordClass.verb, WordClass.participle, WordClass.participle]);
    });

    test('analyse: true on a compound: a member slot, then the last word',
        () async {
      final s = _seg(
          await engine.segment(const SanskritText('rAmAlayaH'), analyse: true));
      final slots = s.candidates.single.analyses!;
      expect(slots.length, 2);
      final member = _analysis(slots[0]);
      expect(member.input, const SanskritText('rAma'));
      expect(member.analyses, const [
        Analysis(
            lemma: SanskritText('rAma'), wordClass: WordClass.compoundMember),
      ]);
      final last = _analysis(slots[1]);
      expect(last.analyses.map((a) => a.lemma.wx), ['Alaya', 'Ali', 'Ali']);
      expect(last.analyses.first.features.first.value, FeatureValue.masculine);
    });

    test('analyse: true with the same word twice shares the entries out',
        () async {
      final s = _seg(await engine.segment(
          const SanskritText('rAmaH rAmaH'), analyse: true));
      final slots = s.candidates.single.analyses!;
      expect(slots.length, 2);
      for (final slot in slots) {
        expect(_analysis(slot).analyses.map((a) => a.lemma.wx), ['rA', 'rAma']);
      }
    });

    test('analyse: true on an unknown word is NotFound', () async {
      expect(await engine.segment(const SanskritText('xyzq'), analyse: true),
          isA<NotFound<Segmentation>>());
    });

    test('a segment with no morph entries is NotFound in its slot only',
        () async {
      final e = _engine(FakeClient((_) => const ClientResponse(
          200,
          '{"input":"vanam xyzq","segmentation":["vanam xyzq"],"morph":['
              '{"word":"vanam","derived_stem":"vana","base":"","derivational_morph":"","inflectional_morphs":["n. sg. nom."]},'
              '{"word":"xyzq","derived_stem":"xyzq","base":"","derivational_morph":"","inflectional_morphs":["?"]}]}')));
      final s = _seg(await e.segment(const SanskritText('vanam xyzq'), analyse: true));
      final slots = s.candidates.single.analyses!;
      expect(slots[0], isA<Found<WordAnalysis>>());
      expect(slots[1], isA<NotFound<WordAnalysis>>());
    });
  });

  group('failures', () {
    test('Devanagari sent with t=DN: the error answer is BadInput', () async {
      // The engine never sends DN; this is the answer it would get.
      final e = _engine(
          FakeClient((_) => ClientResponse(200, _fixture('error_devanagari'))));
      expect(await e.analyseWord(const SanskritText('x')),
          const BadInput<WordAnalysis>(
              'Fatal error  - Unknown transliteration scheme'));
      expect(await e.segment(const SanskritText('x')),
          const BadInput<Segmentation>(
              'Fatal error  - Unknown transliteration scheme'));
    });

    test('malformed JSON is a ServerFault', () async {
      Future<Outcome<WordAnalysis>> run(String body) =>
          _engine(FakeClient((_) => ClientResponse(200, body)))
              .analyseWord(const SanskritText('x'));
      expect(await run('{"input": '), isA<ServerFault<WordAnalysis>>());
      expect(await run('<html>'), isA<ServerFault<WordAnalysis>>());
      expect(await run('[]'), isA<ServerFault<WordAnalysis>>());
      expect(await run('{}'), isA<ServerFault<WordAnalysis>>());
      expect(await run('{"segmentation":["x"]}'),
          isA<ServerFault<WordAnalysis>>());
      expect(await run('{"segmentation":["x"],"morph":[{"word":1}]}'),
          isA<ServerFault<WordAnalysis>>());
    });

    test('a timeout from the client is Unreachable', () async {
      final e = _engine(
          FakeClient((_) => throw const UnreachableException('timeout after 20 s')));
      expect(await e.analyseWord(const SanskritText('rAmaH')),
          const Unreachable<WordAnalysis>('timeout after 20 s'));
      expect(await e.segment(const SanskritText('rAmaH')),
          const Unreachable<Segmentation>('timeout after 20 s'));
    });

    test('a non-200 status is a ServerFault', () async {
      final e = _engine(FakeClient((_) => const ClientResponse(502, 'x')));
      expect(await e.analyseWord(const SanskritText('rAmaH')),
          isA<ServerFault<WordAnalysis>>());
      expect(await e.segment(const SanskritText('rAmaH')),
          isA<ServerFault<Segmentation>>());
    });

    test('an unexpected client error is a ServerFault', () async {
      final e = _engine(FakeClient((_) => throw StateError('boom')));
      expect(await e.analyseWord(const SanskritText('rAmaH')),
          isA<ServerFault<WordAnalysis>>());
    });
  });

  group('engine identity and input', () {
    test('tasks, id and credit', () {
      final e = HeritageEngine(client: FakeClient.fixtures());
      expect(e.id, EngineId.heritage);
      expect(e.tasks, {Task.analyseWord, Task.splitText});
      expect(e.credit.name, 'Sanskrit Heritage Platform');
    });

    test('danda, double danda and verse numbers are removed before sending',
        () async {
      expect(cleanForServer(const SanskritText('rAmaH ॥ 12 ॥')), 'rAmaH');
      expect(cleanForServer(const SanskritText('vanam ।')), 'vanam');
      final client = FakeClient.fixtures();
      await _engine(client).analyseWord(const SanskritText('vanam ।'));
      expect(client.queries.single['text'], 'vanam');
    });

    test('Unsupported tasks are not offered, so the fake rule is not needed',
        () {
      expect(HeritageEngine(client: FakeClient.fixtures()).tasks.contains(Task.nounForms),
          isFalse);
    });
  });

  group('no prefix is read from Heritage answers', () {
    test('every analysis in the fixtures has a null prefix', () async {
      // Heritage writes a preverb into `derived_stem` (`A-gam`, `pra-gam`,
      // `anu-gam`, seen live 5 Oct 2026) and spells āṅ `A`, not `Af`. That is
      // not read: the key would be a guess against the prefix list.
      final engine = _engine(FakeClient.fixtures());
      for (final word in ['gacCawi', 'agacCaw', 'gamayawi', 'rAmaH']) {
        final o = await engine.analyseWord(SanskritText(word));
        for (final a in (o as Found<WordAnalysis>).value.analyses) {
          expect(a.prefix, isNull, reason: '$word: $a');
        }
      }
    });

    test('a prefixed word in the answer is kept as the stem it is', () async {
      final engine = _engine(FakeClient((_) => ClientResponse(
          200,
          '{"input":"AgacCawi","segmentation":["AgacCawi"],"morph":['
          '{"word":"AgacCawi","derived_stem":"A-gam","base":"",'
          '"derivational_morph":"","inflectional_morphs":["pr. [1] ac. sg. 3"]}]}')));
      final o = await engine.analyseWord(const SanskritText('AgacCawi'));
      final a = (o as Found<WordAnalysis>).value.analyses.single;
      expect(a.prefix, isNull);
      expect(a.lemma.wx, 'A-gam');
    });
  });
}
