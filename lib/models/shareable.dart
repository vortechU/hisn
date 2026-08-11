import '../models/dua.dart';
import '../models/quran.dart';

/// A passage the app is willing to send out of itself — a dua, or a verse.
///
/// Duas and verses are different things inside the app and want different
/// screens, but the moment either leaves for a chat window they are the same
/// shape: a heading, a line of Arabic, its rendering, and the source it came
/// from. Flattening them here means the card and the share text are written
/// once, and a third kind of passage later gets both for free.
class Shareable {
  const Shareable({
    required this.arabic,
    required this.reference,
    this.title,
    this.titleArabic,
    this.transliteration,
    this.translation,
    this.translationCredit,
    this.translationIsArabic = false,
    this.repeat = 1,
  });

  /// The Arabic text. The one field that is never optional — without it there
  /// is nothing worth sending.
  final String arabic;

  /// Where the text comes from: a hadith collection, or a surah and verse.
  ///
  /// Required, and deliberately so. The app's whole claim is that what it
  /// shows is traceable; a passage that leaves without its source is exactly
  /// the thing it exists to avoid producing.
  final String reference;

  final String? title;
  final String? titleArabic;
  final String? transliteration;
  final String? translation;

  /// Who rendered [translation], when it came from a named edition rather than
  /// from the app's own content. A translation is a source like any other, so
  /// it does not leave the app without the person who made it.
  final String? translationCredit;

  /// Whether [translation] is Arabic prose — the tafsir the Arabic interface
  /// carries — so the card sets it in Arabic type, right-to-left, instead of
  /// the Latin body face.
  final bool translationIsArabic;

  /// How many times the dua is repeated. 1 (the default) is not shown.
  final int repeat;

  /// A dua, rendered into the language the interface is currently in.
  ///
  /// In Arabic both rendering lines are dropped. A transliteration spells the
  /// Arabic out in Latin letters and the translation carries its meaning —
  /// neither says anything to a reader who has the Arabic itself right above
  /// them, and the app ships no Arabic translation to put there instead.
  factory Shareable.dua(Dua dua, String langCode) {
    final arabicUi = langCode == _arabicCode;
    return Shareable(
      arabic: dua.arabic,
      reference: dua.referenceFor(langCode),
      title: dua.title,
      titleArabic: dua.titleArabic,
      transliteration:
          arabicUi ? null : _orNull(dua.transliteration),
      translation: arabicUi ? null : _orNull(dua.translationFor(langCode)),
      repeat: dua.repeat,
    );
  }

  /// A single verse, with its meaning when the interface language has a
  /// bundled edition.
  ///
  /// Never a transliteration: the app ships none for the Qur'an, and inventing
  /// one to fill the card would be the same mistake as inventing a source. The
  /// meaning travels whatever language it is in — in Arabic that is the
  /// Muyassar tafsir, which says something the verse above it does not, unlike
  /// a translation of Arabic into Arabic.
  factory Shareable.verse(PageVerse verse, String langCode) {
    final arabicUi = langCode == _arabicCode;
    final name = verse.surah.nameFor(arabicUi);
    final translation = _orNull(verse.translation);
    return Shareable(
      arabic: verse.ayah.text,
      reference: '$name ${verse.reference}',
      title: name,
      titleArabic: verse.surah.name,
      translation: translation,
      translationCredit:
          translation == null ? null : _orNull(verse.translationCredit),
      translationIsArabic: translation != null && verse.translationIsArabic,
    );
  }

  /// The language code the Arabic interface runs under (see `AppLang.ar`).
  static const String _arabicCode = 'ar';

  static String? _orNull(String? value) =>
      (value == null || value.trim().isEmpty) ? null : value;

  /// The plain-text form, for sharing somewhere an image doesn't belong and
  /// for the clipboard.
  ///
  /// Ordered the way the card is, and ending in the source — so a passage
  /// pasted into a chat still says where it came from.
  String asText() {
    final buffer = StringBuffer(arabic);
    if (transliteration != null) buffer.write('\n\n$transliteration');
    if (translation != null) buffer.write('\n\n$translation');
    buffer.write('\n\n— $reference');
    if (translationCredit != null) {
      buffer.write('\n($translationCredit)');
    }
    return buffer.toString();
  }
}
