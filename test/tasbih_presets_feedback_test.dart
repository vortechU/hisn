import 'dart:convert';

import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/screens/tasbih_screen.dart';
import 'package:dua_app/services/display_settings.dart';
import 'package:dua_app/services/tasbih_controller.dart';
import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
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
  });
  const widgetChannel = MethodChannel('hisn/widget');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(widgetChannel, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(widgetChannel, null);
  });

  test(
    'custom presets persist edits, selection and counts independently',
    () async {
      SharedPreferences.setMockInitialValues({
        'tasbih_count_subhanallah': 12,
        'tasbih_laps_subhanallah': 2,
      });
      final prefs = await SharedPreferences.getInstance();
      final controller = TasbihController(prefs);
      addTearDown(controller.dispose);
      final added = await controller.addCustom(
        name: ' My hawqala ',
        arabic: ' لا حول ولا قوة إلا بالله ',
        target: 100,
      );
      expect(added.transliteration, 'My hawqala');
      expect(added.arabic, 'لا حول ولا قوة إلا بالله');
      await controller.select(added);
      await controller.increment(added.id, added.target);
      final updated = await controller.updateCustom(
        id: added.id,
        name: 'Hawqala',
        arabic: added.arabic,
        target: 200,
      );
      expect(updated.id, added.id);
      expect(controller.countFor(added.id), 1);
      final reloaded = TasbihController(prefs);
      addTearDown(reloaded.dispose);
      expect(reloaded.customDhikr.single.target, 200);
      expect(reloaded.selectedId, added.id);
      expect(reloaded.countFor(added.id), 1);
      expect(reloaded.countFor('subhanallah'), 12);
      expect(reloaded.lapsFor('subhanallah'), 2);
      await controller.removeCustom(added.id);
      expect(controller.customDhikr, isEmpty);
      expect(controller.selectedId, isNull);
      expect(controller.countFor(added.id), 0);
      expect(controller.countFor('subhanallah'), 12);
    },
  );

  test('malformed custom entries do not discard other saved phrases', () async {
    SharedPreferences.setMockInitialValues({
      'tasbih_custom_phrases': jsonEncode([
        {
          'id': 'custom_dhikr_good',
          'arabic': 'الحمد لله',
          'transliteration': 'Praise',
          'translation': '',
          'target': 50,
        },
        {'id': 'custom_dhikr_bad', 'target': 0},
      ]),
    });
    final prefs = await SharedPreferences.getInstance();
    final controller = TasbihController(prefs);
    addTearDown(controller.dispose);
    expect(controller.customDhikr.single.id, 'custom_dhikr_good');
    for (final target in [0, TasbihController.maxCustomTarget + 1]) {
      expect(
        controller.addCustom(name: 'Bad', arabic: 'ذكر', target: target),
        throwsArgumentError,
      );
    }
  });

  test('hawqala is available as a 100-count preset', () async {
    final repo = DuaRepository();
    await repo.load();
    final hawqala = repo.dhikr.singleWhere((d) => d.id == 'hawqala');
    expect(hawqala.target, 100);
    expect(hawqala.arabic, 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ');
    expect(repo.dhikr.map((d) => d.id).toSet(), hasLength(repo.dhikr.length));
  });

  Future<TasbihController> host(
    WidgetTester tester, {
    AppLang lang = AppLang.en,
  }) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'app_language': lang.name});
    final prefs = await SharedPreferences.getInstance();
    final controller = TasbihController(prefs);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: repo),
          ChangeNotifierProvider.value(value: controller),
          ChangeNotifierProvider(create: (_) => LocaleController(prefs)),
          ChangeNotifierProvider(create: (_) => DisplaySettings(prefs)),
        ],
        child: MaterialApp(
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
          home: const TasbihScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('create, edit and delete a custom phrase from the counter', (
    tester,
  ) async {
    final controller = await host(tester);
    await tester.tap(find.byKey(const ValueKey('add_custom_dhikr')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('custom_dhikr_name')),
      'My phrase',
    );
    await tester.enterText(
      find.byKey(const ValueKey('custom_dhikr_arabic')),
      'الحمد لله',
    );
    await tester.enterText(
      find.byKey(const ValueKey('custom_dhikr_target')),
      '100',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(controller.customDhikr.single.target, 100);
    final id = controller.customDhikr.single.id;
    expect(controller.selectedId, id);
    await tester.tap(find.byKey(const ValueKey('custom_dhikr_actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit dhikr'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('custom_dhikr_target')),
      '200',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(controller.customDhikr.single.target, 200);
    expect(controller.customDhikr.single.id, id);
    await tester.tap(find.byKey(const ValueKey('custom_dhikr_actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete dhikr'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(controller.customDhikr, isEmpty);
    expect(controller.selectedId, 'subhanallah');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Arabic custom target accepts Arabic digits and validates its range',
    (tester) async {
      final controller = await host(tester, lang: AppLang.ar);
      await tester.tap(find.byKey(const ValueKey('add_custom_dhikr')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('custom_dhikr_name')),
        'الحوقلة',
      );
      await tester.enterText(
        find.byKey(const ValueKey('custom_dhikr_arabic')),
        'لا حول ولا قوة إلا بالله',
      );
      await tester.enterText(
        find.byKey(const ValueKey('custom_dhikr_target')),
        '٠',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
      await tester.pumpAndSettle();
      expect(controller.customDhikr, isEmpty);
      await tester.enterText(
        find.byKey(const ValueKey('custom_dhikr_target')),
        '١٠٠',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
      await tester.pumpAndSettle();
      expect(controller.customDhikr.single.target, 100);
      expect(tester.takeException(), isNull);
    },
  );
}
