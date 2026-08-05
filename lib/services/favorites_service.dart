import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which duas the user has bookmarked, persisted across launches.
class FavoritesService extends ChangeNotifier {
  FavoritesService(this._prefs) {
    _ids = _prefs.getStringList(_key)?.toSet() ?? <String>{};
  }

  static const _key = 'favorite_dua_ids';

  final SharedPreferences _prefs;
  late Set<String> _ids;

  Set<String> get ids => Set.unmodifiable(_ids);
  bool get isEmpty => _ids.isEmpty;

  bool isFavorite(String duaId) => _ids.contains(duaId);

  Future<void> toggle(String duaId) async {
    if (!_ids.add(duaId)) {
      _ids.remove(duaId);
    }
    notifyListeners();
    await _prefs.setStringList(_key, _ids.toList());
  }
}
