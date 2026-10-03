import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/sanskrit/transliteration.dart';

/// WX word -> its spelling in each script.
const _cases = <String, Map<Script, String>>{
  'kqRNa': {
    Script.devanagari: 'कृष्ण',
    Script.iast: 'kṛṣṇa',
    Script.slp1: 'kfzRa',
    Script.kyotoHarvard: 'kRSNa',
    Script.velthuis: 'k.r.s.na',
    Script.itrans: 'kRRiShNa',
  },
  'jFAna': {
    Script.devanagari: 'ज्ञान',
    Script.iast: 'jñāna',
    Script.slp1: 'jYAna',
    Script.kyotoHarvard: 'jJAna',
    Script.velthuis: 'j~naana',
    Script.itrans: 'j~naana',
  },
  'rAmaH': {
    Script.devanagari: 'रामः',
    Script.iast: 'rāmaḥ',
    Script.slp1: 'rAmaH',
    Script.kyotoHarvard: 'rAmaH',
    Script.velthuis: 'raama.h',
    Script.itrans: 'raamaH',
  },
  'saMskqwam': {
    Script.devanagari: 'संस्कृतम्',
    Script.iast: 'saṃskṛtam',
    Script.slp1: 'saMskftam',
    Script.kyotoHarvard: 'saMskRtam',
    Script.velthuis: 'sa.msk.rtam',
    Script.itrans: 'saMskRRitam',
  },
  'AMSa': {
    Script.devanagari: 'आंश',
    Script.iast: 'āṃśa',
    Script.slp1: 'AMSa',
    Script.kyotoHarvard: 'AMza',
    Script.velthuis: 'aa.mza',
    Script.itrans: 'aaMsha',
  },
  'vAk': {
    Script.devanagari: 'वाक्',
    Script.iast: 'vāk',
    Script.slp1: 'vAk',
    Script.kyotoHarvard: 'vAk',
    Script.velthuis: 'vaak',
    Script.itrans: 'vaak',
  },
  'paFcan': {
    Script.devanagari: 'पञ्चन्',
    Script.iast: 'pañcan',
    Script.slp1: 'paYcan',
    Script.kyotoHarvard: 'paJcan',
    Script.velthuis: 'pa~ncan',
    Script.itrans: 'pa~nchan',
  },
};

const _words = [
  'kqRNa', 'jFAna', 'rAmaH', 'saMskqwam', 'AMSa', 'vAk', 'paFcan',
  'gacCawi', 'BavawI', 'xevaH', 'puwraH', 'rAmeNa', 'vanam', 'ca',
  'gaNeSaH', 'mahABArawam', 'BagavaxgIwA', 'yogaH', 'vexaH', 'pqWivI',
  'Qwu', 'guruH', 'SAswram', 'viRNuH', 'ahaM', 'namaH', 'BUmiH',
  'gqhe', 'oM', 'sUryaH', 'wawra', 'kRNoWi', 'ASramaH', 'xaMRtrA',
];

