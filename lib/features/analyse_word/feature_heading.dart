import 'package:flutter/material.dart';

import '../../app/settings.dart';
import '../../domain/domain.dart';
import 'feature_labels.dart';

/// A table heading for a person or number: the short name (`pra.`, `eka.`,
/// `3rd`, `sg.`) so the tables fit a narrow phone, with the full name as the
/// heading's semantic label for screen readers. A value with no short name
/// shows its full name. Sanskrit text is never below 16 sp.
class FeatureHeading extends StatelessWidget {
  const FeatureHeading(
    this.value, {
    super.key,
    required this.settings,
    this.padding = const EdgeInsets.fromLTRB(6, 10, 8, 10),
  });

  final FeatureValue value;
  final AppSettings settings;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final script = settings.displayScript.script;
    final language = settings.labelLanguage;
    return Semantics(
      header: true,
      label: featureValueLabel(value, language: language, display: script),
      excludeSemantics: true,
      child: Padding(
        padding: padding,
        child: Text(
          featureValueLabel(value,
              language: language, display: script, short: true),
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary),
        ),
      ),
    );
  }
}
