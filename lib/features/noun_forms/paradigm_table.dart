import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../task_frame/forms_table.dart';

/// Called when one form is tapped.
typedef OnTapForm = void Function(
    FeatureValue vibhakti, FeatureValue number, SanskritText form);

/// The noun table (`SCREENS.md` 5.4): eight vibhaktis by three numbers, with
/// short headings (`pra.`, `tṛ.`; `nom.`, `ins.`) whose full names go to screen
/// readers and the form sheet. A [FormsTable]: a grid when every form fits in
/// its third of the width, otherwise lines; it never scrolls sideways. A cell
/// with two forms shows both, one under the other, each tappable; an empty
/// cell shows a thin dash.
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
  Widget build(BuildContext context) => FormsTable(
        rows: vibhaktiOrder,
        columns: numberOrder,
        forms: paradigm.forms,
        settings: settings,
        onTapForm: onTapForm,
      );
}
