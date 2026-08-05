import 'dart:convert';

import 'package:dua_app/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A representative slice of real app state: one key of every stored type,
/// drawn from both scopes.
const _sample = <String, Object>{
  // progress
  'muhassan_streak': 12,
  'muhassan_best': 30,
  'muhassan_total': 45,
  'muhassan_history': <String>['2026-08-01', '2026-08-02'],
  'dua_progress_day': '2026-08-05',
  'favorite_dua_ids': <String>['morning_ayat_kursi', 'evening_quls'],
  'tasbih_count_subhanallah': 33,
  'tasbih_laps_subhanallah': 4,
  'quran_bookmark_pages': <String>['2', '604'],
  'quran_bookmark_ayahs': <String>['2:255', '18:10'],
  'quran_last_page': 255,
  // settings
  'app_language': 'ar',
  'prayer_lat': 21.4225,
  'prayer_method': 'ummAlQura',
  'notif_master_enabled': true,
  'display_font_scale': 1.0,
  'theme_patterns': false,
  'onboarding_seen_v1': true,
};

Future<SharedPreferences> _prefsWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

Map<String, Object> _valuesOf(SharedPreferences prefs) => {
      for (final k in prefs.getKeys()) k: prefs.get(k)!,
    };

/// A [BackupService] whose storage gives out on one key.
///
/// Storage failing mid-write is the whole reason the journal exists, and the
/// mock store cannot be made to fail — so the single method through which a
/// restore touches storage is overridden here.
///
/// Which key is chosen decides which path runs. A key the previous state did
/// *not* hold fails only the restore, so the rollback completes normally. A key
/// it did hold fails the rollback as well, which is what being killed outright
/// looks like: the journal survives for the next launch.
class _FailingBackupService extends BackupService {
  const _FailingBackupService(this.failOnKey);

  final String failOnKey;

  @override
  Future<bool> writeValue(
    SharedPreferences prefs,
    String key,
    Object value,
  ) async {
    if (key == failOnKey) throw StateError('storage gave out on $key');
    return super.writeValue(prefs, key, value);
  }
}

