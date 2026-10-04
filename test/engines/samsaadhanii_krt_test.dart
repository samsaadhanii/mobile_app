import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/engines/heritage/client.dart' as h;
import 'package:mobile_app/engines/heritage/heritage_engine.dart';
import 'package:mobile_app/engines/samsaadhanii/client.dart';
import 'package:mobile_app/engines/samsaadhanii/samsaadhanii_engine.dart';

const _dir = 'test/fixtures/samsaadhanii';
const _gam = 'gam1_gamLz_BvAxiH_gawO';
const _paT = 'paT1_paTaz_BvAxiH_vyakwAyAM_vAci';
const _kq = 'kq3_dukqF_wanAxiH_karaNe';

String _fixture(String name) => File('$_dir/krt_$name.json').readAsStringSync();

/// Serves the saved answer for the request, or what a test says, and records
/// what was asked.
class _Client implements SamsaadhaniiClient {
  _Client({this.canned});

  final String? canned;
  final List<Map<String, String>> asked = [];

  @override
  Future<ClientResponse> get(String program, Map<String, String> query) async {
    asked.add(query);
    expect(program, 'skt_gen/kqw/kqw_gen.cgi');
    if (canned != null) return ClientResponse(200, canned!);
    final name = switch ((query['vb'], query['upasarga'])) {
      (_gam, '-') => 'gam',
      (_gam, 'pra') => 'gam_pra',
      (_paT, '-') => 'paT',
      (_kq, '-') => 'kq',
      ('xyzq', _) => 'xyzq',
      _ => throw StateError('no fixture for $query'),
    };
    return ClientResponse(200, _fixture(name));
  }
}

final _now = DateTime.utc(2026, 10, 5, 9);

SamsaadhaniiEngine _engine(_Client c) =>
    SamsaadhaniiEngine(client: c, now: () => _now);

Future<Outcome<KrtForms>> _krt(_Client c, [VerbQuery q = const VerbQuery(root: _gam)]) =>
    _engine(c).krtForms(q);

KrtForms _found(Outcome<KrtForms> o) {
  expect(o, isA<Found<KrtForms>>(), reason: '$o');
  return (o as Found<KrtForms>).value;
}

String _iast(SanskritText t) => t.display(Script.iast);

/// The forms of a gender in the group with this (shown) label.
List<String> _of(KrtForms k, String label, FeatureValue gender) => [
      for (final f in k.groups.firstWhere((g) => g.label == label).forms(gender))
        _iast(f),
    ];

const _sentGam = [
  'tṛc', 'tavyat', 'yak', 'śatṛ_laṭ', 'śānac_laṭ_kartari', 'śānac_laṭ_karmaṇi',
  'ghañ', 'ṇvul', 'ṇyat', 'lyuṭ', 'yat', 'kta', 'ktavatu', 'tumun', 'ṇamul',
  'ktvā',
];

const _shownGam = [
  'tṛc', 'tavyat', 'śatṛ_laṭ', 'śānac_laṭ_kartari', 'śānac_laṭ_karmaṇi',
  'ghañ', 'ṇvul', 'ṇyat', 'lyuṭ', 'yat', 'kta', 'ktavatu', 'anīyar', 'tumun',
  'ṇamul', 'ktvā',
];

const m = FeatureValue.masculine;
const f = FeatureValue.feminine;
const n = FeatureValue.neuter;

