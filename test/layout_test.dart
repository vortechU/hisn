import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/data/quran_repository.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/screens/adhkar_player_screen.dart';
import 'package:dua_app/screens/adhkar_screen.dart';
import 'package:dua_app/screens/category_duas_screen.dart';
import 'package:dua_app/screens/custom_duas_screen.dart';
import 'package:dua_app/screens/favorites_screen.dart';
import 'package:dua_app/screens/home_screen.dart';
import 'package:dua_app/screens/mushaf_screen.dart';
import 'package:dua_app/screens/prayer_schedule_screen.dart';
import 'package:dua_app/screens/quran_bookmarks_screen.dart';
import 'package:dua_app/screens/quran_screen.dart';
import 'package:dua_app/screens/search_screen.dart';
import 'package:dua_app/screens/share_sheet.dart';
import 'package:dua_app/screens/settings/about_settings_screen.dart';
import 'package:dua_app/screens/settings/appearance_settings_screen.dart';
import 'package:dua_app/screens/settings/backup_settings_screen.dart';
import 'package:dua_app/screens/settings/display_settings_screen.dart';
import 'package:dua_app/screens/settings/language_settings_screen.dart';
import 'package:dua_app/screens/settings_screen.dart';
import 'package:dua_app/screens/streak_stats_screen.dart';
import 'package:dua_app/screens/sunnah_calendar_screen.dart';
import 'package:dua_app/screens/tasbih_screen.dart';
import 'package:dua_app/services/adhkar_audio_handler.dart';
import 'package:dua_app/services/adhkar_audio_library.dart';
import 'package:dua_app/services/backup_service.dart';
import 'package:dua_app/services/listen_settings.dart';
import 'package:dua_app/services/custom_dua_service.dart';
import 'package:dua_app/services/display_settings.dart';
import 'package:dua_app/services/dua_progress_service.dart';
import 'package:dua_app/services/favorites_service.dart';
import 'package:dua_app/services/muhassan_service.dart';
import 'package:dua_app/services/prayer_service.dart';
import 'package:dua_app/models/quran.dart';
import 'package:dua_app/models/shareable.dart';
import 'package:dua_app/widgets/dua_card.dart';
import 'package:dua_app/widgets/verse_row.dart';
import 'package:dua_app/services/quran_service.dart';
import 'package:dua_app/services/sunnah_calendar_service.dart';
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

