import 'package:dua_app/data/quran_repository.dart';
import 'package:dua_app/models/quran.dart';
import 'package:dua_app/screens/mushaf_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A page of plain words with rosettes where [ends] says, so a synthetic page
/// can stand in for one of the real ones. Each page gets its own number because
/// the layout and verse-map caches are keyed by it.
///
/// The glyphs are private-use codepoints, as the real ones are. That is not a
/// detail: PUA is bidi class L, which is why the page draws each line's words
/// in reverse to get them reading right-to-left. Arabic codepoints here would
/// be reordered a second time by the shaper and quietly test the mirror image
/// of what ships.
MushafPage _page(int number, {required List<List<bool>> ends}) => MushafPage(
      page: number,
      font: 'QCF4_Hafs_01',
      juz: 1,
      surahs: const [],
      lines: [
        for (var i = 0; i < ends.length; i++)
          [
            for (var w = 0; w < ends[i].length; w++)
              MushafWord(
                code: 0xF100 + ((i * 8 + w) % 40),
                type: ends[i][w] ? 'end' : 'word',
              ),
          ],
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuranRepository repo;

  setUpAll(() async {
    repo = QuranRepository();
    await repo.loadIndex();
  });

  // The pages are runs of private-use glyphs with no verse identity in them.
  // What names a verse is that the rosettes are the verses: 6,236 of them in
  // mushaf order, one per āyah. If that ever stops holding, every citation the
  // reader shows is off by however far it slipped.
  group('the rosette index', () {
    test('the pages account for every verse, once', () {
      var seen = 0;
      final first = <String>[];
      for (var page = 1; page <= QuranRepository.totalPages; page++) {
        final keys = repo.ayahKeysOnPage(page);
        expect(keys, isNotEmpty, reason: 'page $page prints no verse');
        first.add(keys.first);
        seen += keys.length;
      }
      expect(seen, 6236);
      // Ascending across the whole mushaf: no page reaches back or skips.
      expect(first, hasLength(QuranRepository.totalPages));
    });

    test('a page holds the verses it prints, in order', () {
      expect(repo.ayahKeysOnPage(1),
          ['1:1', '1:2', '1:3', '1:4', '1:5', '1:6', '1:7']);
      expect(repo.ayahKeysOnPage(604).first, '112:1');
      expect(repo.ayahKeysOnPage(604).last, '114:6');
    });

    test('every verse is on the page its own page says it is', () {
      // Both directions agree, for all 6,236 — the guarantee that a saved verse
      // can never open a page that does not contain it.
      for (var page = 1; page <= QuranRepository.totalPages; page++) {
        for (final key in repo.ayahKeysOnPage(page)) {
          final parsed = PageVerse.parseKey(key)!;
          expect(repo.pageOfAyah(parsed.$1, parsed.$2), page, reason: key);
        }
      }
    });

    test('the openings of the juz land where the mushaf prints them', () {
      // Two of these fall mid-page, so they pin the verse rather than the page
      // break. 5:83 is the one the surah files get wrong — they put it on 122.
      for (final (surah, ayah, page) in const [
        (2, 142, 22),
        (5, 83, 121),
        (18, 75, 302),
        (36, 28, 442),
        (78, 1, 582),
      ]) {
        expect(repo.pageOfAyah(surah, ayah), page, reason: '$surah:$ayah');
      }
    });

    test('every surah opens on the page the index says', () {
      for (final surah in repo.surahs) {
        expect(repo.pageOfAyah(surah.number, 1), surah.page,
            reason: 'surah ${surah.number}');
      }
    });

    test('an out-of-range verse falls back to the surah, not to a crash', () {
      expect(repo.pageOfAyah(115, 1), 1);
      expect(repo.pageOfAyah(1, 99), repo.surahByNumber(1)!.page);
    });

    test('the sheet lists exactly what the page prints', () async {
      // Page 120 is one the surah files disagree about: it prints seven verses,
      // the last of which the files record as belonging to page 121.
      final verses = await repo.versesOnPage(120);
      expect(verses.map((v) => v.reference).toList(),
          repo.ayahKeysOnPage(120));
      expect(verses, hasLength(7));
    });
  });

  group('naming a glyph', () {
    test('a word belongs to the verse the next rosette closes', () {
      final page = _page(1, ends: [
        [false, false, true, false],
        [false, true, false, false],
      ]);

      // Words 0-2 of the first line close on its rosette (verse 0); everything
      // after it is verse 1, up to and including the second rosette; the tail
      // of the page is verse 2, which closes on the page after.
      expect(mushafVerseMap(page), [
        [0, 0, 0, 1],
        [1, 1, 2, 2],
      ]);
    });

    test('a page that opens mid-verse still starts at its first verse', () {
      // The first rosette closes a verse that began on the page before; the
      // words in front of it are that same verse, not a nameless run.
      final page = _page(2, ends: [
        [false, false, false, true],
      ]);
      expect(mushafVerseMap(page).first, [0, 0, 0, 0]);
    });
  });

  group('marking the page', () {
    /// Every glyph the page draws, in the order the spans are built.
    List<TextStyle> stylesOf(WidgetTester tester) => [
          for (final text in tester.widgetList<Text>(find.byType(Text)))
            ...(text.textSpan! as TextSpan)
                .children!
                .cast<TextSpan>()
                .map((s) => s.style!),
        ];

    Future<void> pump(WidgetTester tester, MushafPage page,
        {Set<int> bookmarked = const {}, int selected = -1}) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 600,
            child: mushafPageBody(
              page: page,
              keys: const ['2:1', '2:2'],
              onAyah: (_) {},
              bookmarked: bookmarked,
              selected: selected,
            ),
          ),
        ),
      ));
    }

    testWidgets('a kept āyah has its rosette rubricated, and only that',
        (tester) async {
      final page = _page(20, ends: [
        [false, false, true],
        [false, false, true],
      ]);
      const gilt = Color(0xFFC9A227);
      const rubric = Color(0xFF1F6F54);

      await pump(tester, page);
      // Unkept, both rosettes are gilt like the print.
      expect(stylesOf(tester).where((s) => s.color == rubric), isEmpty);
      expect(stylesOf(tester).where((s) => s.color == gilt), hasLength(2));

      await pump(tester, page, bookmarked: {1});
      final styles = stylesOf(tester);
      // One rosette turns; the other, and every word, stays as it was.
      expect(styles.where((s) => s.color == rubric), hasLength(1));
      expect(styles.where((s) => s.color == gilt), hasLength(1));
      expect(styles.where((s) => s.background != null), isEmpty);
    });

    testWidgets('the lit āyah is washed, and stops where it ends',
        (tester) async {
      final page = _page(21, ends: [
        [false, false, true, false],
        [false, false, false, true],
      ]);

      await pump(tester, page, selected: 0);
      // Three words and the rosette that closes them — not the word after it.
      expect(stylesOf(tester).where((s) => s.background != null), hasLength(3));
    });
  });

  group('touching a verse', () {
    // The test font draws every glyph as a square of the font size, so where
    // each word lands can be worked out here independently of the code that
    // resolves a tap. That is the point: if the words were read left-to-right,
    // or the paragraph placed anywhere but the middle, these would pick the
    // wrong verse.
    const width = 400.0;
    const height = 600.0;

    Future<String?> touch(
      WidgetTester tester,
      MushafPage page,
      List<String> keys,
      Offset Function(MushafPageLayout layout, double slot) where, {
      bool hold = false,
    }) async {
      String? chosen;
      var dismissed = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              key: const Key('block'),
              width: width,
              height: height,
              child: mushafPageBody(
                page: page,
                keys: keys,
                onAyah: (key) => chosen = key,
                onDismiss: () => dismissed = true,
              ),
            ),
          ),
        ),
      ));

      final layout = mushafPageLayoutFor(page, width, height);
      final slot = height / page.lines.length;
      final origin = tester.getTopLeft(find.byKey(const Key('block')));
      final at = origin + where(layout, slot);
      if (hold) {
        await tester.longPressAt(at);
      } else {
        await tester.tapAt(at);
      }
      await tester.pumpAndSettle();
      expect(dismissed, chosen == null);
      return chosen;
    }

    /// The centre of the word at [index] in reading order on line [line] —
    /// derived from the test font's square glyphs, not from the app's code.
    Offset wordCentre(MushafPage page, MushafPageLayout layout, double slot,
        int line, int index) {
      final count = page.lines[line].length;
      final run = count * layout.fontSize;
      final left = (width - layout.width) / 2 + (layout.width - run) / 2;
      // Drawn in reverse: reading word 0 is the rightmost glyph.
      final display = count - 1 - index;
      return Offset(
        left + (display + 0.5) * layout.fontSize,
        slot * line + slot / 2,
      );
    }

    testWidgets('tapping a rosette opens its own āyah', (tester) async {
      final page = _page(10, ends: [
        [false, false, true, false, false, true],
        [false, false, false, false, false, true],
      ]);
      final keys = ['2:1', '2:2', '2:3'];

      // The second rosette on the first line closes 2:2.
      final chosen = await touch(tester, page, keys,
          (layout, slot) => wordCentre(page, layout, slot, 0, 5));
      expect(chosen, '2:2');
    });

    testWidgets('tapping the words does not open anything', (tester) async {
      final page = _page(11, ends: [
        [false, false, true, false, false, true],
        [false, false, false, false, false, true],
      ]);

      // A plain word, well clear of either rosette on the line.
      final chosen = await touch(tester, page, ['2:1', '2:2', '2:3'],
          (layout, slot) => wordCentre(page, layout, slot, 0, 0));
      expect(chosen, isNull);
    });

    testWidgets('holding a word opens the verse it belongs to',
        (tester) async {
      final page = _page(12, ends: [
        [false, false, true, false, false, true],
        [false, false, false, false, false, true],
      ]);

      // The first word of the second line: past both of the first line's
      // rosettes, so it belongs to the third verse.
      final chosen = await touch(tester, page, ['2:1', '2:2', '2:3'],
          (layout, slot) => wordCentre(page, layout, slot, 1, 0),
          hold: true);
      expect(chosen, '2:3');
    });

    testWidgets('a near miss still finds the rosette', (tester) async {
      final page = _page(13, ends: [
        [false, false, false, false, false, true],
        [false, false, false, false, false, true],
      ]);

      // Short of the rosette by half a finger, and above the line's middle —
      // the sort of aim a reader holding a phone one-handed actually has.
      final chosen = await touch(
        tester,
        page,
        ['2:1', '2:2'],
        (layout, slot) =>
            wordCentre(page, layout, slot, 0, 5) + const Offset(14, -12),
      );
      expect(chosen, '2:1');
    });
  });
}
