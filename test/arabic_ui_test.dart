import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/data/quran_repository.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/screens/category_duas_screen.dart';
import 'package:dua_app/screens/mushaf_screen.dart';
import 'package:dua_app/screens/quran_bookmarks_screen.dart';
import 'package:dua_app/screens/quran_screen.dart';
import 'package:dua_app/screens/tasbih_screen.dart';
import 'package:dua_app/services/custom_dua_service.dart';
import 'package:dua_app/services/display_settings.dart';
import 'package:dua_app/services/dua_progress_service.dart';
import 'package:dua_app/services/favorites_service.dart';
import 'package:dua_app/services/muhassan_service.dart';
import 'package:dua_app/services/quran_service.dart';
import 'package:dua_app/services/tasbih_controller.dart';
import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';

/// Guards against Latin content leaking into an Arabic interface.
///
/// Everything the interface *says* is translated — the strings live in
/// `ar.i18n.json` and a missing key would fail `l10n_test`. What slipped
/// through instead was content the app names things by: surahs were only ever
/// asked for their `translit`, so the register read "Al-Baqara" in an
/// otherwise Arabic page, and the tasbih set its phrases in Latin letters
/// above the Arabic it had just printed.
///
/// Nothing about that is visible to the analyzer or to a key-coverage check,
/// because every string involved is real content that is simply in the wrong
/// script for the reader.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DuaRepository repo;
  late QuranRepository quran;
  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      'quran_bookmark_pages': <String>['1', '255', '604'],
      'quran_bookmark_ayahs': <String>['2:255', '18:10', '114:1'],
    });
    prefs = await SharedPreferences.getInstance();
    repo = DuaRepository();
    quran = QuranRepository();
    await Future.wait([repo.load(), quran.loadIndex()]);
  });

  Widget host(Widget child) => MultiProvider(
        providers: [
          Provider<DuaRepository>.value(value: repo),
          Provider<QuranRepository>.value(value: quran),
          ChangeNotifierProvider(create: (_) => QuranService(prefs)),
          ChangeNotifierProvider(
              create: (_) => LocaleController(prefs)..setLang(AppLang.ar)),
          ChangeNotifierProvider(create: (_) => CustomDuaService(prefs)),
          ChangeNotifierProvider(create: (_) => FavoritesService(prefs)),
          ChangeNotifierProvider(create: (_) => DisplaySettings(prefs)),
          ChangeNotifierProvider(create: (_) => TasbihController(prefs)),
          ChangeNotifierProvider(create: (_) => DuaProgressService(prefs)),
          ChangeNotifierProvider(create: (_) => MuhassanService(prefs)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppPalettes.emerald, arabicUi: true),
          locale: const Locale('ar'),
          supportedLocales: LocaleController.supported,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: child,
        ),
      );

  /// Every Latin-script string the screen is currently painting.
  ///
  /// Digits and punctuation are left alone: "٢٥٥" and "255" are both read
  /// fine, and the citation forms (`2:255`, `×3`) are numeric by convention.
  List<String> latinTextIn(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .where((s) => RegExp('[A-Za-z]').hasMatch(s))
      .toList();

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(child));
    // Rows backed by an on-demand asset load need more than one frame.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(tester.takeException(), isNull);
  }

  testWidgets('the surah register names surahs in Arabic only',
      (tester) async {
    await pump(tester, const QuranScreen());

    // The reported bug: "الفاتحة" was set beside "Al-Faatiha".
    expect(find.text('Al-Faatiha'), findsNothing);
    expect(latinTextIn(tester), isEmpty);
    // And the Arabic name is actually on the page, once — the register no
    // longer sets the name twice in two scripts.
    expect(find.text(quran.surahByNumber(1)!.name), findsOneWidget);
  });

  testWidgets('saved pages and verses are cited in Arabic', (tester) async {
    await pump(tester, const QuranBookmarksScreen());
    expect(latinTextIn(tester), isEmpty);
  });

  testWidgets('the go-to-verse sheet lists surahs in Arabic', (tester) async {
    // The surah picker is a sheet, so no screen-level render reaches it.
    await pump(tester, const MushafScreen(startPage: 1));
    await tester.tap(find.byIcon(Icons.my_location));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.byType(DropdownButton<int>), findsOneWidget);
    expect(latinTextIn(tester), isEmpty);
  });

  testWidgets('a dua reads in Arabic down to its source', (tester) async {
    // The card was the last holdout: the meaning line fell back to English,
    // and the virtue and source had no Arabic to fall back to at all.
    for (final category in repo.categories) {
      await pump(tester, CategoryDuasScreen(category: category));
      expect(latinTextIn(tester), isEmpty, reason: category.id);
    }
  });

  testWidgets('the tasbih sets its phrases in Arabic', (tester) async {
    await pump(tester, const TasbihScreen());

    // The phrase, its transliteration and its English meaning were all
    // stacked on the same screen; in Arabic only the phrase belongs there.
    expect(find.text('SubhanAllah'), findsNothing);
    expect(find.text('Glory be to Allah'), findsNothing);
    expect(latinTextIn(tester), isEmpty);
  });
}
