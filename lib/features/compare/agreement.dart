import '../../domain/domain.dart';

/// The Compare agreement rule (U9 item 3, revised 4 Oct 2026). Plain Dart.
///
/// Two analyses agree when their lemmas are the same and they agree on every
/// feature kind **both** report. A kind only one engine gives (a gaṇa, a
/// present class, a pronoun marker) is shown but is not a difference. A
/// feature whose value is unknown (an unmapped label) cannot be compared and
/// is left out. Word class and homonym number are not part of the rule.
bool analysesAgree(Analysis a, Analysis b) {
  if (a.lemma != b.lemma) return false;
  final left = _byKind(a);
  final right = _byKind(b);
  for (final kind in left.keys) {
    final other = right[kind];
    if (other != null && !_sameValues(left[kind]!, other)) return false;
  }
  return true;
}

/// The comparable values of each kind, as strings so an open-class value
/// (a kṛt suffix, held as text) compares by its text.
Map<FeatureKind, Set<String>> _byKind(Analysis a) {
  final out = <FeatureKind, Set<String>>{};
  for (final f in a.features) {
    if (f.kind == FeatureKind.unknown || f.value == FeatureValue.unknown) continue;
    final value = f.value == FeatureValue.openClass
        ? 'text:${f.text?.wx ?? f.original}'
        : f.value.name;
    out.putIfAbsent(f.kind, () => {}).add(value);
  }
  return out;
}

bool _sameValues(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);

/// The result of comparing two lists of analyses.
class AnalysisComparison {
  /// Every analysis on each side has an agreeing analysis on the other.
  final bool agree;

  /// Indexes of the analyses with no agreeing partner on the other side.
  final Set<int> leftUnmatched;
  final Set<int> rightUnmatched;

  const AnalysisComparison(this.agree, this.leftUnmatched, this.rightUnmatched);
}

AnalysisComparison compareAnalyses(List<Analysis> left, List<Analysis> right) {
  final l = {
    for (var i = 0; i < left.length; i++)
      if (!right.any((r) => analysesAgree(left[i], r))) i,
  };
  final r = {
    for (var j = 0; j < right.length; j++)
      if (!left.any((x) => analysesAgree(x, right[j]))) j,
  };
  return AnalysisComparison(l.isEmpty && r.isEmpty, l, r);
}

/// Two best splits agree when they cut the text the same way and, if both
/// carry analyses, every word's analyses agree (a word neither engine could
/// analyse counts as agreeing).
bool splitsAgree(Split a, Split b) {
  if (a.segments.length != b.segments.length) return false;
  for (var i = 0; i < a.segments.length; i++) {
    if (a.segments[i] != b.segments[i]) return false;
  }
  final x = a.analyses, y = b.analyses;
  if (x == null || y == null) return true;
  if (x.length != y.length) return false;
  for (var i = 0; i < x.length; i++) {
    final s = x[i], t = y[i];
    if (s is Found<WordAnalysis> && t is Found<WordAnalysis>) {
      if (!compareAnalyses(s.value.analyses, t.value.analyses).agree) return false;
    } else if ((s is Found<WordAnalysis>) != (t is Found<WordAnalysis>)) {
      return false;
    }
  }
  return true;
}
