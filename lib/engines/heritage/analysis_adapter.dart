import 'dart:convert';

import '../../domain/domain.dart';
import 'labels.dart';

/// Parses `sktgraph2.cgi` answers into the app's models. Nothing outside this
/// folder knows the server's field names (ARCHITECTURE.md 8.2).

/// Called for every label that could not be mapped, as written.
typedef OnUnmapped = void Function(String label);

final _homonym = RegExp(r'^(.*)#(\d+)$');

/// The decoded answer: the `segmentation` strings and the flat `morph` list.
class HeritageAnswer {
  final List<String> segmentation;
  final List<Map<String, Object?>> morph;

  const HeritageAnswer(this.segmentation, this.morph);
}

/// Decodes the JSON, or returns the failure to give. `error:` in the
/// segmentation is `BadInput` (message kept); anything unreadable is
/// `ServerFault`.
({HeritageAnswer? answer, Outcome<T>? failure}) decodeAnswer<T>(String body) {
  Object? decoded;
  try {
    decoded = jsonDecode(body.trim());
  } on FormatException {
    return (answer: null, failure: ServerFault<T>('heritage: the answer is not JSON'));
  }
  if (decoded is! Map) {
    return (answer: null, failure: ServerFault<T>('heritage: unexpected answer'));
  }
  final seg = decoded['segmentation'];
  if (seg is! List || seg.isEmpty || seg.any((e) => e is! String)) {
    return (answer: null, failure: ServerFault<T>('heritage: no segmentation list'));
  }
  final segmentation = seg.cast<String>();
  if (segmentation.first.startsWith('error:')) {
    return (
      answer: null,
      failure: BadInput<T>(segmentation.first.substring('error:'.length).trim()),
    );
  }
  final rawMorph = decoded['morph'];
  final morph = <Map<String, Object?>>[];
  if (rawMorph is List) {
    for (final m in rawMorph) {
      if (m is! Map || m['word'] is! String || m['inflectional_morphs'] is! List) {
        return (answer: null, failure: ServerFault<T>('heritage: a morph entry is malformed'));
      }
      morph.add(m.cast<String, Object?>());
    }
  }
  return (answer: HeritageAnswer(segmentation, morph), failure: null);
}

/// Word analysis (`st=f`): all analyses of [input], in the server's order.
Outcome<WordAnalysis> parseWordAnalysis(
  String body,
  SanskritText input,
  ResultSource source, {
  OnUnmapped? onUnmapped,
}) {
  final decoded = decodeAnswer<WordAnalysis>(body);
  if (decoded.failure != null) return decoded.failure!;
  final answer = decoded.answer!;
  if (answer.segmentation.first.startsWith('?')) return const NotFound();
  final analyses = analysesOf(answer.morph, onUnmapped);
  if (analyses.isEmpty) {
    return answer.morph.isEmpty
        ? const ServerFault('heritage: no morph list')
        : const NotFound();
  }
  return Found(WordAnalysis(input, analyses), source);
}

/// One [Analysis] per entry of each `inflectional_morphs` list. An entry
/// that is only `?` is skipped (the server's "unknown word").
List<Analysis> analysesOf(List<Map<String, Object?>> morph, OnUnmapped? onUnmapped) {
  final out = <Analysis>[];
  for (final m in morph) {
    for (final label in (m['inflectional_morphs'] as List).cast<Object?>()) {
      final text = '$label'.trim();
      if (text == '?') continue;
      out.add(_analysis(m, text, onUnmapped));
    }
  }
  return out;
}

const _participleLabels = {'ppr.', 'pp.', 'pfu.', 'pfp.', 'ppa.', 'ppft.'};

Analysis _analysis(Map<String, Object?> m, String label, OnUnmapped? onUnmapped) {
  final stem = (m['derived_stem'] as String? ?? '').trim();
  final hm = _homonym.firstMatch(stem);
  final lemma = SanskritText(hm == null ? stem : hm[1]!);
  final homonym = hm == null ? null : int.parse(hm[2]!);

  final parsed = parseLabels(label);
  for (final u in parsed.unmapped) {
    onUnmapped?.call(u);
  }

  final derivation = (m['derivational_morph'] as String? ?? '').trim();
  final base = (m['base'] as String? ?? '').trim();
  var wordClass = parsed.wordClass;
  if (base.isNotEmpty &&
      derivation.split(RegExp(r'\s+')).any(_participleLabels.contains) &&
      wordClass != WordClass.indeclinable &&
      wordClass != WordClass.compoundMember) {
    wordClass = WordClass.participle;
  }
  final baseStem = _homonym.firstMatch(base)?[1] ?? base;

  return Analysis(
    lemma: lemma,
    homonym: homonym,
    wordClass: wordClass,
    features: parsed.features,
    base: baseStem.isEmpty ? null : SanskritText(baseStem),
    derivation: derivation.isEmpty ? null : derivation,
  );
}
