import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/settings.dart';
import '../../features/analyse_word/feature_labels.dart';
import '../data/word_lists.dart';
import 'searchable_picker.dart';

/// A tappable field that opens a searchable sheet of the prefixes in
/// `assets/prefix_list.json` (a [PrefixList] from the app), "No prefix"
/// first, each row in Devanagari and roman. It replaces version 1's free-text
/// field, where the user had to type a WX code such as `Af`.
///
/// [selected] is the prefix key, or null for none; [onChanged] gets the key,
/// or null when "No prefix" is picked.
class PrefixPicker extends StatelessWidget {
  const PrefixPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final list = context.watch<PrefixList>();
    final settings = context.watch<AppSettings>();
    final script = settings.displayScript.script;
    return SearchablePicker(
      label: toolFieldLabel(ToolField.upasarga,
          language: settings.labelLanguage, display: script),
      placeholder: 'Select…',
      searchHint: 'Search prefix…',
      noneLabel: 'None',
      entries: list.entries,
      loading: !list.loaded,
      selected: selected,
      script: script,
      onChanged: (key) => onChanged(key.isEmpty ? null : key),
    );
  }
}
