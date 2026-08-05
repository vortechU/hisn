/// Surah (chapter) metadata, from `assets/data/quran/surahs.json`.
class Surah {
  const Surah({
    required this.number,
    required this.name,
    required this.translit,
    required this.meaning,
    required this.revelation,
    required this.ayahCount,
    required this.page,
    required this.juz,
  });

  final int number;

  /// Arabic name, e.g. "الفاتحة".
  final String name;

  /// Latin transliteration, e.g. "Al-Faatiha".
  final String translit;

  /// English meaning, e.g. "The Opening".
  final String meaning;

  /// 'meccan' or 'medinan'.
  final String revelation;
  final int ayahCount;
  final int page;
  final int juz;

  bool get isMeccan => revelation == 'meccan';

  factory Surah.fromJson(Map<String, dynamic> json) => Surah(
        number: json['number'] as int,
        name: json['name'] as String,
        translit: json['translit'] as String,
        meaning: json['meaning'] as String,
        revelation: json['revelation'] as String,
        ayahCount: json['ayahCount'] as int,
        page: json['page'] as int,
        juz: json['juz'] as int,
      );
}

/// A single verse within a surah.
class Ayah {
  const Ayah({
    required this.number,
    required this.text,
    required this.juz,
    required this.page,
    this.sajda = false,
  });

  final int number;
  final String text;
  final int juz;
  final int page;

  /// True for the verses of prostration (sajdat at-tilāwah).
  final bool sajda;

  factory Ayah.fromJson(Map<String, dynamic> json) => Ayah(
        number: json['n'] as int,
        text: json['text'] as String,
        juz: json['juz'] as int,
        page: json['page'] as int,
        sajda: json['sajda'] as bool? ?? false,
      );
}

/// One glyph "word" on a mushaf page: a private-use codepoint rendered with a
/// King Fahd Complex (QCF v4) page font.
class MushafWord {
  const MushafWord({required this.code, this.type = 'word', this.font});

  final int code;

  /// 'word', 'end' (ayah rosette), 'surah_header', or 'bismillah'.
  final String type;

  /// Overrides the page font (only the surah header differs, using the BSML
  /// header font). Null means "use the page's default font".
  final String? font;

  String get glyph => String.fromCharCode(code);
  bool get isHeader => type == 'surah_header';
  bool get isBismillah => type == 'bismillah';

  factory MushafWord.fromJson(Map<String, dynamic> j) => MushafWord(
        code: j['c'] as int,
        type: j['t'] as String? ?? 'word',
        font: j['f'] as String?,
      );
}

/// A surah reference on a page (which verses of it appear here).
class MushafSurahRef {
  const MushafSurahRef({required this.id, required this.name});
  final int id;
  final String name;

  factory MushafSurahRef.fromJson(Map<String, dynamic> j) =>
      MushafSurahRef(id: j['id'] as int, name: j['name'] as String);
}

/// A single mushaf page: 15 lines of glyph words, rendered with [font].
class MushafPage {
  const MushafPage({
    required this.page,
    required this.font,
    required this.juz,
    required this.surahs,
    required this.lines,
  });

  final int page;
  final String font;
  final int juz;
  final List<MushafSurahRef> surahs;
  final List<List<MushafWord>> lines;

  factory MushafPage.fromJson(Map<String, dynamic> j) => MushafPage(
        page: j['page'] as int,
        font: j['font'] as String,
        juz: j['juz'] as int? ?? 1,
        surahs: (j['surahs'] as List)
            .map((e) => MushafSurahRef.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        lines: (j['lines'] as List)
            .map((line) => (line['words'] as List)
                .map((w) => MushafWord.fromJson(w as Map<String, dynamic>))
                .toList(growable: false))
            .toList(growable: false),
      );
}

/// A verse together with the surah it belongs to.
///
/// The mushaf pages are glyph runs with no verse identity in them, so anything
/// that needs to name a verse — bookmarking it, showing its meaning — joins the
/// page to the surah files on the page number they both carry.
class PageVerse {
  const PageVerse({required this.surah, required this.ayah});

  final Surah surah;
  final Ayah ayah;

  /// The conventional citation, e.g. `2:255`.
  String get reference => '${surah.number}:${ayah.number}';

  /// The stable key a bookmark is stored under.
  String get key => reference;

  /// Parses a stored bookmark key back into its two numbers, or null if the
  /// key is malformed.
  static (int surah, int ayah)? parseKey(String key) {
    final parts = key.split(':');
    if (parts.length != 2) return null;
    final s = int.tryParse(parts[0]);
    final a = int.tryParse(parts[1]);
    if (s == null || a == null) return null;
    return (s, a);
  }
}

/// A surah with its full list of verses (loaded on demand).
class SurahDetail {
  const SurahDetail({
    required this.number,
    required this.name,
    required this.ayahs,
  });

  final int number;
  final String name;
  final List<Ayah> ayahs;

  factory SurahDetail.fromJson(Map<String, dynamic> json) => SurahDetail(
        number: json['number'] as int,
        name: json['name'] as String,
        ayahs: (json['ayahs'] as List)
            .map((e) => Ayah.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}
