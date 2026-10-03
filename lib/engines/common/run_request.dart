import '../../domain/domain.dart';
import 'client_types.dart';

/// Runs one request and turns what happens into an [Outcome]: a client that
/// throws [UnreachableException] is `Unreachable`, any other client error and
/// any status other than 200 is `ServerFault`, and [parse] decides the rest.
/// Makes no network call itself: [fetch] is the engine's client.
Future<Outcome<T>> runRequest<T>({
  required Future<ClientResponse> Function() fetch,
  required EngineId engine,
  required String program,
  required DateTime Function() now,
  required Outcome<T> Function(String body, ResultSource source) parse,
}) async {
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
    return parse(
      response.body,
      ResultSource(engine: engine, program: program, time: now()),
    );
  } catch (e) {
    return ServerFault('could not read the answer of $program: $e');
  }
}
