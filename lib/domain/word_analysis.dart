import 'feature.dart';
import 'list_equality.dart';
import 'sanskrit_text.dart';

enum WordClass {
  noun,
  verb,
  participle,
  indeclinable,

  /// A non-final member of a compound, not analysed on its own
  /// (in initio compositi).
  compoundMember,
  other,
}

/// One feature of an analysis. [original] is exactly what the engine said
/// ("puM", "m.", "pra"), kept even when [value] is understood.
///
/// A closed kind (gender, case, ...) has a [FeatureValue]. An open kind
/// (`FeatureKind.krtPratyaya`) has `FeatureValue.openClass` and the value as
/// Sanskrit text in [text].
class Feature {
  final FeatureKind kind;
  final FeatureValue value;
  final String original;
  final SanskritText? text;

  const Feature(this.kind, this.value, this.original, {this.text});

  @override
  bool operator ==(Object other) =>
      other is Feature &&
      other.kind == kind &&
      other.value == value &&
      other.original == original &&
      other.text == text;

  @override
  int get hashCode => Object.hash(kind, value, original, text);

  @override
  String toString() => 'Feature(${kind.name}, ${value.name}, "$original"'
      '${text == null ? '' : ', text: ${text!.wx}'})';
}

class Analysis {
  /// The dictionary form: `rAma`, `gam`. A homonym number goes in [homonym].
  final SanskritText lemma;
  final int? homonym;
  final WordClass wordClass;
  final List<Feature> features;

  /// For a participle, the root it comes from (`gam` for `gacCaw`).
  final SanskritText? base;

  /// The engine's derivation note, as given.
  final String? derivation;

  /// The prefix (upasarga) of a verb or kṛt analysis, as the engine's key
  /// (`Af`, `pra`, `aXi_ava`, the keys of `assets/prefix_list.json`); null for
  /// none or when the engine does not say.
  final SanskritText? prefix;

  const Analysis({
    required this.lemma,
    this.homonym,
    required this.wordClass,
    this.features = const [],
    this.base,
    this.derivation,
    this.prefix,
  });

  @override
  bool operator ==(Object other) =>
      other is Analysis &&
      other.lemma == lemma &&
      other.homonym == homonym &&
      other.wordClass == wordClass &&
      listEq(other.features, features) &&
      other.base == base &&
      other.derivation == derivation &&
      other.prefix == prefix;

  @override
  int get hashCode => Object.hash(
      lemma, homonym, wordClass, listHash(features), base, derivation, prefix);

  @override
  String toString() => 'Analysis(${lemma.wx}'
      '${homonym == null ? '' : '#$homonym'}, ${wordClass.name}, $features'
      '${base == null ? '' : ', base: ${base!.wx}'}'
      '${derivation == null ? '' : ', derivation: $derivation'}'
      '${prefix == null ? '' : ', prefix: ${prefix!.wx}'})';
}

class WordAnalysis {
  final SanskritText input;

  /// In the engine's order.
  final List<Analysis> analyses;

  const WordAnalysis(this.input, this.analyses);

  @override
  bool operator ==(Object other) =>
      other is WordAnalysis &&
      other.input == input &&
      listEq(other.analyses, analyses);

  @override
  int get hashCode => Object.hash(input, listHash(analyses));

  @override
  String toString() => 'WordAnalysis(${input.wx}, $analyses)';
}
