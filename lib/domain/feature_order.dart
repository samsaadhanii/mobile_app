import 'feature.dart';
import 'word_analysis.dart';

/// The fixed display order of feature kinds for a word class, the same for
/// every engine (`SCREENS.md` 5.1). Kinds not listed, and unknown ones, come
/// last in the order they arrived.
List<FeatureKind> featureKindOrder(WordClass wordClass) => switch (wordClass) {
      WordClass.verb => const [
          FeatureKind.sanadi,
          FeatureKind.prayoga,
          FeatureKind.lakara,
          FeatureKind.person,
          FeatureKind.number,
          FeatureKind.pada,
          FeatureKind.gana,
        ],
      WordClass.participle => const [
          FeatureKind.krtPratyaya,
          FeatureKind.lakara,
          FeatureKind.prayoga,
          FeatureKind.gender,
          FeatureKind.vibhakti,
          FeatureKind.number,
          FeatureKind.nominalCategory,
        ],
      _ => const [
          FeatureKind.gender,
          FeatureKind.vibhakti,
          FeatureKind.number,
          FeatureKind.nominalCategory,
        ],
    };

/// [analysis]'s features in the display order. For display only: the model
/// keeps the engine's order. Features of one kind keep their arrival order.
List<Feature> orderedFeatures(Analysis analysis) {
  final order = featureKindOrder(analysis.wordClass);
  int rank(Feature f) {
    final i = order.indexOf(f.kind);
    return i < 0 ? order.length : i;
  }

  final indexed = [for (var i = 0; i < analysis.features.length; i++) (i, analysis.features[i])];
  indexed.sort((a, b) {
    final r = rank(a.$2).compareTo(rank(b.$2));
    return r != 0 ? r : a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}

/// The kinds in [present] in the display order of [wordClass], the rest after
/// them in the order given.
List<FeatureKind> kindsInOrder(
    WordClass wordClass, Iterable<FeatureKind> present) {
  final order = featureKindOrder(wordClass);
  final kinds = present.toSet();
  return [
    for (final k in order)
      if (kinds.remove(k)) k,
    ...present.where((k) => kinds.remove(k)),
  ];
}
