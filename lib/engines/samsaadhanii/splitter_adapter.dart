import 'dart:convert';

import '../../domain/domain.dart';

/// Parses `sandhi_splitter.cgi` answers (`disp_mode=json`, `outencoding=I`)
/// into a [Segmentation].
Outcome<Segmentation> parseSplit(
    String body, SanskritText input, ResultSource source) {
  final text = body.trim();
  // The server answers an empty input with this plain text.
  if (text == 'No Output Found') return const NotFound();

  Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    return const ServerFault('splitter: the answer is not JSON');
  }
  if (decoded is! Map || decoded.isEmpty) {
    return const ServerFault('splitter: empty or unexpected answer');
  }
  final raw = decoded['segmentation'];
  if (raw is! List || raw.isEmpty || raw.any((e) => e is! String)) {
    return const ServerFault('splitter: no segmentation list');
  }

  // A candidate starting with "?" is the server's "no split found" (it echoes
  // the input after the question mark).
  final candidates = [
    for (final s in raw.cast<String>())
      if (!s.trim().startsWith('?') && s.trim().isNotEmpty) _split(s.trim()),
  ];
  if (candidates.isEmpty) return const NotFound();
  return Found(Segmentation(input, candidates), source);
}

/// "rāmaḥ vanam gacchati" or "rāma-ālayaḥ": spaces end a word, hyphens a
/// compound member.
Split _split(String line) {
  final segments = <Segment>[];
  final words = line.split(RegExp(r'\s+'));
  for (var w = 0; w < words.length; w++) {
    final parts = words[w].split('-').where((p) => p.isNotEmpty).toList();
    for (var p = 0; p < parts.length; p++) {
      final lastOfWord = p == parts.length - 1;
      final lastOfAll = lastOfWord && w == words.length - 1;
      segments.add(Segment(
        SanskritText.from(parts[p], Script.iast),
        lastOfAll
            ? Boundary.end
            : lastOfWord
                ? Boundary.word
                : Boundary.compound,
      ));
    }
  }
  return Split(segments);
}
