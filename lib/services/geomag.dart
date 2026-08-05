import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Magnetic declination — the angle between magnetic north (what the phone's
/// magnetometer reports) and true north (what the Qibla bearing is measured
/// against). Adding it to a magnetic heading yields a true heading, which is
/// what makes the Qibla needle accurate.
///
/// Backed by Android's built-in `GeomagneticField` (the World Magnetic Model),
/// so it needs no network and no bundled coefficient table. Returns 0 on other
/// platforms or on any error, which simply leaves the compass on magnetic north
/// (no worse than before the correction existed).
class Geomag {
  Geomag._();

  static const _channel = MethodChannel('hisn/geomag');

  /// Declination in degrees, east-positive, for the given coordinates.
  static Future<double> declination(double latitude, double longitude) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return 0;
    try {
      final value = await _channel.invokeMethod<double>('declination', {
        'lat': latitude,
        'lng': longitude,
      });
      return value ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
