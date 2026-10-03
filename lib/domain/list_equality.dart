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
