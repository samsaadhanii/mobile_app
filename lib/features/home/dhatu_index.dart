import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The dhātus in `assets/verblist.json`, for the Home suggestions. A key is
/// `gam1_gamLz_BvAxiH_gawO`: the root with a homonym number, the root with its
/// markers, the gaṇa, the meaning. A word counts as a dhātu if it equals the
/// first part without its number (`gam`) or the second part (`gamLz`).
class DhatuIndex extends ChangeNotifier {
  DhatuIndex();

  DhatuIndex.fromKeys(Iterable<String> keys) {
    _add(keys);
    _loaded = true;
  }

  final Set<String> _roots = {};
  bool _loaded = false;

  bool get loaded => _loaded;

  /// Is [wx] a dhātu in the bundled list?
  bool contains(String wx) => _roots.contains(wx);

  Future<void> load([AssetBundle? bundle]) async {
    final text =
        await (bundle ?? rootBundle).loadString('assets/verblist.json');
    final list = (jsonDecode(text) as List).cast<Map<String, dynamic>>();
    _add(list.map((e) => e['wx'] as String));
    _loaded = true;
    notifyListeners();
  }

  void _add(Iterable<String> keys) {
    for (final key in keys) {
      final parts = key.split('_');
      if (parts.isEmpty || parts.first.isEmpty) continue;
      _roots.add(parts.first.replaceAll(RegExp(r'\d+$'), ''));
      if (parts.length > 1 && parts[1].isNotEmpty) _roots.add(parts[1]);
    }
  }
}
