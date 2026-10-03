import '../../domain/domain.dart';

/// Heritage's abbreviated grammatical labels, mapped to the app's features.
/// Only labels seen in live answers (or named in U7) are mapped; the full
/// list is Heritage question 4. Anything else stays `unknown` with the label
/// kept.

const _genders = {
  'm.': FeatureValue.masculine,
  'f.': FeatureValue.feminine,
  'n.': FeatureValue.neuter,
};

/// `*` is the gender of the personal pronouns asmad and yuṣmad (live: `aham`
/// → `asmax`, `* sg. nom.`).
const _noGender = '*';

/// The sanādi suffix: `ca.` causative (seen live), `des.` desiderative and
/// `int.` intensive (from the documented abbreviations, not yet seen).
const _sanadi = {
  'ca.': FeatureValue.nic,
  'des.': FeatureValue.san,
  'int.': FeatureValue.yan,
};

const _numbers = {
  'sg.': FeatureValue.singular,
  'du.': FeatureValue.dual,
  'pl.': FeatureValue.plural,
};

const _cases = {
  'nom.': FeatureValue.nominative,
  'acc.': FeatureValue.accusative,
  'i.': FeatureValue.instrumental,
  'dat.': FeatureValue.dative,
  'abl.': FeatureValue.ablative,
  'g.': FeatureValue.genitive,
  'loc.': FeatureValue.locative,
  'voc.': FeatureValue.vocative,
};

const _tenses = {
  'pr.': FeatureValue.lat,
  'impft.': FeatureValue.lan,
  'opt.': FeatureValue.vidhiling,
  'imp.': FeatureValue.lot,
  'fut.': FeatureValue.lrt,
};

/// Voice: `ac.` active, `md.`/`mo.` middle (both spellings seen), `ps.`
/// passive. Active and middle give the pada, passive gives the prayoga.
const _voices = {
  'ac.': (FeatureKind.pada, FeatureValue.parasmaipada),
  'md.': (FeatureKind.pada, FeatureValue.atmanepada),
  'mo.': (FeatureKind.pada, FeatureValue.atmanepada),
  'ps.': (FeatureKind.prayoga, FeatureValue.karmani),
};

/// Heritage numbers persons the other way round from the Sanskrit order:
/// 3 is prathama, 1 is uttama (checked against Samsaadhanii's answer for
/// `rAmaH`, "rāmaḥ" as the 1st plural of rā).
const _persons = {
  '1': FeatureValue.first,
  '2': FeatureValue.second,
  '3': FeatureValue.third,
};

final _gana = RegExp(r'^\[(\d+)\]$');
final _ganaValues = FeatureValue.of(FeatureKind.gana);

/// What the labels of one `inflectional_morphs` entry say about the word.
class ParsedLabels {
  final WordClass wordClass;
  final List<Feature> features;

  /// Labels that were not mapped, as written.
  final List<String> unmapped;

  const ParsedLabels(this.wordClass, this.features, this.unmapped);
}

ParsedLabels parseLabels(String entry) {
  final features = <Feature>[];
  final unmapped = <String>[];
  var wordClass = WordClass.other;
  var hasGender = false;
  var hasTense = false;

  for (final token in entry.trim().split(RegExp(r'\s+'))) {
    if (token.isEmpty) continue;
    if (token == 'ind.') {
      wordClass = WordClass.indeclinable;
    } else if (token == 'iic.') {
      wordClass = WordClass.compoundMember;
    } else if (_genders.containsKey(token)) {
      features.add(Feature(FeatureKind.gender, _genders[token]!, token));
      hasGender = true;
    } else if (token == _noGender) {
      features.add(Feature(FeatureKind.gender, FeatureValue.noGender, token));
      hasGender = true;
    } else if (_sanadi.containsKey(token)) {
      features.add(Feature(FeatureKind.sanadi, _sanadi[token]!, token));
    } else if (_numbers.containsKey(token)) {
      features.add(Feature(FeatureKind.number, _numbers[token]!, token));
    } else if (_cases.containsKey(token)) {
      features.add(Feature(FeatureKind.vibhakti, _cases[token]!, token));
    } else if (_tenses.containsKey(token)) {
      features.add(Feature(FeatureKind.lakara, _tenses[token]!, token));
      hasTense = true;
    } else if (_voices.containsKey(token)) {
      final (kind, value) = _voices[token]!;
      features.add(Feature(kind, value, token));
      hasTense = true;
    } else if (_persons.containsKey(token)) {
      features.add(Feature(FeatureKind.person, _persons[token]!, token));
    } else if (_gana.hasMatch(token)) {
      final n = int.parse(_gana.firstMatch(token)![1]!);
      features.add(Feature(
        FeatureKind.gana,
        n >= 1 && n <= _ganaValues.length
            ? _ganaValues[n - 1]
            : FeatureValue.unknown,
        token,
      ));
      if (n < 1 || n > _ganaValues.length) unmapped.add(token);
    } else {
      features.add(Feature(FeatureKind.unknown, FeatureValue.unknown, token));
      unmapped.add(token);
    }
  }

  if (wordClass == WordClass.other) {
    if (hasTense) {
      wordClass = WordClass.verb;
    } else if (hasGender) {
      wordClass = WordClass.noun;
    }
  }
  return ParsedLabels(wordClass, features, unmapped);
}
