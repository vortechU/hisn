import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/screens/tasbih_screen.dart';
import 'package:dua_app/services/custom_dua_service.dart';
import 'package:dua_app/services/display_settings.dart';
import 'package:dua_app/services/favorites_service.dart';
import 'package:dua_app/services/tasbih_controller.dart';
import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:dua_app/widgets/arabic_text.dart';
import 'package:dua_app/widgets/dua_card.dart';
import 'package:dua_app/widgets/ornament.dart';

/// What the app's animations are allowed to do.
///
/// Two rules, both learned the hard way. **Nothing may move the text**: a card
/// that reflowed as it was marked complete lost the reader their place, and a
/// swell that pushed its neighbours would do the same thing sixty times a
/// minute on the tasbih. And **the user's reduced-motion setting is honoured**:
/// every duration in the app goes through [Motion.of], and a widget that
/// forgets it is invisible to the analyzer.
///
/// These are checked mid-flight, not just at the ends — a transition that
/// arrives in the right place having shoved the page around on the way is the
/// failure being guarded against.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DuaRepository repo;
  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = DuaRepository();
    await repo.load();
  });

  // The counts live in the store, and every test here taps: without this the
  // second test starts from wherever the first one left off.
  setUp(() async => prefs.clear());

  Widget host(Widget child, {bool reducedMotion = false}) => MultiProvider(
        providers: [
          Provider<DuaRepository>.value(value: repo),
          Provider<SharedPreferences>.value(value: prefs),
          ChangeNotifierProvider(create: (_) => TasbihController(prefs)),
          ChangeNotifierProvider(create: (_) => LocaleController(prefs)),
          ChangeNotifierProvider(create: (_) => CustomDuaService(prefs)),
          ChangeNotifierProvider(create: (_) => FavoritesService(prefs)),
          ChangeNotifierProvider(create: (_) => DisplaySettings(prefs)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppPalettes.emerald),
          locale: const Locale('en'),
          supportedLocales: LocaleController.supported,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reducedMotion),
            child: child,
          ),
        ),
      );

  group('the tasbih answers a tap', () {
    testWidgets('without moving anything around it', (tester) async {
      await tester.pumpWidget(host(const TasbihScreen()));
      await tester.pump();

      // Two fixed points either side of the counter: the phrase it is counting
      // and the line beneath it. The swell is a scale on the rosette alone, so
      // both must sit exactly where they were through every frame of it.
      final phrase = find.byType(ArabicText).first;
      final foot = find.byType(ProgressRosette);
      final before = tester.getRect(phrase);
      final plate = tester.getRect(find.byType(Scaffold));
      expect(tester.getRect(foot).size, const Size(244, 244));

      await tester.tap(foot);
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 30));
        expect(tester.getRect(phrase), before,
            reason: 'the phrase must not shift while the count swells');
        expect(tester.getRect(find.byType(Scaffold)), plate);
      }
      await tester.pumpAndSettle();

      expect(tester.getRect(phrase), before);
      expect(find.text('1'), findsOneWidget,
          reason: 'the tap should have been counted');
    });

    testWidgets('and holds still when animations are switched off',
        (tester) async {
      await tester.pumpWidget(host(const TasbihScreen(), reducedMotion: true));
      await tester.pump();

      await tester.tap(find.byType(ProgressRosette));
      await tester.pump();

      expect(find.text('1'), findsOneWidget,
          reason: 'the new figure should arrive in the very next frame');
      expect(tester.hasRunningAnimations, isFalse,
          reason: 'nothing should still be animating under reduced motion');

      // Counting also arms the home-widget refresh, on its own debounce. Let
      // it fire, or the test ends with a timer outstanding.
      await tester.pump(const Duration(milliseconds: 700));
    });
  });

  // The gilding a finished dua earns eases in over a quarter of a second. It
  // rides on the frame's rules, which grow inwards — so unless the gutter gives
  // back exactly what the rule takes, on every frame and not merely at the two
  // ends, the block inside it narrows and the text reflows mid-animation.
  testWidgets('gilding a finished dua never moves its text', (tester) async {
    final dua = repo
        .duasForCategory('morning')
        .firstWhere((d) => d.repeat > 1, orElse: () => repo.duasForCategory('morning').first);

    var count = 0;
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(host(
      StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: SingleChildScrollView(
            child: DuaCard(
              dua: dua,
              count: count,
              onCount: () => setState(() => count++),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();

    final body = find.text(dua.translationFor('en'));
    final before = tester.getRect(body);

    final tapPoint =
        tester.getTopLeft(find.byType(DuaCard)) + const Offset(40, 40);
    for (var i = 0; i < dua.repeat; i++) {
      await tester.tapAt(tapPoint);
      await tester.pump();
    }

    // Every frame of the wash, not just its end.
    for (var i = 0; i < 10; i++) {
      expect(tester.getRect(body), before,
          reason: 'the text moved ${i * 40}ms into the gilding');
      await tester.pump(const Duration(milliseconds: 40));
    }
    await tester.pumpAndSettle();
    expect(tester.getRect(body), before);
  });
}
