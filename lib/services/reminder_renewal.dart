import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android owns the wakeup; the same Dart planner used in the foreground owns
/// every reminder rule, translation, iqamah delay, and fasting date.
class ReminderRenewal {
  static const channel = MethodChannel('hisn/reminder_renewal');

  static Future<void> configure(bool enabled) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await channel.invokeMethod<void>('configure', {'enabled': enabled});
    } on MissingPluginException {
      // Widget tests and platform previews have no Android job scheduler.
    }
  }
}
