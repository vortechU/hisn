import 'package:flutter_test/flutter_test.dart';
import 'package:dua_app/util/arabic.dart';

void main() {
  test('stripHarakat removes diacritics from a title', () {
    expect(stripHarakat('آيَةُ الْكُرْسِيِّ'), 'آية الكرسي');
    expect(stripHarakat('أَذْكَارُ الصَّبَاحِ'), 'أذكار الصباح');
    expect(stripHarakat('سُبْحَانَ اللَّهِ'), 'سبحان الله');
  });

  test('normalizeArabic folds letter variants for forgiving search', () {
    // A query without hamza/diacritics should normalise to the same form.
    expect(normalizeArabic('آيَةُ الْكُرْسِيِّ'), normalizeArabic('ايه الكرسي'));
    expect(normalizeArabic('أذكار'), normalizeArabic('اذكار'));
  });
}
