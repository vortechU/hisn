import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists per-dua repetition counts for the current day, so a partially
/// completed remembrance set survives leaving the screen (and reopening the
/// app). It resets at the calendar-day boundary — the same rollover the streak
/// / muhassan system uses — so "today's progress" stays in sync with the streak.
class DuaProgressService extends ChangeNotifier {
  DuaProgressService(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;

  static const _kDay = 'dua_progress_day';
  static const _kCounts = 'dua_progress_counts';

  String _day = '';
  Map<String, int> _counts = {};

  /// How many times [duaId] has been counted today.
  int countOf(String duaId) {
    _rolloverIfNeeded();
    return _counts[duaId] ?? 0;
  }

  /// Set today's count for [duaId] (0 clears it).
  void setCount(String duaId, int count) {
    _rolloverIfNeeded();
    if (count <= 0) {
      _counts.remove(duaId);
    } else {
      _counts[duaId] = count;
    }
    _persist();
    notifyListeners();
  }

  /// Clear today's counts for a set of duas (used by the "reset" action).
  void resetDuas(Iterable<String> duaIds) {
    _rolloverIfNeeded();
    var changed = false;
    for (final id in duaIds) {
      if (_counts.remove(id) != null) changed = true;
    }
    if (changed) {
      _persist();
      notifyListeners();
    }
  }

  // ---- internals ----
  String _todayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  void _load() {
    _day = _prefs.getString(_kDay) ?? '';
    final raw = _prefs.getString(_kCounts);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _counts = map.map((k, v) => MapEntry(k, (v as num).toInt()));
      } catch (_) {
        _counts = {};
      }
    }
    _rolloverIfNeeded();
  }

  /// On a new calendar day, wipe the counts so each day starts fresh.
  void _rolloverIfNeeded() {
    final today = _todayKey();
    if (_day == today) return;
    _day = today;
    _counts = {};
    _prefs
      ..setString(_kDay, today)
      ..remove(_kCounts);
  }

  void _persist() {
    _prefs
      ..setString(_kDay, _day)
      ..setString(_kCounts, jsonEncode(_counts));
  }
}
