import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../home/script_detection.dart';

/// Reads what the user typed as Sanskrit: the script is detected from the
/// text, falling back to the Settings input script (WX when that is
/// automatic), as on Home.
SanskritText parseSanskrit(String text, AppSettings settings) {
  final detected = detectInput(
    text,
    fallback: settings.inputScript.script ?? Script.wx,
  );
  return SanskritText.from(text.trim(), detected.script);
}

/// The first word of [text], for tasks that take one word.
String firstWord(String text) {
  final parts = text.trim().split(RegExp(r'\s+'));
  return parts.isEmpty ? '' : parts.first;
}
