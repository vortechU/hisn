import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dua_app/services/prayer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PrayerService> service(Map<String, Object> extra) async {
    SharedPreferences.setMockInitialValues({
      'prayer_location_mode': 'manual',
      'prayer_lat': 21.4225,
      'prayer_lng': 39.8262,
      'prayer_location_label': 'Makkah',
      ...extra,
    });
    return PrayerService(await SharedPreferences.getInstance());
  }

  test('sunrise is always shown, between Fajr and Dhuhr', () async {
    final prayers = await service({});
    final day = DateTime(2026, 10, 23);
    final marks = prayers.marksForDay(day);
    expect(marks.map((m) => m.mark), [DayMark.sunrise]);
    final times = prayers.prayersForDay(day);
    expect(marks.single.time.isAfter(times[0].time), isTrue);
    expect(marks.single.time.isBefore(times[1].time), isTrue);
  });

  test('night times follow Maghrib, in order, only when chosen', () async {
    final prayers = await service({
      'prayer_show_midnight': true,
      'prayer_show_last_third': true,
    });
    final day = DateTime(2026, 10, 23);
    final marks = prayers.marksForDay(day);
    expect(marks.map((m) => m.mark), [
      DayMark.sunrise,
      DayMark.midnight,
      DayMark.lastThird,
    ]);
    final maghrib = prayers
        .prayersForDay(day)
        .firstWhere((p) => p.prayer == Prayer.maghrib)
        .time;
    final nextFajr = prayers
        .prayersForDay(day.add(const Duration(days: 1)))[0]
        .time;
    final night = nextFajr.difference(maghrib);
    expect(
      marks[1].time.difference(maghrib).inMinutes,
      closeTo(night.inMinutes / 2, 1),
    );
    expect(
      marks[2].time.difference(maghrib).inMinutes,
      closeTo(night.inMinutes * 2 / 3, 1),
    );
    // Display only: the adhan schedule is unchanged.
    expect(prayers.prayersForDay(day), hasLength(5));
  });

  test('night times can be turned on and off', () async {
    final prayers = await service({});
    await prayers.setShowLastThird(true);
    expect(prayers.todaysMarks.map((m) => m.mark), [
      DayMark.sunrise,
      DayMark.lastThird,
    ]);
    await prayers.setShowLastThird(false);
    expect(prayers.todaysMarks, hasLength(1));
  });
}
