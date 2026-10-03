import '../../domain/domain.dart';

/// The engines the app has, by id. Screens get engines from here (provided
/// by `lib/app`); they never construct or import one (ARCHITECTURE.md 8.2).
class EngineSet {
  const EngineSet(this._engines);

  final Map<EngineId, Engine> _engines;

  Engine? operator [](EngineId id) => _engines[id];

  /// The engines that can answer [task], in `EngineId` order.
  List<EngineId> forTask(Task task) => [
        for (final id in EngineId.values)
          if (_engines[id]?.tasks.contains(task) ?? false) id,
      ];
}
