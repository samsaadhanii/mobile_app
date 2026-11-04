import 'package:flutter/material.dart';

import '../domain/domain.dart';
import 'engine_identity.dart' show readableOn;

/// The colour of a word class, as a second signal beside the text tags
/// (tester's point 3). The scheme is the Sanskrit Heritage reader's own, read
/// from its page and its stylesheet (https://sanskrit.inria.fr/DICO/style.css,
/// classes `deep_sky_back`, `carmin_back`, `mauve_back`, `yellow_back`, as the
/// reader paints them on 4 Nov 2026). Samsaadhanii sends `skyblue` for a noun
/// and a kṛt form and `pink` for a verb: the same two families.

/// Heritage's colour for [wordClass]; null where Heritage has none (the app's
/// "other"; Heritage paints an unknown word grey, which marks nothing).
Color? heritageWordClassColour(WordClass wordClass) => switch (wordClass) {
      WordClass.noun => const Color(0xFF00C0FF), // deep_sky
      // Heritage paints a participle as a noun; so does Samsaadhanii (skyblue).
      WordClass.participle => const Color(0xFF00C0FF),
      WordClass.verb => const Color(0xFFFF1975), // carmin
      WordClass.indeclinable => const Color(0xFFFF99FF), // mauve
      WordClass.compoundMember => const Color(0xFFFFFF00), // yellow
      WordClass.other => null,
    };

/// The mark for [wordClass] on a card of [scheme]: Heritage's colour, moved
/// toward black (light theme) or white (dark theme) until it reaches 3 to 1
/// against the card, since it is a mark and not text. Null for a class without
/// a colour.
Color? wordClassColour(WordClass wordClass, ColorScheme scheme) {
  final base = heritageWordClassColour(wordClass);
  if (base == null) return null;
  final light = scheme.brightness == Brightness.light;
  return readableOn(
      base, scheme.surfaceContainerLow, light ? Colors.black : Colors.white,
      minimum: 3);
}

/// The classes that have a colour, in the order About lists them, with the
/// words it uses.
const colouredWordClasses = [
  WordClass.noun,
  WordClass.participle,
  WordClass.verb,
  WordClass.indeclinable,
  WordClass.compoundMember,
];
