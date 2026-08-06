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

    test('smoothing crosses the seam without going the long way', () {
      // 355° heading toward 5°: the needle must pass through 0, not sweep back
      // through 180.
      final next = smoothAngle(355, 5, 0.5);
      expect(next, closeTo(0, 1e-9));
    });

    test('smoothing converges on the target and stays in range', () {
      var heading = 350.0;
      for (var i = 0; i < 200; i++) {
        heading = smoothAngle(heading, 40, 0.18);
        expect(heading, greaterThanOrEqualTo(0));
        expect(heading, lessThan(360));
      }
      expect(heading, closeTo(40, 0.01));
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
    Future<void> send(WidgetTester tester, CompassReading reading) async {
      await messenger.handlePlatformMessage(
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
      // The smoothing closes only part of the gap per reading, so a heading has
      // to be held for a moment before the needle has actually arrived.
      for (var i = 0; i < 80; i++) {
        await messenger.handlePlatformMessage(
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
      }
      await tester.pump();
    }

    Future<void> pumpCompass(WidgetTester tester) async {
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
          home: const Scaffold(body: SingleChildScrollView(child: QiblaCompass())),
        ),
      ));
      await tester.pump();
    }

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
