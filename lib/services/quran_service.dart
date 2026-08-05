import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quran.dart';

/// Persists the mushaf reader's bookmarks and last-read position.
///
/// Two kinds of bookmark, because they answer different questions. A **page**
/// bookmark is "I was reading here" — what the reader's own bookmark button
/// sets. A **verse** bookmark is "this āyah matters to me", chosen from the
/// verses on a page. Keeping them apart means the reading marks a user
/// accumulates over a khatmah never bury the handful of verses they meant to
/// keep.
class QuranService extends ChangeNotifier {
  QuranService(this._prefs) {
    _bookmarks = (_prefs.getStringList(_kBookmarks) ?? const [])
        .map(int.parse)
        .toSet();
    _verses = (_prefs.getStringList(_kVerses) ?? const []).toSet();
    _lastPage = _prefs.getInt(_kLastPage);
  }

  final SharedPreferences _prefs;

  static const _kBookmarks = 'quran_bookmark_pages';
  static const _kVerses = 'quran_bookmark_ayahs';
  static const _kLastPage = 'quran_last_page';

  Set<int> _bookmarks = {};
  Set<String> _verses = {};
  int? _lastPage;

  // ---- last read ----
  int? get lastPage => _lastPage;
  bool get hasLastRead => _lastPage != null;

  void setLastPage(int page) {
    if (_lastPage == page) return;
    _lastPage = page;
    _prefs.setInt(_kLastPage, page);
    notifyListeners();
  }

  // ---- bookmarks ----
  bool isBookmarked(int page) => _bookmarks.contains(page);
  int get bookmarkCount => _bookmarks.length;

  List<int> get bookmarkedPages => _bookmarks.toList()..sort();

  void toggleBookmark(int page) {
    if (!_bookmarks.add(page)) _bookmarks.remove(page);
    _prefs.setStringList(
        _kBookmarks, _bookmarks.map((p) => p.toString()).toList());
    notifyListeners();
  }

  // ---- bookmarked verses ----

  /// Bookmarked verses as `surah:ayah` keys, in mushaf order.
  List<String> get bookmarkedVerses {
    final keys = _verses.toList();
    keys.sort((a, b) {
      final left = PageVerse.parseKey(a);
      final right = PageVerse.parseKey(b);
      if (left == null || right == null) return a.compareTo(b);
      return left.$1 == right.$1
          ? left.$2.compareTo(right.$2)
          : left.$1.compareTo(right.$1);
    });
    return keys;
  }

  int get verseBookmarkCount => _verses.length;

  bool isVerseBookmarked(String key) => _verses.contains(key);

  void toggleVerseBookmark(String key) {
    if (!_verses.add(key)) _verses.remove(key);
    _prefs.setStringList(_kVerses, _verses.toList());
    notifyListeners();
  }
}
