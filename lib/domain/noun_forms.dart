import 'feature.dart';
import 'list_equality.dart';
import 'sanskrit_text.dart';

/// What to decline: a stem, its gender and the kind of nominal it is.
class NounQuery {
  final SanskritText stem;

  /// masculine, feminine, neuter or noGender (asmad, yuṣmad).
  final FeatureValue gender;

  /// A `FeatureKind.nominalCategory` value: plainNoun, sarvanama, sankhya,
  /// sankhyeya or purana.
  final FeatureValue category;

  const NounQuery({
    required this.stem,
    required this.gender,
    this.category = FeatureValue.plainNoun,
  });

  @override
  bool operator ==(Object other) =>
      other is NounQuery &&
      other.stem == stem &&
      other.gender == gender &&
      other.category == category;

  @override
  int get hashCode => Object.hash(stem, gender, category);

  @override
  String toString() => 'NounQuery(${stem.wx}, ${gender.name}, ${category.name})';
}

/// The eight vibhaktis in table order (sambodhana last) and the three numbers.
const vibhaktiOrder = [
  FeatureValue.nominative,
  FeatureValue.accusative,
  FeatureValue.instrumental,
  FeatureValue.dative,
  FeatureValue.ablative,
  FeatureValue.genitive,
  FeatureValue.locative,
  FeatureValue.vocative,
];

const numberOrder = [
  FeatureValue.singular,
  FeatureValue.dual,
  FeatureValue.plural,
];

/// The forms of a noun, by vibhakti and number. A cell holds a list of forms
/// (asmad has `mām/mā`), and a cell may be empty (a form that does not exist).
class NounParadigm {
  final NounQuery query;
  final Map<(FeatureValue, FeatureValue), List<SanskritText>> cells;

  const NounParadigm(this.query, this.cells);

  /// The forms in one cell; empty when the cell is empty or absent.
  List<SanskritText> forms(FeatureValue vibhakti, FeatureValue number) =>
      cells[(vibhakti, number)] ?? const [];

  @override
  bool operator ==(Object other) {
    if (other is! NounParadigm ||
        other.query != query ||
        other.cells.length != cells.length) {
      return false;
    }
    for (final e in cells.entries) {
      if (!listEq(other.cells[e.key], e.value)) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        query,
        Object.hashAllUnordered(
            [for (final e in cells.entries) Object.hash(e.key, listHash(e.value))]),
      );

  @override
  String toString() => 'NounParadigm($query, ${cells.length} cells)';
}
