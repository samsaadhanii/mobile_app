import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_theme.dart';

/// A tappable outlined field that opens a searchable modal bottom sheet
/// for selecting a Sanskrit dhātu (verbal root).
///
/// Loads [assets/verblist.json] once and caches the result for the
/// lifetime of the app process.  Each entry has three fields:
///   • wx  — internal WX key returned by the API
///   • dev — Devanagari display string
///   • rom — Roman transliteration display string
///
/// [selectedWx] is the currently selected WX key.
/// [onChanged] is called with the new WX key when the user picks an entry.
class DhatuPicker extends StatefulWidget {
  const DhatuPicker({
    super.key,
    required this.selectedWx,
    required this.onChanged,
  });

  final String selectedWx;
  final ValueChanged<String> onChanged;

  @override
  State<DhatuPicker> createState() => _DhatuPickerState();
}

class _DhatuPickerState extends State<DhatuPicker> {
  // Module-level cache so the list is only decoded once per process.
  static List<Map<String, dynamic>>? _cache;

  List<Map<String, dynamic>> _verbList = [];

  @override
  void initState() {
    super.initState();
    if (_cache != null) {
      _verbList = _cache!;
    } else {
      _loadVerbs();
    }
  }

  Future<void> _loadVerbs() async {
    final raw = await rootBundle.loadString('assets/verblist.json');
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    _cache = list;
    if (mounted) setState(() => _verbList = list);
  }

  Map<String, dynamic>? get _current =>
      _verbList.where((e) => e['wx'] == widget.selectedWx).firstOrNull;

  Future<void> _showPicker() async {
    // Ensure data is loaded before opening the sheet.
    if (_verbList.isEmpty) {
      final raw = await rootBundle.loadString('assets/verblist.json');
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _cache = list;
      if (mounted) setState(() => _verbList = list);
    }
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _DhatuPickerSheet(
        verbList: _verbList,
        selectedWx: widget.selectedWx,
        onSelected: (wx) {
          widget.onChanged(wx);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;

    // Three states: still loading, loaded but no match, loaded with match.
    Widget entryContent;
    if (_verbList.isEmpty) {
      entryContent = Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Loading…',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      );
    } else if (current == null) {
      entryContent = Text(
        'Select a dhātu…',
        style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
      );
    } else {
      entryContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(current['dev']?.toString() ?? '', style: const TextStyle(fontSize: 15)),
          Text(
            current['rom']?.toString() ?? '',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      );
    }

    return InkWell(
      onTap: _showPicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Dhātu',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  entryContent,
                ],
              ),
            ),
            Icon(Icons.search, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}

// ── Modal bottom sheet ──────────────────────────────────────────────────────

class _DhatuPickerSheet extends StatefulWidget {
  const _DhatuPickerSheet({
    required this.verbList,
    required this.selectedWx,
    required this.onSelected,
  });

  final List<Map<String, dynamic>> verbList;
  final String selectedWx;
  final ValueChanged<String> onSelected;

  @override
  State<_DhatuPickerSheet> createState() => _DhatuPickerSheetState();
}

class _DhatuPickerSheetState extends State<_DhatuPickerSheet> {
  final _searchController = TextEditingController();
  late List<Map<String, dynamic>> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.verbList;
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? widget.verbList
          : widget.verbList.where((e) {
              return (e['dev']?.toString().toLowerCase().contains(query) ??
                      false) ||
                  (e['rom']?.toString().toLowerCase().contains(query) ??
                      false) ||
                  (e['wx']?.toString().toLowerCase().contains(query) ?? false);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Column(
        children: [
          // ── Drag handle ───────────────────────────────────────────────
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // ── Search field ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search dhātu…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: ListenableBuilder(
                  listenable: _searchController,
                  builder: (_, __) => _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _searchController.clear,
                        )
                      : const SizedBox.shrink(),
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          // ── Results list ──────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final entry = _filtered[i];
                final wx = entry['wx']?.toString() ?? '';
                final isSelected = wx == widget.selectedWx;
                return ListTile(
                  title: Text(entry['dev']?.toString() ?? ''),
                  subtitle: Text(
                    entry['rom']?.toString() ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: AppColors.primary.withAlpha(20),
                  selectedColor: AppColors.primary,
                  trailing: isSelected
                      ? Icon(Icons.check, color: AppColors.primary, size: 18)
                      : null,
                  onTap: () => widget.onSelected(wx),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}