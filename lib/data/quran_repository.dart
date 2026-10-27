import 'dart:convert';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../models/quran.dart';
import '../util/arabic.dart';

/// Loads Quran content from the bundled JSON assets. The surah index is small
/// and loaded once up front; each surah's verses are loaded (and cached) on
/// demand the first time it's opened, so startup stays fast.
class QuranRepository {
  QuranRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  List<Surah> _surahs = const [];
  final Map<int, SurahDetail> _cache = {};
  final Map<int, Future<SurahDetail>> _surahLoads = {};
  bool _loaded = false;
  Future<void>? _indexLoad;

  List<Surah> get surahs => _surahs;

  /// The Bismillah in Uthmani script, shown as a header above most surahs.
  static const bismillah = 'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ';

  Future<void> loadIndex() {
    if (_loaded) return Future<void>.value();
    return _indexLoad ??= _readIndex();
  }

  Future<void> _readIndex() async {
    try {
      final raw = await _bundle.loadString('assets/data/quran/surahs.json');
      _surahs = (jsonDecode(raw) as List)
          .map((e) => Surah.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
      await _loadAyahIndex();
      _loaded = true;
    } finally {
      _indexLoad = null;
    }
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

  Future<SurahDetail> loadSurah(int number) =>
      _cachedLoad(number, _cache, _surahLoads, () async {
        final raw = await _bundle.loadString(
          'assets/data/quran/surah_$number.json',
        );
        return SurahDetail.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      });

  // ---- Verse meanings ----
  final Map<String, SurahTranslation> _transCache = {};
  final Map<String, Future<SurahTranslation>> _translationLoads = {};
  List<QuranEdition>? _editions;
  Future<List<QuranEdition>>? _editionLoad;

  /// The meaning editions bundled with the app, one per language — a
  /// translation for English and Indonesian, the Muyassar tafsir for Arabic.
  ///
  /// Generated alongside the verse files, so this is also the authority on
  /// which languages have a meaning at all — rather than a list kept in Dart
  /// that could fall out of step with what actually shipped.
  Future<List<QuranEdition>> loadEditions() {
    final cached = _editions;
    if (cached != null) return Future.value(cached);
    return _editionLoad ??= _readEditions();
  }

  Future<List<QuranEdition>> _readEditions() async {
    try {
      final raw = await _bundle.loadString(
        'assets/data/quran/trans/editions.json',
      );
      return _editions = (jsonDecode(raw) as List)
          .map((e) => QuranEdition.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } finally {
      _editionLoad = null;
    }
  }

  /// The edition for [lang], or null if that language has none.
  Future<QuranEdition?> editionFor(String lang) async {
    for (final e in await loadEditions()) {
      if (e.lang == lang) return e;
    }
    return null;
  }

  /// A surah's meanings in [lang], or null if the language has no edition.
  ///
  /// The absence check runs off [loadEditions] rather than a caught exception,
  /// so an untranslated interface language stays a fast expected answer while
  /// a genuinely missing or malformed file still throws and gets noticed.
  Future<SurahTranslation?> loadTranslation(int surah, String lang) async {
    if (await editionFor(lang) == null) return null;
    final key = '$lang:$surah';
    return _cachedLoad<String, SurahTranslation>(
      key,
      _transCache,
      _translationLoads,
      () async {
        final raw = await _bundle.loadString(
          'assets/data/quran/trans/$lang/surah_$surah.json',
        );
        return SurahTranslation.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      },
    );
  }

  // ---- Madani Mushaf pages (QCF v4) ----
  static const totalPages = 604;
  final Map<int, MushafPage> _pageCache = {};
  final Map<int, Future<MushafPage>> _pageLoads = {};

  /// The page if it's already decoded in memory (visited before or prefetched),
  /// or null. Lets the reader render instantly without a FutureBuilder spinner.
  MushafPage? pageIfCached(int page) => _pageCache[page];

  Future<MushafPage> loadPage(int page) =>
      _cachedLoad(page, _pageCache, _pageLoads, () async {
        final name = page.toString().padLeft(3, '0');
        final raw = await _bundle.loadString('assets/data/mushaf/$name.json');
        return MushafPage.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      });

  // ---- Which verse is which on a page ----
  //
  // The pages carry no verse identity: an āyah rosette is a glyph typed 'end'
  // and nothing more. But the rosettes *are* the verses — 6,236 of them across
  // the 604 pages, in order — so the n-th rosette closes the n-th āyah, and a
  // running total of rosettes before each page is enough to name every verse
  // the page prints. That total is generated by tool/gen_ayah_index.py.
  //
  // This is also the authority on which page a verse is on, in preference to
  // the `page` field the surah files carry on each verse: the two disagree for
  // 56 verses, and where they do, the field is the one that is wrong. It puts
  // the opening of juz 7 (5:83) a page later than the mushaf prints it.

  /// The number of verses closed before each page, plus the total at the end,
  /// so page p's verses are `_versesBefore[p - 1] ..< _versesBefore[p]`.
  List<int> _versesBefore = const [];

  /// The number of verses before each surah, so a verse's place in the mushaf
  /// is `_surahBefore[surah - 1] + ayah - 1`.
  List<int> _surahBefore = const [];

  Future<void> _loadAyahIndex() async {
    final raw = await _bundle.loadString('assets/data/mushaf/ayah_index.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _versesBefore = [
      ...(json['before'] as List).cast<int>(),
      json['total'] as int,
    ];
    final before = <int>[];
    var running = 0;
    for (final surah in _surahs) {
      before.add(running);
      running += surah.ayahCount;
    }
    _surahBefore = before;
  }

  /// The verses printed on [page], as `surah:ayah` keys in reading order.
  ///
  /// Synchronous: it reads the index alone, not the page or the surah files, so
  /// the reader can name the verse under a tap without waiting on a load.
  List<String> ayahKeysOnPage(int page) {
    if (page < 1 || page > totalPages || _versesBefore.isEmpty) return const [];
    return [
      for (var i = _versesBefore[page - 1]; i < _versesBefore[page]; i++)
        ayahKeyAt(i),
    ];
  }

  /// The `surah:ayah` key of the [index]-th verse of the mushaf (0-based).
  String ayahKeyAt(int index) {
    final (surah, ayah) = ayahAt(index);
    return '$surah:$ayah';
  }

  /// The [index]-th verse of the mushaf (0-based), by binary search over the
  /// surah lengths.
  (int surah, int ayah) ayahAt(int index) {
    if (_surahBefore.isEmpty) return (1, 1);
    var low = 0;
    var high = _surahBefore.length - 1;
    while (low < high) {
      final mid = (low + high + 1) ~/ 2;
      if (_surahBefore[mid] <= index) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return (_surahs[low].number, index - _surahBefore[low] + 1);
  }

  /// The mushaf page a verse is printed on, from the index rather than the
  /// surah file's own page field. Returns the surah's first page if the verse
  /// is out of range.
  int pageOfAyah(int surah, int ayah) {
    final meta = surahByNumber(surah);
    if (meta == null || _versesBefore.isEmpty) return 1;
    if (ayah < 1 || ayah > meta.ayahCount) return meta.page;
    final index = _surahBefore[_surahs.indexOf(meta)] + ayah - 1;
    // The first page whose verses run past this one.
    var low = 0;
    var high = totalPages - 1;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (_versesBefore[mid + 1] > index) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }
    return low + 1;
  }

  /// The verses printed on a mushaf page, in reading order, with their text and
  /// (if [lang] is given) their meaning.
  ///
  /// Which verses those are comes from the rosette index; their text comes from
  /// the surah files, one or two of which cover a page and both of which are
  /// cached after the first visit.
  Future<List<PageVerse>> versesOnPage(int page, {String? lang}) async {
    final keys = ayahKeysOnPage(page);
    final edition = lang == null ? null : await editionFor(lang);
    final verses = <PageVerse>[];
    for (final key in keys) {
      final parsed = PageVerse.parseKey(key);
      if (parsed == null) continue;
      final surah = surahByNumber(parsed.$1);
      if (surah == null) continue;
      final detail = await loadSurah(parsed.$1);
      final translation = edition == null
          ? null
          : await loadTranslation(parsed.$1, edition.lang);
      final ayah = _ayahIn(detail, parsed.$2);
      if (ayah == null) continue;
      final meaning = translation?.forAyah(parsed.$2);
      verses.add(
        PageVerse(
          surah: surah,
          ayah: ayah,
          translation: meaning,
          translationCredit: meaning == null ? null : edition!.credit,
          translationKind: meaning == null ? null : edition!.kind,
        ),
      );
    }
    return verses;
  }

  /// A surah's verse by number. Stored positionally, so the position is tried
  /// first and the scan is only a guard against a file that is not.
  Ayah? _ayahIn(SurahDetail detail, int number) {
    if (number >= 1 && number <= detail.ayahs.length) {
      final at = detail.ayahs[number - 1];
      if (at.number == number) return at;
    }
    for (final ayah in detail.ayahs) {
      if (ayah.number == number) return ayah;
    }
    return null;
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
          translationKind: meaning == null ? null : edition!.kind,
        );
      }
    }
    return null;
  }

