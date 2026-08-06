import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/quran.dart';
import '../util/arabic.dart';

/// Loads Quran content from the bundled JSON assets. The surah index is small
/// and loaded once up front; each surah's verses are loaded (and cached) on
/// demand the first time it's opened, so startup stays fast.
class QuranRepository {
  List<Surah> _surahs = const [];
  final Map<int, SurahDetail> _cache = {};
  bool _loaded = false;

  List<Surah> get surahs => _surahs;

  /// The Bismillah in Uthmani script, shown as a header above most surahs.
  static const bismillah = 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ';

  Future<void> loadIndex() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/quran/surahs.json');
    _surahs = (jsonDecode(raw) as List)
        .map((e) => Surah.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    _loaded = true;
  }

  Surah? surahByNumber(int number) {
    for (final s in _surahs) {
      if (s.number == number) return s;
    }
    return null;
  }

  /// The surah that a given mushaf page belongs to (the last surah whose start
  /// page is at or before [page]). Surahs are ordered by number = by page.
  Surah surahForPage(int page) {
    var result = _surahs.first;
    for (final s in _surahs) {
      if (s.page <= page) {
        result = s;
      } else {
        break;
      }
    }
    return result;
  }

  Future<SurahDetail> loadSurah(int number) async {
    final cached = _cache[number];
    if (cached != null) return cached;
    final raw =
        await rootBundle.loadString('assets/data/quran/surah_$number.json');
    final detail =
        SurahDetail.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _cache[number] = detail;
    return detail;
  }

  // ---- Verse meanings ----
  final Map<String, SurahTranslation> _transCache = {};
  List<QuranEdition>? _editions;

  /// The translations bundled with the app, one per language.
  ///
  /// Generated alongside the verse files, so this is also the authority on
  /// which languages have a translation at all — rather than a list kept in
  /// Dart that could fall out of step with what actually shipped.
  Future<List<QuranEdition>> loadEditions() async {
    final cached = _editions;
    if (cached != null) return cached;
    final raw =
        await rootBundle.loadString('assets/data/quran/trans/editions.json');
    final editions = (jsonDecode(raw) as List)
        .map((e) => QuranEdition.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    _editions = editions;
    return editions;
  }

  /// The edition for [lang], or null if that language has none.
  Future<QuranEdition?> editionFor(String lang) async {
    for (final e in await loadEditions()) {
      if (e.lang == lang) return e;
    }
    return null;
  }

  /// A surah's verses in [lang], or null if the language has no edition.
  ///
  /// The absence check runs off [loadEditions] rather than a caught exception,
  /// so "Arabic has no translation" stays a fast expected answer while a
  /// genuinely missing or malformed file still throws and gets noticed.
  Future<SurahTranslation?> loadTranslation(int surah, String lang) async {
    if (await editionFor(lang) == null) return null;
    final key = '$lang:$surah';
    final cached = _transCache[key];
    if (cached != null) return cached;
    final raw = await rootBundle
        .loadString('assets/data/quran/trans/$lang/surah_$surah.json');
    final translation =
        SurahTranslation.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _transCache[key] = translation;
    return translation;
  }

  // ---- Madani Mushaf pages (QCF v4) ----
  static const totalPages = 604;
  final Map<int, MushafPage> _pageCache = {};

  /// The page if it's already decoded in memory (visited before or prefetched),
  /// or null. Lets the reader render instantly without a FutureBuilder spinner.
  MushafPage? pageIfCached(int page) => _pageCache[page];

  Future<MushafPage> loadPage(int page) async {
    final cached = _pageCache[page];
    if (cached != null) return cached;
    final name = page.toString().padLeft(3, '0');
    final raw = await rootBundle.loadString('assets/data/mushaf/$name.json');
    final mushaf = MushafPage.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _pageCache[page] = mushaf;
    return mushaf;
  }

  /// The verses printed on a mushaf page, in reading order.
  ///
  /// The glyph pages carry no verse identity — they are runs of private-use
  /// codepoints — so the verses are recovered from the surah files, which
  /// record the page each verse falls on. The page's own surah list says which
  /// files to consult, keeping this to one or two loads (both cached) rather
  /// than a scan of all 114.
  /// Pass [lang] to carry each verse's meaning along; omit it for the Arabic
  /// interface, or anywhere the meaning isn't going to be shown.
  Future<List<PageVerse>> versesOnPage(int page, {String? lang}) async {
    final mushaf = await loadPage(page);
    final numbers = mushaf.surahs.isNotEmpty
        ? mushaf.surahs.map((s) => s.id).toSet().toList()
        : [surahForPage(page).number];
    numbers.sort();

    final edition = lang == null ? null : await editionFor(lang);
    final verses = <PageVerse>[];
    for (final number in numbers) {
      final surah = surahByNumber(number);
      if (surah == null) continue;
      final detail = await loadSurah(number);
      // One translation file per surah, alongside the one surah file — so a
      // page still costs the same one or two loads it always did.
      final translation =
          edition == null ? null : await loadTranslation(number, edition.lang);
      for (final ayah in detail.ayahs) {
        if (ayah.page == page) {
          final meaning = translation?.forAyah(ayah.number);
          verses.add(PageVerse(
            surah: surah,
            ayah: ayah,
            translation: meaning,
            translationCredit: meaning == null ? null : edition!.credit,
          ));
        }
      }
    }
    return verses;
  }

  /// One verse by surah and number, or null if either is out of range.
  Future<PageVerse?> verse(int surah, int ayah, {String? lang}) async {
    final meta = surahByNumber(surah);
    if (meta == null) return null;
    final detail = await loadSurah(surah);
    for (final a in detail.ayahs) {
      if (a.number == ayah) {
        final edition = lang == null ? null : await editionFor(lang);
        final translation = edition == null
            ? null
            : await loadTranslation(surah, edition.lang);
        final meaning = translation?.forAyah(ayah);
        return PageVerse(
          surah: meta,
          ayah: a,
          translation: meaning,
          translationCredit: meaning == null ? null : edition!.credit,
        );
      }
    }
    return null;
  }

  /// The mushaf page a given verse sits on. Loads the surah on demand and
  /// looks the verse up by number; falls back to the surah's first page.
  Future<int> pageForAyah(int surah, int ayah) async {
    final detail = await loadSurah(surah);
    for (final a in detail.ayahs) {
      if (a.number == ayah) return a.page;
    }
    return surahByNumber(surah)?.page ?? 1;
  }

  /// Whether a surah shows the Bismillah header. All surahs do except
  /// At-Tawbah (9), and Al-Fatiha (1) where it is verse 1.
  static bool showsBismillah(int number) => number != 1 && number != 9;

  /// Search surahs by number, Arabic name (harakat-insensitive), Latin
  /// transliteration, or English meaning.
  List<Surah> searchSurahs(String query) {
    final raw = query.trim();
    if (raw.isEmpty) return _surahs;
    final q = raw.toLowerCase();
    final qn = normalizeArabic(raw);
    final asNumber = int.tryParse(raw);
    return _surahs.where((s) {
      return s.number == asNumber ||
          s.translit.toLowerCase().contains(q) ||
          s.meaning.toLowerCase().contains(q) ||
          normalizeArabic(s.name).contains(qn);
    }).toList(growable: false);
  }
}
