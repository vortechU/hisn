import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/models/dua.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Dua sample({String? virtue}) => Dua(
        id: 'x',
        categoryId: 'morning',
        title: 'Test',
        arabic: 'عربي',
        transliteration: 'translit',
        translation: 'English meaning',
        reference: 'Quran',
        virtue: virtue,
      );

  group('Dua localized overlays', () {
    test('falls back to English when no overlay exists', () {
      final dua = sample();
      expect(dua.translationFor('id'), 'English meaning');
      expect(dua.translationFor('ar'), 'English meaning');
    });

    test('uses the localized meaning when present', () {
      final dua = sample().withLocalized(translations: {'id': 'Makna Indonesia'});
      expect(dua.translationFor('id'), 'Makna Indonesia');
      // Other languages still fall back.
      expect(dua.translationFor('en'), 'English meaning');
      expect(dua.translationFor('ar'), 'English meaning');
    });

    test('localizes the virtue, falling back otherwise', () {
      final dua =
          sample(virtue: 'Reward').withLocalized(virtues: {'id': 'Keutamaan'});
      expect(dua.virtueFor('id'), 'Keutamaan');
      expect(dua.virtueFor('en'), 'Reward');
    });
  });

  test('repository attaches the Indonesian meaning overlay', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final repo = DuaRepository();
    await repo.load();
    expect(repo.duas, isNotEmpty);

    // A known entry should now carry an Indonesian meaning distinct from the
    // English one, while English itself stays untouched.
    final dua = repo.duaById('morning_ayat_kursi')!;
    expect(dua.translationFor('id'), isNot(dua.translation));
    expect(dua.translationFor('id'), contains('Allah'));
    expect(dua.translationFor('en'), dua.translation);

    // Every dua should have a non-empty Indonesian meaning (overlay or
    // fallback), and Arabic text is never overlaid.
    for (final d in repo.duas) {
      expect(d.translationFor('id'), isNotEmpty);
    }
  });
}
