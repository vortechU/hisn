import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/dua_repository.dart';
import 'adhan_audio.dart';
import 'backup_service.dart';
import 'dua_progress_service.dart';
import 'notification_service.dart';
import 'prayer_service.dart';
import 'reminder_renewal.dart';
import 'sunnah_calendar_service.dart';

/// Runs in a short-lived engine, with no view, audio player, or GPS request.
Future<void> runReminderRenewal() async {
  WidgetsFlutterBinding.ensureInitialized();
  var success = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    await const BackupService().recoverInterruptedRestore(prefs);
    final repository = DuaRepository();
    await repository.load();
    final prayer = PrayerService(prefs, refreshDeviceLocation: false);
    final adhan = AdhanAudioService(prefs, previewEnabled: false);
    final progress = DuaProgressService(prefs);
    final calendar = SunnahCalendarService(prefs);
    final notifications = NotificationService(
      prefs,
      repository,
      background: true,
    );
    try {
      notifications.bind(prayer, adhan, progress, calendar, schedule: false);
      await notifications.reschedule();
      success = true;
    } finally {
      notifications.dispose();
      prayer.dispose();
      adhan.dispose();
      progress.dispose();
      calendar.dispose();
    }
  } catch (error) {
    debugPrint('Reminder renewal failed: $error');
  } finally {
    await ReminderRenewal.channel.invokeMethod<void>('complete', {
      'success': success,
    });
  }
}
