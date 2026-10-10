import 'feature.dart';
import 'list_equality.dart';
import 'sanskrit_text.dart';

/// The voice a verb is conjugated in: the three choices of the Verb forms
/// screen. ṇijanta is the causative, in the active.
enum VerbPrayoga {
  kartari('kartari', 'active'),
  karmani('karmaṇi', 'passive'),
  nijanta('ṇijanta', 'causative');

  const VerbPrayoga(this.iast, this.english);

  /// The Sanskrit name, in IAST.
  final String iast;
  final String english;
}

/// What to conjugate: a root and an optional prefix, in a voice.
class VerbQuery {
  /// The dhātu key from `assets/verblist.json`, WX
  /// (`gam1_gamLz_BvAxiH_gawO`). A key, not text to be converted.
  final String root;

  /// A key from `assets/prefix_list.json` (`Af`, `pra`, `aXi_ava`), or null
  /// for none.
  final String? prefix;

  final VerbPrayoga prayoga;

  const VerbQuery({
    required this.root,
    this.prefix,
    this.prayoga = VerbPrayoga.kartari,
  });

  @override
  bool operator ==(Object other) =>
      other is VerbQuery &&
      other.root == root &&
      other.prefix == prefix &&
      other.prayoga == prayoga;

  @override
  int get hashCode => Object.hash(root, prefix, prayoga);

  @override
  String toString() => 'VerbQuery($root, ${prefix ?? '-'}, ${prayoga.name})';
}

/// The ten lakāras in the order the server lists them.
const lakaraOrder = [
  FeatureValue.lat,
  FeatureValue.lit,
  FeatureValue.lut,
  FeatureValue.lrt,
  FeatureValue.lot,
  FeatureValue.lan,
  FeatureValue.vidhiling,
  FeatureValue.ashirling,
  FeatureValue.lun,
  FeatureValue.lrn,
];

/// The persons in table order: prathama, madhyama, uttama.
const personOrder = [
  FeatureValue.third,
  FeatureValue.second,
  FeatureValue.first,
];

/// The padas in the order a screen offers them.
const padaOrder = [
  FeatureValue.parasmaipada,
  FeatureValue.atmanepada,
];

/// One lakāra: three persons by three numbers. A cell holds a list of forms
/// (`gacchatu/gacchatāt`, three alternatives for the perfect of a causative)
/// and may be empty.
class LakaraTable {
  final FeatureValue lakara;
  final Map<(FeatureValue, FeatureValue), List<SanskritText>> cells;

  const LakaraTable(this.lakara, this.cells);

  /// The forms in one cell; empty when it is empty or absent.
  List<SanskritText> forms(FeatureValue person, FeatureValue number) =>
      cells[(person, number)] ?? const [];

  bool get isEmpty => cells.values.every((f) => f.isEmpty);

  @override
  bool operator ==(Object other) =>
      other is LakaraTable &&
      other.lakara == lakara &&
      mapOfListsEq(other.cells, cells);

  @override
  int get hashCode => Object.hash(lakara, mapOfListsHash(cells));

  @override
  String toString() => 'LakaraTable(${lakara.name})';
}

/// All the lakāras of one pada, in the server's order.
class PadaTables {
  final FeatureValue pada;
  final List<LakaraTable> lakaras;

  const PadaTables(this.pada, this.lakaras);

  @override
  bool operator ==(Object other) =>
      other is PadaTables &&
      other.pada == pada &&
      listEq(other.lakaras, lakaras);

  @override
  int get hashCode => Object.hash(pada, listHash(lakaras));

  @override
  String toString() => 'PadaTables(${pada.name}, ${lakaras.length} lakāras)';
}

/// The forms of a verb. [padas] holds only the padas that have a form, in
/// [padaOrder]; none at all is not a paradigm (the engine answers `NotFound`).
class VerbParadigm {
  final VerbQuery query;

  /// The heading the server gives, with a space before the bracket:
  /// `gam (bhvādiḥ)`, or `āṅ_gam (bhvādiḥ)` with a prefix.
  final SanskritText heading;
  final List<PadaTables> padas;

  const VerbParadigm(this.query, this.heading, this.padas);

  PadaTables? pada(FeatureValue pada) {
    for (final p in padas) {
      if (p.pada == pada) return p;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is VerbParadigm &&
      other.query == query &&
      other.heading == heading &&
      listEq(other.padas, padas);

  @override
  int get hashCode => Object.hash(query, heading, listHash(padas));

  @override
  String toString() => 'VerbParadigm($query, ${padas.length} padas)';
}
