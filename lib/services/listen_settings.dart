import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'muhassan_service.dart';

/// How the hands-free recitation behaves: the pause between repetitions,
/// whether the long dhikr are recited, and whether the screen stays on.
class ListenSettings extends ChangeNotifier {
  ListenSettings(this._prefs) {
    _gapSteps = _prefs.getInt(_kGap) ?? 1;
    _includeAppendix = _prefs.getBool(_kAppendix) ?? false;
    _keepScreenOn = _prefs.getBool(_kScreenOn) ?? false;
  }

  final SharedPreferences _prefs;

  static const _kGap = 'listen_gap_steps';
  static const _kAppendix = 'listen_include_appendix';
  static const _kScreenOn = 'listen_keep_screen_on';

  /// Selectable pause lengths, in seconds. Zero runs the recitation straight
  /// through; three leaves room to say it along with the reciter.
  static const List<int> gapChoices = [0, 1, 2, 3];

  int _gapSteps = 1;
  bool _includeAppendix = false;
  bool _keepScreenOn = false;

  /// Seconds of silence between one repetition and the next.
  int get gapSteps => _gapSteps;

  /// Whether the 100× tahlīl and tasbīḥ are recited at the end of the set.
  ///
  /// Off by default: said aloud a hundred times they run to about a quarter of
  /// an hour each, and [MuhassanService.highRepeatThreshold] already leaves
  /// them out of the streak. Offered rather than imposed.
  bool get includeAppendix => _includeAppendix;

  /// Whether to hold the screen awake while reciting.
  ///
  /// Off by default — the point of the feature is the screen being off. It
  /// exists for following along on a propped-up phone while your hands are
  /// busy.
  bool get keepScreenOn => _keepScreenOn;

  Future<void> setGapSteps(int value) async {
    if (value == _gapSteps) return;
    _gapSteps = value;
    await _prefs.setInt(_kGap, value);
    notifyListeners();
  }

  Future<void> setIncludeAppendix(bool value) async {
    if (value == _includeAppendix) return;
    _includeAppendix = value;
    await _prefs.setBool(_kAppendix, value);
    notifyListeners();
  }

  Future<void> setKeepScreenOn(bool value) async {
    if (value == _keepScreenOn) return;
    _keepScreenOn = value;
    await _prefs.setBool(_kScreenOn, value);
    notifyListeners();
  }
}
