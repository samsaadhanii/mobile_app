// Saves the live server's raw answers under test/fixtures/samsaadhanii/, for
// the engine tests (which never call the network).
//
// Run from the repository root:
//   dart run tool/capture_samsaadhanii_fixtures.dart

import 'dart:io';

import 'package:mobile_app/engines/samsaadhanii/client.dart';
import 'package:mobile_app/engines/samsaadhanii/samsaadhanii_engine.dart';

const morphWords = {
  'rAmaH': 'rAmaH',
  'rAmeNa': 'rAmeNa',
  'vanam': 'vanam',
  'gacCawi': 'gacCawi',
  'gacCan': 'gacCan',
  'ca': 'ca',
  'AlayaH': 'AlayaH',
  'aham': 'aham',
  'gamyawe': 'gamyawe',
  'gamayawi': 'gamayawi',
  'xyzq': 'xyzq',
  'empty': '',
};

/// name -> (mode, text)
const splits = {
  'word_rAmAlayaH': ('word', 'rAmAlayaH'),
  'sent_rAmovanafgacCawi': ('sent', 'rAmovanafgacCawi'),
  'sent_xyzq': ('sent', 'xyzq'),
  'sent_empty': ('sent', ''),
};

Future<void> main() async {
  final client = HttpSamsaadhaniiClient();
  final dir = Directory('test/fixtures/samsaadhanii')..createSync(recursive: true);

  for (final e in morphWords.entries) {
    final r = await client.get(morphProgram, {
      'morfword': e.value,
      'encoding': 'WX',
      'outencoding': 'IAST',
      'mode': 'json',
    });
    _save(dir, 'morph_${e.key}.txt', r);
  }
  for (final e in splits.entries) {
    final (mode, text) = e.value;
    final r = await client.get(splitterProgram, {
      'word': text,
      'encoding': 'WX',
      'outencoding': 'I',
      'mode': mode,
      'disp_mode': 'json',
    });
    _save(dir, 'split_${e.key}.txt', r);
  }
}

void _save(Directory dir, String name, ClientResponse r) {
  if (r.statusCode != 200) {
    stderr.writeln('$name: HTTP ${r.statusCode}');
    exit(1);
  }
  File('${dir.path}/$name').writeAsStringSync(r.body);
  stdout.writeln('saved $name (${r.body.length} chars)');
}
