import 'package:dua_app/data/quran_repository.dart';
import 'package:dua_app/models/quran.dart';
import 'package:dua_app/services/quran_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuranRepository repo;

  setUpAll(() async {
    repo = QuranRepository();
    await repo.loadIndex();
  });

  // Damage that no count and no schema would catch: the text keeps the right
  // length and the right shape, and only a reader of Arabic sees that a word
  // has come apart. The bundled text arrived with 2,418 of these — a space
  // between a tanween and the silent alef after it — plus a fragment of the
  // Bismillah welded to the front of Al-Qadr. See tool/repair_quran_text.py.
  group('the text is whole', () {
    // The base letters: hamza through ghain, fa through ya, and the alef
    // wasla. Everything else — harakat, pause marks, the sajda sign —
    // decorates a word rather than being part of one.
    final notALetter = RegExp(r'[^ء-غف-يٱ]');

    test('no word is split before its silent alef', () async {
      // Arabic has no one-letter word spelled with a bare alef or alef
      // maqsura, so a token that reduces to one is the tail of the word in
      // front of it, stranded by a space — and rendered detached, because
      // shaping joins letters only within a word.
      final split = <String>[];
      for (final surah in repo.surahs) {
        final detail = await repo.loadSurah(surah.number);
        for (final ayah in detail.ayahs) {
          for (final token in ayah.text.split(' ')) {
            final bare = token.replaceAll(notALetter, '');
            if (bare == 'ا' || bare == 'ى') {
              split.add('${surah.number}:${ayah.number}');
            }
          }
        }
      }

      expect(split, isEmpty,
          reason: '${split.length} split word(s), first at ${split.take(3)}');
    });

    test('the words that carried the split read whole', () async {
      // Pinned by their joined spelling, so a regeneration that loses the
      // repair fails here rather than shipping.
      for (final (surah, ayah, word) in const [
        (4, 8, 'مَّعۡرُوفࣰا'),
        (4, 9, 'قَوۡلࣰا'),
        (2, 2, 'هُدࣰى'),
      ]) {
        final verse = await repo.verse(surah, ayah);
        expect(verse!.ayah.text, contains(word), reason: '$surah:$ayah');
      }
    });

    test('Al-Qadr opens on its own first word', () async {
      // 97:1 began with the tail of the Bismillah welded to it — the verse
      // opened on "ٱلرَّحِيمِ" run into its real first word. The Bismillah is
      // drawn as a header above the surah; it is not part of a verse.
      //
      // Asserted on the letters rather than by matching a literal: this text
      // writes a hamza as a carrier plus a combining mark, so a precomposed
      // "إ" typed here would not equal the one in the data.
      final verse = await repo.verse(97, 1);
      final words = verse!.ayah.text.split(' ');

      expect(words, hasLength(5));
      // إنا — alef, nun, alef. With the remnant it read الرحيمانا.
      expect(words.first.replaceAll(notALetter, ''), 'انا');
    });
  });

  group('verses on a page', () {
    test('page 1 is the whole of Al-Fatiha', () async {
      final verses = await repo.versesOnPage(1);

      expect(verses, hasLength(7));
      expect(verses.first.reference, '1:1');
      expect(verses.last.reference, '1:7');
      expect(verses.every((v) => v.surah.number == 1), isTrue);
    });

    test('a page spanning two surahs returns both, in reading order',
        () async {
      // Page 106 is where An-Nisa ends and Al-Ma'idah begins.
      final verses = await repo.versesOnPage(106);

      final surahs = verses.map((v) => v.surah.number).toSet();
      expect(surahs, {4, 5});

      // An-Nisa's verses all precede Al-Ma'idah's, and each run ascends.
      final numbers = verses.map((v) => (v.surah.number, v.ayah.number));
      var previous = (0, 0);
      for (final n in numbers) {
        expect(
          n.$1 > previous.$1 || (n.$1 == previous.$1 && n.$2 > previous.$2),
          isTrue,
          reason: 'out of order at $n after $previous',
        );
        previous = n;
      }
    });

    test('the last page holds the three closing surahs', () async {
      final verses = await repo.versesOnPage(604);

      expect(verses.map((v) => v.surah.number).toSet(), {112, 113, 114});
      expect(verses.last.reference, '114:6');
    });

    test('a page lists what it prints, not what the surah file claims',
        () async {
      // The list comes from the rosettes on the page, not from the `page` field
      // each verse carries in the surah files: the two disagree for 56 verses,
      // and there the field is wrong (see test/mushaf_ayah_test.dart). Pages 1
      // and 300 are ones they agree on; page 123 is not.
      for (final page in const [1, 50, 123, 255, 300, 604]) {
        final verses = await repo.versesOnPage(page);
        expect(verses, isNotEmpty, reason: 'page $page');
        expect(verses.map((v) => v.reference).toList(),
            repo.ayahKeysOnPage(page),
            reason: 'page $page');
      }
    });

    test('agrees with the page lookup used by go-to-verse', () async {
      // The two directions must not disagree, or a bookmark would open a page
      // that does not contain its verse.
      for (final (surah, ayah) in const [(2, 255), (18, 10), (36, 1), (1, 1)]) {
        final page = await repo.pageForAyah(surah, ayah);
        final verses = await repo.versesOnPage(page);
        expect(
          verses.any((v) => v.surah.number == surah && v.ayah.number == ayah),
          isTrue,
          reason: '$surah:$ayah should be on page $page',
        );
      }
    });
  });

  group('surah naming', () {
    test('an Arabic interface never falls back to the Latin name', () {
      // The bug this pins: the surah register showed "Al-Baqara" in Arabic,
      // because `translit` was the only name any screen asked for.
      for (final surah in repo.surahs) {
        final arabic = surah.nameFor(true);
        expect(arabic, surah.name, reason: 'surah ${surah.number}');
        expect(arabic, isNot(surah.translit), reason: 'surah ${surah.number}');
        // No Latin letters anywhere in what an Arabic reader is shown.
        expect(arabic, isNot(matches(RegExp('[A-Za-z]'))),
            reason: 'surah ${surah.number}');
      }
    });

    test('every other language keeps the transliteration', () {
      final baqara = repo.surahByNumber(2)!;
      expect(baqara.nameFor(false), 'Al-Baqara');
    });
  });

  group('single verse lookup', () {
    test('finds a verse by surah and number', () async {
      final verse = await repo.verse(2, 255);

      expect(verse, isNotNull);
      expect(verse!.reference, '2:255');
      expect(verse.surah.translit, 'Al-Baqara');
      expect(verse.ayah.text, isNotEmpty);
    });

    test('returns null outside the Quran', () async {
      expect(await repo.verse(115, 1), isNull);
      expect(await repo.verse(1, 99), isNull);
    });
  });

  group('verse keys', () {
    test('round trip through the stored form', () {
      final parsed = PageVerse.parseKey('2:255');
      expect(parsed, isNotNull);
      expect(parsed!.$1, 2);
      expect(parsed.$2, 255);
    });

    test('rejects anything that is not two numbers', () {
      for (final bad in const ['', '2', '2:', ':255', 'a:b', '2:255:1']) {
        expect(PageVerse.parseKey(bad), isNull, reason: bad);
      }
    });
  });

  group('saved verses', () {
    Future<QuranService> serviceWith(Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues(values);
      return QuranService(await SharedPreferences.getInstance());
    }

    test('toggles on and off, and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = QuranService(prefs);

      expect(service.isVerseBookmarked('2:255'), isFalse);
      service.toggleVerseBookmark('2:255');
      expect(service.isVerseBookmarked('2:255'), isTrue);
      expect(service.verseBookmarkCount, 1);
      expect(prefs.getStringList('quran_bookmark_ayahs'), ['2:255']);

      service.toggleVerseBookmark('2:255');
      expect(service.isVerseBookmarked('2:255'), isFalse);
      expect(prefs.getStringList('quran_bookmark_ayahs'), isEmpty);
    });

    test('lists in mushaf order, not insertion or lexical order', () async {
      final service = await serviceWith({
        'quran_bookmark_ayahs': <String>['2:255', '114:1', '2:30', '18:10'],
      });

      // Lexically '114:1' would sort before '18:10' and '2:30'; by surah and
      // verse it comes last.
      expect(service.bookmarkedVerses, ['2:30', '2:255', '18:10', '114:1']);
    });

    test('page and verse marks are kept apart', () async {
      final service = await serviceWith({
        'quran_bookmark_pages': <String>['42'],
        'quran_bookmark_ayahs': <String>['2:255'],
      });

      expect(service.bookmarkedPages, [42]);
      expect(service.bookmarkedVerses, ['2:255']);
      expect(service.bookmarkCount, 1);
      expect(service.verseBookmarkCount, 1);

      // Toggling one leaves the other alone.
      service.toggleVerseBookmark('2:255');
      expect(service.bookmarkedPages, [42]);
      expect(service.bookmarkedVerses, isEmpty);
    });

    test('a malformed stored key does not break the ordering', () async {
      final service = await serviceWith({
        'quran_bookmark_ayahs': <String>['2:255', 'rubbish', '1:1'],
      });

      expect(service.bookmarkedVerses, hasLength(3));
      expect(service.bookmarkedVerses, contains('rubbish'));
    });
  });
}
