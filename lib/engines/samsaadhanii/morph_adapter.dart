import 'dart:convert';

import '../../domain/domain.dart';

/// Parses `morph.cgi` answers (`mode=json`, `outencoding=IAST`) into
/// [WordAnalysis]. Nothing outside this folder knows the server's field
/// names (ARCHITECTURE.md 8.2).

final _group = RegExp(r'\{([^{}:]*):([^{}]*)\}');
final _trailingDigits = RegExp(r'^(.*?)(\d+)?$');

const _genders = {
  'puṃ': FeatureValue.masculine,
  'strī': FeatureValue.feminine,
  'napuṃ': FeatureValue.neuter,
  'napuṃsakam': FeatureValue.neuter,
  // `a` is the gender of asmad and yuṣmad ("for asmad, yuṣmad", version 1).
  'a': FeatureValue.noGender,
};

const _cases = {
  '1': FeatureValue.nominative,
  '2': FeatureValue.accusative,
  '3': FeatureValue.instrumental,
  '4': FeatureValue.dative,
  '5': FeatureValue.ablative,
  '6': FeatureValue.genitive,
  '7': FeatureValue.locative,
  '8': FeatureValue.vocative,
};

const _numbers = {
  'eka': FeatureValue.singular,
  'dvi': FeatureValue.dual,
  'bahu': FeatureValue.plural,
};

const _persons = {
  'pra': FeatureValue.third,
  'ma': FeatureValue.second,
  'u': FeatureValue.first,
};

const _lakaras = {
  'laṭ': FeatureValue.lat,
  'liṭ': FeatureValue.lit,
  'luṭ': FeatureValue.lut,
  'lṛṭ': FeatureValue.lrt,
  'leṭ': FeatureValue.let,
  'loṭ': FeatureValue.lot,
  'laṅ': FeatureValue.lan,
  'vidhiliṅ': FeatureValue.vidhiling,
  'āśīrliṅ': FeatureValue.ashirling,
  'luṅ': FeatureValue.lun,
  'lṛṅ': FeatureValue.lrn,
};

const _padas = {
  'parasmaipadī': FeatureValue.parasmaipada,
  'ātmanepadī': FeatureValue.atmanepada,
};

/// `vargaḥ`: `sarva` marks a pronoun (sarvanāma). `avy` is dropped before this
/// table is read; other values are not known yet and stay unknown.
const _vargas = {
  'sarva': FeatureValue.sarvanama,
};

/// `sanādi_pratyayaḥ` (IAST output, seen live on `gamayawi`: `ṇic`).
const _sanadis = {
  'ṇic': FeatureValue.nic,
  'san': FeatureValue.san,
  'yaṅ': FeatureValue.yan,
};

const _prayogas = {
  'kartari': FeatureValue.kartari,
  'karmaṇi': FeatureValue.karmani,
  'bhāve': FeatureValue.bhave,
};

/// The WX spellings of the same values, as in the server's API document
/// (`Nickarwari`); only read after a `Nic` prefix.
const _prayogasWx = {
  'karwari': FeatureValue.kartari,
  'karmaNi': FeatureValue.karmani,
  'BAve': FeatureValue.bhave,
};

const _ganas = {
  'bhvādiḥ': FeatureValue.bhvadi,
  'adādiḥ': FeatureValue.adadi,
  'juhotyādiḥ': FeatureValue.juhotyadi,
  'divādiḥ': FeatureValue.divadi,
  'svādiḥ': FeatureValue.svadi,
  'tudādiḥ': FeatureValue.tudadi,
  'rudhādiḥ': FeatureValue.rudhadi,
  'tanādiḥ': FeatureValue.tanadi,
  'kryādiḥ': FeatureValue.kryadi,
  'curādiḥ': FeatureValue.curadi,
};

/// key -> (kind, value table), for the keys the adapter understands.
const _keys = <String, (FeatureKind, Map<String, FeatureValue>)>{
  'liṅgam': (FeatureKind.gender, _genders),
  'vibhaktiḥ': (FeatureKind.vibhakti, _cases),
  'vacanam': (FeatureKind.number, _numbers),
  'puruṣaḥ': (FeatureKind.person, _persons),
  'lakāraḥ': (FeatureKind.lakara, _lakaras),
  'padī': (FeatureKind.pada, _padas),
  'prayogaḥ': (FeatureKind.prayoga, _prayogas),
  'sanādi_pratyayaḥ': (FeatureKind.sanadi, _sanadis),
  'vargaḥ': (FeatureKind.nominalCategory, _vargas),
  'gaṇaḥ': (FeatureKind.gana, _ganas),
};

const _noAnswer = 'No answer found';

/// Called for every `{key:value}` the adapter could not map, with the pair as
/// the server wrote it.
typedef OnUnmapped = void Function(String key, String value);

