import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards for the faults of version 1's network code (`BUGS.md` #2 to #5),
/// kept as tests so they cannot come back: the engines' clients are the only
/// place that talks to the network, and they talk over HTTPS.

List<File> _libFiles() => [
      for (final e in Directory('lib').listSync(recursive: true))
        if (e is File && e.path.endsWith('.dart')) e,
    ];

void main() {
  test('there are files to check', () {
    expect(_libFiles().length, greaterThan(50));
  });

  test('no file under lib/ contains http:// (every address is https)', () {
    final offenders = [
      for (final f in _libFiles())
        if (f.readAsStringSync().contains('http://')) f.path,
    ];
    expect(offenders, isEmpty);
  });

  test('only the engines\' clients import package:http', () {
    final users = [
      for (final f in _libFiles())
        if (f.readAsStringSync().contains("package:http/")) f.path,
    ]..sort();
    expect(users, [
      'lib/engines/heritage/client.dart',
      'lib/engines/samsaadhanii/client.dart',
    ]);
  });

  test('no certificate check is switched off', () {
    final offenders = [
      for (final f in _libFiles())
        if (RegExp(r'badCertificateCallback|HttpOverrides|SecurityContext')
            .hasMatch(f.readAsStringSync()))
          f.path,
    ];
    expect(offenders, isEmpty);
  });

  test('nothing prints, so no request address reaches a log', () {
    final offenders = [
      for (final f in _libFiles())
        if (RegExp(r'(^|[^A-Za-z_.])(print|debugPrint)\(', multiLine: true)
            .hasMatch(f.readAsStringSync()))
          f.path,
    ];
    expect(offenders, isEmpty);
  });

  test('the guard itself would catch a plain http address', () {
    // The scan is a plain substring search; this shows what it looks for.
    expect('final u = "http://x.invalid";'.contains('http://'), isTrue);
    expect('final u = "https://x.invalid";'.contains('http://'), isFalse);
  });
}
