import '../app/settings.dart';
import '../domain/domain.dart';
import '../sanskrit/transliteration.dart' show convert;

/// The name of a feature kind, for the row headings of Compare. Provisional
/// wording like the rest.
String featureKindLabel(
  FeatureKind kind, {
  required LabelLanguage language,
  required Script display,
}) {
  final (iast, english) = switch (kind) {
    FeatureKind.gender => ('liṅgam', 'gender'),
    FeatureKind.vibhakti => ('vibhaktiḥ', 'case'),
    FeatureKind.number => ('vacanam', 'number'),
    FeatureKind.person => ('puruṣaḥ', 'person'),
    FeatureKind.lakara => ('lakāraḥ', 'tense or mood'),
    FeatureKind.pada => ('padam', 'pada'),
    FeatureKind.prayoga => ('prayogaḥ', 'voice'),
    FeatureKind.gana => ('gaṇaḥ', 'class'),
    FeatureKind.sanadi => ('sanādiḥ', 'derived root'),
    FeatureKind.nominalCategory => ('prakāraḥ', 'category'),
    FeatureKind.krtPratyaya => ('kṛtpratyayaḥ', 'kṛt suffix'),
    FeatureKind.unknown => (null, 'other'),
  };
  if (language == LabelLanguage.sanskrit && iast != null) {
    return convert(iast, Script.iast, display);
  }
  return english;
}

/// The input fields of the tool screens that are named by a grammatical term.
enum ToolField { dhatu, upasarga, linga, prakara }

/// The name of an input field, by the same rule as the feature labels:
/// Sanskrit (shown in the [display] script) or English, per [language].
/// Placeholders and hints are interface text and are not set here.
String toolFieldLabel(
  ToolField field, {
  required LabelLanguage language,
  required Script display,
}) {
  final (iast, english) = switch (field) {
    ToolField.dhatu => ('dhātuḥ', 'Root'),
    ToolField.upasarga => ('upasargaḥ', 'Prefix'),
    ToolField.linga => ('liṅgam', 'Gender'),
    ToolField.prakara => ('prakāraḥ', 'Category'),
  };
  return language == LabelLanguage.sanskrit
      ? convert(iast, Script.iast, display)
      : english;
}
