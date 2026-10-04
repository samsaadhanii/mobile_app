import 'dart:convert';

import '../../domain/domain.dart';

/// The sandhi joiner (`sandhi_json.cgi`, `outencoding=IAST`). Nothing outside
/// this folder knows the server's field names (ARCHITECTURE.md 8.2).

/// The request: both words in WX.
Map<String, String> sandhiQueryParams(String left, String right) => {
      'word1': left,
      'word2': right,
      'encoding': 'WX',
      'outencoding': 'IAST',
    };

final _arrow = RegExp(r'\s*->\s*');
final _spaces = RegExp(r'\s+');

// A sūtra's number: the bracket at the end, `(8.2.66)` or `(vā 3640)`.
final _number = RegExp(r'^(.*?)\s*\(([^()]*)\)\s*$');

/// Trims and collapses runs of spaces to one. A space inside is real and is
/// kept as one.
String _tidy(String s) => s.trim().replaceAll(_spaces, ' ');

SanskritText _iast(String s) => SanskritText.from(_tidy(s), Script.iast);

String _string(Map item, String key) {
  final v = item[key];
  if (v is! String) throw FormatException('"$key" is missing in $item');
  return v;
}

/// The server sometimes fills `sUwram` with a copy of `sanXiH` (WEBSITE-TOOLS
/// F15): no number on any entry and the same names as the steps. That is not a
/// list of sūtras, and showing it as one would put step names where rules
/// belong. Where the counts differ, or any entry has a number, the lists are
/// kept as given and not paired.
bool _copyOfSteps(List<SandhiSutra> sutras, List<SanskritText> steps) {
  if (sutras.isEmpty || sutras.length != steps.length) return false;
  for (var i = 0; i < sutras.length; i++) {
    if (sutras[i].number != null || sutras[i].text != steps[i]) return false;
  }
  return true;
}

/// Reads the options. `sanXiH` and `sUwram` are lists joined by `->` (the
/// spaces around it vary); the sūtra's number is the bracket at its end; the
/// spelt-out words are split on spaces. A sūtra list that only repeats the steps
/// is empty (see [_copyOfSteps]). An option whose joined form is empty is
/// dropped, and an answer with none left is `NotFound`. The program applies
/// its letter rules to whatever it is given, so a nonsense word still gets an
/// answer: that is not detected here.
Outcome<SandhiResult> parseSandhi(
    String body, SanskritText left, SanskritText right, ResultSource source) {
  final decoded = jsonDecode(body);
  final items = switch (decoded) {
    List() => decoded,
    Map() => [decoded],
    _ => throw FormatException('expected a list, got $decoded'),
  };

  final options = <SandhiOption>[];
  for (final item in items) {
    if (item is! Map) throw FormatException('unexpected entry $item');
    final joined = _tidy(_string(item, 'saMhiwapaxam'));
    if (joined.isEmpty) continue;

    List<String> parts(String key) => [
          for (final p in _string(item, key).split(_arrow))
            if (_tidy(p).isNotEmpty) _tidy(p),
        ];
    List<SanskritText> letters(String key) => [
          for (final l in _tidy(_string(item, key)).split(' '))
            if (l.isNotEmpty) _iast(l),
        ];

    final steps = [for (final s in parts('sanXiH')) _iast(s)];
    final sutras = [
      for (final s in parts('sUwram'))
        switch (_number.firstMatch(s)) {
          final m? => SandhiSutra(_iast(m.group(1)!), m.group(2)!.trim()),
          null => SandhiSutra(_iast(s)),
        },
    ];

    options.add(SandhiOption(
      joined: _iast(joined),
      lastLetter: _iast(_string(item, 'last_letter')),
      firstLetter: _iast(_string(item, 'first_letter')),
      modifiedLetter: _iast(_string(item, 'modified_letter')),
      leftLetters: letters('spelling_word1'),
      rightLetters: letters('spelling_word2'),
      steps: steps,
      sutras: _copyOfSteps(sutras, steps) ? const [] : sutras,
    ));
  }
  if (options.isEmpty) return const NotFound();
  return Found(SandhiResult(left, right, options), source);
}
