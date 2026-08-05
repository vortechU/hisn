import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prayer_settings.dart';

/// One prayer occurrence: which prayer, and the moment its adhan is called.
class PrayerTiming {
  const PrayerTiming(this.prayer, this.time);
  final Prayer prayer;
  final DateTime time;
}

/// Computes prayer times for the user's location and exposes the current /
/// next prayer. Location mode, calculation method, and madhab are configurable
/// (see Settings) and persisted.
///
/// In GPS mode it starts with a Makkah fallback (so the UI has data instantly),
/// then tries the device location and recomputes if a fix arrives.
class PrayerService extends ChangeNotifier {
  PrayerService(this._prefs) {
    _load();
    if (_locationMode == LocationMode.gps) {
      _compute();
      _tryDeviceLocation();
    } else {
      _compute();
    }
  }

  final SharedPreferences _prefs;

  static const _kMethod = 'prayer_method';
  static const _kMadhab = 'prayer_madhab';
  static const _kLocMode = 'prayer_location_mode';
  static const _kLat = 'prayer_lat';
  static const _kLng = 'prayer_lng';
  static const _kLabel = 'prayer_location_label';
  // The last *detected* device location — kept separate from the manual-city
  // keys so the two modes never clobber each other. This is what lets the app
  // remember (e.g.) "Madinah" after location services are switched off.
  static const _kGpsLat = 'prayer_gps_lat';
  static const _kGpsLng = 'prayer_gps_lng';
  static const _kGpsLabel = 'prayer_gps_label';
  static const _kLang = 'app_language'; // for localized place names

  // Makkah (the Ka'bah) — the GPS-mode fallback.
  static final Coordinates _makkah = Coordinates(21.4225, 39.8262);
  static const String _makkahLabel = 'Makkah';

  CalculationMethod _method = CalculationMethod.umm_al_qura;
  Madhab _madhab = Madhab.shafi;
  LocationMode _locationMode = LocationMode.gps;
  Coordinates _coordinates = _makkah;
  String _locationLabel = _makkahLabel;
  bool _usingDeviceLocation = false;
  bool _locating = false;

  /// Yesterday's Isha → today's five prayers → tomorrow's Fajr, in order, so a
  /// "current" and "next" can always be resolved whatever the time of day.
  List<PrayerTiming> _schedule = const [];

  CalculationMethod get method => _method;
  Madhab get madhab => _madhab;
  LocationMode get locationMode => _locationMode;
  String get locationLabel => _locationLabel;
  bool get usingDeviceLocation => _usingDeviceLocation;
  bool get isLocating => _locating;
  bool get isReady => _schedule.isNotEmpty;

  CalculationParameters get _params =>
      _method.getParameters()..madhab = _madhab;

  /// Direction to the Qibla in degrees clockwise from true north.
  double get qiblaDirection => Qibla(_coordinates).direction;

  /// Whether the coordinates describe where the user actually is. False only
  /// in GPS mode while still on the Makkah fallback — the bearing "from the
  /// Ka'bah to the Ka'bah" is meaningless, so the Qibla compass must not
  /// present it as real.
  bool get hasKnownLocation =>
      _locationMode == LocationMode.manual || _usingDeviceLocation;

  /// Current latitude/longitude (used for magnetic-declination correction).
  double get latitude => _coordinates.latitude;
  double get longitude => _coordinates.longitude;

  /// The five daily prayers for today, in order (for the full schedule view).
  List<PrayerTiming> get todaysPrayers => prayersForDay(DateTime.now());

  /// The five daily prayers for [day], in order (used for scheduling ahead).
  List<PrayerTiming> prayersForDay(DateTime day) {
    final times = PrayerTimes(_coordinates, DateComponents.from(day), _params);
    return [
      PrayerTiming(Prayer.fajr, times.fajr),
      PrayerTiming(Prayer.dhuhr, times.dhuhr),
      PrayerTiming(Prayer.asr, times.asr),
      PrayerTiming(Prayer.maghrib, times.maghrib),
      PrayerTiming(Prayer.isha, times.isha),
    ];
  }

