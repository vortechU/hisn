import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sunnah_day.dart';

/// Holds the Islamic-calendar preferences: how far the computed Hijri date is
/// nudged to match the user's local sighting, and whether the night-before
/// fasting reminders are on.
///
/// The offset lives here rather than in [DisplaySettings] because it changes
/// what the app *tells you to do*, not how something looks: the calculated
/// date can run a day ahead of the moon, and a day's error would put a fasting
/// reminder on Eid.
class SunnahCalendarService extends ChangeNotifier {
  SunnahCalendarService(this._prefs) {
    final saved = _prefs.getInt(_kOffset) ?? 0;
    _offset = saved.clamp(
        SunnahCalendarRules.minOffset, SunnahCalendarRules.maxOffset);
    _remindersEnabled = _prefs.getBool(_kReminders) ?? false;
  }

  final SharedPreferences _prefs;

  // Under the `notif_` prefix so backup & restore already carries it (see
  // BackupService's settings prefixes).
  static const _kReminders = 'notif_fasting_reminders';
  static const _kOffset = 'hijri_offset';

  int _offset = 0;
  bool _remindersEnabled = false;

  /// Days added to the Gregorian date before converting to Hijri.
  int get offset => _offset;

  /// Whether to be reminded the evening before a sunnah fast.
  bool get remindersEnabled => _remindersEnabled;

  /// The calendar rules, carrying the current offset.
  SunnahCalendarRules get rules => SunnahCalendarRules(offset: _offset);

  /// Everything known about the day [date] falls on.
  SunnahDay dayFor(DateTime date) => rules.dayFor(date);

  /// Today's entry.
  SunnahDay get today => dayFor(DateTime.now());

  /// The notable days over the next [days], in order.
  List<SunnahDay> upcoming({int days = 60}) =>
      rules.upcoming(DateTime.now(), days: days);

  Future<void> setOffset(int value) async {
    final clamped = value.clamp(
        SunnahCalendarRules.minOffset, SunnahCalendarRules.maxOffset);
    if (clamped == _offset) return;
    _offset = clamped;
    notifyListeners();
    await _prefs.setInt(_kOffset, clamped);
  }

  Future<void> setRemindersEnabled(bool value) async {
    if (value == _remindersEnabled) return;
    _remindersEnabled = value;
    notifyListeners();
    await _prefs.setBool(_kReminders, value);
  }
}
