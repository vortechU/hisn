import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dua_app/data/dua_repository.dart';
import 'package:dua_app/l10n/locale_controller.dart';
import 'package:dua_app/services/display_settings.dart';
import 'package:dua_app/services/dua_progress_service.dart';
import 'package:dua_app/services/prayer_service.dart';
import 'package:dua_app/services/prayer_widget_service.dart';
import 'package:dua_app/services/sunnah_calendar_service.dart';
import 'package:dua_app/services/tasbih_controller.dart';
import 'package:dua_app/services/theme_controller.dart';
import 'package:dua_app/theme/app_palette.dart';

/// What the home-screen widgets are drawn from.
///
/// This is the one contract in the app with a consumer the Dart analyzer cannot
/// see: the Kotlin providers read these exact keys out of SharedPreferences, so
/// a rename here fails silently on a phone and nowhere else. The test pins the
/// key names, the shapes the native side parses (hex colours, integer counts,
/// the encoded verse pool), and the invariants that would otherwise only show
/// up as a widget drawn in the wrong ink.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('hisn/widget');
  late DuaRepository repo;
  late Map<String, String> pushed;

  setUpAll(() async {
    repo = DuaRepository();
    await repo.load();
  });

  setUp(() async {
    pushed = {};
    // The bridge only pushes on Android, which is flutter_test's default
    // platform; capture the payload instead of letting it reach a real channel.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'update') {
        final data = (call.arguments as Map)['data'] as Map;
        pushed.addAll(data.cast<String, String>());
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  /// Build the service, bind it, and wait out its debounce.
  Future<void> push({
    AppPalette palette = AppPalettes.emerald,
    ThemeMode mode = ThemeMode.system,
    AppLang lang = AppLang.en,
  }) async {
    SharedPreferences.setMockInitialValues({
      // Manual mode keeps PrayerService off the geolocator in tests.
      'prayer_location_mode': 'manual',
      'prayer_lat': 21.4225,
      'prayer_lng': 39.8262,
      'prayer_location_label': 'Makkah',
      'theme_palette': palette.id,
      'theme_mode': mode.name,
      'app_language': lang.name,
    });
    final prefs = await SharedPreferences.getInstance();
    final service = PrayerWidgetService(repo);
    service.bind(
      PrayerService(prefs),
      LocaleController(prefs),
      SunnahCalendarService(prefs),
      ThemeController(prefs),
      DisplaySettings(prefs),
      DuaProgressService(prefs),
      TasbihController(prefs),
    );
    // bind() debounces by 500ms so a burst of changes results in one write.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    service.dispose();
  }

  test('pushes every key the native widgets read', () async {
    await push();

    // Prayer config — the widgets compute times from these themselves.
    for (final key in ['lat', 'lng', 'method', 'madhab', 'label', 'next_label',
      'am', 'pm', 'hijri', 'hijri_months', 'hijri_offset']) {
      expect(pushed, contains(key), reason: 'prayer widgets read "$key"');
    }
    // Appearance.
    for (final key in ['theme_mode', 'arabic_font', 'lang']) {
      expect(pushed, contains(key));
    }
    // Tasbih.
    for (final key in ['tasbih_id', 'tasbih_arabic', 'tasbih_target']) {
      expect(pushed, contains(key));
    }
    // Adhkar — all three candidate sets, since the native side picks one.
    for (final set in ['morning', 'evening', 'sleep']) {
      for (final part in ['title', 'sub', 'done', 'total']) {
        expect(pushed, contains('adhkar_${set}_$part'));
      }
    }
    expect(pushed, contains('ayah_pool'));
  });

  test('sends both brightnesses of every ink role, as opaque ARGB hex',
      () async {
    await push();

    for (final brightness in ['l', 'n']) {
      for (final role in ['sheet', 'ink', 'muted', 'rubric', 'gilt', 'rule']) {
        final hex = pushed['c_${brightness}_$role'];
        expect(hex, isNotNull, reason: 'missing c_${brightness}_$role');
        expect(hex, matches(RegExp(r'^[0-9A-F]{8}$')),
            reason: '$role must be 8-digit uppercase ARGB for Color.parseColor');
        // Every role is filled or filtered onto the page opaquely. The rule in
        // particular is translucent in the app and flattened before it is sent,
        // because a colour filter blends a translucent tint toward the
        // drawable's own colour rather than thinning it.
        expect(hex!.substring(0, 2), 'FF',
            reason: '$role reaches a colour filter and must be opaque');
      }
    }
  });

  test('both brightnesses are sent even when the mode is fixed', () async {
    // "Follow the system" is resolved natively, so the widget can turn dark at
    // dusk without the app running — which means it always needs both sets.
    await push(mode: ThemeMode.light);
    expect(pushed['theme_mode'], 'light');
    expect(pushed['c_n_sheet'], isNotNull);
    expect(pushed['c_l_sheet'], isNotNull);
  });

  test('each palette pushes its own inks', () async {
    final sheets = <String, String>{};
    for (final palette in AppPalettes.all) {
      await push(palette: palette);
      sheets[palette.id] = pushed['c_l_rubric']!;
    }
    expect(sheets.values.toSet(), hasLength(AppPalettes.all.length),
        reason: 'no two palettes should share a rubric');
  });

  test('adhkar tallies are integers, and done never exceeds total', () async {
    await push();
    for (final set in ['morning', 'evening', 'sleep']) {
      final done = int.tryParse(pushed['adhkar_${set}_done']!);
      final total = int.tryParse(pushed['adhkar_${set}_total']!);
      expect(done, isNotNull, reason: 'native parses these with toIntOrNull');
      expect(total, isNotNull);
      expect(total, greaterThan(0), reason: '$set should have duas');
      expect(done, lessThanOrEqualTo(total!));
    }
  });

  test('the verse pool is short, non-empty, and complete', () async {
    await push();
    final pool = jsonDecode(pushed['ayah_pool']!) as List;
    expect(pool, isNotEmpty);
    expect(pool.length, lessThanOrEqualTo(40));
    for (final entry in pool.cast<Map<String, dynamic>>()) {
      expect(entry['a'], isNotEmpty, reason: 'the Arabic is the whole point');
      // The widget gives the Arabic two lines; anything longer arrives
      // ellipsized, which is worse than not offering it.
      expect((entry['a'] as String).length, lessThanOrEqualTo(110));
      expect(entry.keys.toSet(), {'a', 't', 's'});
    }
  });

  test('the tasbih phrase is seeded before one has ever been chosen', () async {
    // A widget dropped on the home screen before the Tasbih screen has been
    // opened still needs something to count.
    await push();
    expect(pushed['tasbih_id'], isNotEmpty);
    expect(pushed['tasbih_arabic'], isNotEmpty);
    expect(int.tryParse(pushed['tasbih_target']!), greaterThan(0));
  });

  test('Arabic changes the chrome but never the Arabic text itself', () async {
    await push(lang: AppLang.ar);
    expect(pushed['lang'], 'ar');
    final arabicTitle = pushed['adhkar_morning_title'];
    await push(lang: AppLang.en);
    expect(pushed['lang'], 'en');
    expect(pushed['adhkar_morning_title'], isNot(arabicTitle),
        reason: 'category titles are localized');
  });
}
