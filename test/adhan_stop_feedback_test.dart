import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/services/adhan_scheduler.dart';
import 'package:dua_app/widgets/adhan_playback_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  var playing = false;
  final calls = <String>[];

  setUp(() {
    playing = false;
    calls.clear();
    messenger.setMockMethodCallHandler(const MethodChannel('hisn/adhan'), (
      call,
    ) async {
      calls.add(call.method);
      if (call.method == 'stop') playing = false;
      if (call.method == 'isPlaying') return playing;
      return null;
    });
    messenger.setMockMethodCallHandler(
      const MethodChannel('hisn/adhan_playback'),
      (_) async => null,
    );
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(const MethodChannel('hisn/adhan'), null);
    messenger.setMockMethodCallHandler(
      const MethodChannel('hisn/adhan_playback'),
      null,
    );
  });

  Future<void> pushPlayback(bool value) async {
    playing = value;
    await messenger.handlePlatformMessage(
      'hisn/adhan_playback',
      const StandardMethodCodec().encodeSuccessEnvelope(value),
      (_) {},
    );
  }

  test('native state query and stop do not cancel prayer alarms', () async {
    playing = true;
    expect(await AdhanScheduler.isPlaying(), isTrue);
    await AdhanScheduler.stop();
    expect(await AdhanScheduler.isPlaying(), isFalse);
    expect(calls, ['isPlaying', 'stop', 'isPlaying']);
  });

  testWidgets(
    'native playback banner appears and Stop silences scheduled playback',
    (tester) async {
      SharedPreferences.setMockInitialValues({'app_language': 'en'});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => LocaleController(prefs),
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Expanded(child: Center(child: Text('App content'))),
                  AdhanPlaybackBanner(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.stop), findsNothing);
      await pushPlayback(true);
      await tester.pump();
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.text('Playing adhan…'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();
      expect(playing, isFalse);
      expect(find.byIcon(Icons.stop), findsNothing);
      expect(calls, contains('stop'));
      expect(calls, isNot(contains('cancelAll')));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('banner detects locked-screen playback when app is opened', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'app_language': 'ar'});
    final prefs = await SharedPreferences.getInstance();
    playing = true;
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => LocaleController(prefs),
        child: const MaterialApp(home: Scaffold(body: AdhanPlaybackBanner())),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.stop), findsOneWidget);
    expect(find.text('إيقاف الأذان'), findsOneWidget);
    await pushPlayback(false);
    await tester.pump();
    expect(find.byIcon(Icons.stop), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
