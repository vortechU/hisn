import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dua.dart';

/// Stores the duas the user adds themselves, persisted as JSON in
/// shared_preferences. These live alongside the bundled content but in their
/// own "My Duas" section.
class CustomDuaService extends ChangeNotifier {
  CustomDuaService(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;
  static const _kKey = 'custom_duas';

  List<Dua> _duas = [];

  /// The user's duas, newest first.
  List<Dua> get duas => List.unmodifiable(_duas);
  int get count => _duas.length;
  bool get isEmpty => _duas.isEmpty;

  void _load() {
    final raw = _prefs.getString(_kKey);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _duas = list
          .map((e) => Dua.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _duas = [];
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(
        _kKey, jsonEncode(_duas.map((d) => d.toJson()).toList()));
  }

  /// Assemble a [Dua] from raw form fields, normalizing whitespace and applying
  /// the same defaults used by both [add] and [update].
  Dua _compose({
    required String id,
    required String arabic,
    required String title,
    required String transliteration,
    required String translation,
    required String reference,
    required int repeat,
  }) {
    final trimmedTitle = title.trim();
    return Dua(
      id: id,
      categoryId: Dua.customCategoryId,
      title: trimmedTitle.isEmpty ? 'My dua' : trimmedTitle,
      titleArabic: trimmedTitle.isEmpty ? null : trimmedTitle,
      arabic: arabic.trim(),
      transliteration: transliteration.trim(),
      translation: translation.trim(),
      reference: reference.trim().isEmpty ? 'My dua' : reference.trim(),
      repeat: repeat < 1 ? 1 : repeat,
    );
  }

  /// Build and store a new custom dua. Only [arabic] is required; everything
  /// else is optional. Returns the created dua.
  Future<Dua> add({
    required String arabic,
    String title = '',
    String transliteration = '',
    String translation = '',
    String reference = '',
    int repeat = 1,
  }) async {
    final dua = _compose(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      arabic: arabic,
      title: title,
      transliteration: transliteration,
      translation: translation,
      reference: reference,
      repeat: repeat,
    );
    _duas = [dua, ..._duas];
    notifyListeners();
    await _persist();
    return dua;
  }

  /// Replace the dua with [id] in place (keeping its position), e.g. to fix a
  /// typo. No-op if the id isn't found.
  Future<void> update({
    required String id,
    required String arabic,
    String title = '',
    String transliteration = '',
    String translation = '',
    String reference = '',
    int repeat = 1,
  }) async {
    final index = _duas.indexWhere((d) => d.id == id);
    if (index < 0) return;
    final updated = _compose(
      id: id,
      arabic: arabic,
      title: title,
      transliteration: transliteration,
      translation: translation,
      reference: reference,
      repeat: repeat,
    );
    _duas = [..._duas]..[index] = updated;
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _duas = _duas.where((d) => d.id != id).toList();
    notifyListeners();
    await _persist();
  }
}
