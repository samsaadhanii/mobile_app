// Saves the live server's raw answers under test/fixtures/samsaadhanii/, for
// the engine tests (which never call the network).
//
// Run from the repository root:
//   dart run tool/capture_samsaadhanii_fixtures.dart [morph] [split] [noun] [derivation] [verb] [prefixed] [krt] [sandhi] [dictionary]
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

/// file name -> (root key, upasarga) for the kṛt generator. `gam_pra` has
/// `lyap` where the others have `ktvā`; `xyzq` is all dashes.
const krts = {
  'gam': ('gam1_gamLz_BvAxiH_gawO', '-'),
  'paT': ('paT1_paTaz_BvAxiH_vyakwAyAM_vAci', '-'),
  'kq': ('kq3_dukqF_wanAxiH_karaNe', '-'),
  'gam_pra': ('gam1_gamLz_BvAxiH_gawO', 'pra'),
  'xyzq': ('xyzq', '-'),
};

/// file name -> (word1, word2) for the sandhi joiner. The last has an empty
/// second word: the server answers the first word unchanged, which the engine
/// never asks for (it answers `BadInput` first).
const sandhis = {
  'rAmaH_AlayaH': ('rAmaH', 'AlayaH'),
  'rAma_ayam': ('rAma', 'ayam'),
  'lakRmIvAn_SuBalakRaNaH': ('lakRmIvAn', 'SuBalakRaNaH'),
  'wax_tIkA': ('wax', 'tIkA'),
  'empty': ('rAmaH', ''),
};

/// file name -> the headword sent to the dictionary. The app always sends
/// Devanagari; `broken` is the WX headword that the server cannot find, saved as
/// text (it is not JSON) to test the `ServerFault`; `nonsense` has four empty
/// meanings.
const dictionaries = {
  'vana': 'वन',
  'rama': 'राम',
  'nonsense': 'ज़ञ्ज़',
  'broken': 'rAma',
};

/// A prefixed verb and kṛt form, for the `upasarga` the analyses carry.
const prefixedMorph = {'AgacCawi': 'AgacCawi'};

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

  for (final e in dictionaries.entries) {
    if (!wanted('dictionary')) break;
    final r = await client.get(dictionaryProgram, {'word': e.value});
    _save(dir, 'dictionary_${e.key}.${e.key == 'broken' ? 'txt' : 'json'}', r);
  }
  for (final e in sandhis.entries) {
    if (!wanted('sandhi')) break;
    final (w1, w2) = e.value;
    final r = await client.get(sandhiProgram, {
      'word1': w1,
      'word2': w2,
      'encoding': 'WX',
      'outencoding': 'IAST',
    });
    _save(dir, 'sandhi_${e.key}.json', r);
  }
  for (final e in krts.entries) {
    if (!wanted('krt')) break;
    final (root, upasarga) = e.value;
    final r = await client.get(krtProgram, {
      'vb': root,
      'upasarga': upasarga,
      'encoding': 'WX',
      'outencoding': 'IAST',
      'mode': 'json',
    });
    _save(dir, 'krt_${e.key}.json', r);
  }
  for (final e in prefixedMorph.entries) {
    if (!wanted('prefixed')) break;
    final r = await client.get(morphProgram, {
      'morfword': e.value,
      'encoding': 'WX',
      'outencoding': 'IAST',
      'mode': 'json',
    });
    _save(dir, 'morph_${e.key}.txt', r);
  }
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
