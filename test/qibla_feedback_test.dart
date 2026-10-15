import 'dart:io';
import 'dart:ui' as ui;

import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/screens/qibla_screen.dart';
import 'package:dua_app/services/compass.dart';
import 'package:dua_app/services/geomag.dart';
import 'package:dua_app/services/prayer_service.dart';
import 'package:dua_app/services/prayer_settings.dart';
import 'package:dua_app/services/qibla_preferences.dart';
import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _field = GeomagneticField(declination: 4.9, strength: 44);

CompassReading reading(double heading, {double accuracy = 5}) => CompassReading(
  heading: heading,
  pitch: 0,
  roll: 0,
  accuracy: accuracy,
  fieldStrength: 44,
);

QiblaFix fix(
  double offset, {
  bool prior = false,
  bool corrected = true,
  double accuracy = 5,
}) => QiblaFix.of(
  magneticHeading: 100 - offset - (corrected ? 4.9 : 0),
  qibla: 100,
  reading: reading(100 - offset, accuracy: accuracy),
  field: corrected ? _field : null,
  wasAligned: prior,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    if (Platform.environment['CAPTURE_QIBLA_PREVIEWS'] != '1') return;
    for (final (family, path) in [
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
      ('Amiri', 'assets/fonts/Amiri-Regular.ttf'),
      ('Crimson Pro', 'assets/fonts/latin/CrimsonPro-Regular.ttf'),
      ('Karla', 'assets/fonts/latin/Karla-Regular.ttf'),
    ]) {
      final font = FontLoader(family)..addFont(rootBundle.load(path));
      await font.load();
    }
  });

  test('alignment pulse has hysteresis, cooldown and trust gates', () {
    final feedback = QiblaAlignmentFeedback();
    bool update(
      QiblaFix value,
      int ms, {
      bool active = true,
      bool enabled = true,
    }) => feedback.update(
      fix: value,
      active: active,
      enabled: enabled,
      elapsed: Duration(milliseconds: ms),
    );
    expect(update(fix(0, corrected: false), 0), isFalse);
    expect(update(fix(0, accuracy: 20), 0), isFalse);
    expect(update(fix(0), 0, active: false), isFalse);
    expect(update(fix(0), 0), isTrue);
    expect(update(fix(0), 100), isFalse);
    expect(update(fix(6, prior: true), 200), isFalse);
    expect(update(fix(8, prior: true), 300), isFalse);
    expect(update(fix(0), 400), isFalse);
    expect(update(fix(0), 4000), isFalse);
    expect(update(fix(8), 4100), isFalse);
    expect(update(fix(0), 4200), isTrue);
    feedback.suspend();
    expect(update(fix(0), 8000, enabled: false), isFalse);
    expect(update(fix(0), 9000), isFalse);
  });

  test(
    'compass preferences persist and tolerate unknown saved options',
    () async {
      SharedPreferences.setMockInitialValues({'qibla_dial_style': 'removed'});
      final store = await SharedPreferences.getInstance();
      final prefs = QiblaPreferences(store);
      expect(prefs.style, QiblaDialStyle.classic);
      expect(prefs.tone, QiblaDialTone.accent);
      await prefs.setStyle(QiblaDialStyle.rose);
      await prefs.setTone(QiblaDialTone.gold);
      await prefs.setVibration(false);
      final reloaded = QiblaPreferences(store);
      expect(reloaded.style, QiblaDialStyle.rose);
      expect(reloaded.tone, QiblaDialTone.gold);
      expect(reloaded.vibration, isFalse);
    },
  );

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final pulses = <String>[];
  setUp(() {
    pulses.clear();
    messenger.setMockMethodCallHandler(
      const MethodChannel('hisn/compass'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('hisn/geomag'),
      (_) async => {'declination': 4.9, 'strength': 44.0},
    );
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        pulses.add(call.arguments as String);
      }
      return null;
    });
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(
      const MethodChannel('hisn/compass'),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('hisn/geomag'),
      null,
    );
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> push(WidgetTester tester, CompassReading value) async {
    await messenger.handlePlatformMessage(
      'hisn/compass',
      const StandardMethodCodec().encodeSuccessEnvelope({
        'heading': value.heading,
        'pitch': value.pitch,
        'roll': value.roll,
        'accuracy': value.accuracy,
        'field': value.fieldStrength,
      }),
      (_) {},
    );
    await tester.pump();
  }

  final previewKey = GlobalKey();
  Future<void> pumpCompass(
    WidgetTester tester, {
    AppLang lang = AppLang.en,
    bool vibration = true,
    QiblaDialStyle style = QiblaDialStyle.classic,
    bool visible = true,
    double textScale = 1,
    bool dark = false,
  }) async {
    SharedPreferences.setMockInitialValues({
      'prayer_location_mode': LocationMode.manual.name,
      'prayer_lat': 31.9539,
      'prayer_lng': 35.9106,
      'prayer_location_label': 'Amman',
      'app_language': lang.name,
      'qibla_alignment_vibration': vibration,
      'qibla_dial_style': style.name,
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PrayerService(prefs)),
          ChangeNotifierProvider(create: (_) => LocaleController(prefs)),
        ],
        child: MaterialApp(
          theme: dark
              ? AppTheme.dark(AppPalettes.emerald, arabicUi: lang == AppLang.ar)
              : AppTheme.light(
                  AppPalettes.emerald,
                  arabicUi: lang == AppLang.ar,
                ),
          home: Scaffold(
            body: Directionality(
              textDirection: lang == AppLang.ar
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
                child: Visibility(
                  visible: visible,
                  maintainState: true,
                  child: RepaintBoundary(
                    key: previewKey,
                    child: ColoredBox(
                      color: dark
                          ? const Color(0xFF1B211E)
                          : const Color(0xFFF7F5EB),
                      child: const SingleChildScrollView(child: QiblaCompass()),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('trusted alignment pulses once, rebuilding style never pulses', (
    tester,
  ) async {
    await pumpCompass(tester);
    await push(tester, reading(155.8, accuracy: 20));
    expect(pulses, isEmpty);
    await push(tester, reading(155.8));
    expect(pulses, ['HapticFeedbackType.mediumImpact']);
    await push(tester, reading(155.8));
    expect(pulses, hasLength(1));
    await tester.tap(find.byTooltip('Compass design'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Minimal').last);
    await tester.pumpAndSettle();
    expect(find.text('Minimal'), findsOneWidget);
    expect(pulses, hasLength(1));
    expect(
      (await SharedPreferences.getInstance()).getString('qibla_dial_style'),
      'minimal',
    );
  });

  testWidgets('disabled and hidden compasses never vibrate', (tester) async {
    await pumpCompass(tester, vibration: false);
    await push(tester, reading(155.8));
    expect(pulses, isEmpty);
    await tester.pumpWidget(const SizedBox());
    await pumpCompass(tester, visible: false);
    await push(tester, reading(155.8));
    expect(pulses, isEmpty);
  });

  testWidgets('inactive app cannot pulse from queued sensor readings', (
    tester,
  ) async {
    await pumpCompass(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await push(tester, reading(155.8));
    expect(pulses, isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await push(tester, reading(155.8));
    expect(pulses, hasLength(1));
  });

  testWidgets('all styles fit phone width and enlarged localized controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final style in QiblaDialStyle.values) {
      for (final lang in AppLang.values) {
        await tester.pumpWidget(const SizedBox());
        await pumpCompass(
          tester,
          lang: lang,
          style: style,
          textScale: 1.5,
          dark: style == QiblaDialStyle.rose,
        );
        await push(tester, reading(90));
        expect(tester.takeException(), isNull);
        if (Platform.environment['CAPTURE_QIBLA_PREVIEWS'] == '1' &&
            lang == AppLang.ar) {
          await tester.runAsync(() async {
            final boundary =
                previewKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 1);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File('tool/feedback/qibla-preview-${style.name}.png');
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
    }
  });
}
