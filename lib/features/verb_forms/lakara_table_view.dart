import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../analyse_word/feature_labels.dart';
import '../task_frame/forms_table.dart';

/// Called when one form is tapped.
typedef OnTapVerbForm = void Function(
    FeatureValue lakara, FeatureValue person, FeatureValue number, SanskritText form);

/// One lakāra as a titled table: three persons by three numbers, the headings
/// the short names (`pra.`, `eka.`) with the full names for screen readers. A
/// [FormsTable]: a grid when every form fits in its third of the width,
/// otherwise lines; it never scrolls sideways. This table chooses on its own,
/// so on one page laṭ can be a grid and a causative perfect lines.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
          child: Text(
              featureValueLabel(table.lakara,
                  language: settings.labelLanguage,
                  display: settings.displayScript.script),
              key: Key('lakara-${table.lakara.name}'),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontSize: 18, fontWeight: FontWeight.w600)),
        ),
        FormsTable(
          rows: personOrder,
          columns: numberOrder,
          forms: table.forms,
          settings: settings,
          onTapForm: (person, number, form) =>
              onTapForm(table.lakara, person, number, form),
        ),
      ],
    );
  }
}
