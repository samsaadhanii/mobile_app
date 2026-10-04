import 'list_equality.dart';
import 'sanskrit_text.dart';

/// One rule of a sandhi: its text, and its number when the engine gives one,
/// as the bracket at the end of the text had it (`8.2.66`, or `vā 3640` for a
/// vārttika). A name with no bracket has no number.
class SandhiSutra {
  final SanskritText text;
  final String? number;

  const SandhiSutra(this.text, [this.number]);

  @override
  bool operator ==(Object other) =>
      other is SandhiSutra && other.text == text && other.number == number;

  @override
  int get hashCode => Object.hash(text, number);

  @override
  String toString() => 'SandhiSutra(${text.wx}${number == null ? '' : ' ($number)'})';
}

/// One way two words can join.
class SandhiOption {
  /// The joined form. A space in it is real: after a lopa the two words can
  /// stay apart (`rāma ālayaḥ`).
  final SanskritText joined;

  /// The left word's last letter, the right word's first letter, and what they
  /// became (one or more letters: `ḥ + ā → ā`, `n + ś → ñch`).
  final SanskritText lastLetter;
  final SanskritText firstLetter;
  final SanskritText modifiedLetter;

  /// Each word spelt out, one entry per letter (`bh` is one letter).
  final List<SanskritText> leftLetters;
  final List<SanskritText> rightLetters;

  /// The sandhi's name as a list of steps (`rutva`, `yatva`, `lopa`).
  final List<SanskritText> steps;

  /// The rules applied, in order.
  final List<SandhiSutra> sutras;

  const SandhiOption({
    required this.joined,
    required this.lastLetter,
    required this.firstLetter,
    required this.modifiedLetter,
    this.leftLetters = const [],
    this.rightLetters = const [],
    this.steps = const [],
    this.sutras = const [],
  });

  @override
  bool operator ==(Object other) =>
      other is SandhiOption &&
      other.joined == joined &&
      other.lastLetter == lastLetter &&
      other.firstLetter == firstLetter &&
      other.modifiedLetter == modifiedLetter &&
      listEq(other.leftLetters, leftLetters) &&
      listEq(other.rightLetters, rightLetters) &&
      listEq(other.steps, steps) &&
      listEq(other.sutras, sutras);

  @override
  int get hashCode => Object.hash(joined, lastLetter, firstLetter,
      modifiedLetter, listHash(leftLetters), listHash(rightLetters),
      listHash(steps), listHash(sutras));

  @override
  String toString() => 'SandhiOption(${joined.wx})';
}

/// The ways to join two words, in the engine's order.
class SandhiResult {
  final SanskritText left;
  final SanskritText right;
  final List<SandhiOption> options;

  const SandhiResult(this.left, this.right, this.options);

  @override
  bool operator ==(Object other) =>
      other is SandhiResult &&
      other.left == left &&
      other.right == right &&
      listEq(other.options, options);

  @override
  int get hashCode => Object.hash(left, right, listHash(options));

  @override
  String toString() => 'SandhiResult(${left.wx} + ${right.wx}, ${options.length} options)';
}
