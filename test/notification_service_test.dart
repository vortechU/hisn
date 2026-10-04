import 'package:adhan/adhan.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/services/adhan_audio.dart';
import 'package:dua_app/services/dua_progress_service.dart';
import 'package:dua_app/services/notification_service.dart';
import 'package:dua_app/services/prayer_service.dart';
import 'package:dua_app/services/prayer_settings.dart';
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

  /// What gets handed to the OS, worked out without the OS.
  ///
  /// [NotificationService.bind] fires on every dua counted, and a reschedule
  /// that re-sends the whole window is a cancel and some fifty alarms. So it is
  /// only sent when the plan has changed — which makes it matter that the plan
  /// changes exactly when it should.
  group('the reminder plan', () {
    late DuaRepository repo;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    // The adhan preview player is built with its service, and reaches for its
    // plugin as it is; the plan only reads whether the adhan is on.
    const audioChannels = [
      MethodChannel('xyz.luan/audioplayers.global'),
      MethodChannel('xyz.luan/audioplayers'),
    ];

    setUpAll(() async {
      repo = DuaRepository();
      await repo.load();
      for (final channel in audioChannels) {
        messenger.setMockMethodCallHandler(channel, (_) async => null);
      }
    });

    tearDownAll(() {
      for (final channel in audioChannels) {
        messenger.setMockMethodCallHandler(channel, null);
      }
    });

    /// Every kind of reminder on, the adhan with them, one iqāmah delay, in
    /// a fixed city — as much as the plan can hold.
    Future<(NotificationService, DuaProgressService)> everythingOn() async {
      SharedPreferences.setMockInitialValues({
        'notif_master_enabled': true,
        'notif_daily_remembrance': true,
        'notif_fasting_reminders': true,
        'adhan_sound_enabled': true,
        'notif_iqamah_isha': 15,
        'prayer_location_mode': LocationMode.manual.name,
        'prayer_lat': 31.9539,
        'prayer_lng': 35.9106,
        'prayer_location_label': 'Amman',
      });
      final prefs = await SharedPreferences.getInstance();
      final progress = DuaProgressService(prefs);
      final service = NotificationService(prefs, repo)
        ..bind(PrayerService(prefs), AdhanAudioService(prefs), progress,
            SunnahCalendarService(prefs));
      // bind's debounce would reach for the plugin, which a unit test lacks.
      addTearDown(service.dispose);
      return (service, progress);
    }

    /// A minute past midnight today: the whole of today's window still ahead.
    DateTime earlyToday() {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, 0, 1);
    }

    test('holds every kind of reminder that is on', () async {
      final (service, _) = await everythingOn();
      final plan = service.planAt(earlyToday(), exact: true);

      final prayers = plan.reminders.where((r) => r.adhan != null);
      expect(prayers, hasLength(15), reason: 'five prayers, three days');
      expect(plan.adhanOn, isTrue);
      expect(plan.reminders.where((r) => r.payload == 'adhkar:morning'),
          isNotEmpty);
      expect(plan.reminders.where((r) => r.payload == 'adhkar:evening'),
          isNotEmpty);
      // The iqāmah delay moves the reminder, not the adhan.
      final isha = prayers.firstWhere((r) => r.adhan!.fajr == false &&
          r.at.difference(r.adhan!.time) != Duration.zero);
      expect(isha.at.difference(isha.adhan!.time),
          const Duration(minutes: 15));
    });

    test('counting a dua that leaves its set unfinished changes nothing',
        () async {
      final (service, progress) = await everythingOn();
      final now = earlyToday();
      final before = service.planAt(now, exact: true);

      final morning = repo.duasForCategory('morning')
          .firstWhere((d) => d.repeat > 1 && d.repeat < 100);
      progress.setCount(morning.id, 1);

      expect(service.planAt(now, exact: true), before,
          reason: 'this is the tap that should cost nothing');
    });

    test('finishing the morning set drops today\'s morning reminders, '
        'and nothing else', () async {
      final (service, progress) = await everythingOn();
      final now = earlyToday();
      final before = service.planAt(now, exact: true);

      for (final dua in repo.duasForCategory('morning')) {
        progress.setCount(dua.id, dua.repeat);
      }
      final after = service.planAt(now, exact: true);

      final dropped =
          before.reminders.toSet().difference(after.reminders.toSet());
      expect(dropped, isNotEmpty);
      for (final reminder in dropped) {
        expect(reminder.payload, 'adhkar:morning');
        expect(reminder.at.day, now.day, reason: 'tomorrow starts afresh');
      }
      expect(after.reminders.toSet().difference(before.reminders.toSet()),
          isEmpty);
    });

    test('a reminder having fired since is no reason to schedule again',
        () async {
      // The whole of the skip rests on this: a plan made now must equal the
      // plan made earlier today, less whatever has fired in between. Walked
      // through the day so every prayer, ping and reminder passes once.
      final (service, _) = await everythingOn();
      final start = earlyToday();
      final first = service.planAt(start, exact: true);

      for (var minutes = 15; minutes < 24 * 60 - 2; minutes += 15) {
        final later = start.add(Duration(minutes: minutes));
        if (later.day != start.day) break; // a short day, at a DST change
        expect(service.planAt(later, exact: true), first.after(later),
            reason: 'at ${later.hour}:${later.minute}');
      }
    });

    test('an adhan that has sounded is not set again', () async {
      // Isha with a fifteen-minute iqāmah delay: for those fifteen minutes the
      // reminder is still to come, but the adhan is not. Setting its alarm then
      // would play it the moment it was set — a second adhan, late.
      final (service, _) = await everythingOn();
      final plan = service.planAt(earlyToday(), exact: true);
      final isha = plan.reminders.firstWhere((r) =>
          r.adhan != null && r.at.isAfter(r.adhan!.time));
      final between = isha.adhan!.time.add(const Duration(minutes: 1));

      final replanned = service.planAt(between, exact: true);
      final stillOwed = replanned.reminders.firstWhere((r) => r.id == isha.id);
      expect(stillOwed.at, isha.at);
      expect(stillOwed.adhan, isNull);
      // And the earlier plan, read at that moment, says the same.
      expect(plan.after(between), replanned);
    });

    test('whether alarms may be exact is part of what was scheduled', () async {
      final (service, _) = await everythingOn();
      final now = earlyToday();
      expect(service.planAt(now, exact: true),
          isNot(service.planAt(now, exact: false)));
    });

    test('nothing on plans nothing', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = NotificationService(prefs, repo)
        ..bind(PrayerService(prefs), AdhanAudioService(prefs),
            DuaProgressService(prefs), SunnahCalendarService(prefs));
      addTearDown(service.dispose);

      final plan = service.planAt(earlyToday(), exact: true);
      expect(plan.reminders, isEmpty);
      expect(plan.adhanOn, isFalse);
    });
  });
}
