import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/services/adhan_audio.dart';
import 'package:dua_app/services/dua_progress_service.dart';
import 'package:dua_app/services/notification_service.dart';
import 'package:dua_app/services/prayer_service.dart';
import 'package:dua_app/services/sunnah_calendar_service.dart';

/// Covers the iqāmah-offset persistence added to [NotificationService], and
/// the launch-time early-out in [NotificationService.reschedule].
///
/// The plugin itself isn't available in a plain unit test (see the exclusion of
/// the notifications settings screen from test/layout_test.dart's harness), so
/// the reschedule cases watch its channel rather than its effects: what matters
/// is whether the plugin is reached at all.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('iqāmah offset defaults to "at adhan" for every prayer', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifications = NotificationService(prefs, DuaRepository());

    for (final prayer in NotificationService.notifiablePrayers) {
      expect(notifications.iqamahOffset(prayer), 0);
    }
  });

  test('a persisted offset is read back on construction', () async {
    SharedPreferences.setMockInitialValues({'notif_iqamah_isha': 20});
    final prefs = await SharedPreferences.getInstance();
    final notifications = NotificationService(prefs, DuaRepository());

    expect(notifications.iqamahOffset(Prayer.isha), 20);
    expect(notifications.iqamahOffset(Prayer.fajr), 0);
  });

  test('offset choices start at zero and are strictly increasing', () {
    final choices = NotificationService.iqamahOffsetChoices;
    expect(choices.first, 0);
    for (var i = 1; i < choices.length; i++) {
      expect(choices[i], greaterThan(choices[i - 1]));
    }
  });

  /// The launch-time early-out: whether a launch has to set the notifications
  /// plugin up at all, which is what decodes the timezone database.
  ///
  /// Tested through [NotificationService.hasReminderWork] rather than by
  /// watching the plugin channel, because the plugin cannot be initialized at
  /// all in a unit test — the very reason this path went uncovered before.
  group('reminder work at launch', () {
    Future<NotificationService> serviceWith(Map<String, Object> initial,
        {bool bindCalendar = false}) async {
      SharedPreferences.setMockInitialValues(initial);
      final prefs = await SharedPreferences.getInstance();
      final service = NotificationService(prefs, DuaRepository());
      if (bindCalendar) {
        service.bind(PrayerService(prefs), AdhanAudioService(prefs),
            DuaProgressService(prefs), SunnahCalendarService(prefs));
        addTearDown(service.dispose);
      }
      return service;
    }

    test('nothing on and nothing outstanding is nothing to do', () async {
      final service = await serviceWith({'notif_outstanding': false});
      expect(service.hasReminderWork, isFalse,
          reason: 'this is the launch that should cost nothing');
    });

    test('reminders left over from a previous run are still cleared', () async {
      final service = await serviceWith({'notif_outstanding': true});
      expect(service.hasReminderWork, isTrue);
    });

    test('an install predating the flag is not trusted to be clear', () async {
      final service = await serviceWith({});
      expect(service.hasReminderWork, isTrue,
          reason: 'reminders may have been scheduled before the flag existed');
    });

    test('any reminder being on is work, whatever the flag says', () async {
      for (final key in const [
        'notif_master_enabled',
        'notif_daily_remembrance',
      ]) {
        final service =
            await serviceWith({key: true, 'notif_outstanding': false});
        expect(service.hasReminderWork, isTrue, reason: '$key is on');
      }
    });
  });
}
