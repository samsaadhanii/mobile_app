import 'feature.dart';
import 'list_equality.dart';
import 'sanskrit_text.dart';

/// Which form to derive: the stem and the cell of its table (never the
/// inflected form: the derivation starts from the stem).
class DerivationQuery {
  final SanskritText stem;
  final FeatureValue gender;
  final FeatureValue vibhakti;
  final FeatureValue number;

  const DerivationQuery({
    required this.stem,
    required this.gender,
    required this.vibhakti,
    required this.number,
  });

  @override
  bool operator ==(Object other) =>
      other is DerivationQuery &&
      other.stem == stem &&
      other.gender == gender &&
      other.vibhakti == vibhakti &&
      other.number == number;

  @override
  int get hashCode => Object.hash(stem, gender, vibhakti, number);

  @override
  String toString() =>
      'DerivationQuery(${stem.wx}, ${gender.name}, ${vibhakti.name}, ${number.name})';
}

/// A rule the engine considered at a point of the derivation before the one
/// that applied.
class ConsideredRule {
  final String sutra;
  final String sutraText;

  const ConsideredRule(this.sutra, this.sutraText);

  @override
  bool operator ==(Object other) =>
      other is ConsideredRule &&
      other.sutra == sutra &&
      other.sutraText == sutraText;

  @override
  int get hashCode => Object.hash(sutra, sutraText);

  @override
  String toString() => 'ConsideredRule($sutra)';
}

/// One rule applied. [sutra], [sutraText], [label] and [state] are the raw
/// strings the engine sends, in Devanagari. They are not [SanskritText] and
/// are never converted: the state lines mix Sanskrit with Latin markers such
/// as `root(राम)`.
class DerivationStep {
  /// The sūtra number as given, `8-4-2`.
  final String sutra;
  final String sutraText;

  /// What the rule did to the form (`त्रिपादी`, `सुप्`).
  final String label;

  /// The lines that follow the rule: the form's state after it.
  final List<String> state;

  /// The rules considered just before this one, each once, in order.
  final List<ConsideredRule> considered;

  const DerivationStep({
    required this.sutra,
    required this.sutraText,
    required this.label,
    this.state = const [],
    this.considered = const [],
  });

  @override
  bool operator ==(Object other) =>
      other is DerivationStep &&
      other.sutra == sutra &&
      other.sutraText == sutraText &&
      other.label == label &&
      listEq(other.state, state) &&
      listEq(other.considered, considered);

  @override
  int get hashCode => Object.hash(
      sutra, sutraText, label, listHash(state), listHash(considered));

  @override
  String toString() => 'DerivationStep($sutra, $label, ${state.length} lines)';
}

/// How a form is derived, step by step.
class Derivation {
  /// The finished form, in Devanagari as the engine sends it.
  final String form;
  final List<DerivationStep> steps;

  const Derivation(this.form, this.steps);

  @override
  bool operator ==(Object other) =>
      other is Derivation && other.form == form && listEq(other.steps, steps);

  @override
  int get hashCode => Object.hash(form, listHash(steps));

  @override
  String toString() => 'Derivation($form, ${steps.length} steps)';
}
