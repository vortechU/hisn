import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/dua_repository.dart';
import 'data/quran_repository.dart';
import 'l10n/locale_controller.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/adhan_audio.dart';
import 'services/custom_dua_service.dart';
import 'services/display_settings.dart';
import 'services/dua_progress_service.dart';
import 'services/favorites_service.dart';
import 'services/muhassan_service.dart';
import 'services/notification_service.dart';
import 'services/prayer_service.dart';
import 'services/prayer_widget_service.dart';
import 'services/quran_service.dart';
import 'services/tasbih_controller.dart';
import 'services/theme_controller.dart';
import 'theme/app_theme.dart';
import 'util/app_navigator.dart';

/// The dua ids in [categoryId] that count toward the daily streak — everything
/// except the long 100× dhikr (see [MuhassanService.highRepeatThreshold]), so a
/// day is fortified once the essentials are done.
Set<String> _essentialIds(DuaRepository repository, String categoryId) =>
    repository
        .duasForCategory(categoryId)
        .where((d) => d.repeat < MuhassanService.highRepeatThreshold)
        .map((d) => d.id)
        .toSet();

/// Wires up the providers and the [MaterialApp].
class DuaApp extends StatelessWidget {
  const DuaApp({
    super.key,
    required this.repository,
    required this.quran,
    required this.prefs,
  });

  final DuaRepository repository;
  final QuranRepository quran;
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DuaRepository>.value(value: repository),
        Provider<QuranRepository>.value(value: quran),
        ChangeNotifierProvider(create: (_) => QuranService(prefs)),
        ChangeNotifierProvider(create: (_) => LocaleController(prefs)),
        ChangeNotifierProvider(create: (_) => CustomDuaService(prefs)),
        ChangeNotifierProvider(create: (_) => FavoritesService(prefs)),
        ChangeNotifierProvider(create: (_) => DisplaySettings(prefs)),
        ChangeNotifierProvider(create: (_) => ThemeController(prefs)),
        ChangeNotifierProvider(create: (_) => DuaProgressService(prefs)),
        ChangeNotifierProvider(create: (_) => TasbihController(prefs)),
        ChangeNotifierProvider(
          create: (_) => MuhassanService(prefs)
            ..setEssential(
              _essentialIds(repository, MuhassanService.morningId),
              _essentialIds(repository, MuhassanService.eveningId),
            ),
        ),
        ChangeNotifierProvider(create: (_) => PrayerService(prefs)),
        ChangeNotifierProvider(create: (_) => AdhanAudioService(prefs)),
        ChangeNotifierProxyProvider3<PrayerService, AdhanAudioService,
            DuaProgressService, NotificationService>(
          // Eager so reminders are (re)scheduled at launch, not only when the
          // Settings tab is first opened.
          lazy: false,
          create: (_) => NotificationService(prefs, repository),
          update: (_, prayer, adhan, progress, notifications) =>
              (notifications ?? NotificationService(prefs, repository))
                ..bind(prayer, adhan, progress),
        ),
        ChangeNotifierProxyProvider2<PrayerService, LocaleController,
            PrayerWidgetService>(
          // Eager so the home-screen widget is refreshed at launch.
          lazy: false,
          create: (_) => PrayerWidgetService(),
          update: (_, prayer, locale, widget) =>
              (widget ?? PrayerWidgetService())..bind(prayer, locale),
        ),
      ],
      // DisplaySettings joins the theme because the Latin faces carry no
      // Arabic: the chosen Arabic typeface is threaded in as the fallback so
      // Arabic interface text is set in the same face as the dua text, rather
      // than in whatever the platform substitutes.
      child: Consumer3<LocaleController, ThemeController, DisplaySettings>(
        builder: (context, localeController, themeController, display, _) {
          final arabicFamily = display.arabicFontFamily;
          final arabicUi = localeController.lang == AppLang.ar;
          return MaterialApp(
            title: 'Hisn',
            navigatorKey: appNavigatorKey,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(
              themeController.palette,
              arabicFamily: arabicFamily,
              arabicUi: arabicUi,
            ),
            darkTheme: AppTheme.dark(
              themeController.palette,
              arabicFamily: arabicFamily,
              arabicUi: arabicUi,
            ),
            themeMode: themeController.themeMode,
            locale: localeController.locale,
            supportedLocales: LocaleController.supported,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: (prefs.getBool(OnboardingScreen.seenKey) ?? false)
                ? const HomeScreen()
                : OnboardingScreen(prefs: prefs),
          );
        },
      ),
    );
  }
}
