import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/geomag.dart';
import '../services/prayer_service.dart';
import '../theme/app_theme.dart';

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
    final ms = ManuscriptTheme.of(context);
    final s = AppStrings.of(context);

    // Offset of the Qibla from where the device currently points, in [-180,180].
    var offset = (qibla - heading) % 360;
    if (offset > 180) offset -= 360;
    if (offset < -180) offset += 360;
    final aligned = offset.abs() < 5;
    final accent = aligned ? ms.rubric : ms.gilt;

    // Accuracy is degrees of heading error; null means the platform flagged
    // the sensor as unreliable. Anything worse than the "medium" bucket (30°)
    // means the magnetometer needs calibration — a figure-8 wave fixes it.
    final needsCalibration = accuracy == null || accuracy! > 30;

    final headingRad = heading * math.pi / 180;
    final qiblaRad = (qibla - heading) * math.pi / 180;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 6),
        Text(location, style: theme.textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(s.qiblaFromNorth(qibla.toStringAsFixed(0)),
            style: theme.textTheme.titleMedium),
        if (needsCalibration)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.gesture, size: 15, color: ms.gilt),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(s.calibrateHint,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: ms.gilt)),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: SizedBox(
            width: 288,
            height: 288,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // The graduated dial, rotated so North tracks true north.
                Transform.rotate(
                  angle: -headingRad,
                  child: CustomPaint(
                    size: const Size.square(288),
                    painter: _DialPainter(
                      rule: ms.rule,
                      ink: scheme.onSurfaceVariant,
                      north: ms.rubric,
                      face: scheme.onSurface,
                    ),
                  ),
                ),
                // The Qibla index: a ruled line to a rosette at the rim.
                Transform.rotate(
                  angle: qiblaRad,
                  child: _QiblaIndex(color: accent, aligned: aligned),
                ),
                // Fixed mark for where the device itself points.
                Align(
                  alignment: Alignment.topCenter,
                  child: CustomPaint(
                    size: const Size(16, 13),
                    painter: _IndexMark(accent),
                  ),
                ),
              ],
            ),
          ),
        ),
        Text(
          aligned
              ? s.facingQibla
              : offset > 0
                  ? s.turnRight(offset.abs().toStringAsFixed(0))
                  : s.turnLeft(offset.abs().toStringAsFixed(0)),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(color: accent),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

/// The graduated dial: two rules, a tick for every five degrees with the
/// cardinals struck longer, and the four points lettered in the serif.
class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.rule,
    required this.ink,
    required this.north,
    required this.face,
  });

  final Color rule;
  final Color ink;
  final Color north;
  final Color face;

  static const _points = ['N', 'E', 'S', 'W'];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    final hair = Paint()
      ..color = rule
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = true;

    canvas.drawCircle(c, r - 1, hair);
    canvas.drawCircle(c, r - 26, hair);

    for (var deg = 0; deg < 360; deg += 5) {
      final major = deg % 45 == 0;
      final a = (deg - 90) * math.pi / 180;
      final outer = r - 2;
      final inner = outer - (major ? 15 : deg % 15 == 0 ? 9 : 5);
      canvas.drawLine(
        c + Offset(math.cos(a) * inner, math.sin(a) * inner),
        c + Offset(math.cos(a) * outer, math.sin(a) * outer),
        Paint()
          ..color = major ? ink : rule
          ..strokeWidth = major ? 1.6 : 1
          ..isAntiAlias = true,
      );
    }

    for (var i = 0; i < 4; i++) {
      final a = (i * 90 - 90) * math.pi / 180;
      final at = c + Offset(math.cos(a) * (r - 40), math.sin(a) * (r - 40));
      final painter = TextPainter(
        text: TextSpan(
          text: _points[i],
          style: TextStyle(
            fontFamily: AppTheme.serif,
            fontSize: 19,
            fontWeight: FontWeight.w600,
            color: i == 0 ? north : face,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, at - painter.size.center(Offset.zero));
    }
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.rule != rule ||
      old.ink != ink ||
      old.north != north ||
      old.face != face;
}

/// The Qibla index: a ruled line from the pivot out to a rosette that carries
/// the direction of the Ka'bah.
class _QiblaIndex extends StatelessWidget {
  const _QiblaIndex({required this.color, required this.aligned});

  final Color color;
  final bool aligned;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // A single ruled ring, not a lobed rosette: this is a compass head and
        // has to read as a pointer at a glance, not as ornament. It fills when
        // the device is lined up with the Qibla.
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: aligned ? color.withValues(alpha: 0.18) : null,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: aligned ? 2 : 1.4),
          ),
          child: Icon(Icons.mosque_outlined, size: 22, color: color),
        ),
        Container(width: 1.6, height: 92, color: color),
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        // Balances the rosette and shaft above so the pivot dot — not the
        // column's midpoint — lands on the centre of the dial.
        const SizedBox(height: 138),
      ],
    );
  }
}

/// The fixed mark at the top of the dial — a filled triangle showing where the
/// device is pointing.
class _IndexMark extends CustomPainter {
  _IndexMark(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color..isAntiAlias = true);
  }

  @override
  bool shouldRepaint(_IndexMark old) => old.color != color;
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
