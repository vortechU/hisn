import 'dart:async';
import 'dart:convert';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';

import '../data/dua_repository.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../theme/app_palette.dart';
import 'adhan_widget_bridge.dart';
import 'display_settings.dart';
import 'dua_progress_service.dart';
import 'prayer_service.dart';
import 'sunnah_calendar_service.dart';
import 'tasbih_controller.dart';
import 'theme_controller.dart';

/// Keeps the Android home-screen widgets in sync with the app.
///
/// It pushes *config* and *chrome*, never answers: coordinates and calculation
/// settings rather than times, three candidate adhkar sets rather than the one
/// that suits this hour, a pool of verses rather than today's. The widgets
/// resolve those themselves so they keep working — turning over at Fajr,
/// changing verse at midnight — on a phone whose app has not been opened in a
/// fortnight.
///
/// The push is debounced so a burst of notifications (a GPS fix landing right
/// after launch, say) results in one write.
class PrayerWidgetService extends ChangeNotifier {
  PrayerWidgetService(this._repository);

  final DuaRepository _repository;

  Timer? _debounce;
  PrayerService? _prayer;
  AppLang _lang = AppLang.en;
  int _hijriOffset = 0;
  AppPalette _palette = AppPalettes.fallback;
  ThemeMode _themeMode = ThemeMode.system;
  String _arabicFontId = 'amiri';
  DuaProgressService? _progress;
  TasbihController? _tasbih;

  /// The adhkar sets the widget may show, in the order the day reaches them.
  /// Mirrored natively in `AdhkarWidgetProvider`; keep the two in step.
  static const _adhkarSets = ['morning', 'evening', 'sleep'];

  /// How many verses to offer the "verse of the day" widget.
  ///
  /// Enough that a year barely repeats a season's worth, few enough that the
  /// encoded pool stays a handful of kilobytes in a preference value.
  static const _poolSize = 40;

  /// Wired by the provider whenever anything a widget draws from changes.
  void bind(
    PrayerService prayer,
    LocaleController locale,
    SunnahCalendarService calendar,
    ThemeController theme,
    DisplaySettings display,
    DuaProgressService progress,
    TasbihController tasbih,
  ) {
    _prayer = prayer;
    _lang = locale.lang;
    _hijriOffset = calendar.offset;
    _palette = theme.palette;
    _themeMode = theme.themeMode;
    _arabicFontId = display.arabicFontId;
    _progress = progress;
    _tasbih = tasbih;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _push);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _push() async {
    final s = AppStrings(_lang);
    final prayer = _prayer;
    await AdhanWidgetBridge.update({
      // The prayer config is the only section that can be unavailable — a
      // location may not have resolved yet. The rest goes regardless, so a
      // tasbih or verse widget is not left blank waiting on a GPS fix it has
      // no use for.
      if (prayer != null && prayer.isReady) ..._prayerConfig(prayer, s),
      ..._appearance(),
      ..._adhkar(s),
      ..._tasbihPhrase(),
      'ayah_pool': _versePool(s),
    });
  }

  // ---- payload sections ----

  Map<String, String> _prayerConfig(PrayerService prayer, AppStrings s) => {
        'lat': prayer.latitude.toString(),
        'lng': prayer.longitude.toString(),
        'method': prayer.method.name,
        'madhab': prayer.madhab.name,
        'label': s.place(prayer.locationLabel),
        'name_fajr': s.prayerName(Prayer.fajr),
        'name_dhuhr': s.prayerName(Prayer.dhuhr),
        'name_asr': s.prayerName(Prayer.asr),
        'name_maghrib': s.prayerName(Prayer.maghrib),
        'name_isha': s.prayerName(Prayer.isha),
        'next_label': s.next,
        'remaining': s.remaining,
        // Localized 12-hour markers (index 0 = AM, 1 = PM).
        'am': s.ampm(9),
        'pm': s.ampm(21),
        // Hijri date: a ready-made string (fallback for old Android) plus the
        // pieces the widget needs to recompute it natively each day. The
        // sighting offset is pushed alongside; the ready-made string already
        // carries it, but the native daily recompute must apply it too or the
        // widget will drift a day from the app.
        'hijri': s.hijriDate(DateTime.now(), offset: _hijriOffset),
        'hijri_months': s.hijriMonths.join('|'),
        'hijri_suffix': s.hijriSuffix,
        'hijri_offset': _hijriOffset.toString(),
      };

