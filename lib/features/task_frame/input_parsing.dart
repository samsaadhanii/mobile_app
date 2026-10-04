import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../../shared/data/word_lists.dart';
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

/// The dhātu keys a root passed to a screen can mean, best first. [input] is
/// either the exact key of a dhātu in the list (another screen hands one over;
/// a key may hold a space, so the whole text is tried first) or a word typed in
/// any script, whose first word is read as Sanskrit. Empty when it is not a
/// dhātu of the list.
List<String> rootKeysFor(
    String input, DhatuList dhatus, AppSettings settings) {
  final whole = input.trim();
  if (whole.isNotEmpty && dhatus.entryFor(whole) != null) return [whole];
  final typed = firstWord(input);
  if (typed.isEmpty) return const [];
  return dhatus.keysFor(parseSanskrit(typed, settings).wx);
}
