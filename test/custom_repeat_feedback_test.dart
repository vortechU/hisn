import 'dart:convert';

import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/models/dua.dart';
import 'package:dua_app/screens/add_dua_screen.dart';
import 'package:dua_app/services/custom_dua_service.dart';
import 'package:dua_app/services/display_settings.dart';
import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final repeatField = find.byKey(const ValueKey('custom_repeat_count'));
  late CustomDuaService service;

  Future<void> openEditor(
    WidgetTester tester, {
    AppLang lang = AppLang.en,
    Dua? existing,
  }) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'app_language': lang.name});
    final prefs = await SharedPreferences.getInstance();
    service = CustomDuaService(prefs);
    if (existing != null) {
      await prefs.setString('custom_duas', jsonEncode([existing.toJson()]));
      service = CustomDuaService(prefs);
    }
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: service),
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
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => AddDuaScreen(existing: existing),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    if (existing == null) {
      await tester.enterText(find.byType(TextFormField).first, 'اللهم اغفر لي');
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      repeatField,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(TextButton),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('entering 100 saves it directly without increment taps', (
    tester,
  ) async {
    await openEditor(tester);
    expect(repeatField, findsOneWidget);
    await tester.ensureVisible(repeatField);
    await tester.enterText(repeatField, '100');
    await save(tester);
    expect(service.duas.single.repeat, 100);
  });

  for (final value in ['١٠٠', '۱۰۰']) {
    testWidgets(
      'Arabic interface accepts numeral input $value with LTR editing',
      (tester) async {
        await openEditor(tester, lang: AppLang.ar);
        await tester.ensureVisible(repeatField);
        final field = tester.widget<EditableText>(
          find.descendant(of: repeatField, matching: find.byType(EditableText)),
        );
        expect(field.textDirection, TextDirection.ltr);
        await tester.enterText(repeatField, value);
        await save(tester);
        expect(service.duas.single.repeat, 100);
      },
    );
  }

  testWidgets('empty and zero targets cannot save a stale value', (
    tester,
  ) async {
    await openEditor(tester);
    await tester.ensureVisible(repeatField);
    for (final text in ['', '0']) {
      await tester.enterText(repeatField, text);
      await save(tester);
      expect(service.duas, isEmpty);
      expect(find.text('Enter a whole number of 1 or more.'), findsOneWidget);
    }
    await tester.enterText(repeatField, '7');
    await save(tester);
    expect(service.duas.single.repeat, 7);
  });

  testWidgets(
    'editing preserves service-valid values above the old stepper limit',
    (tester) async {
      const dua = Dua(
        id: 'custom_existing',
        categoryId: Dua.customCategoryId,
        title: 'Existing',
        arabic: 'الحمد لله',
        transliteration: '',
        translation: '',
        reference: 'My dua',
        repeat: 2000,
      );
      await openEditor(tester, existing: dua);
      await tester.ensureVisible(repeatField);
      expect(
        tester.widget<TextFormField>(repeatField).controller!.text,
        '2000',
      );
      await tester.tap(find.byKey(const ValueKey('custom_repeat_increment')));
      await tester.pump();
      expect(
        tester.widget<TextFormField>(repeatField).controller!.text,
        '2001',
      );
      await save(tester);
      expect(service.duas.single.id, dua.id);
      expect(service.duas.single.repeat, 2001);
    },
  );

  testWidgets('decrement cannot cross one and stepper follows typed counts', (
    tester,
  ) async {
    await openEditor(tester);
    await tester.ensureVisible(repeatField);
    final decrement = find.byKey(const ValueKey('custom_repeat_decrement'));
    expect(tester.widget<IconButton>(decrement).onPressed, isNull);
    await tester.enterText(repeatField, '100');
    await tester.pump();
    await tester.tap(decrement);
    await tester.pump();
    expect(tester.widget<TextFormField>(repeatField).controller!.text, '99');
    await save(tester);
    expect(service.duas.single.repeat, 99);
  });
}
