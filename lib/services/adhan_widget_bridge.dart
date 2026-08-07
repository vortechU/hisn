import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridges to the Android home-screen widgets: pushes the current location +
/// calculation settings, the active palette, and the localized labels down to
/// native code, which stores them and redraws. The widgets then compute what
/// they show — prayer times, which adhkar belong to this hour, today's verse —
/// themselves, so they stay right even while the app is closed.
///
/// Also carries taps the other way: a widget can ask the app to open at a
/// particular place, which arrives either as a route waiting at launch or as a
/// call on an app that is already running.
///
/// No-op off Android (and on web).
class AdhanWidgetBridge {
  static const _channel = MethodChannel('hisn/widget');

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Send the widgets their config + display strings. Values are all strings so
  /// the native side can read them unambiguously from SharedPreferences.
  ///
  /// Native merges rather than replaces, so a caller that only owns part of the
  /// payload — the tasbih phrase, say — may push just that part.
  static Future<void> update(Map<String, String> data) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('update', {'data': data});
    } catch (e) {
      debugPrint('Widget update failed: $e');
    }
  }

  /// Redraw every widget without changing anything it holds.
  ///
  /// Used after the app itself changes something a widget reads directly out of
  /// the shared preference store — a tasbih count, most of all — where there is
  /// nothing to push but the drawing is now stale.
  static Future<void> refresh() => update(const {});

  /// The destination a widget tap asked for, if this launch came from one.
  ///
  /// Cleared natively as it is read, so a rebuild that calls this twice does
  /// not navigate twice.
  static Future<String?> consumeRoute() async {
    if (!_supported) return null;
    try {
      return await _channel.invokeMethod<String>('consumeRoute');
    } catch (e) {
      debugPrint('Widget route read failed: $e');
      return null;
    }
  }

  /// Listen for widget taps that arrive while the app is already running.
  ///
  /// The cold-launch case goes through [consumeRoute] instead: at that point
  /// Dart is not yet listening, so native holds the route until it is asked.
  static void onRoute(ValueChanged<String> handler) {
    if (!_supported) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'route') {
        final route = call.arguments as String?;
        if (route != null && route.isNotEmpty) handler(route);
      }
      return null;
    });
  }
}
