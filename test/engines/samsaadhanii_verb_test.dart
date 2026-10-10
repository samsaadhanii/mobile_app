import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/engines/heritage/client.dart' as h;
import 'package:mobile_app/engines/heritage/heritage_engine.dart';
import 'package:mobile_app/engines/samsaadhanii/client.dart';
import 'package:mobile_app/engines/samsaadhanii/samsaadhanii_engine.dart';
import 'package:mobile_app/engines/samsaadhanii/verb_adapter.dart';

const _dir = 'test/fixtures/samsaadhanii';
const _gam = 'gam1_gamLz_BvAxiH_gawO';

String _fixture(String name) => File('$_dir/verb_$name.json').readAsStringSync();

/// Serves the saved answer for the request, or what a test says, and records
/// what was asked.
class _Client implements SamsaadhaniiClient {
  _Client({this.canned, this.failOn});

  /// Answers every request with this body.
  final String? canned;

  /// A `prayoga_paxI` code whose call is unreachable.
  final String? failOn;
  final List<Map<String, String>> asked = [];

  @override
  Future<ClientResponse> get(String program, Map<String, String> query) async {
    asked.add(query);
    expect(program, 'skt_gen/verb/verb_gen.cgi');
    if (query['prayoga_paxI'] == failOn) {
      throw const UnreachableException('timeout');
    }
    if (canned != null) return ClientResponse(200, canned!);
    final name = switch ((query['vb'], query['prayoga_paxI'], query['upasarga'])) {
      (_gam, 'karwari-uBayapaxI', '-') => 'gam',
      (_gam, 'karwari-uBayapaxI', 'Af') => 'Af',
      (_gam, 'karwari-uBayapaxI', 'pra') => 'pra',
      (_gam, 'karmaNi', '-') => 'karmaNi',
      (_gam, 'Nickarwari-parasmEpaxI', '-') => 'nic_parasmE',
      (_gam, 'Nickarwari-AwmanepaxI', '-') => 'nic_Awmane',
      ('xyzq', _, _) => 'xyzq',
      _ => throw StateError('no fixture for $query'),
    };
    return ClientResponse(200, _fixture(name));
  }
}

final _now = DateTime.utc(2026, 10, 5, 9);

SamsaadhaniiEngine _engine(_Client c) =>
    SamsaadhaniiEngine(client: c, now: () => _now);

const _kartari = VerbQuery(root: _gam);

VerbParadigm _paradigm(Outcome<VerbParadigm> o) {
  expect(o, isA<Found<VerbParadigm>>(), reason: '$o');
  return (o as Found<VerbParadigm>).value;
}

List<String> _wx(LakaraTable t, FeatureValue person, FeatureValue number) =>
    [for (final f in t.forms(person, number)) f.wx];

const third = FeatureValue.third;
const sg = FeatureValue.singular;
const du = FeatureValue.dual;