  /// The mushaf page a given verse sits on.
  ///
  /// Answered from the rosette index, so it agrees with what the page actually
  /// prints — and so a saved verse cannot open a page that does not contain it.
  Future<int> pageForAyah(int surah, int ayah) async => pageOfAyah(surah, ayah);

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
    return _surahs
        .where((s) {
          return s.number == asNumber ||
              s.translit.toLowerCase().contains(q) ||
              s.meaning.toLowerCase().contains(q) ||
              normalizeArabic(s.name).contains(qn);
        })
        .toList(growable: false);
  }

  Future<_VerseSearchIndex>? _verseSearchIndex;

  /// Searches bundled Arabic verse text, ignoring diacritics and letter
  /// variants. The word index is built only on the first Arabic word search,
  /// shared by concurrent searches, and reused for the rest of this session.
  /// Surah-name and short/numeric searches do not load the verse corpus.
  Future<List<PageVerse>> searchVerses(String query, {int limit = 50}) async {
    final normalized = _normalizeVerseSearch(query);
    if (limit <= 0 || normalized.length < 2 || !isArabicScript(normalized)) {
      return const [];
    }
    await loadIndex();
    final index = await (_verseSearchIndex ??= _buildVerseSearchIndex());
    Set<int>? candidates;
    for (final part in normalized.split(' ')) {
      final matching = <int>{};
      for (final entry in index.words.entries) {
        if (entry.key.contains(part)) matching.addAll(entry.value);
      }
      candidates = candidates == null
          ? matching
          : candidates.intersection(matching);
      if (candidates.isEmpty) return const [];
    }
    final ordered = candidates!.toList()..sort();
    final results = <PageVerse>[];
    for (final position in ordered) {
      if (!index.texts[position].contains(normalized)) continue;
      results.add(index.verses[position]);
      if (results.length == limit) break;
    }
    return results;
  }

  Future<_VerseSearchIndex> _buildVerseSearchIndex() async {
    try {
      final documents = <_SearchSurah>[];
      // Read assets here; decoding and normalizing the complete corpus belongs
      // on a worker, not between keyboard/scroll frames on the UI isolate.
      for (var start = 0; start < _surahs.length; start += 8) {
        final group = _surahs.skip(start).take(8).toList();
        documents.addAll(
          await Future.wait(
            group.map((surah) async {
              final cached =
                  _cache[surah.number] ?? await _surahLoads[surah.number];
              return (
                surah: surah,
                cached: cached,
                raw: cached == null
                    ? await _bundle.loadString(
                        'assets/data/quran/surah_${surah.number}.json',
                      )
                    : null,
              );
            }),
          ),
        );
      }
      final index = await compute(
        _indexVerseDocuments,
        documents,
        debugLabel: 'Quran word index',
      );
      for (final entry in index.surahs.entries) {
        _cache.putIfAbsent(entry.key, () => entry.value);
      }
      return index;
    } catch (_) {
      _verseSearchIndex =
          null; // A later retry can recover an asset-read error.
      rethrow;
    }
  }
}

