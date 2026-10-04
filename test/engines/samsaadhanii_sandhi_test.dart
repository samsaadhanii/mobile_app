import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/engines/heritage/client.dart' as h;
import 'package:mobile_app/engines/heritage/heritage_engine.dart';
import 'package:mobile_app/engines/samsaadhanii/client.dart';
import 'package:mobile_app/engines/samsaadhanii/samsaadhanii_engine.dart';

const _dir = 'test/fixtures/samsaadhanii';

String _fixture(String name) =>
    File('$_dir/sandhi_$name.json').readAsStringSync();

/// Serves the saved answer for the two words, or what a test says, and records
/// what was asked.
class _Client implements SamsaadhaniiClient {
  _Client({this.canned});

  final String? canned;
  final List<Map<String, String>> asked = [];

  @override
  Future<ClientResponse> get(String program, Map<String, String> query) async {
    asked.add(query);
    expect(program, 'sandhi/sandhi_json.cgi');
    if (canned != null) return ClientResponse(200, canned!);
    return ClientResponse(
        200, _fixture('${query['word1']}_${query['word2']}'));
  }
}

final _now = DateTime.utc(2026, 10, 5, 9);

SamsaadhaniiEngine _engine(_Client c) =>
    SamsaadhaniiEngine(client: c, now: () => _now);

Future<Outcome<SandhiResult>> _join(_Client c, String l, String r) =>
    _engine(c).joinSandhi(SanskritText(l), SanskritText(r));

SandhiResult _found(Outcome<SandhiResult> o) {
  expect(o, isA<Found<SandhiResult>>(), reason: '$o');
  return (o as Found<SandhiResult>).value;
}

String _iast(SanskritText t) => t.display(Script.iast);

List<String> _all(List<SanskritText> l) => [for (final t in l) _iast(t)];

