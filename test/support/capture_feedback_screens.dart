// Manual visual QA helper; run with `flutter test --no-pub <this file>`.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/screens/add_dua_screen.dart';
import 'package:dua_app/screens/after_prayer_tasbih_screen.dart';
import 'package:dua_app/screens/tasbih_screen.dart';
import 'package:dua_app/services/custom_dua_service.dart';
import 'package:dua_app/services/display_settings.dart';
import 'package:dua_app/services/dua_progress_service.dart';
import 'package:dua_app/services/tasbih_controller.dart';
import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DuaRepository repo;
  setUpAll(() async {
    repo = DuaRepository();
    await repo.load();
    for (final family in {
      'MaterialIcons': ['fonts/MaterialIcons-Regular.otf'],
      'Crimson Pro': [
        'assets/fonts/latin/CrimsonPro-Regular.ttf',
        'assets/fonts/latin/CrimsonPro-SemiBold.ttf',
      ],
      'Karla': [
        'assets/fonts/latin/Karla-Regular.ttf',
        'assets/fonts/latin/Karla-Bold.ttf',
      ],
      'Amiri': [
        'assets/fonts/Amiri-Regular.ttf',
        'assets/fonts/Amiri-Bold.ttf',
      ],
    }.entries) {
      final loader = FontLoader(family.key);
      for (final path in family.value) {
        loader.addFont(rootBundle.load(path));
      }
      await loader.load();
    }
  });

  testWidgets('capture edited phone surfaces with bundled fonts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> capture(
      String name,
      Widget screen, {
      AppLang lang = AppLang.en,
      bool dialog = false,
      bool bottom = false,
    }) async {
      SharedPreferences.setMockInitialValues({
        'app_language': lang.name,
        'tasbih_count_subhanallah': 33,
        'tasbih_laps_subhanallah': 1,
      });
      final prefs = await SharedPreferences.getInstance();
      final tasbih = TasbihController(prefs);
      final progress = DuaProgressService(prefs)
        ..setCount('salah_subhanallah', 33);
      final key = GlobalKey();
      await tester.pumpWidget(
        MultiProvider(
          key: UniqueKey(),
          providers: [
            Provider.value(value: repo),
            ChangeNotifierProvider.value(value: tasbih),
            ChangeNotifierProvider.value(value: progress),
            ChangeNotifierProvider(create: (_) => LocaleController(prefs)),
            ChangeNotifierProvider(create: (_) => DisplaySettings(prefs)),
            ChangeNotifierProvider(create: (_) => CustomDuaService(prefs)),
          ],
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: Locale(lang.name),
              supportedLocales: LocaleController.supported,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: AppTheme.light(
                AppPalettes.emerald,
                arabicUi: lang == AppLang.ar,
              ),
              home: screen,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      if (bottom) {
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('custom_repeat_count')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('custom_repeat_count')),
          '100',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
      }
      if (dialog) {
        await tester.tap(find.byKey(const ValueKey('add_custom_dhikr')));
        await tester.pumpAndSettle();
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
      }
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final path = File('tool/feedback/previews/$name.png');
        await path.parent.create(recursive: true);
        await path.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
      tasbih.dispose();
    }

    await capture('custom-repeat-en', const AddDuaScreen(), bottom: true);
    await capture('tasbih-complete-en', const TasbihScreen());
    await capture(
      'tasbih-add-ar',
      const TasbihScreen(),
      lang: AppLang.ar,
      dialog: true,
    );
    await capture(
      'after-prayer-ar',
      const AfterPrayerTasbihScreen(),
      lang: AppLang.ar,
    );
  });
}
