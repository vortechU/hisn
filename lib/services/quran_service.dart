import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the mushaf reader's bookmarks and last-read position, by page.
class QuranService extends ChangeNotifier {
  QuranService(this._prefs) {
    _bookmarks = (_prefs.getStringList(_kBookmarks) ?? const [])
        .map(int.parse)
        .toSet();
    _lastPage = _prefs.getInt(_kLastPage);
  }

  final SharedPreferences _prefs;

  static const _kBookmarks = 'quran_bookmark_pages';
  static const _kLastPage = 'quran_last_page';

  Set<int> _bookmarks = {};
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
}
