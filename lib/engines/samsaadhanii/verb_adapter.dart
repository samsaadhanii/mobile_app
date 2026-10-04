import 'dart:convert';

import '../../domain/domain.dart';

/// The verb generator (`verb_gen.cgi`, `mode=json`, `outencoding=IAST`).
/// Nothing outside this folder knows the server's field names
/// (ARCHITECTURE.md 8.2).

/// `prayoga_paxI` for a voice. ṇijanta is two calls, one per pada, merged by
/// [mergeVerb].
const activeCode = 'karwari-uBayapaxI';
const passiveCode = 'karmaNi';
const causativeParasmaipadaCode = 'Nickarwari-parasmEpaxI';
const causativeAtmanepadaCode = 'Nickarwari-AwmanepaxI';

/// The request for one call: [prayogaPada] is one of the codes above;
/// `upasarga` is `-` for no prefix.
Map<String, String> verbQueryParams(VerbQuery query, String prayogaPada) => {
      'vb': query.root,
      'prayoga_paxI': prayogaPada,
      'upasarga': query.prefix ?? '-',
      'encoding': 'WX',
      'outencoding': 'IAST',
      'mode': 'json',
    };

const _persons = {
  'prathamapuruṣaḥ': FeatureValue.third,
  'madhyamapuruṣaḥ': FeatureValue.second,
  'uttamapuruṣaḥ': FeatureValue.first,
};

const _numbers = {
  'ekavacanam': FeatureValue.singular,
  'dvivacanam': FeatureValue.dual,
  // The noun program leaks `xvivacanam` (F7); accepted here too.
  'xvivacanam': FeatureValue.dual,
  'bahuvacanam': FeatureValue.plural,
};

/// The server's key for each pada.
const _padaKeys = [
  ('parasmE', FeatureValue.parasmaipada),
  ('Awmane', FeatureValue.atmanepada),
];

// Letters the server's headings spell without their diacritics (F14: `lat`
// for laṭ, `vidhilṅ`, `āśīrlṅ`), so a heading is compared by its first three
// letters with the marks folded away.
const _fold = {
  'ṭ': 't', 'ṅ': 'n', 'ṛ': 'r', 'ā': 'a', 'ī': 'i', 'ū': 'u', 'ś': 's',
  'ṣ': 's', 'ṇ': 'n', 'ñ': 'n', 'ḍ': 'd', 'ṃ': 'm', 'ḥ': 'h',
};

String _key(String s) {
  final b = StringBuffer();
  for (final c in s.toLowerCase().split('')) {
    b.write(_fold[c] ?? c);
  }
  final k = b.toString();
  return k.length < 3 ? k : k.substring(0, 3);
}

/// Reads the verb tables. The server's raw line break inside `rt` when there
/// is a prefix makes its JSON invalid (F2, `BUGS.md` #14), so line breaks are
/// removed before decoding; JSON allows them only between tokens, where they
/// mean nothing.
///
/// A pada whose cells are all `-` is left out (ātmanepada of a parasmaipadī
/// root, F4); no pada left is `NotFound` (F3, F13). The ten lakāras are mapped
/// by position, not by the misspelt headings; a heading that does not start
/// like the lakāra in that position is a `ServerFault`.
Outcome<VerbParadigm> parseVerb(
    String body, VerbQuery query, ResultSource source) {
  final decoded = jsonDecode(body.replaceAll(RegExp(r'[\r\n]'), ''));
  final items = switch (decoded) {
    List() => decoded,
    Map() => [decoded],
    _ => throw FormatException('expected a list, got $decoded'),
  };
  if (items.isEmpty || items.first is! Map) {
    throw const FormatException('no verb entry');
  }
  final entry = items.first as Map;
  final rt = entry['rt'];
  if (rt is! String) throw FormatException('no heading in $entry');

  final padas = <PadaTables>[];
  for (final (key, pada) in _padaKeys) {
    final raw = entry[key];
    if (raw == null) continue;
    final tables = _readPada(raw);
    if (tables.every((t) => t.isEmpty)) continue;
    padas.add(PadaTables(pada, tables));
  }
  if (padas.isEmpty) return const NotFound();
  return Found(
      VerbParadigm(query, SanskritText.from(rt.trim(), Script.iast), padas),
      source);
}

List<LakaraTable> _readPada(Object raw) {
  // "each a one-element list holding `paxI` and the lakāras".
  final pada = switch (raw) {
    List() when raw.isNotEmpty => raw.first,
    Map() => raw,
    _ => throw FormatException('unexpected pada $raw'),
  };
  if (pada is! Map) throw FormatException('unexpected pada $pada');

  final tables = <LakaraTable>[];
  for (var i = 0; i < lakaraOrder.length; i++) {
    final lakara = lakaraOrder[i];
    final heading = pada['lakAra_$i'];
    final forms = pada['l_forms_$i'];
    if (heading is! String || forms is! List) {
      throw FormatException('lakāra $i is missing');
    }
    if (_key(heading) != _key(lakara.iast)) {
      throw FormatException(
          'lakāra $i is "$heading", expected ${lakara.iast}');
    }
    final cells = <(FeatureValue, FeatureValue), List<SanskritText>>{};
    for (final cell in forms) {
      if (cell is! Map) throw FormatException('unexpected cell $cell');
      final person = _persons[cell['person']];
      final number = _numbers[cell['number']];
      final form = cell['form'];
      if (person == null || number == null || form is! String) {
        throw FormatException('unexpected cell $cell');
      }
      cells[(person, number)] = [
        for (final f in form.split('/').map((f) => f.trim()))
          if (f.isNotEmpty && f != '-') SanskritText.from(f, Script.iast),
      ];
    }
    tables.add(LakaraTable(lakara, cells));
  }
  return tables;
}

/// Puts the two one-pada answers of a ṇijanta together. A pada that has no
/// form is simply absent, so one `NotFound` beside a `Found` is the root
/// having one pada only. A failure of either call fails the whole answer: a
/// table that silently lacks a pada would be wrong.
Outcome<VerbParadigm> mergeVerb(
    Outcome<VerbParadigm> a, Outcome<VerbParadigm> b) {
  for (final o in [a, b]) {
    if (o is! Found<VerbParadigm> && o is! NotFound<VerbParadigm>) return o;
  }
  if (a is Found<VerbParadigm> && b is Found<VerbParadigm>) {
    final padas = [...a.value.padas, ...b.value.padas]..sort((x, y) =>
        padaOrder.indexOf(x.pada).compareTo(padaOrder.indexOf(y.pada)));
    return Found(
        VerbParadigm(a.value.query, a.value.heading, padas), a.source);
  }
  if (a is Found<VerbParadigm>) return a;
  if (b is Found<VerbParadigm>) return b;
  return const NotFound();
}
