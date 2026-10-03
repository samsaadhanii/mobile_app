import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/domain/domain.dart';
import 'package:mobile_app/engines/heritage/client.dart' as h;
import 'package:mobile_app/engines/heritage/heritage_engine.dart';
import 'package:mobile_app/engines/samsaadhanii/client.dart' as s;
import 'package:mobile_app/engines/samsaadhanii/samsaadhanii_engine.dart';

class _SamsaadhaniiFixtures implements s.SamsaadhaniiClient {
  @override
  Future<s.ClientResponse> get(String program, Map<String, String> query) async =>
      s.ClientResponse(200,
          File('test/fixtures/samsaadhanii/morph_${query['morfword']}.txt').readAsStringSync());
}

class _HeritageFixtures implements h.HeritageClient {
  @override
  Future<h.ClientResponse> get(Map<String, String> query) async =>
      h.ClientResponse(200,
          File('test/fixtures/heritage/analysis_${query['text']}.json').readAsStringSync());
}

/// `gamyawe`: the standard example for Compare. The two engines answer
/// differently, and the domain model holds both.
void main() {
  test('the two engines\' gamyawe answers differ', () async {
    const word = SanskritText('gamyawe');
    final sam = await SamsaadhaniiEngine(client: _SamsaadhaniiFixtures())
        .analyseWord(word) as Found<WordAnalysis>;
    final her = await HeritageEngine(client: _HeritageFixtures())
        .analyseWord(word) as Found<WordAnalysis>;

    // Samsaadhanii: one passive reading.
    expect(sam.value.analyses.length, 1);
    expect(sam.value.analyses.single.wordClass, WordClass.verb);

    // Heritage: passive, causative passive, and two noun lemmas (gamyawA).
    expect(her.value.analyses.length, 6);
    expect(her.value.analyses.where((a) => a.wordClass == WordClass.verb).length, 2);
    expect(her.value.analyses.where((a) => a.wordClass == WordClass.noun).length, 4);
    expect(her.value.analyses.map((a) => a.lemma.wx).toSet(), {'gam', 'gamyawA'});

    expect(sam.value, isNot(her.value));
    expect(sam.source.engine, EngineId.samsaadhanii);
    expect(her.source.engine, EngineId.heritage);
  });
}
