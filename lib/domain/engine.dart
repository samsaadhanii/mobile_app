import 'derivation.dart';
import 'dictionary.dart';
import 'krt_forms.dart';
import 'noun_forms.dart';
import 'outcome.dart';
import 'sanskrit_text.dart';
import 'sandhi.dart';
import 'segmentation.dart';
import 'task.dart';
import 'verb_forms.dart';
import 'word_analysis.dart';

enum EngineId { samsaadhanii, heritage }

/// Who made an engine, shown under every result it gives.
class EngineCredit {
  final String name;
  final String team;
  final String url;

  const EngineCredit({
    required this.name,
    required this.team,
    required this.url,
  });

  @override
  bool operator ==(Object other) =>
      other is EngineCredit &&
      other.name == name &&
      other.team == team &&
      other.url == url;

  @override
  int get hashCode => Object.hash(name, team, url);

  @override
  String toString() => 'EngineCredit($name, $team, $url)';
}

/// What the app asks of a Sanskrit engine (ARCHITECTURE.md 8.3).
///
/// A method for a task that is not in [tasks] returns [Unsupported] at once,
/// without a network call. Every task of the first release has its method.
abstract interface class Engine {
  EngineId get id;

  EngineCredit get credit;

  /// What this engine can answer today.
  Set<Task> get tasks;

  Future<Outcome<WordAnalysis>> analyseWord(SanskritText word);

  /// The analyses of [word] that the engine's frequency data says are the
  /// most likely, in the engine's order: a set, since the data picks a stem
  /// (sometimes two), not one case or gender. [NotFound] when there are none.
  Future<Outcome<List<Analysis>>> likeliestReading(SanskritText word);

  Future<Outcome<Segmentation>> segment(SanskritText text,
      {bool analyse = false});

  Future<Outcome<NounParadigm>> declineNoun(NounQuery query);

  Future<Outcome<Derivation>> derive(DerivationQuery query);

  Future<Outcome<VerbParadigm>> conjugateVerb(VerbQuery query);

  /// The kṛt forms of a root; the voice of [query] is ignored.
  Future<Outcome<KrtForms>> krtForms(VerbQuery query);

  /// The ways to join two words. An empty word is `BadInput`, before any
  /// request.
  Future<Outcome<SandhiResult>> joinSandhi(SanskritText left, SanskritText right);

  /// The entries for a headword, one per dictionary that has one, in the
  /// engine's order. An empty headword is `BadInput`, before any request.
  Future<Outcome<List<DictionaryEntry>>> lookUp(SanskritText headword);
}
