import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/compass.dart';
import '../services/geomag.dart';
import '../services/prayer_service.dart';
import '../theme/app_theme.dart';
import '../util/angles.dart';

/// A live compass pointing toward the Qibla (the Ka'bah in Makkah), from the
/// device magnetometer and the Qibla bearing for the current location.
///
/// Two corrections stand between a magnetometer and a Qibla, and the screen
/// gets neither of them for free:
///
/// * The sensor reads **magnetic** north; the Qibla bearing is measured from
///   **true** north. The gap between them — the declination — runs to twenty
///   degrees in some places, and is applied here from the World Magnetic Model.
/// * A magnetometer that is uncalibrated, tilted, or sitting near metal is
///   wrong in a way that looks exactly like being right: the needle is just as
///   steady. So each reading is checked against [CompassTrust], and when it
///   fails the screen says which of the three it is instead of quietly
///   pointing somewhere.
///
/// The needle is moved by a spring stepped once a frame (see [NeedleSpring]),
/// not once a reading, so it glides at the screen's own rate between readings
/// instead of stepping at the sensor's, and the visible left/right wobble is
/// filtered out on the way.
///
/// Self-contained (no Scaffold) so it can sit inside the combined
/// "Prayer & Qibla" page above the prayer-times list.
class QiblaCompass extends StatefulWidget {
  const QiblaCompass({super.key});

  @override
  State<QiblaCompass> createState() => _QiblaCompassState();
}

