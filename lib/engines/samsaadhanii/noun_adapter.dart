import 'dart:convert';

import '../../domain/domain.dart';

/// The noun generator (`noun_gen.cgi`, `mode=json`, `outencoding=IAST`).
/// Nothing outside this folder knows the server's field names
/// (ARCHITECTURE.md 8.2).

/// `gen`: the server's WX gender codes.
const _genderCodes = {
  FeatureValue.masculine: 'puM',
  FeatureValue.feminine: 'swrI',
  FeatureValue.neuter: 'napuM',
  FeatureValue.noGender: 'a',
};

/// `jAwi`: the nominal category.
const _categoryCodes = {
  FeatureValue.plainNoun: 'nA',
  FeatureValue.sarvanama: 'sarva',
  FeatureValue.sankhya: 'saMKyA',
  FeatureValue.sankhyeya: 'saMKyeyam',
  FeatureValue.purana: 'pUraNam',
};

/// The server's gender code, or null for a value it has none for.
String? genderCode(FeatureValue gender) => _genderCodes[gender];

/// The server's category code, or null for a value it has none for.
String? categoryCode(FeatureValue category) => _categoryCodes[category];

const _vibhaktis = {
  'prathamā': FeatureValue.nominative,
  'dvitīyā': FeatureValue.accusative,
  'tṛtīyā': FeatureValue.instrumental,
  'caturthī': FeatureValue.dative,
  'pañcamī': FeatureValue.ablative,
  'ṣaṣṭhī': FeatureValue.genitive,
  'saptamī': FeatureValue.locative,
  'saṃ.pra': FeatureValue.vocative,
};

const _numbers = {
  'ekavacanam': FeatureValue.singular,
  // `xvivacanam` is a WX leak in the IAST output (WEBSITE-TOOLS F7).
  'xvivacanam': FeatureValue.dual,
  'dvivacanam': FeatureValue.dual,
  'bahuvacanam': FeatureValue.plural,
};

/// Reads the noun table. A cell of `-` is an empty cell (F4); a cell with
/// alternatives (`mām/mā`) holds several forms; a table in which every cell
/// is empty means the stem is unknown, which is `NotFound` (F3).
///
/// Some endpoints return a single object where a list is expected, so one
/// object is read as a list of one.
Outcome<NounParadigm> parseNoun(
    String body, NounQuery query, ResultSource source) {
  final decoded = jsonDecode(body);
  final items = switch (decoded) {
    List() => decoded,
    Map() => [decoded],
    _ => throw FormatException('expected a list of forms, got $decoded'),
  };

  final cells = <(FeatureValue, FeatureValue), List<SanskritText>>{};
  for (final item in items) {
    if (item is! Map) throw FormatException('unexpected entry $item');
    final vibhakti = _vibhaktis[item['vib']];
    final number = _numbers[item['vac']];
    final form = item['form'];
    if (vibhakti == null || number == null || form is! String) {
      throw FormatException('unexpected entry $item');
    }
    cells[(vibhakti, number)] = [
      for (final f in form.split('/').map((f) => f.trim()))
        if (f.isNotEmpty && f != '-') SanskritText.from(f, Script.iast),
    ];
  }

  if (cells.values.every((forms) => forms.isEmpty)) return const NotFound();
  return Found(NounParadigm(query, cells), source);
}
