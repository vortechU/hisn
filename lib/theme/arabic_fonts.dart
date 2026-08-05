/// A selectable Arabic typeface for the app's Arabic script (dua text, dhikr,
/// titles). The Qur'an *mushaf* pages keep their own KFGQPC page fonts — only
/// general Arabic text follows this choice.
class ArabicFontOption {
  const ArabicFontOption({required this.id, required this.family});

  /// Stable key persisted in preferences.
  final String id;

  /// The font family name as declared in pubspec.yaml.
  final String family;
}

/// The bundled Arabic typefaces offered in Display settings. [amiri] is the
/// default — the app's original Arabic font.
class ArabicFonts {
  ArabicFonts._();

  static const amiri = ArabicFontOption(id: 'amiri', family: 'Amiri');
  static const scheherazade =
      ArabicFontOption(id: 'scheherazade', family: 'Scheherazade New');
  static const noto =
      ArabicFontOption(id: 'noto', family: 'Noto Naskh Arabic');

  static const List<ArabicFontOption> all = [amiri, scheherazade, noto];
  static const ArabicFontOption fallback = amiri;

  static ArabicFontOption byId(String? id) =>
      all.firstWhere((f) => f.id == id, orElse: () => fallback);
}
