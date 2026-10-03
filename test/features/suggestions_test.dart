import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/features/home/dhatu_index.dart';
import 'package:mobile_app/features/home/suggestions.dart';

final _dhatus = DhatuIndex.fromKeys([
  'gam1_gamLz_BvAxiH_gawO',
  'aMSa1_aMSa_curAxiH_samaGAwe',
  'rA1__axAxiH',
]);

List<Task> _rows(List<String> words, {bool nothing = false}) => [
      for (final s in suggestionsFor(words,
          dhatus: _dhatus, analysisFoundNothing: nothing))
        s.task,
    ];

void main() {
  group('the rows of the table in SCREENS.md section 2', () {
    test('nothing typed, nothing offered', () {
      expect(_rows([]), isEmpty);
    });

    test('one word: Analyse, Dictionary, Noun forms', () {
      expect(_rows(['rAmaH']),
          [Task.analyseWord, Task.dictionary, Task.nounForms]);
    });

    test('one word that is a dhatu: Verb forms and Kṛt forms are added', () {
      expect(_rows(['gam']), [
        Task.analyseWord,
        Task.dictionary,
        Task.nounForms,
        Task.verbForms,
        Task.krtForms,
      ]);
    });

    test('two or more words: Split first, then Analyse', () {
      expect(_rows(['rAmaH', 'vanam', 'gacCawi']),
          [Task.splitText, Task.analyseWord]);
    });

    test('exactly two words: Join words is added', () {
      expect(_rows(['rAma', 'AlayaH']),
          [Task.splitText, Task.analyseWord, Task.joinWords]);
    });

    test('a word that analysis finds nothing for: Split first, then Analyse',
        () {
      expect(_rows(['xyzq'], nothing: true), [
        Task.splitText,
        Task.analyseWord,
        Task.dictionary,
        Task.nounForms,
      ]);
    });

    test('a dhatu is only checked for a single word', () {
      expect(_rows(['gam', 'gam']).contains(Task.verbForms), isFalse);
    });
  });

  group('DhatuIndex', () {
    test('matches the root without its number, and with its markers', () {
      expect(_dhatus.contains('gam'), isTrue);
      expect(_dhatus.contains('gamLz'), isTrue);
      expect(_dhatus.contains('aMSa'), isTrue);
      expect(_dhatus.contains('rA'), isTrue);
      expect(_dhatus.contains('gam1'), isFalse);
      expect(_dhatus.contains('rAma'), isFalse);
    });

    test('loads the bundled list', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final index = DhatuIndex();
      expect(index.loaded, isFalse);
      await index.load();
      expect(index.loaded, isTrue);
      expect(index.contains('gam'), isTrue);
      expect(index.contains('BU'), isTrue);
      expect(index.contains('rAmaH'), isFalse);
    });
  });
}
