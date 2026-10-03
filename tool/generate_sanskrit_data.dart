// Regenerates assets/verblist.json and assets/prefix_list.json from the
// server's own lists (js_files/variables.js in the scl repository).
//
// Run from the repository root: dart run tool/generate_sanskrit_data.dart

import 'dart:convert';
import 'dart:io';

/// scl `master`, 16 Apr 2026.
const sclCommit = '1ec51dc4cbfecf271e4f3cb0bba41f25b5921572';

const variablesUrl =
    'https://raw.githubusercontent.com/samsaadhanii/scl/$sclCommit/js_files/variables.js';

final _entry = RegExp(
  r"'([^']+)'\s*:\s*\{\s*"
  r'dev:\s*"((?:[^"\\]|\\.)*)"\s*,\s*'
  r'rom:\s*"((?:[^"\\]|\\.)*)"\s*,\s*'
  r'wx:\s*"((?:[^"\\]|\\.)*)"\s*\}',
);

/// Returns the text of `var <name> = { ... };`.
String _block(String source, String name) {
  final start = source.indexOf('var $name = {');
  if (start < 0) throw StateError('$name not found');
  final end = source.indexOf('\n};', start);
  if (end < 0) throw StateError('end of $name not found');
  return source.substring(start, end);
}

/// Entries of one object as {key, dev, rom}, in the server's order.
List<Map<String, String>> _entries(String block) => [
      for (final m in _entry.allMatches(block))
        {'key': m[1]!, 'dev': m[2]!, 'rom': m[3]!},
    ];

String _unescape(String s) => jsonDecode('"$s"') as String;

Future<void> main() async {
  final client = HttpClient();
  final request = await client.getUrl(Uri.parse(variablesUrl));
  final response = await request.close();
  if (response.statusCode != 200) {
    stderr.writeln('GET $variablesUrl -> ${response.statusCode}');
    exit(1);
  }
  final source = await utf8.decodeStream(response);
  client.close();

  final prefixes = [
    for (final e in _entries(_block(source, 'pref_info')))
      if (e['key'] != '-')
        {
          'wx': e['key']!.replaceAll('Y', '_'),
          'dev': _unescape(e['dev']!),
          'rom': _unescape(e['rom']!),
        },
  ];
  final verbs = [
    for (final e in _entries(_block(source, 'root_info')))
      {
        'wx': e['key']!,
        'dev': _unescape(e['dev']!),
        'rom': _unescape(e['rom']!),
      },
  ];

  const encoder = JsonEncoder.withIndent('  ');
  File('assets/prefix_list.json').writeAsStringSync('${encoder.convert(prefixes)}\n');
  File('assets/verblist.json').writeAsStringSync('${encoder.convert(verbs)}\n');
  stdout.writeln('prefixes: ${prefixes.length}, verbs: ${verbs.length}');
}
