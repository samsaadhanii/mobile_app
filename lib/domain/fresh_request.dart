import 'dart:async';

final _freshKey = Object();

/// Runs [body] so that every engine request it makes goes to the server, not
/// to what the app kept from an earlier answer. For Retry: the user asked
/// again because the answer in hand is not the one they want.
Future<T> runFresh<T>(Future<T> Function() body) =>
    runZoned(body, zoneValues: {_freshKey: true});

/// Whether the code running now was started by [runFresh].
bool get isFreshRequest => Zone.current[_freshKey] == true;
