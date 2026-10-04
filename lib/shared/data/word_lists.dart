import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One row of a bundled list: the server's WX key, the Devanagari and the
/// roman (IAST) display forms.
class ListEntry {
  final String wx;
  final String dev;
  final String rom;

  /// Lower-case text the pickers search in.
  final String searchKey;

  ListEntry(this.wx, this.dev, this.rom)
      : searchKey = '$dev $rom $wx'.toLowerCase();

  factory ListEntry.fromJson(Map<String, dynamic> json) => ListEntry(
        json['wx'].toString(),
        json['dev']?.toString() ?? '',
        json['rom']?.toString() ?? '',
      );
}

/// A list read from an asset once and kept for the life of the app, for the
/// root and prefix pickers and for turning a typed root into its key.
abstract class AssetList extends ChangeNotifier {
  AssetList(this._asset);

  AssetList.fromEntries(Iterable<ListEntry> entries) : _asset = '' {
    _entries = List.unmodifiable(entries);
    _loaded = true;
  }

  final String _asset;
  List<ListEntry> _entries = const [];
  bool _loaded = false;

  bool get loaded => _loaded;
  List<ListEntry> get entries => _entries;

  Future<void> load([AssetBundle? bundle]) async {
    final text = await (bundle ?? rootBundle).loadString(_asset);
    _entries = List.unmodifiable([
      for (final e in (jsonDecode(text) as List).cast<Map<String, dynamic>>())
        ListEntry.fromJson(e),
    ]);
    _loaded = true;
    notifyListeners();
  }
}

/// The dhātus of `assets/verblist.json`. A key is `gam1_gamLz_BvAxiH_gawO`:
/// the root with a homonym number, the root with its markers, the gaṇa, the
/// meaning.
class DhatuList extends AssetList {
  DhatuList() : super('assets/verblist.json');
  DhatuList.fromEntries(super.entries) : super.fromEntries();

  /// The keys a typed root can mean, best first: the key itself, then the
  /// roots whose first part without its number (`gam`) or second part
  /// (`gamLz`) is [wx]. Empty when [wx] is not a dhātu of the list.
  List<String> keysFor(String wx) {
    if (wx.isEmpty) return const [];
    final exact = [
      for (final e in _entries)
        if (e.wx == wx) e.wx,
    ];
    if (exact.isNotEmpty) return exact;
    return [
      for (final e in _entries)
        if (_rootsOf(e.wx).contains(wx)) e.wx,
    ];
  }

  static Set<String> _rootsOf(String key) {
    final parts = key.split('_');
    return {
      if (parts.isNotEmpty) parts.first.replaceAll(RegExp(r'\d+$'), ''),
      if (parts.length > 1) parts[1],
    };
  }

  /// The entry for a key, or null.
  ListEntry? entryFor(String key) {
    for (final e in _entries) {
      if (e.wx == key) return e;
    }
    return null;
  }
}

/// The prefixes of `assets/prefix_list.json`: `Af`, `pra`, `aXi_ava`.
class PrefixList extends AssetList {
  PrefixList() : super('assets/prefix_list.json');
  PrefixList.fromEntries(super.entries) : super.fromEntries();

  ListEntry? entryFor(String key) {
    for (final e in _entries) {
      if (e.wx == key) return e;
    }
    return null;
  }
}
