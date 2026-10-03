import '../../domain/domain.dart';

final _danda = RegExp('[।॥]');
final _devanagariDigits = RegExp('[०-९]');
// "12", "1.2.3", "1-2": a number that is not part of a word.
final _verseNumber = RegExp(r'(?<![A-Za-z0-9])\d+(?:[.\-:]\d+)*\.?(?![A-Za-z0-9])');

/// Removes daṇḍa, double daṇḍa and verse numbers, which the servers do not
/// understand (U4b item 2), and tidies the spaces. WX in, WX out.
String cleanForServer(SanskritText text) => text.wx
    .replaceAll(_danda, ' ')
    .replaceAll(_devanagariDigits, ' ')
    .replaceAll(_verseNumber, ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
