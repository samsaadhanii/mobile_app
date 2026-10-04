import 'feature.dart';
import 'list_equality.dart';
import 'sanskrit_text.dart';
import 'verb_forms.dart';

/// How far the suffix names (`kṛt_pratyayaḥ` labels) of a kṛt answer can be
/// trusted (WEBSITE-TOOLS F12).
enum KrtLabels {
  /// Shown as the engine sent them: the answer does not have the fault that
  /// the correction is for (the server was fixed, or it was never there).
  asSent,

  /// The engine's labels were one place off against the forms and have been
  /// relabelled by position. Every group keeps the label that was sent.
  corrected,

  /// The answer looks like the faulty one but not in the order the correction
  /// knows, so nothing was changed. The labels may be wrong.
  unverified,
}

/// The genders of a gendered kṛt group, in the order the engine lists them.
const krtGenders = [
  FeatureValue.masculine,
  FeatureValue.feminine,
  FeatureValue.neuter,
];

/// One kṛt suffix and its forms: three gendered cells (puṃ, strī, napuṃ) or,
/// for tumun, ṇamul, ktvā and lyap, one indeclinable cell. A cell is a list of
/// forms and may be empty.
class KrtGroup {
  /// The label as the engine sent it (`yak`, `śānac_laṭ_kartari`).
  final String sentLabel;

  /// The label to show: the corrected one, or [sentLabel] when nothing was
  /// changed.
  final String label;

  /// The suffix's name, the part of [label] before any `_` (`śatṛ`, `kta`).
  final SanskritText pratyaya;

  /// The lakāra and prayoga the label carries (`śatṛ_laṭ`,
  /// `śānac_laṭ_karmaṇi`), or null.
  final FeatureValue? lakara;
  final FeatureValue? prayoga;

  /// For a gendered group, the forms by gender; empty for an indeclinable one.
  final Map<FeatureValue, List<SanskritText>> gendered;

  /// For an indeclinable group, its forms; empty for a gendered one.
  final List<SanskritText> indeclinable;

  const KrtGroup({
    required this.sentLabel,
    required this.label,
    required this.pratyaya,
    this.lakara,
    this.prayoga,
    this.gendered = const {},
    this.indeclinable = const [],
  });

  bool get isIndeclinable => gendered.isEmpty;

  /// The forms of one gender (empty for a missing or empty cell).
  List<SanskritText> forms(FeatureValue gender) => gendered[gender] ?? const [];

  /// No form at all: shown muted so every root's list reads the same.
  bool get isEmpty =>
      indeclinable.isEmpty && gendered.values.every((forms) => forms.isEmpty);

  /// Was the label changed from what the engine sent?
  bool get wasRelabelled => label != sentLabel;

  @override
  bool operator ==(Object other) =>
      other is KrtGroup &&
      other.sentLabel == sentLabel &&
      other.label == label &&
      other.pratyaya == pratyaya &&
      other.lakara == lakara &&
      other.prayoga == prayoga &&
      mapOfListsEq(other.gendered, gendered) &&
      listEq(other.indeclinable, indeclinable);

  @override
  int get hashCode => Object.hash(sentLabel, label, pratyaya, lakara, prayoga,
      mapOfListsHash(gendered), listHash(indeclinable));

  @override
  String toString() => 'KrtGroup($label'
      '${wasRelabelled ? ' (sent $sentLabel)' : ''})';
}

/// The kṛt forms of a root, in the engine's order. The engine sends no
/// heading, so a screen shows the root the user chose.
class KrtForms {
  /// What was asked for; its voice was ignored.
  final VerbQuery query;
  final List<KrtGroup> groups;
  final KrtLabels labels;

  const KrtForms(this.query, this.groups, this.labels);

  @override
  bool operator ==(Object other) =>
      other is KrtForms &&
      other.query == query &&
      other.labels == labels &&
      listEq(other.groups, groups);

  @override
  int get hashCode => Object.hash(query, labels, listHash(groups));

  @override
  String toString() => 'KrtForms($query, ${groups.length} groups, ${labels.name})';
}
