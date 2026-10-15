import 'dart:io';
import 'dart:ui' as ui;

import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/data/quran_repository.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/screens/home_screen.dart';
import 'package:dua_app/screens/settings/appearance_settings_screen.dart';
import 'package:dua_app/services/adhkar_audio_library.dart';
import 'package:dua_app/services/custom_dua_service.dart';
import 'package:dua_app/services/display_settings.dart';
import 'package:dua_app/services/dua_progress_service.dart';
import 'package:dua_app/services/feature_tour_controller.dart';
import 'package:dua_app/services/muhassan_service.dart';
import 'package:dua_app/services/notification_service.dart';
import 'package:dua_app/services/prayer_service.dart';
import 'package:dua_app/services/quran_service.dart';
import 'package:dua_app/services/sunnah_calendar_service.dart';
import 'package:dua_app/services/theme_controller.dart';
import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:dua_app/widgets/feature_tour_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DuaRepository duas;
  late QuranRepository quran;
  const boundaryKey = ValueKey('tour-preview');
  const capture = bool.fromEnvironment('CAPTURE_FEEDBACK');

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('hisn/compass'),
          (_) async => null,
        );
    duas = DuaRepository();
    quran = QuranRepository();
    await Future.wait([duas.load(), quran.loadIndex()]);
    if (capture) {
      for (final (family, asset) in [
        ('Amiri', 'assets/fonts/Amiri-Regular.ttf'),
        ('Crimson Pro', 'assets/fonts/latin/CrimsonPro-Regular.ttf'),
        ('Karla', 'assets/fonts/latin/Karla-Regular.ttf'),
        ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
      ]) {
        await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
      }
    }
  });

  Future<SharedPreferences> prefs({
    bool seen = false,
    String lang = 'ar',
  }) async {
    SharedPreferences.setMockInitialValues({
      'app_language': lang,
      'prayer_location_mode': 'manual',
      'theme_palette': AppPalettes.all.last.id,
      'theme_mode': 'dark',
      FeatureTourController.seenKey: seen,
    });
    return SharedPreferences.getInstance();
  }

  Widget host(SharedPreferences p) => MultiProvider(
    key: UniqueKey(),
    providers: [
      Provider.value(value: duas),
      Provider.value(value: quran),
      Provider.value(value: AdhkarAudioLibrary.empty()),
      ChangeNotifierProvider(create: (_) => FeatureTourController(p)),
      ChangeNotifierProvider(create: (_) => LocaleController(p)),
      ChangeNotifierProvider(create: (_) => ThemeController(p)),
      ChangeNotifierProvider(create: (_) => PrayerService(p)),
      ChangeNotifierProvider(create: (_) => QuranService(p)),
      ChangeNotifierProvider(create: (_) => CustomDuaService(p)),
      ChangeNotifierProvider(create: (_) => DisplaySettings(p)),
      ChangeNotifierProvider(create: (_) => DuaProgressService(p)),
      ChangeNotifierProvider(create: (_) => MuhassanService(p)),
      ChangeNotifierProvider(create: (_) => NotificationService(p, duas)),
      ChangeNotifierProvider(create: (_) => SunnahCalendarService(p)),
    ],
    child: Consumer2<LocaleController, ThemeController>(
      builder: (context, locale, theme, _) => RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale.locale,
          supportedLocales: LocaleController.supported,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: AppTheme.light(theme.palette, arabicUi: locale.rtl),
          darkTheme: AppTheme.dark(theme.palette, arabicUi: locale.rtl),
          themeMode: theme.themeMode,
          home: const HomeScreen(),
        ),
      ),
    ),
  );

  Future<void> settle(WidgetTester tester) async {
    // The compass has a ticker on its visible tab; bounded frames also cover
    // the scroll-to-anchor and the subsequent layout measurement.
    for (var frame = 0; frame < 14; frame++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(tester.takeException(), isNull);
  }

  Future<void> save(WidgetTester tester, String name) async {
    if (!capture) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(boundaryKey),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/feedback-preview/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  test(
    'skip and finish persist while replay starts from the first feature',
    () async {
      final p = await prefs();
      final tour = FeatureTourController(p);
      expect(tour.seen, isFalse);
      tour.start();
      await tour.next();
      expect(tour.step, 1);
      await tour.finish();
      expect(FeatureTourController(p).seen, isTrue);
      tour.start();
      expect(tour.step, 0);
      for (var i = 0; i < FeatureTourController.stepCount; i++) {
        await tour.next();
      }
      expect(tour.active, isFalse);
      tour.dispose();
    },
  );

  for (final (device, size, lang, scale) in [
    ('phone-ar', const Size(390, 844), 'ar', 1.0),
    ('small-phone-ar', const Size(320, 568), 'ar', 1.3),
    ('tablet-ur', const Size(840, 1100), 'ur', 1.0),
  ]) {
    testWidgets(
      '$device guide measures five real targets and can replay/skip',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(() => tester.binding.setSurfaceSize(null));
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        HomeScreen.tab.value = HomeScreen.tabAdhkar;
        final p = await prefs(lang: lang);
        await tester.pumpWidget(host(p));
        await settle(tester);
        await tester.tap(
          find.byKey(const ValueKey('feature_guide_welcome_view')),
        );
        await settle(tester);
        for (var step = 0; step < 5; step++) {
          final overlay = tester.widget<FeatureTourOverlay>(
            find.byType(FeatureTourOverlay),
          );
          expect(overlay.step, step + 1);
          expect(overlay.targetRect, isNotNull);
          final rect = overlay.targetRect!;
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
          expect(rect.bottom, lessThanOrEqualTo(size.height));
          final panel = find.byKey(const ValueKey('feature_tour_panel'));
          final panelRect = tester.getRect(panel);
          expect(panelRect.top, greaterThanOrEqualTo(0));
          expect(panelRect.bottom, lessThanOrEqualTo(size.height));
          if (step == 0 || step == 3 || step == 4) {
            await save(tester, '$device-guide-${step + 1}');
          }
          final next = find.byKey(const ValueKey('feature_tour_next'));
          final skip = find.byKey(const ValueKey('feature_tour_skip'));
          expect(tester.getRect(next).bottom, lessThanOrEqualTo(size.height));
          expect(tester.getRect(skip).bottom, lessThanOrEqualTo(size.height));
          expect(next.hitTestable(), findsOneWidget);
          expect(skip.hitTestable(), findsOneWidget);
          await tester.tap(next);
          await settle(tester);
        }
        expect(find.byType(FeatureTourOverlay), findsNothing);
        expect(p.getBool(FeatureTourController.seenKey), isTrue);
        final replay = find.byKey(const ValueKey('replay_feature_guide'));
        await tester.ensureVisible(replay);
        await settle(tester);
        await tester.tap(replay);
        await settle(tester);
        expect(
          tester
              .widget<FeatureTourOverlay>(find.byType(FeatureTourOverlay))
              .step,
          1,
        );
        expect(HomeScreen.tab.value, HomeScreen.tabAdhkar);
        await tester.tap(find.byKey(const ValueKey('feature_tour_skip')));
        await settle(tester);
        expect(find.byType(FeatureTourOverlay), findsNothing);
        // The guide never grants permissions or turns reminders on.
        expect(p.getBool('notif_master_enabled'), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'welcome skip stays dismissed and home theme menu persists without changing palette',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      HomeScreen.tab.value = HomeScreen.tabAdhkar;
      final p = await prefs(lang: 'en');
      await tester.pumpWidget(host(p));
      await settle(tester);
      await tester.tap(
        find.byKey(const ValueKey('feature_guide_welcome_skip')),
      );
      await settle(tester);
      final palette = p.getString('theme_palette');
      for (final mode in ['light', 'dark', 'system']) {
        final menu = find.byKey(const ValueKey('home_appearance'));
        await tester.ensureVisible(menu);
        await tester.tap(menu);
        await settle(tester);
        await tester.tap(find.byKey(ValueKey('home_theme_$mode')));
        await settle(tester);
        expect(p.getString('theme_mode'), mode);
        expect(p.getString('theme_palette'), palette);
      }
      await tester.tap(find.byKey(const ValueKey('home_appearance')));
      await settle(tester);
      await tester.tap(find.text('Appearance').last);
      await settle(tester);
      expect(find.byType(AppearanceSettingsScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      HomeScreen.tab.value = HomeScreen.tabAdhkar;
      await tester.pumpWidget(host(p));
      await settle(tester);
      expect(
        find.byKey(const ValueKey('feature_guide_welcome_view')),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
