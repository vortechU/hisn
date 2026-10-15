import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/screens/after_prayer_tasbih_screen.dart';
import 'package:dua_app/services/display_settings.dart';
import 'package:dua_app/services/dua_progress_service.dart';
import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:dua_app/widgets/ornament.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DuaRepository repo;
  late DuaProgressService progress;
  late SharedPreferences prefs;

  setUpAll(() async {
    repo = DuaRepository();
    await repo.load();
  });

  Future<void> host(
    WidgetTester tester, {
    Map<String, int> initial = const {},
  }) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'app_language': 'en',
      'tasbih_count_subhanallah': 12,
    });
    prefs = await SharedPreferences.getInstance();
    progress = DuaProgressService(prefs);
    for (final entry in initial.entries) {
      progress.setCount(entry.key, entry.value);
    }
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: repo),
          ChangeNotifierProvider.value(value: progress),
          ChangeNotifierProvider(create: (_) => LocaleController(prefs)),
          ChangeNotifierProvider(create: (_) => DisplaySettings(prefs)),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: LocaleController.supported,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(AppPalettes.emerald),
          home: const AfterPrayerTasbihScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final counter = find.byKey(const ValueKey('after_prayer_counter'));
  String shownCount(WidgetTester tester) => tester
      .widget<Numeral>(find.byKey(const ValueKey('after_prayer_count')))
      .text;

  testWidgets(
    '33 + 33 + 33 + 1 uses daily card progress and shows stage targets',
    (tester) async {
      await host(tester, initial: {'daily_leaving_home': 1});
      for (final id in AfterPrayerTasbihScreen.duaIds.take(3)) {
        for (var count = 1; count <= 33; count++) {
          await tester.tap(counter);
          await tester.pump();
          expect(progress.countOf(id), count);
          expect(shownCount(tester), '$count');
        }
        expect(shownCount(tester), '33');
        await tester.pump(const Duration(seconds: 1));
        expect(shownCount(tester), '33');
      }
      await tester.tap(counter);
      await tester.pump();
      expect(progress.countOf('salah_tasbih_tahlil_final'), 1);
      expect(shownCount(tester), '1');
      expect(find.text('The dhikr after prayer is complete.'), findsOneWidget);
      await tester.tap(counter);
      await tester.pump();
      expect(progress.countOf('salah_tasbih_tahlil_final'), 1);
      final reloaded = DuaProgressService(prefs);
      for (final id in AfterPrayerTasbihScreen.duaIds.take(3)) {
        expect(reloaded.countOf(id), 33);
      }
      expect(reloaded.countOf('salah_tasbih_tahlil_final'), 1);
      expect(prefs.getInt('tasbih_count_subhanallah'), 12);
      await tester.tap(find.byKey(const ValueKey('after_prayer_reset')));
      await tester.pump();
      for (final id in AfterPrayerTasbihScreen.duaIds) {
        expect(progress.countOf(id), 0);
      }
      expect(progress.countOf('daily_leaving_home'), 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a partially completed category resumes at the first unfinished phrase',
    (tester) async {
      await host(
        tester,
        initial: {'salah_subhanallah': 33, 'salah_alhamdulillah': 20},
      );
      expect(shownCount(tester), '20');
      await tester.tap(counter);
      await tester.pump();
      expect(progress.countOf('salah_alhamdulillah'), 21);
      expect(progress.countOf('salah_subhanallah'), 33);
      // Resetting via the original category cards is reflected by the session.
      progress.resetDuas(AfterPrayerTasbihScreen.duaIds);
      await tester.pump();
      expect(shownCount(tester), '0');
      await tester.tap(counter);
      await tester.pump();
      expect(progress.countOf('salah_subhanallah'), 1);
    },
  );
}