  /// The active scheme, in both brightnesses, plus the script settings.
  ///
  /// Both are sent because "follow the system" is resolved natively — the
  /// launcher turns dark at dusk whether or not this app is running, and the
  /// widget should turn with it.
  ///
  /// Rules are flattened over the page before being sent. They are translucent
  /// in the app, but the widget recolours its frame with a colour filter, which
  /// blends a translucent tint toward the drawable's own colour instead of
  /// thinning it — an opaque equivalent is the only form that survives.
  Map<String, String> _appearance() {
    final light = _roles(Brightness.light);
    final night = _roles(Brightness.dark);
    return {
      'theme_mode': _themeMode.name,
      'arabic_font': _arabicFontId,
      'lang': _lang.name,
      for (final role in light.keys) 'c_l_$role': _hex(light[role]!),
      for (final role in night.keys) 'c_n_$role': _hex(night[role]!),
    };
  }

  /// The five ink roles, resolved for one brightness.
  Map<String, Color> _roles(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final sheet = _palette.paperFor(brightness);
    final ink = _palette.inkFor(brightness);
    return {
      'sheet': sheet,
      'ink': ink,
      'muted': Color.lerp(ink, sheet, isLight ? 0.34 : 0.40)!,
      'rubric': _palette.rubricFor(brightness),
      'gilt': _palette.giltFor(brightness),
      'rule': Color.alphaBlend(_palette.ruleFor(brightness), sheet),
    };
  }

  /// Title, subtitle and tally for every set the widget might choose.
  ///
  /// All three go down rather than just today's, because which one belongs to
  /// now is decided natively at draw time — by then this app may be long gone
  /// from memory.
  Map<String, String> _adhkar(AppStrings s) {
    final progress = _progress;
    // Uppercased to match how the app sets this label — small, tracked, and
    // read as apparatus rather than as a sentence. A no-op in Arabic.
    final data = <String, String>{'adhkar_label': s.recommendedNow.toUpperCase()};
    for (final id in _adhkarSets) {
      final category = _repository.categoryById(id);
      final duas = _repository.duasForCategory(id);
      final done = progress == null
          ? 0
          : duas.where((d) => progress.countOf(d.id) >= d.repeat).length;
      data['adhkar_${id}_title'] = category?.titleFor(s.ar) ?? '';
      data['adhkar_${id}_sub'] = category?.subtitleFor(s.ar) ?? '';
      data['adhkar_${id}_done'] = done.toString();
      data['adhkar_${id}_total'] = duas.length.toString();
    }
    return data;
  }

  /// The phrase the tasbih widget counts.
  ///
  /// Seeded from the first preset until one has been chosen, so a widget
  /// dropped on the home screen before the Tasbih screen has ever been opened
  /// still has something to count.
  Map<String, String> _tasbihPhrase() {
    final presets = _repository.dhikr;
    if (presets.isEmpty) return const {};
    final selected = _tasbih?.selectedId;
    final dhikr = presets.firstWhere(
      (d) => d.id == selected,
      orElse: () => presets.first,
    );
    return TasbihController.widgetPayload(dhikr);
  }

  /// The pool the "verse of the day" widget draws from.
  ///
  /// Short duas only — the widget gives the Arabic two lines, and a supplication
  /// that arrives ellipsized is worse than one that is not offered. Picked at an
  /// even stride through the collection rather than from the front, so the pool
  /// spans the whole book instead of whichever category sorts first.
  String _versePool(AppStrings s) {
    final lang = s.lang.name;
    final short = _repository.duas
        .where((d) => d.arabic.length >= 12 && d.arabic.length <= 110)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (short.isEmpty) return '[]';

    final stride = (short.length / _poolSize).ceil().clamp(1, short.length);
    final pool = <Map<String, String>>[];
    for (var i = 0; i < short.length && pool.length < _poolSize; i += stride) {
      pool.add({
        'a': short[i].arabic,
        't': short[i].translationFor(lang),
        's': short[i].referenceFor(lang),
      });
    }
    return jsonEncode(pool);
  }

  static String _hex(Color color) =>
      color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
}