void main() {
  group('the correction (F12), on all three roots', () {
    test('gam: sixteen groups, the labels shifted into place', () async {
      final k = _found(await _krt(_Client()));
      expect(k.labels, KrtLabels.corrected);
      expect(k.groups.map((g) => g.label), _shownGam);
      // The label the server sent is kept in every group.
      expect(k.groups.map((g) => g.sentLabel), _sentGam);
      expect(k.groups.where((g) => g.wasRelabelled).length, 11);
    });

    test('gam: each form is under its right suffix', () async {
      final k = _found(await _krt(_Client()));
      expect(_of(k, 'śatṛ_laṭ', m), ['gacchat']); // sent as `yak`
      expect(_of(k, 'śatṛ_laṭ', f), ['gacchantī']);
      expect(_of(k, 'śānac_laṭ_karmaṇi', m), ['gamyamāna']);
      expect(_of(k, 'ṇvul', m), ['gāmaka']);
      expect(_of(k, 'lyuṭ', n), ['gamana']);
      expect(_of(k, 'yat', m), ['gamya']);
      expect(_of(k, 'kta', m), ['gata']); // sent as `yat`
      expect(_of(k, 'ktavatu', m), ['gatavat']); // sent as `kta`
      expect(_of(k, 'anīyar', m), ['gamanīya']); // sent as `ktavatu`
      // Correct as sent.
      expect(_of(k, 'tṛc', m), ['gantṛ']);
      expect(_of(k, 'tavyat', m), ['gantavya']);
    });

    test('kṛ: kurvāṇa is a śānac kartari, kurvat a śatṛ', () async {
      final k = _found(await _krt(_Client(), const VerbQuery(root: _kq)));
      expect(k.labels, KrtLabels.corrected);
      expect(_of(k, 'śatṛ_laṭ', m), ['kurvat']);
      expect(_of(k, 'śānac_laṭ_kartari', m), ['kurvāṇa']);
      expect(_of(k, 'śānac_laṭ_karmaṇi', m), ['kriyamāṇa']);
      expect(_of(k, 'kta', m), ['kṛta']);
      expect(_of(k, 'ktavatu', m), ['kṛtavat']);
      expect(_of(k, 'anīyar', m), ['karaṇīya']);
    });

    test('paṭh: paṭhita is a kta, paṭhitavat a ktavatu, paṭhanīya an anīyar',
        () async {
      final k = _found(await _krt(_Client(), const VerbQuery(root: _paT)));
      expect(k.labels, KrtLabels.corrected);
      expect(_of(k, 'kta', m), ['paṭhita']);
      expect(_of(k, 'ktavatu', m), ['paṭhitavat']);
      expect(_of(k, 'anīyar', m), ['paṭhanīya']);
      expect(_of(k, 'ṇvul', m), ['pāṭhaka']); // sent as `ghañ`
      expect(_of(k, 'ṇyat', m), ['pāṭhya']); // sent as `ṇvul`
      expect(_of(k, 'lyuṭ', n), ['paṭhana']); // sent as `ṇyat`
    });

    test('the forms do not move: only the labels change', () async {
      for (final root in [_gam, _kq, _paT]) {
        final k = _found(await _krt(_Client(), VerbQuery(root: root)));
        final sent = [
          for (final e in jsonDecode(_fixture(root == _gam ? 'gam' : root == _kq ? 'kq' : 'paT')) as List)
            (e as Map)['form'],
        ];
        final shown = [
          for (final g in k.groups)
            if (g.isIndeclinable)
              ...g.indeclinable.map((x) => x.wx)
            else
              for (final gender in krtGenders) ...g.forms(gender).map((x) => x.wx),
        ];
        // Same forms in the same order (alternatives are split on `/`).
        expect(shown.length, greaterThan(20));
        expect(
            sent
                .where((s) => s != '-')
                .expand((s) => (s as String).split('/'))
                .length,
            shown.length,
            reason: root);
      }
    });

    test('gam + pra: the groups are shifted too; lyap, tumun and ṇamul stay',
        () async {
      final k = _found(await _krt(_Client(), const VerbQuery(root: _gam, prefix: 'pra')));
      expect(k.labels, KrtLabels.corrected);
      expect(k.groups.length, 16);
      expect(k.groups[12].label, 'anīyar');
      expect(k.groups[12].sentLabel, 'ktavatu');
      expect(k.groups.map((g) => g.label).skip(13), ['tumun', 'ṇamul', 'lyap']);
      final lyap = k.groups.last;
      expect(lyap.isIndeclinable, isTrue);
      expect(lyap.indeclinable.map(_iast), ['pragamya', 'pragatya']);
      // The prefixed root has no gendered form and no tumun or ṇamul.
      expect(k.groups.take(15).every((g) => g.isEmpty), isTrue);
    });
  });

  group('an answer without the fault, and an unexpected one', () {
    test('a server that has been fixed passes through untouched', () async {
      final fixed = _found(await _krt(_Client(canned: _fixture('gam_fixed'))));
      expect(fixed.labels, KrtLabels.asSent);
      expect(fixed.groups.map((g) => g.label), _shownGam);
      expect(fixed.groups.every((g) => !g.wasRelabelled), isTrue);
      // The same groups as the corrected answer, but for the sent labels.
      final corrected = _found(await _krt(_Client()));
      for (var i = 0; i < fixed.groups.length; i++) {
        expect(fixed.groups[i].label, corrected.groups[i].label);
        expect(fixed.groups[i].gendered, corrected.groups[i].gendered);
        expect(fixed.groups[i].indeclinable, corrected.groups[i].indeclinable);
      }
    });

    test('anīyar in the answer switches the correction off', () async {
      // Signature (tṛc, tavyat, yak) but with an anīyar: not the fault.
      final body = jsonEncode([
        {'form': 'a', 'kqw_prawyayaH': 'tṛc', 'lifgam': 'puṃ'},
        {'form': 'b', 'kqw_prawyayaH': 'tavyat', 'lifgam': 'puṃ'},
        {'form': 'c', 'kqw_prawyayaH': 'yak', 'lifgam': 'puṃ'},
        {'form': 'd', 'kqw_prawyayaH': 'anīyar', 'lifgam': 'puṃ'},
      ]);
      final k = _found(await _krt(_Client(canned: body)));
      expect(k.labels, KrtLabels.asSent);
      expect(k.groups.map((g) => g.label), ['tṛc', 'tavyat', 'yak', 'anīyar']);
    });

    test('a different start is not the fault: nothing changes', () async {
      final body = jsonEncode([
        {'form': 'a', 'kqw_prawyayaH': 'kta', 'lifgam': 'puṃ'},
        {'form': 'b', 'kqw_prawyayaH': 'yak', 'lifgam': 'puṃ'},
      ]);
      final k = _found(await _krt(_Client(canned: body)));
      expect(k.labels, KrtLabels.asSent);
      expect(k.groups.map((g) => g.label), ['kta', 'yak']);
    });

    test('the signature in another order is unverified and left as sent',
        () async {
      // Swap two of the later labels: the first three still say `yak`.
      final raw = (jsonDecode(_fixture('gam')) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      for (final e in raw) {
        if (e['kqw_prawyayaH'] == 'ghañ') {
          e['kqw_prawyayaH'] = 'ṇvul';
        } else if (e['kqw_prawyayaH'] == 'ṇvul') {
          e['kqw_prawyayaH'] = 'ghañ';
        }
      }
      final k = _found(await _krt(_Client(canned: jsonEncode(raw))));
      expect(k.labels, KrtLabels.unverified);
      expect(k.groups.every((g) => !g.wasRelabelled), isTrue);
      expect(k.groups.map((g) => g.label).take(3), ['tṛc', 'tavyat', 'yak']);
    });

    test('the signature in a list of another length is unverified', () async {
      final raw = (jsonDecode(_fixture('gam')) as List)
          .where((e) => (e as Map)['kqw_prawyayaH'] != 'ktvā')
          .toList();
      final k = _found(await _krt(_Client(canned: jsonEncode(raw))));
      expect(k.labels, KrtLabels.unverified);
      expect(k.groups.length, 15);
      expect(k.groups.every((g) => !g.wasRelabelled), isTrue);
    });

    test('a new suffix at the end is unverified too, not silently corrected',
        () async {
      final raw = (jsonDecode(_fixture('gam')) as List).toList()
        ..add({'form': 'x', 'kqw_prawyayaH': 'new'});
      final k = _found(await _krt(_Client(canned: jsonEncode(raw))));
      expect(k.labels, KrtLabels.unverified);
    });
  });

  group('groups', () {
    test('indeclinables have no gender and may hold alternatives', () async {
      final k = _found(await _krt(_Client()));
      final tumun = k.groups.firstWhere((g) => g.label == 'tumun');
      expect(tumun.isIndeclinable, isTrue);
      expect(tumun.gendered, isEmpty);
      expect(tumun.indeclinable.map(_iast), ['gantum']);
      final namul = k.groups.firstWhere((g) => g.label == 'ṇamul');
      expect(namul.indeclinable.map(_iast), ['gāmam', 'gāmaṃ']);
      final ktva = k.groups.firstWhere((g) => g.label == 'ktvā');
      expect(ktva.indeclinable.map(_iast), ['gatvā', 'gattvā']);
      expect(ktva.indeclinable.map((x) => x.wx), ['gawvA', 'gawwvA']);
    });

    test('a gendered group has three cells; an empty one stays empty',
        () async {
      final k = _found(await _krt(_Client()));
      // The group sent as `ṇyat`, shown as `lyuṭ`: only a neuter form.
      final lyut = k.groups.firstWhere((g) => g.label == 'lyuṭ');
      expect(lyut.sentLabel, 'ṇyat');
      expect(lyut.isIndeclinable, isFalse);
      expect(lyut.gendered.keys, krtGenders);
      expect(lyut.forms(m), isEmpty);
      expect(lyut.forms(f), isEmpty);
      expect(lyut.forms(n).map(_iast), ['gamana']);
      expect(lyut.isEmpty, isFalse);
      // A whole group of dashes.
      final empty = k.groups.firstWhere((g) => g.label == 'śānac_laṭ_kartari');
      expect(empty.isEmpty, isTrue);
      expect(empty.gendered.length, 3);
    });

    test('the lakāra and prayoga a label carries', () async {
      final k = _found(await _krt(_Client()));
      KrtGroup g(String label) => k.groups.firstWhere((x) => x.label == label);
      expect(_iast(g('śatṛ_laṭ').pratyaya), 'śatṛ');
      expect(g('śatṛ_laṭ').lakara, FeatureValue.lat);
      expect(g('śatṛ_laṭ').prayoga, isNull);
      expect(_iast(g('śānac_laṭ_kartari').pratyaya), 'śānac');
      expect(g('śānac_laṭ_kartari').lakara, FeatureValue.lat);
      expect(g('śānac_laṭ_kartari').prayoga, FeatureValue.kartari);
      expect(g('śānac_laṭ_karmaṇi').prayoga, FeatureValue.karmani);
      expect(_iast(g('kta').pratyaya), 'kta');
      expect(g('kta').lakara, isNull);
      expect(g('kta').prayoga, isNull);
      expect(g('tumun').lakara, isNull);
    });

    test('the pratyaya is held as WX Sanskrit text', () async {
      final k = _found(await _krt(_Client()));
      expect(k.groups.first.pratyaya.wx, 'wqc');
    });
  });

  group('not found, odd answers, and the request', () {
    test('a nonsense root is all dashes: NotFound', () async {
      final o = await _krt(_Client(), const VerbQuery(root: 'xyzq'));
      expect(o, isA<NotFound<KrtForms>>());
    });

    Future<Outcome<KrtForms>> run(String body) => _krt(_Client(canned: body));

    test('not JSON, empty, or an entry without a form is a ServerFault',
        () async {
      expect(await run('<html>oops</html>'), isA<ServerFault<KrtForms>>());
      expect(await run(''), isA<ServerFault<KrtForms>>());
      expect(await run('[{"kqw_prawyayaH":"kta"}]'), isA<ServerFault<KrtForms>>());
      expect(await run('[{"form":"x"}]'), isA<ServerFault<KrtForms>>());
    });

    test('an unknown gender is a ServerFault, not a guessed cell', () async {
      expect(
          await run('[{"form":"x","kqw_prawyayaH":"kta","lifgam":"zzz"}]'),
          isA<ServerFault<KrtForms>>());
    });

    test('a group that mixes gendered and indeclinable entries is a ServerFault',
        () async {
      expect(
          await run('[{"form":"x","kqw_prawyayaH":"kta","lifgam":"puṃ"},'
              '{"form":"y","kqw_prawyayaH":"kta"}]'),
          isA<ServerFault<KrtForms>>());
    });

    test('a single object where a list is expected is read as a list of one',
        () async {
      final k = _found(await run('{"form":"gantum","kqw_prawyayaH":"tumun"}'));
      expect(k.groups.single.indeclinable.map(_iast), ['gantum']);
    });

    test('a raw line break in the answer does not break it', () async {
      final body = _fixture('gam').replaceAll('},{', '},\n{');
      expect(await run(body), isA<Found<KrtForms>>());
    });

    test('the request: root, prefix as a dash, IAST output, no voice',
        () async {
      final client = _Client();
      await _krt(client);
      expect(client.asked.single, {
        'vb': _gam,
        'upasarga': '-',
        'encoding': 'WX',
        'outencoding': 'IAST',
        'mode': 'json',
      });
      final withPra = _Client();
      await _krt(withPra, const VerbQuery(root: _gam, prefix: 'pra'));
      expect(withPra.asked.single['upasarga'], 'pra');
    });

    test('the voice is ignored: it changes neither the request nor the answer',
        () async {
      final a = _Client();
      final b = _Client();
      final active = _found(await _krt(a));
      final passive = _found(await _krt(
          b, const VerbQuery(root: _gam, prayoga: VerbPrayoga.karmani)));
      expect(a.asked.single, b.asked.single);
      expect(passive.groups, active.groups);
    });

    test('Found carries its source and the query', () async {
      final o = await _krt(_Client());
      final source = (o as Found<KrtForms>).source;
      expect(source.engine, EngineId.samsaadhanii);
      expect(source.program, 'kqw_gen.cgi');
      expect(source.time, _now);
      expect(o.value.query, const VerbQuery(root: _gam));
    });
  });

  group('the engines and the models', () {
    test('Samsaadhanii offers kṛt forms; Heritage does not, and never calls',
        () async {
      expect(SamsaadhaniiEngine().tasks, contains(Task.krtForms));
      final heritage = HeritageEngine(client: _ThrowingHeritageClient());
      expect(HeritageEngine().tasks, isNot(contains(Task.krtForms)));
      expect(await heritage.krtForms(const VerbQuery(root: _gam)),
          const Unsupported<KrtForms>(EngineId.heritage, Task.krtForms));
    });

    test('KrtGroup and KrtForms equality look at what they hold', () {
      KrtGroup of(String form, {String label = 'kta'}) => KrtGroup(
            sentLabel: 'yat',
            label: label,
            pratyaya: const SanskritText('kta'),
            gendered: {m: [SanskritText(form)]},
          );
      expect(of('gata'), of('gata'));
      expect(of('gata').hashCode, of('gata').hashCode);
      expect(of('gata'), isNot(of('gatA')));
      expect(of('gata'), isNot(of('gata', label: 'yat')));
      expect(of('gata').wasRelabelled, isTrue);
      const q = VerbQuery(root: _gam);
      expect(KrtForms(q, [of('gata')], KrtLabels.corrected),
          KrtForms(q, [of('gata')], KrtLabels.corrected));
      expect(KrtForms(q, [of('gata')], KrtLabels.corrected),
          isNot(KrtForms(q, [of('gata')], KrtLabels.unverified)));
    });

    test('the genders in table order', () {
      expect(krtGenders, [m, f, n]);
    });
  });
}

class _ThrowingHeritageClient implements h.HeritageClient {
  @override
  Future<h.ClientResponse> get(Map<String, String> query) =>
      throw StateError('no network call expected');
}
