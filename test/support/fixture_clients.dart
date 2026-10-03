import 'dart:io';

import 'package:mobile_app/engines/heritage/client.dart' as h;
import 'package:mobile_app/engines/samsaadhanii/client.dart' as s;

/// Serves the captured Samsaadhanii morph answers.
class SamsaadhaniiMorphFixtures implements s.SamsaadhaniiClient {
  @override
  Future<s.ClientResponse> get(String program, Map<String, String> query) async =>
      s.ClientResponse(
          200,
          File('test/fixtures/samsaadhanii/morph_${query['morfword']}.txt')
              .readAsStringSync());
}

/// Serves the captured Heritage word-analysis answers.
class HeritageAnalysisFixtures implements h.HeritageClient {
  @override
  Future<h.ClientResponse> get(Map<String, String> query) async =>
      h.ClientResponse(
          200,
          File('test/fixtures/heritage/analysis_${query['text']}.json')
              .readAsStringSync());
}
