import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks the daily "muhassan" (مُحَصَّن — *fortified*) habit: completing the
/// morning and evening adhkar each day, and the resulting streak.
///
/// A day is **fortified** once both the morning *and* evening sets are finished.
/// Each fortified day extends the streak; a missed day breaks it. Per-day
/// progress is the set of completed dua ids for each session, reset at the day
/// boundary. Everything persists in [SharedPreferences].
class MuhassanService extends ChangeNotifier {
  MuhassanService(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;

  /// Category ids that count toward the daily fortress.
  static const morningId = 'morning';
  static const eveningId = 'evening';

  /// Duas repeated this many times or more (the long 100× tahlīl/tasbīḥ) are
  /// optional for the daily streak — completing everything else fortifies the
  /// day. Keeps the streak forgiving, matching the reminder logic.
  static const highRepeatThreshold = 100;

  static const _kDay = 'muhassan_day';
  static const _kMorning = 'muhassan_morning';
  static const _kEvening = 'muhassan_evening';
  static const _kStreak = 'muhassan_streak';
  static const _kBest = 'muhassan_best';
  static const _kLast = 'muhassan_last'; // last fully-fortified day
  static const _kHistory = 'muhassan_history'; // all fortified day keys
  static const _kTotal = 'muhassan_total'; // lifetime fortified-day count

  /// How many recent fortified days to keep for the calendar/history.
  static const _historyCap = 400;

  // The "essential" dua ids for each set — everything except the long 100×
  // dhikr. Supplied once at startup from the repository; only these count
  // toward the streak and the daily meter.
  Set<String> _morningEssential = {};
  Set<String> _eveningEssential = {};

  String _day = '';
  Set<String> _morningDone = {};
  Set<String> _eveningDone = {};
  int _streak = 0;
  int _best = 0;
  String _last = '';
  Set<String> _fortifiedDays = {};
  int _total = 0;

  // ---- public state ----
  int get streak => _streak;
  int get best => _best;

  /// Lifetime number of fully-fortified days.
  int get totalFortified => _total;

  /// Whether a given calendar day was fully fortified.
  bool wasFortified(DateTime day) => _fortifiedDays.contains(_todayKey(day));

  int get morningTotal => _morningEssential.length;
  int get eveningTotal => _eveningEssential.length;
  // Only essential duas count; any completed 100× dhikr are recorded but
  // filtered out here so they neither help nor block the streak/meter.
  int get morningCount => _morningDone
      .where(_morningEssential.contains)
      .length
      .clamp(0, morningTotal);
  int get eveningCount => _eveningDone
      .where(_eveningEssential.contains)
      .length
      .clamp(0, eveningTotal);

  bool get morningDone => morningTotal > 0 && morningCount >= morningTotal;
  bool get eveningDone => eveningTotal > 0 && eveningCount >= eveningTotal;

  /// Today's fortification, 0.0–1.0: morning is worth half, evening half.
  double get fraction {
    final m = morningTotal == 0 ? 0.0 : morningCount / morningTotal;
    final e = eveningTotal == 0 ? 0.0 : eveningCount / eveningTotal;
    return (m * 0.5 + e * 0.5).clamp(0.0, 1.0);
  }

  int get percent => (fraction * 100).round();

  /// Whether today already counts as fully fortified.
  bool get fortifiedToday => _last == _todayKey();

  /// True when there is no active streak (nothing done and none carried over) —
  /// the UI shows a gentle frown to nudge the user back.
  bool get isBroken => _streak == 0;

  /// Supply the essential dua ids for each set (called once at startup from the
  /// repository). The 100× dhikr are excluded so the streak stays forgiving.
  void setEssential(Set<String> morning, Set<String> evening) {
    _morningEssential = morning;
    _eveningEssential = evening;
    notifyListeners();
  }

  /// Record that [duaId] in [categoryId] was completed today. Idempotent.
  void markCompleted(String categoryId, String duaId) {
    if (categoryId != morningId && categoryId != eveningId) return;
    _rolloverIfNeeded();

    final set = categoryId == morningId ? _morningDone : _eveningDone;
    if (!set.add(duaId)) return; // already counted today

    _persistProgress();
    _maybeFortify();
    notifyListeners();
  }

  // ---- internals ----
  String _todayKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  void _load() {
    _day = _prefs.getString(_kDay) ?? '';
    _morningDone = _decode(_prefs.getString(_kMorning));
    _eveningDone = _decode(_prefs.getString(_kEvening));
    _streak = _prefs.getInt(_kStreak) ?? 0;
    _best = _prefs.getInt(_kBest) ?? 0;
    _last = _prefs.getString(_kLast) ?? '';
    _fortifiedDays = _decode(_prefs.getString(_kHistory));
    _total = _prefs.getInt(_kTotal) ?? 0;
    _rolloverIfNeeded();
  }

  Set<String> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      return (jsonDecode(raw) as List).map((e) => e as String).toSet();
    } catch (_) {
      return {};
    }
  }

  /// On a new calendar day: clear today's progress and, if the last fortified
  /// day is older than yesterday, the streak is considered broken (reset to 0).
  void _rolloverIfNeeded() {
    final today = _todayKey();
    if (_day == today) return;

    final yesterday = _todayKey(DateTime.now().subtract(const Duration(days: 1)));
    if (_last != today && _last != yesterday) {
      _streak = 0; // a day was missed
    }

    _day = today;
    _morningDone = {};
    _eveningDone = {};
    _prefs
      ..setString(_kDay, today)
      ..remove(_kMorning)
      ..remove(_kEvening)
      ..setInt(_kStreak, _streak);
  }

  /// If today just became fully fortified, extend (or start) the streak.
  void _maybeFortify() {
    final today = _todayKey();
    if (_last == today) return; // already credited today
    if (!(morningDone && eveningDone)) return; // not complete yet

    final yesterday = _todayKey(DateTime.now().subtract(const Duration(days: 1)));
    _streak = (_last == yesterday) ? _streak + 1 : 1;
    _last = today;
    if (_streak > _best) _best = _streak;

    if (_fortifiedDays.add(today)) {
      _total += 1;
      _trimHistory();
    }

    _prefs
      ..setString(_kLast, today)
      ..setInt(_kStreak, _streak)
      ..setInt(_kBest, _best)
      ..setInt(_kTotal, _total)
      ..setString(_kHistory, jsonEncode(_fortifiedDays.toList()));
  }

  /// Keep the history bounded to the most recent [_historyCap] days.
  void _trimHistory() {
    if (_fortifiedDays.length <= _historyCap) return;
    final sorted = _fortifiedDays.toList()..sort();
    _fortifiedDays = sorted.sublist(sorted.length - _historyCap).toSet();
  }

  void _persistProgress() {
    _prefs
      ..setString(_kMorning, jsonEncode(_morningDone.toList()))
      ..setString(_kEvening, jsonEncode(_eveningDone.toList()));
  }
}
