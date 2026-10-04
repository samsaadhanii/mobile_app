import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../analyse_word/feature_heading.dart';
import '../analyse_word/feature_labels.dart';

/// Called when one form is tapped.
typedef OnTapFormCell = void Function(
    FeatureValue row, FeatureValue column, SanskritText form);

/// The forms of a table of rows by columns (cases or persons by the three
/// numbers), laid out so that **it never scrolls sideways and never breaks a
/// word**. The table picks its own layout by measuring what it has to show:
///
/// - a **grid** when the columns, each as wide as its widest form at 16 sp, fit
///   the width together with the row headings (so a table whose forms all fit
///   in a third of the width is always a grid, and so is one whose short
///   columns leave room for a long one);
/// - otherwise **lines**: each row is a small block, a heading and under it the
///   three numbers as three labelled lines, the short number name in muted
///   text and then the form, with the whole width to itself. Alternatives in a
///   cell go on separate lines under the same label.
///
/// The layout is chosen per table, so one lakāra can be a grid while the
/// causative perfect on the same page is lines; within a table it is never
/// mixed. The row and column headings are short names, with the full names as
/// the semantic labels.
class FormsTable extends StatelessWidget {
  const FormsTable({
    super.key,
    required this.rows,
    required this.columns,
    required this.forms,
    required this.settings,
    required this.onTapForm,
  });

  final List<FeatureValue> rows;
  final List<FeatureValue> columns;

  /// The forms in one cell; empty for an empty cell.
  final List<SanskritText> Function(FeatureValue row, FeatureValue column) forms;
  final AppSettings settings;
  final OnTapFormCell onTapForm;

  /// Horizontal padding of a grid cell, left and right.
  static const _cellPadding = EdgeInsets.fromLTRB(6, 10, 8, 10);

  static double _width(String text, TextStyle style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final script = settings.displayScript.script;
    final language = settings.labelLanguage;
    final base = DefaultTextStyle.of(context).style;
    final scaler = MediaQuery.textScalerOf(context);
    // Sanskrit text is never smaller than 16 sp.
    final formStyle = base.merge(const TextStyle(fontSize: 16));
    final headingStyle =
        formStyle.merge(const TextStyle(fontWeight: FontWeight.w600));

    String short(FeatureValue v) => featureValueLabel(v,
        language: language, display: script, short: true);

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final padding = _cellPadding.horizontal;

      // The first column holds the row headings; each other column is as
      // wide as its widest form or heading. They fit, with a dp to spare for
      // rounding, or the table is lines.
      final headingWidth = rows
              .map((r) => _width(short(r), headingStyle, scaler))
              .fold<double>(0, math.max) +
          padding;
      var needed = headingWidth;
      for (final c in columns) {
        var widest = _width(short(c), headingStyle, scaler);
        for (final r in rows) {
          for (final form in forms(r, c)) {
            widest = math.max(
                widest, _width(form.display(script), formStyle, scaler));
          }
        }
        needed += widest + padding;
      }
      final fits = width.isFinite && needed + 1 <= width;

      return fits
          ? _Grid(table: this)
          : _Lines(table: this, labelStyle: headingStyle, scaler: scaler);
    });
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.table});

  final FormsTable table;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = table.settings;
    final script = settings.displayScript.script;
    final muted = theme.colorScheme.onSurfaceVariant;
    const sanskrit = TextStyle(fontSize: 16);

    Widget cell(FeatureValue row, FeatureValue column) {
      final forms = table.forms(row, column);
      if (forms.isEmpty) {
        return Padding(
          padding: FormsTable._cellPadding,
          child: Text('–', style: sanskrit.copyWith(color: muted)),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final form in forms)
            InkWell(
              onTap: () => table.onTapForm(row, column, form),
              child: Padding(
                padding: FormsTable._cellPadding,
                child: Text(form.display(script), style: sanskrit),
              ),
            ),
        ],
      );
    }

    final line = BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5);
    return Table(
      key: const Key('forms-grid'),
      // Each column as wide as its content; what is left over is shared.
      columnWidths: {
        0: IntrinsicColumnWidth(),
        for (var i = 1; i <= table.columns.length; i++)
          i: const IntrinsicColumnWidth(flex: 1),
      },
      border: TableBorder(horizontalInside: line, bottom: line),
      children: [
        TableRow(children: [
          const SizedBox.shrink(),
          for (final c in table.columns)
            FeatureHeading(c,
                settings: settings, padding: FormsTable._cellPadding),
        ]),
        for (final r in table.rows)
          TableRow(children: [
            FeatureHeading(r,
                settings: settings, padding: FormsTable._cellPadding),
            for (final c in table.columns) cell(r, c),
          ]),
      ],
    );
  }
}

class _Lines extends StatelessWidget {
  const _Lines(
      {required this.table, required this.labelStyle, required this.scaler});

  final FormsTable table;
  final TextStyle labelStyle;
  final TextScaler scaler;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = table.settings;
    final script = settings.displayScript.script;
    final language = settings.labelLanguage;
    final muted = theme.colorScheme.onSurfaceVariant;
    const sanskrit = TextStyle(fontSize: 16);

    String full(FeatureValue v) =>
        featureValueLabel(v, language: language, display: script);
    String short(FeatureValue v) =>
        featureValueLabel(v, language: language, display: script, short: true);

    // The number names line up: one label column as wide as the longest.
    final labelWidth = table.columns
            .map((c) => FormsTable._width(short(c), labelStyle, scaler))
            .fold<double>(0, math.max) +
        14;

    Widget line(FeatureValue row, FeatureValue column) {
      final forms = table.forms(row, column);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Semantics(
              label: full(column),
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(short(column),
                    style: sanskrit.copyWith(color: muted)),
              ),
            ),
          ),
          Expanded(
            child: forms.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('–', style: sanskrit.copyWith(color: muted)),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final form in forms)
                        InkWell(
                          onTap: () => table.onTapForm(row, column, form),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(form.display(script), style: sanskrit),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      );
    }

    final divider = Divider(
        height: 1, thickness: 0.5, color: theme.colorScheme.outlineVariant);
    return Column(
      key: const Key('forms-lines'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in table.rows) ...[
          FeatureHeading(r,
              settings: settings,
              padding: const EdgeInsets.fromLTRB(6, 10, 8, 2)),
          Padding(
            padding: const EdgeInsets.only(left: 14, bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final c in table.columns) line(r, c)],
            ),
          ),
          divider,
        ],
      ],
    );
  }
}
