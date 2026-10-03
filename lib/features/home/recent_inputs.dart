import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The last ten inputs, stored on the phone only.
class RecentInputs extends ChangeNotifier {
  RecentInputs._(this._prefs) : _items = _prefs.getStringList(_key) ?? [];

  static const _key = 'recent.inputs';
  static const maxItems = 10;

  final SharedPreferences _prefs;
  final List<String> _items;

  /// Newest first.
  List<String> get items => List.unmodifiable(_items);

  static Future<RecentInputs> load([SharedPreferences? prefs]) async =>
      RecentInputs._(prefs ?? await SharedPreferences.getInstance());

  /// Puts [text] at the top, once, keeping at most [maxItems].
  Future<void> add(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    _items
      ..remove(t)
      ..insert(0, t);
    if (_items.length > maxItems) _items.removeRange(maxItems, _items.length);
    await _prefs.setStringList(_key, _items);
    notifyListeners();
  }

  Future<void> clear() async {
    _items.clear();
    await _prefs.remove(_key);
    notifyListeners();
  }
}
