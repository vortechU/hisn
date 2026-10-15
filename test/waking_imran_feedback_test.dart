import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/data/quran_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'waking Aal Imran card carries the complete numbered Quran range',
    () async {
      final repo = DuaRepository();
      final quran = QuranRepository();
      await repo.load();
      final surah = await quran.loadSurah(3);
      final dua = repo.duaById('waking_imran_190_200')!;
      final expected = surah.ayahs.where((v) => v.number >= 190).toList();
      expect(expected, hasLength(11));
      var previous = -1;
      for (final verse in expected) {
        final position = dua.arabic.indexOf(verse.text);
        expect(position, greaterThan(previous), reason: '${verse.number}');
        previous = position;
      }
      expect(dua.arabic, isNot(contains(surah.ayahs[188].text)));
      expect(dua.categoryId, 'waking');
      expect(dua.title, contains('190–200'));
      expect(dua.titleArabic, contains('١٩٠–٢٠٠'));
      expect(dua.repeat, 1);
      expect(dua.virtue, isNull);
      expect(dua.referenceFor('ar'), isNot(matches(RegExp('[A-Za-z]'))));
      expect(dua.instructionFor('ar'), contains('ليلًا'));
      expect(dua.instructionFor('id'), contains('malam hari'));

      for (final lang in ['en', 'id']) {
        final translation = (await quran.loadTranslation(3, lang))!;
        for (var number = 190; number <= 200; number++) {
          expect(
            dua.translationFor(lang),
            contains(translation.ayahs[number - 1]),
          );
        }
      }
    },
  );
}
