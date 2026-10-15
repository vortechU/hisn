import 'dart:convert';

import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/models/dua.dart';
import 'package:dua_app/services/display_settings.dart';
import 'package:dua_app/services/favorites_service.dart';
import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:dua_app/widgets/dua_card.dart';
import 'package:dua_app/widgets/dua_instruction.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sample = Dua(
    id: 'sleep_test',
    categoryId: 'sleep',
    title: 'Bedtime remembrance',
    arabic: 'قُلْ هُوَ اللَّهُ أَحَدٌ',
    transliteration: 'Qul huwallahu ahad',
    translation: 'Say: He is Allah, One.',
    reference: 'Sahih al-Bukhari 5017',
    virtue: 'The Prophet did this every night.',
    instruction: 'Cup your hands and recite the three surahs.',
    localizedInstructions: {
      'ar': 'اجمع كفيك واقرأ السور الثلاث، ثم انفث وامسح جسدك ثلاث مرات.',
      'id': 'Satukan kedua telapak tangan dan baca ketiga surah.',
    },
  );

  test(
    'optional instruction survives serialization and unrelated overlays',
    () {
      final restored = Dua.fromJson(sample.toJson());
      expect(restored.instructionFor('en'), sample.instruction);
      expect(restored.instructionFor('ar'), sample.instruction);
      final localized = sample.withLocalized(
        references: {'ar': 'صحيح البخاري'},
      );
      expect(
        localized.instructionFor('ar'),
        sample.localizedInstructions['ar'],
      );
      expect(
        localized.instructionFor('id'),
        sample.localizedInstructions['id'],
      );
      final legacy = Map<String, dynamic>.from(sample.toJson())
        ..remove('instruction');
      expect(Dua.fromJson(legacy).instructionFor('en'), isNull);
      expect(Dua.fromJson(legacy).toJson(), isNot(contains('instruction')));
    },
  );

  test('repository attaches instructions and ignores blank overlays', () async {
    final fixtures = {
      'assets/data/categories.json': <Object>[],
      'assets/data/tasbih.json': <Object>[],
      'assets/data/duas.json': [sample.toJson()],
      'assets/data/duas.ar.json': {
        sample.id: {'instruction': sample.localizedInstructions['ar']},
      },
      'assets/data/duas.id.json': {
        sample.id: {'instruction': '   '},
      },
    };
    rootBundle.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      final value = fixtures[key];
      if (value == null) return null;
      return ByteData.sublistView(
        Uint8List.fromList(utf8.encode(jsonEncode(value))),
      );
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
      rootBundle.clear();
    });
    final repository = DuaRepository();
    await repository.load();
    final dua = repository.duaById(sample.id)!;
    expect(dua.instructionFor('ar'), sample.localizedInstructions['ar']);
    expect(dua.instructionFor('id'), sample.instruction);
    expect(dua.virtue, sample.virtue);
    expect(dua.arabic, sample.arabic);
  });

  for (final lang in AppLang.values) {
    testWidgets(
      'guidance precedes recitation, virtue stays below in ${lang.name}',
      (tester) async {
        SharedPreferences.setMockInitialValues({'app_language': lang.name});
        final prefs = await SharedPreferences.getInstance();
        await tester.binding.setSurfaceSize(const Size(320, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => LocaleController(prefs)),
              ChangeNotifierProvider(create: (_) => DisplaySettings(prefs)),
              ChangeNotifierProvider(create: (_) => FavoritesService(prefs)),
            ],
            child: MaterialApp(
              theme: AppTheme.light(AppPalettes.fallback),
              home: Scaffold(
                body: Directionality(
                  textDirection: lang == AppLang.ar
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: const SingleChildScrollView(
                    child: DuaCard(dua: sample),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        final instruction = find.text(sample.instructionFor(lang.name)!);
        final recitation = find.text(sample.arabic);
        final virtue = find.text(sample.virtue!);
        expect(find.byType(DuaInstruction), findsOneWidget);
        expect(instruction, findsOneWidget);
        expect(
          tester.getBottomLeft(instruction).dy,
          lessThan(tester.getTopLeft(recitation).dy),
        );
        expect(
          tester.getBottomLeft(recitation).dy,
          lessThan(tester.getTopLeft(virtue).dy),
        );
        if (lang == AppLang.ar) {
          expect(find.text(sample.translation), findsNothing);
          expect(find.text(sample.transliteration), findsNothing);
          final text = tester.widget<Text>(instruction);
          expect(
            Directionality.of(tester.element(instruction)),
            TextDirection.rtl,
          );
          expect(text.maxLines, isNull);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
