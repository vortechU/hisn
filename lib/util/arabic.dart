// Helpers for working with Arabic text.

// Harakat (diacritics), Quranic annotation marks, superscript alef, and tatweel.
final RegExp _harakat = RegExp(
  '[ؐ-ًؚ-ٰٟۖ-ۜ'
  '۟-۪ۨ-ۭـ]',
);

// Letter-variant folds for forgiving search (alef hamzas, ta marbuta, etc.).
const Map<String, String> _folds = {
  'أ': 'ا', // أ -> ا
  'إ': 'ا', // إ -> ا
  'آ': 'ا', // آ -> ا
  'ٱ': 'ا', // ٱ -> ا
  'ة': 'ه', // ة -> ه
  'ى': 'ي', // ى -> ي
  'ؤ': 'و', // ؤ -> و
  'ئ': 'ي', // ئ -> ي
};

/// Removes the harakat (tashkeel) from [text], leaving the bare letters.
/// Used for dua titles so they read cleanly and are easy to type/search.
String stripHarakat(String text) => text.replaceAll(_harakat, '');

/// A search-friendly normalisation: strips harakat and folds the common letter
/// variants so a query typed without diacritics still matches.
String normalizeArabic(String text) {
  var t = stripHarakat(text);
  _folds.forEach((from, to) => t = t.replaceAll(from, to));
  return t;
}

// Any letter from the Arabic block. Enough to tell a name written in Arabic
// from one written in Latin letters — which is all the callers need, and why
// this doesn't try to cover every RTL script the app doesn't ship.
final RegExp _arabicLetter = RegExp('[ء-ي]');

/// Whether [text] is written in Arabic script, so it wants Arabic type and a
/// right-to-left line rather than the interface's Latin body face.
bool isArabicScript(String text) => _arabicLetter.hasMatch(text);

const List<String> _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

/// Renders an integer with Arabic-Indic digits (e.g. 255 → "٢٥٥"), as used for
/// ayah numbers in the mushaf.
String toArabicDigits(int n) =>
    n.toString().split('').map((c) {
      final d = int.tryParse(c);
      return d == null ? c : _arabicDigits[d];
    }).join();
