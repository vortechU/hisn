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
