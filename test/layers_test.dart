import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The layer rule (ARCHITECTURE.md section 8): `features/` uses the layers
/// below it; none of them imports from `features/`.
void main() {
  test('shared, domain, sanskrit and engines never import from features', () {
    final import = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
        multiLine: true);
    final offenders = <String>[];
    for (final dir in ['shared', 'domain', 'sanskrit', 'engines']) {
      final root = Directory('lib/$dir');
      expect(root.existsSync(), isTrue, reason: 'lib/$dir is missing');
      for (final f in root.listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        for (final m in import.allMatches(f.readAsStringSync())) {
          final target = m.group(1)!;
          if (target.contains('features/')) offenders.add('${f.path}: $target');
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
