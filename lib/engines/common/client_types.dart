/// Types both engines' clients share. No engine's field names live here.
library;

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
