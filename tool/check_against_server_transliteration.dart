// Asks the site's own transliteration program for the same words the unit
// tests use, and saves the answers as test/fixtures/server_transliteration.json.
// The test compares `convert` with that fixture; the test itself never calls
// the network.
//
// Run from the repository root:
//   dart run tool/check_against_server_transliteration.dart

import 'dart:convert';
import 'dart:io';

const endpoint =
    'https://sanskrit.uohyd.ac.in/cgi-bin/scl/transliteration/transliterate.cgi';

const wxName = 'WX-Alphabetic';
const devanagariName = 'Unicode-Devanagari';
const iastName = 'Unicode-Roman-Diacritic';

/// The round-trip list of test/transliteration_test.dart.
const words = [
  'kqRNa', 'jFAna', 'rAmaH', 'saMskqwam', 'AMSa', 'vAk', 'paFcan',
  'gacCawi', 'BavawI', 'xevaH', 'puwraH', 'rAmeNa', 'vanam', 'ca',
  'gaNeSaH', 'mahABArawam', 'BagavaxgIwA', 'yogaH', 'vexaH', 'pqWivI',
  'Qwu', 'guruH', 'SAswram', 'viRNuH', 'ahaM', 'namaH', 'BUmiH',
  'gqhe', 'oM', 'sUryaH', 'wawra', 'kRNoWi', 'ASramaH', 'xaMRtrA',
  // five with candrabindu (WX z), five with anusvara (WX M)
  'gamLz', 'puMsz', 'hazsaH', 'sazskqwam', 'yAzwi',
  'gaMgA', 'saMyogaH', 'vaMSaH', 'kiMcit', 'aMgam',
];

Future<String> ask(HttpClient client, String text, String from, String to) async {
  // The server sometimes closes a kept-alive connection; retry on a new one.
  for (var attempt = 1;; attempt++) {
    try {
      final request = await client.postUrl(Uri.parse(endpoint));
      request.headers.contentType =
          ContentType('application', 'x-www-form-urlencoded', charset: 'utf-8');
      request.headers.set(HttpHeaders.connectionHeader, 'close');
      // A fixed Content-Length: the server drops chunked requests.
      final payload = utf8.encode(
          'src=${Uri.encodeQueryComponent(text)}&srclang=$from&tarlang=$to');
      request.contentLength = payload.length;
      request.add(payload);
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      if (response.statusCode != 200) {
        throw StateError('${response.statusCode} for $text $from->$to');
      }
      return body.trim();
    } on HttpException {
      if (attempt >= 4) rethrow;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }
}

Future<void> main() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  final records = <Map<String, String>>[];

  Future<String> record(String text, String from, String to) async {
    final answer = await ask(client, text, from, to);
    records.add({'src': text, 'from': from, 'to': to, 'answer': answer});
    return answer;
  }

  for (final w in words) {
    final deva = await record(w, wxName, devanagariName);
    final iast = await record(w, wxName, iastName);
    await record(deva, devanagariName, wxName);
    await record(deva, devanagariName, iastName);
    await record(iast, iastName, wxName);
    await record(iast, iastName, devanagariName);
  }
  client.close();

  File('test/fixtures/server_transliteration.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(records)}\n');
  stdout.writeln('saved ${records.length} answers for ${words.length} words');
}
