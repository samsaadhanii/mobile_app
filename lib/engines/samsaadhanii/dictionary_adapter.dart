import 'dart:convert';

import '../../domain/domain.dart';

/// The dictionary lookup (`dict_help_json.cgi`). Nothing outside this folder
/// knows the server's field names (ARCHITECTURE.md 8.2).

/// The request. **The headword is always sent in Devanagari**, whatever script
/// the user typed it in: with anything else the server answers with broken JSON
/// and a file path (WEBSITE-TOOLS F5, `BUGS.md` #15). The HTTP client encodes
/// the query.
Map<String, String> dictionaryQueryParams(SanskritText headword) =>
    {'word': headword.display(Script.devanagari)};

/// The dictionaries by the name the server gives them.
const _known = {
  "Apte's Skt-Hnd Dict": DictionaryInfo('Apte', DictionaryLanguage.hindi),
  "Monier Williams' Skt-Eng Dict":
      DictionaryInfo('Monier-Williams', DictionaryLanguage.english),
  'Heritage Skt-French Dict':
      DictionaryInfo('Heritage', DictionaryLanguage.french),
  "Cappeller's Skt-Ger Dict":
      DictionaryInfo('Cappeller', DictionaryLanguage.german),
};

const _apte = "Apte's Skt-Hnd Dict";

final _reference = RegExp(r'&(?:#(\d+)|#[xX]([0-9a-fA-F]+)|([A-Za-z]+));');
final _spaces = RegExp(r' {2,}');

const _named = {
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': ' ',
};

/// Decodes the character references the entries carry (`&#257;`, `&#x0935;`,
/// `&#8201;`) and the few named ones. One that is not a character is kept as it
/// was written.
String decodeReferences(String text) => text.replaceAllMapped(_reference, (m) {
      final code = m[1] != null
          ? int.tryParse(m[1]!)
          : m[2] != null
              ? int.tryParse(m[2]!, radix: 16)
              : null;
      if (code != null) {
        return code > 0 && code <= 0x10FFFF && !(code >= 0xD800 && code < 0xE000)
            ? String.fromCharCode(code)
            : m[0]!;
      }
      return _named[m[3]] ?? m[0]!;
    });

/// Reads the entries, in the server's order. An entry with an empty meaning is
/// left out and an answer with none left is `NotFound`. Apte's meaning is cut
/// into lines at its runs of spaces, which mark the senses; every other is one
/// paragraph with its runs of spaces collapsed. Unparseable JSON throws, and the
/// request runner turns it into `ServerFault`.
Outcome<List<DictionaryEntry>> parseDictionary(
    String body, ResultSource source) {
  // The parser's own message quotes the text it choked on, which for the
  // broken answer is a server file path: say only that it is not JSON.
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    throw const FormatException('the dictionary answer is not JSON');
  }
  final items = switch (decoded) {
    List() => decoded,
    Map() => [decoded],
    _ => throw FormatException('expected a list, got $decoded'),
  };

  final entries = <DictionaryEntry>[];
  for (final item in items) {
    if (item is! Map ||
        item['Word'] is! String ||
        item['DICT'] is! String ||
        item['Meaning'] is! String) {
      throw FormatException('unexpected entry $item');
    }
    final server = item['DICT'] as String;
    final meaning = decodeReferences(item['Meaning'] as String);
    final text = server == _apte
        ? [
            for (final p in meaning.split(_spaces))
              if (p.trim().isNotEmpty) p.trim(),
          ].join('\n')
        : meaning.replaceAll(_spaces, ' ').trim();
    if (text.isEmpty) continue;
    entries.add(DictionaryEntry(
      dictionary: _known[server] ?? DictionaryInfo(server, DictionaryLanguage.other),
      headword: SanskritText.from(item['Word'] as String, Script.devanagari),
      body: text,
    ));
  }
  if (entries.isEmpty) return const NotFound();
  return Found(entries, source);
}
