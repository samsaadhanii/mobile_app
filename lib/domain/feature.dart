/// What a grammatical feature is about. `unknown` is for a feature the
/// adapter could not place; its `Feature.original` keeps what the engine said.
enum FeatureKind {
  gender,
  vibhakti,
  number,
  person,
  lakara,
  pada,
  prayoga,
  gana,

  /// The sanādi suffix that derives a secondary root: causative, desiderative
  /// or intensive.
  sanadi,

  /// Pronoun, numeral, cardinal or ordinal: the category of a nominal word
  /// beyond its gender, case and number.
  nominalCategory,

  /// Open list: the value is free text in [Feature.text] (kṛt suffixes such
  /// as `śatṛ`, `kta`, `tavyat`; later taddhitas).
  krtPratyaya,
  unknown,
}

/// A canonical feature value, with its Sanskrit name (IAST) and an English
/// name for display. [unknown] fits any kind: an unmapped label is kept as
/// `Feature(kind, unknown, original)`, never dropped.
enum FeatureValue {
  // gender
  masculine(FeatureKind.gender, 'puṃliṅgam', 'masculine',
      shortIast: 'puṃ', shortEnglish: 'm.'),
  feminine(FeatureKind.gender, 'strīliṅgam', 'feminine',
      shortIast: 'strī', shortEnglish: 'f.'),
  neuter(FeatureKind.gender, 'napuṃsakaliṅgam', 'neuter',
      shortIast: 'napuṃ', shortEnglish: 'n.'),
  noGender(FeatureKind.gender, 'aliṅgam', 'no gender'),

  // case: the seven vibhaktis and sambodhana
  nominative(FeatureKind.vibhakti, 'prathamā', 'nominative'),
  accusative(FeatureKind.vibhakti, 'dvitīyā', 'accusative'),
  instrumental(FeatureKind.vibhakti, 'tṛtīyā', 'instrumental'),
  dative(FeatureKind.vibhakti, 'caturthī', 'dative'),
  ablative(FeatureKind.vibhakti, 'pañcamī', 'ablative'),
  genitive(FeatureKind.vibhakti, 'ṣaṣṭhī', 'genitive'),
  locative(FeatureKind.vibhakti, 'saptamī', 'locative'),
  vocative(FeatureKind.vibhakti, 'sambodhanam', 'vocative'),

  // number
  singular(FeatureKind.number, 'ekavacanam', 'singular',
      shortIast: 'eka.', shortEnglish: 'sg.'),
  dual(FeatureKind.number, 'dvivacanam', 'dual',
      shortIast: 'dvi.', shortEnglish: 'du.'),
  plural(FeatureKind.number, 'bahuvacanam', 'plural',
      shortIast: 'bahu.', shortEnglish: 'pl.'),

  // person
  third(FeatureKind.person, 'prathamapuruṣaḥ', 'third person',
      shortIast: 'pra.', shortEnglish: '3rd'),
  second(FeatureKind.person, 'madhyamapuruṣaḥ', 'second person',
      shortIast: 'ma.', shortEnglish: '2nd'),
  first(FeatureKind.person, 'uttamapuruṣaḥ', 'first person',
      shortIast: 'u.', shortEnglish: '1st'),

  // lakāra
  lat(FeatureKind.lakara, 'laṭ', 'present'),
  lit(FeatureKind.lakara, 'liṭ', 'perfect'),
  lut(FeatureKind.lakara, 'luṭ', 'periphrastic future'),
  lrt(FeatureKind.lakara, 'lṛṭ', 'simple future'),
  let(FeatureKind.lakara, 'leṭ', 'Vedic subjunctive'),
  lot(FeatureKind.lakara, 'loṭ', 'imperative'),
  lan(FeatureKind.lakara, 'laṅ', 'imperfect'),
  vidhiling(FeatureKind.lakara, 'vidhiliṅ', 'optative'),
  ashirling(FeatureKind.lakara, 'āśīrliṅ', 'benedictive'),
  lun(FeatureKind.lakara, 'luṅ', 'aorist'),
  lrn(FeatureKind.lakara, 'lṛṅ', 'conditional'),

  // pada
  parasmaipada(FeatureKind.pada, 'parasmaipadam', 'parasmaipada'),
  atmanepada(FeatureKind.pada, 'ātmanepadam', 'ātmanepada'),

  // prayoga
  kartari(FeatureKind.prayoga, 'kartari', 'active'),
  karmani(FeatureKind.prayoga, 'karmaṇi', 'passive'),
  bhave(FeatureKind.prayoga, 'bhāve', 'impersonal'),

  // sanādi suffixes
  nic(FeatureKind.sanadi, 'ṇic', 'causative (ṇijanta)'),
  san(FeatureKind.sanadi, 'san', 'desiderative (sannanta)'),
  yan(FeatureKind.sanadi, 'yaṅ', 'intensive (yaṅanta)'),

  // nominal category
  plainNoun(FeatureKind.nominalCategory, 'nāma', 'plain noun'),
  sarvanama(FeatureKind.nominalCategory, 'sarvanāma', 'pronoun'),
  sankhya(FeatureKind.nominalCategory, 'saṅkhyā', 'numeral'),
  sankhyeya(FeatureKind.nominalCategory, 'saṅkhyeya', 'cardinal'),
  purana(FeatureKind.nominalCategory, 'pūraṇa', 'ordinal'),

  // gaṇa
  bhvadi(FeatureKind.gana, 'bhvādiḥ', 'class 1 (bhvādi)'),
  adadi(FeatureKind.gana, 'adādiḥ', 'class 2 (adādi)'),
  juhotyadi(FeatureKind.gana, 'juhotyādiḥ', 'class 3 (juhotyādi)'),
  divadi(FeatureKind.gana, 'divādiḥ', 'class 4 (divādi)'),
  svadi(FeatureKind.gana, 'svādiḥ', 'class 5 (svādi)'),
  tudadi(FeatureKind.gana, 'tudādiḥ', 'class 6 (tudādi)'),
  rudhadi(FeatureKind.gana, 'rudhādiḥ', 'class 7 (rudhādi)'),
  tanadi(FeatureKind.gana, 'tanādiḥ', 'class 8 (tanādi)'),
  kryadi(FeatureKind.gana, 'kryādiḥ', 'class 9 (kryādi)'),
  curadi(FeatureKind.gana, 'curādiḥ', 'class 10 (curādi)'),

  /// The feature's kind is an open list; the value is in `Feature.text`.
  openClass(FeatureKind.unknown, '', 'open-class value'),

  unknown(FeatureKind.unknown, '', 'unknown');

  const FeatureValue(this.kind, this.iast, this.english,
      {this.shortIast, this.shortEnglish});

  final FeatureKind kind;

  /// The Sanskrit name, in IAST.
  final String iast;
  final String english;

  /// A short name for table headings, in each label language (person and
  /// number have one: `pra.` / `3rd`, `eka.` / `sg.`; so do the three genders:
  /// `puṃ` / `m.`); null when the full name is already short. The full name is
  /// used everywhere else.
  final String? shortIast;
  final String? shortEnglish;

  /// The values that belong to [kind], without [unknown].
  static List<FeatureValue> of(FeatureKind kind) =>
      [for (final v in values) if (v.kind == kind) v];
}
