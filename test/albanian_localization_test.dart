import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/data/quran_repository.dart';
import 'package:dua_app/l10n/app_strings.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/models/shareable.dart';
import 'package:dua_app/screens/settings/language_settings_screen.dart';
import 'package:dua_app/services/display_settings.dart';
import 'package:dua_app/services/favorites_service.dart';
import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:dua_app/widgets/dua_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late DuaRepository repository;
  late QuranRepository quran;
  late Map<String, dynamic> overlay;

  setUpAll(() async {
    repository = DuaRepository();
    quran = QuranRepository();
    await Future.wait([repository.load(), quran.loadIndex()]);
    overlay =
        jsonDecode(await rootBundle.loadString('assets/data/duas.sq.json'))
            as Map<String, dynamic>;
    for (final family in {
      'Readex Pro': [
        'assets/fonts/ui/ReadexPro-Regular.ttf',
        'assets/fonts/ui/ReadexPro-Medium.ttf',
        'assets/fonts/ui/ReadexPro-SemiBold.ttf',
        'assets/fonts/ui/ReadexPro-Bold.ttf',
      ],
      'Amiri': ['assets/fonts/Amiri-Regular.ttf'],
      'MaterialIcons': ['fonts/MaterialIcons-Regular.otf'],
    }.entries) {
      final loader = FontLoader(family.key);
      for (final path in family.value) {
        loader.addFont(rootBundle.load(path));
      }
      await loader.load();
    }
  });

  test(
    'Albanian is recognized from device locales and restored preferences',
    () async {
      binding.platformDispatcher.localesTestValue = [const Locale('sq', 'AL')];
      addTearDown(binding.platformDispatcher.clearLocalesTestValue);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final locale = LocaleController(prefs);
      addTearDown(locale.dispose);
      expect(locale.lang, AppLang.sq);
      expect(locale.rtl, isFalse);
      expect(prefs.getString('app_language'), 'sq');
      await locale.setLang(AppLang.en);
      await locale.setLang(AppLang.sq);
      final restored = LocaleController(prefs);
      addTearDown(restored.dispose);
      expect(restored.lang, AppLang.sq);
      expect(AppStrings(restored.lang).currentLanguage, 'Shqip');
    },
  );

  test(
    'Albanian plurals and duration parameters resolve without English text',
    () {
      final strings = AppStrings(AppLang.sq);
      expect(strings.daysValue(1), '1 ditë');
      expect(strings.daysValue(2), '2 ditë');
      expect(strings.versesCount(1), '1 ajet');
      expect(strings.versesCount(3), '3 ajete');
      expect(strings.restoreDone(1), 'U rikthye 1 element');
      expect(strings.restoreDone(5), 'U rikthyen 5 elemente');
      expect(
        strings.shortDuration(const Duration(hours: 2, minutes: 5)),
        '2 orë 5 min',
      );
      expect(strings.shortDuration(const Duration(minutes: 5)), '5 min');
    },
  );

  test(
    'every dua has Albanian content with original Arabic and reference identifiers',
    () async {
      final base =
          (jsonDecode(await rootBundle.loadString('assets/data/duas.json'))
                  as List)
              .cast<Map<String, dynamic>>();
      final identifiers = RegExp(r'\d+[a-z]?');
      expect(
        overlay.keys.where((key) => key != '_meta').toSet(),
        repository.duas.map((dua) => dua.id).toSet(),
      );
      for (final original in base) {
        final dua = repository.duaById(original['id'] as String)!;
        final localized = overlay[dua.id] as Map<String, dynamic>;
        expect(dua.arabic, original['arabic']);
        expect(dua.repeat, original['repeat'] ?? 1);
        expect(dua.translationFor('sq'), localized['translation']);
        expect(dua.titleForLang('sq'), localized['title']);
        expect(
          identifiers
              .allMatches(dua.referenceFor('sq'))
              .map((match) => match[0]),
          identifiers.allMatches(dua.reference).map((match) => match[0]),
          reason: dua.id,
        );
        for (final field in [
          'title',
          'translation',
          'reference',
          if (dua.virtue != null) 'virtue',
          if (dua.instruction != null) 'instruction',
        ]) {
          expect(localized[field], isA<String>(), reason: '${dua.id}.$field');
          expect((localized[field] as String).trim(), isNotEmpty);
        }
      }
      final found = repository.search('PËRGJIGJJA', langCode: 'sq');
      expect(
        found.map((dua) => dua.id),
        contains('mosque_adhan_response_hayya'),
      );
    },
  );

  test(
    'Quran meanings retain the published Albanian translator and exact passages',
    () async {
      final edition = (await quran.editionFor('sq'))!;
      expect(edition.id, 'sq.nahi');
      expect(edition.translator, 'Hasan Efendi Nahi');
      expect(edition.sourceUrl, 'https://tanzil.net');
      Future<String> verse(int surah, int ayah) async =>
          (await quran.loadTranslation(surah, 'sq'))!.forAyah(ayah)!;
      expect(
        await verse(1, 1),
        'Me emër të Allahut, Mëshirues dhe Përdëllimtar i Madh.',
      );
      for (final prefix in ['morning', 'evening', 'salah', 'sleep']) {
        expect(
          repository.duaById('${prefix}_ayat_kursi')!.translationFor('sq'),
          await verse(2, 255),
        );
        for (final surah in [
          ('ikhlas', 112, 4),
          ('falaq', 113, 5),
          ('nas', 114, 6),
        ]) {
          final expected = [
            for (var n = 1; n <= surah.$3; n++) await verse(surah.$2, n),
          ];
          expect(
            repository.duaById('${prefix}_${surah.$1}')!.translationFor('sq'),
            '${await verse(1, 1)}\n\n${expected.join('\n')}',
          );
        }
      }
      final waking = repository
          .duaById('waking_imran_190_200')!
          .translationFor('sq');
      for (var n = 190; n <= 200; n++) {
        expect(waking, contains('($n) ${await verse(3, n)}'));
      }
      final meta = overlay['_meta'] as Map<String, dynamic>;
      expect(meta['status'], contains('DRAFT'));
      expect((meta['quran'] as Map)['edition'], 'sq.nahi');
      final shared = Shareable.verse(
        (await quran.verse(2, 255, lang: 'sq'))!,
        'sq',
      );
      expect(shared.translationCredit, 'Hasan Efendi Nahi');
      expect(shared.translationIsRtl, isFalse);
      expect(shared.asText(), contains('Hasan Efendi Nahi'));
    },
  );

  test(
    'Quran-containing dua shares retain the published translator credit',
    () {
      for (final id in [
        'morning_ayat_kursi',
        'sleep_ikhlas',
        'waking_imran_190_200',
        'forgiveness_yunus',
        'travel_setting_off',
        'travel_returning',
        'distress_musibah',
      ]) {
        final shared = Shareable.dua(repository.duaById(id)!, 'sq');
        expect(
          shared.reference,
          contains('Përkthimi i pjesës kuranore: Hasan Efendi Nahi'),
        );
        expect(shared.asText(), contains('Hasan Efendi Nahi'));
      }
      final hadith = Shareable.dua(
        repository.duaById('daily_leaving_home')!,
        'sq',
      );
      expect(hadith.asText(), isNot(contains('Hasan Efendi Nahi')));
      expect(hadith.translation, contains('Nuk ka forcë e as fuqi'));
    },
  );

  Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
    if (!const bool.fromEnvironment('CAPTURE_ALBANIAN')) return;
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/albanian-preview/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(png!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets(
    'Shqip is selectable and dua cards keep Arabic alongside Albanian',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({'app_language': 'en'});
      final prefs = await SharedPreferences.getInstance();
      final key = GlobalKey();
      Widget host(Widget screen) => MultiProvider(
        key: UniqueKey(),
        providers: [
          ChangeNotifierProvider(create: (_) => LocaleController(prefs)),
          ChangeNotifierProvider(create: (_) => DisplaySettings(prefs)),
          ChangeNotifierProvider(create: (_) => FavoritesService(prefs)),
        ],
        child: Consumer<LocaleController>(
          builder: (context, locale, _) => RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: locale.locale,
              supportedLocales: LocaleController.supported,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: AppTheme.light(
                AppPalettes.emerald,
                uiFamily: locale.lang.uiFontFamily,
                arabicUi: locale.lang.usesArabicScript,
              ),
              home: screen,
            ),
          ),
        ),
      );
      await tester.pumpWidget(host(const LanguageSettingsScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Shqip'));
      await tester.pumpAndSettle();
      expect(find.text('Gjuha'), findsOneWidget);
      expect(prefs.getString('app_language'), 'sq');
      expect(tester.takeException(), isNull);
      await capture(tester, key, 'language');
      final dua = repository.duaById('daily_leaving_home')!;
      await tester.pumpWidget(
        host(
          Scaffold(
            appBar: AppBar(title: const Text('Lutjet')),
            body: SingleChildScrollView(child: DuaCard(dua: dua)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(dua.translationFor('sq')), findsOneWidget);
      expect(find.text(dua.arabic), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.text(dua.translationFor('sq')))),
        TextDirection.ltr,
      );
      expect(tester.takeException(), isNull);
      await capture(tester, key, 'dua');
      // Inspect the real layout of a long Quran-containing reference. A two-line
      // ellipsis would remove the translator name from this rendered paragraph.
      final quranDua = repository.duaById('morning_ikhlas')!;
      await tester.pumpWidget(
        host(
          Scaffold(
            appBar: AppBar(title: const Text('Lutjet')),
            body: SingleChildScrollView(child: DuaCard(dua: quranDua)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final reference = quranDua.referenceFor('sq');
      final referenceFinder = find.text(reference);
      await tester.ensureVisible(referenceFinder);
      await tester.pumpAndSettle();
      final paragraph = tester.renderObject<RenderParagraph>(referenceFinder);
      final creditStart = reference.indexOf('Hasan Efendi Nahi');
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: creditStart, extentOffset: reference.length),
      );
      expect(boxes, isNotEmpty);
      for (final box in boxes) {
        expect(box.bottom, lessThanOrEqualTo(paragraph.size.height + 0.01));
      }
      expect(tester.takeException(), isNull);
      await capture(tester, key, 'quran-credit');
    },
  );
}
