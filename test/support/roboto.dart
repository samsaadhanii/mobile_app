import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the real Roboto that ships with the Flutter SDK, so a widget test can
/// measure text with true widths. The default test font draws every glyph as
/// a full-width square, which says nothing about whether a table fits a
/// phone. Returns false (and loads nothing) when the SDK's fonts are not where
/// `FLUTTER_ROOT` says.
Future<bool> loadRoboto() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return false;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  final files = [
    for (final w in ['Regular', 'Medium', 'Bold']) File('$dir/Roboto-$w.ttf'),
  ];
  if (!files.every((f) => f.existsSync())) return false;
  final loader = FontLoader('Roboto');
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
  }
  await loader.load();
  return true;
}
