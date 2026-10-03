import 'package:flutter/foundation.dart';

import '../../domain/domain.dart';

/// Runs one request at a time for a task screen: which engine, waiting or the
/// outcome. A late answer from an engine the user has since left is dropped.
class TaskController<T> extends ChangeNotifier {
  TaskController({
    required this.available,
    required EngineId preferred,
    required this.run,
  }) : engine = available.contains(preferred) ? preferred : available.first;

  /// The engines that can answer this task (never empty).
  final List<EngineId> available;

  /// Asks [id] for the answer to the current input.
  final Future<Outcome<T>> Function(EngineId id) run;

  EngineId engine;
  bool waiting = false;
  Outcome<T>? outcome;

  int _generation = 0;
  bool _disposed = false;

  /// The engine the user could switch to, when there is one.
  EngineId? get other {
    for (final id in available) {
      if (id != engine) return id;
    }
    return null;
  }

  Future<void> request() async {
    final mine = ++_generation;
    waiting = true;
    outcome = null;
    notifyListeners();
    Outcome<T> result;
    try {
      result = await run(engine);
    } catch (e) {
      result = ServerFault('unexpected error: $e');
    }
    if (_disposed || mine != _generation) return;
    waiting = false;
    outcome = result;
    notifyListeners();
  }

  Future<void> switchTo(EngineId id) {
    if (id == engine) return Future.value();
    engine = id;
    return request();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
