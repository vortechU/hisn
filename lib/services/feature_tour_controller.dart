import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FeatureTourTarget {
  tasbih,
  quranSearch,
  prayerQibla,
  appearance,
  notifications,
}

/// The welcome decision is persistent; the guide itself uses live widget keys.
/// Starting or advancing a guide never changes any permission or feature state.
class FeatureTourController extends ChangeNotifier {
  FeatureTourController(this._prefs) : _seen = _prefs.getBool(seenKey) ?? false;

  static const seenKey = 'feature_guide_seen_v1';
  final SharedPreferences _prefs;
  final Map<FeatureTourTarget, GlobalKey> _targets = {};
  bool _seen;
  bool _active = false;
  int _step = 0;

  bool get seen => _seen;
  bool get active => _active;
  int get step => _step;
  static const stepCount = 5;

  GlobalKey keyFor(FeatureTourTarget target) => _targets.putIfAbsent(
    target,
    () => GlobalKey(debugLabel: 'feature-guide-${target.name}'),
  );

  void start() {
    _step = 0;
    _active = true;
    notifyListeners();
  }

  Future<void> next() async {
    if (!_active) return;
    if (_step == stepCount - 1) {
      await finish();
    } else {
      _step++;
      notifyListeners();
    }
  }

  /// Used for both Skip and Done. Replay remains available in Settings.
  Future<void> finish() async {
    _active = false;
    _seen = true;
    notifyListeners();
    await _prefs.setBool(seenKey, true);
  }
}
