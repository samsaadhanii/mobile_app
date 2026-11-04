import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../../shared/data/word_lists.dart';
import '../../shared/widgets/searchable_picker.dart' show PickerSuggestion;
import '../analyse_word/feature_labels.dart';
import 'engine_set.dart';
import 'input_parsing.dart';

/// "Did you mean …?" (tester's point 4): a tool that wants a stem or a root,
/// given an inflected word, runs Analyse a word on it and offers what it
/// finds. Only called after the tool itself found nothing.

/// The analyses of [word]: Samsaadhanii first, Heritage only if Samsaadhanii
/// gave no answer. Empty when neither did. The engines keep their answers for
/// the session, so asking again for the same word costs no request.
Future<List<Analysis>> analysesForSuggestion(
    EngineSet engines, SanskritText word) async {
  for (final id in engines.forTask(Task.analyseWord)) {
    final outcome = await engines[id]!.analyseWord(word);
    if (outcome is Found<WordAnalysis> && outcome.value.analyses.isNotEmpty) {
      return outcome.value.analyses;
    }
  }
  return const [];
}

/// Only plain letters make a headword or a stem; the engine's prefixed forms
/// (`Af_gam`, `}AgacCaw`) are not one.
final _plain = RegExp(r'^[A-Za-z]+$');

class LemmaSuggestion {
  const LemmaSuggestion(this.lemma, [this.gender]);

  final SanskritText lemma;

  /// The gender the analysis gave, for Noun forms.
  final FeatureValue? gender;
}

/// One row per distinct lemma. For the dictionary any lemma will do; for Noun
/// forms [nominal] keeps nouns and participles, one row for each gender.
List<LemmaSuggestion> lemmaSuggestions(List<Analysis> analyses,
    {required bool nominal}) {
  final seen = <String>{};
  final out = <LemmaSuggestion>[];
  for (final a in analyses) {
    if (!_plain.hasMatch(a.lemma.wx)) continue;
    FeatureValue? gender;
    if (nominal) {
      if (a.wordClass != WordClass.noun &&
          a.wordClass != WordClass.participle) {
        continue;
      }
      for (final f in a.features) {
        if (f.kind == FeatureKind.gender) gender = f.value;
      }
    }
    if (seen.add('${a.lemma.wx}|${gender?.name}')) {
      out.add(LemmaSuggestion(a.lemma, gender));
    }
  }
  return out;
}

/// The dhātus of [dhatus] that [analyses] come from, with the prefix when the
/// analysis has one that is in [prefixes]; an analysis names a root by its
/// lemma (verb) or its base (participle).
List<PickerSuggestion> rootSuggestions(
  List<Analysis> analyses, {
  required String typed,
  required DhatuList dhatus,
  required PrefixList prefixes,
  required Script display,
}) {
  String show(ListEntry e) => display == Script.devanagari ? e.dev : e.rom;
  final seen = <String>{};
  final out = <PickerSuggestion>[];
  for (final a in analyses) {
    final root = switch (a.wordClass) {
      WordClass.verb => a.base ?? a.lemma,
      WordClass.participle => a.base,
      _ => null,
    };
    if (root == null) continue;
    final prefixKey = a.prefix?.wx;
    final prefix = prefixKey == null ? null : prefixes.entryFor(prefixKey);
    for (final key in dhatus.keysFor(root.wx)) {
      if (!seen.add('$key|${prefix?.wx}')) continue;
      final entry = dhatus.entryFor(key)!;
      out.add(PickerSuggestion(
        key: key,
        prefix: prefix?.wx,
        title: '$typed → ${show(entry)}',
        subtitle: prefix == null ? null : 'with prefix ${show(prefix)}',
      ));
    }
  }
  return out;
}

/// What the dhātu picker asks when its search matches no root: analyses what
/// was typed and offers the roots found.
Future<List<PickerSuggestion>> suggestRoots({
  required String text,
  required EngineSet engines,
  required DhatuList dhatus,
  required PrefixList prefixes,
  required AppSettings settings,
}) async {
  final typed = firstWord(text);
  if (typed.isEmpty) return const [];
  final analyses =
      await analysesForSuggestion(engines, parseSanskrit(typed, settings));
  return rootSuggestions(analyses,
      typed: typed,
      dhatus: dhatus,
      prefixes: prefixes,
      display: settings.displayScript.script);
}

/// The "Did you mean:" rows under a not-found message, for Dictionary and Noun
/// forms. Shows nothing while it asks and nothing when the analysis finds
/// nothing, so the not-found state is as it was.
class DidYouMean extends StatefulWidget {
  const DidYouMean({
    super.key,
    required this.word,
    required this.engines,
    required this.nominal,
    required this.onChosen,
  });

  final SanskritText word;
  final EngineSet engines;

  /// Noun forms: nominal lemmas, with their gender.
  final bool nominal;
  final ValueChanged<LemmaSuggestion> onChosen;

  @override
  State<DidYouMean> createState() => _DidYouMeanState();
}

class _DidYouMeanState extends State<DidYouMean> {
  List<LemmaSuggestion> _rows = const [];

  @override
  void initState() {
    super.initState();
    _ask();
  }

  @override
  void didUpdateWidget(DidYouMean old) {
    super.didUpdateWidget(old);
    if (old.word != widget.word || old.nominal != widget.nominal) {
      _rows = const [];
      _ask();
    }
  }

  Future<void> _ask() async {
    final word = widget.word;
    final analyses = await analysesForSuggestion(widget.engines, word);
    if (!mounted || word != widget.word) return;
    setState(() =>
        _rows = lemmaSuggestions(analyses, nominal: widget.nominal));
  }

  @override
  Widget build(BuildContext context) {
    if (_rows.isEmpty) return const SizedBox.shrink();
    final settings = context.watch<AppSettings>();
    final theme = Theme.of(context);
    final script = settings.displayScript.script;
    return Column(
      key: const Key('did-you-mean'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Did you mean:', style: theme.textTheme.titleSmall),
        for (final r in _rows)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(r.lemma.display(script),
                style: const TextStyle(fontSize: 18)),
            subtitle: r.gender == null
                ? null
                : Text(
                    featureValueLabel(r.gender!,
                        language: settings.labelLanguage, display: script),
                    style: const TextStyle(fontSize: 16)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => widget.onChosen(r),
          ),
      ],
    );
  }
}
