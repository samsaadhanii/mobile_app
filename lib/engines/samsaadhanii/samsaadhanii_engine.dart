import '../../domain/domain.dart';
import 'client.dart';
import 'input.dart';
import 'morph_adapter.dart';
import 'splitter_adapter.dart';

const morphProgram = 'MT/prog/morph/morph.cgi';
const splitterProgram = 'MT/prog/sandhi_splitter/sandhi_splitter.cgi';

/// Samsaadhanii behind the [Engine] interface: word analysis and splitting.
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
  Set<Task> get tasks => const {Task.analyseWord, Task.splitText};

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
  /// single word or compound.
  ///
  /// [analyse] is not honoured yet: `Split.analyses` is a flat
  /// `List<Analysis>`, which cannot hold "one outcome per word, some of them
  /// NotFound" (U6 step 4). The splits come back with `analyses: null` until
  /// the domain type is decided; see the U6 report. [analyseWords] does the
  /// per-word calls.
  @override
  Future<Outcome<Segmentation>> segment(SanskritText text,
      {bool analyse = false}) {
    final cleaned = cleanForServer(text);
    return _run(
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
  }

  /// Analyses each segment of [split] separately; a word the server does not
  /// know is a `NotFound` entry, it does not fail the others.
  Future<List<Outcome<WordAnalysis>>> analyseWords(Split split) =>
      Future.wait([for (final s in split.segments) analyseWord(s.text)]);

  Future<Outcome<T>> _run<T>(
    String program,
    Map<String, String> query,
    Outcome<T> Function(String body, ResultSource source) parse,
  ) async {
    final ClientResponse response;
    try {
      response = await _client.get(program, query);
    } on UnreachableException catch (e) {
      return Unreachable(e.message);
    } catch (e) {
      return ServerFault('unexpected error from the client: $e');
    }
    if (response.statusCode != 200) {
      return ServerFault('HTTP ${response.statusCode} from $program');
    }
    try {
      return parse(
        response.body,
        ResultSource(
          engine: EngineId.samsaadhanii,
          program: program.split('/').last,
          time: _now(),
        ),
      );
    } catch (e) {
      return ServerFault('could not read the answer of $program: $e');
    }
  }
}