void main() {
  group('rāmaḥ + ālayaḥ, two options', () {
    late SandhiResult result;

    setUp(() async {
      result = _found(await _join(_Client(), 'rAmaH', 'AlayaH'));
    });

    test('the inputs are echoed and the options come in the server order', () {
      expect(result.left, const SanskritText('rAmaH'));
      expect(result.right, const SanskritText('AlayaH'));
      expect(result.options.length, 2);
      expect(result.options.map((o) => _iast(o.joined)),
          ['rāma ālayaḥ', 'rāmayālayaḥ']);
    });

    test('a space inside the joined form is real, and kept as one', () {
      // The server writes `rāma  ālayaḥ` with two.
      expect(File('$_dir/sandhi_rAmaH_AlayaH.json').readAsStringSync(),
          contains('rāma  ālayaḥ'));
      expect(result.options.first.joined.wx, 'rAma AlayaH');
    });

    test('the letters that meet, trimmed', () {
      final o = result.options.first;
      expect(o.lastLetter.wx, 'H');
      expect(o.firstLetter.wx, 'A');
      // `"  ā"` on the server.
      expect(o.modifiedLetter.wx, 'A');
      expect(_iast(o.modifiedLetter), 'ā');
      expect(_iast(result.options.last.modifiedLetter), 'yā');
    });

    test('each word spelt out, one entry per letter', () {
      final o = result.options.first;
      expect(_all(o.leftLetters), ['r', 'ā', 'm', 'a', 'ḥ']);
      expect(_all(o.rightLetters), ['ā', 'l', 'a', 'y', 'a', 'ḥ']);
    });

    test('the name of the sandhi, split on ->, however the spaces fall', () {
      // `rutva -> yatva-> lopa`: spaces around the arrow vary.
      expect(File('$_dir/sandhi_rAmaH_AlayaH.json').readAsStringSync(),
          contains('rutva -> yatva-> lopa'));
      expect(_all(result.options.first.steps), ['rutva', 'yatva', 'lopa']);
      expect(_all(result.options.last.steps), ['rutva', 'yatva']);
    });

    test('the sūtras, each with its number from the bracket at its end', () {
      final sutras = result.options.first.sutras;
      expect(sutras.length, 3);
      expect(sutras.map((s) => _iast(s.text)),
          ['sasajuṣo ruḥ', "bhobhago agho apūrvasya yo'śi", 'lopaḥ śākalyasya']);
      expect(sutras.map((s) => s.number), ['8.2.66', '8.3.17', '8.3.19']);
      expect(result.options.last.sutras.map((s) => s.number), ['8.2.66', '8.3.17']);
    });

    test('Found carries its source', () async {
      final o = await _join(_Client(), 'rAmaH', 'AlayaH');
      final source = (o as Found<SandhiResult>).source;
      expect(source.engine, EngineId.samsaadhanii);
      expect(source.program, 'sandhi_json.cgi');
      expect(source.time, _now);
    });
  });

  group('the other fixtures', () {
    test('rāma + ayam: one option, a vārttika-free sūtra with its number',
        () async {
      final r = _found(await _join(_Client(), 'rAma', 'ayam'));
      expect(r.options.length, 1);
      final o = r.options.single;
      expect(_iast(o.joined), 'rāmāyam');
      expect(_all(o.steps), ['savarṇadīrgha']);
      expect(o.sutras.single.number, '6.1.101');
      expect(_iast(o.sutras.single.text), 'akaḥ savarṇe dīrghaḥ');
    });

    test('lakṣmīvān + śubhalakṣaṇaḥ: four options, in order', () async {
      final r = _found(await _join(_Client(), 'lakRmIvAn', 'SuBalakRaNaH'));
      expect(r.options.map((o) => _iast(o.joined)), [
        'lakṣmīvāñchubhalakṣaṇaḥ',
        'lakṣmīvāñcchubhalakṣaṇaḥ',
        'lakṣmīvāñcśubhalakṣaṇaḥ',
        'lakṣmīvāñśubhalakṣaṇaḥ',
      ]);
      expect(r.options.map((o) => _iast(o.modifiedLetter)),
          ['ñch', 'ñcch', 'ñcś', 'ñś']);
      // A letter is `bh`, not `b` and `h`.
      expect(_all(r.options.first.rightLetters).take(3), ['ś', 'u', 'bh']);
      expect(_all(r.options.first.steps),
          ['tugāgama', 'ścutva', 'cartva', 'chatva', 'lopaḥ']);
    });

    test('a sūtra with no bracket has no number: its text is as given',
        () async {
      final r = _found(await _join(_Client(), 'lakRmIvAn', 'SuBalakRaNaH'));
      // The second option's `sUwram` repeats the names, with no brackets.
      final second = r.options[1];
      expect(second.sutras.every((s) => s.number == null), isTrue);
      expect(_all([for (final s in second.sutras) s.text]),
          ['tugāgama', 'ścutva', 'cartva', 'chatva', 'lopābhāvaḥ']);
      // The first has numbers on all five.
      expect(r.options.first.sutras.map((s) => s.number),
          ['8.3.31', '8.4.40', '8.4.55', '8.4.63', '8.4.65']);
    });

    test('tad + ṭīkā: the WX that stands for tad', () async {
      final r = _found(await _join(_Client(), 'wax', 'tIkA'));
      expect(_iast(r.options.single.joined), 'taṭṭīkā');
      expect(_all(r.options.single.steps), ['ṣṭutva', 'cartva']);
    });

    test('the empty second word, as the server answers it: the first word, no steps',
        () async {
      // The engine never asks for this (see below); the saved answer is read
      // by feeding it to the engine directly.
      final r = _found(await _join(
          _Client(canned: _fixture('empty')), 'rAmaH', 'AlayaH'));
      final o = r.options.single;
      expect(_iast(o.joined), 'rāmaḥ');
      expect(o.firstLetter.isEmpty, isTrue);
      expect(o.rightLetters, isEmpty);
      expect(o.steps, isEmpty);
      expect(o.sutras, isEmpty);
    });
  });

  group('the number of a sūtra', () {
    Future<SandhiResult> one(String sutra) async => _found(await _join(
        _Client(
            canned: jsonEncode([
          {
            'word1': 'a', 'word2': 'b', 'spelling_word1': 'a ', 'spelling_word2': 'b ',
            'last_letter': 'a', 'first_letter': 'b', 'modified_letter': 'b',
            'saMhiwapaxam': 'ab', 'sanXiH': 'x', 'sUwram': sutra,
          }
        ])),
        'a',
        'b'));

    test('a vārttika keeps the content of its bracket as given', () async {
      final s = (await one('ṇatvam (vā 3640)')).options.single.sutras.single;
      expect(s.number, 'vā 3640');
      expect(_iast(s.text), 'ṇatvam');
    });

    test('only the bracket at the end is the number', () async {
      final s = (await one('a (b) c (8.1.1)')).options.single.sutras.single;
      expect(s.number, '8.1.1');
      expect(_iast(s.text), 'a (b) c');
    });

    test('an empty list of sūtras and of steps', () async {
      final o = (await one('')).options.single;
      expect(o.sutras, isEmpty);
    });
  });

  group('empty words, not found and odd answers', () {
    test('an empty second word is BadInput and no request is made', () async {
      final client = _Client();
      final o = await _join(client, 'rAmaH', '');
      expect(o, const BadInput<SandhiResult>('Enter two words'));
      expect(client.asked, isEmpty);
    });

    test('an empty first word, a blank, or only a daṇḍa too', () async {
      final client = _Client();
      for (final (l, r) in [('', 'AlayaH'), ('  ', 'AlayaH'), ('rAmaH', '।'), ('rAmaH', '12')]) {
        expect(await _join(client, l, r), isA<BadInput<SandhiResult>>(),
            reason: '"$l" + "$r"');
      }
      expect(client.asked, isEmpty);
    });

    test('the request: the cleaned words in WX, IAST output', () async {
      final client = _Client();
      await _join(client, 'rAmaH', 'AlayaH');
      expect(client.asked.single, {
        'word1': 'rAmaH',
        'word2': 'AlayaH',
        'encoding': 'WX',
        'outencoding': 'IAST',
      });
      final cleaned = _Client(canned: _fixture('rAmaH_AlayaH'));
      await _join(cleaned, 'rAmaH ।', ' AlayaH ॥ 12 ');
      expect(cleaned.asked.single['word1'], 'rAmaH');
      expect(cleaned.asked.single['word2'], 'AlayaH');
    });

    Future<Outcome<SandhiResult>> run(String body) =>
        _join(_Client(canned: body), 'a', 'b');

    test('an empty list is NotFound', () async {
      expect(await run('[]'), isA<NotFound<SandhiResult>>());
    });

    test('an option whose joined form is empty is dropped; none left is NotFound',
        () async {
      Map<String, String> option(String joined) => {
            'word1': 'a', 'word2': 'b', 'spelling_word1': 'a ', 'spelling_word2': 'b ',
            'last_letter': 'a', 'first_letter': 'b', 'modified_letter': 'b',
            'saMhiwapaxam': joined, 'sanXiH': '', 'sUwram': '',
          };
      expect(await run(jsonEncode([option(''), option('   ')])),
          isA<NotFound<SandhiResult>>());
      final r = _found(await run(jsonEncode([option(''), option('ab')])));
      expect(r.options.map((o) => o.joined.wx), ['ab']);
    });

    test('not JSON, empty, or an entry missing a field is a ServerFault',
        () async {
      expect(await run('<html>oops</html>'), isA<ServerFault<SandhiResult>>());
      expect(await run(''), isA<ServerFault<SandhiResult>>());
      expect(await run('[{"word1":"a"}]'), isA<ServerFault<SandhiResult>>());
      expect(await run('["x"]'), isA<ServerFault<SandhiResult>>());
    });

    test('a single object where a list is expected is read as a list of one',
        () async {
      final first = (jsonDecode(_fixture('rAma_ayam')) as List).first;
      final r = _found(await run(jsonEncode(first)));
      expect(r.options.length, 1);
    });

    test('a nonsense word still gets the program\'s answer (not detected)',
        () async {
      // The program applies letter rules to whatever it is given.
      final r = _found(await _join(
          _Client(canned: _fixture('wax_tIkA')), 'xyzq', 'abc'));
      expect(r.options.length, 1);
    });
  });

  group('the engines and the models', () {
    test('Samsaadhanii offers join words; Heritage does not, and never calls',
        () async {
      expect(SamsaadhaniiEngine().tasks, contains(Task.joinWords));
      final heritage = HeritageEngine(client: _ThrowingHeritageClient());
      expect(HeritageEngine().tasks, isNot(contains(Task.joinWords)));
      expect(
          await heritage.joinSandhi(
              const SanskritText('rAmaH'), const SanskritText('AlayaH')),
          const Unsupported<SandhiResult>(EngineId.heritage, Task.joinWords));
    });

    test('equality looks at what the models hold', () {
      SandhiOption of(String joined, {String? number}) => SandhiOption(
            joined: SanskritText(joined),
            lastLetter: const SanskritText('H'),
            firstLetter: const SanskritText('A'),
            modifiedLetter: const SanskritText('A'),
            sutras: [SandhiSutra(const SanskritText('x'), number)],
          );
      expect(of('a'), of('a'));
      expect(of('a').hashCode, of('a').hashCode);
      expect(of('a'), isNot(of('b')));
      expect(of('a', number: '1'), isNot(of('a')));
      expect(
          SandhiResult(const SanskritText('l'), const SanskritText('r'), [of('a')]),
          SandhiResult(const SanskritText('l'), const SanskritText('r'), [of('a')]));
    });
  });
}

class _ThrowingHeritageClient implements h.HeritageClient {
  @override
  Future<h.ClientResponse> get(Map<String, String> query) =>
      throw StateError('no network call expected');
}
