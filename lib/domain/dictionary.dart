import 'list_equality.dart';
import 'sanskrit_text.dart';

/// The language a dictionary's definitions are written in.
enum DictionaryLanguage {
  hindi('Hindi'),
  english('English'),
  french('French'),
  german('German'),

  /// A dictionary the app does not know yet.
  other('');

  const DictionaryLanguage(this.label);

  final String label;
}

/// A dictionary the engine looks a headword up in: its name and the language
/// of its definitions.
class DictionaryInfo {
  final String name;
  final DictionaryLanguage language;

  const DictionaryInfo(this.name, this.language);

  @override
  bool operator ==(Object other) =>
      other is DictionaryInfo && other.name == name && other.language == language;

  @override
  int get hashCode => Object.hash(name, language);

  @override
  String toString() => 'DictionaryInfo($name, ${language.name})';
}

/// The four dictionaries Samsaadhanii looks in, in its order. A screen can say
/// which of them had no entry for a word.
const standardDictionaries = [
  DictionaryInfo('Apte', DictionaryLanguage.hindi),
  DictionaryInfo('Monier-Williams', DictionaryLanguage.english),
  DictionaryInfo('Heritage', DictionaryLanguage.french),
  DictionaryInfo('Cappeller', DictionaryLanguage.german),
];

/// One dictionary's entry for a headword. The [body] is **not**
/// [SanskritText]: it is prose in another language with Sanskrit inside it,
/// and it is shown as given. Apte's senses are on separate lines (`\n`); the
/// others are one paragraph.
class DictionaryEntry {
  final DictionaryInfo dictionary;
  final SanskritText headword;
  final String body;

  const DictionaryEntry({
    required this.dictionary,
    required this.headword,
    required this.body,
  });

  /// The body's lines (Apte's senses, or the one paragraph).
  List<String> get paragraphs => [
        for (final p in body.split('\n'))
          if (p.isNotEmpty) p,
      ];

  @override
  bool operator ==(Object other) =>
      other is DictionaryEntry &&
      other.dictionary == dictionary &&
      other.headword == headword &&
      other.body == body;

  @override
  int get hashCode => Object.hash(dictionary, headword, body);

  @override
  String toString() => 'DictionaryEntry(${dictionary.name}, ${headword.wx}, '
      '${body.length} chars)';
}

/// Which of the [standardDictionaries] have no entry among [entries].
List<DictionaryInfo> missingDictionaries(List<DictionaryEntry> entries) => [
      for (final d in standardDictionaries)
        if (!entries.any((e) => e.dictionary.name == d.name)) d,
    ];

/// Entry-list equality for tests and `Found`.
bool sameEntries(List<DictionaryEntry> a, List<DictionaryEntry> b) =>
    listEq(a, b);
