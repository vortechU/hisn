import 'dart:convert';
import 'dart:io';

import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/l10n/app_strings.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/models/dua.dart';
import 'package:dua_app/models/shareable.dart';
import 'package:dua_app/services/display_settings.dart';
import 'package:dua_app/services/favorites_service.dart';
import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:dua_app/widgets/dua_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Urdu UI supplies every source key with matching placeholders', () {
    final en =
        jsonDecode(File('lib/i18n/en.i18n.json').readAsStringSync()) as Map;
    final ur =
        jsonDecode(File('lib/i18n/ur.i18n.json').readAsStringSync()) as Map;
    expect(ur.keys.toSet(), en.keys.toSet());
    final parameters = RegExp(r'\$[a-zA-Z_]+');
    for (final key in en.keys) {
      final originals = en[key] is List ? en[key] as List : [en[key]];
      final localized = ur[key] is List ? ur[key] as List : [ur[key]];
      expect(localized, hasLength(originals.length), reason: '$key');
      for (var i = 0; i < originals.length; i++) {
        expect(
          parameters
              .allMatches(localized[i] as String)
              .map((m) => m[0])
              .toSet(),
          parameters
              .allMatches(originals[i] as String)
              .map((m) => m[0])
              .toSet(),
          reason: '$key',
        );
        if (key != 'verseRange' && key != 'prayerNone') {
          expect(
            localized[i],
            matches(RegExp(r'[\u0600-\u06FF]')),
            reason: '$key',
          );
        }
      }
    }
  });

  test(
    'Urdu persists as a distinct RTL language and resolves generated text',
    () async {
      SharedPreferences.setMockInitialValues({'app_language': 'ur'});
      final prefs = await SharedPreferences.getInstance();
      final locale = LocaleController(prefs);
      expect(locale.lang, AppLang.ur);
      expect(locale.rtl, isTrue);
      expect(locale.isArabic, isFalse);
      expect(LocaleController.supported, contains(const Locale('ur')));
      final strings = AppStrings(locale.lang);
      expect(strings.ar, isFalse);
      expect(strings.rtl, isTrue);
      expect(strings.currentLanguage, 'اردو');
      expect(strings.navQuran, 'قرآن');
      await locale.setLang(AppLang.en);
      await locale.setLang(AppLang.ur);
      expect(prefs.getString('app_language'), 'ur');
    },
  );

  const dua = Dua(
    id: 'example',
    categoryId: 'daily',
    title: 'Example',
    titleArabic: 'عنوان',
    arabic: 'الْحَمْدُ لِلَّهِ',
    transliteration: 'Alhamdulillah',
    translation: 'Praise belongs to Allah.',
    reference: 'Example reference',
    localizedTitles: {'ur': 'اَلْحَمْدُ لِلّٰہ کا ذکر'},
    localizedTranslations: {'ur': 'تمام تعریفیں اللہ کے لیے ہیں'},
    localizedInstructions: {'ur': 'یہ دعا پڑھیں'},
    localizedReferences: {'ur': 'حوالہ'},
  );

  test(
    'Urdu titles are searchable with and without diacritics and survive overlays',
    () {
      expect(DuaRepository.searchIn([dua], 'الحمد', langCode: 'ur'), [dua]);
      expect(DuaRepository.searchIn([dua], 'کا ذکر', langCode: 'ur'), [dua]);
      expect(
        dua.withLocalized(virtues: {'ur': 'فضیلت'}).titleForLang('ur'),
        dua.titleForLang('ur'),
      );
      final share = Shareable.dua(dua, 'ur');
      expect(share.translation, 'تمام تعریفیں اللہ کے لیے ہیں');
      expect(share.translationIsRtl, isTrue);
      expect(share.translationIsArabic, isFalse);
      expect(share.titleArabic, dua.titleForLang('ur'));
      expect(share.asText(), contains('تمام تعریفیں'));
    },
  );

  testWidgets(
    'Urdu reads right to left while keeping dua meaning and instruction visible',
    (tester) async {
      SharedPreferences.setMockInitialValues({'app_language': 'ur'});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LocaleController(prefs)),
            ChangeNotifierProvider(create: (_) => DisplaySettings(prefs)),
            ChangeNotifierProvider(create: (_) => FavoritesService(prefs)),
          ],
          child: MaterialApp(
            locale: const Locale('ur'),
            supportedLocales: LocaleController.supported,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.light(AppPalettes.emerald, arabicUi: true),
            home: const Scaffold(
              body: SingleChildScrollView(child: DuaCard(dua: dua)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        Directionality.of(tester.element(find.byType(DuaCard))),
        TextDirection.rtl,
      );
      expect(find.text('تمام تعریفیں اللہ کے لیے ہیں'), findsOneWidget);
      expect(find.text('یہ دعا پڑھیں'), findsOneWidget);
      expect(find.text(dua.titleForLang('ur')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
