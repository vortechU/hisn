import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language.dart';
export 'app_language.dart';

/// Persists the UI language; first launch honors the device's ordered choices.
class LocaleController extends ChangeNotifier {
  LocaleController(this._prefs) {
    final saved = _prefs.getString(preferenceKey);
    _lang = saved == null ? _deviceDefault() : AppLang.fromCode(saved);
    // Normalize stale saved codes for background readers as well.
    if (saved != _lang.code) _prefs.setString(preferenceKey, _lang.code);
  }

  final SharedPreferences _prefs;
  static const preferenceKey = 'app_language';
  late AppLang _lang;

  AppLang get lang => _lang;
  Locale get locale => Locale(_lang.code);
  bool get isArabic => _lang == AppLang.ar;
  bool get rtl => _lang.rtl;

  static final List<Locale> supported = List.unmodifiable(
    AppLang.values.map((language) => Locale(language.code)),
  );

  static AppLang _deviceDefault() {
    for (final locale in WidgetsBinding.instance.platformDispatcher.locales) {
      final language = AppLang.tryFromCode(locale.languageCode);
      if (language != null) return language;
    }
    return AppLang.en;
  }

  Future<void> setLocale(Locale locale) =>
      setLang(AppLang.fromCode(locale.languageCode));

  Future<void> setLang(AppLang language) async {
    if (language == _lang) return;
    _lang = language;
    // The setter updates the preference cache synchronously. Observers see the
    // new choice immediately, with no notification delayed past disposal.
    final persisted = _prefs.setString(preferenceKey, language.code);
    notifyListeners();
    await persisted;
  }
}
