import '../sanskrit/transliteration.dart';

/// Sanskrit text held in WX, the app's pivot (ARCHITECTURE.md D4). Only
/// Sanskrit goes through here: labels, counts and English never do.
class SanskritText {
  final String wx;

  const SanskritText(this.wx);

  /// Text typed or received in [script], converted to WX.
  factory SanskritText.from(String text, Script script) =>
      SanskritText(toWx(text, script));

  /// The text in the script the user chose to read.
  String display(Script script) => fromWx(wx, script);

  bool get isEmpty => wx.isEmpty;

  @override
  bool operator ==(Object other) => other is SanskritText && other.wx == wx;

  @override
  int get hashCode => wx.hashCode;

  @override
  String toString() => 'SanskritText($wx)';
}
