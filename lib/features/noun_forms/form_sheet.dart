import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';
import '../analyse_word/feature_labels.dart';

/// The bottom sheet for a tapped form: the form, its case and number, and
/// what can be done with it. "Analyse this form" shows only when [onAnalyse]
/// is given. ("Why this form?" is not built in the first release.)
Future<void> showFormSheet(
  BuildContext context, {
  required SanskritText form,
  required FeatureValue vibhakti,
  required FeatureValue number,
  required AppSettings settings,
  required VoidCallback onDerive,
  VoidCallback? onAnalyse,
}) {
  final script = settings.displayScript.script;
  String label(FeatureValue v) => featureValueLabel(v,
      language: settings.labelLanguage, display: script);
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
                  Text('${label(vibhakti)} · ${label(number)}',
                      style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.format_list_numbered),
              title: const Text('Show derivation'),
              onTap: () {
                Navigator.pop(sheetContext);
                onDerive();
              },
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
