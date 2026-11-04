import 'package:flutter/material.dart';

import 'dart:async';

import '../../sanskrit/script.dart' show Script;
import '../data/word_lists.dart';

/// A row offered when a search matches nothing: [key] is the entry it stands
/// for, [prefix] a second thing it selects with it (a prefix key), if any.
class PickerSuggestion {
  const PickerSuggestion(
      {required this.key, required this.title, this.subtitle, this.prefix});

  final String key;
  final String title;
  final String? subtitle;
  final String? prefix;
}

/// A tappable outlined field that opens a searchable bottom sheet of
/// [ListEntry] rows. Each row shows the entry in the display [script]
/// (Devanagari or roman) with the other form under it; colours come from the
/// theme, so it reads in light and dark. Sanskrit text is never below 16 sp.
///
/// With [noneLabel], a first row of that name stands for "nothing selected"
/// (value `''`), as "No prefix" does.
class SearchablePicker extends StatelessWidget {
  const SearchablePicker({
    super.key,
    required this.label,
    required this.entries,
    required this.selected,
    required this.onChanged,
    required this.script,
    required this.placeholder,
    this.loading = false,
    this.noneLabel,
    this.searchHint = 'Search…',
    this.suggest,
    this.onSuggested,
  });

  final String label;
  final List<ListEntry> entries;

  /// The selected key, or null / `''` for none.
  final String? selected;
  final ValueChanged<String> onChanged;
  final Script script;
  final String placeholder;
  final bool loading;
  final String? noneLabel;
  final String searchHint;

  /// Asked, once the user stops typing, when the search text matches no entry:
  /// what else it might mean. With [onSuggested] for the tapped row.
  final Future<List<PickerSuggestion>> Function(String text)? suggest;
  final ValueChanged<PickerSuggestion>? onSuggested;

  bool get _noneSelected => selected == null || selected!.isEmpty;

  ListEntry? get _current {
    for (final e in entries) {
      if (e.wx == selected) return e;
    }
    return null;
  }

  String _primary(ListEntry e) =>
      script == Script.devanagari ? e.dev : e.rom;

  String _secondary(ListEntry e) =>
      script == Script.devanagari ? e.rom : e.dev;

  Future<void> _open(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _PickerSheet(
        entries: entries,
        selected: selected,
        noneLabel: noneLabel,
        searchHint: searchHint,
        suggest: onSuggested == null ? null : suggest,
        onSuggested: (s) {
          Navigator.pop(sheetContext);
          onSuggested?.call(s);
        },
        primary: _primary,
        secondary: _secondary,
        onSelected: (key) {
          Navigator.pop(sheetContext);
          onChanged(key);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    final Widget content;
    final current = _current;
    if (loading) {
      content = Row(children: [
        const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 8),
        Text('Loading…', style: TextStyle(fontSize: 16, color: muted)),
      ]);
    } else if (_noneSelected && noneLabel != null) {
      content = Text(noneLabel!, style: const TextStyle(fontSize: 16));
    } else if (current == null) {
      content = Text(placeholder, style: TextStyle(fontSize: 16, color: muted));
    } else {
      content = Text(_primary(current),
          style: const TextStyle(fontSize: 16),
          maxLines: 2,
          overflow: TextOverflow.ellipsis);
    }

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: loading ? null : () => _open(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: muted)),
                    const SizedBox(height: 2),
                    content,
                  ],
                ),
              ),
              Icon(Icons.search, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({
    required this.entries,
    required this.selected,
    required this.noneLabel,
    required this.searchHint,
    this.suggest,
    this.onSuggested,
    required this.primary,
    required this.secondary,
    required this.onSelected,
  });

  final List<ListEntry> entries;
  final String? selected;
  final String? noneLabel;
  final String searchHint;
  final Future<List<PickerSuggestion>> Function(String text)? suggest;
  final ValueChanged<PickerSuggestion>? onSuggested;
  final String Function(ListEntry) primary;
  final String Function(ListEntry) secondary;
  final ValueChanged<String> onSelected;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  final _search = TextEditingController();
  late List<ListEntry> _filtered = widget.entries;

  /// What the search might mean when it matches nothing: asked for after a
  /// short pause, never before.
  List<PickerSuggestion>? _suggestions;
  bool _asking = false;
  Timer? _pause;
  int _asked = 0;

  @override
  void dispose() {
    _pause?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String text) {
    final q = text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.entries
          : [
              for (final e in widget.entries)
                if (e.searchKey.contains(q)) e,
            ];
    });
    _pause?.cancel();
    final mine = ++_asked;
    _suggestions = null;
    _asking = false;
    if (widget.suggest == null || q.isEmpty || _filtered.isNotEmpty) return;
    _pause = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted || mine != _asked) return;
      setState(() => _asking = true);
      List<PickerSuggestion> found;
      try {
        found = await widget.suggest!(text.trim());
      } catch (_) {
        found = const [];
      }
      if (!mounted || mine != _asked) return;
      setState(() {
        _suggestions = found;
        _asking = false;
      });
    });
  }

  bool get _showNone {
    final none = widget.noneLabel;
    if (none == null) return false;
    final q = _search.text.trim().toLowerCase();
    return q.isEmpty || none.toLowerCase().contains(q);
  }

  Widget _suggestionList(ThemeData theme, Color muted) {
    final rows = _suggestions ?? const <PickerSuggestion>[];
    if (_asking) {
      return const Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return ListView(
      key: const Key('picker-suggestions'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Text('Did you mean:', style: theme.textTheme.titleSmall),
        ),
        for (final s in rows)
          ListTile(
            title: Text(s.title, style: const TextStyle(fontSize: 16)),
            subtitle: s.subtitle == null
                ? null
                : Text(s.subtitle!,
                    style: TextStyle(fontSize: 16, color: muted)),
            onTap: () => widget.onSuggested!(s),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final none = _showNone ? 1 : 0;
    final noneSelected = widget.selected == null || widget.selected!.isEmpty;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _search,
              autofocus: true,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          _onSearch('');
                        },
                      ),
              ),
            ),
          ),
          if (_filtered.isEmpty && (_asking || _suggestions != null))
            Expanded(child: _suggestionList(theme, muted))
          else
          Expanded(
            child: ListView.builder(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              controller: scrollController,
              itemCount: _filtered.length + none,
              itemBuilder: (context, i) {
                if (none == 1 && i == 0) {
                  return ListTile(
                    title: Text(widget.noneLabel!,
                        style: const TextStyle(fontSize: 16)),
                    selected: noneSelected,
                    trailing: noneSelected ? const Icon(Icons.check) : null,
                    onTap: () => widget.onSelected(''),
                  );
                }
                final e = _filtered[i - none];
                final isSelected = e.wx == widget.selected;
                final second = widget.secondary(e);
                return ListTile(
                  title: Text(widget.primary(e),
                      style: const TextStyle(fontSize: 16)),
                  subtitle: second.isEmpty
                      ? null
                      : Text(second,
                          style: TextStyle(fontSize: 16, color: muted)),
                  selected: isSelected,
                  trailing: isSelected ? const Icon(Icons.check) : null,
                  onTap: () => widget.onSelected(e.wx),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
