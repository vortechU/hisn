import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';

typedef PrayerCountdownBridge = Future<Map<Object?, Object?>?> Function(
    Map<String, Object> payload);

/// Opt-in native status notification. The OS owns all countdown ticking.
class PrayerCountdownSettings extends ChangeNotifier {
  PrayerCountdownSettings(this._prefs,
      {PrayerCountdownBridge? bridge, bool? supported})
      : supported = supported ??
            (!kIsWeb && defaultTargetPlatform == TargetPlatform.android),
        _bridge = bridge ?? _invoke {
    _enabled = _prefs.getBool(preferenceKey) ?? false;
    final saved = _prefs.getString('app_language');
    _strings = AppStrings(AppLang.fromCode(saved));
  }

  static const preferenceKey = 'notif_prayer_countdown_enabled';
  static const _channel = MethodChannel('hisn/prayer_countdown');
  final SharedPreferences _prefs;
  final PrayerCountdownBridge _bridge;
  final bool supported;
  late bool _enabled;
  late AppStrings _strings;
  bool? _notificationsAllowed;
  bool _disposed = false;
  Map<String, Object>? _lastPayload;
  Future<void> _pending = Future<void>.value();

  bool get enabled => _enabled;
  bool? get notificationsAllowed => _notificationsAllowed;

  static Future<Map<Object?, Object?>?> _invoke(Map<String, Object> payload) =>
      _channel.invokeMapMethod<Object?, Object?>('update', payload);

  Future<void> setEnabled(bool value) async {
    if (value && !supported) return;
    if (value != _enabled) {
      _enabled = value;
      await _prefs.setBool(preferenceKey, value);
      if (!_disposed) notifyListeners();
    }
    await _push();
  }

  /// Called by the locale provider; unchanged payloads cause no native work.
  Future<void> sync(AppStrings strings) {
    _strings = strings;
    return _push();
  }

  /// Resume/restore entry point, also checks posting/channel permission again.
  Future<void> refresh() async {
    await _prefs.reload();
    final saved = _prefs.getBool(preferenceKey) ?? false;
    if (saved != _enabled) {
      _enabled = saved;
      if (!_disposed) notifyListeners();
    }
    await _push(force: true);
  }

  Future<void> _push({bool force = false}) {
    if (!supported || _disposed) return Future<void>.value();
    final payload = <String, Object>{
      'enabled': _enabled,
      'titlePrefix': _strings.next,
      'remainingLabel': _strings.remaining,
      'sinceLabel': _strings.sinceAdhan,
      'channelName': _strings.prayerCountdownTitle,
      'channelDescription': _strings.prayerCountdownChannelDescription,
    };
    if (!force && mapEquals(payload, _lastPayload)) return _pending;
    _lastPayload = payload;
    // Serialize rapid toggle/locale changes so an older update cannot finish
    // after a newer disable and resurrect the notification.
    _pending = _pending.then((_) async {
      if (_disposed) return;
      try {
        final status = await _bridge(payload);
        if (_disposed) return;
        final allowed = status?['notificationsAllowed'] as bool?;
        if (allowed != _notificationsAllowed) {
          _notificationsAllowed = allowed;
          notifyListeners();
        }
      } catch (error) {
        // Keep the user's preference; a later sync/resume may retry transport.
        if (identical(_lastPayload, payload)) _lastPayload = null;
        debugPrint('Prayer countdown update failed: $error');
      }
    });
    return _pending;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
