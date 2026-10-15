import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/screens/settings/notifications_settings_screen.dart';
import 'package:dua_app/screens/settings/prayer_silence_settings_screen.dart';
import 'package:dua_app/services/adhan_audio.dart';
import 'package:dua_app/services/notification_service.dart';
import 'package:dua_app/services/prayer_countdown_settings.dart';
import 'package:dua_app/services/prayer_silence_settings.dart';
import 'package:dua_app/services/sunnah_calendar_service.dart';
import 'package:dua_app/widgets/prayer_features_lifecycle.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:dua_app/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _PostingPermission extends NotificationService {
  _PostingPermission(super.prefs, super.repository);

  bool granted = false;
  int requests = 0;

  @override
  Future<bool> requestDisplayPermission() async {
    requests++;
    return granted;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late SharedPreferences prefs;
  late _PostingPermission notifications;
  late PrayerCountdownSettings countdown;
  late PrayerSilenceSettings silence;
  late List<Map<String, Object>> countdownCalls;
  late List<String> silenceCalls;
  final audioEventChannels = <String>{'xyz.luan/audioplayers.global/events'};

  setUp(() async {
    for (final name in [
      'xyz.luan/audioplayers',
      'xyz.luan/audioplayers.global',
    ]) {
      messenger.setMockMethodCallHandler(MethodChannel(name), (call) async {
        final id = (call.arguments as Map?)?['playerId'];
        if (id is String) {
          final channel = 'xyz.luan/audioplayers/events/$id';
          audioEventChannels.add(channel);
          messenger.setMockMethodCallHandler(
            MethodChannel(channel),
            (_) async => null,
          );
        }
        return null;
      });
    }
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global/events'),
      (_) async => null,
    );
    SharedPreferences.setMockInitialValues({'app_language': 'en'});
    prefs = await SharedPreferences.getInstance();
    notifications = _PostingPermission(prefs, DuaRepository());
    countdownCalls = [];
    silenceCalls = [];
    countdown = PrayerCountdownSettings(
      prefs,
      supported: true,
      bridge: (payload) async {
        countdownCalls.add(payload);
        return {'notificationsAllowed': true};
      },
    );
    silence = PrayerSilenceSettings(
      prefs,
      supported: true,
      bridge: (method, payload) async {
        silenceCalls.add(method);
        return {
          'reason': payload?['enabled'] == true ? 'permission' : 'disabled',
          'policyGranted': false,
          'exactAllowed': false,
        };
      },
    );
  });

  Widget host(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => LocaleController(prefs)),
      ChangeNotifierProvider<NotificationService>.value(value: notifications),
      ChangeNotifierProvider(create: (_) => AdhanAudioService(prefs)),
      ChangeNotifierProvider(create: (_) => SunnahCalendarService(prefs)),
      ChangeNotifierProvider<PrayerCountdownSettings>.value(value: countdown),
      ChangeNotifierProvider<PrayerSilenceSettings>.value(value: silence),
    ],
    child: MaterialApp(
      theme: AppTheme.light(AppPalettes.fallback),
      home: child,
    ),
  );

  tearDown(() {
    countdown.dispose();
    silence.dispose();
    notifications.dispose();
    for (final channel in audioEventChannels) {
      messenger.setMockMethodCallHandler(MethodChannel(channel), null);
    }
  });

  testWidgets(
    'countdown asks only on enable and preserves denied intent as off',
    (tester) async {
      await tester.pumpWidget(host(const NotificationsSettingsScreen()));
      await tester.pumpAndSettle();
      expect(notifications.requests, 0);
      expect(silenceCalls, isEmpty);
      expect(countdownCalls, isEmpty);

      final toggle = find.widgetWithText(
        SwitchListTile,
        'Next prayer countdown',
      );
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(notifications.requests, 1);
      expect(countdown.enabled, isFalse);
      expect(countdownCalls, isEmpty);

      notifications.granted = true;
      await tester.tap(toggle);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
      expect(countdown.enabled, isTrue);
      expect(countdownCalls.last['enabled'], isTrue);
      expect(notifications.masterEnabled, isFalse);
      expect(silence.enabled, isFalse);

      await tester.tap(toggle);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
      expect(notifications.requests, 2);
      expect(countdownCalls.last['enabled'], isFalse);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('silence entry opens configuration without granting access', (
    tester,
  ) async {
    await tester.pumpWidget(host(const NotificationsSettingsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Silence during prayer'));
    await tester.pumpAndSettle();
    expect(find.byType(PrayerSilenceSettingsScreen), findsOneWidget);
    expect(silence.enabled, isFalse);
    expect(silenceCalls, everyElement('update'));
    expect(notifications.requests, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'resume reconciles restored preferences without permission prompts',
    (tester) async {
      await tester.pumpWidget(
        host(const PrayerFeaturesLifecycle(child: Scaffold(body: Text('App')))),
      );
      await tester.pumpAndSettle();
      expect(countdownCalls, isEmpty);
      expect(silenceCalls, isEmpty);
      await prefs.setBool(PrayerCountdownSettings.preferenceKey, true);
      await prefs.setBool(PrayerSilenceSettings.preferenceKey, true);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
      expect(countdown.enabled, isTrue);
      expect(silence.enabled, isTrue);
      expect(countdownCalls.single['enabled'], isTrue);
      expect(silenceCalls, ['update']);
      expect(notifications.requests, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
