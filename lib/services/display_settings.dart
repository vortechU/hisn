import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/arabic_fonts.dart';
import '../theme/reading_theme.dart';

/// User preferences for how duas are displayed: text size, Arabic typeface,
/// the reading-surface tint, and which lines (transliteration / translation)
/// are shown. Persisted across launches.
class DisplaySettings extends ChangeNotifier {
  DisplaySettings(this._prefs) {
    _fontScale = _prefs.getDouble(_kScale) ?? 1.0;
    _showTransliteration = _prefs.getBool(_kTranslit) ?? true;
    _showTranslation = _prefs.getBool(_kTranslation) ?? true;
    _arabicFontId = _prefs.getString(_kArabicFont) ?? ArabicFonts.fallback.id;
    _readingTheme = ReadingThemeX.fromName(_prefs.getString(_kReadingTheme));
  }

  final SharedPreferences _prefs;

  static const _kScale = 'display_font_scale';
  static const _kTranslit = 'display_show_transliteration';
  static const _kTranslation = 'display_show_translation';
  static const _kArabicFont = 'display_arabic_font';
  static const _kReadingTheme = 'display_reading_theme';

  /// Discrete, layout-safe text-size steps. Their labels are localized —
  /// see `AppStrings.fontScaleLabels`.
  static const List<double> fontScaleSteps = [0.9, 1.0, 1.15, 1.3];

  double _fontScale = 1.0;
  bool _showTransliteration = true;
  bool _showTranslation = true;
  String _arabicFontId = ArabicFonts.fallback.id;
  ReadingTheme _readingTheme = ReadingTheme.system;

  double get fontScale => _fontScale;
  bool get showTransliteration => _showTransliteration;
  bool get showTranslation => _showTranslation;

  /// The selected Arabic-font id (see [ArabicFonts]).
  String get arabicFontId => _arabicFontId;

  /// The font family name to render Arabic script with.
  String get arabicFontFamily => ArabicFonts.byId(_arabicFontId).family;

  /// The reading-surface tint applied to dua cards.
  ReadingTheme get readingTheme => _readingTheme;

  Future<void> setFontScale(double value) async {
    if (value == _fontScale) return;
    _fontScale = value;
    notifyListeners();
    await _prefs.setDouble(_kScale, value);
  }

  Future<void> setShowTransliteration(bool value) async {
    _showTransliteration = value;
    notifyListeners();
    await _prefs.setBool(_kTranslit, value);
  }

  Future<void> setShowTranslation(bool value) async {
    _showTranslation = value;
    notifyListeners();
    await _prefs.setBool(_kTranslation, value);
  }

  Future<void> setArabicFont(String id) async {
    if (id == _arabicFontId) return;
    _arabicFontId = id;
    notifyListeners();
    await _prefs.setString(_kArabicFont, id);
  }

  Future<void> setReadingTheme(ReadingTheme theme) async {
    if (theme == _readingTheme) return;
    _readingTheme = theme;
    notifyListeners();
    await _prefs.setString(_kReadingTheme, theme.name);
  }
}
