import 'package:flutter/material.dart';

/// One thing the user can do with a form from [showFormSheet].
class FormSheetAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const FormSheetAction(this.icon, this.label, this.onTap);
}

/// The bottom sheet for a tapped form, shared by Noun forms, Verb forms and
/// Kṛt forms: the form large, a [description] under it (its case and number,
/// its pada, lakāra and person, ...), and a list of actions. Choosing an action
/// closes the sheet and then runs it. The texts are already in the display
/// script and label language: the sheet converts nothing.
Future<void> showFormSheet(
  BuildContext context, {
  required String form,
  required String description,
  required List<FormSheetAction> actions,
}) {
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
                  // Sanskrit text is never below 16 sp.
                  Text(form,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w600)),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(description,
                        style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
            for (final action in actions)
              ListTile(
                leading: Icon(action.icon),
                title: Text(action.label),
                onTap: () {
                  Navigator.pop(sheetContext);
                  action.onTap();
                },
              ),
          ],
        ),
      );
    },
  );
}
