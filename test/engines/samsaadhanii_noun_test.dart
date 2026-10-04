import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/engines/heritage/client.dart' as h;
import 'package:mobile_app/engines/heritage/heritage_engine.dart';
import 'package:mobile_app/engines/samsaadhanii/client.dart';
import 'package:mobile_app/engines/samsaadhanii/samsaadhanii_engine.dart';

const _dir = 'test/fixtures/samsaadhanii';

String _fixture(String name) => File('$_dir/$name').readAsStringSync();

/// Answers noun and derivation requests with the saved file, or with what a
/// test says, and records what was asked.
class _Client implements SamsaadhaniiClient {
  _Client([this.canned]);

  final String? canned;
  final List<(String, Map<String, String>)> asked = [];

  @override
  Future<ClientResponse> get(String program, Map<String, String> query) async {
    asked.add((program, query));
    if (canned != null) return ClientResponse(200, canned!);
    if (program == nounProgram) {
      final stem = query['rt']!;
      return ClientResponse(200, _fixture('noun_${stem.isEmpty ? 'empty' : stem}.json'));
    }
    final stem = query['praatipadika']!;
    return ClientResponse(
        200, _fixture('derivation_${stem.isEmpty ? 'empty' : stem}.html'));
  }
}

final _now = DateTime.utc(2026, 10, 5, 9);

SamsaadhaniiEngine _engine(_Client c) =>
    SamsaadhaniiEngine(client: c, now: () => _now);

NounQuery _q(String stem, FeatureValue gender,
        [FeatureValue category = FeatureValue.plainNoun]) =>
    NounQuery(stem: SanskritText(stem), gender: gender, category: category);

NounParadigm _paradigm(Outcome<NounParadigm> o) {
  expect(o, isA<Found<NounParadigm>>());
  return (o as Found<NounParadigm>).value;
}

List<String> _wx(NounParadigm p, FeatureValue vib, FeatureValue num) =>
    [for (final f in p.forms(vib, num)) f.wx];

const nom = FeatureValue.nominative;
const acc = FeatureValue.accusative;
const voc = FeatureValue.vocative;
const sg = FeatureValue.singular;
const du = FeatureValue.dual;
const pl = FeatureValue.plural;

