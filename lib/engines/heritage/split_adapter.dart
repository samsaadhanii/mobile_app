import '../../domain/domain.dart';
import 'analysis_adapter.dart';

/// Splitting (`st=t`): up to ten candidates, best first as given. With
/// `stemmer=t&mode=f` the answer also has the `morph` list for the best
/// segmentation, which [parseSplit] groups into one outcome per segment.
Outcome<Segmentation> parseSplit(
  String body,
  SanskritText input,
  ResultSource source, {
  bool withAnalyses = false,
  OnUnmapped? onUnmapped,
}) {
  final decoded = decodeAnswer<Segmentation>(body);
  if (decoded.failure != null) return decoded.failure!;
  final answer = decoded.answer!;

  // A candidate starting with "?" is "no split found".
  final lines = [
    for (final s in answer.segmentation)
      if (!s.trim().startsWith('?') && s.trim().isNotEmpty) s.trim(),
  ];
  if (lines.isEmpty) return const NotFound();

  final candidates = <Split>[];
  for (var i = 0; i < lines.length; i++) {
    final segments = _segments(lines[i]);
    // The morph list belongs to the best (first) segmentation only.
    candidates.add(withAnalyses && i == 0
        ? Split(segments,
            analyses: groupAnalyses(segments, answer.morph, source, onUnmapped))
        : Split(segments));
  }
  return Found(Segmentation(input, candidates), source);
}

/// "rAmaH vanam gacCawi" or "rAma-AlayaH": spaces end a word, hyphens a
/// compound member. Heritage is already WX.
List<Segment> _segments(String line) {
  final segments = <Segment>[];
  final words = line.split(RegExp(r'\s+'));
  for (var w = 0; w < words.length; w++) {
    final parts = words[w].split('-').where((p) => p.isNotEmpty).toList();
    for (var p = 0; p < parts.length; p++) {
      final lastOfWord = p == parts.length - 1;
      final lastOfAll = lastOfWord && w == words.length - 1;
      segments.add(Segment(
        SanskritText(parts[p]),
        lastOfAll
            ? Boundary.end
            : lastOfWord
                ? Boundary.word
                : Boundary.compound,
      ));
    }
  }
  return segments;
}

/// Heritage's `morph` list is flat and keyed by `word` (`rAma-` for a
/// compound member), in segment order. Entries are matched to segments by
/// that key. When the same word stands in several neighbouring segments
/// (`rAmaH rAmaH`) its entries are repeated once per occurrence, so a run of
/// entries is shared out evenly between them; if it does not divide evenly,
/// each occurrence gets the whole run. A segment with no entries, or only `?`,
/// is `NotFound` in its slot.
List<Outcome<WordAnalysis>> groupAnalyses(
  List<Segment> segments,
  List<Map<String, Object?>> morph,
  ResultSource source,
  OnUnmapped? onUnmapped,
) {
  String keyOf(Segment s) =>
      s.after == Boundary.compound ? '${s.text.wx}-' : s.text.wx;

  final slots = <Outcome<WordAnalysis>>[];
  var m = 0;
  var s = 0;
  while (s < segments.length) {
    final key = keyOf(segments[s]);
    var occurrences = 1;
    while (s + occurrences < segments.length &&
        keyOf(segments[s + occurrences]) == key) {
      occurrences++;
    }
    var end = m;
    while (end < morph.length && morph[end]['word'] == key) {
      end++;
    }
    final run = morph.sublist(m, end);
    final share = occurrences > 1 && run.length % occurrences == 0
        ? run.length ~/ occurrences
        : run.length;
    for (var k = 0; k < occurrences; k++) {
      final mine = share == run.length ? run : run.sublist(k * share, (k + 1) * share);
      final analyses = analysesOf(mine, onUnmapped);
      final seg = segments[s + k];
      slots.add(analyses.isEmpty
          ? const NotFound()
          : Found(WordAnalysis(seg.text, analyses), source));
    }
    m = end;
    s += occurrences;
  }
  return slots;
}
