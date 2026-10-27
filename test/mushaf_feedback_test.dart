import 'package:dua_app/data/quran_repository.dart';
import 'package:dua_app/l10n/app_strings.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/screens/mushaf_screen.dart';
import 'package:dua_app/services/display_settings.dart';
import 'package:dua_app/services/quran_service.dart';
import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late QuranRepository repo;
  late SharedPreferences prefs;
  late QuranService quran;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'app_language': 'ar'});
    prefs = await SharedPreferences.getInstance();
    repo = QuranRepository();
    await repo.loadIndex();
    final target = repo.pageOfAyah(2, 123);
    await Future.wait([
      for (final page in [
        602,
        603,
        604,
        target - 2,
        target - 1,
        target,
        target + 1,
        target + 2,
      ])
        repo.loadPage(page),
    ]);
  });

  Future<void> openPicker(WidgetTester tester, Brightness brightness) async {
    quran = QuranService(prefs);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<QuranRepository>.value(value: repo),
          ChangeNotifierProvider<QuranService>.value(value: quran),
          ChangeNotifierProvider(create: (_) => LocaleController(prefs)),
          ChangeNotifierProvider(create: (_) => DisplaySettings(prefs)),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: LocaleController.supported,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: brightness == Brightness.dark
              ? AppTheme.dark(AppPalettes.fallback)
              : AppTheme.light(AppPalettes.fallback),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: MushafScreen(startPage: 604),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppStrings(AppLang.ar).quranReaderOptions));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings(AppLang.ar).goToAyah));
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    testWidgets(
      'Arabic verse field is editable and keyboard hint follows $brightness',
      (tester) async {
        await openPicker(tester, brightness);
        final fieldFinder = find.byType(TextField);
        final field = tester.widget<TextField>(fieldFinder);
        expect(field.textDirection, TextDirection.ltr);
        expect(field.keyboardAppearance, brightness);
        await tester.tap(fieldFinder);
        await tester.pump();
        expect(
          field.controller!.selection,
          const TextSelection(baseOffset: 0, extentOffset: 1),
        );
        await tester.enterText(fieldFinder, '٢٨٦');
        final dropdown = tester.widget<DropdownButton<int>>(
          find.byType(DropdownButton<int>),
        );
        dropdown.onChanged!(112);
        await tester.pump();
        expect(field.controller!.text, '4');
        expect(
          field.controller!.selection,
          const TextSelection(baseOffset: 0, extentOffset: 1),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'mixed Arabic, Persian and Western digits navigate to the verse',
    (tester) async {
      await openPicker(tester, Brightness.light);
      tester
          .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
          .onChanged!(2);
      await tester.pump();
      await tester.enterText(find.byType(TextField), '١a۲3');
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '١۲3');
      field.onSubmitted!(field.controller!.text);
      await tester.pumpAndSettle();
      expect(quran.lastPage, repo.pageOfAyah(2, 123));
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'last-page surahs receive frames without changing verse mapping',
    (tester) async {
      await openPicker(tester, Brightness.light);
      // Close the picker to inspect the underlying page.
      Navigator.of(tester.element(find.byType(TextField))).pop();
      await tester.pumpAndSettle();
      for (final line in [0, 4, 9]) {
        final header = find.byKey(ValueKey('mushaf-surah-header-604-$line'));
        expect(header, findsOneWidget);
        expect(
          tester.widget<Container>(header).decoration,
          isA<BoxDecoration>(),
        );
      }
      final page = repo.pageIfCached(604)!;
      final map = mushafVerseMap(page);
      // Decorative lines retain the next verse index in the existing map, but
      // remain untouchable because only body lines have gesture handlers.
      for (final (line, nextVerse) in [
        (0, 0),
        (1, 0),
        (4, 4),
        (5, 4),
        (9, 9),
        (10, 9),
      ]) {
        expect(map[line], everyElement(nextVerse));
      }
      expect(map.expand((line) => line).where((index) => index >= 0).last, 14);
      expect(tester.takeException(), isNull);
    },
  );
}
