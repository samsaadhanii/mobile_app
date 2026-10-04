import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../analyse_word/feature_labels.dart';

/// Called when one form is tapped.
typedef OnTapVerbForm = void Function(
    FeatureValue lakara, FeatureValue person, FeatureValue number, SanskritText form);

/// One lakāra as a titled table: three persons by three numbers, the headings
/// from `FeatureValue` in the label language and display script. A cell with
/// alternatives shows them one under the other, each tappable; an empty cell
/// is a muted dash. The table is as wide as its forms need and scrolls
/// sideways on a narrow phone, so no form is broken mid-word.
class LakaraTableView extends StatelessWidget {
  const LakaraTableView({
    super.key,
    required this.table,
    required this.settings,
    required this.onTapForm,
  });

  final LakaraTable table;
  final AppSettings settings;
  final OnTapVerbForm onTapForm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final script = settings.displayScript.script;
    final language = settings.labelLanguage;
    final muted = theme.colorScheme.onSurfaceVariant;
    // Sanskrit text is never smaller than 16 sp.
    const sanskrit = TextStyle(fontSize: 16);
    String label(FeatureValue v) =>
        featureValueLabel(v, language: language, display: script);

    Widget heading(FeatureValue v) => Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
          child: Text(label(v),
              style: sanskrit.copyWith(
                  fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
        );

    Widget cell(FeatureValue person, FeatureValue number) {
      final forms = table.forms(person, number);
      if (forms.isEmpty) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
          child: Text('–', style: sanskrit.copyWith(color: muted)),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final form in forms)
            InkWell(
              onTap: () => onTapForm(table.lakara, person, number, form),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
                child: Text(form.display(script), style: sanskrit),
              ),
            ),
        ],
      );
    }

    final line = BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
          child: Text(label(table.lakara),
              key: Key('lakara-${table.lakara.name}'),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
        ),
        LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                border: TableBorder(horizontalInside: line, bottom: line),
                children: [
                  TableRow(children: [
                    const SizedBox.shrink(),
                    for (final n in numberOrder) heading(n),
                  ]),
                  for (final p in personOrder)
                    TableRow(children: [
                      heading(p),
                      for (final n in numberOrder) cell(p, n),
                    ]),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
