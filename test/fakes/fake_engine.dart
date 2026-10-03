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
    this.segmentation,
    this.segmentationPlain,
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

  /// What [segment] returns with `analyse: true`; `null` means [NotFound].
  final Outcome<Segmentation>? segmentation;

  /// What [segment] returns without `analyse`; defaults to [segmentation].
  final Outcome<Segmentation>? segmentationPlain;

  /// Delay before a supported task answers (Unsupported never waits).
  final Duration latency;

  /// Delay for [segment] without `analyse`, if different from [latency].
  final Duration? plainLatency;

  /// Every call made, for assertions: `analyseWord:rAmaH`, `segment:rAmaH`.
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
}
