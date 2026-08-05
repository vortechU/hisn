import 'package:adhan/adhan.dart';
import 'package:dua_app/l10n/app_strings.dart';
import 'package:dua_app/models/sunnah_day.dart';
import 'package:dua_app/services/backup_service.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Exercises the localization facade for every language to catch runtime issues
/// (missing keys, bad list indices, plural/param wiring) that the analyzer can't.
void main() {
  for (final lang in AppLang.values) {
    group('AppStrings(${lang.name})', () {
      final s = AppStrings(lang);

      test('plain getters resolve to non-empty strings', () {
        expect(s.navQibla, isNotEmpty);
        expect(s.settings, isNotEmpty);
        expect(s.aboutBody, isNotEmpty);
        expect(s.currentLanguage, isNotEmpty);
        // Custom-dua editing + daily-remembrance reminders (added later).
        expect(s.editDua, isNotEmpty);
        expect(s.duaUpdated, isNotEmpty);
        expect(s.edit, isNotEmpty);
        expect(s.notifications, isNotEmpty);
        expect(s.dailyRemembrance, isNotEmpty);
        expect(s.dailyRemembranceSub, isNotEmpty);
        expect(s.adhkarMorningTitle, isNotEmpty);
        expect(s.adhkarEveningBody, isNotEmpty);
        expect(s.kahfTitle, isNotEmpty);
        expect(s.kahfBody, isNotEmpty);
        expect(s.salawatTitle, isNotEmpty);
        expect(s.salawatFridayBody, isNotEmpty);
        expect(s.mulkTitle, isNotEmpty);
        expect(s.mulkBody, isNotEmpty);
      });

      test('parameterized + plural strings interpolate', () {
        expect(s.muhassanToday(80), contains('80'));
        expect(s.streakDays(1), isNotEmpty);
        expect(s.streakDays(5), contains('5'));
        expect(s.versesCount(1), isNotEmpty);
        expect(s.versesCount(7), contains('7'));
        expect(s.readNow(1), isNotEmpty);
        expect(s.readNow(3), contains('3'));
        expect(s.juzLabel(15), contains('15'));
        expect(s.qiblaFromNorth('123'), contains('123'));
        expect(s.locDeviceGps('Madinah'), contains('Madinah'));
      });

      test('list-backed strings have the right length', () {
        expect(s.weekdayLetters, hasLength(7));
        expect(s.fontScaleLabels, hasLength(4));
        for (var i = 0; i < 3; i++) {
          expect(s.streamLabel(i), isNotEmpty);
          expect(s.streamHint(i), isNotEmpty);
        }
      });

      test('enum-driven strings cover every value', () {
        for (final p in Prayer.values) {
          expect(s.prayerName(p), isNotEmpty);
          expect(s.notifTitle(p), isNotEmpty);
          expect(s.notifBody(p, 'Madinah'), contains('Madinah'));
          expect(s.notifIqamahBody(p, 'Madinah'), contains('Madinah'));
        }
        expect(s.iqamahOffset, isNotEmpty);
        expect(s.iqamahOffsetValue(0), isNotEmpty);
        expect(s.iqamahOffsetValue(15), contains('15'));
        for (final m in Madhab.values) {
          expect(s.madhabLabel(m), isNotEmpty);
          expect(s.madhabHint(m), isNotEmpty);
        }
        expect(s.revelationLabel('meccan'), isNotEmpty);
        expect(s.revelationLabel('medinan'), isNotEmpty);
        for (final f in SunnahFast.values) {
          expect(s.fastName(f), isNotEmpty);
          // Every fast must carry its grounding — an unsourced claim about
          // what the Sunnah encourages is exactly what this app must not do.
          expect(s.fastVirtue(f), isNotEmpty);
          expect(s.notifFastBody(f), contains(s.fastName(f)));
        }
        for (final e in IslamicEvent.values) {
          expect(s.eventName(e), isNotEmpty);
        }
        for (final b in FastingBar.values) {
          expect(s.fastingBar(b), isNotEmpty);
        }
        for (final r in FastingRuling.values) {
          expect(s.fastingRuling(r), isNotEmpty);
        }
        for (var o = SunnahCalendarRules.minOffset;
            o <= SunnahCalendarRules.maxOffset;
            o++) {
          expect(s.hijriOffsetLabel(o), isNotEmpty);
        }
        // The five offsets must read differently, or the picker is unusable.
        expect(
          {
            for (var o = SunnahCalendarRules.minOffset;
                o <= SunnahCalendarRules.maxOffset;
                o++)
              s.hijriOffsetLabel(o),
          },
          hasLength(
              SunnahCalendarRules.maxOffset - SunnahCalendarRules.minOffset + 1),
        );
      });

      test('the Hijri offset actually moves the printed date', () {
        // A date late in a Hijri month, so ±1 stays inside the same month and
        // the day number is what changes.
        final date = DateTime(2026, 8, 6);
        expect(s.hijriDate(date, offset: 0),
            isNot(s.hijriDate(date, offset: 1)));
        expect(s.hijriDate(date, offset: 0),
            isNot(s.hijriDate(date, offset: -1)));
      });

      test('date + clock formatting works for all months/weekdays', () {
        for (var month = 1; month <= 12; month++) {
          expect(s.dateLabel(DateTime(2026, month, 15)), isNotEmpty);
        }
        expect(s.ampm(9), isNotEmpty);
        expect(s.ampm(21), isNotEmpty);
      });

      test('hijri date formats across a full Gregorian year', () {
        expect(s.hijriMonths, hasLength(12));
        expect(s.hijriSuffix, isNotEmpty);
        expect(s.next, isNotEmpty);
        for (var month = 1; month <= 12; month++) {
          final hijri = s.hijriDate(DateTime(2026, month, 15));
          expect(hijri, isNotEmpty);
          expect(hijri, contains(s.hijriSuffix));
        }
      });

      test('backup & restore strings are present and parameterised', () {
        for (final text in [
          s.secBackup,
          s.backupSub,
          s.backupOnThisDevice,
          s.backupSave,
          s.backupSaveHint,
          s.backupRestoreHeading,
          s.backupRestore,
          s.backupRestoreHint,
          s.backupPrivacy,
          s.backupStatStreak,
          s.backupStatBest,
          s.backupStatDays,
          s.backupStatFavorites,
          s.backupStatCustom,
          s.backupStatQuran,
          s.restoreTitle,
          s.restoreScopeEverything,
          s.restoreScopeEverythingSub,
          s.restoreScopeProgress,
          s.restoreScopeProgressSub,
          s.restoreWarning,
          s.restoreAction,
          s.backupSaved,
          s.backupFailed,
          s.restoreFailed,
        ]) {
          expect(text, isNotEmpty);
        }

        // Every failure mode needs a sentence the user can act on.
        for (final error in BackupError.values) {
          expect(s.restoreError(error), isNotEmpty);
        }

        // The date and version placeholders must actually be substituted.
        final dated = s.restoreSavedOn(DateTime(2026, 8, 5), '1.9.0');
        expect(dated, contains('2026'));
        expect(dated, contains('1.9.0'));
        expect(dated, isNot(contains(r'$')));
        // A file with no recorded version falls back to the date-only form.
        final undated = s.restoreSavedOn(DateTime(2026, 8, 5), '');
        expect(undated, isNot(contains('1.9.0')));
        expect(undated, isNot(contains(r'$')));

        expect(s.restoreDone(1), isNotEmpty);
        expect(s.restoreDone(7), contains('7'));
      });

      test('place sentinels translate, unknown names pass through', () {
        expect(s.place('Your location'), isNotEmpty);
        expect(s.place('Makkah'), isNotEmpty);
        expect(s.place('Tokyo'), 'Tokyo');
      });
    });
  }

  test('languages differ where expected', () {
    expect(AppStrings(AppLang.en).navQibla, 'Qibla');
    expect(AppStrings(AppLang.id).navQibla, 'Kiblat');
    expect(AppStrings(AppLang.ar).navQibla, isNot('Qibla'));
  });
}
