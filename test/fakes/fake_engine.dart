import 'package:mobile_app/domain/domain.dart';

/// An [Engine] that returns canned outcomes, so screen and adapter tests need
/// no network. Like a real engine, a task outside [tasks] gives [Unsupported]
/// at once, whatever was canned for it.
class FakeEngine implements Engine {
  FakeEngine({
    this.id = EngineId.samsaadhanii,
    this.credit = const EngineCredit(
      name: 'Fake engine',
      team: 'Tests',
      url: 'https://example.invalid/',
    ),
    this.tasks = const {Task.analyseWord, Task.splitText},
    this.analysis,
    this.likeliest,
    this.segmentation,
    this.segmentationPlain,
    this.paradigm,
    this.derivation,
    this.verbParadigm,
    this.krt,
    this.sandhi,
    this.dictionary,
    this.latency = Duration.zero,
    this.plainLatency,
  });

  @override
  final EngineId id;

  @override
  final EngineCredit credit;

  @override
  final Set<Task> tasks;

  /// What [analyseWord] returns; `null` means [NotFound].
  final Outcome<WordAnalysis>? analysis;

  /// What [likeliestReading] returns; `null` means [NotFound].
  final Outcome<Analysis>? likeliest;

  /// What [segment] returns with `analyse: true`; `null` means [NotFound].
  final Outcome<Segmentation>? segmentation;

  /// What [segment] returns without `analyse`; defaults to [segmentation].
  final Outcome<Segmentation>? segmentationPlain;

  /// What [declineNoun] returns; `null` means [NotFound].
  final Outcome<NounParadigm>? paradigm;

  /// What [derive] returns; `null` means [NotFound].
  final Outcome<Derivation>? derivation;

  /// What [conjugateVerb] returns; `null` means [NotFound].
  final Outcome<VerbParadigm>? verbParadigm;

  /// What [krtForms] returns; `null` means [NotFound].
  final Outcome<KrtForms>? krt;

  /// What [joinSandhi] returns; `null` means [NotFound].
  final Outcome<SandhiResult>? sandhi;

  /// What [lookUp] returns; `null` means [NotFound].
  final Outcome<List<DictionaryEntry>>? dictionary;

  /// Delay before a supported task answers (Unsupported never waits).
  final Duration latency;

  /// Delay for [segment] without `analyse`, if different from [latency].
  final Duration? plainLatency;

  /// Every call made, for assertions: `analyseWord:rAmaH`, `segment:rAmaH`,
  /// `declineNoun:rAma:masculine:plainNoun`, `derive:rAma:masculine:instrumental:singular`,
  /// `conjugateVerb:gam1_gamLz_BvAxiH_gawO:Af:kartari` (`-` for no prefix),
  /// `krtForms:gam1_gamLz_BvAxiH_gawO:Af`,
  /// `joinSandhi:rAmaH:AlayaH`, `lookUp:vana`, `likeliestReading:rAmaH`.
  final List<String> calls = [];

  Future<T> _after<T>(T value, [Duration? delay]) {
    final d = delay ?? latency;
    return d == Duration.zero ? Future.value(value) : Future.delayed(d, () => value);
  }

  @override
  Future<Outcome<WordAnalysis>> analyseWord(SanskritText word) {
    calls.add('analyseWord:${word.wx}');
    if (!tasks.contains(Task.analyseWord)) {
      return Future.value(Unsupported(id, Task.analyseWord));
    }
    return _after(analysis ?? const NotFound());
  }

  @override
  Future<Outcome<Analysis>> likeliestReading(SanskritText word) {
    calls.add('likeliestReading:${word.wx}');
    if (!tasks.contains(Task.likeliestReading)) {
      return Future.value(Unsupported(id, Task.likeliestReading));
    }
    return _after(likeliest ?? const NotFound());
  }

  @override
  Future<Outcome<Segmentation>> segment(SanskritText text,
      {bool analyse = false}) {
    calls.add('segment:${text.wx}${analyse ? ':analyse' : ''}');
    if (!tasks.contains(Task.splitText)) {
      return Future.value(Unsupported(id, Task.splitText));
    }
    final canned = analyse ? segmentation : (segmentationPlain ?? segmentation);
    return _after(canned ?? const NotFound(),
        analyse ? latency : (plainLatency ?? latency));
  }

  @override
  Future<Outcome<NounParadigm>> declineNoun(NounQuery query) {
    calls.add('declineNoun:${query.stem.wx}:${query.gender.name}:'
        '${query.category.name}');
    if (!tasks.contains(Task.nounForms)) {
      return Future.value(Unsupported(id, Task.nounForms));
    }
    return _after(paradigm ?? const NotFound());
  }

  @override
  Future<Outcome<Derivation>> derive(DerivationQuery query) {
    calls.add('derive:${query.stem.wx}:${query.gender.name}:'
        '${query.vibhakti.name}:${query.number.name}');
    if (!tasks.contains(Task.derivation)) {
      return Future.value(Unsupported(id, Task.derivation));
    }
    return _after(derivation ?? const NotFound());
  }

  @override
  Future<Outcome<VerbParadigm>> conjugateVerb(VerbQuery query) {
    calls.add('conjugateVerb:${query.root}:${query.prefix ?? '-'}:'
        '${query.prayoga.name}');
    if (!tasks.contains(Task.verbForms)) {
      return Future.value(Unsupported(id, Task.verbForms));
    }
    return _after(verbParadigm ?? const NotFound());
  }

  @override
  Future<Outcome<KrtForms>> krtForms(VerbQuery query) {
    calls.add('krtForms:${query.root}:${query.prefix ?? '-'}');
    if (!tasks.contains(Task.krtForms)) {
      return Future.value(Unsupported(id, Task.krtForms));
    }
    return _after(krt ?? const NotFound());
  }

  @override
  Future<Outcome<SandhiResult>> joinSandhi(
      SanskritText left, SanskritText right) {
    calls.add('joinSandhi:${left.wx}:${right.wx}');
    if (!tasks.contains(Task.joinWords)) {
      return Future.value(Unsupported(id, Task.joinWords));
    }
    if (left.isEmpty || right.isEmpty) {
      return Future.value(const BadInput('Enter two words'));
    }
    return _after(sandhi ?? const NotFound());
  }

  @override
  Future<Outcome<List<DictionaryEntry>>> lookUp(SanskritText headword) {
    calls.add('lookUp:${headword.wx}');
    if (!tasks.contains(Task.dictionary)) {
      return Future.value(Unsupported(id, Task.dictionary));
    }
    if (headword.isEmpty) return Future.value(const BadInput('Enter a word'));
    return _after(dictionary ?? const NotFound());
  }
}
