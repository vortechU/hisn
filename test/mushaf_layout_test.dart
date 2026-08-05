import 'package:dua_app/models/quran.dart';
import 'package:dua_app/screens/mushaf_screen.dart';
import 'package:flutter_test/flutter_test.dart';

/// A synthetic 15-line page.
///
/// The real glyphs need the ~2 MB QCF page fonts, which a widget test does not
/// load; the fallback face measures differently but the rule under test is a
/// proportion, so it holds whatever the glyphs measure. Each page gets its own
/// number because the metrics cache is keyed by it.
MushafPage _page(int number, {int lines = 15, int wordsPerLine = 8}) =>
    MushafPage(
      page: number,
      font: 'QCF4_Hafs_01',
      juz: 1,
      surahs: const [],
      lines: [
        for (var i = 0; i < lines; i++)
          [
            for (var w = 0; w < wordsPerLine; w++)
              MushafWord(code: 0x0620 + ((i * wordsPerLine + w) % 40)),
          ],
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // How wide the widest line is drawn at a given layout — the check that the
  // block is actually justified rather than adrift in the middle of the frame.
  double lineFill(MushafPage page, MushafPageLayout layout) {
    final reference = mushafPageLayoutFor(page, 1000, 1e6);
    // At the reference call the width bound is what binds, so the widest line
    // is drawn at exactly `width` for `fontSize` — giving width-per-unit-font.
    final perFont = reference.width / reference.fontSize;
    return layout.fontSize * perFont;
  }

  group('page fitting', () {
    test('portrait uses the full frame width', () {
      final page = _page(1);
      final layout = mushafPageLayoutFor(page, 360, 700);

      expect(layout.width, 360);
      expect(layout.fontSize, greaterThan(0));
    });

    test('landscape letterboxes instead of stretching', () {
      final page = _page(2);
      final portrait = mushafPageLayoutFor(page, 360, 700);
      final landscape = mushafPageLayoutFor(page, 700, 360);

      // The block does not take the whole width of a wide, short frame...
      expect(landscape.width, lessThan(700));
      // ...and it is not wider than the portrait block was, either.
      expect(landscape.width, lessThan(portrait.width));
    });

    test('lines stay justified in both orientations', () {
      final page = _page(3);

      for (final (w, h) in const [(360.0, 700.0), (700.0, 360.0), (900.0, 400.0)]) {
        final layout = mushafPageLayoutFor(page, w, h);
        // The widest line fills the block it is drawn into. This is what broke
        // in landscape: the text shrank to fit the height and left the width
        // unfilled, so lines no longer reached the frame edges.
        expect(
          lineFill(page, layout),
          closeTo(layout.width, layout.width * 0.02),
          reason: 'widest line should fill the block at ${w}x$h',
        );
      }
    });

    test('the block never exceeds the frame', () {
      final page = _page(4);

      for (final (w, h) in const [
        (360.0, 700.0),
        (700.0, 360.0),
        (320.0, 240.0),
        (1280.0, 800.0),
      ]) {
        final layout = mushafPageLayoutFor(page, w, h);
        expect(layout.width, lessThanOrEqualTo(w));
        // Fifteen lines at this size must still fit the height.
        expect(layout.fontSize * 15, lessThanOrEqualTo(h * 1.001));
      }
    });

    test('a taller frame yields a bigger font, never a smaller one', () {
      final page = _page(5);

      var previous = 0.0;
      for (final h in const [300.0, 500.0, 700.0, 900.0]) {
        final layout = mushafPageLayoutFor(page, 400, h);
        expect(layout.fontSize, greaterThanOrEqualTo(previous));
        previous = layout.fontSize;
      }
    });

    test('fitting is stable, and follows the frame', () {
      // Fitting is pure: the same frame gives the same answer, a different one
      // gives a different answer. (That re-fitting reuses the cached
      // measurement rather than re-running it is an optimisation this cannot
      // observe — it is asserted by the metrics cache being keyed on the page
      // alone.)
      final page = _page(6);
      final first = mushafPageLayoutFor(page, 360, 700);
      final again = mushafPageLayoutFor(page, 360, 700);
      final rotated = mushafPageLayoutFor(page, 700, 360);

      expect(again.width, first.width);
      expect(again.fontSize, first.fontSize);
      expect(rotated.width, isNot(first.width));
    });
  });
}
