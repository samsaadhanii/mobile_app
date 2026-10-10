import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../../sanskrit/transliteration.dart' show convert;

/// The text of one feature chip.
///
/// [ownLabels] shows exactly what the engine said (`Feature.original`).
/// Otherwise a known value is shown by its Sanskrit (IAST) or English name,
/// per [language]; Sanskrit names are Sanskrit words, so they are shown in the
/// [display] script (`प्रथमा` or `prathamā`), and English names never change; an open-class value (a kṛt suffix) is shown as Sanskrit
/// text in the [display] script; an unknown one as the engine wrote it.
String featureLabel(
  Feature f, {
  required LabelLanguage language,
  required Script display,
  bool ownLabels = false,
}) {
  if (ownLabels) return f.original;
  if (f.value == FeatureValue.openClass) {
    return f.text?.display(display) ?? f.original;
  }
  if (f.value == FeatureValue.unknown) return f.original;
  return featureValueLabel(f.value, language: language, display: display);
}

/// The name of one known value: Sanskrit (IAST, shown in the [display]
/// script) or English, per [language]. For headings and menus, where there is
/// no engine wording to keep.
///
/// With [short], the short name for table headings (`pra.`, `3rd`) when the
/// value has one; otherwise the full name.
String featureValueLabel(
  FeatureValue value, {
  required LabelLanguage language,
  required Script display,
  bool short = false,
}) {
  final sanskrit = language == LabelLanguage.sanskrit;
  if (short) {
    final shortName = sanskrit ? value.shortIast : value.shortEnglish;
    if (shortName != null) {
      return sanskrit ? convert(shortName, Script.iast, display) : shortName;
    }
  }
  return sanskrit ? convert(value.iast, Script.iast, display) : value.english;
}

/// The word-class tag, by the same rule as the feature labels: Sanskrit
/// (shown in the [display] script) or English, per [language]. A class with
/// no Sanskrit name reads the same in both.
String wordClassLabel(
  WordClass c, {
  required LabelLanguage language,
  required Script display,
}) {
  final iast = c.iast;
  if (language == LabelLanguage.sanskrit && iast != null) {
    return convert(iast, Script.iast, display);
  }
  return c.english;
}

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

/// Whether a feature's label is Sanskrit text, which is never set below 16 sp.
bool featureIsSanskrit(Feature f, {required LabelLanguage language, bool ownLabels = false}) =>
    ownLabels ||
    language == LabelLanguage.sanskrit ||
    f.value == FeatureValue.openClass ||
    f.value == FeatureValue.unknown;
