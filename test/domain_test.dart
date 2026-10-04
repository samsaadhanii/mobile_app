import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/domain/domain.dart';

import 'fakes/fake_engine.dart';

final _source = ResultSource(
  engine: EngineId.samsaadhanii,
  program: 'morph.cgi',
  time: DateTime.utc(2026, 10, 3),
);

Analysis _rama() => Analysis(
      lemma: const SanskritText('rAma'),
      wordClass: WordClass.noun,
      features: const [
        Feature(FeatureKind.gender, FeatureValue.masculine, 'puM'),
        Feature(FeatureKind.vibhakti, FeatureValue.nominative, '1'),
        Feature(FeatureKind.number, FeatureValue.singular, 'eka'),
      ],
    );

void main() {
  group('Unsupported', () {
    test('comes back at once for a task not in tasks', () async {
      final engine = FakeEngine(
        tasks: {Task.analyseWord},
        latency: const Duration(seconds: 30),
        segmentation: Found(
            const Segmentation(SanskritText('rAmaH'), []), _source),
      );
      final outcome = await engine
          .segment(const SanskritText('rAmaH'))
          .timeout(const Duration(milliseconds: 500));
      expect(outcome, isA<Unsupported<Segmentation>>());
      expect(outcome,
          const Unsupported<Segmentation>(EngineId.samsaadhanii, Task.splitText));
    });

    test('also for analyseWord when it is not offered', () async {
      final engine = FakeEngine(tasks: {Task.splitText});
      final outcome = await engine
          .analyseWord(const SanskritText('rAmaH'))
          .timeout(Duration.zero);
      expect(outcome, isA<Unsupported<WordAnalysis>>());
    });

    test('a supported task returns what was canned', () async {
      final found = Found(WordAnalysis(const SanskritText('rAmaH'), [_rama()]),
          _source);
      final engine = FakeEngine(analysis: found);
      expect(await engine.analyseWord(const SanskritText('rAmaH')), found);
      expect(engine.calls, ['analyseWord:rAmaH']);
      expect(await engine.segment(const SanskritText('x'), analyse: true),
          isA<NotFound<Segmentation>>());
    });
  });

  group('Outcome', () {
    test('equality and toString', () {
      expect(const NotFound<int>(), const NotFound<int>());
      expect(const BadInput<int>('x'), const BadInput<int>('x'));
      expect(const BadInput<int>('x') == const BadInput<int>('y'), isFalse);
      expect(const ServerFault<int>('bad json'),
          const ServerFault<int>('bad json'));
      expect(const Unreachable<int>('timeout'),
          isNot(const ServerFault<int>('timeout')));
      expect(Found(1, _source), Found(1, _source));
      expect(Found(1, _source) == Found(2, _source), isFalse);
      expect(const NotFound<int>().toString(), 'NotFound');
      expect(const BadInput<int>('x').toString(), 'BadInput(x)');
      expect(const Unsupported<int>(EngineId.heritage, Task.nounForms).toString(),
          'Unsupported(heritage, nounForms)');
    });

    test('a switch over the sealed type is exhaustive', () {
      String describe(Outcome<int> o) => switch (o) {
            Found() => 'found',
            NotFound() => 'notFound',
            BadInput() => 'badInput',
            ServerFault() => 'serverFault',
            Unreachable() => 'unreachable',
            Unsupported() => 'unsupported',
          };
      expect(describe(const NotFound()), 'notFound');
      expect(describe(Found(1, _source)), 'found');
    });
  });

  group('models', () {
    test('equality is by value, lists included', () {
      expect(_rama(), _rama());
      expect(_rama().hashCode, _rama().hashCode);
      expect(
          WordAnalysis(const SanskritText('rAmaH'), [_rama()]),
          WordAnalysis(const SanskritText('rAmaH'), [_rama()]));
      expect(
          WordAnalysis(const SanskritText('rAmaH'), [_rama()]) ==
              const WordAnalysis(SanskritText('rAmaH'), []),
          isFalse);
      const split = Split([
        Segment(SanskritText('rAmaH'), Boundary.word),
        Segment(SanskritText('vanam'), Boundary.end),
      ]);
      expect(
          split,
          const Split([
            Segment(SanskritText('rAmaH'), Boundary.word),
            Segment(SanskritText('vanam'), Boundary.end),
          ]));
      expect(split == const Split([]), isFalse);
      final slot = Found(WordAnalysis(const SanskritText('x'), [_rama()]), _source);
      expect(Split(const [], analyses: [slot]) == const Split([]), isFalse);
      expect(Split(const [], analyses: [slot]),
          Split(const [], analyses: [slot]));
      expect(
          Split(const [], analyses: [slot]) ==
              Split(const [], analyses: const [NotFound<WordAnalysis>()]),
          isFalse);
      expect(const Segmentation(SanskritText('x'), [split]),
          const Segmentation(SanskritText('x'), [split]));
    });

    test('toString', () {
      expect(const SanskritText('rAmaH').toString(), 'SanskritText(rAmaH)');
      expect(
          const Feature(FeatureKind.gender, FeatureValue.masculine, 'puM')
              .toString(),
          'Feature(gender, masculine, "puM")');
      expect(const Segment(SanskritText('vanam'), Boundary.end).toString(),
          'Segment(vanam, end)');
      expect(
          const Analysis(
                  lemma: SanskritText('gam'),
                  homonym: 1,
                  wordClass: WordClass.verb)
              .toString(),
          'Analysis(gam#1, verb, [])');
    });

    test('an open-class feature carries its value as text', () {
      final f = Feature(FeatureKind.krtPratyaya, FeatureValue.openClass, 'śatṛ',
          text: SanskritText.from('śatṛ', Script.iast));
      expect(f.text, const SanskritText('Sawq'));
      expect(f, isNot(const Feature(FeatureKind.krtPratyaya, FeatureValue.openClass, 'śatṛ')));
      expect(f.toString(), 'Feature(krtPratyaya, openClass, "śatṛ", text: Sawq)');
      expect(WordClass.values, contains(WordClass.compoundMember));
    });

    test('an unmapped label keeps its original text', () {
      const f = Feature(FeatureKind.vibhakti, FeatureValue.unknown, 'xyz');
      expect(f.original, 'xyz');
      expect(f.value, FeatureValue.unknown);
    });
  });

  group('FeatureValue', () {
    test('every value has an IAST and an English name, except unknown', () {
      for (final v in FeatureValue.values) {
        expect(v.english, isNotEmpty);
        if (v != FeatureValue.unknown && v != FeatureValue.openClass) {
          expect(v.iast, isNotEmpty);
        }
      }
    });

    test('the first set has the expected sizes', () {
      expect(FeatureValue.of(FeatureKind.gender).length, 4);
      expect(FeatureValue.of(FeatureKind.vibhakti).length, 8);
      expect(FeatureValue.of(FeatureKind.number).length, 3);
      expect(FeatureValue.of(FeatureKind.person).length, 3);
      expect(FeatureValue.of(FeatureKind.lakara).length, 11);
      expect(FeatureValue.of(FeatureKind.pada).length, 2);
      expect(FeatureValue.of(FeatureKind.prayoga).length, 3);
      expect(FeatureValue.of(FeatureKind.gana).length, 10);
      expect(FeatureValue.of(FeatureKind.sanadi).length, 3);
      expect(FeatureValue.of(FeatureKind.nominalCategory).map((v) => v.english),
          ['plain noun', 'pronoun', 'numeral', 'cardinal', 'ordinal']);
    });
  });

  group('Task', () {
    test('eight tasks, each with names and a description', () {
      expect(Task.values.length, 8);
      for (final t in Task.values) {
        expect(t.nameEn, isNotEmpty);
        expect(t.nameSa, isNotEmpty);
        expect(t.description, isNotEmpty);
      }
    });
  });

  group('SanskritText.display', () {
    const text = SanskritText('saMskqwam');
    test('Devanagari, IAST and WX', () {
      expect(text.display(Script.devanagari), 'संस्कृतम्');
      expect(text.display(Script.iast), 'saṃskṛtam');
      expect(text.display(Script.wx), 'saMskqwam');
    });
    test('from() converts into WX', () {
      expect(SanskritText.from('गमॢँ', Script.devanagari),
          const SanskritText('gamLz'));
      expect(SanskritText.from('rāmaḥ', Script.iast),
          const SanskritText('rAmaH'));
    });
  });
}
