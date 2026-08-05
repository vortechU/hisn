import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/data/quran_repository.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/screens/adhkar_screen.dart';
import 'package:dua_app/screens/category_duas_screen.dart';
import 'package:dua_app/screens/custom_duas_screen.dart';
import 'package:dua_app/screens/favorites_screen.dart';
import 'package:dua_app/screens/home_screen.dart';
import 'package:dua_app/screens/prayer_schedule_screen.dart';
import 'package:dua_app/screens/quran_screen.dart';
import 'package:dua_app/screens/search_screen.dart';
import 'package:dua_app/screens/settings/about_settings_screen.dart';
import 'package:dua_app/screens/settings/appearance_settings_screen.dart';
import 'package:dua_app/screens/settings/backup_settings_screen.dart';
import 'package:dua_app/screens/settings/display_settings_screen.dart';
import 'package:dua_app/screens/settings/language_settings_screen.dart';
import 'package:dua_app/screens/settings_screen.dart';
import 'package:dua_app/screens/streak_stats_screen.dart';
import 'package:dua_app/screens/tasbih_screen.dart';
import 'package:dua_app/services/backup_service.dart';
import 'package:dua_app/services/custom_dua_service.dart';
import 'package:dua_app/services/display_settings.dart';
import 'package:dua_app/services/dua_progress_service.dart';
import 'package:dua_app/services/favorites_service.dart';
import 'package:dua_app/services/muhassan_service.dart';
import 'package:dua_app/services/prayer_service.dart';
import 'package:dua_app/services/quran_service.dart';
import 'package:dua_app/services/tasbih_controller.dart';
import 'package:dua_app/services/theme_controller.dart';
import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';