void main() {
  group('hand-written cases', () {
    for (final entry in _cases.entries) {
      for (final s in entry.value.entries) {
        test('${entry.key}: ${s.key.name} -> WX', () {
          expect(toWx(s.value, s.key), entry.key);
        });
        test('${entry.key}: WX -> ${s.key.name}', () {
          expect(fromWx(entry.key, s.key), s.value);
        });
      }
    }
  });

  group('Devanagari', () {
    test('virama, inherent a, vowel signs', () {
      expect(toWx('क', Script.devanagari), 'ka');
      expect(toWx('क्', Script.devanagari), 'k');
      expect(toWx('कि', Script.devanagari), 'ki');
      expect(toWx('स्त्री', Script.devanagari), 'swrI');
      expect(toWx('क्‍ष', Script.devanagari), 'kRa'); // virama + ZWJ
    });
    test('independent vowels', () {
      expect(toWx('अआइईउऊऋॠऌएऐओऔ', Script.devanagari), 'aAiIuUqQLeEoO');
    });
    test('anusvara, visarga, candrabindu, avagraha, om', () {
      expect(toWx('अं अः अँ ऽ', Script.devanagari), 'aM aH az Z');
      expect(toWx('ॐ', Script.devanagari), 'oM');
      expect(fromWx('aM aH az Z', Script.devanagari), 'अं अः अँ ऽ');
    });
    test('digits', () {
      expect(toWx('१२३', Script.devanagari), '123');
      expect(fromWx('123', Script.devanagari), '१२३');
    });
    test('danda and double danda pass through', () {
      expect(toWx('रामः ।', Script.devanagari), 'rAmaH ।');
      expect(toWx('॥', Script.devanagari), '॥');
    });
    test('hiatus gives an independent vowel', () {
      expect(fromWx('kaa', Script.devanagari), 'कअ');
      expect(fromWx('ai', Script.devanagari), 'अइ');
    });
  });

  group('pass-through', () {
    test('spaces, punctuation, separators and parentheses', () {
      const text = 'rAma-vana_x (y) -> z, 5.';
      expect(toWx(text, Script.wx), text);
      for (final s in [Script.iast, Script.devanagari]) {
        final out = fromWx('rAma-vana (rAmaH) -> vanam', s);
        expect(out, contains('-'));
        expect(out, contains('('));
        expect(out, contains('->'));
      }
    });
    test('@word is a literal Latin word going out', () {
      expect(fromWx('@Hello rAmaH', Script.iast), 'Hello rāmaḥ');
    });
    test('Latin letters outside the scheme are kept', () {
      expect(toWx('rāma Q', Script.iast), 'rAma Q');
    });
    test('convert to the same script is the identity', () {
      expect(convert('rāmaḥ', Script.iast, Script.iast), 'rāmaḥ');
    });
  });

  group('IAST input', () {
    test('upper case and decomposed letters', () {
      expect(toWx('Rāmaḥ', Script.iast), 'rAmaH');
      expect(toWx('ra\u0304m\u0323', Script.iast), 'rAM');
      expect(toWx('s\u0301a\u0304stram', Script.iast), 'SAswram');
      expect(toWx('Ṛṣi', Script.iast), 'qRi');
      expect(toWx('gacchati', Script.iast), 'gacCawi');
    });
    test('dot above m is candrabindu, as in Samsaadhanii\'s own output', () {
      expect(toWx('gamḷṁ', Script.iast), 'gamLz');
      expect(toWx('saṃskṛtam', Script.iast), 'saMskqwam');
      expect(convert('gamḷṁ', Script.iast, Script.devanagari), 'गमॢँ');
      expect(toWx('gam\u1e37m\u0310', Script.iast), 'gamLz');
    });
  });

  group('ITRANS', () {
    test('capital A, I, U are accepted as long vowels', () {
      expect(toWx('rAmaH vAk AMsha', Script.itrans), 'rAmaH vAk AMSa');
    });
  });

  group('Velthuis', () {
    test('both spellings of ś are read', () {
      expect(toWx('aa.m"sa aa.mza', Script.velthuis), 'AMSa AMSa');
    });
  });

  group('convert', () {
    test('via WX between any two scripts', () {
      expect(convert('कृष्ण', Script.devanagari, Script.iast), 'kṛṣṇa');
      expect(convert('kṛṣṇa', Script.iast, Script.devanagari), 'कृष्ण');
      expect(convert('kfzRa', Script.slp1, Script.velthuis), 'k.r.s.na');
    });
  });

  group('round trips', () {
    for (final script in Script.values) {
      test('WX -> ${script.name} -> WX for ${_words.length} words', () {
        expect(_words.length, 34);
        for (final w in _words) {
          expect(toWx(fromWx(w, script), script), w,
              reason: '$w via ${script.name}: ${fromWx(w, script)}');
        }
      });
    }
  });

  group('corpus from assets/verblist.json', () {
    final verbs = (jsonDecode(File('assets/verblist.json').readAsStringSync())
            as List)
        .cast<Map<String, dynamic>>();

    test('Devanagari -> IAST equals the server\'s rom', () {
      final mismatches = [
        for (final v in verbs)
          if (convert(v['dev'], Script.devanagari, Script.iast) != v['rom'])
            v['wx'],
      ];
      expect(mismatches, isEmpty);
    });

    test('IAST rom and Devanagari dev give the same WX', () {
      final mismatches = [
        for (final v in verbs)
          if (toWx(v['rom'], Script.iast) != toWx(v['dev'], Script.devanagari))
            v['wx'],
      ];
      expect(mismatches, isEmpty);
    });

    test('Devanagari -> WX -> Devanagari is the identity', () {
      final mismatches = [
        for (final v in verbs)
          if (fromWx(toWx(v['dev'], Script.devanagari), Script.devanagari) !=
              v['dev'])
            v['wx'],
      ];
      expect(mismatches, isEmpty);
    });
  });

  group('the server\'s own transliteration (test/fixtures)', () {
    const scripts = {
      'WX-Alphabetic': Script.wx,
      'Unicode-Devanagari': Script.devanagari,
      'Unicode-Roman-Diacritic': Script.iast,
    };
    final records = (jsonDecode(
                File('test/fixtures/server_transliteration.json')
                    .readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();

    // The server's converter reads IAST `ṁ` as anusvara; we read it as
    // candrabindu, as Samsaadhanii's output uses it (U4b item 1). Every
    // other answer must agree.
    bool knownDisagreement(Map<String, dynamic> r) =>
        r['from'] == 'Unicode-Roman-Diacritic' &&
        (r['src'] as String).contains('ṁ');

    test('has answers for 44 words in six directions', () {
      expect(records.length, 264);
    });

    test('convert agrees with the server except for IAST ṁ', () {
      final disagreements = [
        for (final r in records)
          if (!knownDisagreement(r) &&
              convert(r['src'], scripts[r['from']]!, scripts[r['to']]!) !=
                  r['answer'])
            '${r['from']} -> ${r['to']}: ${r['src']}',
      ];
      expect(disagreements, isEmpty);
    });

    test('the known disagreements are exactly the ṁ cases', () {
      final known = records.where(knownDisagreement).toList();
      expect(known.length, 10);
      for (final r in known) {
        expect(
            convert(r['src'], scripts[r['from']]!, scripts[r['to']]!) !=
                r['answer'],
            isTrue,
            reason: 'if the server changed, drop this exception: ${r['src']}');
      }
    });
  });
}
