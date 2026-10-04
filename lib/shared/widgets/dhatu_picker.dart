import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/settings.dart';
import '../data/word_lists.dart';
import 'searchable_picker.dart';

/// A tappable field that opens a searchable sheet of the dhātus in
/// `assets/verblist.json` (a [DhatuList] from the app). Rows follow the
/// display script and the theme.
///
/// [selectedWx] is the selected key (empty for none); [onChanged] gets the key
/// of the picked entry.
class DhatuPicker extends StatelessWidget {
  const DhatuPicker({
    super.key,
    required this.selectedWx,
    required this.onChanged,
  });

  final String selectedWx;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final list = context.watch<DhatuList>();
    final script = context.watch<AppSettings>().displayScript.script;
    return SearchablePicker(
      label: 'Dhātu',
      placeholder: 'Select a dhātu…',
      searchHint: 'Search dhātu…',
      entries: list.entries,
      loading: !list.loaded,
      selected: selectedWx,
      script: script,
      onChanged: onChanged,
    );
  }
}
