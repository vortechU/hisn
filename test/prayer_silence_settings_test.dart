import 'package:adhan/adhan.dart';
import 'package:dua_app/l10n/app_strings.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/screens/settings/prayer_silence_settings_screen.dart';
import 'package:dua_app/services/prayer_silence_settings.dart';
import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'off by default with Fajr fifty and Maghrib thirty minute windows',
    () async {
      SharedPreferences.setMockInitialValues({});
      final settings = PrayerSilenceSettings(
        await SharedPreferences.getInstance(),
        supported: true,
      );
      addTearDown(settings.dispose);
      expect(settings.enabled, isFalse);
      expect(settings.windowFor(Prayer.fajr).endMinutes, 50);
      expect(settings.windowFor(Prayer.maghrib).endMinutes, 30);
      expect(settings.windowFor(Prayer.maghrib).startMinutes, 0);
    },
  );

  test(
    'enable and sync never request permissions; explicit actions do',
    () async {
      SharedPreferences.setMockInitialValues({});
      final calls = <String>[];
      final settings = PrayerSilenceSettings(
        await SharedPreferences.getInstance(),
        supported: true,
        bridge: (method, args) async {
          calls.add(method);
          return {
            'reason': 'permission',
            'policyGranted': false,
            'exactAllowed': true,
          };
        },
      );
      addTearDown(settings.dispose);
      await settings.setEnabled(true);
      await settings.sync(AppStrings(AppLang.ar));
      await settings.refreshStatus();
      expect(calls, everyElement('update'));
      expect(settings.reason, 'permission');
      await settings.openPolicySettings();
      await settings.openExactAlarmSettings();
      expect(calls.sublist(calls.length - 2), [
        'openPolicySettings',
        'openExactAlarmSettings',
      ]);
    },
  );

  test(
    'invalid or corrupt windows cannot reach the native scheduler',
    () async {
      SharedPreferences.setMockInitialValues({
        'prayer_silence_fajr_start': 60,
        'prayer_silence_fajr_end': 20,
      });
      final settings = PrayerSilenceSettings(
        await SharedPreferences.getInstance(),
        supported: true,
        bridge: (_, args) async => {'reason': 'ready'},
      );
      addTearDown(settings.dispose);
      expect(settings.windowFor(Prayer.fajr).endMinutes, 50);
      expect(settings.windowFor(Prayer.fajr).enabled, isFalse);
      for (final window in [
        const PrayerSilenceWindow(startMinutes: -1),
        const PrayerSilenceWindow(startMinutes: 30, endMinutes: 30),
        const PrayerSilenceWindow(endMinutes: 181),
      ]) {
        await expectLater(
          settings.setWindow(Prayer.fajr, window),
          throwsArgumentError,
        );
      }
      await expectLater(
        settings.setWindow(Prayer.sunrise, const PrayerSilenceWindow()),
        throwsArgumentError,
      );
    },
  );

  test(
    'per-prayer choices persist and refresh reloads a backup restore',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      Map<String, Object>? payload;
      final settings = PrayerSilenceSettings(
        prefs,
        supported: true,
        bridge: (_, args) async {
          payload = args;
          return {
            'reason': 'ready',
            'policyGranted': true,
            'exactAllowed': true,
          };
        },
      );
      addTearDown(settings.dispose);
      await settings.setWindow(
        Prayer.maghrib,
        const PrayerSilenceWindow(startMinutes: 5, endMinutes: 35),
      );
      expect(prefs.getInt('prayer_silence_maghrib_start'), 5);
      expect((payload!['windows'] as Map)['maghrib'], {
        'enabled': true,
        'start': 5,
        'end': 35,
      });
      await prefs.setBool(PrayerSilenceSettings.preferenceKey, true);
      await prefs.setInt('prayer_silence_maghrib_end', 60);
      await settings.refreshStatus();
      expect(settings.enabled, isTrue);
      expect(settings.windowFor(Prayer.maghrib).endMinutes, 60);
      expect(payload!['enabled'], isTrue);
    },
  );

  test('ordered transport ends with disable after rapid changes', () async {
    SharedPreferences.setMockInitialValues({});
    final calls = <bool>[];
    final settings = PrayerSilenceSettings(
      await SharedPreferences.getInstance(),
      supported: true,
      bridge: (_, args) async {
        calls.add(args!['enabled'] as bool);
        return {'reason': 'ready'};
      },
    );
    addTearDown(settings.dispose);
    await Future.wait([settings.setEnabled(true), settings.setEnabled(false)]);
    expect(calls.last, isFalse);
  });

  test(
    'bridge errors remain visible and a later refresh can recover',
    () async {
      SharedPreferences.setMockInitialValues({});
      var fail = true;
      final settings = PrayerSilenceSettings(
        await SharedPreferences.getInstance(),
        supported: true,
        bridge: (_, args) async {
          if (fail) throw StateError('unavailable');
          return {
            'reason': 'active',
            'activeUntil': 120000,
            'policyGranted': true,
            'exactAllowed': true,
          };
        },
      );
      addTearDown(settings.dispose);
      await settings.setEnabled(true);
      expect(settings.reason, 'error');
      fail = false;
      await settings.refreshStatus();
      expect(settings.reason, 'active');
      expect(settings.activeUntil!.millisecondsSinceEpoch, 120000);
      await settings.skipCurrentWindow();
    },
  );

  test(
    'unsupported platforms never invoke Android or enable the feature',
    () async {
      SharedPreferences.setMockInitialValues({});
      final settings = PrayerSilenceSettings(
        await SharedPreferences.getInstance(),
        supported: false,
        bridge: (_, args) async => throw StateError('must not invoke'),
      );
      addTearDown(settings.dispose);
      await settings.setEnabled(true);
      await settings.openPolicySettings();
      await settings.sync(AppStrings(AppLang.en));
      expect(settings.enabled, isFalse);
      expect(settings.reason, 'unsupported');
    },
  );

  for (final lang in AppLang.values) {
    testWidgets('silence settings fit narrow large-text ${lang.name}', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'prayer_silence_enabled': true});
      final prefs = await SharedPreferences.getInstance();
      final settings = PrayerSilenceSettings(
        prefs,
        supported: true,
        bridge: (_, args) async => {
          'reason': 'permission',
          'policyGranted': false,
          'exactAllowed': false,
        },
      );
      addTearDown(settings.dispose);
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider(
              create: (_) => LocaleController(prefs)..setLang(lang),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(AppPalettes.emerald),
            locale: Locale(lang.name),
            supportedLocales: LocaleController.supported,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.6)),
              child: child!,
            ),
            home: const PrayerSilenceSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.fling(find.byType(ListView), const Offset(0, -1500), 3000);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
