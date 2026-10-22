import 'dart:async';

import 'package:dua_app/l10n/app_strings.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/services/prayer_countdown_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> preferences([
    Map<String, Object> initial = const {},
  ]) {
    SharedPreferences.setMockInitialValues(initial);
    return SharedPreferences.getInstance();
  }

  test(
    'countdown is opt in and unsupported platforms do not call native',
    () async {
      final prefs = await preferences();
      var calls = 0;
      final settings = PrayerCountdownSettings(
        prefs,
        supported: false,
        bridge: (_) async {
          calls++;
          return null;
        },
      );
      addTearDown(settings.dispose);
      expect(settings.enabled, false);
      await settings.setEnabled(true);
      await settings.sync(AppStrings(AppLang.en));
      await settings.refresh();
      expect(settings.enabled, false);
      expect(calls, 0);
    },
  );

  test(
    'enable persists opt in, denied notification permission keeps the choice',
    () async {
      final prefs = await preferences();
      final calls = <Map<String, Object>>[];
      final settings = PrayerCountdownSettings(
        prefs,
        supported: true,
        bridge: (payload) async {
          calls.add(payload);
          return {'notificationsAllowed': false};
        },
      );
      addTearDown(settings.dispose);
      await settings.setEnabled(true);
      expect(settings.enabled, true);
      expect(prefs.getBool(PrayerCountdownSettings.preferenceKey), true);
      expect(settings.notificationsAllowed, false);
      expect(calls.single['enabled'], true);
      // Native checks permission; this API never opens an exact-alarm prompt.
      expect(
        calls.single.keys,
        unorderedEquals([
          'enabled',
          'titlePrefix',
          'remainingLabel',
          'sinceLabel',
          'channelName',
          'channelDescription',
        ]),
      );
    },
  );

  test(
    'resume retries unchanged configuration after a permission grant',
    () async {
      final prefs = await preferences({
        PrayerCountdownSettings.preferenceKey: true,
      });
      var allowed = false;
      var calls = 0;
      final settings = PrayerCountdownSettings(
        prefs,
        supported: true,
        bridge: (_) async {
          calls++;
          return {'notificationsAllowed': allowed};
        },
      );
      addTearDown(settings.dispose);
      await settings.refresh();
      expect(settings.notificationsAllowed, false);
      allowed = true;
      await settings.refresh();
      expect(calls, 2);
      expect(settings.notificationsAllowed, true);
    },
  );

  test(
    'unchanged locale is deduplicated and a language change is pushed',
    () async {
      final prefs = await preferences();
      final calls = <Map<String, Object>>[];
      final settings = PrayerCountdownSettings(
        prefs,
        supported: true,
        bridge: (payload) async {
          calls.add(payload);
          return {'notificationsAllowed': true};
        },
      );
      addTearDown(settings.dispose);
      await settings.sync(AppStrings(AppLang.ar));
      await settings.sync(AppStrings(AppLang.ar));
      await settings.sync(AppStrings(AppLang.ur));
      expect(calls, hasLength(2));
      expect(
        calls[0]['channelName'],
        AppStrings(AppLang.ar).prayerCountdownTitle,
      );
      expect(
        calls[1]['channelName'],
        AppStrings(AppLang.ur).prayerCountdownTitle,
      );
    },
  );

  test(
    'rapid enable then disable completes in order and stays disabled',
    () async {
      final prefs = await preferences();
      final entered = Completer<void>();
      final release = Completer<void>();
      final calls = <bool>[];
      final settings = PrayerCountdownSettings(
        prefs,
        supported: true,
        bridge: (payload) async {
          calls.add(payload['enabled'] as bool);
          if (calls.length == 1) {
            entered.complete();
            await release.future;
          }
          return {'notificationsAllowed': true};
        },
      );
      addTearDown(settings.dispose);
      final enabling = settings.setEnabled(true);
      await entered.future;
      final disabling = settings.setEnabled(false);
      release.complete();
      await Future.wait([enabling, disabling]);
      expect(calls, [true, false]);
      expect(settings.enabled, false);
      expect(prefs.getBool(PrayerCountdownSettings.preferenceKey), false);
    },
  );

  test('failed transport retries on the next synchronization', () async {
    final prefs = await preferences();
    var attempts = 0;
    final settings = PrayerCountdownSettings(
      prefs,
      supported: true,
      bridge: (_) async {
        if (++attempts == 1) throw StateError('transport unavailable');
        return {'notificationsAllowed': true};
      },
    );
    addTearDown(settings.dispose);
    await settings.setEnabled(true);
    await settings.sync(AppStrings(AppLang.en));
    expect(attempts, 2);
    expect(settings.enabled, true);
    expect(settings.notificationsAllowed, true);
  });

  test(
    'refresh reloads a restored disabled preference and cancels native',
    () async {
      final prefs = await preferences({
        PrayerCountdownSettings.preferenceKey: true,
      });
      final calls = <Map<String, Object>>[];
      final settings = PrayerCountdownSettings(
        prefs,
        supported: true,
        bridge: (payload) async {
          calls.add(payload);
          return {'notificationsAllowed': true};
        },
      );
      addTearDown(settings.dispose);
      await settings.refresh();
      await prefs.setBool(PrayerCountdownSettings.preferenceKey, false);
      await settings.refresh();
      expect(settings.enabled, false);
      expect(calls.last['enabled'], false);
    },
  );

  test(
    'disposing while native is pending does not notify disposed listeners',
    () async {
      final prefs = await preferences();
      final entered = Completer<void>();
      final release = Completer<void>();
      final settings = PrayerCountdownSettings(
        prefs,
        supported: true,
        bridge: (_) async {
          entered.complete();
          await release.future;
          return {'notificationsAllowed': true};
        },
      );
      final pending = settings.setEnabled(true);
      await entered.future;
      settings.dispose();
      release.complete();
      await pending;
      expect(settings.notificationsAllowed, isNull);
    },
  );
}
