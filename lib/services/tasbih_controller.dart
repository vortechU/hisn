import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the live count for each dhikr preset on the Tasbih screen.
///
/// Counts persist between launches so a long session of dhikr isn't lost if the
/// app is closed. `laps` tracks how many full sets (of the dhikr's target) have
/// been completed.
class TasbihController extends ChangeNotifier {
  TasbihController(this._prefs);

  static const _countPrefix = 'tasbih_count_';
  static const _lapPrefix = 'tasbih_laps_';

  final SharedPreferences _prefs;

  int countFor(String dhikrId) => _prefs.getInt('$_countPrefix$dhikrId') ?? 0;

  int lapsFor(String dhikrId) => _prefs.getInt('$_lapPrefix$dhikrId') ?? 0;

  /// Increments the count for [dhikrId]. Returns `true` when this tap completed
  /// a full set (so the UI can fire stronger haptics / feedback).
  Future<bool> increment(String dhikrId, int target) async {
    final next = countFor(dhikrId) + 1;
    var completedSet = false;

    if (next >= target) {
      completedSet = true;
      await _prefs.setInt('$_countPrefix$dhikrId', 0);
      await _prefs.setInt('$_lapPrefix$dhikrId', lapsFor(dhikrId) + 1);
    } else {
      await _prefs.setInt('$_countPrefix$dhikrId', next);
    }

    notifyListeners();
    return completedSet;
  }

  Future<void> reset(String dhikrId) async {
    await _prefs.remove('$_countPrefix$dhikrId');
    await _prefs.remove('$_lapPrefix$dhikrId');
    notifyListeners();
  }
}
