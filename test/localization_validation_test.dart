import 'dart:io';

import 'package:dua_app/data/content_overlay.dart';
import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/i18n/strings.g.dart';
import 'package:dua_app/l10n/app_strings.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tool/validate_localizations.dart';

class _BrokenOverlayBundle extends CachingAssetBundle {
  _BrokenOverlayBundle(this.broken);
  final String? broken;

  @override
  Future<ByteData> load(String key) => rootBundle.load(key);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == 'assets/data/duas.ur.json') {
      if (broken == null) throw StateError('Missing test asset');
      return broken!;
    }
    return rootBundle.loadString(key, cache: cache);
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  test('all registered catalogs, content and native assets are complete', () {
    expect(localizationProblems(), isEmpty);
    expect(
      AppLocale.values.map((locale) => locale.languageCode).toSet(),
      AppLang.values.map((language) => language.code).toSet(),
    );
    expect(
      LocaleController.supported.map((locale) => locale.languageCode),
      AppLang.values.map((language) => language.code),
    );
  });

  test('registered directions agree with Flutter for every language', () async {
    for (final language in AppLang.values) {
      final widgets = await GlobalWidgetsLocalizations.delegate.load(
        Locale(language.code),
      );
      expect(
        widgets.textDirection,
        language.rtl ? TextDirection.rtl : TextDirection.ltr,
        reason: language.code,
      );
    }
  });

  test(
    'validation rejects missing keys, empty strings and incorrect placeholders',
    () {
      final source = {
        'greeting': r'Hello $name',
        'choices': ['First', 'Second'],
      };
      for (final invalid in [
        {
          'choices': ['First', 'Second'],
        },
        {
          'greeting': '',
          'choices': ['First', 'Second'],
        },
        {
          'greeting': r'Hello $other',
          'choices': ['First', 'Second'],
        },
        {
          'greeting': r'Hello ${name}',
          'choices': ['First'],
        },
      ]) {
        expect(validateCatalog(source, invalid), isNotEmpty);
      }
      expect(
        validateCatalog(source, {
          'greeting': r'Hello ${name}',
          'choices': ['A', 'B'],
        }),
        isEmpty,
      );
    },
  );

  test('validation permits language-specific plural categories and duals', () {
    final source = {
      'items(param=count)': {'one': 'One item', 'other': r'$count items'},
    };
    final translated = {
      'items(param=count)': {
        'one': 'عنصر واحد',
        'two': 'عنصران',
        'few': r'$count عناصر',
        'other': r'$count عنصر',
      },
    };
    expect(validateCatalog(source, translated), isEmpty);
    expect(
      validateCatalog(source, {
        'items(param=count)': {'one': 'Only one'},
      }),
      isNotEmpty,
    );
    expect(
      validateCatalog(source, {
        'items(param=count)': {'other': r'$wrong items'},
      }),
      isNotEmpty,
    );
  });

  test(
    'content parser rejects malformed entries rather than treating them as absent',
    () {
      for (final invalid in [
        '[]',
        '{',
        '{"x": 7}',
        '{"x": {"translation": 7}}',
        '{"x": {"translation": " "}}',
        '{"x": {"typo": "text"}}',
      ]) {
        expect(
          () => decodeContentOverlay(invalid, allowedFields: {'translation'}),
          throwsFormatException,
        );
      }
    },
  );

  test('Arabic plurals select zero, singular, dual, few, many and other', () {
    final strings = AppStrings(AppLang.ar);
    expect(strings.streakDays(0), 'سلسلة بلا أيام');
    expect(strings.daysValue(1), 'يوم واحد');
    expect(strings.daysValue(2), 'يومان');
    expect(strings.daysValue(3), '3 أيام');
    expect(strings.daysValue(11), '11 يومًا');
    expect(strings.daysValue(102), '102 يوم');
    expect(strings.versesCount(2), 'آيتان');
    expect(strings.readNow(3), 'اقرأ الآن · 3 أدعية');
    expect(strings.restoreDone(2), 'تمت استعادة عنصرين');
    expect(AppStrings(AppLang.en).daysValue(2), '2 days');
    expect(AppStrings(AppLang.id).daysValue(1), '1 hari');
  });

  test(
    'language changes persist before observers read the new language',
    () async {
      SharedPreferences.setMockInitialValues({'app_language': 'obsolete'});
      final prefs = await SharedPreferences.getInstance();
      final controller = LocaleController(prefs);
      addTearDown(controller.dispose);
      expect(controller.lang, AppLang.en);
      expect(prefs.getString('app_language'), 'en');
      controller.addListener(() {
        expect(prefs.getString('app_language'), controller.lang.code);
        expect(AppStrings(controller.lang).rtl, controller.rtl);
      });
      for (final language in AppLang.values) {
        await controller.setLang(language);
        expect(controller.locale, Locale(language.code));
        expect(
          AppStrings(controller.lang).currentLanguage,
          language.nativeName,
        );
      }
      await controller.setLocale(const Locale('unsupported'));
      expect(controller.lang, AppLang.en);
    },
  );

  test('a pending preference write cannot notify after disposal', () async {
    SharedPreferences.setMockInitialValues({'app_language': 'en'});
    final prefs = await SharedPreferences.getInstance();
    final controller = LocaleController(prefs);
    final pending = controller.setLang(AppLang.ar);
    controller.dispose();
    await pending;
    expect(prefs.getString('app_language'), 'ar');
  });

  test(
    'first launch matches the ordered device locales and persists the choice',
    () async {
      binding.platformDispatcher.localesTestValue = [
        const Locale('fr'),
        const Locale('ur', 'PK'),
      ];
      addTearDown(binding.platformDispatcher.clearLocalesTestValue);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = LocaleController(prefs);
      addTearDown(controller.dispose);
      expect(controller.lang, AppLang.ur);
      expect(controller.rtl, isTrue);
      expect(controller.isArabic, isFalse);
      expect(prefs.getString('app_language'), 'ur');
    },
  );

  test(
    'repository loads category and tasbih overlays without changing base content',
    () async {
      final repository = DuaRepository();
      await repository.load();
      for (final language in AppLang.values) {
        for (final dataset in ['categories', 'tasbih']) {
          if (!language.overlays.containsKey(dataset)) continue;
          final overlay = decodeContentOverlay(
            File(language.overlayAsset(dataset)).readAsStringSync(),
            allowedFields: contentFields[dataset]!,
          );
          for (final entry in overlay.entries) {
            if (dataset == 'categories') {
              final category = repository.categoryById(entry.key)!;
              expect(
                category.titleForLang(language.code),
                entry.value['title'],
              );
              expect(
                category.subtitleForLang(language.code),
                entry.value['subtitle'],
              );
              expect(category.titleForLang('unknown'), category.title);
            } else {
              final dhikr = repository.dhikr.singleWhere(
                (dhikr) => dhikr.id == entry.key,
              );
              expect(
                dhikr.translationFor(language.code),
                entry.value['translation'],
              );
              expect(dhikr.translationFor('unknown'), dhikr.translation);
            }
          }
        }
      }
    },
  );

  for (final broken in <String?>[
    null,
    '{',
    '{"morning_ayat_kursi":{"translation": 7}}',
  ]) {
    test(
      'missing/malformed overlay falls back without losing the base dua ($broken)',
      () async {
        final repository = DuaRepository(bundle: _BrokenOverlayBundle(broken));
        await repository.load();
        final dua = repository.duas.first;
        expect(dua.translationFor('ur'), dua.translation);
        expect(dua.referenceFor('ur'), dua.reference);
        expect(dua.arabic, isNotEmpty);
        expect(dua.translationFor('id'), isNot(dua.translation));
        expect(
          repository.categoryById('morning')!.titleForLang('ur'),
          'صبح کے اذکار',
        );
      },
    );
  }
}