class _QiblaCompassState extends State<QiblaCompass>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  /// The needle, pulled toward the latest *magnetic* heading. True north is
  /// [QiblaFix]'s business, applied where the needle is read.
  final _needle = NeedleSpring();

  /// The needle's angle, published once a frame. Only the two turning layers
  /// listen to it, so a frame of motion rebuilds nothing else.
  final _needleAngle = ValueNotifier<double>(0);

  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;

  /// The most recent reading, kept whole for its tilt, accuracy and field
  /// strength — the three things that say whether the needle means anything.
  CompassReading? _reading;

  /// The fix the dial was last built from. A frame that would say the same
  /// thing again is not worth a rebuild; see [QiblaFix.readsAs].
  QiblaFix? _shown;

  /// The Earth's field where the user is standing. Null while it is still
  /// being fetched, or if it can't be had at all.
  GeomagneticField? _field;
  double? _fieldLat;
  double? _fieldLng;

  /// Set when the platform says there is no magnetometer behind the channel.
  bool _unavailable = false;

  StreamSubscription<CompassReading>? _sub;

  /// Whether anyone can see this compass: its tab is the one selected and no
  /// other page covers it.
  bool _onScreen = false;

  /// Whether the app itself is in the foreground.
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_onTick);
    _unavailable = DeviceCompass.readings == null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final onScreen =
        Visibility.of(context) && TickerMode.valuesOf(context).enabled;
    if (onScreen == _onScreen) return;
    _onScreen = onScreen;
    _syncSensors();
    if (!onScreen) return;
    // The startup location attempt runs only once and can fail (indoors, slow
    // GPS). Without real coordinates the Qibla bearing is meaningless, so try
    // again whenever the compass comes into view without them.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prayer = context.read<PrayerService>();
      if (!prayer.hasKnownLocation) prayer.refreshLocation();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _ticker.dispose();
    _needleAngle.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _foreground = true;
      case AppLifecycleState.paused:
        _foreground = false;
      default:
        return;
    }
    _syncSensors();
  }

  /// Hold the sensors exactly while someone can see the needle.
  ///
  /// Two sensors at fifty readings a second are not free. The compass lives in
  /// an [IndexedStack], built at launch and kept built behind the other tabs,
  /// so going by the app's lifecycle alone would run them — and redraw — the
  /// whole time the app is open, on whichever tab.
  void _syncSensors() {
    final wanted = _onScreen && _foreground && !_unavailable;
    if (wanted && _sub == null) {
      _sub = DeviceCompass.readings!.listen(
        _onReading,
        onError: (_) {
          if (!mounted) return;
          setState(() => _unavailable = true);
          _syncSensors();
        },
      );
    } else if (!wanted && _sub != null) {
      _sub!.cancel();
      _sub = null;
      _ticker.stop();
    }
  }

  void _onReading(CompassReading reading) {
    if (!mounted) return;
    final first = _reading == null;
    _reading = reading;
    _needle.aim(reading.heading);

    if (first) {
      // The spinner gives way to the dial, with the needle already in place.
      _needleAngle.value = _needle.angle!;
      setState(() {});
      return;
    }
    if (!_ticker.isActive && !_needle.atRest) {
      _lastTick = Duration.zero;
      _ticker.start();
    }
    // Tilt, calibration and field strength can change with the needle still.
    _rebuildIfChanged();
  }

  void _onTick(Duration elapsed) {
    final seconds = (elapsed - _lastTick).inMicroseconds /
        Duration.microsecondsPerSecond;
    _lastTick = elapsed;
    _needle.advance(seconds);
    _needleAngle.value = _needle.angle!;
    // A phone lying still costs no frames.
    if (_needle.atRest) _ticker.stop();
    _rebuildIfChanged();
  }

  /// Rebuild the dial only if the words or colours on it would change.
  void _rebuildIfChanged() {
    final shown = _shown;
    final angle = _needle.angle;
    final reading = _reading;
    if (shown == null || angle == null || reading == null) return;
    final next = QiblaFix.of(
      magneticHeading: angle,
      qibla: context.read<PrayerService>().qiblaDirection,
      reading: reading,
      field: _field,
      wasAligned: shown.aligned,
    );
    if (!next.readsAs(shown)) setState(() {});
  }

  /// Fetch the field for [lat],[lng] once per location change.
  void _ensureField(double lat, double lng) {
    if (_fieldLat == lat && _fieldLng == lng) return;
    _fieldLat = lat;
    _fieldLng = lng;
    Geomag.at(lat, lng).then((value) {
      if (mounted) setState(() => _field = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Out of sight, nothing in here should be asking for frames — a spinner
    // turning behind another tab keeps the whole app drawing.
    return TickerMode(enabled: _onScreen, child: _buildCompass(context));
  }

  Widget _buildCompass(BuildContext context) {
    final prayer = context.watch<PrayerService>();
    _ensureField(prayer.latitude, prayer.longitude);
    final s = AppStrings.of(context);

    if (_unavailable) return const _Unavailable();
    // Still on the Makkah fallback: there is no real bearing to show, so ask
    // for a location instead of confidently pointing the needle at nonsense.
    if (!prayer.hasKnownLocation) {
      return _NeedsLocation(
        locating: prayer.isLocating,
        onRetry: () => context.read<PrayerService>().refreshLocation(),
      );
    }

    final magnetic = _needle.angle;
    final reading = _reading;
    if (magnetic == null || reading == null) {
      return const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final fix = _shown = QiblaFix.of(
      magneticHeading: magnetic,
      qibla: prayer.qiblaDirection,
      reading: reading,
      field: _field,
      wasAligned: _shown?.aligned ?? false,
    );
    return _Compass(
      fix: fix,
      qibla: prayer.qiblaDirection,
      declination: _field?.declination ?? 0,
      needle: _needleAngle,
      location: s.place(prayer.locationLabel),
    );
  }
}

class _Compass extends StatelessWidget {
  const _Compass({
    required this.fix,
    required this.qibla,
    required this.declination,
    required this.needle,
    required this.location,
  });

  /// What is said about the needle: rebuilt only when that changes.
  final QiblaFix fix;
  final double qibla;
  final double declination;

  /// Where the needle is this frame: magnetic, unwrapped. The dial and the
  /// Qibla index follow it without this widget being rebuilt.
  final ValueListenable<double> needle;
  final String location;

  static const _fade = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ms = ManuscriptTheme.of(context);
    final s = AppStrings.of(context);

    final fault = fix.fault;
    final aligned = fix.aligned;
    final turn = fix.turn;
    // A muted needle for a reading that can't be trusted: the dial stays put so
    // nothing jumps, but it stops looking like an answer.
    final accent = fault != null
        ? scheme.onSurfaceVariant
        : aligned
            ? ms.rubric
            : ms.gilt;

    // Painted once and kept as a layer: each frame only turns it.
    final dial = RepaintBoundary(
      child: CustomPaint(
        size: const Size.square(288),
        painter: _DialPainter(
          rule: ms.rule,
          ink: scheme.onSurfaceVariant,
          north: ms.rubric,
          face: scheme.onSurface,
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 6),
        Text(location, style: theme.textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(s.qiblaFromNorth(qibla.toStringAsFixed(0)),
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 2),
        // Which north the needle is actually on. Small, but it is the whole
        // difference between a Qibla and a bearing that is merely nearby.
        Text(
          fix.corrected ? s.qiblaTrueNorth : s.qiblaMagneticOnly,
          style: theme.textTheme.bodySmall?.copyWith(
            color: fix.corrected ? scheme.onSurfaceVariant : ms.gilt,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          // Its own layer, so the frames spent turning the needle repaint
          // this square and not the page around it.
          child: RepaintBoundary(
            child: SizedBox(
              width: 288,
              height: 288,
              // The needle's colour eases between states rather than snapping,
              // most of all onto the Qibla.
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: accent),
                duration: _fade,
                builder: (context, color, _) => Stack(
                  alignment: Alignment.center,
                  children: [
                    // The graduated dial, turned so North tracks true north.
                    _Turning(
                      needle: needle,
                      degrees: (magnetic) => -(magnetic + declination),
                      child: dial,
                    ),
                    // The Qibla index: a ruled line to a rosette at the rim.
                    // Measured from the needle rather than from [fix], which
                    // is only as fresh as the last time the words changed.
                    _Turning(
                      needle: needle,
                      degrees: (magnetic) => qibla - (magnetic + declination),
                      child: RepaintBoundary(
                        child: _QiblaIndex(
                          color: color ?? accent,
                          aligned: aligned,
                        ),
                      ),
                    ),
                    // Fixed mark for where the device itself points.
                    Align(
                      alignment: Alignment.topCenter,
                      child: CustomPaint(
                        size: const Size(16, 13),
                        painter: _IndexMark(color ?? accent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Fades between kinds of answer — a fault, a turn, the Qibla — but not
        // between one number and the next, which would only blur them.
        AnimatedSwitcher(
          duration: _fade,
          child: fault != null
              ? _FaultNote(key: ValueKey(fault), fault: fault)
              : Text(
                  aligned
                      ? s.facingQibla
                      : turn > 0
                          ? s.turnRight('$turn')
                          : s.turnLeft('${-turn}'),
                  key: ValueKey(aligned),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: accent,
                    // Every digit the same width, so the line doesn't shuffle
                    // sideways as the number counts down.
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}

/// What to do about a reading that can't be trusted, standing where the turn
/// instruction would otherwise be.
///
/// It replaces that instruction rather than sitting beside it. "Turn right 40°"
/// next to "this compass is wrong" leaves the reader to work out which of the
/// two to believe, and they opened the compass to be told.
class _FaultNote extends StatelessWidget {
  const _FaultNote({super.key, required this.fault});

  final CompassFault fault;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final s = AppStrings.of(context);

    final (IconData icon, String message) = switch (fault) {
      CompassFault.interference => (
          Icons.warning_amber_rounded,
          s.qiblaInterference,
        ),
      CompassFault.uncalibrated => (Icons.gesture, s.calibrateHint),
      CompassFault.tilted => (Icons.phone_android, s.qiblaHoldFlat),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: ms.gilt),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: ms.gilt),
            ),
          ),
        ],
      ),
    );
  }
}

/// [child] turned to wherever [needle] puts it, frame by frame, without
/// [child] itself being rebuilt or repainted.
class _Turning extends StatelessWidget {
  const _Turning({
    required this.needle,
    required this.degrees,
    required this.child,
  });

  final ValueListenable<double> needle;

  /// The clockwise turn, in degrees, for a given needle angle.
  final double Function(double needle) degrees;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: needle,
      child: child,
      builder: (context, angle, child) => Transform.rotate(
        angle: degrees(angle) * math.pi / 180,
        child: child,
      ),
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
    final cardinal = Paint()
      ..color = ink
      ..strokeWidth = 1.6
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
        major ? cardinal : hair,
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
      painter
        ..paint(canvas, at - painter.size.center(Offset.zero))
        ..dispose();
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
