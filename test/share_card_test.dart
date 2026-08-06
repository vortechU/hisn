import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/data/quran_repository.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/models/shareable.dart';
import 'package:dua_app/screens/share_sheet.dart';
import 'package:dua_app/services/display_settings.dart';
import 'package:dua_app/services/share_io.dart';
import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:dua_app/widgets/share_card.dart';

/// The PNG signature. A capture that returns something else isn't an image.
const _pngMagic = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget host(Widget child, {double textScale = 1.0}) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocaleController(prefs)),
          ChangeNotifierProvider(create: (_) => DisplaySettings(prefs)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppPalettes.fallback),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(body: Center(child: child)),
          ),
        ),
      );

  Widget sheetHost(Widget child) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocaleController(prefs)),
          ChangeNotifierProvider(create: (_) => DisplaySettings(prefs)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(AppPalettes.fallback),
          home: Scaffold(body: child),
        ),
      );

  const passage = Shareable(
    arabic: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
    reference: 'Al-Fatihah 1:1',
    title: 'Al-Fatihah',
    transliteration: 'Bismi-llahi r-rahmani r-rahim',
    translation: 'In the name of Allah, the Most Gracious, the Most Merciful.',
  );

  group('Shareable', () {
    test('the text form always ends in the source', () {
      expect(passage.asText(), endsWith('— Al-Fatihah 1:1'));
      expect(passage.asText(), startsWith(passage.arabic));
    });

    test('optional lines are omitted rather than left blank', () {
      const bare = Shareable(arabic: 'ٱللَّٰه', reference: 'Muslim 2137');
      final text = bare.asText();
      expect(text, 'ٱللَّٰه\n\n— Muslim 2137');
      // No stray blank runs where a missing line used to be.
      expect(text, isNot(contains('\n\n\n')));
    });

    test('a verse carries no transliteration or translation', () async {
      // The app ships neither for the Qur'an; the card must not imply it does.
      final quran = QuranRepository();
      await quran.loadIndex();
      final verse = await quran.verse(112, 1);
      final shareable = Shareable.verse(verse!);

      expect(shareable.transliteration, isNull);
      expect(shareable.translation, isNull);
      expect(shareable.arabic, isNotEmpty);
      expect(shareable.reference, contains('112:1'));
      expect(shareable.asText(), endsWith(shareable.reference));
    });

    test('a dua keeps its repeat count and drops empty fields', () async {
      final repo = DuaRepository();
      await repo.load();
      final dua = repo.duasForCategory('morning').first;
      final shareable = Shareable.dua(dua, 'en');

      expect(shareable.arabic, dua.arabic);
      expect(shareable.reference, dua.reference);
      expect(shareable.repeat, dua.repeat);
      // Empty strings would render as a gap in the card, so they become null.
      expect(shareable.transliteration, isNot(''));
      expect(shareable.translation, isNot(''));
    });
  });

  group('ShareCard', () {
    testWidgets('is exactly the declared width, whatever the text scale',
        (tester) async {
      // The whole point of the fixed width: the image must not change size
      // because the reader turned their system font up.
      for (final scale in [1.0, 1.5, 2.0]) {
        await tester.pumpWidget(
            host(const ShareCard(passage: passage), textScale: scale));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.getSize(find.byType(ShareCard)).width, ShareCard.width,
            reason: 'at text scale $scale');
      }
    });

    testWidgets('renders the source, and does not overflow', (tester) async {
      await tester.pumpWidget(host(const ShareCard(passage: passage)));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Al-Fatihah 1:1'), findsOneWidget);
      expect(find.text(passage.arabic), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('capture', () {
    testWidgets('produces a PNG at the capture ratio', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(host(
        RepaintBoundary(key: key, child: const ShareCard(passage: passage)),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      final size = tester.getSize(find.byType(ShareCard));

      // toImage hands work to the engine, so it needs real async time.
      late final ({int? width, int? height, List<int>? head}) captured;
      await tester.runAsync(() async {
        final (png, error) = await const ShareIo().capture(key);
        expect(error, isNull);
        expect(png, isNotNull);
        final decoded = await decodeImageFromList(png!);
        captured = (
          width: decoded.width,
          height: decoded.height,
          head: png.take(8).toList(),
        );
      });

      expect(captured.head, _pngMagic);
      // 360 logical × 3 = 1080, the size the card was designed to land on.
      expect(captured.width, (size.width * ShareIo.pixelRatio).round());
      expect(captured.height, (size.height * ShareIo.pixelRatio).round());
    });

    testWidgets('reports notReady for a key attached to nothing',
        (tester) async {
      await tester.pumpWidget(host(const SizedBox()));
      final (png, error) = await const ShareIo().capture(GlobalKey());
      expect(png, isNull);
      expect(error, ShareCaptureError.notReady);
    });
  });

  // The failure the user actually sees when any of this goes wrong is a
  // spinner that never stops: the app looks hung, and whatever really broke is
  // hidden behind it. These pin the recovery, not the cause.
  group('the preview sheet always comes back', () {
    testWidgets('when the rasteriser reports failure, it falls back to text',
        (tester) async {
      final io = _FailingIo();
      await tester.pumpWidget(
          sheetHost(SharePreviewSheet(passage: passage, io: io)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Share card'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(io.textShared, isTrue, reason: 'the passage should still go out');
      // The symptom the user reported: a spinner that never stopped. The
      // buttons must come back whether or not the picture could be made.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull, reason: 'the button must re-enable');
    });

  });
}

/// Capture fails the way a real device would: politely, with a reason.
class _FailingIo extends ShareIo {
  _FailingIo();

  bool textShared = false;

  @override
  Future<(Uint8List?, ShareCaptureError?)> capture(GlobalKey key) async =>
      (null, ShareCaptureError.unsupported);

  @override
  Future<bool> shareText(Shareable passage, {ui.Rect? origin}) async {
    textShared = true;
    return true;
  }

  @override
  Future<bool> shareImage(Uint8List png,
          {required Shareable passage, ui.Rect? origin}) async =>
      throw StateError('should not be reached');
}