  /// Most recent prayer whose time has passed (the prayer we're "in").
  PrayerTiming? currentPrayer(DateTime now) {
    PrayerTiming? current;
    for (final timing in _schedule) {
      if (!timing.time.isAfter(now)) {
        current = timing;
      } else {
        break;
      }
    }
    return current;
  }

  /// The next upcoming adhan.
  PrayerTiming? nextPrayer(DateTime now) {
    for (final timing in _schedule) {
      if (timing.time.isAfter(now)) return timing;
    }
    return null;
  }

  /// Recompute the schedule. Cheap; safe to call when the day rolls over.
  void refresh() => _compute();

  /// Re-attempt a device fix. The startup attempt runs only once, so screens
  /// that depend on real coordinates (the Qibla compass) call this when they
  /// open. No-op in manual mode or while a lookup is already in flight.
  Future<void> refreshLocation() async {
    if (_locationMode != LocationMode.gps || _locating) return;
    await _tryDeviceLocation();
  }

  // ---- settings mutations ----

  Future<void> setMethod(CalculationMethod method) async {
    if (method == _method) return;
    _method = method;
    await _prefs.setString(_kMethod, method.name);
    _compute();
  }

  Future<void> setMadhab(Madhab madhab) async {
    if (madhab == _madhab) return;
    _madhab = madhab;
    await _prefs.setString(_kMadhab, madhab.name);
    _compute();
  }

