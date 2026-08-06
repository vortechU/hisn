import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../util/angles.dart';
import 'geomag.dart';

/// One reading from the device's compass, carrying not just the heading but
/// enough context to decide whether the heading deserves to be believed.
///
/// The values arrive raw from the platform. Judging them is [CompassTrust]'s
/// job, kept separate so the thresholds can be tested without a device.
@immutable
class CompassReading {
  const CompassReading({
    required this.heading,
    required this.pitch,
    required this.roll,
    this.accuracy,
    this.fieldStrength,
  });

  /// Magnetic heading in degrees `[0, 360)`: where the top edge of the phone
  /// points when the phone is lying flat. Not yet corrected to true north —
  /// see [GeomagneticField.declination].
  final double heading;

  /// How far from flat the phone is, in degrees. [pitch] is its top edge
  /// lifting or dipping, [roll] is it leaning onto one side.
  ///
  /// Both near zero and the heading can be read straight off. Near ±90 the
  /// top edge is pointing at the sky, its shadow on the ground has no
  /// direction left, and there is no heading to read at all.
  final double pitch;
  final double roll;

  /// How far out the heading is likely to be, in degrees — Android's
  /// calibration buckets of 15, 30 and 45.
  ///
  /// Null when the platform won't say, which is emphatically not the same as
  /// "fine": an uncalibrated magnetometer is exactly the case that reports
  /// nothing.
  final double? accuracy;

  /// What the magnetometer is actually reading, in microtesla, or null if it
  /// isn't saying. Compared against [GeomagneticField.strength] to catch a
  /// phone sitting next to something magnetic.
  final double? fieldStrength;

  factory CompassReading.fromMap(Map<Object?, Object?> map) {
    double read(String key) => (map[key] as num?)?.toDouble() ?? 0;

    // The platform says "I don't know" with a negative number; this side says
    // it with null, so that further up an unknown can never be read as good.
    double? readOptional(String key) {
      final value = (map[key] as num?)?.toDouble();
      return value == null || value < 0 ? null : value;
    }

    return CompassReading(
      heading: read('heading'),
      pitch: read('pitch'),
      roll: read('roll'),
      accuracy: readOptional('accuracy'),
      fieldStrength: readOptional('field'),
    );
  }
}

/// Why a heading on screen should not be trusted, worst first.
///
/// The order is the order they are worth saying out loud. Interference and a
/// stale calibration each put the heading out by an unknown amount; tilt only
/// makes it noisy. And there is no use telling someone to lay their phone flat
/// while it is resting on a radiator.
enum CompassFault { interference, uncalibrated, tilted }

/// The rules deciding whether a reading is fit to point someone toward the
/// Qibla. Pure and free of Flutter, so every threshold below is testable.
///
/// This exists because a compass that is wrong looks exactly like a compass
/// that is right — the needle is just as steady and just as confident. The
/// only defence is to check the conditions that make it wrong and say so.
class CompassTrust {
  const CompassTrust._();

  /// Past this much tilt, the horizontal shadow of the phone's top edge gets
  /// short and the noise in the heading grows as 1/cos(tilt). At 25° that is
  /// about a tenth; much beyond it the needle visibly wanders.
  static const double maxTilt = 25;

  /// Android's buckets are 15 (high), 30 (medium) and 45 (low). Only the top
  /// one will do here: a Qibla that might be thirty degrees out is not a Qibla.
  static const double maxError = 15;

  /// How far the measured field may stray from the model before something
  /// magnetic nearby is the better explanation. Generous, because the model and
  /// the sensor's own scaling are each approximate.
  static const double maxFieldDeviation = 0.35;

  /// Everything wrong with [reading]. [expectedField] is the strength the World
  /// Magnetic Model predicts here, in microtesla; without it the interference
  /// check is simply not made rather than guessed at.
  static Set<CompassFault> faults(
    CompassReading reading, {
    double? expectedField,
  }) {
    final faults = <CompassFault>{};

    if (reading.pitch.abs() > maxTilt || reading.roll.abs() > maxTilt) {
      faults.add(CompassFault.tilted);
    }

    final accuracy = reading.accuracy;
    if (accuracy == null || accuracy > maxError) {
      faults.add(CompassFault.uncalibrated);
    }

    final measured = reading.fieldStrength;
    if (measured != null && expectedField != null && expectedField > 0) {
      final deviation = (measured - expectedField).abs() / expectedField;
      if (deviation > maxFieldDeviation) faults.add(CompassFault.interference);
    }

    return faults;
  }

  /// The one fault worth putting on screen. Listing three at once reads as
  /// "this app is broken" rather than "do this one thing".
  static CompassFault? primary(Set<CompassFault> faults) {
    for (final fault in CompassFault.values) {
      if (faults.contains(fault)) return fault;
    }
    return null;
  }
}

/// A compass reading turned into guidance toward a Qibla bearing: which way to
/// turn, and whether the answer deserves to be acted on.
///
/// This is where magnetic north becomes true north. It lives outside the widget
/// so that the correction — and the refusal to claim alignment on a reading
/// known to be bad — can be tested without a device or a sensor.
@immutable
class QiblaFix {
  const QiblaFix({
    required this.heading,
    required this.offset,
    required this.corrected,
    this.fault,
  });

  /// Where the device points, in degrees `[0, 360)` from **true** north.
  final double heading;

  /// The turn from [heading] to the Qibla, in `[-180, 180)`. Positive is
  /// clockwise — to the user's right.
  final double offset;

  /// Whether the declination was known and applied. When false, [heading] is
  /// still on magnetic north and the screen has to say so.
  final bool corrected;

  /// The one thing wrong with the reading behind this fix, if anything is.
  final CompassFault? fault;

  /// How close counts as facing the Qibla. Wide enough to settle into by hand,
  /// narrow enough that a row of people using it still comes out straight.
  static const double alignedWithin = 5;

  /// Whether the user is facing the Qibla. Never true on a faulty reading:
  /// that is a claim about the world, not about the arithmetic.
  bool get aligned => fault == null && offset.abs() < alignedWithin;

  /// Combine a [reading] with the [qibla] bearing and the local [field].
  ///
  /// [magneticHeading] is the *smoothed* heading rather than [reading]'s own,
  /// so the wobble is already out before any of this is decided.
  factory QiblaFix.of({
    required double magneticHeading,
    required double qibla,
    required CompassReading reading,
    GeomagneticField? field,
  }) {
    final heading =
        normalizeDegrees(magneticHeading + (field?.declination ?? 0));
    return QiblaFix(
      heading: heading,
      offset: signedDelta(heading, qibla),
      corrected: field != null,
      fault: CompassTrust.primary(
        CompassTrust.faults(reading, expectedField: field?.strength),
      ),
    );
  }
}

/// The device compass, as a stream of readings.
class DeviceCompass {
  DeviceCompass._();

  static const _channel = EventChannel('hisn/compass');
  static Stream<CompassReading>? _stream;

  /// The readings, or null where nothing sits behind this channel.
  ///
  /// iOS will want a CoreLocation equivalent when that platform is taken on.
  /// Until then the Qibla screen shows its "no compass" state there, which is
  /// at least true, rather than a needle pointing somewhere invented.
  static Stream<CompassReading>? get readings {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    return _stream ??= _channel.receiveBroadcastStream().map(
          (event) => CompassReading.fromMap(event as Map<Object?, Object?>),
        );
  }
}
