import 'package:shared_preferences/shared_preferences.dart';

import 'compass.dart';

enum QiblaDialStyle { classic, minimal, rose }

enum QiblaDialTone { accent, gold, ink }

/// Preferences local to the compass, independent of the app's reading theme.
class QiblaPreferences {
  QiblaPreferences(this._prefs);

  final SharedPreferences _prefs;

  QiblaDialStyle get style => QiblaDialStyle.values.firstWhere(
    (value) => value.name == _prefs.getString('qibla_dial_style'),
    orElse: () => QiblaDialStyle.classic,
  );

  QiblaDialTone get tone => QiblaDialTone.values.firstWhere(
    (value) => value.name == _prefs.getString('qibla_dial_tone'),
    orElse: () => QiblaDialTone.accent,
  );

  bool get vibration => _prefs.getBool('qibla_alignment_vibration') ?? true;

  Future<void> setStyle(QiblaDialStyle value) async =>
      _prefs.setString('qibla_dial_style', value.name);

  Future<void> setTone(QiblaDialTone value) async =>
      _prefs.setString('qibla_dial_tone', value.name);

  Future<void> setVibration(bool value) async =>
      _prefs.setBool('qibla_alignment_vibration', value);
}

/// One pulse upon entering alignment, never one per frame or sensor sample.
/// [QiblaFix] supplies the existing 5° / 6.5° hysteresis; this adds a cooldown.
class QiblaAlignmentFeedback {
  static const cooldown = Duration(seconds: 3);
  bool _aligned = false;
  Duration? _lastPulse;

  void suspend() => _aligned = false;

  bool update({
    required QiblaFix fix,
    required bool active,
    required bool enabled,
    required Duration elapsed,
  }) {
    final aligned = active && fix.corrected && fix.fault == null && fix.aligned;
    final entered = aligned && !_aligned;
    _aligned = aligned;
    if (!entered || !enabled) return false;
    if (_lastPulse != null && elapsed - _lastPulse! < cooldown) return false;
    _lastPulse = elapsed;
    return true;
  }
}
