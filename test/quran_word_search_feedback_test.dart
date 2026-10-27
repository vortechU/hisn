import 'package:dua_app/data/quran_repository.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/screens/mushaf_screen.dart';
import 'package:dua_app/screens/quran_screen.dart';
import 'package:dua_app/services/display_settings.dart';
import 'package:dua_app/services/quran_service.dart';
import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CountingQuranBundle extends CachingAssetBundle {
  int verseLoads = 0;
  @override
  Future<ByteData> load(String key) {
    if (RegExp(r'^assets/data/quran/surah_\d+\.json$').hasMatch(key)) {
      verseLoads++;
    }
    return rootBundle.load(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late QuranRepository repository;
  late CountingQuranBundle bundle;

  setUpAll(() async {
    bundle = CountingQuranBundle();
    repository = QuranRepository(bundle: bundle);
    await repository.loadIndex();
  });

  test(
    'surah, numeric, empty and single-letter lookup do not load verses',
    () async {
      expect(bundle.verseLoads, 0);
      expect(repository.searchSurahs('Ikhlaas').single.number, 112);
      for (final query in ['', '1', 'Allah', 'ا']) {
        expect(await repository.searchVerses(query), isEmpty);
      }
      expect(bundle.verseLoads, 0);
    },
  );

  test(
    'concurrent word searches build one index and normalize Arabic',
    () async {
      final results = await Future.wait([
        repository.searchVerses('قُلْ هُوَ اللَّهُ أَحَدٌ'),
        repository.searchVerses('قل هو الله احد'),
      ]);
      expect(results[0].map((verse) => verse.key), ['112:1']);
      expect(results[1].map((verse) => verse.key), ['112:1']);
      expect(bundle.verseLoads, 114);
      expect(
        (await repository.searchVerses('  قل   هو الله احد ')).single.key,
        '112:1',
      );
      expect(bundle.verseLoads, 114);
    },
  );

  test(
    'limits results in Quran order and preserves source verse citations',
    () async {
      final results = await repository.searchVerses('الله', limit: 3);
      expect(results, hasLength(3));
      expect(results.map((verse) => verse.key), ['1:1', '2:7', '2:8']);
      for (final verse in results) {
        expect(verse.ayah.text, isNotEmpty);
        expect(
          repository.pageOfAyah(verse.surah.number, verse.ayah.number),
          inInclusiveRange(1, 604),
        );
      }
      expect(await repository.searchVerses('الله', limit: 0), isEmpty);
      expect(await repository.searchVerses('كلمةغيرموجودةفيالقرآن'), isEmpty);
    },
  );

  testWidgets('Arabic word results open the exact verse in the mushaf', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'app_language': 'ar'});
    final prefs = await SharedPreferences.getInstance();
    await tester.runAsync(() async {
      await repository.searchVerses('قل هو الله احد');
      await Future.wait([
        for (final page in [602, 603, 604]) repository.loadPage(page),
      ]);
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<QuranRepository>.value(value: repository),
          ChangeNotifierProvider(create: (_) => LocaleController(prefs)),
          ChangeNotifierProvider(create: (_) => DisplaySettings(prefs)),
          ChangeNotifierProvider(create: (_) => QuranService(prefs)),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: LocaleController.supported,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: AppTheme.light(AppPalettes.fallback),
          home: const QuranScreen(),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'قل هو الله احد');
    await tester.pump(const Duration(milliseconds: 300));
    // Repository Futures complete outside the widget test's fake clock.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    final result = find.byKey(const ValueKey('quran-search-112:1'));
    expect(result, findsOneWidget);
    await tester.tap(result);
    await tester.pumpAndSettle();
    final mushaf = tester.widget<MushafScreen>(find.byType(MushafScreen));
    expect(mushaf.startPage, 604);
    expect(mushaf.highlightVerse, '112:1');
    expect(tester.takeException(), isNull);
  });
}
