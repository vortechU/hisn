import 'package:flutter_test/flutter_test.dart';
import 'dart:ui' show TextDirection;
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

  test('contentDirection follows the first letter typed', () {
    const ltr = TextDirection.ltr, rtl = TextDirection.rtl;
    expect(contentDirection('', ltr), ltr);
    expect(contentDirection('', rtl), rtl);
    expect(contentDirection('123 ', rtl), rtl);
    expect(contentDirection('الحمد لله', ltr), rtl);
    expect(contentDirection('  ٢ الحمد', ltr), rtl);
    expect(contentDirection('اذان', ltr), rtl); // Urdu
    expect(contentDirection('ﷲ', ltr), rtl); // presentation form
    expect(contentDirection('hello الحمد', rtl), ltr);
    expect(contentDirection('Ṣalāh', rtl), ltr);
  });
}
