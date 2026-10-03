/// The only file in the Samsaadhanii engine that makes HTTP calls.
/// Plain Dart (package:http, no Flutter).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const samsaadhaniiBaseUrl = 'https://samsaadhanii.org/cgi-bin/scl';

const samsaadhaniiTimeout = Duration(seconds: 20);

/// A raw answer: the status and the body, decoded as UTF-8.
class ClientResponse {
  final int statusCode;
  final String body;

  const ClientResponse(this.statusCode, this.body);
}

/// Thrown when the server could not be reached in time: a timeout, a socket
/// or TLS error, or a connection the client library gave up on.
class UnreachableException implements Exception {
  final String message;

  const UnreachableException(this.message);

  @override
  String toString() => 'UnreachableException($message)';
}

/// What the engine needs from the network. Tests replace it with a fake that
/// reads saved answers.
abstract interface class SamsaadhaniiClient {
  /// GETs [program] (a path under [samsaadhaniiBaseUrl], such as
  /// `MT/prog/morph/morph.cgi`) with [query]. Throws [UnreachableException]
  /// on a timeout or socket error; any HTTP status is returned as is.
  Future<ClientResponse> get(String program, Map<String, String> query);
}

class HttpSamsaadhaniiClient implements SamsaadhaniiClient {
  HttpSamsaadhaniiClient({http.Client? client, this.baseUrl = samsaadhaniiBaseUrl})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  @override
  Future<ClientResponse> get(String program, Map<String, String> query) async {
    final base = Uri.parse('$baseUrl/$program');
    final uri = base.replace(queryParameters: query);
    try {
      final response = await _client.get(uri).timeout(samsaadhaniiTimeout);
      // The server does not name a charset; its JSON is UTF-8.
      return ClientResponse(response.statusCode,
          utf8.decode(response.bodyBytes, allowMalformed: true));
    } on TimeoutException {
      throw UnreachableException('timeout after ${samsaadhaniiTimeout.inSeconds} s');
    } on SocketException catch (e) {
      throw UnreachableException('socket error: ${e.message}');
    } on HandshakeException catch (e) {
      throw UnreachableException('TLS error: ${e.message}');
    } on http.ClientException catch (e) {
      throw UnreachableException('connection error: ${e.message}');
    }
  }
}
