import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dua_app/models/sunnah_day.dart';
import 'package:dua_app/services/backup_service.dart';
import 'package:dua_app/services/sunnah_calendar_service.dart';

/// The Gregorian date on which a given Hijri date falls, under no offset.
///
/// The tests are written against Hijri dates, because that is what the rules
/// are stated in; searching for the Gregorian day keeps them readable and
/// keeps them honest if the conversion library is ever swapped.
DateTime _gregorianFor(int hYear, int hMonth, int hDay) {
  final estimate = HijriCalendar()
    ..hYear = hYear
    ..hMonth = hMonth
    ..hDay = hDay;
  final from = estimate.hijriToGregorian(hYear, hMonth, hDay);
  final found = DateTime(from.year, from.month, from.day);
  final check = HijriCalendar.fromDate(found);
  expect(check.hYear, hYear);
  expect(check.hMonth, hMonth);
  expect(check.hDay, hDay);
  return found;
}

void main() {
  const rules = SunnahCalendarRules();

  group('fasting is never suggested when it is forbidden', () {
    test('Eid al-Fitr', () {
      final day = rules.dayFor(_gregorianFor(1447, 10, 1));
      expect(day.ruling, FastingRuling.forbidden);
      expect(day.bar, FastingBar.eidAlFitr);
      expect(day.fasts, isEmpty);
      expect(day.events, contains(IslamicEvent.eidAlFitr));
    });

    test('Eid al-Adha', () {
      final day = rules.dayFor(_gregorianFor(1447, 12, 10));
      expect(day.ruling, FastingRuling.forbidden);
      expect(day.bar, FastingBar.eidAlAdha);
      expect(day.fasts, isEmpty);
    });

    test('the three days of Tashriq', () {
      for (final hDay in [11, 12, 13]) {
        final day = rules.dayFor(_gregorianFor(1447, 12, hDay));
        expect(day.ruling, FastingRuling.forbidden,
            reason: '$hDay Dhul Hijjah');
        expect(day.bar, FastingBar.tashriq);
      }
    });

    test('the 13th of Dhul Hijjah is a white day, and still forbidden', () {
      // The only date where the two rules collide: 13 Dhul Hijjah is both one
      // of the white days and one of the days of Tashriq. The prohibition has
      // to win, or the app would tell someone to fast when they must not.
      final day = rules.dayFor(_gregorianFor(1447, 12, 13));
      expect(day.hijriDay, 13);
      expect(day.fasts, isEmpty);
      expect(day.ruling, FastingRuling.forbidden);
    });

    test('a weekday fast falling on an Eid is dropped', () {
      // Walk several years so at least one Eid lands on a Monday or Thursday.
      var checked = 0;
      for (var year = 1447; year < 1460; year++) {
        for (final hMonth in [10, 12]) {
          final date = _gregorianFor(year, hMonth, hMonth == 10 ? 1 : 10);
          if (date.weekday != DateTime.monday &&
              date.weekday != DateTime.thursday) {
            continue;
          }
          checked++;
          expect(rules.dayFor(date).fasts, isEmpty,
              reason: 'Eid on a ${date.weekday == DateTime.monday ? //
                  'Monday' : 'Thursday'}, $year');
        }
      }
      expect(checked, greaterThan(0), reason: 'no Eid fell on Mon/Thu');
    });
  });

  group('sunnah fasts land on the right days', () {
    test('the white days are the 13th, 14th and 15th', () {
      for (var hDay = 1; hDay <= 28; hDay++) {
        // Rajab: no other rule of ours touches this month.
        final day = rules.dayFor(_gregorianFor(1447, 7, hDay));
        expect(day.fasts.contains(SunnahFast.whiteDay), hDay >= 13 && hDay <= 15,
            reason: '$hDay Rajab');
      }
    });

    test('Ashura and Tasua', () {
      expect(rules.dayFor(_gregorianFor(1447, 1, 9)).fasts,
          contains(SunnahFast.tasua));
      final ashura = rules.dayFor(_gregorianFor(1447, 1, 10));
      expect(ashura.fasts, contains(SunnahFast.ashura));
      expect(ashura.events, contains(IslamicEvent.ashuraDay));
      // Ashura leads, ahead of any weekday fast on the same date.
      expect(ashura.primaryFast, SunnahFast.ashura);
    });

    test('the first nine of Dhul Hijjah, and Arafah leading on the 9th', () {
      for (var hDay = 1; hDay <= 9; hDay++) {
        expect(rules.dayFor(_gregorianFor(1447, 12, hDay)).fasts,
            contains(SunnahFast.dhulHijjah),
            reason: '$hDay Dhul Hijjah');
      }
      final arafah = rules.dayFor(_gregorianFor(1447, 12, 9));
      expect(arafah.primaryFast, SunnahFast.arafah);
      expect(arafah.events, contains(IslamicEvent.dayOfArafah));
    });

    test('six of Shawwal, never on the Eid itself', () {
      expect(rules.dayFor(_gregorianFor(1447, 10, 1)).fasts, isEmpty);
      for (var hDay = 2; hDay <= 7; hDay++) {
        expect(rules.dayFor(_gregorianFor(1447, 10, hDay)).fasts,
            contains(SunnahFast.sixOfShawwal),
            reason: '$hDay Shawwal');
      }
    });

    test('Ramadan is obligatory, and suppresses voluntary fasts', () {
      for (var hDay = 1; hDay <= 29; hDay++) {
        final day = rules.dayFor(_gregorianFor(1447, 9, hDay));
        expect(day.ruling, FastingRuling.obligatory, reason: '$hDay Ramadan');
        // A Monday, or the 14th, in Ramadan is simply a day of Ramadan.
        expect(day.fasts, [SunnahFast.ramadan], reason: '$hDay Ramadan');
      }
    });

    test('Mondays and Thursdays outside those months', () {
      final start = _gregorianFor(1447, 7, 1);
      for (var i = 0; i < 28; i++) {
        final date = start.add(Duration(days: i));
        final fasts = rules.dayFor(date).fasts;
        expect(fasts.contains(SunnahFast.monday),
            date.weekday == DateTime.monday);
        expect(fasts.contains(SunnahFast.thursday),
            date.weekday == DateTime.thursday);
      }
    });
  });

  group('occasions', () {
    test('each falls on its stated Hijri date', () {
      final cases = {
        IslamicEvent.islamicNewYear: (1, 1),
        IslamicEvent.ashuraDay: (1, 10),
        IslamicEvent.ramadanBegins: (9, 1),
        IslamicEvent.lastTenNights: (9, 21),
        IslamicEvent.eidAlFitr: (10, 1),
        IslamicEvent.dhulHijjahBegins: (12, 1),
        IslamicEvent.dayOfArafah: (12, 9),
        IslamicEvent.eidAlAdha: (12, 10),
      };
      for (final entry in cases.entries) {
        final (hMonth, hDay) = entry.value;
        expect(rules.dayFor(_gregorianFor(1447, hMonth, hDay)).events,
            contains(entry.key),
            reason: '${entry.key.name} on $hDay/$hMonth');
      }
    });

    test('an ordinary day carries none', () {
      final day = rules.dayFor(_gregorianFor(1447, 7, 5));
      expect(day.events, isEmpty);
      expect(day.isNotable, day.fasts.isNotEmpty);
    });
  });

  group('the sighting offset', () {
    test('shifts which Gregorian day is the Eid', () {
      final eid = _gregorianFor(1447, 10, 1);
      expect(const SunnahCalendarRules().dayFor(eid).bar, FastingBar.eidAlFitr);

      // With the calendar nudged a day later, the Eid moves a day later too:
      // the day that *was* Eid is now the last of Ramadan.
      const later = SunnahCalendarRules(offset: -1);
      expect(later.dayFor(eid).ruling, FastingRuling.obligatory);
      expect(later.dayFor(eid.add(const Duration(days: 1))).bar,
          FastingBar.eidAlFitr);
    });

    test('is applied without tripping over a DST change', () {
      // Late March and late October cross the European DST boundaries; adding
      // a raw Duration to a local midnight can land on a skipped hour and slip
      // a day. Every day of both months must convert to a distinct Hijri day.
      for (final month in [3, 10]) {
        for (final offset in [-1, 0, 1]) {
          final r = SunnahCalendarRules(offset: offset);
          final seen = <int>{};
          for (var d = 1; d <= 28; d++) {
            seen.add(r.dayFor(DateTime(2026, month, d)).hijriDay);
          }
          expect(seen, hasLength(28), reason: 'month $month, offset $offset');
        }
      }
    });
  });

  group('upcoming', () {
    test('returns only notable days, in order, within the window', () {
      final from = _gregorianFor(1447, 7, 1);
      final days = rules.upcoming(from, days: 60);

      expect(days, isNotEmpty);
      for (final day in days) {
        expect(day.isNotable, isTrue);
      }
      for (var i = 1; i < days.length; i++) {
        expect(days[i].date.isAfter(days[i - 1].date), isTrue);
      }
      expect(days.first.date.isBefore(from), isFalse);
      expect(days.last.date.difference(from).inDays, lessThan(60));
    });

    test('a 60-day window always covers both weekly fasts', () {
      // Sanity check that the list is never empty for a user opening the
      // screen on an arbitrary day — Mondays and Thursdays alone guarantee it.
      final days = rules.upcoming(DateTime(2026, 8, 6), days: 60);
      expect(days.length, greaterThan(15));
    });
  });

  group('SunnahCalendarService', () {
    test('defaults to no offset and reminders off', () async {
      SharedPreferences.setMockInitialValues({});
      final service = SunnahCalendarService(await _prefs());
      expect(service.offset, 0);
      expect(service.remindersEnabled, isFalse);
    });

    test('persists both, and clamps a stored offset out of range', () async {
      SharedPreferences.setMockInitialValues({'hijri_offset': 9});
      final prefs = await _prefs();
      expect(SunnahCalendarService(prefs).offset, SunnahCalendarRules.maxOffset);

      final service = SunnahCalendarService(prefs);
      await service.setOffset(-1);
      await service.setRemindersEnabled(true);
      expect(prefs.getInt('hijri_offset'), -1);

      final reloaded = SunnahCalendarService(prefs);
      expect(reloaded.offset, -1);
      expect(reloaded.remindersEnabled, isTrue);
    });

    test('setOffset refuses to go beyond the allowed range', () async {
      SharedPreferences.setMockInitialValues({});
      final service = SunnahCalendarService(await _prefs());
      await service.setOffset(5);
      expect(service.offset, SunnahCalendarRules.maxOffset);
      await service.setOffset(-5);
      expect(service.offset, SunnahCalendarRules.minOffset);
    });

    test('both keys are carried by backup & restore', () {
      // The offset is a device setting; the reminder toggle rides the notif_
      // prefix. Progress-only restores must leave the offset alone, so that a
      // backup from another country cannot shift this phone's calendar.
      expect(BackupService.isBackedUp('hijri_offset'), isTrue);
      expect(BackupService.isBackedUp('notif_fasting_reminders'), isTrue);
      expect(BackupService.inScope('hijri_offset', BackupScope.progressOnly),
          isFalse);
      expect(
          BackupService.inScope('hijri_offset', BackupScope.everything), isTrue);
    });
  });
}

Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();
