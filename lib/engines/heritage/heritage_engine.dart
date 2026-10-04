import '../../domain/domain.dart';
import 'analysis_adapter.dart';
import '../common/input.dart';
import '../common/run_request.dart';
import 'client.dart';
import 'split_adapter.dart';

/// Heritage's `sktgraph2.cgi` behind the [Engine] interface: word analysis
/// and splitting.
class HeritageEngine implements Engine {
  HeritageEngine({HeritageClient? client, DateTime Function()? now})
      : _client = client ?? HttpHeritageClient(),
        _now = now ?? DateTime.now;

  final HeritageClient _client;
  final DateTime Function() _now;

  @override
  EngineId get id => EngineId.heritage;

  // Placeholder wording: the Heritage team decides it (Heritage Q28).
  @override
  EngineCredit get credit => const EngineCredit(
        name: 'Sanskrit Heritage Platform',
        team: 'Gérard Huet and the Sanskrit Heritage team, Inria',
        url: 'https://sanskrit.inria.fr/',
      );

  @override
  Set<Task> get tasks => const {Task.analyseWord, Task.splitText};

  /// Reports every label the adapter could not map; for tests and review.
  OnUnmapped? onUnmapped;

  /// Heritage answers neither yet; they wait on its team (questions 14 to 19).
  @override
  Future<Outcome<NounParadigm>> declineNoun(NounQuery query) =>
      Future.value(Unsupported(id, Task.nounForms));

  @override
  Future<Outcome<Derivation>> derive(DerivationQuery query) =>
      Future.value(Unsupported(id, Task.derivation));

  @override
  Future<Outcome<VerbParadigm>> conjugateVerb(VerbQuery query) =>
      Future.value(Unsupported(id, Task.verbForms));

  @override
  Future<Outcome<KrtForms>> krtForms(VerbQuery query) =>
      Future.value(Unsupported(id, Task.krtForms));

  @override
  Future<Outcome<SandhiResult>> joinSandhi(
          SanskritText left, SanskritText right) =>
      Future.value(Unsupported(id, Task.joinWords));

  /// Always WX, always the Monier-Williams lexicon (D4; single words accept
  /// only WX).
  Map<String, String> _query(String text, Map<String, String> extra) =>
      {'text': text, 't': 'WX', 'lex': 'MW', ...extra};

  @override
  Future<Outcome<WordAnalysis>> analyseWord(SanskritText word) {
    final cleaned = cleanForServer(word);
    return _run(
      _query(cleaned, {'st': 'f', 'stemmer': 't', 'mode': 'b', 'fmode': 'w'}),
      (body, source) => parseWordAnalysis(body, SanskritText(cleaned), source,
          onUnmapped: onUnmapped),
    );
  }

  /// Up to ten candidates, best first. With [analyse], one call for the best
  /// segmentation with every word's analyses, as one candidate.
  @override
  Future<Outcome<Segmentation>> segment(SanskritText text,
      {bool analyse = false}) {
    final cleaned = cleanForServer(text);
    final extra = analyse
        ? {'st': 't', 'stemmer': 't', 'mode': 'f', 'fmode': 'w'}
        : {'st': 't', 'pipeline': 't', 'mode': 'l', 'fmode': 'w'};
    return _run(
      _query(cleaned, extra),
      (body, source) => parseSplit(body, SanskritText(cleaned), source,
          withAnalyses: analyse, onUnmapped: onUnmapped),
    );
  }

  Future<Outcome<T>> _run<T>(
    Map<String, String> query,
    Outcome<T> Function(String body, ResultSource source) parse,
  ) =>
      runRequest(
        fetch: () => _client.get(query),
        engine: EngineId.heritage,
        program: 'sktgraph2.cgi',
        now: _now,
        parse: parse,
      );
}
