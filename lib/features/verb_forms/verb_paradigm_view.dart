import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../analyse_word/feature_labels.dart';
import 'lakara_table_view.dart';

/// Called when a form is tapped, with the pada it is in.
typedef OnTapPadaForm = void Function(FeatureValue pada, FeatureValue lakara,
    FeatureValue person, FeatureValue number, SanskritText form);

/// The result of Verb forms (`SCREENS.md` 5.4): the heading, a pada switch
/// (only when more than one pada has forms), a row of lakāra chips that
/// scrolls to a lakāra, and the lakāras as titled tables. [onKrt] adds the
/// link to the root's kṛt forms at the end.
class VerbParadigmView extends StatefulWidget {
  const VerbParadigmView({
    super.key,
    required this.paradigm,
    required this.settings,
    required this.onTapForm,
    this.onKrt,
  });

  final VerbParadigm paradigm;
  final AppSettings settings;
  final OnTapPadaForm onTapForm;
  final VoidCallback? onKrt;

  @override
  State<VerbParadigmView> createState() => _VerbParadigmViewState();
}

class _VerbParadigmViewState extends State<VerbParadigmView> {
  late FeatureValue _pada = widget.paradigm.padas.first.pada;
  final _keys = [for (final _ in lakaraOrder) GlobalKey()];

  @override
  void didUpdateWidget(VerbParadigmView old) {
    super.didUpdateWidget(old);
    // A new answer keeps the pada the user was on if it still has forms.
    if (widget.paradigm.pada(_pada) == null) {
      _pada = widget.paradigm.padas.first.pada;
    }
  }

  void _scrollTo(int i) {
    final context = _keys[i].currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(context,
        alignment: 0.0, duration: const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = widget.settings;
    final script = settings.displayScript.script;
    String label(FeatureValue v) => featureValueLabel(v,
        language: settings.labelLanguage, display: script);
    final padas = widget.paradigm.padas;
    final shown = widget.paradigm.pada(_pada) ?? padas.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(widget.paradigm.heading.display(script),
              key: const Key('verb-heading'),
              style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary)),
        ),
        if (padas.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SegmentedButton<FeatureValue>(
              key: const Key('pada-switch'),
              segments: [
                for (final p in padas)
                  ButtonSegment(value: p.pada, label: Text(label(p.pada))),
              ],
              selected: {shown.pada},
              onSelectionChanged: (s) => setState(() => _pada = s.first),
            ),
          ),
        SingleChildScrollView(
          key: const Key('lakara-chips'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < shown.lakaras.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(label(shown.lakaras[i].lakara),
                        style: const TextStyle(fontSize: 16)),
                    onPressed: () => _scrollTo(i),
                  ),
                ),
            ],
          ),
        ),
        for (var i = 0; i < shown.lakaras.length; i++)
          KeyedSubtree(
            key: _keys[i],
            child: LakaraTableView(
              table: shown.lakaras[i],
              settings: settings,
              onTapForm: (lakara, person, number, form) =>
                  widget.onTapForm(shown.pada, lakara, person, number, form),
            ),
          ),
        if (widget.onKrt != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextButton.icon(
              onPressed: widget.onKrt,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Kṛt forms of this root'),
            ),
          ),
      ],
    );
  }
}
