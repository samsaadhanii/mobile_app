import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../../sanskrit/transliteration.dart' show convert;
import '../analyse_word/feature_labels.dart';

/// Called when a form is tapped: the group it is in, and its gender (null for
/// an indeclinable).
typedef OnTapKrtForm = void Function(
    KrtGroup group, FeatureValue? gender, SanskritText form);

/// The suffix name of a group in the display script, then the lakāra and
/// prayoga its label carries in the label language: `śānac · laṭ · karmaṇi`.
String krtGroupTitle(KrtGroup g, AppSettings settings) {
  final script = settings.displayScript.script;
  String label(FeatureValue v) => featureValueLabel(v,
      language: settings.labelLanguage, display: script);
  return [
    g.pratyaya.display(script),
    if (g.lakara != null) label(g.lakara!),
    if (g.prayoga != null) label(g.prayoga!),
  ].join(' · ');
}

/// One kṛt suffix and its forms: the name, then three gendered cells side by
/// side (they wrap onto a second line on a narrow phone, so no form is broken
/// and nothing scrolls sideways) or the one indeclinable cell. An empty group
/// is shown muted, not hidden, so the list reads the same for every root.
class KrtGroupView extends StatelessWidget {
  const KrtGroupView({
    super.key,
    required this.group,
    required this.settings,
    required this.onTapForm,
  });

  final KrtGroup group;
  final AppSettings settings;
  final OnTapKrtForm onTapForm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final script = settings.displayScript.script;
    final muted = theme.colorScheme.onSurfaceVariant;
    final empty = group.isEmpty;
    // Sanskrit text is never smaller than 16 sp.
    const sanskrit = TextStyle(fontSize: 16);

    Widget forms(List<SanskritText> list, FeatureValue? gender) {
      if (list.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text('–', style: sanskrit.copyWith(color: muted)),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final form in list)
            InkWell(
              onTap: () => onTapForm(group, gender, form),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(form.display(script), style: sanskrit),
              ),
            ),
        ],
      );
    }

    return Padding(
      key: Key('krt-${group.label}'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            krtGroupTitle(group, settings),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: empty ? muted : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          if (group.isIndeclinable)
            forms(group.indeclinable, null)
          else
            Wrap(
              spacing: 20,
              runSpacing: 4,
              children: [
                for (final gender in krtGenders)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 84),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          label: featureValueLabel(gender,
                              language: settings.labelLanguage, display: script),
                          excludeSemantics: true,
                          child: Text(
                            featureValueLabel(gender,
                                language: settings.labelLanguage,
                                display: script,
                                short: true),
                            style: sanskrit.copyWith(color: muted),
                          ),
                        ),
                        forms(group.forms(gender), gender),
                      ],
                    ),
                  ),
              ],
            ),
          const Divider(height: 1, thickness: 0.5),
        ],
      ),
    );
  }
}

/// The line under the result about the suffix names: when the app corrected
/// them, "Suffix names corrected by the app." and, on tapping it, each suffix
/// that was relabelled with the name the engine sent; when it could not check
/// them, one visible line saying so.
class KrtLabelsNote extends StatefulWidget {
  const KrtLabelsNote({super.key, required this.forms, required this.settings});

  final KrtForms forms;
  final AppSettings settings;

  @override
  State<KrtLabelsNote> createState() => _KrtLabelsNoteState();
}

class _KrtLabelsNoteState extends State<KrtLabelsNote> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final script = widget.settings.displayScript.script;

    switch (widget.forms.labels) {
      case KrtLabels.asSent:
        return const SizedBox.shrink();
      case KrtLabels.unverified:
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_outlined,
                  size: 18, color: theme.colorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Suffix names could not be checked against the expected list.",
                  key: const Key('krt-unverified'),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
        );
      case KrtLabels.corrected:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            InkWell(
              key: const Key('krt-corrected'),
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Suffix names corrected by the app.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: muted)),
                    ),
                    Icon(_open ? Icons.expand_less : Icons.expand_more,
                        size: 18, color: muted),
                  ],
                ),
              ),
            ),
            if (_open) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('Samsaadhanii sent  →  shown',
                    style: theme.textTheme.labelMedium?.copyWith(color: muted)),
              ),
              for (final g in widget.forms.groups.where((g) => g.wasRelabelled))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${convert(g.sentLabel, Script.iast, script)}  →  '
                    '${convert(g.label, Script.iast, script)}',
                    style: TextStyle(fontSize: 16, color: muted),
                  ),
                ),
            ],
          ],
        );
    }
  }
}
