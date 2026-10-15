import 'dart:convert';

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';

typedef PrayerSilenceBridge =
    Future<Map<Object?, Object?>?> Function(
      String method,
      Map<String, Object>? arguments,
    );

@immutable
class PrayerSilenceWindow {
  const PrayerSilenceWindow({
    this.enabled = true,
    this.startMinutes = 0,
    this.endMinutes = 30,
  });

  final bool enabled;
  final int startMinutes;
  final int endMinutes;

  bool get isValid =>
      startMinutes >= 0 && startMinutes < endMinutes && endMinutes <= 180;

  PrayerSilenceWindow copyWith({
    bool? enabled,
    int? startMinutes,
    int? endMinutes,
  }) => PrayerSilenceWindow(
    enabled: enabled ?? this.enabled,
    startMinutes: startMinutes ?? this.startMinutes,
    endMinutes: endMinutes ?? this.endMinutes,
  );

  Map<String, Object> toMap() => {
    'enabled': enabled,
    'start': startMinutes,
    'end': endMinutes,
  };
}

/// Persists user intent; Android owns scheduling and its own finite DND rule.
/// No permission UI is opened by enabling, sync, refresh, or app launch.
class PrayerSilenceSettings extends ChangeNotifier {
  PrayerSilenceSettings(
    this._prefs, {
    PrayerSilenceBridge? bridge,
    bool? supported,
  }) : supported =
           supported ??
           (!kIsWeb && defaultTargetPlatform == TargetPlatform.android),
       _bridge = bridge ?? _invoke {
    _readPreferences();
    final saved = _prefs.getString('app_language');
    _strings = AppStrings(
      AppLang.values.firstWhere(
        (lang) => lang.name == saved,
        orElse: () => AppLang.en,
      ),
    );
  }

  static const preferenceKey = 'prayer_silence_enabled';
  static const prayers = [
    Prayer.fajr,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ];
  static const _channel = MethodChannel('hisn/prayer_silence');
  final SharedPreferences _prefs;
  final PrayerSilenceBridge _bridge;
  final bool supported;
  final Map<Prayer, PrayerSilenceWindow> _windows = {};
  late AppStrings _strings;
  bool _enabled = false;
  bool _disposed = false;
  bool _policyGranted = false;
  bool _exactAllowed = false;
  String _reason = 'disabled';
  DateTime? _activeUntil;
  String? _lastPayload;
  Future<void> _pending = Future<void>.value();

  bool get enabled => _enabled;
  bool get policyGranted => _policyGranted;
  bool get exactAllowed => _exactAllowed;
  String get reason => supported ? _reason : 'unsupported';
  DateTime? get activeUntil => _activeUntil;
  PrayerSilenceWindow windowFor(Prayer prayer) =>
      _windows[prayer] ?? (throw ArgumentError.value(prayer, 'prayer'));

  static String windowPreference(Prayer prayer, String field) =>
      'prayer_silence_${prayer.name}_$field';

  void _readPreferences() {
    _enabled = _prefs.getBool(preferenceKey) ?? false;
    for (final prayer in prayers) {
      final fallback = PrayerSilenceWindow(
        endMinutes: prayer == Prayer.fajr ? 50 : 30,
      );
      final saved = PrayerSilenceWindow(
        enabled: _prefs.getBool(windowPreference(prayer, 'enabled')) ?? true,
        startMinutes: _prefs.getInt(windowPreference(prayer, 'start')) ?? 0,
        endMinutes:
            _prefs.getInt(windowPreference(prayer, 'end')) ??
            fallback.endMinutes,
      );
      // Corrupt/restored timing cannot silently opt a prayer into a window.
      _windows[prayer] = saved.isValid
          ? saved
          : fallback.copyWith(enabled: false);
    }
  }

  static Future<Map<Object?, Object?>?> _invoke(
    String method,
    Map<String, Object>? args,
  ) => _channel.invokeMapMethod<Object?, Object?>(method, args);

  Future<void> setEnabled(bool value) async {
    if (value && !supported) return;
    _enabled = value;
    await _prefs.setBool(preferenceKey, value);
    _notify();
    await _push(force: true);
  }

  Future<void> setWindow(Prayer prayer, PrayerSilenceWindow window) async {
    if (!prayers.contains(prayer) || !window.isValid) {
      throw ArgumentError(
        'Prayer silence needs a finite window within 0–180 minutes.',
      );
    }
    _windows[prayer] = window;
    await _prefs.setBool(windowPreference(prayer, 'enabled'), window.enabled);
    await _prefs.setInt(windowPreference(prayer, 'start'), window.startMinutes);
    await _prefs.setInt(windowPreference(prayer, 'end'), window.endMinutes);
    _notify();
    await _push();
  }

  Future<void> sync(AppStrings strings) {
    _strings = strings;
    return _push();
  }

  Future<void> refreshStatus() async {
    await _prefs.reload();
    _readPreferences();
    _notify();
    await _push(force: true);
  }

  Future<void> openPolicySettings() => _command('openPolicySettings');
  Future<void> openExactAlarmSettings() => _command('openExactAlarmSettings');
  Future<void> skipCurrentWindow() => _command('skipCurrent');

  Future<void> _command(String method) {
    if (!supported || _disposed) return Future<void>.value();
    return _enqueue(() async => _apply(await _bridge(method, null)));
  }

  Future<void> _push({bool force = false}) {
    if (!supported || _disposed) return Future<void>.value();
    final payload = <String, Object>{
      'enabled': _enabled,
      'ruleName': 'Hisn · ${_strings.prayerSilenceTitle}',
      'windows': {
        for (final prayer in prayers) prayer.name: windowFor(prayer).toMap(),
      },
    };
    final serialized = jsonEncode(payload);
    if (!force && serialized == _lastPayload) return _pending;
    _lastPayload = serialized;
    return _enqueue(() async => _apply(await _bridge('update', payload)));
  }

  Future<void> _enqueue(Future<void> Function() task) {
    _pending = _pending.then((_) async {
      if (_disposed) return;
      try {
        await task();
      } catch (_) {
        _lastPayload = null;
        _reason = 'error';
        _activeUntil = null;
        _notify();
      }
    });
    return _pending;
  }

  void _apply(Map<Object?, Object?>? status) {
    if (status == null) throw StateError('Missing prayer silence status');
    _policyGranted = status['policyGranted'] == true;
    _exactAllowed = status['exactAllowed'] == true;
    _reason = status['reason'] as String? ?? 'error';
    final end = status['activeUntil'];
    _activeUntil = end is num
        ? DateTime.fromMillisecondsSinceEpoch(end.toInt())
        : null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
