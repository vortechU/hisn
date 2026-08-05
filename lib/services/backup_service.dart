import 'dart:convert';

import 'package:flutter/foundation.dart' show protected, visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';

/// Which part of a backup to write back.
enum BackupScope {
  /// Everything the backup carries — progress *and* settings.
  everything,

  /// Only what the user has earned or written (streak, counters, bookmarks,
  /// custom duas), leaving this device's settings — location, calculation
  /// method, reminders, language, theme — as they are.
  progressOnly,
}

/// Why a backup file was rejected.
enum BackupError {
  /// Not JSON at all, or JSON that isn't an object.
  malformed,

  /// Valid JSON, but not a Hisn backup.
  notABackup,

  /// A Hisn backup written by a newer app than this one.
  tooNew,

  /// A Hisn backup with nothing in it.
  empty,
}

/// The handful of numbers shown before a restore is confirmed, so the user can
/// tell one backup file from another without opening it.
class BackupSummary {
  const BackupSummary({
    required this.streak,
    required this.bestStreak,
    required this.fortifiedDays,
    required this.favorites,
    required this.customDuas,
    required this.quranBookmarks,
  });

  final int streak;
  final int bestStreak;
  final int fortifiedDays;
  final int favorites;
  final int customDuas;
  final int quranBookmarks;

  Map<String, dynamic> toJson() => {
        'streak': streak,
        'bestStreak': bestStreak,
        'fortifiedDays': fortifiedDays,
        'favorites': favorites,
        'customDuas': customDuas,
        'quranBookmarks': quranBookmarks,
      };

}

/// A backup file that parsed and validated — ready to be restored.
class Backup {
  const Backup({
    required this.formatVersion,
    required this.appVersion,
    required this.createdAt,
    required this.summary,
    required this.values,
  });

  final int formatVersion;

  /// The app version that wrote the file, for display only.
  final String appVersion;

  /// When the file was written; null if the stamp was missing or unparseable.
  final DateTime? createdAt;

  final BackupSummary summary;

  /// The restorable prefs entries, already decoded to their Dart types.
  final Map<String, Object> values;

  /// How many entries fall inside [scope].
  int countIn(BackupScope scope) =>
      values.keys.where((k) => BackupService.inScope(k, scope)).length;
}

/// Reads and writes the user's data as a single portable JSON document.
///
/// Everything the app persists lives in [SharedPreferences], so a backup is a
/// filtered snapshot of it. Keys are selected by an explicit allow-list — by
/// exact name or by prefix — rather than by dumping the store wholesale, so
/// nothing incidental (plugin scratch state, cached values) rides along, and a
/// key added under an existing prefix later is covered without further work.
///
/// Values carry an explicit type tag. JSON on its own can't tell an `int` from
/// a `double` that happens to be whole — restoring the font scale `1.0` as an
/// `int` would throw on read — so the type is written down rather than guessed.
class BackupService {
  const BackupService();

  /// Bumped only when the document shape changes incompatibly. A file from a
  /// *newer* format is refused; older formats stay readable.
  static const formatVersion = 1;

  /// Identifies the document as ours before we act on any of its contents.
  static const _magic = 'hisn-backup';

  // --- what counts as "progress": earned or authored by the user ---
  static const _progressKeys = <String>{
    'favorite_dua_ids',
    'custom_duas',
    'quran_bookmark_pages',
    'quran_last_page',
  };
  static const _progressPrefixes = <String>[
    'muhassan_', // streak, best, history, per-day completion
    'dua_progress_', // today's partially-counted set
    'tasbih_count_',
    'tasbih_laps_',
  ];

  // --- what counts as "settings": this device's configuration ---
  static const _settingsKeys = <String>{
    'app_language',
    'onboarding_seen_v1',
  };
  static const _settingsPrefixes = <String>[
    'prayer_', // location, method, madhab
    'notif_', // master, per-prayer, daily remembrance
    'display_', // font scale, transliteration/translation, Arabic face
    'theme_', // palette, mode, patterns
    'adhan_sound_', // enabled, volume stream
  ];

