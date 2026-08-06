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

    test('localizes the source, falling back otherwise', () {
      final dua = sample().withLocalized(references: {'ar': 'صحيح البخاري'});
      expect(dua.referenceFor('ar'), 'صحيح البخاري');
      expect(dua.referenceFor('en'), 'Quran');
      expect(dua.referenceFor('id'), 'Quran');
    });

    test('overlaying one field leaves the others alone', () {
      // The overlays are filled in a field at a time — Indonesian ships
      // meanings but no sources, Arabic sources but no meanings.
      final dua = sample(virtue: 'Reward')
          .withLocalized(references: {'ar': 'صحيح البخاري'});
      expect(dua.translationFor('ar'), 'English meaning');
      expect(dua.virtueFor('ar'), 'Reward');
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

  test('the Arabic overlay covers every source and every virtue', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final repo = DuaRepository();
    await repo.load();
    expect(repo.duas, isNotEmpty);

    final latin = RegExp('[A-Za-z]');
    for (final d in repo.duas) {
      // A source left in transliteration is the gap this overlay closes: it
      // is the one line of Latin an Arabic card would otherwise still carry.
      expect(d.referenceFor('ar'), isNot(matches(latin)),
          reason: '${d.id} has an untranslated source');
      expect(d.referenceFor('ar'), isNot(d.reference), reason: d.id);

      // A dua with a virtue must have it in Arabic too — the card shows the
      // note whatever the language, so a gap here shows as English prose.
      if (d.virtue != null) {
        expect(d.virtueFor('ar'), isNot(matches(latin)),
            reason: '${d.id} has an untranslated virtue');
        expect(d.virtueFor('ar'), isNot(d.virtue), reason: d.id);
      } else {
        expect(d.virtueFor('ar'), isNull, reason: '${d.id} gained a virtue');
      }
    }

    // English is untouched by any of it.
    final kursi = repo.duaById('morning_ayat_kursi')!;
    expect(kursi.referenceFor('en'), kursi.reference);
    expect(kursi.virtueFor('en'), kursi.virtue);
    // Arabic ships no meaning: the card drops that line rather than rendering
    // the Arabic back into Arabic, so the fallback is the right value here.
    expect(kursi.translationFor('ar'), kursi.translation);
  });
}
