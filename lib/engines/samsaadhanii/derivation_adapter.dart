import '../../domain/domain.dart';

/// The Aṣṭādhyāyī simulator (`simulation.cgi`). It answers with an HTML page
/// whose lines are separated by `<br>`; nothing outside this folder knows
/// that (ARCHITECTURE.md 8.2).

/// The server's WX names of the vibhaktis.
const _vibhaktiNames = {
  FeatureValue.nominative: 'praWamA',
  FeatureValue.accusative: 'xviwIyA',
  FeatureValue.instrumental: 'wqwIyA',
  FeatureValue.dative: 'cawurWI',
  FeatureValue.ablative: 'paFcamI',
  FeatureValue.genitive: 'RaRTI',
  FeatureValue.locative: 'sapwamI',
  FeatureValue.vocative: 'samboXana',
};

const _vacanaNames = {
  FeatureValue.singular: 'ekavacana',
  FeatureValue.dual: 'xvivacana',
  FeatureValue.plural: 'bahuvacana',
};

String? vibhaktiName(FeatureValue v) => _vibhaktiNames[v];

String? vacanaName(FeatureValue v) => _vacanaNames[v];

// `8-4-2(अट्कुप्वाङ्नुम्व्यवाये अपि)::::::::त्रिपादी`: number, the rule's text in
// brackets, and after the colons what the rule did.
final _stepLine = RegExp(r'^(\d+-\d+-\d+)\((.*)\)::::::::(.*)$');

// `::::::::6-1-87(आद् गुणः)::::::::`: a rule considered at this point, before
// the rule that applies (colons first, nothing after).
final _consideredLine = RegExp(r'^::::::::(\d+-\d+-\d+)\((.*)\)::::::::$');

final _body = RegExp(r'<body[^>]*>(.*?)(?:</body>|$)',
    caseSensitive: false, dotAll: true);
final _lineBreak = RegExp(r'<br\s*/?>', caseSensitive: false);
final _tag = RegExp(r'<[^>]*>');

/// Reads the page into steps. A line that starts a step opens it, and the
/// lines up to the next step are its state. A line that begins with the
/// colons names a rule that was considered before the next step; it is
/// attached to that step (a repeat once) and is neither a step nor state. A
/// page with no step at all is `NotFound`.
Outcome<Derivation> parseDerivation(String body, ResultSource source) {
  final inner = _body.firstMatch(body)?.group(1) ?? body;
  final lines = [
    for (final line in inner.split(_lineBreak))
      if (line.replaceAll(_tag, '').trim().isNotEmpty)
        line.replaceAll(_tag, '').trim(),
  ];

  final steps = <DerivationStep>[];
  var state = <String>[];
  ({String sutra, String text, String label, List<ConsideredRule> considered})?
      open;
  var pending = <ConsideredRule>[];

  void close() {
    final o = open;
    if (o != null) {
      steps.add(DerivationStep(
          sutra: o.sutra,
          sutraText: o.text,
          label: o.label,
          state: state,
          considered: o.considered));
    }
    state = <String>[];
  }

  for (final line in lines) {
    final m = _stepLine.firstMatch(line);
    if (m != null) {
      close();
      open = (
        sutra: m.group(1)!,
        text: m.group(2)!.trim(),
        label: m.group(3)!.trim(),
        considered: pending,
      );
      pending = <ConsideredRule>[];
    } else if (_consideredLine.firstMatch(line) case final c?) {
      final rule = ConsideredRule(c.group(1)!, c.group(2)!.trim());
      if (!pending.contains(rule)) pending.add(rule);
    } else if (line.startsWith('::::::::')) {
      continue;
    } else if (open != null) {
      state.add(line);
    }
  }
  close();

  if (steps.isEmpty) return const NotFound();

  // The last state line starts with the finished form: `रामेण(पद,अवसान)(...`.
  final last = steps.last.state.isEmpty ? '' : steps.last.state.last;
  final form = last.split('(').first.trim();
  return Found(Derivation(form, steps), source);
}
