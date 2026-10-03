import 'engine.dart';
import 'task.dart';

/// Where a result came from, so a screen can credit it.
class ResultSource {
  final EngineId engine;

  /// The server program that answered, e.g. `morph.cgi`.
  final String program;
  final DateTime time;

  const ResultSource({
    required this.engine,
    required this.program,
    required this.time,
  });

  @override
  bool operator ==(Object other) =>
      other is ResultSource &&
      other.engine == engine &&
      other.program == program &&
      other.time == time;

  @override
  int get hashCode => Object.hash(engine, program, time);

  @override
  String toString() => 'ResultSource(${engine.name}, $program, $time)';
}

/// The answer to one request: a value, or one of five typed failures
/// (ARCHITECTURE.md 8.3). Nothing above the engine layer sees raw server data.
sealed class Outcome<T> {
  const Outcome();
}

class Found<T> extends Outcome<T> {
  final T value;
  final ResultSource source;

  const Found(this.value, this.source);

  @override
  bool operator ==(Object other) =>
      other is Found<T> && other.value == value && other.source == source;

  @override
  int get hashCode => Object.hash(value, source);

  @override
  String toString() => 'Found($value, $source)';
}

/// The engine understood the input and has no answer.
class NotFound<T> extends Outcome<T> {
  const NotFound();

  @override
  bool operator ==(Object other) => other is NotFound<T>;

  @override
  int get hashCode => (NotFound<T>).hashCode;

  @override
  String toString() => 'NotFound';
}

/// The input cannot be processed as given.
class BadInput<T> extends Outcome<T> {
  final String message;

  const BadInput(this.message);

  @override
  bool operator ==(Object other) =>
      other is BadInput<T> && other.message == message;

  @override
  int get hashCode => Object.hash(BadInput, message);

  @override
  String toString() => 'BadInput($message)';
}

/// The engine answered with something unusable.
class ServerFault<T> extends Outcome<T> {
  final String detail;

  const ServerFault(this.detail);

  @override
  bool operator ==(Object other) =>
      other is ServerFault<T> && other.detail == detail;

  @override
  int get hashCode => Object.hash(ServerFault, detail);

  @override
  String toString() => 'ServerFault($detail)';
}

/// Network error or timeout.
class Unreachable<T> extends Outcome<T> {
  final String detail;

  const Unreachable(this.detail);

  @override
  bool operator ==(Object other) =>
      other is Unreachable<T> && other.detail == detail;

  @override
  int get hashCode => Object.hash(Unreachable, detail);

  @override
  String toString() => 'Unreachable($detail)';
}

/// This engine does not do this task.
class Unsupported<T> extends Outcome<T> {
  final EngineId engine;
  final Task task;

  const Unsupported(this.engine, this.task);

  @override
  bool operator ==(Object other) =>
      other is Unsupported<T> && other.engine == engine && other.task == task;

  @override
  int get hashCode => Object.hash(Unsupported, engine, task);

  @override
  String toString() => 'Unsupported(${engine.name}, ${task.name})';
}