  /// Whether [key] belongs to the user's data at all.
  static bool isBackedUp(String key) =>
      _matches(key, _progressKeys, _progressPrefixes) ||
      _matches(key, _settingsKeys, _settingsPrefixes);

  /// Whether [key] should be written back when restoring with [scope].
  static bool inScope(String key, BackupScope scope) =>
      switch (scope) {
        BackupScope.everything => isBackedUp(key),
        BackupScope.progressOnly =>
          _matches(key, _progressKeys, _progressPrefixes),
      };

  static bool _matches(String key, Set<String> exact, List<String> prefixes) =>
      exact.contains(key) || prefixes.any(key.startsWith);

  // ---------------------------------------------------------------- export

  /// Builds the backup document for everything currently stored in [prefs].
  Map<String, dynamic> build(
    SharedPreferences prefs, {
    required String appVersion,
    DateTime? now,
  }) {
    final values = <String, Object>{};
    for (final key in prefs.getKeys()) {
      if (!isBackedUp(key)) continue;
      final value = prefs.get(key);
      if (value != null) values[key] = value;
    }

    return {
      'app': _magic,
      'format': formatVersion,
      'appVersion': appVersion,
      'createdAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'summary': _summarize(values).toJson(),
      'data': {
        for (final entry in _sorted(values))
          entry.key: _encodeValue(entry.value),
      },
    };
  }

  /// The backup document as the bytes to write to a file. Indented, because a
  /// file the user can open and read is a file they can trust.
  List<int> encode(
    SharedPreferences prefs, {
    required String appVersion,
    DateTime? now,
  }) =>
      utf8.encode(
        const JsonEncoder.withIndent('  ')
            .convert(build(prefs, appVersion: appVersion, now: now)),
      );

  /// The suggested filename, dated so successive backups don't collide.
  String fileName({DateTime? now}) {
    final d = now ?? DateTime.now();
    final stamp = '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    return 'hisn-backup-$stamp.json';
  }

  static Iterable<MapEntry<String, Object>> _sorted(Map<String, Object> v) =>
      v.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

  static Map<String, dynamic> _encodeValue(Object value) => switch (value) {
        bool v => {'type': 'bool', 'value': v},
        int v => {'type': 'int', 'value': v},
        double v => {'type': 'double', 'value': v},
        String v => {'type': 'string', 'value': v},
        List<String> v => {'type': 'stringList', 'value': v},
        // getKeys/get only ever yield the five types above.
        _ => {'type': 'string', 'value': value.toString()},
      };

  static Object? _decodeValue(Object? encoded) {
    if (encoded is! Map) return null;
    final value = encoded['value'];
    return switch (encoded['type']) {
      'bool' => value is bool ? value : null,
      'int' => value is int ? value : null,
      // A whole double may have been written as `21` by hand; accept both.
      'double' => value is num ? value.toDouble() : null,
      'string' => value is String ? value : null,
      'stringList' =>
        value is List && value.every((e) => e is String) ? value.cast<String>() : null,
      _ => null,
    };
  }

  // ---------------------------------------------------------------- import

  /// Parses and validates [raw]. Returns the [Backup] on success, or a
  /// [BackupError] describing why the file can't be used.
  ///
  /// Unknown keys and entries that fail to decode are dropped rather than
  /// failing the whole file: a backup from a later app version should still
  /// restore everything this version understands.
  (Backup?, BackupError?) parse(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return (null, BackupError.malformed);
    }
    if (decoded is! Map<String, dynamic>) return (null, BackupError.malformed);
    if (decoded['app'] != _magic) return (null, BackupError.notABackup);

    final format = decoded['format'];
    if (format is! int) return (null, BackupError.notABackup);
    if (format > formatVersion) return (null, BackupError.tooNew);

    final data = decoded['data'];
    if (data is! Map) return (null, BackupError.notABackup);

    final values = <String, Object>{};
    for (final entry in data.entries) {
      final key = entry.key;
      if (key is! String || !isBackedUp(key)) continue;
      final value = _decodeValue(entry.value);
      if (value != null) values[key] = value;
    }
    if (values.isEmpty) return (null, BackupError.empty);

