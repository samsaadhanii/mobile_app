import 'list_equality.dart';
import 'sanskrit_text.dart';
import 'word_analysis.dart';

/// What follows a segment: a space, a hyphen, or nothing.
enum Boundary { word, compound, end }

class Segment {
  final SanskritText text;
  final Boundary after;

  const Segment(this.text, this.after);

  @override
  bool operator ==(Object other) =>
      other is Segment && other.text == text && other.after == after;

  @override
  int get hashCode => Object.hash(text, after);

  @override
  String toString() => 'Segment(${text.wx}, ${after.name})';
}

class Split {
  final List<Segment> segments;

  /// One per word, when analyses were asked for and are available.
  final List<Analysis>? analyses;

  const Split(this.segments, {this.analyses});

  @override
  bool operator ==(Object other) =>
      other is Split &&
      listEq(other.segments, segments) &&
      listEq(other.analyses, analyses);

  @override
  int get hashCode => Object.hash(listHash(segments), listHash(analyses));

  @override
  String toString() => 'Split($segments'
      '${analyses == null ? '' : ', analyses: $analyses'})';
}

class Segmentation {
  final SanskritText input;

  /// Best first; Samsaadhanii usually gives one.
  final List<Split> candidates;

  const Segmentation(this.input, this.candidates);

  @override
  bool operator ==(Object other) =>
      other is Segmentation &&
      other.input == input &&
      listEq(other.candidates, candidates);

  @override
  int get hashCode => Object.hash(input, listHash(candidates));

  @override
  String toString() => 'Segmentation(${input.wx}, $candidates)';
}
