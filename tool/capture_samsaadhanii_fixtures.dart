// Saves the live server's raw answers under test/fixtures/samsaadhanii/, for
// the engine tests (which never call the network).
//
// Run from the repository root:
//   dart run tool/capture_samsaadhanii_fixtures.dart [morph] [split] [noun] [derivation] [verb]
// With no argument every section is captured; with names, only those, so a
// new fixture does not rewrite the older ones.

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

/// file name -> (stem, gender, category) for the noun generator.
const nouns = {
  'rAma': ('rAma', 'puM', 'nA'),
  'vana': ('vana', 'napuM', 'nA'),
  'naxI': ('naxI', 'swrI', 'nA'),
  'asmax': ('asmax', 'a', 'sarva'),
  'xyzq': ('xyzq', 'puM', 'nA'),
  'empty': ('', 'puM', 'nA'),
};

/// file name -> (stem, vibhakti, gender, vacana) for the simulator. The empty
/// stem is the request that finds nothing.
const derivations = {
  'rAma': ('rAma', 'wqwIyA', 'puM', 'ekavacana'),
  'empty': ('', 'wqwIyA', 'puM', 'ekavacana'),
};

/// file name -> (root key, prayoga_paxI, upasarga) for the verb generator. The
/// prefixed answers are saved exactly as the server sends them, with the raw
/// line break in `rt`, so the adapter's repair is tested on the real thing.
const verbs = {
  'gam': ('gam1_gamLz_BvAxiH_gawO', 'karwari-uBayapaxI', '-'),
  'Af': ('gam1_gamLz_BvAxiH_gawO', 'karwari-uBayapaxI', 'Af'),
  'pra': ('gam1_gamLz_BvAxiH_gawO', 'karwari-uBayapaxI', 'pra'),
  'karmaNi': ('gam1_gamLz_BvAxiH_gawO', 'karmaNi', '-'),
  'nic_parasmE': ('gam1_gamLz_BvAxiH_gawO', 'Nickarwari-parasmEpaxI', '-'),
  'nic_Awmane': ('gam1_gamLz_BvAxiH_gawO', 'Nickarwari-AwmanepaxI', '-'),
  'xyzq': ('xyzq', 'karwari-uBayapaxI', '-'),
};

Future<void> main(List<String> args) async {
  final client = HttpSamsaadhaniiClient();
  final dir = Directory('test/fixtures/samsaadhanii')..createSync(recursive: true);
  bool wanted(String section) => args.isEmpty || args.contains(section);

  for (final e in verbs.entries) {
    if (!wanted('verb')) break;
    final (root, prayoga, upasarga) = e.value;
    final r = await client.get(verbProgram, {
      'vb': root,
      'prayoga_paxI': prayoga,
      'upasarga': upasarga,
      'encoding': 'WX',
      'outencoding': 'IAST',
      'mode': 'json',
    });
    _save(dir, 'verb_${e.key}.json', r);
  }
  for (final e in nouns.entries) {
    if (!wanted('noun')) break;
    final (stem, gen, jati) = e.value;
    final r = await client.get(nounProgram, {
      'rt': stem,
      'gen': gen,
      'jAwi': jati,
      'level': '1',
      'mode': 'json',
      'encoding': 'WX',
      'outencoding': 'IAST',
    });
    _save(dir, 'noun_${e.key}.json', r);
  }
  for (final e in derivations.entries) {
    if (!wanted('derivation')) break;
    final (stem, vibhakti, gen, vacana) = e.value;
    final r = await client.get(derivationProgram, {
      'encoding': 'WX',
      'praatipadika': stem,
      'vibhakti': vibhakti,
      'linga': gen,
      'vacana': vacana,
    });
    _save(dir, 'derivation_${e.key}.html', r);
  }
  for (final e in morphWords.entries) {
    if (!wanted('morph')) break;
    final r = await client.get(morphProgram, {
      'morfword': e.value,
      'encoding': 'WX',
      'outencoding': 'IAST',
      'mode': 'json',
    });
    _save(dir, 'morph_${e.key}.txt', r);
  }
  for (final e in splits.entries) {
    if (!wanted('split')) break;
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
