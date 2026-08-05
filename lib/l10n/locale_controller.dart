import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The languages the UI is translated into.
enum AppLang { en, ar, id }

/// Holds the app's chosen UI language and persists it. On first launch it
/// follows the phone's language when that's one we translate into, so the app
/// (and the welcome tour) open in a language the user understands; any other
/// device language falls back to English. Switching to Arabic also flips the
/// whole app to a right-to-left layout (handled by [MaterialApp] via the locale
/// + localizations delegates). Indonesian (`id`) is left-to-right like English.
class LocaleController extends ChangeNotifier {
  LocaleController(this._prefs) {
    final saved = _prefs.getString(_kKey);
    if (saved != null) {
      _locale = _localeForCode(saved);
    } else {
      // No explicit choice yet — match the device language if we support it.
      // Persist it so everything that reads [_kKey] (notifications, place
      // names) stays in step with the UI; the user can still override it in
      // Settings.
      _locale = _deviceDefaultLocale();
      _prefs.setString(_kKey, _locale.languageCode);
    }
  }

  final SharedPreferences _prefs;
  static const _kKey = 'app_language';

  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  /// The current language as an [AppLang] (what [AppStrings] switches on).
  AppLang get lang {
    switch (_locale.languageCode) {
      case 'ar':
        return AppLang.ar;
      case 'id':
        return AppLang.id;
      default:
        return AppLang.en;
    }
  }

  /// The languages the app offers, in display order.
  static const List<Locale> supported = [
    Locale('en'),
    Locale('ar'),
    Locale('id'),
  ];

  static Locale _localeForCode(String? code) {
    switch (code) {
      case 'ar':
        return const Locale('ar');
      case 'id':
        return const Locale('id');
      default:
        return const Locale('en');
    }
  }

  /// The first of the device's preferred languages that we translate into,
  /// or English if none match. Mirrors how the platform resolves resources:
  /// the user's ordered locale list is honoured, most-preferred first.
  static Locale _deviceDefaultLocale() {
    const supportedCodes = {'en', 'ar', 'id'};
    for (final locale in WidgetsBinding.instance.platformDispatcher.locales) {
      if (supportedCodes.contains(locale.languageCode)) {
        return Locale(locale.languageCode);
      }
    }
    return const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode == _locale.languageCode) return;
    _locale = locale;
    notifyListeners();
    await _prefs.setString(_kKey, locale.languageCode);
  }

  /// Switch to a specific UI language.
  Future<void> setLang(AppLang lang) => setLocale(Locale(lang.name));
}
