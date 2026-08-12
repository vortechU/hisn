import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/screens/category_duas_screen.dart';
import 'package:dua_app/services/adhkar_audio_library.dart';
import 'package:dua_app/services/custom_dua_service.dart';
import 'package:dua_app/services/display_settings.dart';
import 'package:dua_app/services/dua_progress_service.dart';
import 'package:dua_app/services/favorites_service.dart';
import 'package:dua_app/services/muhassan_service.dart';
import 'package:dua_app/services/prayer_service.dart';
import 'package:dua_app/services/prayer_widget_service.dart';
import 'package:dua_app/services/sunnah_calendar_service.dart';
import 'package:dua_app/services/tasbih_controller.dart';
import 'package:dua_app/services/theme_controller.dart';
import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:dua_app/theme/reading_theme.dart';
import 'package:dua_app/widgets/dua_card.dart';

/// The work the app is *not* supposed to do.
///
/// Every case here guards a cost that is invisible in a screenshot and silent
/// in the analyzer: a screenful of cards rebuilt for one tap, a full ThemeData
/// derived per card per frame, a method channel hop per bead. None of them is
/// wrong on the screen — they are only slow — so nothing else in the suite
/// would notice them coming back.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DuaRepository repo;

  setUpAll(() async {
    repo = DuaRepository();
    await repo.load();
  });

  // -------------------------------------------------------------------------
  // Rebuild blast radius
  // -------------------------------------------------------------------------

  group('counting a dua', () {
    /// The screen under test, with just enough of the app around it.
    Widget host(SharedPreferences prefs, category) => MultiProvider(
          providers: [
            Provider<DuaRepository>.value(value: repo),
            Provider<SharedPreferences>.value(value: prefs),
            // Nothing recorded: this group measures what a *tap* rebuilds, and
            // an extra AppBar action would only add noise to that count.
            Provider<AdhkarAudioLibrary>.value(
                value: AdhkarAudioLibrary.empty()),
            ChangeNotifierProvider(create: (_) => LocaleController(prefs)),
            ChangeNotifierProvider(create: (_) => CustomDuaService(prefs)),
            ChangeNotifierProvider(create: (_) => FavoritesService(prefs)),
            ChangeNotifierProvider(create: (_) => DisplaySettings(prefs)),
            ChangeNotifierProvider(create: (_) => ThemeController(prefs)),
            ChangeNotifierProvider(create: (_) => DuaProgressService(prefs)),
            ChangeNotifierProvider(create: (_) => MuhassanService(prefs)),
          ],
          child: MaterialApp(
            theme: AppTheme.light(AppPalettes.emerald),
            locale: const Locale('en'),
            supportedLocales: LocaleController.supported,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: CategoryDuasScreen(category: category),
          ),
        );

    testWidgets('rebuilds the dua counted and leaves the rest alone',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final category = repo.categoryById('morning')!;
      final duas = repo.duasForCategory(category.id);
      expect(duas.length, greaterThan(2),
          reason: 'the case needs a card that is not the one being counted');

      tester.view.physicalSize = const Size(400, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host(prefs, category));
      await tester.pump();

      // A card that is not rebuilt keeps the very widget instance it was
      // given, because the builder that would replace it never ran. That
      // identity is the whole assertion.
      DuaCard cardFor(String duaId) => tester.widget<DuaCard>(
            find.byWidgetPredicate((w) => w is DuaCard && w.dua.id == duaId),
          );

      final counted = duas.first;
      final untouched = duas[1];
      final countedBefore = cardFor(counted.id);
      final untouchedBefore = cardFor(untouched.id);

      // Count it the way the card's tap handler does.
      final context = tester.element(find.byType(CategoryDuasScreen));
      context.read<DuaProgressService>().setCount(counted.id, 1);
      await tester.pump();

      expect(identical(cardFor(counted.id), countedBefore), isFalse,
          reason: 'the dua that was counted must show its new tally');
      expect(identical(cardFor(untouched.id), untouchedBefore), isTrue,
          reason: 'nothing changed for this dua, so it should not be rebuilt');
    });

    testWidgets('still redraws every card when the whole set is reset',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final category = repo.categoryById('morning')!;
      final duas = repo.duasForCategory(category.id);

      tester.view.physicalSize = const Size(400, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host(prefs, category));
      await tester.pump();

      final context = tester.element(find.byType(CategoryDuasScreen));
      final progress = context.read<DuaProgressService>();
      for (final dua in duas.take(2)) {
        progress.setCount(dua.id, 1);
      }
      await tester.pump();

      DuaCard cardFor(String duaId) => tester.widget<DuaCard>(
            find.byWidgetPredicate((w) => w is DuaCard && w.dua.id == duaId),
          );
      final before = {for (final d in duas.take(2)) d.id: cardFor(d.id)};

      progress.resetDuas(duas.map((d) => d.id));
      await tester.pump();

      for (final entry in before.entries) {
        expect(identical(cardFor(entry.key), entry.value), isFalse,
            reason: 'a reset clears every tally, so every card must redraw');
        expect(cardFor(entry.key).count, 0);
      }
    });
  });

  // -------------------------------------------------------------------------
  // Derived themes
  // -------------------------------------------------------------------------

  group('reading theme', () {
    test('derives once per base theme rather than once per card', () {
      final base = AppTheme.light(AppPalettes.emerald);
      final first = ReadingTheme.sepia.apply(base);
      final second = ReadingTheme.sepia.apply(base);
      expect(identical(first, second), isTrue,
          reason: 'every dua card asks for this on every build');
    });

    test('keeps the two reading surfaces apart', () {
      final base = AppTheme.light(AppPalettes.emerald);
      expect(
        identical(ReadingTheme.sepia.apply(base), ReadingTheme.night.apply(base)),
        isFalse,
      );
    });

    test('re-derives when the app theme itself changes', () {
      final light = AppTheme.light(AppPalettes.emerald);
      final dark = AppTheme.dark(AppPalettes.emerald);
      final onLight = ReadingTheme.sepia.apply(light);
      final onDark = ReadingTheme.sepia.apply(dark);
      expect(identical(onLight, onDark), isFalse);
      // And the first is still the cached one, not evicted by the second.
      expect(identical(ReadingTheme.sepia.apply(light), onLight), isTrue);
    });

    test('system is a no-op and costs nothing', () {
      final base = AppTheme.light(AppPalettes.emerald);
      expect(identical(ReadingTheme.system.apply(base), base), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Repository lookups
  // -------------------------------------------------------------------------

  group('repository lookups', () {
    test('a category keeps the duas, and the order, it had before', () {
      for (final category in repo.categories) {
        final indexed = repo.duasForCategory(category.id);
        final scanned =
            repo.duas.where((d) => d.categoryId == category.id).toList();
        expect(indexed.map((d) => d.id).toList(), scanned.map((d) => d.id).toList());
        expect(repo.countForCategory(category.id), scanned.length);
      }
    });

    test('an unknown category is empty rather than an error', () {
      expect(repo.duasForCategory('no-such-category'), isEmpty);
      expect(repo.countForCategory('no-such-category'), 0);
      expect(repo.categoryById('no-such-category'), isNull);
      expect(repo.duaById('no-such-dua'), isNull);
    });

    test('every dua is reachable by its id', () {
      for (final dua in repo.duas) {
        expect(repo.duaById(dua.id)?.id, dua.id);
      }
      expect(repo.duasByIds(repo.duas.map((d) => d.id)).length, repo.duas.length);
    });
  });

  // -------------------------------------------------------------------------
  // Home-screen widget traffic
  // -------------------------------------------------------------------------

  group('widget traffic', () {
    const channel = MethodChannel('hisn/widget');
    var updates = 0;

    setUp(() {
      updates = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'update') updates++;
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('a hundred beads are one redraw, not a hundred', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = TasbihController(prefs);

      for (var i = 0; i < 100; i++) {
        await controller.increment('subhanallah', 33);
      }
      expect(updates, 0,
          reason: 'counting must not wait on the widget between taps');

      await Future<void>.delayed(const Duration(milliseconds: 900));
      expect(updates, 1, reason: 'the widget is told once the beads settle');
      controller.dispose();
    });

    test('the count is readable the moment the tap is handled', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = TasbihController(prefs);
      addTearDown(controller.dispose);

      var seen = -1;
      controller.addListener(() => seen = controller.countFor('subhanallah'));
      final pending = controller.increment('subhanallah', 33);

      expect(seen, 1,
          reason: 'the screen is told before the disk write is awaited');
      await pending;
      expect(controller.countFor('subhanallah'), 1);
    });

    test('an unchanged payload is not pushed again', () async {
      SharedPreferences.setMockInitialValues({
        // Manual mode keeps PrayerService off the geolocator in tests.
        'prayer_location_mode': 'manual',
        'prayer_lat': 21.4225,
        'prayer_lng': 39.8262,
        'prayer_location_label': 'Makkah',
      });
      final prefs = await SharedPreferences.getInstance();
      final service = PrayerWidgetService(repo);
      addTearDown(service.dispose);

      final prayer = PrayerService(prefs);
      final locale = LocaleController(prefs);
      final calendar = SunnahCalendarService(prefs);
      final theme = ThemeController(prefs);
      final display = DisplaySettings(prefs);
      final progress = DuaProgressService(prefs);
      final tasbih = TasbihController(prefs);
      addTearDown(tasbih.dispose);

      void bind() => service.bind(
          prayer, locale, calendar, theme, display, progress, tasbih);

      bind();
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(updates, 1);

      // Nothing a widget draws has moved — a re-bind is a notification from
      // one of six services, most of which change nothing on the home screen.
      bind();
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(updates, 1, reason: 'the same payload should not be sent twice');

      // Something a widget does draw: the tally on the adhkar panel.
      progress.setCount(repo.duasForCategory('morning').first.id, 99);
      bind();
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(updates, 2, reason: 'a real change still reaches the widget');
    });
  });
}
