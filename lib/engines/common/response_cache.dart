import '../../domain/domain.dart';

/// The `Found` answers of this session, least recently used dropped first.
/// Not saved to the phone, so a new launch asks again. What is kept is the
/// domain object, so a change of display script or label language redraws
/// from it without a request.
///
/// Sits above the clients (only `client.dart` talks to the network): the
/// engines ask it in [runRequest] before they fetch. Failures and `NotFound`
/// are never kept.
class ResponseCache {
  ResponseCache({this.capacity = 60});

  final int capacity;

  // Insertion order is recency order: the first key is the oldest.
  final _entries = <String, Found<Object?>>{};

  int get length => _entries.length;

  /// The key of one request: the engine, the program and every query field,
  /// in a fixed order.
  static String keyFor(
      EngineId engine, String program, Map<String, String> query) {
    final fields = query.keys.toList()..sort();
    return '${engine.name}|$program|'
        '${fields.map((k) => '$k=${query[k]}').join('&')}';
  }

  Found<T>? get<T>(String key) {
    final hit = _entries.remove(key);
    if (hit is! Found<T>) return null;
    _entries[key] = hit; // now the most recently used
    return hit;
  }

  void put(String key, Found<Object?> found) {
    _entries.remove(key);
    _entries[key] = found;
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }
}
