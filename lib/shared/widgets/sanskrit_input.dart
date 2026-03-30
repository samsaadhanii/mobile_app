import 'package:flutter/material.dart';

/// A text-input widget for Sanskrit word entry.
///
/// Accepts both Devanagari and Roman-script input with no keyboard restriction.
/// Uses an outlined field with rounded corners (Material 3 style).
class SanskritInput extends StatelessWidget {
  const SanskritInput({
    super.key,
    required this.controller,
    required this.label,
    this.hint = '',
    this.onSubmitted,
  });

  final TextEditingController controller;

  /// Label shown inside the border (floating label).
  final String label;

  /// Optional placeholder shown when the field is empty.
  final String hint;

  /// Called when the user presses the keyboard action button.
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.text,
      textInputAction:
          onSubmitted != null ? TextInputAction.search : TextInputAction.done,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint.isEmpty ? null : hint,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}