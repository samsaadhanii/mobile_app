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
  return language == LabelLanguage.sanskrit
      ? convert(f.value.iast, Script.iast, display)
      : f.value.english;
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
