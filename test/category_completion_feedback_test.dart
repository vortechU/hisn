import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/services/display_settings.dart';
import 'package:dua_app/services/dua_progress_service.dart';
import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:dua_app/widgets/category_card.dart';
import 'package:dua_app/widgets/ornament.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DuaRepository repository;

  setUpAll(() async {
    repository = DuaRepository();
    await repository.load();
  });

  for (final brightness in Brightness.values) {
    for (final id in ['morning', 'evening', 'after_salah', 'sleep', 'waking']) {
      testWidgets('$id tile reflects all daily counts in $brightness',
          (tester) async {
        SharedPreferences.setMockInitialValues({'app_language': 'ar'});
        final prefs = await SharedPreferences.getInstance();
        final progress = DuaProgressService(prefs);
        final duas = repository.duasForCategory(id);
        expect(duas, isNotEmpty);
        await tester.pumpWidget(MultiProvider(
          providers: [
            Provider<DuaRepository>.value(value: repository),
            ChangeNotifierProvider<DuaProgressService>.value(value: progress),
            ChangeNotifierProvider(create: (_) => LocaleController(prefs)),
            ChangeNotifierProvider(create: (_) => DisplaySettings(prefs)),
          ],
          child: MaterialApp(
            theme: brightness == Brightness.dark
                ? AppTheme.dark(AppPalettes.fallback)
                : AppTheme.light(AppPalettes.fallback),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: id == 'morning' ? 320 : 170,
                  height: 190,
                  child: CategoryCard(
                    category: repository.categoryById(id)!,
                    count: duas.length,
                    featured: id == 'morning',
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ));
        JadwalFrame frame() => tester.widget<JadwalFrame>(find.byType(JadwalFrame));
        expect(frame().background, isNull);
        for (final dua in duas.take(duas.length - 1)) {
          progress.setCount(dua.id, dua.repeat);
        }
        // A count below the last dua's repetition target cannot finish a tile.
        progress.setCount(duas.last.id, duas.last.repeat - 1);
        await tester.pumpAndSettle();
        expect(frame().background, isNull);
        expect(find.byIcon(Icons.check_circle_outline), findsNothing);
        progress.setCount(duas.last.id, duas.last.repeat);
        await tester.pumpAndSettle();
        expect(frame().background, isNotNull);
        expect(frame().emphasis, isTrue);
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
        final background = frame().background!;
        final context = tester.element(find.byType(CategoryCard));
        final foreground = Theme.of(context).colorScheme.onSurface;
        final a = background.computeLuminance();
        final b = foreground.computeLuminance();
        final contrast = a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05);
        expect(contrast, greaterThanOrEqualTo(4.5));
        progress.resetDuas(duas.map((dua) => dua.id));
        await tester.pumpAndSettle();
        expect(frame().background, isNull);
        expect(find.byIcon(Icons.check_circle_outline), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