void main() {
  group('active, from fixtures', () {
    test('gam: only parasmaipada, ten lakāras in the server order', () async {
      final p = _paradigm(await _engine(_Client()).conjugateVerb(_kartari));
      // The ātmanepada tables are all dashes, so the pada is left out.
      expect(p.padas.map((x) => x.pada), [FeatureValue.parasmaipada]);
      expect(p.pada(FeatureValue.atmanepada), isNull);
      final lakaras = p.padas.single.lakaras;
      expect(lakaras.map((t) => t.lakara), lakaraOrder);
      expect(lakaras.length, 10);
      expect(p.heading.display(Script.iast), 'gam (bhvādiḥ)');
      expect(p.query, _kartari);
    });

    test('a lakāra is three persons by three numbers', () async {
      final p = _paradigm(await _engine(_Client()).conjugateVerb(_kartari));
      final lat = p.padas.single.lakaras.first;
      expect(lat.cells.length, 9);
      expect(_wx(lat, third, sg), ['gacCawi']);
      expect(_wx(lat, third, du), ['gacCawaH']);
      expect(_wx(lat, FeatureValue.first, FeatureValue.plural), ['gacCAmaH']);
      final lit = p.padas.single.lakaras[1];
      expect(_wx(lit, third, sg), ['jagAma']);
    });

    test('a cell with alternatives holds each form', () async {
      final p = _paradigm(await _engine(_Client()).conjugateVerb(_kartari));
      final lot = p.padas.single.lakaras[4];
      expect(lot.lakara, FeatureValue.lot);
      expect(_wx(lot, third, sg), ['gacCawu', 'gacCawAw']);
    });

    test('the misspelt lakāra headings are mapped by position', () async {
      final raw = _fixture('gam');
      // The server really writes these (F14).
      expect(raw, contains('"lakAra_6":"vidhilṅ (Optative)"'));
      expect(raw, contains('"lakAra_7":"āśīrlṅ (Benedictive)"'));
      expect(raw, contains('"lakAra_0":"lat (Present)"'));
      final p = _paradigm(await _engine(_Client()).conjugateVerb(_kartari));
      final lakaras = p.padas.single.lakaras;
      expect(lakaras[0].lakara, FeatureValue.lat);
      expect(lakaras[6].lakara, FeatureValue.vidhiling);
      expect(lakaras[7].lakara, FeatureValue.ashirling);
      expect(_wx(lakaras[6], third, sg), ['gacCew']);
    });

    test('the request: root key, voice code, no prefix as a dash', () async {
      final client = _Client();
      await _engine(client).conjugateVerb(_kartari);
      expect(client.asked.single, {
        'vb': _gam,
        'prayoga_paxI': 'karwari-uBayapaxI',
        'upasarga': '-',
        'encoding': 'WX',
        'outencoding': 'IAST',
        'mode': 'json',
      });
    });

    test('Found carries its source', () async {
      final o = await _engine(_Client()).conjugateVerb(_kartari);
      final source = (o as Found<VerbParadigm>).source;
      expect(source.engine, EngineId.samsaadhanii);
      expect(source.program, 'verb_gen.cgi');
      expect(source.time, _now);
    });
  });

  group('a prefix: the line break in the heading', () {
    const withAf = VerbQuery(root: _gam, prefix: 'Af');

    test('the saved answer has the raw line break and is not valid JSON', () {
      final raw = _fixture('Af');
      expect(RegExp(r'"rt":"[^"]*\n').hasMatch(raw), isTrue);
      expect(() => jsonDecode(raw), throwsFormatException);
    });

    test('the adapter removes it: Af + gam gives the forms and a clean heading',
        () async {
      final client = _Client();
      final p = _paradigm(await _engine(client).conjugateVerb(withAf));
      expect(client.asked.single['upasarga'], 'Af');
      expect(p.heading.display(Script.iast), 'āṅ_gam (bhvādiḥ)');
      expect(p.heading.wx, isNot(contains('\n')));
      expect(p.padas.map((x) => x.pada), [FeatureValue.parasmaipada]);
      expect(_wx(p.padas.single.lakaras.first, third, sg), ['AgacCawi']);
    });

    test('pra + gam is all dashes: NotFound (F13)', () async {
      // The line break is there too, so this also proves the repair is not
      // what makes it NotFound.
      expect(RegExp(r'"rt":"[^"]*\n').hasMatch(_fixture('pra')), isTrue);
      final o = await _engine(_Client())
          .conjugateVerb(const VerbQuery(root: _gam, prefix: 'pra'));
      expect(o, isA<NotFound<VerbParadigm>>());
    });

    test('a carriage return too', () async {
      final body = _fixture('Af').replaceAll('\n', '\r\n');
      final o = await _engine(_Client(canned: body)).conjugateVerb(withAf);
      expect(o, isA<Found<VerbParadigm>>());
    });
  });

  group('passive and causative', () {
    test('karmaṇi: one call, ātmanepada only', () async {
      final client = _Client();
      final p = _paradigm(await _engine(client).conjugateVerb(
          const VerbQuery(root: _gam, prayoga: VerbPrayoga.karmani)));
      expect(client.asked.single['prayoga_paxI'], 'karmaNi');
      expect(p.padas.map((x) => x.pada), [FeatureValue.atmanepada]);
      expect(_wx(p.padas.single.lakaras.first, third, sg), ['gamyawe']);
    });

    test('ṇijanta: two calls, one per pada, merged in pada order', () async {
      final client = _Client();
      final p = _paradigm(await _engine(client).conjugateVerb(
          const VerbQuery(root: _gam, prayoga: VerbPrayoga.nijanta)));
      expect(client.asked.map((q) => q['prayoga_paxI']).toSet(), {
        'Nickarwari-parasmEpaxI',
        'Nickarwari-AwmanepaxI',
      });
      expect(client.asked.length, 2);
      expect(p.padas.map((x) => x.pada),
          [FeatureValue.parasmaipada, FeatureValue.atmanepada]);
      expect(_wx(p.pada(FeatureValue.parasmaipada)!.lakaras.first, third, sg),
          ['gamayawi']);
      expect(_wx(p.pada(FeatureValue.atmanepada)!.lakaras.first, third, sg),
          ['gamayawe']);
      // The perfect has three alternatives in a cell.
      final lit = p.pada(FeatureValue.parasmaipada)!.lakaras[1];
      expect(lit.forms(third, sg).length, 3);
    });

    test('ṇijanta: a failed call fails the answer, never a half table',
        () async {
      final o = await _engine(_Client(failOn: 'Nickarwari-AwmanepaxI'))
          .conjugateVerb(const VerbQuery(
              root: _gam, prayoga: VerbPrayoga.nijanta));
      expect(o, isA<Unreachable<VerbParadigm>>());
    });
  });

  group('mergeVerb', () {
    final src = ResultSource(
        engine: EngineId.samsaadhanii, program: 'verb_gen.cgi', time: _now);
    VerbParadigm one(FeatureValue pada) => VerbParadigm(
        _kartari, const SanskritText('gam(bhvAxiH)'), [
      PadaTables(pada, [
        LakaraTable(FeatureValue.lat, {
          (third, sg): [const SanskritText('x')],
        })
      ])
    ]);

    test('one pada found beside NotFound is that pada', () {
      final found = Found(one(FeatureValue.parasmaipada), src);
      expect(mergeVerb(found, const NotFound()), found);
      expect(mergeVerb(const NotFound(), found), found);
    });

    test('both NotFound is NotFound', () {
      expect(mergeVerb(const NotFound(), const NotFound()),
          isA<NotFound<VerbParadigm>>());
    });

    test('a failure wins over a result', () {
      final found = Found(one(FeatureValue.parasmaipada), src);
      expect(mergeVerb(found, const ServerFault('x')),
          isA<ServerFault<VerbParadigm>>());
      expect(mergeVerb(const Unreachable('t'), found),
          isA<Unreachable<VerbParadigm>>());
    });

    test('the merged padas follow the pada order whichever came first', () {
      final a = Found(one(FeatureValue.atmanepada), src);
      final b = Found(one(FeatureValue.parasmaipada), src);
      final merged = mergeVerb(a, b) as Found<VerbParadigm>;
      expect(merged.value.padas.map((p) => p.pada),
          [FeatureValue.parasmaipada, FeatureValue.atmanepada]);
    });
  });

  group('not found and odd answers', () {
    test('a nonsense root answers all dashes: NotFound', () async {
      final o = await _engine(_Client())
          .conjugateVerb(const VerbQuery(root: 'xyzq'));
      expect(o, isA<NotFound<VerbParadigm>>());
    });

    Future<Outcome<VerbParadigm>> run(String body) =>
        _engine(_Client(canned: body)).conjugateVerb(_kartari);

    test('a heading that does not start like its lakāra is a ServerFault',
        () async {
      // Position 2 is luṭ; the server must not be allowed to reorder.
      final swapped = _fixture('gam').replaceAll('"lakAra_2":"luṭ', '"lakAra_2":"lat');
      expect(await run(swapped), isA<ServerFault<VerbParadigm>>());
    });

    test('the guard ignores the marks the server drops, and nothing else',
        () async {
      // luṭ and luṅ differ in their third letter once marks are folded
      // (`lut`, `lun`) and so do laṭ and laṅ.
      final wrong = _fixture('gam').replaceAll('"lakAra_8":"luṅ', '"lakAra_8":"luṭ');
      expect(await run(wrong), isA<ServerFault<VerbParadigm>>());
    });

    test('a missing lakāra is a ServerFault', () async {
      final cut = _fixture('gam').replaceAll('"lakAra_9"', '"lakAra_x"');
      expect(await run(cut), isA<ServerFault<VerbParadigm>>());
    });

    test('an unknown person or number is a ServerFault', () async {
      final bad = _fixture('gam').replaceAll('prathamapuruṣaḥ', 'zzz');
      expect(await run(bad), isA<ServerFault<VerbParadigm>>());
      final bad2 = _fixture('gam').replaceAll('dvivacanam', 'zzz');
      expect(await run(bad2), isA<ServerFault<VerbParadigm>>());
    });

    test('not JSON, empty, or no heading is a ServerFault', () async {
      expect(await run('<html>oops</html>'), isA<ServerFault<VerbParadigm>>());
      expect(await run(''), isA<ServerFault<VerbParadigm>>());
      expect(await run('[]'), isA<ServerFault<VerbParadigm>>());
      expect(await run('[{"parasmE":[]}]'), isA<ServerFault<VerbParadigm>>());
    });

    test('a single object where a list is expected is read as a list of one',
        () async {
      final list = jsonDecode(_fixture('gam')) as List;
      final o = await run(jsonEncode(list.first));
      expect(o, isA<Found<VerbParadigm>>());
    });

    test('a pada as an object instead of a one-element list is read too',
        () async {
      final entry = (jsonDecode(_fixture('gam')) as List).first as Map;
      entry['parasmE'] = (entry['parasmE'] as List).first;
      expect(await run(jsonEncode([entry])), isA<Found<VerbParadigm>>());
    });
  });

  group('the engines and the models', () {
    test('Samsaadhanii offers verb forms', () {
      expect(SamsaadhaniiEngine().tasks, contains(Task.verbForms));
    });

    test('Heritage returns Unsupported at once, without a network call', () async {
      final engine = HeritageEngine(client: _ThrowingHeritageClient());
      expect(HeritageEngine().tasks, isNot(contains(Task.verbForms)));
      expect(await engine.conjugateVerb(_kartari),
          const Unsupported<VerbParadigm>(EngineId.heritage, Task.verbForms));
    });

    test('LakaraTable and VerbParadigm equality look at the cells', () {
      LakaraTable of(String f) => LakaraTable(FeatureValue.lat, {
            (third, sg): [SanskritText(f)],
          });
      expect(of('a'), of('a'));
      expect(of('a').hashCode, of('a').hashCode);
      expect(of('a'), isNot(of('b')));
      expect(of('a').isEmpty, isFalse);
      expect(const LakaraTable(FeatureValue.lat, {(third, sg): <SanskritText>[]}).isEmpty,
          isTrue);
    });

    test('the table orders', () {
      expect(lakaraOrder.length, 10);
      expect(personOrder, [third, FeatureValue.second, FeatureValue.first]);
      expect(padaOrder, [FeatureValue.parasmaipada, FeatureValue.atmanepada]);
      expect(VerbPrayoga.values.map((v) => v.iast),
          ['kartari', 'karmaṇi', 'ṇijanta']);
    });
  });
}

class _ThrowingHeritageClient implements h.HeritageClient {
  @override
  Future<h.ClientResponse> get(Map<String, String> query) =>
      throw StateError('no network call expected');
}
