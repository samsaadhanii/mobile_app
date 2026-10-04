import '../../domain/domain.dart';
import '../common/input.dart';
import '../common/run_request.dart';
import 'client.dart';
import 'derivation_adapter.dart';
import 'morph_adapter.dart';
import 'noun_adapter.dart';
import 'splitter_adapter.dart';
import 'verb_adapter.dart';

const morphProgram = 'MT/prog/morph/morph.cgi';
const splitterProgram = 'MT/prog/sandhi_splitter/sandhi_splitter.cgi';
const nounProgram = 'skt_gen/noun/noun_gen.cgi';
const derivationProgram = 'ashtadhyayi_simulator/simulation.cgi';
const verbProgram = 'skt_gen/verb/verb_gen.cgi';

/// Samsaadhanii behind the [Engine] interface: word analysis, splitting, noun
/// forms, the derivation of a noun form, and verb forms.
class SamsaadhaniiEngine implements Engine {
  SamsaadhaniiEngine({SamsaadhaniiClient? client, DateTime Function()? now})
      : _client = client ?? HttpSamsaadhaniiClient(),
        _now = now ?? DateTime.now;

  final SamsaadhaniiClient _client;
  final DateTime Function() _now;

  @override
  EngineId get id => EngineId.samsaadhanii;

  @override
  EngineCredit get credit => const EngineCredit(
        name: 'Samsaadhanii',
        team: 'Sanskrit Computational Linguistics, University of Hyderabad',
        url: 'https://sanskrit.uohyd.ac.in/scl/',
      );

  @override
  Set<Task> get tasks => const {
        Task.analyseWord,
        Task.splitText,
        Task.nounForms,
        Task.derivation,
        Task.verbForms,
      };

  /// Reports every `{key:value}` the morph adapter could not map; for tests
  /// and fixture review.
  OnUnmapped? onUnmapped;

  @override
  Future<Outcome<WordAnalysis>> analyseWord(SanskritText word) {
    final cleaned = cleanForServer(word);
    return _run(
      morphProgram,
      {
        'morfword': cleaned,
        'encoding': 'WX',
        'outencoding': 'IAST',
        'mode': 'json',
      },
      (body, source) => parseMorph(body, SanskritText(cleaned), source,
          onUnmapped: onUnmapped),
    );
  }

  /// Splits [text] with the server's sentence mode, which also handles a
  /// single word or compound. With [analyse], each candidate's segments are
  /// analysed (see [analyseWords]); a failed word does not fail the split.
  @override
  Future<Outcome<Segmentation>> segment(SanskritText text,
      {bool analyse = false}) async {
    final cleaned = cleanForServer(text);
    final outcome = await _run(
      splitterProgram,
      {
        'word': cleaned,
        'encoding': 'WX',
        'outencoding': 'I',
        'mode': 'sent',
        'disp_mode': 'json',
      },
      (body, source) => parseSplit(body, SanskritText(cleaned), source),
    );
    if (!analyse || outcome is! Found<Segmentation>) return outcome;

    final seg = outcome.value;
    return Found(
      Segmentation(seg.input, [
        for (final split in seg.candidates)
          Split(split.segments, analyses: await analyseWords(split, outcome.source)),
      ]),
      outcome.source,
    );
  }

  @override
  Future<Outcome<NounParadigm>> declineNoun(NounQuery query) {
    final gen = genderCode(query.gender);
    final jati = categoryCode(query.category);
    if (gen == null || jati == null) {
      return Future.value(BadInput(
          'no gender or category ${query.gender.english}/${query.category.english}'));
    }
    return _run(
      nounProgram,
      {
        'rt': cleanForServer(query.stem),
        'gen': gen,
        'jAwi': jati,
        'level': '1',
        'mode': 'json',
        'encoding': 'WX',
        'outencoding': 'IAST',
      },
      (body, source) => parseNoun(body, query, source),
    );
  }

  /// The derivation is requested with the stem, never the inflected form.
  @override
  Future<Outcome<Derivation>> derive(DerivationQuery query) {
    final gen = genderCode(query.gender);
    final vibhakti = vibhaktiName(query.vibhakti);
    final vacana = vacanaName(query.number);
    if (gen == null || vibhakti == null || vacana == null) {
      return Future.value(const BadInput('not a case, number or gender'));
    }
    return _run(
      derivationProgram,
      {
        'encoding': 'WX',
        'praatipadika': cleanForServer(query.stem),
        'vibhakti': vibhakti,
        'linga': gen,
        'vacana': vacana,
      },
      (body, source) => parseDerivation(body, source),
    );
  }

  /// Active and passive are one call. ṇijanta is two (the server answers one
  /// pada per call), made together and merged.
  @override
  Future<Outcome<VerbParadigm>> conjugateVerb(VerbQuery query) async {
    Future<Outcome<VerbParadigm>> call(String code) => _run(
          verbProgram,
          verbQueryParams(query, code),
          (body, source) => parseVerb(body, query, source),
        );
    return switch (query.prayoga) {
      VerbPrayoga.kartari => call(activeCode),
      VerbPrayoga.karmani => call(passiveCode),
      VerbPrayoga.nijanta => () async {
          final results = await Future.wait([
            call(causativeParasmaipadaCode),
            call(causativeAtmanepadaCode),
          ]);
          return mergeVerb(results[0], results[1]);
        }(),
    };
  }

  /// One outcome per segment of [split], in order. A segment followed by a
  /// compound boundary is not sent to the server (a bare stem would come back
  /// with misleading readings); it is a `compoundMember`. Every other segment
  /// is analysed, and a word the server does not know is `NotFound` in its
  /// slot only.
  Future<List<Outcome<WordAnalysis>>> analyseWords(Split split,
      [ResultSource? splitSource]) {
    final source = splitSource ??
        ResultSource(
          engine: EngineId.samsaadhanii,
          program: splitterProgram.split('/').last,
          time: _now(),
        );
    return Future.wait([
      for (final s in split.segments)
        if (s.after == Boundary.compound)
          Future.value(Found(
            WordAnalysis(s.text, [
              Analysis(lemma: s.text, wordClass: WordClass.compoundMember),
            ]),
            source,
          ) as Outcome<WordAnalysis>)
        else
          analyseWord(s.text),
    ]);
  }

  Future<Outcome<T>> _run<T>(
    String program,
    Map<String, String> query,
    Outcome<T> Function(String body, ResultSource source) parse,
  ) =>
      runRequest(
        fetch: () => _client.get(program, query),
        engine: EngineId.samsaadhanii,
        program: program.split('/').last,
        now: _now,
        parse: parse,
      );
}
