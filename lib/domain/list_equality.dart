/// Element-wise list equality and hash, so the models need no package.
bool listEq<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

int listHash<T>(List<T>? list) => list == null ? 0 : Object.hashAll(list);

/// Equality of two maps whose values are lists.
bool mapOfListsEq<K, V>(Map<K, List<V>> a, Map<K, List<V>> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (!b.containsKey(e.key) || !listEq(b[e.key], e.value)) return false;
  }
  return true;
}

int mapOfListsHash<K, V>(Map<K, List<V>> m) => Object.hashAllUnordered(
    [for (final e in m.entries) Object.hash(e.key, listHash(e.value))]);
