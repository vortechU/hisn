import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/services/notification_service.dart';

/// Covers the iqāmah-offset persistence added to [NotificationService].
/// Doesn't exercise [NotificationService.reschedule] — like the rest of this
/// service, that touches the notifications plugin channel, which isn't
/// available in a plain unit test (see the exclusion of the notifications
/// settings screen from test/layout_test.dart's harness).
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
}