void main() {
  group('noun forms from fixtures', () {
    test('rAma: 24 cells, one form each, the vocative from saṃ.pra', () async {
      final client = _Client();
      final p = _paradigm(
          await _engine(client).declineNoun(_q('rAma', FeatureValue.masculine)));
      expect(p.cells.length, 24);
      expect(_wx(p, nom, sg), ['rAmaH']);
      expect(_wx(p, nom, du), ['rAmO']); // from the leaked `xvivacanam`
      expect(_wx(p, FeatureValue.instrumental, sg), ['rAmeNa']);
      expect(_wx(p, voc, sg), ['rAma']);
      expect(_wx(p, voc, pl), ['rAmAH']);
      expect(p.query.stem.wx, 'rAma');
    });

    test('the request carries the stem, gender, category and IAST output',
        () async {
      final client = _Client();
      await _engine(client).declineNoun(_q('rAma', FeatureValue.masculine));
      final (program, query) = client.asked.single;
      expect(program, 'skt_gen/noun/noun_gen.cgi');
      expect(query, {
        'rt': 'rAma',
        'gen': 'puM',
        'jAwi': 'nA',
        'level': '1',
        'mode': 'json',
        'encoding': 'WX',
        'outencoding': 'IAST',
      });
    });

    test('the other genders and categories use the server codes', () async {
      for (final (gender, category, gen, jati) in [
        (FeatureValue.feminine, FeatureValue.plainNoun, 'swrI', 'nA'),
        (FeatureValue.neuter, FeatureValue.plainNoun, 'napuM', 'nA'),
        (FeatureValue.noGender, FeatureValue.sarvanama, 'a', 'sarva'),
        (FeatureValue.masculine, FeatureValue.sankhya, 'puM', 'saMKyA'),
        (FeatureValue.masculine, FeatureValue.sankhyeya, 'puM', 'saMKyeyam'),
        (FeatureValue.masculine, FeatureValue.purana, 'puM', 'pUraNam'),
      ]) {
        final client = _Client();
        await _engine(client).declineNoun(_q('rAma', gender, category));
        final q = client.asked.single.$2;
        expect([q['gen'], q['jAwi']], [gen, jati]);
      }
    });

    test('asmad: a cell holds alternatives', () async {
      final p = _paradigm(await _engine(_Client()).declineNoun(
          _q('asmax', FeatureValue.noGender, FeatureValue.sarvanama)));
      expect(_wx(p, nom, sg), ['aham']);
      expect(_wx(p, acc, sg), ['mAm', 'mA']);
      expect(_wx(p, acc, du), ['AvAm', 'nO']);
      expect(_wx(p, acc, pl), ['asmAn', 'naH']);
    });

    test('vana and nadī answer in their own genders', () async {
      final vana = _paradigm(
          await _engine(_Client()).declineNoun(_q('vana', FeatureValue.neuter)));
      expect(_wx(vana, nom, sg), ['vanam']);
      final nadi = _paradigm(
          await _engine(_Client()).declineNoun(_q('naxI', FeatureValue.feminine)));
      expect(_wx(nadi, nom, sg), ['naxI']);
    });

    test('Found carries its source', () async {
      final o = await _engine(_Client())
          .declineNoun(_q('rAma', FeatureValue.masculine));
      final source = (o as Found<NounParadigm>).source;
      expect(source.engine, EngineId.samsaadhanii);
      expect(source.program, 'noun_gen.cgi');
      expect(source.time, _now);
    });

    test('a table of dashes is NotFound, for a nonsense and an empty stem',
        () async {
      for (final stem in ['xyzq', '']) {
        final o = await _engine(_Client())
            .declineNoun(_q(stem, FeatureValue.masculine));
        expect(o, isA<NotFound<NounParadigm>>(), reason: 'stem "$stem"');
      }
    });
  });

  group('noun forms, odd answers', () {
    Future<Outcome<NounParadigm>> run(String body) =>
        _engine(_Client(body)).declineNoun(_q('rAma', FeatureValue.masculine));

    test('a dash is an empty cell, the rest of the table stays', () async {
      final p = _paradigm(await run('['
          '{"form":"rāmaḥ","vib":"prathamā","vac":"ekavacanam"},'
          '{"form":"-","vib":"prathamā","vac":"dvivacanam"},'
          '{"form":"rāmāḥ","vib":"prathamā","vac":"bahuvacanam"}]'));
      expect(_wx(p, nom, sg), ['rAmaH']);
      expect(p.forms(nom, du), isEmpty);
      expect(p.cells.containsKey((nom, du)), isTrue);
      expect(_wx(p, nom, pl), ['rAmAH']);
    });

    test('dvivacanam is accepted as well as the leaked xvivacanam', () async {
      final p = _paradigm(await run(
          '[{"form":"rāmau","vib":"prathamā","vac":"dvivacanam"}]'));
      expect(_wx(p, nom, du), ['rAmO']);
    });

    test('a single object where a list is expected is read as a list of one',
        () async {
      final p = _paradigm(await run(
          '{"form":"rāmaḥ","vib":"prathamā","vac":"ekavacanam"}'));
      expect(_wx(p, nom, sg), ['rAmaH']);
    });

    test('alternatives with dashes keep only the real forms', () async {
      final p = _paradigm(await run(
          '[{"form":"mām/-","vib":"dvitīyā","vac":"ekavacanam"}]'));
      expect(_wx(p, acc, sg), ['mAm']);
    });

    test('an answer that is not JSON is a ServerFault', () async {
      expect(await run('<html>oops</html>'), isA<ServerFault<NounParadigm>>());
      expect(await run(''), isA<ServerFault<NounParadigm>>());
    });

    test('an unknown case or number is a ServerFault, not a wrong table',
        () async {
      expect(
          await run('[{"form":"x","vib":"zzz","vac":"ekavacanam"}]'),
          isA<ServerFault<NounParadigm>>());
      expect(
          await run('[{"form":"x","vib":"prathamā","vac":"zzz"}]'),
          isA<ServerFault<NounParadigm>>());
    });

    test('a gender the server has no code for is BadInput, without a call',
        () async {
      final client = _Client();
      final o = await _engine(client)
          .declineNoun(_q('rAma', FeatureValue.unknown));
      expect(o, isA<BadInput<NounParadigm>>());
      expect(client.asked, isEmpty);
    });
  });

  group('derivation from fixtures', () {
    DerivationQuery q([String stem = 'rAma']) => DerivationQuery(
          stem: SanskritText(stem),
          gender: FeatureValue.masculine,
          vibhakti: FeatureValue.instrumental,
          number: FeatureValue.singular,
        );

    test('rAma, tṛtīyā ekavacana: the steps and the finished form', () async {
      final o = await _engine(_Client()).derive(q());
      expect(o, isA<Found<Derivation>>());
      final d = (o as Found<Derivation>).value;
      expect(d.form, 'रामेण');
      expect(d.steps.length, 15);

      final first = d.steps.first;
      expect(first.sutra, '1-2-45');
      expect(first.sutraText, 'अर्थवत् अधातुः अप्रत्ययः प्रातिपदिकम्');
      expect(first.label, 'प्रातिपदिक');
      expect(first.state, [
        'राम(तृतीया, पुं, एकवचन, प्रातिपदिक, root(राम), अकारान्त)',
      ]);

      final last = d.steps.last;
      expect(last.sutra, '8-4-2');
      expect(last.sutraText, 'अट्कुप्वाङ्नुम्व्यवाये अपि');
      expect(last.label, 'त्रिपादी');
      expect(last.state.single, startsWith('रामेण(पद,अवसान)'));
    });

    test('every step has a number, a text and a label; none is empty',
        () async {
      final d = ((await _engine(_Client()).derive(q())) as Found<Derivation>).value;
      for (final s in d.steps) {
        expect(s.sutra, matches(RegExp(r'^\d+-\d+-\d+$')));
        expect(s.sutraText, isNotEmpty);
        expect(s.label, isNotEmpty, reason: s.sutra);
      }
    });

    test('state lines go with the step before them, markers kept raw', () async {
      final d = ((await _engine(_Client()).derive(q())) as Found<Derivation>).value;
      final ekadesha = d.steps.firstWhere((s) => s.sutra == '6-1-87');
      expect(ekadesha.label, 'एकादेश');
      expect(ekadesha.state.single, contains('root(राम)'));
      // Eleven of the fifteen steps are followed by a line of state.
      expect(d.steps.fold<int>(0, (n, s) => n + s.state.length), 11);
    });

    test('rules considered attach to the next real step, each once', () async {
      final d = ((await _engine(_Client()).derive(q())) as Found<Derivation>).value;
      // They are neither steps nor state.
      expect(d.steps.where((s) => s.sutra == '6-1-101'), isEmpty);
      expect(d.steps.where((s) => s.sutra == '6-1-87').length, 1);
      expect(d.steps.expand((s) => s.state).where((l) => l.contains('::::')),
          isEmpty);

      // Three before the अङ्ग_विधि step; 7-1-12 is the one that applies.
      final angaVidhi = d.steps.firstWhere((s) => s.label == 'अङ्ग_विधि');
      expect(angaVidhi.sutra, '7-1-12');
      expect(angaVidhi.considered.map((c) => c.sutra),
          ['6-1-87', '6-1-101', '7-1-12']);
      expect(angaVidhi.considered.first.sutraText, 'आद् गुणः');

      // 6-1-87 appears twice before the एकादेश step and is kept once.
      final ekadesha = d.steps.firstWhere((s) => s.label == 'एकादेश');
      expect(ekadesha.considered.map((c) => c.sutra), ['6-1-87']);

      // Steps with nothing considered have an empty list.
      expect(d.steps.first.considered, isEmpty);
      expect(d.steps.fold<int>(0, (n, s) => n + s.considered.length), 4);
    });

    test('rules considered after the last step are dropped', () async {
      final o = await _engine(_Client('<body>\n'
              '1-2-45(प्रातिपदिकम्)::::::::प्रातिपदिक<br>\n'
              ' राम(x)<br>\n'
              '::::::::6-1-87(आद् गुणः)::::::::<br>'))
          .derive(q());
      final d = (o as Found<Derivation>).value;
      expect(d.steps.length, 1);
      expect(d.steps.single.considered, isEmpty);
      expect(d.steps.single.state, ['राम(x)']);
    });

    test('the request carries the stem, not the inflected form', () async {
      final client = _Client();
      await _engine(client).derive(q());
      final (program, query) = client.asked.single;
      expect(program, 'ashtadhyayi_simulator/simulation.cgi');
      expect(query, {
        'encoding': 'WX',
        'praatipadika': 'rAma',
        'vibhakti': 'wqwIyA',
        'linga': 'puM',
        'vacana': 'ekavacana',
      });
    });

    test('every case and number has its WX name', () async {
      final names = <String>[];
      for (final v in vibhaktiOrder) {
        final client = _Client();
        await _engine(client).derive(DerivationQuery(
            stem: const SanskritText('rAma'),
            gender: FeatureValue.masculine,
            vibhakti: v,
            number: FeatureValue.dual));
        final query = client.asked.single.$2;
        names.add(query['vibhakti']!);
        expect(query['vacana'], 'xvivacana');
      }
      expect(names, [
        'praWamA', 'xviwIyA', 'wqwIyA', 'cawurWI', 'paFcamI', 'RaRTI',
        'sapwamI', 'samboXana',
      ]);
    });

    test('a page with no step is NotFound', () async {
      final o = await _engine(_Client()).derive(q(''));
      expect(o, isA<NotFound<Derivation>>());
    });

    test('a page cut short still gives the steps it has', () async {
      final o = await _engine(_Client(
              '<body>\n1-2-45(प्रातिपदिकम्)::::::::प्रातिपदिक<br>\n राम(x)<br>'))
          .derive(q());
      final d = (o as Found<Derivation>).value;
      expect(d.steps.length, 1);
      expect(d.form, 'राम');
    });
  });

  group('the engines and their tasks', () {
    test('Samsaadhanii answers noun forms and the derivation', () {
      expect(SamsaadhaniiEngine().tasks,
          containsAll([Task.nounForms, Task.derivation]));
    });

    test('Heritage returns Unsupported at once, without a network call', () async {
      final engine = HeritageEngine(client: _ThrowingHeritageClient());
      expect(HeritageEngine().tasks, isNot(contains(Task.nounForms)));
      expect(await engine.declineNoun(_q('rAma', FeatureValue.masculine)),
          const Unsupported<NounParadigm>(EngineId.heritage, Task.nounForms));
      expect(
          await engine.derive(const DerivationQuery(
              stem: SanskritText('rAma'),
              gender: FeatureValue.masculine,
              vibhakti: FeatureValue.nominative,
              number: FeatureValue.singular)),
          const Unsupported<Derivation>(EngineId.heritage, Task.derivation));
    });
  });

  group('the models', () {
    test('NounParadigm equality looks at the cells', () {
      final query = _q('rAma', FeatureValue.masculine);
      NounParadigm of(String form) => NounParadigm(query, {
            (nom, sg): [SanskritText(form)],
          });
      expect(of('rAmaH'), of('rAmaH'));
      expect(of('rAmaH').hashCode, of('rAmaH').hashCode);
      expect(of('rAmaH'), isNot(of('rAma')));
    });

    test('the table order is the eight vibhaktis, sambodhana last', () {
      expect(vibhaktiOrder.length, 8);
      expect(vibhaktiOrder.last, FeatureValue.vocative);
      expect(numberOrder, [sg, du, pl]);
    });
  });
}

class _ThrowingHeritageClient implements h.HeritageClient {
  @override
  Future<h.ClientResponse> get(Map<String, String> query) =>
      throw StateError('no network call expected');
}