    return (
      Backup(
        formatVersion: format,
        appVersion: decoded['appVersion'] is String
            ? decoded['appVersion'] as String
            : '',
        createdAt: DateTime.tryParse(
          decoded['createdAt'] is String ? decoded['createdAt'] as String : '',
        )?.toLocal(),
        // Recomputed from the data rather than read back from the file's own
        // `summary` block, so a hand-edited or stale summary can't misdescribe
        // what is about to be restored. The block is written for the benefit of
        // a human opening the file, not for us.
        summary: _summarize(values),
        values: values,
      ),
      null
    );
  }

  /// Writes [backup] back into [prefs], replacing what is currently stored
  /// within [scope].
  ///
  /// Replace — not merge — so the result is exactly the snapshot the file
  /// describes: keys in scope that the backup doesn't carry are cleared, rather
  /// than left behind to blend two different histories together.
  ///
  /// **All or nothing.** A restore rewrites many keys one at a time, and there
  /// is no transaction in [SharedPreferences] to wrap that in. Half of it
  /// landing would leave a streak history spliced onto someone else's
  /// counters — silently wrong, and unrecoverable because the previous state is
  /// gone. So the in-scope state is journalled first (see [_kJournal]); if any
  /// write fails, the journal is played back and the store ends up exactly as
  /// it started. If the *process* dies partway, the journal outlives it and
  /// [recoverInterruptedRestore] rolls back at next launch.
  ///
  /// Returns the number of entries written. Rethrows whatever failed, after
  /// rolling back.
  Future<int> restore(
    SharedPreferences prefs,
    Backup backup, {
    BackupScope scope = BackupScope.everything,
  }) async {
    final rollback = _inScopeValues(prefs, scope);
    await _writeJournal(prefs, scope, rollback);

    try {
      final written = await _apply(prefs, scope, backup.values);
      await prefs.remove(_kJournal);
      return written;
    } catch (_) {
      try {
        await _apply(prefs, scope, rollback);
        // Undone here, so there is nothing left for startup to recover.
        await prefs.remove(_kJournal);
      } catch (_) {
        // Rolling back failed too. Leave the journal in place — the next
        // launch will finish the job. Swallowed so the original failure, not
        // this one, is what reaches the caller.
      }
      rethrow;
    }
  }

  /// Finishes rolling back a restore that never completed.
  ///
  /// Call once at startup, before any service reads its state. Returns true if
  /// a rollback was performed.
  ///
  /// A journal on disk means [restore] began and did not get to clear it — the
  /// app was killed mid-write, or the rollback itself was interrupted. Either
  /// way the recorded state is the last known-good one, so it is replayed. The
  /// backup file is not available at this point, so rolling *forward* is not an
  /// option; back is the only defined direction.
  Future<bool> recoverInterruptedRestore(SharedPreferences prefs) async {
    final raw = prefs.getString(_kJournal);
    if (raw == null) return false;

    final journal = _readJournal(raw);
    if (journal == null) {
      // Unreadable, so there is nothing to replay. Drop it rather than leave a
      // journal that would be retried fruitlessly on every launch.
      await prefs.remove(_kJournal);
      return false;
    }

    final (scope, values) = journal;
    await _apply(prefs, scope, values);
    await prefs.remove(_kJournal);
    return true;
  }

  /// Clears everything in [scope] and writes [values] in its place.
  ///
  /// Shared by the restore and its rollback: both are "make the in-scope state
  /// exactly this", which keeps the undo path on the same code as the do path
  /// rather than on a second implementation that is only exercised when
  /// something has already gone wrong.
  Future<int> _apply(
    SharedPreferences prefs,
    BackupScope scope,
    Map<String, Object> values,
  ) async {
    final stale = prefs
        .getKeys()
        .where((k) => inScope(k, scope))
        .toList(growable: false);
    for (final key in stale) {
      await prefs.remove(key);
    }

    // Sorted, so that a run interrupted at the same point twice leaves the same
    // state twice — a nondeterministic order would make any report of a failed
    // restore impossible to reproduce.
    var written = 0;
    for (final entry in _sorted(values)) {
      if (!inScope(entry.key, scope)) continue;
      if (await writeValue(prefs, entry.key, entry.value)) written++;
    }
    return written;
  }

  /// Everything currently stored within [scope].
  Map<String, Object> _inScopeValues(
    SharedPreferences prefs,
    BackupScope scope,
  ) {
    final values = <String, Object>{};
    for (final key in prefs.getKeys()) {
      if (!inScope(key, scope)) continue;
      final value = prefs.get(key);
      if (value != null) values[key] = value;
    }
    return values;
  }

  /// Writes one value, dispatching on its type.
  ///
  /// The single point where a restore touches storage, and so the seam a test
  /// overrides to make a write fail partway through.
  @protected
  @visibleForTesting
  Future<bool> writeValue(
    SharedPreferences prefs,
    String key,
    Object value,
  ) async =>
      switch (value) {
        bool v => prefs.setBool(key, v),
        int v => prefs.setInt(key, v),
        double v => prefs.setDouble(key, v),
        String v => prefs.setString(key, v),
        List<String> v => prefs.setStringList(key, v),
        _ => Future.value(false),
      };

  // --------------------------------------------------------------- journal

  /// Where the pre-restore state is parked while a restore is in flight.
  ///
  /// Deliberately outside the backed-up key space, so a journal can never end
  /// up inside a backup file or be cleared by the restore it is protecting.
  static const _kJournal = 'backup_restore_journal';

  /// Records the state to return to, and waits for it to be stored before the
  /// caller is allowed to change anything.
  ///
  /// This is as durable as [SharedPreferences] itself: the platform may still
  /// be holding the write in a buffer when the future completes, so a power
  /// cut at exactly the wrong moment remains outside what this can promise.
  /// It covers the failure that actually happens — the app being killed.
  Future<void> _writeJournal(
    SharedPreferences prefs,
    BackupScope scope,
    Map<String, Object> values,
  ) =>
      prefs.setString(
        _kJournal,
        jsonEncode({
          'scope': scope.name,
          'data': {
            for (final entry in values.entries)
              entry.key: _encodeValue(entry.value),
          },
        }),
      );

  static (BackupScope, Map<String, Object>)? _readJournal(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return null;
    }
    if (decoded is! Map) return null;
    final journal = decoded;

    BackupScope? scope;
    for (final candidate in BackupScope.values) {
      if (candidate.name == journal['scope']) scope = candidate;
    }
    final data = journal['data'];
    if (scope == null || data is! Map) return null;

    final values = <String, Object>{};
    for (final entry in data.entries) {
      final key = entry.key;
      if (key is! String || !isBackedUp(key)) continue;
      final value = _decodeValue(entry.value);
      if (value != null) values[key] = value;
    }
    return (scope, values);
  }

  // --------------------------------------------------------------- summary

  static BackupSummary _summarize(Map<String, Object> values) {
    int intOf(String key) {
      final v = values[key];
      return v is int ? v : 0;
    }

    int lengthOf(String key) {
      final v = values[key];
      return v is List<String> ? v.length : 0;
    }

    return BackupSummary(
      streak: intOf('muhassan_streak'),
      bestStreak: intOf('muhassan_best'),
      fortifiedDays: intOf('muhassan_total'),
      favorites: lengthOf('favorite_dua_ids'),
      customDuas: _customDuaCount(values['custom_duas']),
      quranBookmarks: lengthOf('quran_bookmark_pages'),
    );
  }

  /// Custom duas are stored as an encoded JSON list; count them without
  /// building [Dua] objects, so a single malformed entry can't break the
  /// preview of an otherwise good file.
  static int _customDuaCount(Object? raw) {
    if (raw is! String || raw.isEmpty) return 0;
    try {
      final list = jsonDecode(raw);
      return list is List ? list.length : 0;
    } catch (_) {
      return 0;
    }
  }
}