typedef _SearchSurah = ({Surah surah, SurahDetail? cached, String? raw});

_VerseSearchIndex _indexVerseDocuments(List<_SearchSurah> documents) {
  final verses = <PageVerse>[];
  final texts = <String>[];
  final words = <String, List<int>>{};
  final surahs = <int, SurahDetail>{};
  for (final document in documents) {
    final detail =
        document.cached ??
        SurahDetail.fromJson(jsonDecode(document.raw!) as Map<String, dynamic>);
    surahs[document.surah.number] = detail;
    for (final ayah in detail.ayahs) {
      final position = verses.length;
      final text = _normalizeVerseSearch(ayah.text);
      verses.add(PageVerse(surah: document.surah, ayah: ayah));
      texts.add(text);
      for (final word in text.split(' ').toSet()) {
        (words[word] ??= []).add(position);
      }
    }
  }
  return _VerseSearchIndex(verses, texts, words, surahs);
}

/// Share pending work as well as its result. Failed reads are removed so a
/// later request can retry instead of retaining a rejected future forever.
Future<T> _cachedLoad<K, T extends Object>(
  K key,
  Map<K, T> cache,
  Map<K, Future<T>> pending,
  Future<T> Function() read,
) {
  final cached = cache[key];
  if (cached != null) return Future.value(cached);
  return pending.putIfAbsent(key, () async {
    try {
      return cache[key] = await read();
    } finally {
      pending.remove(key);
    }
  });
}

String _normalizeVerseSearch(String text) =>
    normalizeArabic(text).replaceAll(RegExp(r'\s+'), ' ').trim();

class _VerseSearchIndex {
  const _VerseSearchIndex(this.verses, this.texts, this.words, this.surahs);
  final List<PageVerse> verses;
  final List<String> texts;
  final Map<String, List<int>> words;
  final Map<int, SurahDetail> surahs;
}
