import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/settings.dart';
import 'package:mobile_app/features/task_frame/input_parsing.dart';
import 'package:mobile_app/shared/data/word_lists.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _gam = 'gam1_gamLz_BvAxiH_gawO';
const _paT = 'paT1_paT_BvAxiH_vyakwAyAM vAci';

final _dhatus = DhatuList.fromEntries([
  ListEntry(_gam, 'गम्', 'gam'),
  ListEntry('gam2_gamLz_curAxiH_gawO', 'गम्', 'gam'),
  ListEntry(_paT, 'पठ्', 'paṭh'),
]);

void main() {
  late AppSettings settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = await AppSettings.load();
  });

  test('a word typed in WX, IAST or Devanagari', () {
    for (final typed in ['gam', 'गम्', 'paṭ']) {
      // `paṭ` is not a root: only the first two are.
      final keys = rootKeysFor(typed, _dhatus, settings);
      expect(keys.isEmpty, typed == 'paṭ', reason: typed);
    }
    expect(rootKeysFor('gam', _dhatus, settings).first, _gam);
    expect(rootKeysFor('paṭh', _dhatus, settings), [_paT]);
  });

  test('only the first word counts', () {
    expect(rootKeysFor('gam xyz', _dhatus, settings).first, _gam);
  });

  test('an exact key is taken whole, even with a space in it', () {
    expect(rootKeysFor(_paT, _dhatus, settings), [_paT]);
    expect(rootKeysFor('  $_gam ', _dhatus, settings), [_gam]);
  });

  test('nothing for a word that is not a dhātu, or an empty input', () {
    expect(rootKeysFor('xyzq', _dhatus, settings), isEmpty);
    expect(rootKeysFor('', _dhatus, settings), isEmpty);
    expect(rootKeysFor('   ', _dhatus, settings), isEmpty);
  });
}
