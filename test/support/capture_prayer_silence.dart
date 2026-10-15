// Manual screenshot QA: flutter test --no-pub test/support/capture_prayer_silence.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/screens/settings/prayer_silence_settings_screen.dart';
import 'package:dua_app/services/prayer_silence_settings.dart';
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
  setUpAll(() async {
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
  testWidgets('capture prayer silence with bundled fonts', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final lang in [AppLang.en, AppLang.ar]) {
      SharedPreferences.setMockInitialValues({
        'app_language': lang.name,
        'prayer_silence_enabled': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final settings = PrayerSilenceSettings(
        prefs,
        supported: true,
        bridge: (_, args) async => {
          'reason': 'permission',
          'policyGranted': false,
          'exactAllowed': false,
        },
      );
      final key = GlobalKey();
      await tester.pumpWidget(
        MultiProvider(
          key: UniqueKey(),
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider(create: (_) => LocaleController(prefs)),
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
              theme: lang == AppLang.ar
                  ? AppTheme.dark(AppPalettes.emerald, arabicUi: true)
                  : AppTheme.light(AppPalettes.emerald),
              home: const PrayerSilenceSettingsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(
          'tool/feedback/previews/prayer-silence-${lang.name}.png',
        );
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
      settings.dispose();
    }
  });
}
