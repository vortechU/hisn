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

/// Rebuilds the app from persisted state.
///
/// Every service reads [SharedPreferences] once, in its constructor. After a
/// backup is restored the store no longer matches what those services hold in
/// memory, so the whole provider subtree is thrown away and built again —
/// which re-runs every constructor and re-reads everything. The alternative,
/// a `reload()` on each of the dozen services, is more code to write now and a
/// standing invitation for the next service to quietly forget to implement it.
class AppReload extends InheritedWidget {
  const AppReload({super.key, required this.reload, required super.child});

  /// Discards the current provider tree and rebuilds it from storage.
  final Future<void> Function() reload;

  static AppReload of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppReload>()!;

  @override
  bool updateShouldNotify(AppReload oldWidget) => false;
}

/// Wires up the providers and the [MaterialApp].
class DuaApp extends StatefulWidget {
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
  State<DuaApp> createState() => _DuaAppState();
}

class _DuaAppState extends State<DuaApp> {
  /// Changing this key discards the provider subtree below it.
  int _generation = 0;

  /// True for exactly one frame, while the old tree is torn down.
  bool _rebuilding = false;

  Future<void> _reload() async {
    // The old and the new tree must not exist at once: [appNavigatorKey] is a
    // GlobalKey, and two MaterialApps holding it in the same frame is a
    // duplicate-key error. Blanking for a frame guarantees the old one is
    // unmounted before the new one is built.
    setState(() => _rebuilding = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    setState(() {
      _rebuilding = false;
      _generation++;
    });
    // Settle the replacement tree before returning, so a caller can address
    // the new navigator (to report what it did) the moment this completes.
    await WidgetsBinding.instance.endOfFrame;
  }

  @override
  Widget build(BuildContext context) {
    return AppReload(
      reload: _reload,
      child: _rebuilding
          // One frame, in the brand ground colour — short enough not to read
          // as a flash, and there is no theme to consult this far up the tree.
          ? const ColoredBox(color: Color(0xFF072C3E))
          : KeyedSubtree(
              key: ValueKey(_generation),
              child: _providers(context),
            ),
    );
  }

  Widget _providers(BuildContext context) {
    final repository = widget.repository;
    final quran = widget.quran;
    final prefs = widget.prefs;
    return MultiProvider(
      providers: [
        Provider<DuaRepository>.value(value: repository),
        Provider<QuranRepository>.value(value: quran),
        // Exposed so backup & restore can read and write the whole store.
        Provider<SharedPreferences>.value(value: prefs),
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
