import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

List<Map<String, dynamic>> _load(String path) =>
    (jsonDecode(File(path).readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();

void main() {
  final verbs = _load('assets/verblist.json');
  final prefixes = _load('assets/prefix_list.json');

  for (final entry in {'verbs': verbs, 'prefixes': prefixes}.entries) {
    group(entry.key, () {
      test('every entry has non-empty wx, dev and rom', () {
        for (final e in entry.value) {
          for (final k in ['wx', 'dev', 'rom']) {
            expect(e[k], isA<String>(), reason: '$k of $e');
            expect((e[k] as String).trim(), isNotEmpty, reason: '$k of $e');
          }
        }
      });

      test('wx keys are unique', () {
        final keys = entry.value.map((e) => e['wx']).toList();
        expect(keys.toSet().length, keys.length);
      });
    });
  }

  test('prefix list has nis and xus and no "no prefix" row', () {
    final keys = prefixes.map((e) => e['wx']).toSet();
    expect(keys, containsAll(['nis', 'xus']));
    expect(keys, isNot(contains('-')));
  });

  test('verb list has the corrected key and not the old bad ones', () {
    final keys = verbs.map((e) => e['wx']).toSet();
    expect(keys, contains('guX1_guXaz_xivAxiH_pariveRtane'));
    expect(keys, isNot(contains('guX1_gqXuz_xivAxiH_pariveRtane')));
    expect(keys, isNot(contains('saMsAXanI_iw_XAwu_gaNa_mng')));
  });
}