Outcome<WordAnalysis> parseMorph(
  String body,
  SanskritText input,
  ResultSource source, {
  OnUnmapped? onUnmapped,
}) {
  final text = body.trim();
  Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    // The server's "nothing found" is `["ANS":"No answer found"]`, which is
    // not JSON (WEBSITE-TOOLS F3).
    if (text.contains(_noAnswer)) return const NotFound();
    return const ServerFault('morph: the answer is not JSON');
  }

  // Some endpoints return one object where a list is expected.
  final List<Object?> items = switch (decoded) {
    List<Object?> list => list,
    Map<String, Object?> map => [map],
    _ => const [],
  };
  if (items.isEmpty) return const ServerFault('morph: empty answer');

  final analyses = <Analysis>[];
  for (final item in items) {
    if (item is! Map || item['ANS'] is! String) {
      return const ServerFault('morph: an entry has no ANS');
    }
    analyses.add(_analysis(item.cast<String, Object?>(), onUnmapped));
  }
  return Found(WordAnalysis(input, analyses), source);
}

Analysis _analysis(Map<String, Object?> item, OnUnmapped? onUnmapped) {
  final app = item['APP'] as String? ?? '';
  final wordClass = switch (app) {
    'noun' => WordClass.noun,
    'verb' => WordClass.verb,
    'kqw' => WordClass.participle,
    'dict_help' => WordClass.indeclinable,
    _ => WordClass.other,
  };

  final ans = item['ANS'] as String;
  final features = <Feature>[];
  String? kritSuffix;
  SanskritText? root;
  for (final m in _group.allMatches(ans)) {
    final key = m[1]!;
    final value = m[2]!;
    if (key == 'kṛt_pratyayaḥ') {
      // "śatṛ_laṭ": the suffix, and the lakāra it belongs to.
      kritSuffix = value;
      final cut = value.lastIndexOf('_');
      final tail = cut < 0 ? null : _lakaras[value.substring(cut + 1)];
      final suffix = tail == null ? value : value.substring(0, cut);
      features.add(Feature(FeatureKind.krtPratyaya, FeatureValue.openClass,
          suffix, text: SanskritText.from(suffix, Script.iast)));
      if (tail != null) {
        features.add(Feature(FeatureKind.lakara, tail, value.substring(cut + 1)));
      }
      continue;
    }
    if (key == 'dhātuḥ') {
      // The root, not a feature of the word.
      root = SanskritText.from(value, Script.iast);
      continue;
    }
    if (key == 'vargaḥ' && value == 'avy') {
      // Says "indeclinable", which APP already gives.
      continue;
    }
    if (key == 'prayogaḥ' && value.startsWith('Nic')) {
      // "Nickarwari": the causative suffix, then the prayoga.
      final rest = value.substring(3);
      features.add(Feature(FeatureKind.sanadi, FeatureValue.nic, 'Nic'));
      final mapped = _prayogas[rest] ?? _prayogasWx[rest];
      features.add(Feature(FeatureKind.prayoga, mapped ?? FeatureValue.unknown, rest));
      if (mapped == null) onUnmapped?.call(key, value);
      continue;
    }
    final entry = _keys[key];
    if (entry == null) {
      // Unknown key: keep the whole pair, as the server wrote it.
      features.add(Feature(FeatureKind.unknown, FeatureValue.unknown, '$key:$value'));
      onUnmapped?.call(key, value);
      continue;
    }
    final mapped = entry.$2[value];
    features.add(Feature(entry.$1, mapped ?? FeatureValue.unknown, value));
    if (mapped == null) onUnmapped?.call(key, value);
  }

  // Text outside the braces is the participle stem ("gacchat ").
  final bare = ans.replaceAll(_group, '').trim();

  // RT is the lemma in IAST, with a trailing homonym number; rt is the
  // server's key (WX), whose first part carries the number as well.
  final rt = item['RT'] as String?;
  final key = item['rt'] as String?;
  String lemmaIast = rt ?? '';
  int? homonym;
  final fromRt = _trailingDigits.firstMatch(lemmaIast);
  if (fromRt != null && fromRt[2] != null) {
    lemmaIast = fromRt[1]!;
    homonym = int.parse(fromRt[2]!);
  }
  if (homonym == null && key != null) {
    final first = key.split('_').first;
    final m = _trailingDigits.firstMatch(first);
    if (m != null && m[2] != null) homonym = int.parse(m[2]!);
  }
  var lemma = SanskritText.from(lemmaIast, Script.iast);

  SanskritText? base;
  if (wordClass == WordClass.participle && bare.isNotEmpty) {
    base = root ?? lemma;
    lemma = SanskritText.from(bare, Script.iast);
  } else if (bare.isNotEmpty) {
    features.add(Feature(FeatureKind.unknown, FeatureValue.unknown, bare));
    onUnmapped?.call('', bare);
  }

  base ??= root;

  if (wordClass == WordClass.other) onUnmapped?.call('APP', app);

  // `upasarga` is the prefix's key (WX, as in the prefix list) on verb and kṛt
  // analyses, `-` for none.
  final upasarga = item['upasarga'];
  final prefix = upasarga is String && upasarga.isNotEmpty && upasarga != '-'
      ? SanskritText(upasarga)
      : null;

  return Analysis(
    lemma: lemma,
    homonym: homonym,
    wordClass: wordClass,
    features: features,
    base: base,
    derivation: kritSuffix,
    prefix: prefix,
  );
}
