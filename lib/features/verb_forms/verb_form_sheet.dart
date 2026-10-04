import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../analyse_word/feature_labels.dart';

/// The bottom sheet for a tapped verb form: the form, its pada, lakāra,
/// person and number, and "Analyse this form" when the caller can open tools.
Future<void> showVerbFormSheet(
  BuildContext context, {
  required SanskritText form,
  required FeatureValue pada,
  required FeatureValue lakara,
  required FeatureValue person,
  required FeatureValue number,
  required AppSettings settings,
  VoidCallback? onAnalyse,
}) {
  final script = settings.displayScript.script;
  String label(FeatureValue v) =>
      featureValueLabel(v, language: settings.labelLanguage, display: script);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(form.display(script),
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                      '${label(pada)} · ${label(lakara)} · ${label(person)} · '
                      '${label(number)}',
                      style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (onAnalyse != null)
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Analyse this form'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onAnalyse();
                },
              ),
          ],
        ),
      );
    },
  );
}
