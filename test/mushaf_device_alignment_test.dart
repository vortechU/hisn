import 'dart:io';
import 'dart:ui' as ui;

import 'package:dua_app/data/quran_repository.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/screens/mushaf_screen.dart';
import 'package:dua_app/services/display_settings.dart';
import 'package:dua_app/services/quran_service.dart';
import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late QuranRepository repo;
  late SharedPreferences prefs;
  const capture = bool.fromEnvironment('CAPTURE_ALIGNMENT');
  const boundaryKey = ValueKey('mushaf-device-preview');

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
          (_) async =>
              const StandardMessageCodec().encodeMessage(<Object?>[null]),
        );
    SharedPreferences.setMockInitialValues({'app_language': 'en'});
    prefs = await SharedPreferences.getInstance();
    repo = QuranRepository();
    await repo.loadIndex();
    await Future.wait([for (var p = 149; p <= 153; p++) repo.loadPage(p)]);
    for (final (family, asset) in [
      ('Amiri', 'assets/fonts/Amiri-Regular.ttf'),
      ('Crimson Pro', 'assets/fonts/latin/CrimsonPro-Regular.ttf'),
      ('Karla', 'assets/fonts/latin/Karla-Regular.ttf'),
      ('QCF4_Hafs_01', 'assets/fonts/quran/QCF4_Hafs_01.ttf'),
      ('QCF4_Hafs_12', 'assets/fonts/quran/QCF4_Hafs_12.ttf'),
      ('QCF4_QBSML', 'assets/fonts/quran/QCF4_QBSML.ttf'),
    ]) {
      await (FontLoader(family)..addFont(rootBundle.load(asset))).load();
    }
  });

  for (final dpr in [2.0, 2.75, 3.0]) {
    for (final scale in [1.0, 1.3, 1.5]) {
      testWidgets('page 151 stays aligned at DPR $dpr, text scale $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = dpr;
        tester.view.physicalSize = const Size(1080, 2400);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final quran = QuranService(prefs);
        addTearDown(quran.dispose);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<QuranRepository>.value(value: repo),
              ChangeNotifierProvider<QuranService>.value(value: quran),
              ChangeNotifierProvider(create: (_) => LocaleController(prefs)),
              ChangeNotifierProvider(create: (_) => DisplaySettings(prefs)),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: const Locale('en'),
              supportedLocales: LocaleController.supported,
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              theme: AppTheme.dark(AppPalettes.fallback),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  padding: const EdgeInsets.only(top: 24, bottom: 24),
                  viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
                ),
                child: RepaintBoundary(key: boundaryKey, child: child!),
              ),
              home: const MushafScreen(startPage: 151),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final page = repo.pageIfCached(151)!;
        final bodyGlyph = page.lines[2].map((w) => w.glyph).toSet();
        final body = find.byWidgetPredicate(
          (w) =>
              w is RichText && bodyGlyph.every(w.text.toPlainText().contains),
        );
        expect(body, findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(body);
        final painter = TextPainter(
          text: paragraph.text,
          textDirection: paragraph.textDirection,
          textScaler: paragraph.textScaler,
          maxLines: 1,
        )..layout();
        final width = painter.width;
        painter.dispose();
        if (capture) {
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(boundaryKey),
            );
            final image = await boundary.toImage(pixelRatio: 1.5);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory('build/mushaf-alignment').create(recursive: true);
            await File(
              'build/mushaf-alignment/dpr-$dpr-scale-$scale.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        expect(tester.takeException(), isNull);
        expect(
          width,
          lessThanOrEqualTo(paragraph.size.width + 1),
          reason: 'Quran ink must fit inside its line slot',
        );
        final viewportWidth = 1080 / dpr;
        expect(tester.getRect(body).center.dx, closeTo(viewportWidth / 2, 0.1));

        // The screenshot also shows the neighbouring frame. A settled swipe
        // must leave one complete frame centred on the viewport.
        final controller = tester
            .widget<PageView>(find.byType(PageView))
            .controller!;
        for (final direction in [-1.0, 1.0]) {
          await tester.drag(
            find.byType(PageView),
            Offset(direction * viewportWidth * 0.7, 0),
          );
          await tester.pumpAndSettle();
          expect(
            controller.page,
            closeTo(controller.page!.roundToDouble(), 0.001),
          );
          final frames = find.byWidgetPredicate((w) {
            if (w is! Container || w.decoration is! BoxDecoration) return false;
            final decoration = w.decoration! as BoxDecoration;
            return decoration.border is Border &&
                (decoration.border! as Border).top.width == Ms.stroke;
          });
          final visibleFrames = tester
              .elementList(frames)
              .map((e) {
                final box = e.renderObject! as RenderBox;
                return box.localToGlobal(Offset.zero) & box.size;
              })
              .where(
                (rect) => rect.center.dx > 0 && rect.center.dx < viewportWidth,
              );
          expect(visibleFrames, hasLength(1));
          expect(
            visibleFrames.single.center.dx,
            closeTo(viewportWidth / 2, 0.1),
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('enlarged system text keeps the painted rosette tappable', (
    tester,
  ) async {
    final page = repo.pageIfCached(151)!;
    String? chosen;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(
            body: mushafPageBody(
              page: page,
              keys: repo.ayahKeysOnPage(151),
              onAyah: (key) => chosen = key,
            ),
          ),
        ),
      ),
    );
    final words = page.lines[2];
    final glyphs = words.map((w) => w.glyph).toSet();
    final line = find.byWidgetPredicate(
      (w) => w is RichText && glyphs.every(w.text.toPlainText().contains),
    );
    final paragraph = tester.renderObject<RenderParagraph>(line);
    final painter = TextPainter(
      text: paragraph.text,
      textDirection: paragraph.textDirection,
      textScaler: paragraph.textScaler,
      maxLines: 1,
    )..layout();
    final displayIndex = words.length - 1 - words.indexWhere((w) => w.isEnd);
    final rosette = painter
        .getBoxesForSelection(
          TextSelection(
            baseOffset: displayIndex,
            extentOffset: displayIndex + 1,
          ),
        )
        .single
        .toRect();
    final offset = Offset(
      (paragraph.size.width - painter.width) / 2,
      (paragraph.size.height - painter.height) / 2,
    );
    await tester.tapAt(tester.getTopLeft(line) + offset + rosette.center);
    await tester.pump();
    expect(chosen, '7:1');
    painter.dispose();
    expect(tester.takeException(), isNull);
  });
}
