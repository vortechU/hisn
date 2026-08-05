import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';

import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import 'adhan_widget_bridge.dart';
import 'prayer_service.dart';

/// Keeps the Android home-screen prayer widget in sync with the app's current
/// location, calculation settings, and UI language.
///
/// It pushes only the *config* (coordinates + method + madhab) and the localized
/// *chrome* (location label, prayer names, AM/PM markers) — the native widget
/// computes the actual times from that, so it refreshes itself without the app
/// needing to be open. The push is debounced so a burst of [PrayerService]
/// notifications (e.g. a GPS fix landing right after launch) results in one
/// write.
class PrayerWidgetService extends ChangeNotifier {
  Timer? _debounce;
  PrayerService? _prayer;
  AppLang _lang = AppLang.en;

  /// Wired by the provider whenever the [PrayerService] or the language changes.
  void bind(PrayerService prayer, LocaleController locale) {
    _prayer = prayer;
    _lang = locale.lang;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _push);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _push() async {
    final prayer = _prayer;
    if (prayer == null || !prayer.isReady) return;
    final s = AppStrings(_lang);
    await AdhanWidgetBridge.update({
      'lat': prayer.latitude.toString(),
      'lng': prayer.longitude.toString(),
      'method': prayer.method.name,
      'madhab': prayer.madhab.name,
      'label': s.place(prayer.locationLabel),
      'name_fajr': s.prayerName(Prayer.fajr),
      'name_dhuhr': s.prayerName(Prayer.dhuhr),
      'name_asr': s.prayerName(Prayer.asr),
      'name_maghrib': s.prayerName(Prayer.maghrib),
      'name_isha': s.prayerName(Prayer.isha),
      'next_label': s.next,
      'remaining': s.remaining,
      // Localized 12-hour markers (index 0 = AM, 1 = PM).
      'am': s.ampm(9),
      'pm': s.ampm(21),
      // Hijri date: a ready-made string (fallback for old Android) plus the
      // pieces the widget needs to recompute it natively each day.
      'hijri': s.hijriDate(DateTime.now()),
      'hijri_months': s.hijriMonths.join('|'),
      'hijri_suffix': s.hijriSuffix,
    });
  }
}
