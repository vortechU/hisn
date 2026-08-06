import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The Earth's magnetic field at one place on it.
class GeomagneticField {
  const GeomagneticField({required this.declination, required this.strength});

  /// The angle between magnetic north — what the phone's magnetometer reports
  /// — and true north, which is what a Qibla bearing is measured from.
  /// East-positive, so adding it to a magnetic heading gives a true one.
  final double declination;

  /// How strong the field ought to be here, in microtesla. Somewhere between
  /// about 25 and 65 µT anywhere on Earth. A phone reading far from this is
  /// sitting near something magnetic, and its heading is worth nothing.
  final double strength;
}

/// The World Magnetic Model, by way of Android's built-in `GeomagneticField`.
/// No network, no bundled coefficient table.
class Geomag {
  Geomag._();

  static const _channel = MethodChannel('hisn/geomag');

  /// The field at [latitude],[longitude] — or null when it cannot be known:
  /// another platform, or a call that failed.
  ///
  /// Null rather than a zeroed field on purpose. In the arithmetic "no
  /// correction" and "a correction of zero" are the same number, but to
  /// someone deciding whether to trust the needle they are opposites, and the
  /// screen says which one it is.
  static Future<GeomagneticField?> at(double latitude, double longitude) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final value = await _channel.invokeMapMethod<String, double>('field', {
        'lat': latitude,
        'lng': longitude,
      });
      final declination = value?['declination'];
      final strength = value?['strength'];
      if (declination == null || strength == null) return null;
      return GeomagneticField(declination: declination, strength: strength);
    } catch (_) {
      return null;
    }
  }
}
