import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dua_app/services/reminder_renewal.dart';
import 'package:dua_app/services/reminder_renewal_runner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const notifications = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  const adhan = MethodChannel('hisn/adhan');
  const timezone = MethodChannel('flutter_timezone');
  const forbidden = [
    MethodChannel('flutter.baseflow.com/geolocator_android'),
    MethodChannel('flutter.baseflow.com/geolocator'),
    MethodChannel('xyz.luan/audioplayers'),
    MethodChannel('xyz.luan/audioplayers.global'),
  ];
  late List<MethodCall> scheduled;
  late List<MethodCall> renewal;
  late List<MethodCall> playback;
  late List<String> unexpected;
  var failScheduling = false;

  setUp(() {
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    scheduled = [];
    renewal = [];
    playback = [];
    unexpected = [];
    failScheduling = false;
    messenger.setMockMethodCallHandler(timezone, (_) async => 'Asia/Riyadh');
    messenger.setMockMethodCallHandler(notifications, (call) async {
      if (call.method == 'canScheduleExactNotifications' ||
          call.method == 'initialize') {
        return true;
      }
      if (call.method == 'zonedSchedule') {
        if (failScheduling) throw PlatformException(code: 'schedule_failed');
        scheduled.add(call);
      }
      if (call.method == 'getNotificationAppLaunchDetails') {
        unexpected.add('notification launch handling');
      }
      return null;
    });
    messenger.setMockMethodCallHandler(ReminderRenewal.channel, (call) async {
      renewal.add(call);
      return null;
    });
    messenger.setMockMethodCallHandler(adhan, (call) async {
      playback.add(call);
      return null;
    });
    for (final channel in forbidden) {
      messenger.setMockMethodCallHandler(channel, (call) async {
        unexpected.add('${channel.name}:${call.method}');
        return null;
      });
    }
  });

  tearDown(() {
    for (final channel in [
      notifications,
      adhan,
      timezone,
      ReminderRenewal.channel,
      ...forbidden,
    ]) {
      messenger.setMockMethodCallHandler(channel, null);
    }
  });

  const saved = <String, Object>{
    'prayer_gps_lat': 24.7136,
    'prayer_gps_lng': 46.6753,
    'prayer_gps_label': 'Riyadh',
    'notif_master_enabled': true,
    'notif_daily_remembrance': true,
    'notif_fasting_reminders': true,
    'adhan_sound_enabled': true,
    'app_language': 'ar',
  };

  test(
    'headless renewal rebuilds reminders and adhan from saved GPS without a fix or player',
    () async {
      SharedPreferences.setMockInitialValues(saved);
      await runReminderRenewal();
      expect(scheduled.length, greaterThan(10));
      expect(playback.single.method, 'schedule');
      final alarms = (playback.single.arguments as Map)['alarms'] as List;
      expect(alarms, isNotEmpty);
      expect(
        alarms.every(
          (a) => (a as Map)['at'] > DateTime.now().millisecondsSinceEpoch,
        ),
        isTrue,
      );
      expect((renewal.first.arguments as Map)['enabled'], isTrue);
      expect(renewal.last.method, 'complete');
      expect((renewal.last.arguments as Map)['success'], isTrue);
      expect(unexpected, isEmpty);
    },
  );

  test(
    'disabled reminders cancel renewal without initializing notification or audio plugins',
    () async {
      SharedPreferences.setMockInitialValues({'notif_outstanding': false});
      await runReminderRenewal();
      expect(scheduled, isEmpty);
      expect(playback, isEmpty);
      expect((renewal.first.arguments as Map)['enabled'], isFalse);
      expect((renewal.last.arguments as Map)['success'], isTrue);
      expect(unexpected, isEmpty);
    },
  );

  test(
    'partial scheduling reports failure so Android retries renewal',
    () async {
      SharedPreferences.setMockInitialValues(saved);
      failScheduling = true;
      await runReminderRenewal();
      expect((renewal.last.arguments as Map)['success'], isFalse);
      expect(unexpected, isEmpty);
    },
  );
}
