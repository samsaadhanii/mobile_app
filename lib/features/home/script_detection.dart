/// Which script the user's text is in (`SCREENS.md` section 2). Plain Dart.
library;

import '../../domain/domain.dart';

/// What was found in the text.
class DetectedInput {
  /// The script the text will be read as.
  final Script script;

  /// `true` when the text itself decided (Devanagari letters, IAST
  /// diacritics); `false` when it fell back to the Settings script.
  final bool fromText;

  /// Whitespace-separated pieces that contain a letter.
  final int words;

  const DetectedInput(this.script, this.fromText, this.words);

  @override
  bool operator ==(Object other) =>
      other is DetectedInput &&
      other.script == script &&
      other.fromText == fromText &&
      other.words == words;

  @override
  int get hashCode => Object.hash(script, fromText, words);

  @override
  String toString() => 'DetectedInput(${script.name}, $fromText, $words)';
}

const scriptNames = {
  Script.devanagari: 'Devanagari',
  Script.iast: 'IAST',
  Script.wx: 'WX',
  Script.slp1: 'SLP1',
  Script.kyotoHarvard: 'Kyoto-Harvard',
  Script.velthuis: 'Velthuis',
  Script.itrans: 'ITRANS',
};

// Devanagari letters and signs, without the daṇḍas and digits (U+0964-096F).
bool _isDevanagariLetter(int c) =>
    (c >= 0x0900 && c <= 0x0963) || (c >= 0x0970 && c <= 0x097F);

// IAST letters outside plain ASCII, either case, composed or as combining
// marks (macron, dot below, dot above, acute, tilde, candrabindu).
final _iastDiacritics = RegExp(
    '[āīūṛṝḷḹṃṁḥṅñṭḍṇśṣĀĪŪṚṜḶḸṂṀḤṄÑṬḌṆŚṢ̣̄̇́̃̐]');

final _hasLetter = RegExp(r'\p{L}', unicode: true);

/// Any Devanagari letter → Devanagari; IAST diacritics → IAST; otherwise
/// [fallback] (the Settings input script, WX when that is automatic).
DetectedInput detectInput(String text, {required Script fallback}) {
  final words =
      text.split(RegExp(r'\s+')).where((w) => _hasLetter.hasMatch(w)).length;
  if (text.runes.any(_isDevanagariLetter)) {
    return DetectedInput(Script.devanagari, true, words);
  }
  if (_iastDiacritics.hasMatch(text)) {
    return DetectedInput(Script.iast, true, words);
  }
  return DetectedInput(fallback, false, words);
}

/// "Devanagari, 3 words".
String describeDetected(DetectedInput d) =>
    '${scriptNames[d.script]}, ${d.words} ${d.words == 1 ? 'word' : 'words'}';
