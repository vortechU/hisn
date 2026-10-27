import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// Android adapter contract checks intentionally exercise the transitive plugins.
// ignore: depend_on_referenced_packages
import 'package:geocoding_android/geocoding_android.dart';
// ignore: depend_on_referenced_packages
import 'package:geolocator_android/geolocator_android.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/data/quran_repository.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/models/quran.dart';
import 'package:dua_app/screens/prayer_qibla_screen.dart';
import 'package:dua_app/screens/quran_bookmarks_screen.dart';
import 'package:dua_app/services/backup_service.dart';
import 'package:dua_app/services/display_settings.dart';
import 'package:dua_app/services/dua_progress_service.dart';
import 'package:dua_app/services/notification_service.dart';
import 'package:dua_app/services/prayer_service.dart';
import 'package:dua_app/services/prayer_settings.dart';
import 'package:dua_app/services/prayer_widget_service.dart';
import 'package:dua_app/services/quran_service.dart';
import 'package:dua_app/services/sunnah_calendar_service.dart';
import 'package:dua_app/services/tasbih_controller.dart';
import 'package:dua_app/services/theme_controller.dart';
import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:dua_app/widgets/prayer_header.dart';

const manualPrefs = <String, Object>{
  'prayer_location_mode': 'manual',
  'prayer_lat': 21.4225,
  'prayer_lng': 39.8262,
  'prayer_location_label': 'Makkah',
};

class BoundaryPrayerService extends PrayerService {
  BoundaryPrayerService(super.prefs);
  final boundary = DateTime.now().add(const Duration(seconds: 2));
  @override
  List<PrayerTiming> get todaysPrayers => [
    PrayerTiming(Prayer.fajr, boundary.subtract(const Duration(hours: 4))),
    PrayerTiming(Prayer.dhuhr, boundary),
    PrayerTiming(Prayer.asr, boundary.add(const Duration(hours: 3))),
    PrayerTiming(Prayer.maghrib, boundary.add(const Duration(hours: 5))),
    PrayerTiming(Prayer.isha, boundary.add(const Duration(hours: 6))),
  ];
  @override
  List<DayMarkTiming> get todaysMarks => [];
  @override
  PrayerTiming? nextPrayer(DateTime now) =>
      todaysPrayers.firstWhere((p) => p.time.isAfter(now));
}

