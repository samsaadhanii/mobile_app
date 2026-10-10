import '../../domain/domain.dart';
import 'client_types.dart';
import 'response_cache.dart';

/// Runs one request and turns what happens into an [Outcome]: a client that
/// throws [UnreachableException] is `Unreachable`, any other client error and
/// any status other than 200 is `ServerFault`, and [parse] decides the rest.
/// Makes no network call itself: [fetch] is the engine's client.
///
/// With a [cache], a `Found` answer for the same engine, program and [query]
/// is returned without calling [fetch], and a new `Found` is kept. A request
/// made inside `runFresh` (Retry) skips the lookup and replaces the entry.
Future<Outcome<T>> runRequest<T>({
  required Future<ClientResponse> Function() fetch,
  required EngineId engine,
  required String program,
  required DateTime Function() now,
  required Outcome<T> Function(String body, ResultSource source) parse,
  ResponseCache? cache,
  Map<String, String> query = const {},
}) async {
  final key = ResponseCache.keyFor(engine, program, query);
  if (cache != null && !isFreshRequest) {
    final kept = cache.get<T>(key);
    if (kept != null) return kept;
  }
  final ClientResponse response;
  try {
    response = await fetch();
  } on UnreachableException catch (e) {
    return Unreachable(e.message);
  } catch (e) {
    return ServerFault('unexpected error from the client: $e');
  }
  if (response.statusCode != 200) {
    return ServerFault('HTTP ${response.statusCode} from $program');
  }
  try {
    final outcome = parse(
      response.body,
      ResultSource(engine: engine, program: program, time: now()),
    );
    if (cache != null && outcome is Found<T>) cache.put(key, outcome);
    return outcome;
  } catch (e) {
    return ServerFault('could not read the answer of $program: $e');
  }
}