/// Renders every screen at several sizes, palettes and text scales, and fails
/// on any layout overflow.
///
/// The manuscript layout leans on ruled rows and side-by-side Latin/Arabic
/// pairs, both of which are easy to overflow on a narrow phone or at a large
/// accessibility text scale — and neither `flutter analyze` nor a single
/// screenshot would catch it. This does.
/// Stands in for a picked backup file, with figures wide enough to be a real
/// layout test (four digits, not zeroes).
final _sampleBackup = Backup(
  formatVersion: BackupService.formatVersion,
  appVersion: '1.9.0',
  createdAt: DateTime(2026, 12, 28),
  summary: const BackupSummary(
    streak: 365,
    bestStreak: 1024,
    fortifiedDays: 2048,
    favorites: 128,
    customDuas: 64,
    quranBookmarks: 256,
  ),
  values: const {'muhassan_streak': 365},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DuaRepository repo;
  late QuranRepository quran;
  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = DuaRepository();
    quran = QuranRepository();
    await Future.wait([repo.load(), quran.loadIndex()]);
  });

  Widget host(Widget child, {required Brightness brightness,
      required AppPalette palette, required double textScale,
      required AppLang lang}) {
    return MultiProvider(
      providers: [
        Provider<DuaRepository>.value(value: repo),
        Provider<QuranRepository>.value(value: quran),
        Provider<SharedPreferences>.value(value: prefs),
        ChangeNotifierProvider(create: (_) => QuranService(prefs)),
        ChangeNotifierProvider(create: (_) => LocaleController(prefs)..setLang(lang)),
        ChangeNotifierProvider(create: (_) => CustomDuaService(prefs)),
        ChangeNotifierProvider(create: (_) => FavoritesService(prefs)),
        ChangeNotifierProvider(create: (_) => DisplaySettings(prefs)),
        ChangeNotifierProvider(create: (_) => ThemeController(prefs)),
        ChangeNotifierProvider(create: (_) => DuaProgressService(prefs)),
        ChangeNotifierProvider(create: (_) => TasbihController(prefs)),
        ChangeNotifierProvider(
          create: (_) => MuhassanService(prefs)
            ..setEssential(
              repo.duasForCategory('morning').map((d) => d.id).toSet(),
              repo.duasForCategory('evening').map((d) => d.id).toSet(),
            ),
        ),
        ChangeNotifierProvider(create: (_) => PrayerService(prefs)),
      ],
      child: MaterialApp(
        // Match how app.dart builds the theme: an Arabic interface gets the
        // opened-up leading and zeroed tracking, which changes line metrics
        // and so is its own layout risk.
        theme: brightness == Brightness.light
            ? AppTheme.light(palette, arabicUi: lang == AppLang.ar)
            : AppTheme.dark(palette, arabicUi: lang == AppLang.ar),
        locale: Locale(lang.name),
        supportedLocales: LocaleController.supported,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: child,
        ),
      ),
    );
  }

  /// Pumps [child] and asserts nothing overflowed or threw.
  Future<void> renders(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(375, 812),
    Brightness brightness = Brightness.light,
    AppPalette? palette,
    double textScale = 1.0,
    AppLang lang = AppLang.en,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(
      child,
      brightness: brightness,
      palette: palette ?? AppPalettes.emerald,
      textScale: textScale,
      lang: lang,
    ));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  }

  // Screens that render standalone without route arguments.
  final screens = <String, Widget Function()>{
    'home': () => const HomeScreen(),
    'adhkar': () => const AdhkarScreen(),
    'quran': () => const QuranScreen(),
    'settings': () => const SettingsScreen(),
    'tasbih': () => const TasbihScreen(),
    'favorites': () => const FavoritesScreen(),
    'custom duas': () => const CustomDuasScreen(),
    'search': () => const SearchScreen(),
    'streak': () => const StreakStatsScreen(),
    'prayer schedule': () => const PrayerScheduleScreen(),
    'appearance': () => const AppearanceSettingsScreen(),
    'display': () => const DisplaySettingsScreen(),
    'language': () => const LanguageSettingsScreen(),
    'about': () => const AboutSettingsScreen(),
    'backup': () => const BackupSettingsScreen(),
    // The restore confirmation is a sheet, never routed to, so it is rendered
    // here directly — long hint lines plus a two-button row in a narrow sheet
    // is the shape most likely to overflow at a large text scale.
    'restore sheet': () => Scaffold(body: RestoreSheet(backup: _sampleBackup)),
  };

  group('renders without overflow', () {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} — phone, light', (tester) async {
        await renders(tester, entry.value());
      });

      testWidgets('${entry.key} — narrow phone, dark', (tester) async {
        await renders(tester, entry.value(),
            size: const Size(320, 640), brightness: Brightness.dark);
      });

      testWidgets('${entry.key} — large text', (tester) async {
        await renders(tester, entry.value(), textScale: 1.3);
      });

      testWidgets('${entry.key} — narrow phone, large text', (tester) async {
        await renders(tester, entry.value(),
            size: const Size(320, 640), textScale: 1.3);
      });

      // Arabic is a first-class UI language here, and RTL is where the
      // Latin/Arabic pairs in these rows are most likely to break.
      testWidgets('${entry.key} — Arabic, narrow, large text', (tester) async {
        await renders(tester, entry.value(),
            size: const Size(320, 640),
            textScale: 1.3,
            lang: AppLang.ar);
      });

      testWidgets('${entry.key} — Indonesian', (tester) async {
        await renders(tester, entry.value(), lang: AppLang.id);
      });
    }

    testWidgets('category session — every category', (tester) async {
      for (final category in repo.categories) {
        await renders(tester, CategoryDuasScreen(category: category));
      }
    });

    testWidgets('category session — narrow, large text', (tester) async {
      await renders(
        tester,
        CategoryDuasScreen(category: repo.categories.first),
        size: const Size(320, 640),
        textScale: 1.3,
      );
    });

    testWidgets('category session — Arabic', (tester) async {
      for (final category in repo.categories) {
        await renders(tester, CategoryDuasScreen(category: category),
            lang: AppLang.ar);
      }
    });

    testWidgets('adhkar home — every palette, both modes', (tester) async {
      for (final palette in AppPalettes.all) {
        for (final brightness in Brightness.values) {
          await renders(tester, const AdhkarScreen(),
              palette: palette, brightness: brightness);
        }
      }
    });
  });
}