void main() {
  const service = BackupService();

  group('key scoping', () {
    test('recognises every key the app persists', () {
      for (final key in _sample.keys) {
        expect(BackupService.isBackedUp(key), isTrue, reason: key);
      }
    });

    test('ignores keys that are not the user data', () {
      for (final key in const [
        'flutter.some_plugin_cache',
        'last_seen_build',
        '',
      ]) {
        expect(BackupService.isBackedUp(key), isFalse, reason: key);
      }
    });

    test('progress-only scope excludes settings', () {
      const progress = BackupScope.progressOnly;
      expect(BackupService.inScope('muhassan_streak', progress), isTrue);
      expect(BackupService.inScope('custom_duas', progress), isTrue);
      expect(BackupService.inScope('tasbih_count_x', progress), isTrue);
      // Covered by the `quran_` prefix rather than by name, so a Quran key
      // added later is backed up without anyone remembering to list it.
      expect(BackupService.inScope('quran_bookmark_ayahs', progress), isTrue);
      expect(BackupService.inScope('quran_anything_later', progress), isTrue);
      expect(BackupService.inScope('prayer_lat', progress), isFalse);
      expect(BackupService.inScope('app_language', progress), isFalse);
      expect(BackupService.inScope('notif_master_enabled', progress), isFalse);
    });
  });

  group('round trip', () {
    test('restores every value with its original type', () async {
      final source = await _prefsWith(_sample);
      final raw = utf8.decode(service.encode(source, appVersion: '1.9.0'));

      final (backup, error) = service.parse(raw);
      expect(error, isNull);
      expect(backup, isNotNull);

      final target = await _prefsWith({});
      final written = await service.restore(target, backup!);

      expect(written, _sample.length);
      expect(_valuesOf(target), _sample);
      // The whole-number double must not come back as an int.
      expect(target.get('display_font_scale'), isA<double>());
      expect(target.get('quran_last_page'), isA<int>());
    });

    test('summarises the data for the confirm step', () async {
      final prefs = await _prefsWith({
        ..._sample,
        'custom_duas': jsonEncode([
          {'id': 'c1'},
          {'id': 'c2'},
          {'id': 'c3'},
        ]),
      });
      final raw = utf8.decode(service.encode(prefs, appVersion: '1.9.0'));
      final (backup, _) = service.parse(raw);

      expect(backup!.summary.streak, 12);
      expect(backup.summary.bestStreak, 30);
      expect(backup.summary.fortifiedDays, 45);
      expect(backup.summary.favorites, 2);
      expect(backup.summary.customDuas, 3);
      // Saved pages and saved verses both count.
      expect(backup.summary.quranBookmarks, 4);
    });

    test('carries the stamp and a readable filename', () async {
      final prefs = await _prefsWith(_sample);
      final now = DateTime(2026, 8, 5, 14, 30);

      expect(service.fileName(now: now), 'hisn-backup-2026-08-05.json');

      final doc = service.build(prefs, appVersion: '1.9.0', now: now);
      expect(doc['app'], 'hisn-backup');
      expect(doc['format'], BackupService.formatVersion);
      expect(doc['appVersion'], '1.9.0');

      final (backup, _) = service.parse(jsonEncode(doc));
      expect(backup!.createdAt, now);
      expect(backup.appVersion, '1.9.0');
    });

    test('skips prefs that are not the user data', () async {
      final prefs = await _prefsWith({
        'muhassan_streak': 3,
        'flutter.plugin_scratch': 'noise',
        'unrelated': 42,
      });
      final doc = service.build(prefs, appVersion: '1.9.0');

      expect((doc['data'] as Map).keys, ['muhassan_streak']);
    });
  });

  group('restore semantics', () {
    test('replaces rather than merges, within scope', () async {
      final source = await _prefsWith({
        'muhassan_streak': 5,
        'favorite_dua_ids': <String>['a'],
      });
      final raw = utf8.decode(service.encode(source, appVersion: '1.9.0'));
      final (backup, _) = service.parse(raw);

      // The device already has a longer streak and more favourites; restoring
      // the snapshot must not blend the two.
      final target = await _prefsWith({
        'muhassan_streak': 99,
        'muhassan_best': 99,
        'favorite_dua_ids': <String>['a', 'b', 'c'],
      });
      await service.restore(target, backup!);

      expect(target.getInt('muhassan_streak'), 5);
      expect(target.getStringList('favorite_dua_ids'), ['a']);
      // In scope but absent from the backup — cleared, not left behind.
      expect(target.getInt('muhassan_best'), isNull);
    });

    test('progress-only leaves this device settings untouched', () async {
      final source = await _prefsWith({
        'muhassan_streak': 5,
        'prayer_lat': 21.4225,
        'app_language': 'ar',
      });
      final raw = utf8.decode(service.encode(source, appVersion: '1.9.0'));
      final (backup, _) = service.parse(raw);

      final target = await _prefsWith({
        'muhassan_streak': 0,
        'prayer_lat': 51.5072, // this phone is in London now
        'app_language': 'en',
      });
      final written =
          await service.restore(target, backup!, scope: BackupScope.progressOnly);

      expect(written, 1);
      expect(target.getInt('muhassan_streak'), 5);
      expect(target.getDouble('prayer_lat'), 51.5072);
      expect(target.getString('app_language'), 'en');
    });
  });

  group('is transactional', () {
    // The state a user would lose if a restore stopped halfway.
    const before = <String, Object>{
      'muhassan_streak': 200,
      'muhassan_best': 200,
      'muhassan_history': <String>['2026-01-01', '2026-01-02'],
      'favorite_dua_ids': <String>['a', 'b'],
      'tasbih_count_subhanallah': 33,
      'prayer_lat': 51.5072,
      'app_language': 'en',
    };

    Future<Backup> backupOf(Map<String, Object> values) async {
      final prefs = await _prefsWith(values);
      final raw = utf8.decode(service.encode(prefs, appVersion: '1.9.0'));
      final (backup, _) = service.parse(raw);
      return backup!;
    }

    // Carries a key the previous state does not hold ('quran_last_page'), so a
    // test can fail on it without also tripping the rollback.
    Future<Backup> incoming() => backupOf(const {
          'muhassan_streak': 1,
          'muhassan_best': 1,
          'favorite_dua_ids': <String>['z'],
          'quran_last_page': 5,
          'app_language': 'ar',
        });

    test('a failed write leaves the previous state exactly as it was',
        () async {
      final backup = await incoming();
      final prefs = await _prefsWith(before);

      await expectLater(
        const _FailingBackupService('quran_last_page').restore(prefs, backup),
        throwsA(isA<StateError>()),
      );

      expect(_valuesOf(prefs), before);
      // Cleared once the rollback succeeded, so the next launch has nothing
      // left to do.
      expect(prefs.getString('backup_restore_journal'), isNull);
    });

    test('rolls back only the scope it touched', () async {
      final backup = await incoming();
      final prefs = await _prefsWith(before);

      await expectLater(
        const _FailingBackupService('quran_last_page')
            .restore(prefs, backup, scope: BackupScope.progressOnly),
        throwsA(isA<StateError>()),
      );

      expect(_valuesOf(prefs), before);
      expect(prefs.getString('backup_restore_journal'), isNull);
    });

    test('a restore killed mid-write is undone at the next launch', () async {
      final backup = await incoming();
      final prefs = await _prefsWith(before);

      // Failing on a key the previous state also holds takes the rollback down
      // with it — the app dying mid-restore, leaving the journal on disk.
      await expectLater(
        const _FailingBackupService('favorite_dua_ids').restore(prefs, backup),
        throwsA(isA<StateError>()),
      );

      // The store as the user would find it: neither the old state nor the new.
      final mangled = Map.of(_valuesOf(prefs))
        ..remove('backup_restore_journal');
      expect(mangled, isNot(before));
      expect(prefs.getString('backup_restore_journal'), isNotNull);

      // Next launch.
      final recovered = await service.recoverInterruptedRestore(prefs);

      expect(recovered, isTrue);
      expect(_valuesOf(prefs), before);
      expect(prefs.getString('backup_restore_journal'), isNull);
    });

    test('a clean launch has nothing to recover', () async {
      final prefs = await _prefsWith(before);
      expect(await service.recoverInterruptedRestore(prefs), isFalse);
      expect(_valuesOf(prefs), before);
    });

    test('a successful restore leaves no journal behind', () async {
      final backup = await backupOf(const {'muhassan_streak': 1});
      final prefs = await _prefsWith(before);

      await service.restore(prefs, backup);

      expect(prefs.getString('backup_restore_journal'), isNull);
      expect(await service.recoverInterruptedRestore(prefs), isFalse);
      expect(prefs.getInt('muhassan_streak'), 1);
    });

    test('an unreadable journal is dropped rather than retried forever',
        () async {
      final prefs = await _prefsWith({
        ...before,
        'backup_restore_journal': 'not json',
      });

      expect(await service.recoverInterruptedRestore(prefs), isFalse);
      expect(prefs.getString('backup_restore_journal'), isNull);
      expect(_valuesOf(prefs), before);
    });

    test('the journal key never leaks into a backup file', () async {
      expect(BackupService.isBackedUp('backup_restore_journal'), isFalse);

      final prefs = await _prefsWith({
        ...before,
        'backup_restore_journal': '{"scope":"everything","data":{}}',
      });
      final doc = service.build(prefs, appVersion: '1.9.0');

      expect((doc['data'] as Map).containsKey('backup_restore_journal'),
          isFalse);
    });
  });

  group('rejects bad input', () {
    Future<BackupError?> errorFor(String raw) async {
      final (_, error) = service.parse(raw);
      return error;
    }

    test('malformed json', () async {
      expect(await errorFor('not json at all'), BackupError.malformed);
      expect(await errorFor('[1, 2, 3]'), BackupError.malformed);
    });

    test('some other app json file', () async {
      expect(
        await errorFor(jsonEncode({'app': 'something-else', 'data': {}})),
        BackupError.notABackup,
      );
      expect(
        await errorFor(jsonEncode({'hello': 'world'})),
        BackupError.notABackup,
      );
    });

    test('a backup from a newer app', () async {
      expect(
        await errorFor(jsonEncode({
          'app': 'hisn-backup',
          'format': BackupService.formatVersion + 1,
          'data': {'muhassan_streak': {'type': 'int', 'value': 1}},
        })),
        BackupError.tooNew,
      );
    });

    test('a backup with nothing restorable in it', () async {
      expect(
        await errorFor(jsonEncode({
          'app': 'hisn-backup',
          'format': 1,
          'data': {'not_our_key': {'type': 'int', 'value': 1}},
        })),
        BackupError.empty,
      );
    });
  });

  group('tolerates imperfect files', () {
    test('drops entries it cannot decode, keeps the rest', () async {
      final (backup, error) = service.parse(jsonEncode({
        'app': 'hisn-backup',
        'format': 1,
        'data': {
          'muhassan_streak': {'type': 'int', 'value': 7},
          'muhassan_best': {'type': 'int', 'value': 'not a number'},
          'favorite_dua_ids': {'type': 'stringList', 'value': [1, 2]},
          'app_language': {'type': 'mystery', 'value': 'ar'},
          'quran_last_page': 'no type tag at all',
        },
      }));

      expect(error, isNull);
      expect(backup!.values, {'muhassan_streak': 7});
    });

    test('accepts a whole double written by hand as an int', () async {
      final (backup, _) = service.parse(jsonEncode({
        'app': 'hisn-backup',
        'format': 1,
        'data': {
          'display_font_scale': {'type': 'double', 'value': 1},
        },
      }));

      expect(backup!.values['display_font_scale'], isA<double>());
      expect(backup.values['display_font_scale'], 1.0);
    });

    test('counts what is in scope for the confirm step', () async {
      final prefs = await _prefsWith(_sample);
      final raw = utf8.decode(service.encode(prefs, appVersion: '1.9.0'));
      final (backup, _) = service.parse(raw);

      expect(backup!.countIn(BackupScope.everything), _sample.length);
      expect(backup.countIn(BackupScope.progressOnly), 11);
    });
  });
}
