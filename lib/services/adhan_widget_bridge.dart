import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridges to the native (Android) home-screen prayer widget: pushes the current
/// location + calculation settings + localized labels down to native code, which
/// stores them and redraws the widget. The widget then computes the day's prayer
/// times itself (via the Adhan library) so it stays accurate even while the app
/// is closed. No-op off Android (and on web).
class AdhanWidgetBridge {
  static const _channel = MethodChannel('hisn/widget');

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Send the widget its config + display strings. Values are all strings so the
  /// native side can read them unambiguously from SharedPreferences.
  static Future<void> update(Map<String, String> data) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('update', {'data': data});
    } catch (e) {
      debugPrint('Prayer widget update failed: $e');
    }
  }
}
