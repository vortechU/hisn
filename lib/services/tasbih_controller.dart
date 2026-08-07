import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dhikr.dart';
import 'adhan_widget_bridge.dart';

/// Holds the live count for each dhikr preset on the Tasbih screen.
///
/// Counts persist between launches so a long session of dhikr isn't lost if the
/// app is closed. `laps` tracks how many full sets (of the dhikr's target) have
/// been completed.
///
/// The home-screen tasbih widget counts into these same keys — it is the same
/// dhikr whichever surface the tap lands on. That makes this store shared
/// rather than owned, which is why [reload] exists: the widget can write while
/// the app is suspended, and the in-memory copy here would otherwise still hold
/// the count from before.
class TasbihController extends ChangeNotifier {
  TasbihController(this._prefs);

  static const _countPrefix = 'tasbih_count_';
  static const _lapPrefix = 'tasbih_laps_';
  static const _selectedKey = 'tasbih_selected';

  final SharedPreferences _prefs;

  int countFor(String dhikrId) => _prefs.getInt('$_countPrefix$dhikrId') ?? 0;

  int lapsFor(String dhikrId) => _prefs.getInt('$_lapPrefix$dhikrId') ?? 0;

  /// The phrase being counted, or null before one has been chosen.
  ///
  /// Persisted rather than held in the screen's state because the widget shows
  /// this phrase too, and because coming back to a counter that had forgotten
  /// which dhikr you were on was a small unkindness.
  String? get selectedId => _prefs.getString(_selectedKey);

  /// Remember [dhikr] as the phrase being counted, and tell the widget.
  Future<void> select(Dhikr dhikr) async {
    if (dhikr.id == selectedId) return;
    await _prefs.setString(_selectedKey, dhikr.id);
    notifyListeners();
    await AdhanWidgetBridge.update(widgetPayload(dhikr));
  }

  /// What the home-screen widget needs to draw [dhikr].
  ///
  /// The count is deliberately absent: the widget reads that straight from the
  /// shared store, because it changes on a tap while the app is closed and a
  /// pushed value would be a set behind.
  static Map<String, String> widgetPayload(Dhikr dhikr) => {
        'tasbih_id': dhikr.id,
        'tasbih_arabic': dhikr.arabic,
        'tasbih_translit': dhikr.transliteration,
        'tasbih_target': dhikr.target.toString(),
      };

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
    // The widget draws from the same keys, so it is now showing a stale count.
    await AdhanWidgetBridge.refresh();
    return completedSet;
  }

  Future<void> reset(String dhikrId) async {
    await _prefs.remove('$_countPrefix$dhikrId');
    await _prefs.remove('$_lapPrefix$dhikrId');
    notifyListeners();
    await AdhanWidgetBridge.refresh();
  }

  /// Re-read the store from disk.
  ///
  /// Called when the app returns to the foreground. Without it, the first tap
  /// after counting on the widget would be computed from the count this object
  /// cached before the widget's taps, and would undo them.
  Future<void> reload() async {
    await _prefs.reload();
    notifyListeners();
  }
}
