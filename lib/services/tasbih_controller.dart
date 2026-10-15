import 'dart:async';
import 'dart:convert';

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
  TasbihController(this._prefs) {
    _loadCustomDhikr();
  }

  static const _countPrefix = 'tasbih_count_';
  static const _lapPrefix = 'tasbih_laps_';
  static const _selectedKey = 'tasbih_selected';
  static const _customKey = 'tasbih_custom_phrases';
  static const maxCustomTarget = 1000000;

  final SharedPreferences _prefs;
  List<Dhikr> _customDhikr = [];

  List<Dhikr> get customDhikr => List.unmodifiable(_customDhikr);

  bool isCustom(String id) => _customDhikr.any((d) => d.id == id);

  void _loadCustomDhikr() {
    final raw = _prefs.getString(_customKey);
    if (raw == null) {
      _customDhikr = [];
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final loaded = <Dhikr>[];
      for (final item in decoded) {
        try {
          final dhikr = Dhikr.fromJson(Map<String, dynamic>.from(item as Map));
          if (!dhikr.id.startsWith('custom_dhikr_') ||
              dhikr.arabic.trim().isEmpty ||
              dhikr.transliteration.trim().isEmpty ||
              dhikr.target < 1 ||
              dhikr.target > maxCustomTarget ||
              loaded.any((d) => d.id == dhikr.id)) {
            continue;
          }
          loaded.add(dhikr);
        } catch (_) {
          // A malformed entry must not hide the user's other saved phrases.
        }
      }
      _customDhikr = loaded;
    } catch (_) {
      // Preserve the saved store if a restore has an unreadable value.
    }
  }

  Future<void> _persistCustomDhikr() async {
    await _prefs.setString(
      _customKey,
      jsonEncode(
        _customDhikr
            .map(
              (d) => {
                'id': d.id, 'arabic': d.arabic,
                // A custom phrase's presentation label is the name supplied by its user.
                'transliteration': d.transliteration,
                'translation': d.translation,
                'target': d.target,
              },
            )
            .toList(),
      ),
    );
  }

  Dhikr _customPhrase(String id, String name, String arabic, int target) {
    if (name.trim().isEmpty ||
        arabic.trim().isEmpty ||
        target < 1 ||
        target > maxCustomTarget) {
      throw ArgumentError(
        'A dhikr needs a name, text and target from 1 to $maxCustomTarget.',
      );
    }
    return Dhikr(
      id: id,
      arabic: arabic.trim(),
      transliteration: name.trim(),
      translation: '',
      target: target,
    );
  }

  Future<Dhikr> addCustom({
    required String name,
    required String arabic,
    required int target,
  }) async {
    final dhikr = _customPhrase(
      'custom_dhikr_${DateTime.now().microsecondsSinceEpoch}',
      name,
      arabic,
      target,
    );
    _customDhikr = [..._customDhikr, dhikr];
    await _persistCustomDhikr();
    notifyListeners();
    return dhikr;
  }

  Future<Dhikr> updateCustom({
    required String id,
    required String name,
    required String arabic,
    required int target,
  }) async {
    final index = _customDhikr.indexWhere((d) => d.id == id);
    if (index < 0) throw ArgumentError.value(id, 'id', 'Unknown custom dhikr');
    final dhikr = _customPhrase(id, name, arabic, target);
    _customDhikr = [..._customDhikr]..[index] = dhikr;
    await _persistCustomDhikr();
    notifyListeners();
    // Refresh the selected phrase's native display even when its id stays put.
    if (selectedId == id) await AdhanWidgetBridge.update(widgetPayload(dhikr));
    return dhikr;
  }

  Future<void> removeCustom(String id) async {
    if (!isCustom(id)) return;
    _customDhikr = _customDhikr.where((d) => d.id != id).toList();
    await _persistCustomDhikr();
    await _prefs.remove('$_countPrefix$id');
    await _prefs.remove('$_lapPrefix$id');
    if (selectedId == id) await _prefs.remove(_selectedKey);
    notifyListeners();
  }

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
    if (target < 1) {
      throw ArgumentError.value(target, 'target', 'Must be positive');
    }
    final current = countFor(dhikrId);
    // Keep the completed target visible. The next intentional recitation starts
    // the following set at one, so the user never spends a tap just resetting.
    final next = current >= target ? 1 : current + 1;
    final completedSet = next == target;

    // `shared_preferences` updates its in-memory copy synchronously and only
    // the disk write is asynchronous, so the new count is already readable
    // here. Telling the screen first, and settling the write after, takes a
    // platform round trip out from between the bead and the finger.
    final writes = [
      _prefs.setInt('$_countPrefix$dhikrId', next),
      if (completedSet)
        _prefs.setInt('$_lapPrefix$dhikrId', lapsFor(dhikrId) + 1),
    ];

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
    _loadCustomDhikr();
    notifyListeners();
  }
}