  /// Prompt for location permission (used by the first-run onboarding). On a
  /// grant it switches to GPS mode and fetches a fix so prayer times localize
  /// straight away. Returns whether permission is now granted.
  Future<bool> requestLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    final granted = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    if (granted) await useDeviceLocation();
    return granted;
  }

  Future<void> useDeviceLocation() async {
    _locationMode = LocationMode.gps;
    await _prefs.setString(_kLocMode, LocationMode.gps.name);
    // Don't reset to Makkah — fall back to the last detected location (if any)
    // while we try to refresh it. Makkah only stands in when nothing is known.
    if (!_restoreLastGps()) {
      _coordinates = _makkah;
      _locationLabel = _makkahLabel;
      _usingDeviceLocation = false;
    }
    _compute();
    await _tryDeviceLocation();
  }

  /// Restore the last detected device location into the live fields. Returns
  /// true if a saved fix existed.
  bool _restoreLastGps() {
    final lat = _prefs.getDouble(_kGpsLat);
    final lng = _prefs.getDouble(_kGpsLng);
    if (lat == null || lng == null) return false;
    _coordinates = Coordinates(lat, lng);
    _locationLabel = _prefs.getString(_kGpsLabel) ?? 'Your location';
    _usingDeviceLocation = true;
    return true;
  }

  Future<void> useManualCity(PresetCity city) async {
    _locationMode = LocationMode.manual;
    _coordinates = Coordinates(city.latitude, city.longitude);
    _locationLabel = city.name;
    _usingDeviceLocation = false;
    await _prefs.setString(_kLocMode, LocationMode.manual.name);
    await _prefs.setString(_kLabel, city.name);
    await _prefs.setDouble(_kLat, city.latitude);
    await _prefs.setDouble(_kLng, city.longitude);
    _compute();
  }

  // ---- internals ----

  void _load() {
    final method = _prefs.getString(_kMethod);
    if (method != null) {
      try {
        _method = CalculationMethod.values.byName(method);
      } catch (_) {/* keep default */}
    }
    final madhab = _prefs.getString(_kMadhab);
    if (madhab != null) {
      try {
        _madhab = Madhab.values.byName(madhab);
      } catch (_) {/* keep default */}
    }
    _locationMode = _prefs.getString(_kLocMode) == LocationMode.manual.name
        ? LocationMode.manual
        : LocationMode.gps;
    if (_locationMode == LocationMode.manual) {
      final lat = _prefs.getDouble(_kLat);
      final lng = _prefs.getDouble(_kLng);
      if (lat != null && lng != null) {
        _coordinates = Coordinates(lat, lng);
        _locationLabel = _prefs.getString(_kLabel) ?? 'Selected city';
      }
    } else {
      // GPS mode: start from the last detected location so that if location
      // services are off this launch, we keep the user's known town rather
      // than snapping back to Makkah.
      _restoreLastGps();
    }
  }

  void _compute() {
    final now = DateTime.now();
    PrayerTimes forDay(DateTime day) =>
        PrayerTimes(_coordinates, DateComponents.from(day), _params);

    final yesterday = forDay(now.subtract(const Duration(days: 1)));
    final today = forDay(now);
    final tomorrow = forDay(now.add(const Duration(days: 1)));

    _schedule = [
      PrayerTiming(Prayer.isha, yesterday.isha),
      PrayerTiming(Prayer.fajr, today.fajr),
      PrayerTiming(Prayer.dhuhr, today.dhuhr),
      PrayerTiming(Prayer.asr, today.asr),
      PrayerTiming(Prayer.maghrib, today.maghrib),
      PrayerTiming(Prayer.isha, today.isha),
      PrayerTiming(Prayer.fajr, tomorrow.fajr),
    ];
    notifyListeners();
  }

  Future<void> _tryDeviceLocation() async {
    if (_locationMode != LocationMode.gps) return;
    _locating = true;
    notifyListeners();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      // A fresh fix can be slow (or fail entirely) indoors; the OS-cached last
      // known position is plenty for prayer times and the Qibla, which change
      // meaningfully only over tens of kilometres.
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.low),
        ).timeout(const Duration(seconds: 8));
      } on TimeoutException {
        position = await Geolocator.getLastKnownPosition();
      }
      if (position == null) return;

      // The user may have switched to manual while we were waiting.
      if (_locationMode != LocationMode.gps) return;

      _coordinates = Coordinates(position.latitude, position.longitude);
      // Resolve a human town name ("Madinah"); keep the previous label if the
      // lookup fails so we never downgrade a good name to "Your location".
      final town = await _townName(position.latitude, position.longitude);
      _locationLabel =
          town ?? (_locationLabel.isEmpty ? 'Your location' : _locationLabel);
      _usingDeviceLocation = true;

      // Persist the fix so it survives the next launch even with services off.
      await _prefs.setDouble(_kGpsLat, position.latitude);
      await _prefs.setDouble(_kGpsLng, position.longitude);
      await _prefs.setString(_kGpsLabel, _locationLabel);

      _compute();
    } catch (_) {
      // Keep the last known (or Makkah) location if a fix is unavailable.
    } finally {
      _locating = false;
      notifyListeners();
    }
  }

  /// Reverse-geocode coordinates to a town/city name, localized to the app
  /// language where the platform geocoder supports it. Null on failure.
  Future<String?> _townName(double lat, double lng) async {
    try {
      final lang = _prefs.getString(_kLang);
      // Map the app language to a geocoder locale (defaults to English).
      final locale = (lang == 'ar' || lang == 'id') ? lang! : 'en';
      try {
        await setLocaleIdentifier(locale);
      } catch (_) {/* locale override is best-effort */}
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      for (final candidate in [
        p.locality,
        p.subAdministrativeArea,
        p.administrativeArea,
      ]) {
        if (candidate != null && candidate.trim().isNotEmpty) {
          return candidate.trim();
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

/// English and Arabic display names for each [Prayer].
extension PrayerLabels on Prayer {
  String get englishName {
    switch (this) {
      case Prayer.fajr:
        return 'Fajr';
      case Prayer.sunrise:
        return 'Sunrise';
      case Prayer.dhuhr:
        return 'Dhuhr';
      case Prayer.asr:
        return 'Asr';
      case Prayer.maghrib:
        return 'Maghrib';
      case Prayer.isha:
        return 'Isha';
      case Prayer.none:
        return '—';
    }
  }

  String get arabicName {
    switch (this) {
      case Prayer.fajr:
        return 'الفَجْر';
      case Prayer.sunrise:
        return 'الشُّرُوق';
      case Prayer.dhuhr:
        return 'الظُّهْر';
      case Prayer.asr:
        return 'العَصْر';
      case Prayer.maghrib:
        return 'المَغْرِب';
      case Prayer.isha:
        return 'العِشَاء';
      case Prayer.none:
        return '';
    }
  }
}
