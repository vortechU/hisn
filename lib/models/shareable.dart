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

  /// How many times the dua is repeated. 1 (the default) is not shown.
  final int repeat;

  /// A dua, rendered into the language the interface is currently in.
  factory Shareable.dua(Dua dua, String langCode) => Shareable(
        arabic: dua.arabic,
        reference: dua.reference,
        title: dua.title,
        titleArabic: dua.titleArabic,
        transliteration:
            dua.transliteration.isEmpty ? null : dua.transliteration,
        translation: _orNull(dua.translationFor(langCode)),
        repeat: dua.repeat,
      );

  /// A single verse. Carries no transliteration or translation: the app ships
  /// neither for the Qur'an, and inventing one to fill the card would be the
  /// same mistake as inventing a source.
  factory Shareable.verse(PageVerse verse) => Shareable(
        arabic: verse.ayah.text,
        reference: '${verse.surah.translit} ${verse.reference}',
        title: verse.surah.translit,
        titleArabic: verse.surah.name,
      );

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
    return buffer.toString();
  }
}
