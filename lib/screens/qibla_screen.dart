import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/geomag.dart';
import '../services/prayer_service.dart';

/// A live compass that points toward the Qibla (the Ka'bah in Makkah), using
/// the device magnetometer and the Qibla bearing for the current location.
///
/// The raw magnetometer heading is noisy, so we apply an exponential low-pass
/// filter (smoothing it on the shortest angular path so the 359°→0° wrap
/// doesn't cause a jump). This removes the visible left/right wobble.
///
/// This is a self-contained widget (no Scaffold) so it can be embedded inside
/// the combined "Prayer & Qibla" page above the prayer-times list.
class QiblaCompass extends StatefulWidget {
  const QiblaCompass({super.key});

  @override
  State<QiblaCompass> createState() => _QiblaCompassState();
}

class _QiblaCompassState extends State<QiblaCompass> {
  /// Smoothed heading, in degrees [0,360). Null until the first reading.
  /// This is the *magnetic* heading straight from the sensor.
  double? _heading;

  /// Magnetic declination at the current location (degrees, east-positive).
  /// Added to the magnetic heading to get a true-north heading, so the needle
  /// lines up with the Qibla bearing (which is measured from true north).
  double _declination = 0;
  double? _declLat;
  double? _declLng;

  /// Last reported sensor accuracy in degrees of heading error (lower is
  /// better; Android buckets it as 15/30/45 and reports null when the sensor
  /// is unreliable or the status is unknown).
  double? _accuracy;

  StreamSubscription<CompassEvent>? _sub;

  /// Whether this device exposes a compass stream at all.
  bool get _hasSensor => FlutterCompass.events != null;

  /// Smoothing factor: lower = steadier but slower to catch up.
  static const _alpha = 0.18;

  @override
  void initState() {
    super.initState();
    // Subscribe once so setState only fires on real sensor events (not on
    // every rebuild) — avoids a feedback loop and keeps the needle steady.
    _sub = FlutterCompass.events?.listen(_onEvent);
    // The startup location attempt runs only once and can fail (indoors, slow
    // GPS). Without real coordinates the Qibla bearing is meaningless, so
    // re-try every time the compass is opened.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PrayerService>().refreshLocation();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onEvent(CompassEvent event) {
    final raw = event.heading;
    if (raw == null) return;

    final prev = _heading;
    double next;
    if (prev == null) {
      next = raw;
    } else {
      // Shortest signed delta in [-180,180] so the wrap-around is handled.
      final delta = (raw - prev + 540) % 360 - 180;
      next = (prev + _alpha * delta) % 360;
      if (next < 0) next += 360;
    }

    if (!mounted) return;
    setState(() {
      _heading = next;
      _accuracy = event.accuracy;
    });
  }

  /// Fetch the declination for [lat],[lng] once per location change.
  void _ensureDeclination(double lat, double lng) {
    if (_declLat == lat && _declLng == lng) return;
    _declLat = lat;
    _declLng = lng;
    Geomag.declination(lat, lng).then((value) {
      if (mounted) setState(() => _declination = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prayer = context.watch<PrayerService>();
    _ensureDeclination(prayer.latitude, prayer.longitude);
    final qibla = prayer.qiblaDirection;
    // Correct the magnetic reading to true north before comparing to the Qibla.
    final heading =
        _heading == null ? null : (_heading! + _declination) % 360;
    final s = AppStrings.of(context);

    if (!_hasSensor) return const _Unavailable();
    // Still on the Makkah fallback: there is no real bearing to show, so ask
    // for a location instead of confidently pointing the needle at nonsense.
    if (!prayer.hasKnownLocation) {
      return _NeedsLocation(
        locating: prayer.isLocating,
        onRetry: () => context.read<PrayerService>().refreshLocation(),
      );
    }
    if (heading == null) {
      return const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return _Compass(
      heading: heading,
      qibla: qibla,
      location: s.place(prayer.locationLabel),
      accuracy: _accuracy,
    );
  }
}

class _Compass extends StatelessWidget {
  const _Compass({
    required this.heading,
    required this.qibla,
    required this.location,
    this.accuracy,
  });

  final double heading;
  final double qibla;
  final String location;
  final double? accuracy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = AppStrings.of(context);

    // Offset of the Qibla from where the device currently points, in [-180,180].
    var offset = (qibla - heading) % 360;
    if (offset > 180) offset -= 360;
    if (offset < -180) offset += 360;
    final aligned = offset.abs() < 5;
    final accent = aligned ? scheme.primary : scheme.secondary;

    // Accuracy is degrees of heading error; null means the platform flagged
    // the sensor as unreliable. Anything worse than the "medium" bucket (30°)
    // means the magnetometer needs calibration — a figure-8 wave fixes it.
    final needsCalibration = accuracy == null || accuracy! > 30;

    final headingRad = heading * math.pi / 180;
    final qiblaRad = (qibla - heading) * math.pi / 180;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Text(s.qiblaFromNorth(qibla.toStringAsFixed(0)),
            style: theme.textTheme.titleMedium),
        Text(location,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant)),
        if (needsCalibration)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.gesture, size: 16, color: scheme.tertiary),
                const SizedBox(width: 6),
                Text(s.calibrateHint,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.tertiary)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                  // Fixed top index — where the device is pointing.
                  Align(
                    alignment: Alignment.topCenter,
                    child: Icon(Icons.arrow_drop_up, size: 40, color: accent),
                  ),
                  // Cardinal dial, rotated so North tracks true north.
                  Transform.rotate(
                    angle: -headingRad,
                    child: _CompassRose(color: scheme.onSurfaceVariant),
                  ),
                  // Qibla needle pointing at the Ka'bah direction.
                  Transform.rotate(
                    angle: qiblaRad,
                    child: _QiblaNeedle(color: accent),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            aligned
                ? s.facingQibla
                : offset > 0
                    ? s.turnRight(offset.abs().toStringAsFixed(0))
                    : s.turnLeft(offset.abs().toStringAsFixed(0)),
            style: theme.textTheme.titleMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompassRose extends StatelessWidget {
  const _CompassRose({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget label(String text, Alignment alignment) {
      return Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            text,
            style: TextStyle(
              color: text == 'N' ? Colors.red.shade300 : color,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Stack(
        children: [
          label('N', Alignment.topCenter),
          label('E', Alignment.centerRight),
          label('S', Alignment.bottomCenter),
          label('W', Alignment.centerLeft),
        ],
      ),
    );
  }
}

class _QiblaNeedle extends StatelessWidget {
  const _QiblaNeedle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const Icon(Icons.mosque, color: Colors.white, size: 26),
        ),
        Container(width: 4, height: 96, color: color),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _NeedsLocation extends StatelessWidget {
  const _NeedsLocation({required this.locating, required this.onRetry});

  final bool locating;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppStrings.of(context);
    // Min-size column (not Center) for the same reason as [_Unavailable].
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined,
              size: 56, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 14),
          Text(s.qiblaNoLocation, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            s.qiblaNoLocationBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          locating
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : FilledButton.tonalIcon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.my_location, size: 18),
                  label: Text(s.useDeviceLocation),
                ),
        ],
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppStrings.of(context);
    // No Center wrapper: this widget is embedded in a scrolling page, where an
    // unbounded vertical Center would overflow. A min-size column self-sizes.
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.explore_off_outlined,
              size: 56, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 14),
          Text(s.compassUnavailable, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            s.compassUnavailableBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
