import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_palette.dart';

/// Holds and persists the user's appearance choices: which colour [palette] is
/// active and the light/dark [themeMode]. Both default to the app's originals
/// (Emerald & Gold, follow-system) so nothing changes until the user picks.
class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs) {
    _palette = AppPalettes.byId(_prefs.getString(_kPalette));
    _mode = _modeFromName(_prefs.getString(_kMode));
    _patternsEnabled = _prefs.getBool(_kPatterns) ?? true;
  }

  final SharedPreferences _prefs;
  static const _kPalette = 'theme_palette';
  static const _kMode = 'theme_mode';
  static const _kPatterns = 'theme_patterns';

  AppPalette _palette = AppPalettes.fallback;
  ThemeMode _mode = ThemeMode.system;
  bool _patternsEnabled = true;

  AppPalette get palette => _palette;
  ThemeMode get themeMode => _mode;

  /// Whether the subtle geometric pattern is drawn on hero surfaces.
  bool get patternsEnabled => _patternsEnabled;

  Future<void> setPalette(AppPalette palette) async {
    if (palette.id == _palette.id) return;
    _palette = palette;
    notifyListeners();
    await _prefs.setString(_kPalette, palette.id);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _prefs.setString(_kMode, mode.name);
  }

  Future<void> setPatternsEnabled(bool value) async {
    if (value == _patternsEnabled) return;
    _patternsEnabled = value;
    notifyListeners();
    await _prefs.setBool(_kPatterns, value);
  }

  static ThemeMode _modeFromName(String? name) {
    switch (name) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
