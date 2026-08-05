import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'adhan_audio.dart';

/// One scheduled adhan playback at [time].
class AdhanAlarm {
  AdhanAlarm({
    required this.id,
    required this.time,
    required this.fajr,
    required this.usage,
  });

  final int id;
  final DateTime time;
  final bool fajr;
  final String usage; // 'media' | 'notification' | 'alarm'

  Map<String, dynamic> toMap() => {
        'id': id,
        'at': time.millisecondsSinceEpoch,
        'fajr': fajr,
        'usage': usage,
      };
}

/// Bridges to the native (Android) adhan player: exact alarms that start a
/// foreground service to play the full adhan at prayer time, independent of the
/// notification's sound (which MIUI and others drop). No-op off Android.
class AdhanScheduler {
  static const _channel = MethodChannel('hisn/adhan');

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Native audio-attributes usage string for a volume stream.
  static String usageFor(AdhanVolumeStream stream) => switch (stream) {
        AdhanVolumeStream.media => 'media',
        AdhanVolumeStream.ring => 'notification',
        AdhanVolumeStream.alarm => 'alarm',
      };

  static Future<void> schedule(List<AdhanAlarm> alarms) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('schedule', {
        'alarms': alarms.map((a) => a.toMap()).toList(),
      });
    } catch (e) {
      debugPrint('Adhan schedule failed: $e');
    }
  }

  static Future<void> cancelAll() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('cancelAll');
    } catch (e) {
      debugPrint('Adhan cancelAll failed: $e');
    }
  }

  /// Play the adhan immediately through the foreground service (used by the
  /// test button to verify the closed-app playback path works).
  static Future<void> playNow({required bool fajr, required String usage}) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('playNow', {'fajr': fajr, 'usage': usage});
    } catch (e) {
      debugPrint('Adhan playNow failed: $e');
    }
  }

  static Future<void> stop() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('stop');
    } catch (e) {
      debugPrint('Adhan stop failed: $e');
    }
  }
}
