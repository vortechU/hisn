import 'package:dua_app/data/dua_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('farewell card matches its cited final-deeds wording', () async {
    final repo = DuaRepository();
    await repo.load();
    final dua = repo.duaById('travel_astawdiuka')!;
    expect(dua.arabic, contains('وَخَوَاتِيمَ عَمَلِكَ'));
    expect(dua.transliteration, contains("wa khawatima 'amalik"));
    expect(dua.reference, contains('2600'));
    expect(dua.referenceFor('ar'), contains('٢٦٠٠'));
    expect(dua.translationFor('id'), contains('penutup hidupmu'));
  });

  test(
    'both leaving-home supplications remain distinct and adjacent',
    () async {
      final repo = DuaRepository();
      await repo.load();
      final daily = repo.duasForCategory('daily');
      final first = daily.indexWhere((d) => d.id == 'daily_leaving_home');
      expect(first, greaterThanOrEqualTo(0));
      final dua = daily[first + 1];
      expect(dua.id, 'daily_leaving_home_protection');
      expect(daily.where((d) => d.id == dua.id), hasLength(1));
      expect(daily[first].arabic, startsWith('بِسْمِ اللَّهِ'));

      // Vowels distinguish active and passive words: do not normalize them.
      for (final pair in [
        'أَضِلَّ أَوْ أُضَلَّ',
        'أَزِلَّ أَوْ أُزَلَّ',
        'أَظْلِمَ أَوْ أُظْلَمَ',
        'أَجْهَلَ أَوْ يُجْهَلَ عَلَيَّ',
      ]) {
        expect(dua.arabic, contains(pair));
      }
      expect(dua.translation, contains('going astray or being led astray'));
      expect(dua.translationFor('id'), contains('menzalimi atau dizalimi'));
      expect(dua.reference, 'Sunan Abi Dawud 5094');
      expect(dua.referenceFor('ar'), 'سنن أبي داود ٥٠٩٤');
      expect(dua.repeat, 1);
      expect(dua.virtue, isNull);
    },
  );
}
