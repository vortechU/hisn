import 'package:dua_app/data/quran_repository.dart';
import 'package:dua_app/models/quran.dart';
import 'package:dua_app/models/shareable.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/services/display_settings.dart';
import 'package:dua_app/services/quran_service.dart';
import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:dua_app/theme/arabic_fonts.dart';
import 'package:dua_app/util/arabic.dart';
import 'package:dua_app/widgets/verse_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The verse meanings — translations for English and Indonesian, the Muyassar
/// tafsir for Arabic — and the join that attaches them to the mushaf.
///
/// The join is the risky part. An edition that is off by one verse would put
/// every meaning on its neighbour, and nothing on screen would look wrong —
/// the Arabic would be right, the citation would be right, and only someone
/// who reads both languages would ever notice. So the alignment is asserted
/// here against the app's own surah index rather than trusted.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuranRepository repo;

  setUpAll(() async {
    repo = QuranRepository();
    await repo.loadIndex();
  });

  group('bundled editions', () {
    test('every interface language names its edition and translator', () async {
      final editions = await repo.loadEditions();

      expect(editions, isNotEmpty);
      expect(editions.map((e) => e.lang).toSet(), {'en', 'id', 'ar'});
      for (final e in editions) {
        expect(e.name, isNotEmpty, reason: e.lang);
        expect(e.translator, isNotEmpty, reason: e.lang);
        // The short form is what a share card can fit; without it a verse
        // would leave the app with its meaning but not its translator.
        expect(e.credit, isNotEmpty, reason: e.lang);
        expect(e.source, isNotEmpty, reason: e.lang);
      }
    });

    test('Arabic gets a tafsir where the others get a translation', () async {
      // Rendering Arabic into Arabic would say nothing, so the Arabic
      // interface is given the verse explained instead of restated. The kind
      // is what tells the app to set it in Arabic type rather than Latin.
      final arabic = await repo.editionFor('ar');

      expect(arabic, isNotNull);
      expect(arabic!.id, 'ar.muyassar');
      expect(arabic.kind, QuranEditionKind.tafsir);
      expect(isArabicScript(arabic.credit), isTrue);

      for (final lang in const ['en', 'id']) {
        expect((await repo.editionFor(lang))!.kind,
            QuranEditionKind.translation, reason: lang);
      }
    });

    test('an unknown language is absent rather than an error', () async {
      expect(await repo.editionFor('fr'), isNull);
      expect(await repo.loadTranslation(1, 'fr'), isNull);
    });
  });

  group('the join to the surah index', () {
    test('every surah has exactly as many meanings as it has verses',
        () async {
      // The guard against a truncated or reordered regeneration. Checked for
      // all 114 surahs in every language, because a gap anywhere shifts every
      // verse after it.
      for (final lang in const ['en', 'id', 'ar']) {
        for (final surah in repo.surahs) {
          final translation = await repo.loadTranslation(surah.number, lang);
          expect(translation, isNotNull,
              reason: '$lang surah ${surah.number}');
          expect(translation!.ayahs, hasLength(surah.ayahCount),
              reason: '$lang surah ${surah.number}');
          expect(translation.lang, lang);
          expect(translation.number, surah.number);
        }
      }
    });

    test('no meaning is blank, and none carries control characters', () async {
      // Control characters are how the upstream damage showed up; if a future
      // regeneration reintroduces any, it surfaces here rather than on screen.
      final control = RegExp(r'[\x00-\x08\x0b-\x1f\x7f-\x9f]');
      for (final lang in const ['en', 'id', 'ar']) {
        for (final surah in repo.surahs) {
          final t = (await repo.loadTranslation(surah.number, lang))!;
          for (var i = 0; i < t.ayahs.length; i++) {
            final text = t.ayahs[i];
            expect(text.trim(), isNotEmpty,
                reason: '$lang ${surah.number}:${i + 1}');
            expect(control.hasMatch(text), isFalse,
                reason: '$lang ${surah.number}:${i + 1} has a control char');
          }
        }
      }
    });

    test('well-known verses read as themselves', () async {
      // Counting verses proves the shape is right, not that the content sits
      // under the citation it belongs to. A whole edition shifted by one would
      // still have the right length everywhere — these are the anchors that
      // would not survive it.
      const anchors = <(String, int, int, String)>[
        ('en', 1, 1, 'In the Name of Allah'),
        ('en', 2, 255, 'Ever Living'), // Ayat al-Kursi
        ('en', 36, 1, 'Ya-Sin'),
        ('en', 18, 10, 'Cave'),
        ('en', 114, 1, 'mankind'),
        ('id', 1, 1, 'Dengan menyebut nama Allah'),
        ('id', 112, 1, 'Maha Esa'),
        ('ar', 2, 255, 'لا تأخذه سِنَة'), // Ayat al-Kursi, explained
        ('ar', 18, 10, 'الكهف'),
        ('ar', 114, 1, 'أعوذ وأعتصم برب الناس'),
      ];

      for (final (lang, surah, ayah, fragment) in anchors) {
        final text = (await repo.loadTranslation(surah, lang))!.forAyah(ayah);
        expect(text, contains(fragment), reason: '$lang $surah:$ayah');
      }
    });

    test('no word in the tafsir is split by a stray space', () async {
      // The same defect the verse text carried, and the Muyassar had one of
      // its own at 9:39 ("إذ ا" for "إذا"). Arabic has no one-letter word
      // spelled with a bare alef, so a token that reduces to one is a word
      // that has come apart — invisible to every other check here, and plain
      // to anyone reading it.
      // Hamza through ghain, fa through ya, and the alef wasla. Written as
      // escapes because the class has to include the hamza carriers (أ إ ؤ ئ)
      // that the tafsir uses and the Quran text does not — leaving them out
      // reduces a real word like "أى" to a bare alef maqsura.
      final notALetter = RegExp(r'[^ء-غف-يٱ]');
      final split = <String>[];
      for (final surah in repo.surahs) {
        final t = (await repo.loadTranslation(surah.number, 'ar'))!;
        for (var i = 0; i < t.ayahs.length; i++) {
          for (final token in t.ayahs[i].split(' ')) {
            final bare = token.replaceAll(notALetter, '');
            if (bare == 'ا' || bare == 'ى') {
              split.add('${surah.number}:${i + 1}');
            }
          }
        }
      }

      expect(split, isEmpty,
          reason: '${split.length} split word(s), first at ${split.take(3)}');
    });

    test('the tafsir explains the verse rather than repeating it', () async {
      // The failure this rules out is bundling the Quran text itself as the
      // Arabic "meaning": both are Arabic, so nothing else here would notice.
      // Checked across a whole surah, not a lucky verse.
      final tafsir = (await repo.loadTranslation(36, 'ar'))!;
      final detail = await repo.loadSurah(36);

      for (final ayah in detail.ayahs) {
        final meaning = tafsir.forAyah(ayah.number)!;
        expect(normalizeArabic(meaning), isNot(normalizeArabic(ayah.text)),
            reason: '36:${ayah.number} repeats the verse');
      }
    });

    test('verse numbers are 1-based and bounded', () async {
      final fatiha = (await repo.loadTranslation(1, 'en'))!;

      expect(fatiha.forAyah(1), isNotNull);
      expect(fatiha.forAyah(7), isNotNull);
      expect(fatiha.forAyah(0), isNull);
      expect(fatiha.forAyah(8), isNull);
    });
  });

  group('the repaired verses', () {
    // The upstream text arrived with three kinds of encoding damage. These pin
    // each repair to a verse that carried it, so a regeneration that loses the
    // repair fails here instead of shipping.
    test('a soft hyphen reads as a hyphen, not as nothing', () async {
      // Was "Oft<U+00AD>Pardoning", which most text engines render as
      // "OftPardoning" — the soft hyphen is invisible unless it breaks a line.
      final text = (await repo.loadTranslation(4, 'en'))!.forAyah(149)!;

      expect(text, contains('Oft-Pardoning'));
      expect(text, contains('All-Powerful'));
    });

    test('a mis-decoded byte reads as the closing quote it was', () async {
      // Was a raw U+0094 — the Windows-1252 position for a closing curly
      // quote, left undecoded upstream.
      final text = (await repo.loadTranslation(12, 'en'))!.forAyah(50)!;

      expect(text, contains('"'));
      expect(text, isNot(contains('\u0094')));
    });

    test('a NEXT LINE control reads as a single space', () async {
      // Was "an evil,<U+0085>verily" — padded with a space on each side, so
      // replacing it naively leaves a visible three-space gap.
      for (final (surah, ayah) in const [
        (2, 140),
        (3, 21),
        (3, 94),
        (4, 149),
        (9, 24),
        (9, 80),
      ]) {
        final text = (await repo.loadTranslation(surah, 'en'))!.forAyah(ayah)!;
        expect(text, isNot(contains('\u0085')), reason: '$surah:$ayah');
        expect(RegExp(r'  +').hasMatch(text), isFalse,
            reason: '$surah:$ayah has a run of spaces');
      }
    });
  });

  group('meanings on a page', () {
    test('are attached when a language is asked for', () async {
      final verses = await repo.versesOnPage(604, lang: 'en');

      expect(verses, isNotEmpty);
      for (final v in verses) {
        expect(v.translation, isNotNull, reason: v.reference);
        expect(v.translationCredit, isNotEmpty, reason: v.reference);
      }
      // Al-Ikhlas 112:1.
      final ikhlas = verses.firstWhere((v) => v.reference == '112:1');
      expect(ikhlas.translation, contains('Say'));
    });

    test('are absent when none is asked for', () async {
      final verses = await repo.versesOnPage(604);

      expect(verses, isNotEmpty);
      expect(verses.every((v) => v.translation == null), isTrue);
      expect(verses.every((v) => v.translationCredit == null), isTrue);
    });

    test('Arabic gets the tafsir, marked as one', () async {
      final verses = await repo.versesOnPage(1, lang: 'ar');

      expect(verses, hasLength(7));
      for (final v in verses) {
        expect(v.translation, isNotNull, reason: v.reference);
        expect(v.translationCredit, isNotEmpty, reason: v.reference);
        // The flag the reader and the share card set their type from — an
        // unmarked tafsir would come out in the Latin body face, left-to-right.
        expect(v.translationKind, QuranEditionKind.tafsir,
            reason: v.reference);
        expect(v.translationIsArabic, isTrue, reason: v.reference);
      }
    });

    test('each verse gets its own meaning, not its neighbour\'s', () async {
      // Page 604 holds three whole surahs, so a one-verse drift anywhere would
      // land a meaning under the wrong citation. Compared against the surah
      // files read directly, which is the join this all rests on.
      final verses = await repo.versesOnPage(604, lang: 'id');

      for (final v in verses) {
        final direct = (await repo.loadTranslation(v.surah.number, 'id'))!
            .forAyah(v.ayah.number);
        expect(v.translation, direct, reason: v.reference);
      }
    });

    test('a two-surah page keeps each surah on its own edition text',
        () async {
      // Page 106 spans An-Nisa and Al-Ma'idah — two translation files, joined
      // in one pass.
      final verses = await repo.versesOnPage(106, lang: 'en');

      expect(verses.map((v) => v.surah.number).toSet(), {4, 5});
      for (final v in verses) {
        final direct = (await repo.loadTranslation(v.surah.number, 'en'))!
            .forAyah(v.ayah.number);
        expect(v.translation, direct, reason: v.reference);
      }
    });
  });

  group('a single verse', () {
    test('carries its meaning and its translator', () async {
      final verse = await repo.verse(2, 255, lang: 'en');

      expect(verse, isNotNull);
      expect(verse!.reference, '2:255');
      expect(verse.translation, isNotNull);
      expect(verse.translationCredit, isNotEmpty);
    });

    test('drops both outside a language the app has an edition for', () async {
      final verse = await repo.verse(2, 255, lang: 'fr');

      expect(verse, isNotNull);
      expect(verse!.translation, isNull);
      expect(verse.translationCredit, isNull);
      expect(verse.translationKind, isNull);
    });

    test('is still null outside the Quran, language or not', () async {
      expect(await repo.verse(115, 1, lang: 'en'), isNull);
      expect(await repo.verse(1, 99, lang: 'en'), isNull);
    });
  });

  group('sharing a verse', () {
    test('sends the meaning and says who rendered it', () async {
      final verse = (await repo.verse(112, 1, lang: 'en'))!;
      final shareable = Shareable.verse(verse, 'en');

      expect(shareable.translation, isNotNull);
      expect(shareable.translationCredit, isNotEmpty);
      // Both must reach the plain-text form too — that is what gets pasted
      // into a chat, where there is no card to read the credit off.
      final text = shareable.asText();
      expect(text, contains(shareable.translation!));
      expect(text, contains(shareable.translationCredit!));
    });

    test('never invents a transliteration', () async {
      // The app ships none for the Qur'an, and a card padded with one would be
      // the same mistake as inventing a source.
      final verse = (await repo.verse(112, 1, lang: 'en'))!;

      expect(Shareable.verse(verse, 'en').transliteration, isNull);
    });

    test('an Arabic share carries the tafsir, marked as Arabic', () async {
      final verse = (await repo.verse(112, 1, lang: 'ar'))!;
      final shareable = Shareable.verse(verse, 'ar');

      expect(shareable.arabic, isNotEmpty);
      expect(shareable.translation, verse.translation);
      expect(shareable.translationCredit, isNotEmpty);
      // Without the flag the card would set Arabic prose in the Latin body
      // face and lay it out left-to-right.
      expect(shareable.translationIsArabic, isTrue);
      expect(shareable.asText(), contains(shareable.translation!));
    });

    test('a translated share is not marked as Arabic', () async {
      final verse = (await repo.verse(112, 1, lang: 'en'))!;

      expect(Shareable.verse(verse, 'en').translationIsArabic, isFalse);
    });

    test('a credit is never sent without the meaning it belongs to', () async {
      // The pairing that must not come apart: a translator named under no
      // translation is worse than no credit at all.
      for (final lang in const ['en', 'id', 'ar']) {
        final verse = (await repo.verse(18, 10, lang: lang))!;
        final shareable = Shareable.verse(verse, lang);
        if (shareable.translationCredit != null) {
          expect(shareable.translation, isNotNull, reason: lang);
        }
      }
    });
  });

  group('the meaning on screen', () {
    // The data tests prove the text is correct; these prove it actually
    // reaches the widget. A FutureBuilder that never resolved would satisfy
    // every assertion above and still show the user nothing.
    Future<void> pumpRow(
      WidgetTester tester,
      PageVerse verse, {
      bool showTranslation = true,
      AppLang lang = AppLang.en,
    }) async {
      SharedPreferences.setMockInitialValues({
        'display_show_translation': showTranslation,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(MultiProvider(
        providers: [
          Provider<QuranRepository>.value(value: repo),
          ChangeNotifierProvider(create: (_) => QuranService(prefs)),
          ChangeNotifierProvider(create: (_) => DisplaySettings(prefs)),
          ChangeNotifierProvider(
              create: (_) => LocaleController(prefs)..setLang(lang)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppPalettes.emerald,
              arabicUi: lang == AppLang.ar),
          home: Scaffold(body: VerseRow(verse: verse)),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('is rendered under the verse', (tester) async {
      final verse = (await repo.verse(112, 1, lang: 'en'))!;

      await pumpRow(tester, verse);

      expect(find.text(verse.translation!), findsOneWidget);
    });

    testWidgets('is withheld when the reader has turned meanings off',
        (tester) async {
      final verse = (await repo.verse(112, 1, lang: 'en'))!;

      await pumpRow(tester, verse, showTranslation: false);

      expect(find.text(verse.translation!), findsNothing);
      // The verse itself stays — the preference hides the rendering, not the
      // thing being rendered.
      expect(find.text(verse.ayah.text), findsOneWidget);
    });

    testWidgets('an Arabic interface shows the tafsir under the verse',
        (tester) async {
      final verse = (await repo.verse(112, 1, lang: 'ar'))!;

      await pumpRow(tester, verse, lang: AppLang.ar);

      expect(find.text(verse.ayah.text), findsOneWidget);
      expect(find.text(verse.translation!), findsOneWidget);
    });

    testWidgets('the tafsir is set in Arabic type, right-to-left',
        (tester) async {
      // Set in the Latin body face it would render in whatever the system
      // happened to fall back to — and read left-to-right, which for Arabic
      // puts the sentence back to front.
      final verse = (await repo.verse(112, 1, lang: 'ar'))!;

      await pumpRow(tester, verse, lang: AppLang.ar);

      final text = tester.widget<Text>(find.text(verse.translation!));
      expect(text.style?.fontFamily, ArabicFonts.fallback.family);
      expect(
        Directionality.of(tester.element(find.text(verse.translation!))),
        TextDirection.rtl,
      );
    });
  });
}
