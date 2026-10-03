// Saves the live Heritage server's raw answers under test/fixtures/heritage/,
// for the engine tests (which never call the network). The requests are made
// by the engine itself through a recording client, so they are exactly what
// the app sends; the Devanagari one is made by hand, with t=DN, to keep the
// error answer.
//
// Run from the repository root:
//   dart run tool/capture_heritage_fixtures.dart

import 'dart:io';

import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/engines/heritage/client.dart';
import 'package:mobile_app/engines/heritage/heritage_engine.dart';

const analysisWords = [
  'rAmaH', 'vanam', 'gacCawi', 'xyzq', 'kqwam', 'agacCaw', //
  'aham', 'wvam', 'gamyawe', 'gamayawi',
];
const splitWords = ['rAmAlayaH', 'rAmovanafgacCawi', 'xyzq'];
const analysedSplits = ['rAmAlayaH', 'rAmovanafgacCawi', 'rAmaH rAmaH', 'xyzq'];

final dir = Directory('test/fixtures/heritage');

/// Writes each answer under the name set before the call.
class RecordingClient implements HeritageClient {
  RecordingClient(this._inner);

  final HeritageClient _inner;
  String name = '';

  @override
  Future<ClientResponse> get(Map<String, String> query) async {
    final r = await _inner.get(query);
    if (r.statusCode != 200) {
      stderr.writeln('$name: HTTP ${r.statusCode}');
      exit(1);
    }
    File('${dir.path}/$name.json').writeAsStringSync(r.body);
    stdout.writeln('saved $name.json (${r.body.length} chars)');
    return r;
  }
}

String _slug(String w) => w.replaceAll(' ', '_');

Future<void> main() async {
  dir.createSync(recursive: true);
  final inner = HttpHeritageClient();
  final recorder = RecordingClient(inner);
  final engine = HeritageEngine(client: recorder);

  for (final w in analysisWords) {
    recorder.name = 'analysis_${_slug(w)}';
    await engine.analyseWord(SanskritText(w));
  }
  for (final w in splitWords) {
    recorder.name = 'split_${_slug(w)}';
    await engine.segment(SanskritText(w));
  }
  for (final w in analysedSplits) {
    recorder.name = 'split_analyse_${_slug(w)}';
    await engine.segment(SanskritText(w), analyse: true);
  }
  recorder.name = 'analysis_empty';
  await engine.analyseWord(const SanskritText(''));

  // Devanagari with t=DN: Heritage answers "Unknown transliteration scheme".
  recorder.name = 'error_devanagari';
  await recorder.get({
    'text': 'रामः',
    't': 'DN',
    'lex': 'MW',
    'st': 'f',
    'stemmer': 't',
    'mode': 'b',
    'fmode': 'w',
  });
}
