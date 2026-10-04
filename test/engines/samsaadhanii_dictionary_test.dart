import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/engines/heritage/client.dart' as h;
import 'package:mobile_app/engines/heritage/heritage_engine.dart';
import 'package:mobile_app/engines/samsaadhanii/client.dart';
import 'package:mobile_app/engines/samsaadhanii/dictionary_adapter.dart';
import 'package:mobile_app/engines/samsaadhanii/samsaadhanii_engine.dart';

const _dir = 'test/fixtures/samsaadhanii';

String _fixture(String name) => File('$_dir/dictionary_$name').readAsStringSync();

/// Serves the saved answer for the Devanagari headword, or what a test says,
/// and records what was asked.
class _Client implements SamsaadhaniiClient {
  _Client({this.canned});

  final String? canned;
  final List<Map<String, String>> asked = [];

  @override
  Future<ClientResponse> get(String program, Map<String, String> query) async {
    asked.add(query);
    expect(program, 'MT/dict_help_json.cgi');
    if (canned != null) return ClientResponse(200, canned!);
    final body = switch (query['word']) {
      'वन' => _fixture('vana.json'),
      'राम' => _fixture('rama.json'),
      'ज़ञ्ज़' => _fixture('nonsense.json'),
      'rAma' => _fixture('broken.txt'),
      final other => throw StateError('no fixture for "$other"'),
    };
    return ClientResponse(200, body);
  }
}

final _now = DateTime.utc(2026, 10, 5, 9);

SamsaadhaniiEngine _engine(_Client c) =>
    SamsaadhaniiEngine(client: c, now: () => _now);

Future<Outcome<List<DictionaryEntry>>> _look(_Client c, SanskritText w) =>
    _engine(c).lookUp(w);

List<DictionaryEntry> _found(Outcome<List<DictionaryEntry>> o) {
  expect(o, isA<Found<List<DictionaryEntry>>>(), reason: '$o');
  return (o as Found<List<DictionaryEntry>>).value;
}

final _vana = SanskritText.from('वन', Script.devanagari);
final _rama = SanskritText.from('राम', Script.devanagari);

DictionaryEntry _of(List<DictionaryEntry> l, String name) =>
    l.firstWhere((e) => e.dictionary.name == name);

