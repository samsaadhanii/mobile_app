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

/// The word-class tag.
String wordClassLabel(WordClass c) => switch (c) {
      WordClass.noun => 'noun',
      WordClass.verb => 'verb',
      WordClass.participle => 'participle',
      WordClass.indeclinable => 'indeclinable',
      WordClass.compoundMember => 'compound member',
      WordClass.other => 'other',
    };