class PendingVerseRepository extends QuranRepository {
  int requests = 0;
  final pending = Completer<PageVerse?>();
  @override
  Future<PageVerse?> verse(int surah, int ayah, {String? lang}) {
    requests++;
    return pending.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const widgetChannel = MethodChannel('hisn/widget');
  const geoChannel = MethodChannel('flutter.baseflow.com/geolocator_android');
  const townChannel = MethodChannel('flutter.baseflow.com/geocoding');
  late DuaRepository repo;

  setUpAll(() async {
    GeocodingAndroid.registerWith();
    GeolocatorAndroid.registerWith();
    for (final name in [
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(name),
        (_) async => null,
      );
    }
    messenger.setMockMethodCallHandler(
      const MethodChannel('hisn/compass'),
      (_) async => null,
    );
    repo = DuaRepository();
    await repo.load();
  });

  tearDown(() {
    for (final channel in [widgetChannel, geoChannel, townChannel]) {
      messenger.setMockMethodCallHandler(channel, null);
    }
  });

  test('full widget refresh preserves a selected custom tasbih', () async {
    SharedPreferences.setMockInitialValues(manualPrefs);
    final prefs = await SharedPreferences.getInstance();
    final tasbih = TasbihController(prefs);
    final custom = await tasbih.addCustom(
      name: 'My phrase',
      arabic: 'سبحان الله',
      target: 77,
    );
    final pushed = <String, String>{};
    messenger.setMockMethodCallHandler(widgetChannel, (call) async {
      if (call.method == 'update') {
        pushed.addAll(
          ((call.arguments as Map)['data'] as Map).cast<String, String>(),
        );
      }
      return null;
    });
    await tasbih.select(custom);
    expect(pushed['tasbih_id'], custom.id);
    final prayer = PrayerService(prefs);
    final notifications = NotificationService(prefs, repo);
    final service = PrayerWidgetService(repo);
    service.bind(
      prayer,
      LocaleController(prefs),
      SunnahCalendarService(prefs),
      ThemeController(prefs),
      DisplaySettings(prefs),
      DuaProgressService(prefs),
      tasbih,
      notifications,
    );
    await Future<void>.delayed(const Duration(milliseconds: 650));
    service.dispose();
    prayer.dispose();
    notifications.dispose();
    tasbih.dispose();
    expect(pushed['tasbih_id'], custom.id);
  });

  test('backup preserves the selected tasbih', () async {
    SharedPreferences.setMockInitialValues({
      ...manualPrefs,
      'tasbih_selected': 'custom_dhikr_42',
    });
    final prefs = await SharedPreferences.getInstance();
    final data =
        const BackupService().build(prefs, appVersion: 'audit')['data'] as Map;
    expect(data.containsKey('tasbih_selected'), isTrue);
  });

  Future<(PrayerService, Future<void>, Completer<Object?>)> pendingGps() async {
    SharedPreferences.setMockInitialValues(manualPrefs);
    final prefs = await SharedPreferences.getInstance();
    final geocodingStarted = Completer<void>();
    final town = Completer<Object?>();
    messenger.setMockMethodCallHandler(geoChannel, (call) async {
      switch (call.method) {
        case 'isLocationServiceEnabled':
          return true;
        case 'checkPermission':
          return 3;
        case 'getCurrentPosition':
          return {
            'latitude': 24.4672,
            'longitude': 39.6111,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'accuracy': 20.0,
            'altitude': 0.0,
            'heading': 0.0,
            'speed': 0.0,
            'speed_accuracy': 0.0,
          };
      }
      return null;
    });
    messenger.setMockMethodCallHandler(townChannel, (call) async {
      if (call.method == 'placemarkFromCoordinates') {
        geocodingStarted.complete();
        return town.future;
      }
      return null;
    });
    final prayer = PrayerService(prefs);
    final pending = prayer.useDeviceLocation();
    await geocodingStarted.future.timeout(const Duration(seconds: 2));
    return (prayer, pending, town);
  }

  test('late geocoder cannot overwrite a manual city', () async {
    final (prayer, pending, town) = await pendingGps();
    await prayer.useManualCity(
      presetCities.firstWhere((city) => city.name == 'Riyadh'),
    );
    town.complete([
      {'locality': 'Madinah'},
    ]);
    await pending;
    final label = prayer.locationLabel;
    prayer.dispose();
    expect(label, 'Riyadh');
  });

  test('GPS completion after provider disposal is safe', () async {
    final (prayer, pending, town) = await pendingGps();
    prayer.dispose();
    town.complete([
      {'locality': 'Madinah'},
    ]);
    await pending;
  });

  test('concurrent page loads share the decoded page', () async {
    final quran = QuranRepository();
    final pages = await Future.wait([quran.loadPage(20), quran.loadPage(20)]);
    expect(identical(pages[0], pages[1]), isTrue);
  });

  testWidgets('visible prayer timetable advances after a prayer boundary', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(manualPrefs);
    final prefs = await SharedPreferences.getInstance();
    final prayer = BoundaryPrayerService(prefs);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PrayerService>.value(value: prayer),
          ChangeNotifierProvider(create: (_) => LocaleController(prefs)),
          ChangeNotifierProvider(create: (_) => DisplaySettings(prefs)),
        ],
        child: MaterialApp(
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: LocaleController.supported,
          theme: AppTheme.light(AppPalettes.fallback),
          home: const PrayerQiblaScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(
      tester.widget<PrayerTimetable>(find.byType(PrayerTimetable)).next!.prayer,
      Prayer.dhuhr,
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 2100));
    });
    await tester.pump(const Duration(minutes: 1));
    final shown = tester
        .widget<PrayerTimetable>(find.byType(PrayerTimetable))
        .next!
        .prayer;
    await tester.pumpWidget(const SizedBox.shrink());
    prayer.dispose();
    expect(shown, Prayer.asr);
  });

  testWidgets('saved verses only start loads near the viewport', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'quran_bookmark_ayahs': [for (var i = 1; i <= 100; i++) '2:$i'],
    });
    final prefs = await SharedPreferences.getInstance();
    final quran = PendingVerseRepository();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<QuranRepository>.value(value: quran),
          ChangeNotifierProvider(create: (_) => QuranService(prefs)),
          ChangeNotifierProvider(create: (_) => LocaleController(prefs)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppPalettes.fallback),
          home: const QuranBookmarksScreen(),
        ),
      ),
    );
    final requests = quran.requests;
    await tester.pumpWidget(const SizedBox.shrink());
    expect(requests, lessThan(20));
  });

  testWidgets('timed out GPS request cancels its native location work', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(manualPrefs);
    final prefs = await SharedPreferences.getInstance();
    final calls = <String>[];
    final position = Completer<Object?>();
    messenger.setMockMethodCallHandler(geoChannel, (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'isLocationServiceEnabled':
          return true;
        case 'checkPermission':
          return 3;
        case 'getCurrentPosition':
          return position.future;
      }
      return null;
    });
    final prayer = PrayerService(prefs);
    final pending = prayer.useDeviceLocation();
    for (var i = 0; i < 10 && !calls.contains('getCurrentPosition'); i++) {
      await tester.pump();
    }
    expect(calls, contains('getCurrentPosition'));
    await tester.pump(const Duration(seconds: 9));
    await pending;
    prayer.dispose();
    position.complete(null);
    expect(calls, contains('cancelGetCurrentPosition'));
  });
}
