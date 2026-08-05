import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/dhikr.dart';
import '../models/dua.dart';
import '../models/dua_category.dart';
import '../util/arabic.dart';

/// Loads dua content from the bundled JSON assets and exposes simple queries.
///
/// Data is read once and cached in memory. Swapping the JSON files (or pointing
/// this at a database / remote source later) is all that's needed to grow the
/// content without touching the UI.
class DuaRepository {
  List<DuaCategory> _categories = const [];
  List<Dua> _duas = const [];
  List<Dhikr> _dhikr = const [];

  bool _loaded = false;

  List<DuaCategory> get categories => _categories;
  List<Dua> get duas => _duas;
  List<Dhikr> get dhikr => _dhikr;

  Future<void> load() async {
    if (_loaded) return;

    final results = await Future.wait([
      rootBundle.loadString('assets/data/categories.json'),
      rootBundle.loadString('assets/data/duas.json'),
      rootBundle.loadString('assets/data/tasbih.json'),
    ]);

    _categories = (jsonDecode(results[0]) as List)
        .map((e) => DuaCategory.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    final overlays = await _loadTranslationOverlays();
    _duas = (jsonDecode(results[1]) as List)
        .map((e) => _applyOverlays(
            Dua.fromJson(e as Map<String, dynamic>), overlays))
        .toList(growable: false);

    _dhikr = (jsonDecode(results[2]) as List)
        .map((e) => Dhikr.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    _loaded = true;
  }

  /// Languages that ship a translation overlay file
  /// (`assets/data/duas.<lang>.json`). The Arabic dua text is never translated —
  /// only the `translation` (meaning) and `virtue` fields are overlaid.
  static const _overlayLangs = ['id'];

  /// Loads each available overlay into `{ langCode: { duaId: {field: text} } }`.
  /// A missing or empty overlay file is skipped silently, so shipping before the
  /// content is filled in is safe (duas just keep their English meaning).
  Future<Map<String, Map<String, Map<String, dynamic>>>>
      _loadTranslationOverlays() async {
    final result = <String, Map<String, Map<String, dynamic>>>{};
    for (final lang in _overlayLangs) {
      try {
        final raw =
            await rootBundle.loadString('assets/data/duas.$lang.json');
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        result[lang] = decoded.map(
            (id, value) => MapEntry(id, (value as Map).cast<String, dynamic>()));
      } catch (_) {
        // No overlay (or malformed) — fall back to the base English meaning.
      }
    }
    return result;
  }

  /// Attaches any non-empty localized translation/virtue to [dua].
  Dua _applyOverlays(
      Dua dua, Map<String, Map<String, Map<String, dynamic>>> overlays) {
    final translations = <String, String>{};
    final virtues = <String, String>{};
    overlays.forEach((lang, byId) {
      final entry = byId[dua.id];
      if (entry == null) return;
      final t = entry['translation'] as String?;
      final v = entry['virtue'] as String?;
      if (t != null && t.trim().isNotEmpty) translations[lang] = t;
      if (v != null && v.trim().isNotEmpty) virtues[lang] = v;
    });
    if (translations.isEmpty && virtues.isEmpty) return dua;
    return dua.withLocalized(translations: translations, virtues: virtues);
  }

  DuaCategory? categoryById(String id) {
    for (final category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  List<Dua> duasForCategory(String categoryId) =>
      _duas.where((d) => d.categoryId == categoryId).toList(growable: false);

  int countForCategory(String categoryId) =>
      _duas.where((d) => d.categoryId == categoryId).length;

  /// Case-insensitive search across title (English & Arabic), transliteration,
  /// translation, reference, and the Arabic text. Arabic matching ignores
  /// harakat and folds letter variants, so a query typed without diacritics
  /// still matches.
  List<Dua> search(String query) => searchIn(_duas, query);

  /// Same matching logic, runnable over any dua list (e.g. custom duas).
  static List<Dua> searchIn(List<Dua> duas, String query) {
    final raw = query.trim();
    final q = raw.toLowerCase();
    if (q.isEmpty) return const [];
    final qn = normalizeArabic(raw);
    final arabicQuery = qn.isNotEmpty;
    return duas.where((dua) {
      return dua.title.toLowerCase().contains(q) ||
          dua.transliteration.toLowerCase().contains(q) ||
          dua.translation.toLowerCase().contains(q) ||
          dua.reference.toLowerCase().contains(q) ||
          (arabicQuery && normalizeArabic(dua.arabic).contains(qn)) ||
          (arabicQuery &&
              dua.titleArabic != null &&
              normalizeArabic(dua.titleArabic!).contains(qn));
    }).toList(growable: false);
  }

  Dua? duaById(String id) {
    for (final dua in _duas) {
      if (dua.id == id) return dua;
    }
    return null;
  }

  List<Dua> duasByIds(Iterable<String> ids) =>
      ids.map(duaById).whereType<Dua>().toList(growable: false);
}
