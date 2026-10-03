import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/engines/heritage/heritage_engine.dart';
import 'package:mobile_app/engines/samsaadhanii/samsaadhanii_engine.dart';
import 'package:mobile_app/features/compare/agreement.dart';

import '../support/fixture_clients.dart';

Analysis _a(String lemma, List<Feature> features) => Analysis(
    lemma: SanskritText(lemma), wordClass: WordClass.noun, features: features);

Feature _f(FeatureKind k, FeatureValue v) => Feature(k, v, v.name);

Future<(List<Analysis>, List<Analysis>)> _both(String word) async {
  final w = SanskritText(word);
  final sam = await SamsaadhaniiEngine(client: SamsaadhaniiMorphFixtures())
      .analyseWord(w) as Found<WordAnalysis>;
  final her = await HeritageEngine(client: HeritageAnalysisFixtures())
      .analyseWord(w) as Found<WordAnalysis>;
  return (sam.value.analyses, her.value.analyses);
}

void main() {
  group('analysesAgree', () {
    test('same lemma, same features', () {
      expect(
          analysesAgree(
              _a('rAma', [_f(FeatureKind.gender, FeatureValue.masculine)]),
              _a('rAma', [_f(FeatureKind.gender, FeatureValue.masculine)])),
          isTrue);
    });

    test('a different lemma is a difference', () {
      expect(analysesAgree(_a('rAma', []), _a('rA', [])), isFalse);
    });

    test('the same kind with a different value is a difference', () {
      expect(
          analysesAgree(
              _a('x', [_f(FeatureKind.vibhakti, FeatureValue.nominative)]),
              _a('x', [_f(FeatureKind.vibhakti, FeatureValue.accusative)])),
          isFalse);
    });

    test('a kind only one engine reports is not a difference', () {
      expect(
          analysesAgree(
              _a('x', [
                _f(FeatureKind.gender, FeatureValue.masculine),
                _f(FeatureKind.gana, FeatureValue.bhvadi),
                _f(FeatureKind.nominalCategory, FeatureValue.sarvanama),
              ]),
              _a('x', [_f(FeatureKind.gender, FeatureValue.masculine)])),
          isTrue);
      expect(analysesAgree(_a('x', []), _a('x', [])), isTrue);
    });

    test('an unknown value cannot be compared and is left out', () {
      expect(
          analysesAgree(
              _a('x', [const Feature(FeatureKind.prayoga, FeatureValue.unknown, 'dh')]),
              _a('x', [_f(FeatureKind.prayoga, FeatureValue.kartari)])),
          isTrue);
    });

    test('open-class values compare by their text', () {
      Feature pratyaya(String wx) => Feature(
          FeatureKind.krtPratyaya, FeatureValue.openClass, wx,
          text: SanskritText(wx));
      expect(analysesAgree(_a('x', [pratyaya('Sawq')]), _a('x', [pratyaya('Sawq')])),
          isTrue);
      expect(analysesAgree(_a('x', [pratyaya('Sawq')]), _a('x', [pratyaya('kwa')])),
          isFalse);
    });

    test('word class and homonym are not part of the rule', () {
      expect(
          analysesAgree(
              const Analysis(
                  lemma: SanskritText('x'), homonym: 1, wordClass: WordClass.verb),
              const Analysis(lemma: SanskritText('x'), wordClass: WordClass.noun)),
          isTrue);
    });
  });

  group('compareAnalyses', () {
    test('every analysis needs a partner on the other side', () {
      final a = _a('rAma', []), b = _a('rA', []);
      final c = compareAnalyses([a, b], [a]);
      expect(c.agree, isFalse);
      expect(c.leftUnmatched, {1});
      expect(c.rightUnmatched, isEmpty);
      expect(compareAnalyses([a], [a]).agree, isTrue);
      expect(compareAnalyses([], []).agree, isTrue);
    });
  });

  group('the engines\' real answers (fixtures)', () {
    test('rAmaH: the engines agree', () async {
      final (sam, her) = await _both('rAmaH');
      final c = compareAnalyses(sam, her);
      expect(c.agree, isTrue, reason: '${c.leftUnmatched} ${c.rightUnmatched}');
    });

    test('gamyawe: the engines differ (the noun readings have no partner)',
        () async {
      final (sam, her) = await _both('gamyawe');
      final c = compareAnalyses(sam, her);
      expect(c.agree, isFalse);
      // Samsaadhanii's one passive reading has a partner; Heritage's four
      // gamyawA readings do not.
      expect(c.leftUnmatched, isEmpty);
      expect(c.rightUnmatched.length, 4);
    });

    test('aham: a pronoun agrees with Heritage\'s plain noun reading',
        () async {
      final (sam, her) = await _both('aham');
      expect(compareAnalyses(sam, her).agree, isTrue);
    });

    test('vanam agrees', () async {
      final (sam, her) = await _both('vanam');
      expect(compareAnalyses(sam, her).agree, isTrue);
    });
  });

  group('splitsAgree', () {
    const rama = Segment(SanskritText('rAmaH'), Boundary.word);
    const vanam = Segment(SanskritText('vanam'), Boundary.end);

    test('the same cut', () {
      expect(splitsAgree(const Split([rama, vanam]), const Split([rama, vanam])),
          isTrue);
    });

    test('a different cut', () {
      expect(splitsAgree(const Split([rama, vanam]), const Split([rama])), isFalse);
      expect(
          splitsAgree(
              const Split([Segment(SanskritText('rAma'), Boundary.compound), vanam]),
              const Split([Segment(SanskritText('rAma'), Boundary.word), vanam])),
          isFalse);
    });

    test('word analyses must agree when both have them', () {
      final src = ResultSource(
          engine: EngineId.samsaadhanii, program: 'p', time: DateTime(2026));
      Outcome<WordAnalysis> found(String lemma) =>
          Found(WordAnalysis(const SanskritText('w'), [_a(lemma, [])]), src);
      Split s(Outcome<WordAnalysis> slot) =>
          Split(const [vanam], analyses: [slot]);
      expect(splitsAgree(s(found('a')), s(found('a'))), isTrue);
      expect(splitsAgree(s(found('a')), s(found('b'))), isFalse);
      expect(splitsAgree(s(const NotFound()), s(const NotFound())), isTrue);
      expect(splitsAgree(s(found('a')), s(const NotFound())), isFalse);
    });
  });
}
