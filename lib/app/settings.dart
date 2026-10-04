import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/domain.dart';

/// `SCREENS.md` section 6: the five settings, saved on the phone.

enum InputScriptSetting {
  automatic('Automatic', null),
  devanagari('Devanagari', Script.devanagari),
  iast('IAST', Script.iast),
  wx('WX', Script.wx),
  slp1('SLP1', Script.slp1),
  kyotoHarvard('Kyoto-Harvard', Script.kyotoHarvard),
  velthuis('Velthuis', Script.velthuis),
  itrans('ITRANS', Script.itrans);

  const InputScriptSetting(this.label, this.script);

  final String label;

  /// `null` for [automatic].
  final Script? script;
}

enum DisplayScriptSetting {
  devanagari('Devanagari', Script.devanagari),
  iast('IAST', Script.iast);

  const DisplayScriptSetting(this.label, this.script);

  final String label;
  final Script script;
}

enum LabelLanguage {
  sanskrit('Sanskrit'),
  english('English');

  const LabelLanguage(this.label);

  final String label;
}

/// How much of a sandhi the Join words screen shows (`SCREENS.md` 5.4):
/// the words and the letters that meet; then the name of the sandhi; then each
/// sūtra. Kept with the settings so it is remembered, but not a Settings page
/// row: it is chosen on that screen (the level is Sandhi-only for now).
enum LearnerLevel {
  basic('Basic'),
  intermediate('Intermediate'),
  advanced('Advanced');

  const LearnerLevel(this.label);

  final String label;
}

/// The settings model, exposed with `provider`. Every change is written to
/// the phone before listeners hear about it, and read back at the next start.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs) {
    inputScript = _read(InputScriptSetting.values, _kInputScript,
        InputScriptSetting.automatic);
    displayScript = _read(
        DisplayScriptSetting.values, _kDisplayScript, DisplayScriptSetting.iast);
    labelLanguage =
        _read(LabelLanguage.values, _kLabels, LabelLanguage.sanskrit);
    preferredEngine =
        _read(EngineId.values, _kEngine, EngineId.samsaadhanii);
    keepRecentInputs = _prefs.getBool(_kKeepRecent) ?? true;
    learnerLevel =
        _read(LearnerLevel.values, _kLearnerLevel, LearnerLevel.basic);
  }

  static const _kInputScript = 'settings.inputScript';
  static const _kDisplayScript = 'settings.displayScript';
  static const _kLabels = 'settings.labelLanguage';
  static const _kEngine = 'settings.preferredEngine';
  static const _kKeepRecent = 'settings.keepRecentInputs';
  static const _kLearnerLevel = 'settings.learnerLevel';

  final SharedPreferences _prefs;

  late InputScriptSetting inputScript;
  late DisplayScriptSetting displayScript;
  late LabelLanguage labelLanguage;
  late EngineId preferredEngine;
  late bool keepRecentInputs;
  late LearnerLevel learnerLevel;

  static Future<AppSettings> load([SharedPreferences? prefs]) async =>
      AppSettings._(prefs ?? await SharedPreferences.getInstance());

  /// A stored name that no longer exists falls back to the default.
  T _read<T extends Enum>(List<T> values, String key, T fallback) {
    final name = _prefs.getString(key);
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  Future<void> setInputScript(InputScriptSetting v) =>
      _setName(_kInputScript, v, () => inputScript = v);

  Future<void> setDisplayScript(DisplayScriptSetting v) =>
      _setName(_kDisplayScript, v, () => displayScript = v);

  Future<void> setLabelLanguage(LabelLanguage v) =>
      _setName(_kLabels, v, () => labelLanguage = v);

  Future<void> setPreferredEngine(EngineId v) =>
      _setName(_kEngine, v, () => preferredEngine = v);

  Future<void> setLearnerLevel(LearnerLevel v) =>
      _setName(_kLearnerLevel, v, () => learnerLevel = v);

  Future<void> setKeepRecentInputs(bool v) async {
    keepRecentInputs = v;
    await _prefs.setBool(_kKeepRecent, v);
    notifyListeners();
  }

  Future<void> _setName(String key, Enum v, VoidCallback apply) async {
    apply();
    await _prefs.setString(key, v.name);
    notifyListeners();
  }
}
