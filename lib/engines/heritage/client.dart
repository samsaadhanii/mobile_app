/// The only file in the Heritage engine that makes HTTP calls.
/// Plain Dart (package:http, no Flutter).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../common/client_types.dart';

export '../common/client_types.dart';

const heritageUrl = 'https://sanskrit.inria.fr/cgi-bin/SKT/sktgraph2.cgi';

const heritageTimeout = Duration(seconds: 20);

/// What the engine needs from the network. Tests replace it with a fake that
/// reads saved answers.
abstract interface class HeritageClient {
  /// GETs `sktgraph2.cgi` with [query]. Throws [UnreachableException] on a
  /// timeout or socket error; any HTTP status is returned as is.
  Future<ClientResponse> get(Map<String, String> query);
}

class HttpHeritageClient implements HeritageClient {
  HttpHeritageClient({http.Client? client, this.url = heritageUrl})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String url;

  @override
  Future<ClientResponse> get(Map<String, String> query) async {
    final uri = Uri.parse(url).replace(queryParameters: query);
    try {
      final response = await _client.get(uri).timeout(heritageTimeout);
      // The server sends JSON as text/html; it is UTF-8.
      return ClientResponse(response.statusCode,
          utf8.decode(response.bodyBytes, allowMalformed: true));
    } on TimeoutException {
      throw UnreachableException('timeout after ${heritageTimeout.inSeconds} s');
    } on SocketException catch (e) {
      throw UnreachableException('socket error: ${e.message}');
    } on HandshakeException catch (e) {
      throw UnreachableException('TLS error: ${e.message}');
    } on http.ClientException catch (e) {
      throw UnreachableException('connection error: ${e.message}');
    }
  }
}
