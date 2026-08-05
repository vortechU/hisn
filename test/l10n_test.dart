import 'package:adhan/adhan.dart';
import 'package:dua_app/l10n/app_strings.dart';
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
        }
        for (final m in Madhab.values) {
          expect(s.madhabLabel(m), isNotEmpty);
          expect(s.madhabHint(m), isNotEmpty);
        }
        expect(s.revelationLabel('meccan'), isNotEmpty);
        expect(s.revelationLabel('medinan'), isNotEmpty);
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
