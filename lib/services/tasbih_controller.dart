import 'dart:async';

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

  Timer? _widgetRefresh;

  /// Ask the home-screen widget to redraw, once the beads have stopped moving.
  ///
  /// A redraw is not free on the native side: it crosses the method channel,
  /// writes the preference store, and broadcasts to every widget provider,
  /// each of which re-renders its Arabic to a bitmap. Counting is a rhythm —
  /// several taps a second, for a hundred repetitions — and doing all of that
  /// per bead put it squarely in the way of the tap it was reporting. The
  /// widget only needs the number the hand came to rest on.
  void _refreshWidgetSoon() {
    _widgetRefresh?.cancel();
    _widgetRefresh = Timer(
      const Duration(milliseconds: 600),
      AdhanWidgetBridge.refresh,
    );
  }

  @override
  void dispose() {
    _widgetRefresh?.cancel();
    super.dispose();
  }

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
    final completedSet = next >= target;

    // `shared_preferences` updates its in-memory copy synchronously and only
    // the disk write is asynchronous, so the new count is already readable
    // here. Telling the screen first, and settling the write after, takes a
    // platform round trip out from between the bead and the finger.
    final writes = completedSet
        ? [
            _prefs.setInt('$_countPrefix$dhikrId', 0),
            _prefs.setInt('$_lapPrefix$dhikrId', lapsFor(dhikrId) + 1),
          ]
        : [_prefs.setInt('$_countPrefix$dhikrId', next)];

    notifyListeners();
    // The widget draws from the same keys, so it is now showing a stale count.
    _refreshWidgetSoon();
    await Future.wait(writes);
    return completedSet;
  }

  Future<void> reset(String dhikrId) async {
    await _prefs.remove('$_countPrefix$dhikrId');
    await _prefs.remove('$_lapPrefix$dhikrId');
    notifyListeners();
    _refreshWidgetSoon();
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
