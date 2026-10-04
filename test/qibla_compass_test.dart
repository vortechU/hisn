import 'dart:math' as math;

import 'package:adhan/adhan.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/screens/qibla_screen.dart';
import 'package:dua_app/services/compass.dart';
import 'package:dua_app/services/geomag.dart';
import 'package:dua_app/services/prayer_service.dart';
import 'package:dua_app/services/prayer_settings.dart';
import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:dua_app/util/angles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A reading with nothing wrong with it, to vary one thing at a time from.
CompassReading good({
  double heading = 0,
  double pitch = 0,
  double roll = 0,
  double? accuracy = 15,
  double? field = 48,
}) =>
    CompassReading(
      heading: heading,
      pitch: pitch,
      roll: roll,
      accuracy: accuracy,
      fieldStrength: field,
    );

/// A field with a declination big enough that forgetting it is visible.
const amman = GeomagneticField(declination: 4.9, strength: 45.2);

void main() {
  group('bearing arithmetic', () {
    test('folds any angle into a single turn', () {
      expect(normalizeDegrees(0), 0);
      expect(normalizeDegrees(359.5), closeTo(359.5, 1e-9));
      expect(normalizeDegrees(360), 0);
      expect(normalizeDegrees(370), closeTo(10, 1e-9));
      expect(normalizeDegrees(-1), closeTo(359, 1e-9));
      expect(normalizeDegrees(-370), closeTo(350, 1e-9));
      // Android hands back [-180,180]; the first reading of a session can
      // legitimately be negative, and must not be drawn as-is.
      expect(normalizeDegrees(-120), closeTo(240, 1e-9));
    });

    test('takes the short way round the seam', () {
      expect(signedDelta(350, 10), closeTo(20, 1e-9));
      expect(signedDelta(10, 350), closeTo(-20, 1e-9));
      expect(signedDelta(0, 90), closeTo(90, 1e-9));
      expect(signedDelta(90, 0), closeTo(-90, 1e-9));
      expect(signedDelta(0, 359), closeTo(-1, 1e-9));
    });

    test('never proposes a turn longer than half a circle', () {
      for (var from = 0; from < 360; from += 7) {
        for (var to = 0; to < 360; to += 11) {
          final delta = signedDelta(from.toDouble(), to.toDouble());
          expect(delta, greaterThanOrEqualTo(-180));
          expect(delta, lessThan(180));
        }
      }
    });

  });

  group('the needle', () {
    /// Run [needle] for [seconds] at [fps], as the screen would.
    void run(NeedleSpring needle, double seconds, {double fps = 60}) {
      final frames = (seconds * fps).round();
      for (var i = 0; i < frames; i++) {
        needle.advance(1 / fps);
      }
    }

    test('starts where the first reading says, not from north', () {
      final needle = NeedleSpring()..aim(-120);
      expect(needle.angle, closeTo(240, 1e-9));
      expect(needle.atRest, isTrue);
    });

    test('travels to a new heading over time, rather than jumping', () {
      final needle = NeedleSpring()
        ..aim(10)
        ..aim(100);
      expect(needle.angle, 10, reason: 'aiming alone moves nothing');
      needle.advance(1 / 60);
      expect(needle.angle, greaterThan(10));
      expect(needle.angle, lessThan(20), reason: 'one frame is not the trip');
      run(needle, 1);
      expect(needle.angle, 100);
      expect(needle.atRest, isTrue);
    });

    test('settles without swinging past and back', () {
      final needle = NeedleSpring()
        ..aim(0)
        ..aim(90);
      var previous = 0.0;
      for (var i = 0; i < 120; i++) {
        needle.advance(1 / 60);
        expect(needle.angle, greaterThanOrEqualTo(previous));
        expect(needle.angle, lessThanOrEqualTo(90));
        previous = needle.angle!;
      }
    });

    test('does not overshoot when a steady turn stops', () {
      // The phone turning at 90°/s for a second, then held still. The needle
      // is carrying speed when the turn ends; it must not carry it past.
      final needle = NeedleSpring()..aim(0);
      for (var i = 1; i <= 60; i++) {
        needle
          ..aim(i * 1.5)
          ..advance(1 / 60);
      }
      for (var i = 0; i < 120; i++) {
        needle.advance(1 / 60);
        expect(needle.angle, lessThanOrEqualTo(90 + 1e-9));
      }
      expect(needle.angle, 90);
    });

    test('lands in the same place whatever the frame rate', () {
      // A 120 Hz screen, a 60 Hz one, and one that stalled for the whole
      // quarter second: the needle should be in the same place on all three.
      double after(double fps) {
        final needle = NeedleSpring()
          ..aim(0)
          ..aim(80);
        run(needle, 0.25, fps: fps);
        return needle.angle!;
      }

      final stalled = NeedleSpring()
        ..aim(0)
        ..aim(80)
        ..advance(0.25);
      expect(after(120), closeTo(after(60), 1e-9));
      expect(stalled.angle, closeTo(after(60), 1e-9));
      // And it is still on its way, not there already.
      expect(after(60), inExclusiveRange(10, 80));
    });

    test('crosses the seam the short way', () {
      // 355° toward 5°: through north, never back round through 180.
      final needle = NeedleSpring()
        ..aim(355)
        ..aim(5);
      for (var i = 0; i < 60; i++) {
        needle.advance(1 / 60);
        expect(signedDelta(355, normalizeDegrees(needle.angle!)).abs(),
            lessThanOrEqualTo(10 + 1e-9));
      }
      expect(normalizeDegrees(needle.angle!), closeTo(5, 1e-9));
    });

    test('follows the way the phone turned, readings at a time', () {
      // A full clockwise turn, reported a reading at a time. The target winds
      // on past 360 instead of snapping back, so the needle turns with it.
      final needle = NeedleSpring()..aim(0);
      for (var bearing = 10; bearing <= 370; bearing += 10) {
        needle.aim(normalizeDegrees(bearing.toDouble()));
      }
      expect(needle.target, closeTo(370, 1e-9));
    });

    test('holds steady through jitter', () {
      // A phone lying still, with the reading flickering ±2° about 100° at the
      // sensor's 50 Hz. The old per-reading smoothing let a tenth of that
      // through; the needle should show next to none of it.
      final needle = NeedleSpring()..aim(100);
      var widest = 0.0;
      for (var reading = 0; reading < 150; reading++) {
        needle.aim(reading.isEven ? 102 : 98);
        // Each reading's 20 ms in frames of a 60 Hz screen, near enough.
        for (var f = 0; f < (reading % 3 == 2 ? 2 : 1); f++) {
          needle.advance(1 / 60);
        }
        if (reading > 50) {
          widest = math.max(widest, (needle.angle! - 100).abs());
        }
      }
      expect(widest, lessThan(0.05));
    });

    test('does not move for a change too small to see', () {
      final needle = NeedleSpring()
        ..aim(42)
        ..aim(42.01);
      expect(needle.atRest, isTrue);
    });
  });

  group('reading a reading off the platform', () {
    test('a negative accuracy means unknown, not excellent', () {
      // The regression that mattered: the platform says "I have no idea" with
      // -1. Read as a number it is the best accuracy imaginable, and the
      // calibration warning would never appear again.
      final reading = CompassReading.fromMap(
        {'heading': 12.0, 'pitch': 1.0, 'roll': 2.0, 'accuracy': -1.0, 'field': -1.0},
      );
      expect(reading.accuracy, isNull);
      expect(reading.fieldStrength, isNull);
      expect(reading.heading, 12);
      expect(reading.pitch, 1);
      expect(reading.roll, 2);
    });

    test('keeps real values', () {
      final reading = CompassReading.fromMap(
        {'heading': 12.5, 'pitch': -3.0, 'roll': 0.0, 'accuracy': 30.0, 'field': 47.5},
      );
      expect(reading.accuracy, 30);
      expect(reading.fieldStrength, 47.5);
      expect(reading.pitch, -3);
    });

    test('survives a payload missing keys', () {
      final reading = CompassReading.fromMap(const {});
      expect(reading.heading, 0);
      expect(reading.accuracy, isNull);
      expect(reading.fieldStrength, isNull);
    });
  });

  group('when a reading may be trusted', () {
    test('a flat, calibrated phone in a normal field is fine', () {
      expect(CompassTrust.faults(good(), expectedField: 45.2), isEmpty);
    });

    test('an unknown accuracy is a fault, not a pass', () {
      // This is the whole bug. The old compass took its accuracy from whichever
      // sensor spoke last — usually the accelerometer, which is always happy —
      // so a magnetometer tens of degrees out never raised a word.
      expect(
        CompassTrust.faults(good(accuracy: null), expectedField: 45.2),
        contains(CompassFault.uncalibrated),
      );
    });

    test('Android\'s "medium" is not good enough for a Qibla', () {
      // 30° of error would put someone a room's width off over any distance
      // worth facing. Only the top bucket passes.
      expect(
        CompassTrust.faults(good(accuracy: 30), expectedField: 45.2),
        contains(CompassFault.uncalibrated),
      );
      expect(
        CompassTrust.faults(good(accuracy: 45), expectedField: 45.2),
        contains(CompassFault.uncalibrated),
      );
      expect(
        CompassTrust.faults(good(accuracy: 15), expectedField: 45.2),
        isNot(contains(CompassFault.uncalibrated)),
      );
    });

    test('tilt is judged on both axes, in either direction', () {
      expect(CompassTrust.faults(good(pitch: 40)), contains(CompassFault.tilted));
      expect(CompassTrust.faults(good(pitch: -40)), contains(CompassFault.tilted));
      expect(CompassTrust.faults(good(roll: 40)), contains(CompassFault.tilted));
      expect(CompassTrust.faults(good(roll: -40)), contains(CompassFault.tilted));
      // A phone held at a natural reading angle is still readable.
      expect(
        CompassTrust.faults(good(pitch: 20, roll: 20)),
        isNot(contains(CompassFault.tilted)),
      );
      // The threshold itself is not a fault.
      expect(
        CompassTrust.faults(good(pitch: CompassTrust.maxTilt)),
        isNot(contains(CompassFault.tilted)),
      );
    });

    test('a field far from the model means something magnetic is nearby', () {
      // A phone on a desk with a steel frame, or in a magnetic case.
      expect(
        CompassTrust.faults(good(field: 120), expectedField: 45.2),
        contains(CompassFault.interference),
      );
      expect(
        CompassTrust.faults(good(field: 5), expectedField: 45.2),
        contains(CompassFault.interference),
      );
      // Ordinary variation is not.
      expect(
        CompassTrust.faults(good(field: 50), expectedField: 45.2),
        isNot(contains(CompassFault.interference)),
      );
    });

    test('interference is not guessed at when there is nothing to compare to', () {
      // No model value means no opinion — inventing one would put a warning in
      // front of everyone whose location has not resolved yet.
      expect(
        CompassTrust.faults(good(field: 120)),
        isNot(contains(CompassFault.interference)),
      );
      expect(
        CompassTrust.faults(good(field: null), expectedField: 45.2),
        isNot(contains(CompassFault.interference)),
      );
    });

    test('the fault worth saying is the one that costs most to ignore', () {
      expect(
        CompassTrust.primary(
          {CompassFault.tilted, CompassFault.uncalibrated, CompassFault.interference},
        ),
        CompassFault.interference,
      );
      expect(
        CompassTrust.primary({CompassFault.tilted, CompassFault.uncalibrated}),
        CompassFault.uncalibrated,
      );
      expect(CompassTrust.primary({CompassFault.tilted}), CompassFault.tilted);
      expect(CompassTrust.primary(const {}), isNull);
    });
  });

  group('pointing at the Qibla', () {
    test('the declination is actually applied', () {
      // Facing magnetic north in Amman is facing 4.9° east of true north, so
      // the Qibla at 160.7° is 155.8° to the right, not 160.7°.
      final fix = QiblaFix.of(
        magneticHeading: 0,
        qibla: 160.7,
        reading: good(),
        field: amman,
      );
      expect(fix.heading, closeTo(4.9, 1e-9));
      expect(fix.offset, closeTo(155.8, 1e-9));
      expect(fix.corrected, isTrue);
    });

    test('without a field it stays on magnetic north and admits it', () {
      final fix = QiblaFix.of(
        magneticHeading: 0,
        qibla: 160.7,
        reading: good(),
      );
      expect(fix.heading, 0);
      expect(fix.offset, closeTo(160.7, 1e-9));
      expect(fix.corrected, isFalse);
    });

    test('the correction wraps rather than running past 360', () {
      final fix = QiblaFix.of(
        magneticHeading: 358,
        qibla: 0,
        reading: good(),
        field: amman,
      );
      expect(fix.heading, closeTo(2.9, 1e-9));
      expect(fix.offset, closeTo(-2.9, 1e-9));
    });

    test('facing the Qibla is never claimed on a reading known to be bad', () {
      // Dead on the bearing, but the magnetometer is uncalibrated. Saying "you
      // are facing the Qibla" here would be the app inventing a certainty it
      // does not have.
      final fix = QiblaFix.of(
        magneticHeading: 155.8,
        qibla: 160.7,
        reading: good(accuracy: null),
        field: amman,
      );
      expect(fix.offset.abs(), lessThan(QiblaFix.alignedWithin));
      expect(fix.fault, CompassFault.uncalibrated);
      expect(fix.aligned, isFalse);
    });

    test('and is claimed on a good one', () {
      final fix = QiblaFix.of(
        magneticHeading: 155.8,
        qibla: 160.7,
        reading: good(),
        field: amman,
      );
      expect(fix.fault, isNull);
      expect(fix.aligned, isTrue);
    });

    test('once facing it, a little drift does not call it off', () {
      // 6° off: not close enough to arrive at, but close enough to stay at.
      QiblaFix at(double offset, {required bool wasAligned}) => QiblaFix.of(
            magneticHeading: 100 - offset,
            qibla: 100,
            reading: good(),
            wasAligned: wasAligned,
          );

      expect(at(6, wasAligned: false).aligned, isFalse);
      expect(at(6, wasAligned: true).aligned, isTrue);
      expect(at(-6, wasAligned: true).aligned, isTrue);
      expect(at(QiblaFix.staysAlignedWithin + 0.5, wasAligned: true).aligned,
          isFalse);
    });

    test('a fault still overrides having been aligned', () {
      final fix = QiblaFix.of(
        magneticHeading: 100,
        qibla: 100,
        reading: good(accuracy: null),
        wasAligned: true,
      );
      expect(fix.aligned, isFalse);
    });

    test('says the turn in whole degrees, signed', () {
      QiblaFix facing(double heading) => QiblaFix.of(
            magneticHeading: heading,
            qibla: 160.7,
            reading: good(),
          );
      expect(facing(4.9).turn, 156);
      expect(facing(316.5).turn, -156);
    });

    test('reads the same only if it would say the same', () {
      QiblaFix facing(double heading, {double? accuracy = 15}) => QiblaFix.of(
            magneticHeading: heading,
            qibla: 160.7,
            reading: good(accuracy: accuracy),
          );
      // A tenth of a degree is the same words on screen.
      expect(facing(10).readsAs(facing(10.1)), isTrue);
      // A whole one is not.
      expect(facing(10).readsAs(facing(11)), isFalse);
      // Nor is the same heading with a fault.
      expect(facing(10).readsAs(facing(10, accuracy: null)), isFalse);
    });

    test('turns the shorter way across the seam', () {
      // Pointing at 350° true with the Qibla at 10°: a 20° turn right, not a
      // 340° turn left.
      final fix = QiblaFix.of(
        magneticHeading: 350,
        qibla: 10,
        reading: good(),
      );
      expect(fix.offset, closeTo(20, 1e-9));
    });
  });

  group('the compass on screen', () {
    // Everything above proves the arithmetic. This proves the arithmetic is
    // actually reached: that a reading crossing the platform boundary ends up
    // corrected, judged, and spoken about on screen.
    const compassChannel = 'hisn/compass';
    const geomag = MethodChannel('hisn/geomag');

    TestWidgetsFlutterBinding.ensureInitialized();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    setUp(() {
      // The EventChannel's own listen/cancel handshake travels as method calls
      // on a channel of the same name.
      messenger.setMockMethodCallHandler(
        const MethodChannel(compassChannel),
        (call) async => null,
      );
      messenger.setMockMethodCallHandler(
        geomag,
        (call) async =>
            {'declination': amman.declination, 'strength': amman.strength},
      );
    });

    tearDown(() {
      messenger.setMockMethodCallHandler(
          const MethodChannel(compassChannel), null);
      messenger.setMockMethodCallHandler(geomag, null);
    });

    /// Push one reading down the event channel, as the platform would.
    Future<void> push(CompassReading reading) =>
        messenger.handlePlatformMessage(
          compassChannel,
          const StandardMethodCodec().encodeSuccessEnvelope({
            'heading': reading.heading,
            'pitch': reading.pitch,
            'roll': reading.roll,
            'accuracy': reading.accuracy ?? -1.0,
            'field': reading.fieldStrength ?? -1.0,
          }),
          (_) {},
        );

    /// Push a reading and let the needle come to rest on it. Settling also
    /// proves the needle *does* come to rest — that a still phone stops
    /// asking for frames.
    Future<void> send(WidgetTester tester, CompassReading reading) async {
      await push(reading);
      await tester.pumpAndSettle();
    }

    /// [around] puts the compass somewhere it might be hidden.
    Future<void> pumpCompass(
      WidgetTester tester, {
      Widget Function(Widget compass)? around,
    }) async {
      SharedPreferences.setMockInitialValues({
        // A fixed manual location, so nothing reaches for GPS mid-test.
        'prayer_location_mode': LocationMode.manual.name,
        'prayer_lat': 31.9539,
        'prayer_lng': 35.9106,
        'prayer_location_label': 'Amman',
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PrayerService(prefs)),
          ChangeNotifierProvider(
              create: (_) => LocaleController(prefs)..setLang(AppLang.en)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppPalettes.emerald, arabicUi: false),
          home: Scaffold(
            body: (around ?? (compass) => compass)(
              const SingleChildScrollView(child: QiblaCompass()),
            ),
          ),
        ),
      ));
      await tester.pump();
    }

    testWidgets('glides to a new heading instead of jumping to it',
        (tester) async {
      await pumpCompass(tester);
      await send(tester, good(heading: 0));
      expect(find.text('Turn right 156°'), findsOneWidget);

      // A quarter turn to the right. One frame on, the needle is under way but
      // nowhere near there; given time, it arrives.
      await push(good(heading: 90));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Turn right 156°'), findsNothing);
      expect(find.text('Turn right 66°'), findsNothing);

      await tester.pumpAndSettle();
      expect(find.text('Turn right 66°'), findsOneWidget);
    });

    testWidgets('lets go of the sensors while its tab is out of sight',
        (tester) async {
      final calls = <String>[];
      messenger.setMockMethodCallHandler(
        const MethodChannel(compassChannel),
        (call) async {
          calls.add(call.method);
          return null;
        },
      );
      // The compass lives in an IndexedStack, built at launch behind whichever
      // tab is open.
      final tab = ValueNotifier<int>(1);
      addTearDown(tab.dispose);
      await pumpCompass(
        tester,
        around: (compass) => ValueListenableBuilder<int>(
          valueListenable: tab,
          builder: (context, index, _) => IndexedStack(
            index: index,
            children: [compass, const SizedBox()],
          ),
        ),
      );

      expect(calls, isEmpty, reason: 'built, but nobody can see it');
      // Nor is anything behind the other tab keeping the app drawing.
      expect(tester.binding.hasScheduledFrame, isFalse);

      tab.value = 0;
      await tester.pump();
      expect(calls, ['listen']);

      tab.value = 1;
      await tester.pump();
      expect(calls, ['listen', 'cancel']);
    });

    testWidgets('and while another page covers it', (tester) async {
      final calls = <String>[];
      messenger.setMockMethodCallHandler(
        const MethodChannel(compassChannel),
        (call) async {
          calls.add(call.method);
          return null;
        },
      );
      final covered = ValueNotifier<bool>(false);
      addTearDown(covered.dispose);
      // What the navigator does to a route under an opaque one.
      await pumpCompass(
        tester,
        around: (compass) => ValueListenableBuilder<bool>(
          valueListenable: covered,
          builder: (context, hidden, _) =>
              TickerMode(enabled: !hidden, child: compass),
        ),
      );
      expect(calls, ['listen']);

      covered.value = true;
      await tester.pump();
      expect(calls, ['listen', 'cancel']);

      covered.value = false;
      await tester.pump();
      expect(calls, ['listen', 'cancel', 'listen']);
    });

    testWidgets('turns the declination into what it tells you to do',
        (tester) async {
      await pumpCompass(tester);
      // Facing magnetic north in Amman. The Qibla is 160.7° true, and the
      // phone is already 4.9° east of true — so the turn is 155.8°, not 160.7°.
      // Getting this wrong by the declination is the entire bug.
      await send(tester, good(heading: 0));

      expect(find.text('Turn right 156°'), findsOneWidget);
      expect(find.text('Turn right 161°'), findsNothing);
      expect(find.text('Corrected to true north'), findsOneWidget);
    });

    testWidgets('says to calibrate when the platform will not vouch for it',
        (tester) async {
      await pumpCompass(tester);
      await send(tester, good(heading: 0, accuracy: null));

      expect(find.text('Move in a figure-8 to calibrate'), findsOneWidget);
      // And withholds the instruction it can no longer stand behind.
      expect(find.textContaining('Turn right'), findsNothing);
    });

    testWidgets('says to lay the phone flat when it is stood up',
        (tester) async {
      await pumpCompass(tester);
      await send(tester, good(heading: 0, pitch: 70));

      expect(
        find.text('Lay the phone flat to read the compass'),
        findsOneWidget,
      );
    });

    testWidgets('says what is wrong when the field is not the Earth\'s',
        (tester) async {
      await pumpCompass(tester);
      await send(tester, good(heading: 0, field: 140));

      expect(find.text('Move away from metal or magnets'), findsOneWidget);
    });

    testWidgets('does not congratulate you on a reading it cannot trust',
        (tester) async {
      await pumpCompass(tester);
      // Dead on the Qibla, but uncalibrated.
      await send(tester, good(heading: 155.8, accuracy: null));

      expect(find.text('You are facing the Qibla'), findsNothing);
    });

    testWidgets('and does when it can', (tester) async {
      await pumpCompass(tester);
      await send(tester, good(heading: 155.8));

      expect(find.text('You are facing the Qibla'), findsOneWidget);
    });
  });

  group('the bearing itself', () {
    // The needle can only ever be as right as the number it points at. These
    // are published Qibla bearings, held against the library that computes them.
    test('matches known Qibla directions', () {
      void expectBearing(String name, Coordinates at, double bearing) {
        expect(Qibla(at).direction, closeTo(bearing, 0.5), reason: name);
      }

      expectBearing('Amman', Coordinates(31.9539, 35.9106), 160.7);
      expectBearing('Cairo', Coordinates(30.0444, 31.2357), 136.1);
      expectBearing('London', Coordinates(51.5074, -0.1278), 119.0);
      expectBearing('New York', Coordinates(40.7128, -74.0060), 58.5);
      expectBearing('Jakarta', Coordinates(-6.2088, 106.8456), 295.1);
      expectBearing('Kuala Lumpur', Coordinates(3.1390, 101.6869), 292.5);
    });

    test('is due south from directly north of the Ka\'bah', () {
      // The one bearing that can be checked without a table: straight up the
      // same meridian, so the Qibla can only be straight back down it.
      expect(Qibla(Coordinates(22.4225, 39.8262)).direction, closeTo(180, 0.01));
    });
  });
}