void main() {
  group('वन, from the fixture', () {
    late List<DictionaryEntry> entries;

    setUp(() async {
      entries = _found(await _look(_Client(), _vana));
    });

    test('four entries, the four dictionaries in the server order', () {
      expect(entries.map((e) => e.dictionary), standardDictionaries);
      expect(entries.map((e) => e.dictionary.name),
          ['Apte', 'Monier-Williams', 'Heritage', 'Cappeller']);
      expect(entries.map((e) => e.dictionary.language), [
        DictionaryLanguage.hindi,
        DictionaryLanguage.english,
        DictionaryLanguage.french,
        DictionaryLanguage.german,
      ]);
    });

    test('the headword is the Devanagari the server echoes, held as WX', () {
      for (final e in entries) {
        expect(e.headword.wx, 'vana');
        expect(e.headword.display(Script.devanagari), 'वन');
      }
    });

    test('no character reference is left in any body', () {
      for (final e in entries) {
        expect(e.body, isNot(contains(RegExp(r'&#?\w+;'))), reason: e.dictionary.name);
      }
    });

    test('Monier-Williams: the references decoded, IAST letters in place', () {
      final raw = jsonDecode(_fixture('vana.json')) as List;
      expect((raw[1] as Map)['Meaning'], contains('v&#225;na'));
      final mw = _of(entries, 'Monier-Williams').body;
      expect(mw, contains('[ vana ] [ vána ]'));
      expect(mw, contains('forest'));
      expect(mw, startsWith('वन'));
      // The raw entry starts with `&#160;`, which is trimmed; inside, a
      // non-breaking space is the entry's own and stays.
      expect(mw.codeUnitAt(0), isNot(0xa0));
    });

    test('Heritage: &#x0935; and &#8201; and the accents', () {
      final fr = _of(entries, 'Heritage').body;
      expect(fr, startsWith('वन'));
      expect(fr, contains('forêt ;'));
      expect(fr, contains('végétation'));
      expect(fr, contains('«'));
    });

    test('Cappeller keeps its umlauts and is one paragraph', () {
      final de = _of(entries, 'Cappeller').body;
      expect(de, contains('wünschen'));
      expect(de, isNot(contains('\n')));
    });

    test('only Apte is cut into lines, at its runs of spaces', () {
      final apte = _of(entries, 'Apte');
      final lines = apte.paragraphs;
      expect(lines.length, greaterThan(5));
      expect(lines.first, 'वन नपुं* [वन्+अच्]');
      expect(lines[1], startsWith('1. अरण्य, जंगल'));
      expect(lines[2], startsWith('2. गुल्म'));
      for (final l in lines) {
        expect(l, isNotEmpty);
        expect(l, equals(l.trim()));
        expect(l, isNot(contains('  ')));
      }
      for (final e in entries.where((e) => e.dictionary.name != 'Apte')) {
        expect(e.paragraphs.length, 1, reason: e.dictionary.name);
        expect(e.body, isNot(contains('  ')));
      }
    });

    test('the request: the Devanagari headword, and nothing else', () async {
      final client = _Client();
      await _look(client, _vana);
      expect(client.asked.single, {'word': 'वन'});
    });

    test('Found carries its source', () async {
      final o = await _look(_Client(), _vana);
      final source = (o as Found<List<DictionaryEntry>>).source;
      expect(source.engine, EngineId.samsaadhanii);
      expect(source.program, 'dict_help_json.cgi');
      expect(source.time, _now);
    });
  });

  group('राम, from the fixture', () {
    test('four entries; Apte has several entries cut into lines', () async {
      final entries = _found(await _look(_Client(), _rama));
      expect(entries.length, 4);
      final apte = _of(entries, 'Apte');
      expect(apte.paragraphs.first, startsWith('राम वि*'));
      // Apte separates entries with a row of hyphens, a paragraph of its own.
      expect(apte.paragraphs.any((p) => RegExp(r'^-{5,}$').hasMatch(p)), isTrue);
      expect(_of(entries, 'Heritage').body, contains('rāma'.replaceAll('ā', 'ā')));
    });

    test('Heritage\'s long entry keeps its text and its apostrophes', () async {
      final fr = _of(_found(await _look(_Client(), _rama)), 'Heritage').body;
      expect(fr.length, greaterThan(5000));
      expect(fr, contains('le Charmant'));
    });
  });

  group('the script the headword is sent in', () {
    test('Devanagari, whatever the input script', () async {
      for (final word in [
        SanskritText.from('rāma', Script.iast),
        SanskritText.from('राम', Script.devanagari),
        SanskritText.from('rAma', Script.wx),
        const SanskritText('rAma'),
      ]) {
        final client = _Client();
        expect(await _look(client, word), isA<Found<List<DictionaryEntry>>>());
        expect(client.asked.single, {'word': 'राम'}, reason: word.wx);
      }
    });

    test('the WX headword that the server cannot find is never sent', () async {
      final client = _Client();
      await _look(client, const SanskritText('rAma'));
      expect(client.asked.single['word'], isNot('rAma'));
    });
  });

  group('empty entries, not found and the broken answer', () {
    Map<String, String> entry(String dict, String meaning) =>
        {'Word': 'वन', 'DICT': dict, 'Meaning': meaning};

    Future<Outcome<List<DictionaryEntry>>> run(String body) =>
        _look(_Client(canned: body), _vana);

    test('an entry with an empty meaning is left out, the rest keep their order',
        () async {
      final entries = _found(await run(jsonEncode([
        entry("Apte's Skt-Hnd Dict", ''),
        entry("Monier Williams' Skt-Eng Dict", 'forest'),
        entry('Heritage Skt-French Dict', '   '),
        entry("Cappeller's Skt-Ger Dict", 'Wald'),
      ])));
      expect(entries.map((e) => e.dictionary.name), ['Monier-Williams', 'Cappeller']);
    });

    test('a meaning of only references to spaces is empty too', () async {
      expect(
          await run(jsonEncode([entry('Heritage Skt-French Dict', '&#160;&#160;')])),
          isA<NotFound<List<DictionaryEntry>>>());
    });

    test('all four empty is NotFound (the live nonsense word)', () async {
      final o = await _look(_Client(), SanskritText.from('ज़ञ्ज़', Script.devanagari));
      expect(o, isA<NotFound<List<DictionaryEntry>>>());
    });

    test('an empty list is NotFound', () async {
      expect(await run('[]'), isA<NotFound<List<DictionaryEntry>>>());
    });

    test('the broken answer for a WX headword is a ServerFault', () async {
      // Not JSON, with a server file path in it (F5, BUGS #15).
      expect(_fixture('broken.txt'), contains('/var/www/html'));
      // The adapter never sends WX, so the saved answer is fed in directly.
      final o = await _look(_Client(canned: _fixture('broken.txt')), _rama);
      expect(o, isA<ServerFault<List<DictionaryEntry>>>());
      // Whatever the server says is not shown: only the fault.
      expect((o as ServerFault).detail, isNot(contains('/var/www')));
    });

    test('empty, not JSON or an entry without a meaning is a ServerFault',
        () async {
      expect(await run(''), isA<ServerFault<List<DictionaryEntry>>>());
      expect(await run('oops'), isA<ServerFault<List<DictionaryEntry>>>());
      expect(await run('[{"Word":"वन","DICT":"x"}]'),
          isA<ServerFault<List<DictionaryEntry>>>());
      expect(await run('["x"]'), isA<ServerFault<List<DictionaryEntry>>>());
    });

    test('a single object where a list is expected is read as a list of one',
        () async {
      final entries = _found(await run(
          jsonEncode(entry('Heritage Skt-French Dict', 'bois'))));
      expect(entries.single.body, 'bois');
    });

    test('a dictionary the app does not know is shown under the name it sent',
        () async {
      final e = _found(await run(jsonEncode([entry('Some Other Dict', 'x')]))).single;
      expect(e.dictionary, const DictionaryInfo('Some Other Dict', DictionaryLanguage.other));
    });

    test('an empty headword is BadInput and no request is made', () async {
      final client = _Client();
      for (final w in ['', '  ', '।', '12']) {
        expect(await _look(client, SanskritText(w)),
            const BadInput<List<DictionaryEntry>>('Enter a word'),
            reason: '"$w"');
      }
      expect(client.asked, isEmpty);
    });
  });

  group('decoding the references', () {
    test('decimal, hexadecimal and named', () {
      expect(decodeReferences('r&#257;ma'), 'rāma');
      expect(decodeReferences('&#x0935;&#x0928;'), 'वन');
      expect(decodeReferences('a&#8201;;'), 'a ;');
      expect(decodeReferences('a &amp; b &lt;c&gt; &quot;d&quot;'), 'a & b <c> "d"');
      expect(decodeReferences('&nbsp;x'), '\u00a0x');
      expect(decodeReferences('&#X0935;'), 'व');
    });

    test('what is not a character is kept as written', () {
      expect(decodeReferences('&foo; &#99999999; &#xD800; &#0;'),
          '&foo; &#99999999; &#xD800; &#0;');
      expect(decodeReferences('AT&T and a; b'), 'AT&T and a; b');
    });
  });

  group('the dictionaries that had no entry', () {
    DictionaryEntry e(DictionaryInfo d) => DictionaryEntry(
        dictionary: d, headword: const SanskritText('vana'), body: 'x');

    test('the standard four minus those present, in order', () {
      expect(missingDictionaries([e(standardDictionaries[1])]).map((d) => d.name),
          ['Apte', 'Heritage', 'Cappeller']);
      expect(missingDictionaries([for (final d in standardDictionaries) e(d)]),
          isEmpty);
      expect(missingDictionaries(const []), standardDictionaries);
    });

    test('an unknown dictionary hides none of the four', () {
      expect(
          missingDictionaries(
                  [e(const DictionaryInfo('Other', DictionaryLanguage.other))])
              .length,
          4);
    });
  });

  group('the engines and the models', () {
    test('Samsaadhanii offers the dictionary; Heritage does not, and never calls',
        () async {
      expect(SamsaadhaniiEngine().tasks, contains(Task.dictionary));
      final heritage = HeritageEngine(client: _ThrowingHeritageClient());
      expect(HeritageEngine().tasks, isNot(contains(Task.dictionary)));
      expect(await heritage.lookUp(_vana),
          const Unsupported<List<DictionaryEntry>>(EngineId.heritage, Task.dictionary));
    });

    test('entries are equal when what they hold is', () {
      DictionaryEntry of(String body) => DictionaryEntry(
          dictionary: standardDictionaries.first,
          headword: const SanskritText('vana'),
          body: body);
      expect(of('a'), of('a'));
      expect(of('a').hashCode, of('a').hashCode);
      expect(of('a'), isNot(of('b')));
      expect(of('a\nb').paragraphs, ['a', 'b']);
      expect(sameEntries([of('a')], [of('a')]), isTrue);
    });

    test('the language labels', () {
      expect(DictionaryLanguage.values.map((l) => l.label),
          ['Hindi', 'English', 'French', 'German', '']);
    });
  });
}

class _ThrowingHeritageClient implements h.HeritageClient {
  @override
  Future<h.ClientResponse> get(Map<String, String> query) =>
      throw StateError('no network call expected');
}
