import 'dart:convert';

import '../../domain/domain.dart';

/// The kṛt generator (`kqw_gen.cgi`, `mode=json`, `outencoding=IAST`). Nothing
/// outside this folder knows the server's field names (ARCHITECTURE.md 8.2).

/// The request: the root key and the prefix (`-` for none). The voice of the
/// query does not matter to kṛt forms.
Map<String, String> krtQueryParams(VerbQuery query) => {
      'vb': query.root,
      'upasarga': query.prefix ?? '-',
      'encoding': 'WX',
      'outencoding': 'IAST',
      'mode': 'json',
    };

const _genders = {
  'puṃ': FeatureValue.masculine,
  'strī': FeatureValue.feminine,
  'napuṃ': FeatureValue.neuter,
};

/// The labels the server sends for the first thirteen groups when it has the
/// fault of WEBSITE-TOOLS F12: a stray `yak` third and no `anīyar`, so every
/// label from the third on is one place off against its forms.
const _sentOrder = [
  'tṛc', 'tavyat', 'yak', 'śatṛ_laṭ', 'śānac_laṭ_kartari',
  'śānac_laṭ_karmaṇi', 'ghañ', 'ṇvul', 'ṇyat', 'lyuṭ', 'yat', 'kta',
  'ktavatu',
];

/// What each of those groups really is, by position.
const _correctOrder = [
  'tṛc', 'tavyat', 'śatṛ_laṭ', 'śānac_laṭ_kartari', 'śānac_laṭ_karmaṇi',
  'ghañ', 'ṇvul', 'ṇyat', 'lyuṭ', 'yat', 'kta', 'ktavatu', 'anīyar',
];

/// Thirteen gendered groups and tumun, ṇamul and ktvā (lyap with a prefix).
const _expectedGroups = 16;

/// The suffix, and the lakāra and prayoga a label like `śānac_laṭ_karmaṇi`
/// carries.
final _tailValues = {
  for (final v in FeatureValue.values)
    if (v.kind == FeatureKind.lakara || v.kind == FeatureKind.prayoga) v.iast: v,
};

class _Raw {
  _Raw(this.label);

  final String label;

  /// `null` for an entry with no `lifgam` (an indeclinable).
  final entries = <(FeatureValue?, List<SanskritText>)>[];
}

/// Reads the kṛt forms. Entries are grouped by consecutive label; `-` is an
/// empty cell and `/` separates alternatives; an entry with no `lifgam` is an
/// indeclinable (F14); every form `-` is `NotFound` (F3).
///
/// Then the labels are checked for the fault of F12 and, when the answer has
/// it in the order the correction knows, relabelled by position. Every group
/// keeps the label that was sent. An answer that does not have the signature
/// passes through untouched; one that has it in another order or length is
/// returned as sent and flagged [KrtLabels.unverified].
Outcome<KrtForms> parseKrt(String body, VerbQuery query, ResultSource source) {
  // Line breaks are only whitespace between JSON tokens; the verb program puts
  // one inside a string, so they go here too, in case this one ever does.
  final decoded = jsonDecode(body.replaceAll(RegExp(r'[\r\n]'), ''));
  final items = switch (decoded) {
    List() => decoded,
    Map() => [decoded],
    _ => throw FormatException('expected a list, got $decoded'),
  };

  final raw = <_Raw>[];
  for (final item in items) {
    if (item is! Map) throw FormatException('unexpected entry $item');
    final label = item['kqw_prawyayaH'];
    final form = item['form'];
    final lingam = item['lifgam'];
    if (label is! String || form is! String) {
      throw FormatException('unexpected entry $item');
    }
    FeatureValue? gender;
    if (lingam != null) {
      gender = _genders[lingam];
      if (gender == null) throw FormatException('unknown lifgam "$lingam"');
    }
    if (raw.isEmpty || raw.last.label != label) raw.add(_Raw(label));
    raw.last.entries.add((
      gender,
      [
        for (final f in form.split('/').map((f) => f.trim()))
          if (f.isNotEmpty && f != '-') SanskritText.from(f, Script.iast),
      ],
    ));
  }
  if (raw.every((g) => g.entries.every((e) => e.$2.isEmpty))) {
    return const NotFound();
  }

  final sent = [for (final g in raw) g.label];
  final signature = sent.length >= 3 &&
      sent[0] == 'tṛc' &&
      sent[1] == 'tavyat' &&
      sent[2] == 'yak' &&
      !sent.contains('anīyar');
  final known = signature &&
      sent.length == _expectedGroups &&
      _sameList(sent.sublist(0, _sentOrder.length), _sentOrder);
  final labels = !signature
      ? KrtLabels.asSent
      : known
          ? KrtLabels.corrected
          : KrtLabels.unverified;

  final groups = <KrtGroup>[];
  for (var i = 0; i < raw.length; i++) {
    final label = labels == KrtLabels.corrected && i < _correctOrder.length
        ? _correctOrder[i]
        : raw[i].label;
    groups.add(_group(raw[i], label));
  }
  return Found(KrtForms(query, groups, labels), source);
}

KrtGroup _group(_Raw raw, String label) {
  final parts = label.split('_');
  FeatureValue? lakara, prayoga;
  for (final part in parts.skip(1)) {
    final v = _tailValues[part];
    if (v?.kind == FeatureKind.lakara) lakara = v;
    if (v?.kind == FeatureKind.prayoga) prayoga = v;
  }

  final gendered = raw.entries.where((e) => e.$1 != null).toList();
  if (gendered.isNotEmpty && gendered.length != raw.entries.length) {
    throw FormatException('"${raw.label}" mixes gendered and indeclinable forms');
  }
  return KrtGroup(
    sentLabel: raw.label,
    label: label,
    pratyaya: SanskritText.from(parts.first, Script.iast),
    lakara: lakara,
    prayoga: prayoga,
    gendered: {for (final e in gendered) e.$1!: e.$2},
    indeclinable: gendered.isEmpty
        ? [for (final e in raw.entries) ...e.$2]
        : const [],
  );
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
