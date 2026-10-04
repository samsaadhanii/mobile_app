/// Something the user wants done, whoever does it (ARCHITECTURE.md 8.4).
/// The Tools tab lists these (plus Dhātupāṭha, which is not a task yet).
enum Task {
  analyseWord(
    'Analyse a word',
    'शब्दविश्लेषणम्',
    'Every possible analysis of one Sanskrit word.',
  ),
  splitText(
    'Split and analyse',
    'सन्धिविच्छेदः',
    'Split a sentence or compound into its words, optionally with each '
        'word analysed.',
  ),
  nounForms(
    'Noun forms',
    'नामरूपाणि',
    'The inflected forms of a noun stem.',
  ),
  verbForms(
    'Verb forms',
    'क्रियारूपाणि',
    'The inflected forms of a verbal root, with or without a prefix.',
  ),
  krtForms(
    'Kṛt forms',
    'कृदन्तरूपाणि',
    'The participles and other kṛt derivatives of a verbal root.',
  ),
  joinWords(
    'Join two words',
    'सन्धिः',
    'Join two words following the sandhi rules.',
  ),
  dictionary(
    'Dictionary',
    'शब्दकोशः',
    'Look a headword up in the dictionaries.',
  ),
  derivation(
    'Derivation',
    'प्रक्रिया',
    'How a form is derived, step by step, by the Aṣṭādhyāyī rules.',
  );

  const Task(this.nameEn, this.nameSa, this.description);

  final String nameEn;

  /// Devanagari.
  final String nameSa;
  final String description;
}