/// A passage with every optional line filled, so the card is exercised at its
/// tallest rather than in its simplest form.
const _samplePassage = Shareable(
  arabic: 'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ',
  reference: 'Al-Bukhari 6306',
  title: 'Sayyid al-Istighfar',
  transliteration: 'Allahumma anta rabbi la ilaha illa anta, khalaqtani wa ana abduka',
  translation: 'O Allah, You are my Lord. There is no god but You. You created me and I am Your servant.',
  repeat: 3,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DuaRepository repo;
  late QuranRepository quran;
  late SharedPreferences prefs;
  late AdhkarAudioLibrary audioLibrary;
  final audio = AdhkarAudioHandler();

  /// 2:282 with each language's meaning attached. Read here rather than in the
  /// test bodies: asset loading is real async, and awaiting it before the
  /// first pump of a `testWidgets` body would never complete.
  final longestVerse = <AppLang, PageVerse>{};

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      // Populated lists exercise far more layout than empty states do.
      'quran_bookmark_pages': <String>['1', '255', '604'],
      'quran_bookmark_ayahs': <String>['2:255', '18:10', '114:1'],
    });
    prefs = await SharedPreferences.getInstance();
    repo = DuaRepository();
    quran = QuranRepository();
    await Future.wait([repo.load(), quran.loadIndex()]);
    for (final lang in AppLang.values) {
      longestVerse[lang] = (await quran.verse(2, 282, lang: lang.name))!;
    }
    audioLibrary = AdhkarAudioLibrary.forTest({
      for (final id in ['morning', 'evening']
          .expand((c) => repo.duasForCategory(c))
          .map((d) => d.id))
        id: 'assets/audio/adhkar/$id.m4a',
    });
  });

  Widget host(Widget child, {required Brightness brightness,
      required AppPalette palette, required double textScale,
      required AppLang lang}) {
    return MultiProvider(
      providers: [
        Provider<DuaRepository>.value(value: repo),
        Provider<QuranRepository>.value(value: quran),
        Provider<SharedPreferences>.value(value: prefs),
        // Recitation is claimed for every morning and evening dua so the
        // listening affordances — the AppBar mark on a set, the headphone on
        // the "read now" rubric — are actually laid out here. An empty library
        // would hide them and quietly stop testing them.
        Provider<AdhkarAudioLibrary>.value(value: audioLibrary),
        // The handler constructs without a platform behind it — just_audio
        // defers that until a source is set — which is enough to lay the
        // listening screen out in its idle state.
        ChangeNotifierProvider<AdhkarAudioHandler>.value(value: audio),
        ChangeNotifierProvider(create: (_) => ListenSettings(prefs)),
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
        ChangeNotifierProvider(create: (_) => SunnahCalendarService(prefs)),
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
    // Several pumps rather than pumpAndSettle: some screens carry a ticking
    // clock that would never settle, but rows backed by an asset load need
    // more than a single frame to appear.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
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
    'quran bookmarks': () => const QuranBookmarksScreen(),
    'backup': () => const BackupSettingsScreen(),
    'sunnah calendar': () => const SunnahCalendarScreen(),
    // The share preview is a sheet, never routed to. Its card is a fixed 360
    // wide, so the narrow-phone configs are where it would burst its frame.
    'share sheet': () =>
        const Scaffold(body: SharePreviewSheet(passage: _samplePassage)),
    // The restore confirmation is a sheet, never routed to, so it is rendered
    // here directly — long hint lines plus a two-button row in a narrow sheet
    // is the shape most likely to overflow at a large text scale.
    'restore sheet': () => Scaffold(body: RestoreSheet(backup: _sampleBackup)),
  };

  // The mushaf is the one screen with a hard aspect requirement: fifteen
  // justified lines that must fill a frame of any shape. Landscape is where it
  // broke, so it is checked there explicitly rather than only at phone sizes.
  group('mushaf renders without overflow', () {
    for (final (label, size) in const [
      ('portrait phone', Size(375, 812)),
      ('narrow portrait', Size(320, 640)),
      ('landscape phone', Size(812, 375)),
      ('short landscape', Size(640, 320)),
      ('tablet landscape', Size(1280, 800)),
    ]) {
      testWidgets(label, (tester) async {
        await renders(tester, const MushafScreen(startPage: 1), size: size);
      });
    }

    testWidgets('landscape, Arabic', (tester) async {
      await renders(tester, const MushafScreen(startPage: 2),
          size: const Size(812, 375), lang: AppLang.ar);
    });

  });

  // Pinching outwards is the reader's zoom. What makes it read as one is the
  // page shedding its apparatus — bar, running head, gold frame, folio — and
  // handing that space to the glyphs, so the text comes out visibly bigger. A
  // fullscreen flag that only slid the bars away would leave the lines almost
  // the size they already were.
  group('the mushaf zoom', () {
    /// The largest font size anything on screen is drawn at — always a page
    /// glyph, since the running head and the bar title are set far smaller.
    double glyphSize(WidgetTester tester) {
      var largest = 0.0;
      for (final rt in tester.widgetList<RichText>(find.byType(RichText))) {
        rt.text.visitChildren((span) {
          final size = span.style?.fontSize;
          if (size != null && size > largest) largest = size;
          return true;
        });
      }
      return largest;
    }

    /// Pinches by [by] — the fraction the fingers' span changes, so 0.4 spreads
    /// them 40% apart and -0.3 brings them 30% closer — and lets go.
    ///
    /// Deliberately symmetric about the centre: the PageView tracks the two
    /// fingers' average, so a pinch must not turn the page. [holdAt] stops
    /// part-way with the fingers still down, to look at the page mid-gesture.
    Future<void> pinch(
      WidgetTester tester,
      double by, {
      double? holdAt,
      Future<void> Function()? whileHeld,
    }) async {
      const half = 60.0;
      final centre = tester.getCenter(find.byType(PageView));
      final left = await tester.startGesture(centre - const Offset(half, 0));
      final right = await tester.startGesture(centre + const Offset(half, 0));

      Future<void> spreadTo(double fraction) async {
        final reach = half * (1 + by * fraction);
        await left.moveTo(centre - Offset(reach, 0));
        await right.moveTo(centre + Offset(reach, 0));
        await tester.pump();
      }

      if (holdAt != null) {
        await spreadTo(holdAt);
        await whileHeld?.call();
      }
      await spreadTo(1);
      await left.up();
      await right.up();
      await tester.pumpAndSettle();
    }

    testWidgets('pinching out enlarges the text', (tester) async {
      await renders(tester, const MushafScreen(startPage: 1));
      final framed = glyphSize(tester);
      expect(framed, greaterThan(0));

      await pinch(tester, 0.5);

      expect(tester.takeException(), isNull);
      expect(find.byType(AppBar), findsNothing);
      expect(glyphSize(tester), greaterThan(framed * 1.1),
          reason: 'the zoomed page should give the glyphs the frame\'s space');
    });

    // The zoom follows the fingers rather than flipping when they pass a
    // threshold: half a pinch is half the growth, on the page, before anything
    // is released. This is what the reader feels as smooth.
    testWidgets('follows the fingers instead of snapping', (tester) async {
      await renders(tester, const MushafScreen(startPage: 3));
      final framed = glyphSize(tester);
      var midway = 0.0;

      await pinch(tester, 0.5, holdAt: 0.5, whileHeld: () async {
        midway = glyphSize(tester);
      });

      expect(midway, greaterThan(framed),
          reason: 'the page should already have grown with the fingers');
      expect(midway, lessThan(glyphSize(tester)),
          reason: 'and not have arrived before the pinch finished');
    });

    // Coming back out has to undo all of it — including the system bars. It
    // did not: the page un-zoomed while the status bar stayed hidden, leaving
    // the phone eating the first swipe home. Both halves are checked, since
    // the layout returning says nothing about the bars.
    testWidgets('pinching back in restores the page and the bars',
        (tester) async {
      final chrome = <String, Object?>{};
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method.startsWith('SystemChrome.setEnabledSystemUI')) {
            calls.add(call.method);
            chrome[call.method] = call.arguments;
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await renders(tester, const MushafScreen(startPage: 1));
      final framed = glyphSize(tester);

      await pinch(tester, 0.5);
      expect(chrome['SystemChrome.setEnabledSystemUIMode'],
          'SystemUiMode.immersiveSticky');

      await pinch(tester, -0.4);

      expect(tester.takeException(), isNull);
      expect(find.byType(AppBar), findsOneWidget);
      expect(glyphSize(tester), framed,
          reason: 'the framed page should come back exactly as it was');
      // Asking for the bars by name is the part that actually lifts the hide;
      // a mode change on its own leaves the status bar gone.
      expect(calls.last, 'SystemChrome.setEnabledSystemUIMode');
      expect(calls, contains('SystemChrome.setEnabledSystemUIOverlays'));
      expect(
        calls.lastIndexOf('SystemChrome.setEnabledSystemUIOverlays'),
        greaterThan(calls.indexOf('SystemChrome.setEnabledSystemUIMode')),
        reason: 'the overlays must be restored after the immersive mode was set',
      );
      expect(chrome['SystemChrome.setEnabledSystemUIMode'],
          'SystemUiMode.edgeToEdge');
      expect(
        chrome['SystemChrome.setEnabledSystemUIOverlays'],
        containsAll(<String>[
          'SystemUiOverlay.top',
          'SystemUiOverlay.bottom',
        ]),
      );
    });
  });

  // Counting a dua marks the card complete, which gilds its frame. Nothing
  // about that is meant to move the text: the reader is looking at the words
  // while they tap, and a card that reflowed and grew a line under their thumb
  // read as the app losing its place. It did move — the emphasised rule is a
  // pixel heavier on each side, and a border grows inwards, so the block lost
  // two pixels of width the moment it was finished and any line sitting near
  // the edge wrapped.
  testWidgets('finishing a dua does not reflow its card', (tester) async {
    final dua = repo
        .duasForCategory('morning')
        .where((d) => d.repeat > 1)
        // The longest heading of the set: the title sits nearest the wrap, so
        // this is the card with the least room to absorb a shift.
        .reduce((a, b) => b.title.length > a.title.length ? b : a);

    var count = 0;
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host(
      StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: SingleChildScrollView(
            child: DuaCard(
              dua: dua,
              count: count,
              onCount: () => setState(() => count++),
            ),
          ),
        ),
      ),
      brightness: Brightness.light,
      palette: AppPalettes.emerald,
      // A large scale leaves the least slack of all, so a two-pixel loss shows
      // up here first.
      textScale: 1.3,
      lang: AppLang.en,
    ));
    await tester.pump();

    // The card is full-width either way; what the rule steals is the block
    // inside it, so the text is what has to be measured.
    final body = find.text(dua.translationFor('en'));
    final before = tester.getSize(body);
    final cardBefore = tester.getSize(find.byType(DuaCard));

    // Tapped near the top: at this text scale the card runs past the bottom of
    // a 640-tall phone, and its centre — where `tap` would aim — is off screen.
    final tapPoint =
        tester.getTopLeft(find.byType(DuaCard)) + const Offset(40, 40);
    for (var i = 0; i < dua.repeat; i++) {
      await tester.tapAt(tapPoint);
      await tester.pump();
    }
    expect(count, dua.repeat, reason: 'the taps should have completed the dua');

    expect(tester.getSize(body), before,
        reason: 'the text block should be the same width once it is gilded');
    expect(tester.getSize(find.byType(DuaCard)), cardBefore,
        reason: 'and the card should not have grown a line');
  });

  // The verse rows the reader lists a page's verses in. Rendered directly
  // because they live in a bottom sheet, and scrolled the way that sheet
  // scrolls them — 2:282 is the longest verse in the Qur'an and runs many
  // screens deep in any language, so height is not the risk here. The risk is
  // across: a medallion, a citation and three buttons in one row, on a narrow
  // phone at a large text scale. The Arabic case carries the tafsir, which is
  // longer than a translation by an order of magnitude.
  group('a verse row renders without overflow', () {
    for (final lang in AppLang.values) {
      testWidgets('${lang.name} — narrow phone, large text', (tester) async {
        await renders(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: VerseRow(verse: longestVerse[lang]!),
            ),
          ),
          size: const Size(320, 640),
          textScale: 1.3,
          lang: lang,
        );
      });
    }
  });

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

    // The listening screen, in its idle state — the head, the empty page and
    // the transport. Idle is all a widget test can reach: there is no media
    // session here for a real recitation to run in, so [start] never gets past
    // loading a source. The layouts that matter (a long Arabic block under a
    // fixed head and a fixed transport, at large text on a narrow phone) are
    // exercised by the reading screen above, which sets the same block.
    testWidgets('listening — every set, every language', (tester) async {
      for (final lang in AppLang.values) {
        for (final id in ['morning', 'evening']) {
          await renders(
            tester,
            AdhkarPlayerScreen(
              category: repo.categoryById(id)!,
              duas: repo.duasForCategory(id),
            ),
            lang: lang,
          );
        }
      }
    });

    testWidgets('listening — narrow, large text', (tester) async {
      await renders(
        tester,
        AdhkarPlayerScreen(
          category: repo.categoryById('morning')!,
          duas: repo.duasForCategory('morning'),
        ),
        size: const Size(320, 640),
        textScale: 1.3,
      );
    });
  });
}
