import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../analyse_word/feature_heading.dart';

/// Called when one form is tapped.
typedef OnTapForm = void Function(
    FeatureValue vibhakti, FeatureValue number, SanskritText form);

/// The noun table (`SCREENS.md` 5.4): eight vibhaktis by three numbers, the
/// headings from `FeatureValue` in the label language and display script. A
/// cell with two forms shows both, one under the other, each tappable; an
/// empty cell shows a thin dash. The table is as wide as its forms need and
/// scrolls sideways on a narrow phone, so no form is ever broken mid-word.
class ParadigmTable extends StatelessWidget {
  const ParadigmTable({
    super.key,
    required this.paradigm,
    required this.settings,
    required this.onTapForm,
  });

  final NounParadigm paradigm;
  final AppSettings settings;
  final OnTapForm onTapForm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final script = settings.displayScript.script;
    final muted = theme.colorScheme.onSurfaceVariant;
    // Sanskrit text is never smaller than 16 sp.
    const sanskrit = TextStyle(fontSize: 16);

    // The case names stay in full (they are the row headings and have no
    // short form); the numbers are short, so the table fits a narrow phone.
    Widget heading(FeatureValue v) => FeatureHeading(v, settings: settings);

    Widget cell(FeatureValue vibhakti, FeatureValue number) {
      final forms = paradigm.forms(vibhakti, number);
      if (forms.isEmpty) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(6, 10, 8, 10),
          child: Text('–', style: sanskrit.copyWith(color: muted)),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final form in forms)
            InkWell(
              onTap: () => onTapForm(vibhakti, number, form),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 10, 8, 10),
                child: Text(form.display(script), style: sanskrit),
              ),
            ),
        ],
      );
    }

    final line = BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5);
    return LayoutBuilder(
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
              for (final v in vibhaktiOrder)
                TableRow(children: [
                  heading(v),
                  for (final n in numberOrder) cell(v, n),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}
