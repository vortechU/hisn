import 'dart:io';
import 'dart:ui' as ui;

import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/data/quran_repository.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/screens/mushaf_screen.dart';
import 'package:dua_app/screens/quran_screen.dart';
import 'package:dua_app/services/display_settings.dart';
import 'package:dua_app/services/dua_progress_service.dart';
import 'package:dua_app/services/favorites_service.dart';
import 'package:dua_app/services/quran_service.dart';
import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:dua_app/widgets/category_card.dart';
import 'package:dua_app/widgets/dua_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opt-in review artifacts, produced from actual widgets and bundled fonts:
/// flutter test test/feedback_previews_test.dart --dart-define=CAPTURE_FEEDBACK=true
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const capture = bool.fromEnvironment('CAPTURE_FEEDBACK');
  late DuaRepository duas;
  late QuranRepository quran;
  late SharedPreferences prefs;
  late DuaProgressService progress;
  const boundaryKey = ValueKey('feedback-preview');

  setUpAll(() async {
    if (!capture) return;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
      (_) async => const StandardMessageCodec().encodeMessage(<Object?>[null]),
    );
    SharedPreferences.setMockInitialValues({'app_language': 'ur'});
    prefs = await SharedPreferences.getInstance();
    progress = DuaProgressService(prefs);
    duas = DuaRepository();
    quran = QuranRepository();
    await Future.wait([duas.load(), quran.loadIndex()]);
    await quran.searchVerses('قل هو الله احد');
    await Future.wait([for (final page in [602, 603, 604]) quran.loadPage(page)]);
    for (final (family, asset) in [
      ('Amiri', 'assets/fonts/Amiri-Regular.ttf'),
      ('Crimson Pro', 'assets/fonts/latin/CrimsonPro-Regular.ttf'),
      ('Karla', 'assets/fonts/latin/Karla-Regular.ttf'),
      ('QCF4_Hafs_01', 'assets/fonts/quran/QCF4_Hafs_01.ttf'),
      ('QCF4_Hafs_47', 'assets/fonts/quran/QCF4_Hafs_47.ttf'),
      ('QCF4_QBSML', 'assets/fonts/quran/QCF4_QBSML.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
    // Mix complete, partial and untouched entries on the same grid.
    for (final category in ['morning', 'sleep']) {
      for (final dua in duas.duasForCategory(category)) {
        progress.setCount(dua.id, dua.repeat);
      }
    }
    final firstEvening = duas.duasForCategory('evening').first;
    progress.setCount(firstEvening.id, firstEvening.repeat);
  });

  Widget host(Widget screen, Brightness brightness, String lang) => MultiProvider(
    key: ValueKey('${brightness.name}-$lang-${screen.runtimeType}'),
    providers: [
      Provider<DuaRepository>.value(value: duas),
      Provider<QuranRepository>.value(value: quran),
      ChangeNotifierProvider<DuaProgressService>.value(value: progress),
      ChangeNotifierProvider(create: (_) => LocaleController(prefs)..setLocale(Locale(lang))),
      ChangeNotifierProvider(create: (_) => DisplaySettings(prefs)),
      ChangeNotifierProvider(create: (_) => FavoritesService(prefs)),
      ChangeNotifierProvider(create: (_) => QuranService(prefs)),
    ],
    child: RepaintBoundary(
      key: boundaryKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: Locale(lang),
        supportedLocales: LocaleController.supported,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: brightness == Brightness.dark
            ? AppTheme.dark(AppPalettes.fallback)
            : AppTheme.light(AppPalettes.fallback),
        home: screen,
      ),
    ),
  );

  Future<void> save(WidgetTester tester, String name) async {
    expect(tester.takeException(), isNull);
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(boundaryKey));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('build/feedback-preview');
      await directory.create(recursive: true);
      await File('${directory.path}/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final (device, size) in [
    ('phone', const Size(390, 900)),
    ('tablet', const Size(840, 1100)),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets('$device $brightness feedback previews', (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final variant = '$device-${brightness.name}';
        await tester.pumpWidget(host(
          Scaffold(body: SafeArea(child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: DuaCard(dua: duas.duaById('daily_leaving_home')!),
          ))), brightness, 'ur'));
        await tester.pumpAndSettle();
        await save(tester, '$variant-urdu-dua');

        await tester.pumpWidget(host(Scaffold(body: SafeArea(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            CategoryCard(category: duas.categoryById('morning')!,
              count: duas.countForCategory('morning'), featured: true, onTap: () {}),
            const SizedBox(height: 12),
            Expanded(child: GridView.count(crossAxisCount: 2, mainAxisSpacing: 12,
              crossAxisSpacing: 12, childAspectRatio: 1.06, children: [
                for (final id in ['evening', 'after_salah', 'sleep', 'waking'])
                  CategoryCard(category: duas.categoryById(id)!,
                    count: duas.countForCategory(id), onTap: () {}),
              ])),
          ]),
        ))), brightness, 'ar'));
        await tester.pumpAndSettle();
        await save(tester, '$variant-category-completion');

        await tester.pumpWidget(host(const QuranScreen(), brightness, 'ar'));
        await tester.enterText(find.byType(TextField), 'قل هو الله احد');
        await tester.pump(const Duration(milliseconds: 300));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pumpAndSettle();
        await save(tester, '$variant-quran-search');

        await tester.pumpWidget(host(const MushafScreen(startPage: 604), brightness, 'ar'));
        await tester.pumpAndSettle();
        await save(tester, '$variant-mushaf-604');
        await tester.pumpWidget(const SizedBox.shrink());
      }, skip: !capture);
    }
  }
}
