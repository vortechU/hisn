import 'package:flutter/material.dart';

/// A colour scheme for the prayer hall.
///
/// Every palette is one accent and one completion colour laid over the same
/// family of neutrals, the way a mosque interior is one tiled qibla wall in a
/// hall of plaster and stone:
///
///   * [accent] — the qibla ink. The one focal field on a screen is filled
///                with it, and the active state is drawn in it. It never
///                decorates.
///   * [brass]  — the lamp. Completion only: a finished dua, a full set, a
///                streak. Never body text.
///
/// The neutrals are derived from the accent rather than tuned per palette: the
/// plaster ground carries a breath of the accent so the hall feels lit by its
/// own wall, and the night ground is the same hall after Isha — a deep,
/// accent-tinted dark, never a flat grey.
@immutable
class AppPalette {
  const AppPalette({
    required this.id,
    required this.accent,
    required this.accentNight,
    required this.brass,
    required this.brassNight,
  });

  /// Stable key persisted in preferences and used for translated names.
  final String id;

  /// The qibla ink in light mode: the focal field's fill, headings that need
  /// emphasis, and the active state.
  final Color accent;

  /// The accent as a foreground on the night ground — lifted until it reads,
  /// because the light-mode ink disappears into the dark.
  final Color accentNight;

  /// The completion colour, light and dark.
  final Color brass;
  final Color brassNight;

  static const _plaster = Color(0xFFF2F1EC);
  static const _sheet = Color(0xFFFBFAF7);
  static const _ink = Color(0xFF161A1C);
  static const _night = Color(0xFF0B0F11);
  static const _lamp = Color(0xFFE9E5DB);

  bool _light(Brightness b) => b == Brightness.light;

  /// The page: plaster by day; by night the hall after Isha, a deep shade of
  /// the accent itself (for the default palette, the navy of the Hisn mark).
  Color groundFor(Brightness b) => _light(b)
      ? Color.lerp(_plaster, accent, 0.03)!
      : Color.lerp(_night, accent, 0.5)!;

  /// A raised group of rows — a shade off the ground, told apart by value
  /// alone. Nothing in the hall is outlined.
  Color paperFor(Brightness b) => _light(b)
      ? Color.lerp(_sheet, accent, 0.012)!
      : Color.lerp(groundFor(b), accentNight, 0.07)!;

  /// Body text.
  Color inkFor(Brightness b) => _light(b) ? _ink : _lamp;

  /// The accent as it is drawn on the page.
  Color rubricFor(Brightness b) => _light(b) ? accent : accentNight;

  /// The completion colour as it is drawn on the page.
  Color giltFor(Brightness b) => _light(b) ? brass : brassNight;

  /// The mihrab: the one filled field a screen is built around.
  ///
  /// By night it is lifted a clear step above the ground, toward the lit
  /// accent, so the niche still stands out of the dark hall.
  Color fieldFor(Brightness b) =>
      _light(b) ? accent : Color.lerp(accent, accentNight, 0.10)!;

  /// Text and marks set on the [fieldFor] colour.
  Color onFieldFor(Brightness b) => const Color(0xFFF4F1E8);

  /// The faint separator between rows inside a group. Used sparingly: rows are
  /// told apart by spacing first.
  Color ruleFor(Brightness b) => _light(b)
      ? _ink.withValues(alpha: 0.08)
      : _lamp.withValues(alpha: 0.09);
}

/// The palettes offered in Appearance settings.
///
/// Each is the same hall with a different tiled wall: the neutrals are shared,
/// only the accent and the lamp change.
class AppPalettes {
  AppPalettes._();

  /// The petrol of the Hisn mark itself — the app's own colour, and the
  /// default.
  static const qibla = AppPalette(
    id: 'qibla',
    accent: Color(0xFF0F3D4C),
    accentNight: Color(0xFF86C5CC),
    brass: Color(0xFF93681D),
    brassNight: Color(0xFFD4A85A),
  );

  /// Deep emerald, the green of the Prophet's Mosque carpets.
  static const emerald = AppPalette(
    id: 'emerald',
    accent: Color(0xFF0C5A4C),
    accentNight: Color(0xFF6CCBB4),
    brass: Color(0xFF93681D),
    brassNight: Color(0xFFD4A85A),
  );

  /// Iznik cobalt.
  static const sapphire = AppPalette(
    id: 'sapphire',
    accent: Color(0xFF1B4B8F),
    accentNight: Color(0xFF94B7EE),
    brass: Color(0xFF93681D),
    brassNight: Color(0xFFD4A85A),
  );

  /// A muted plum, low in chroma so it reads as dyed wool, not screen purple.
  static const amethyst = AppPalette(
    id: 'amethyst',
    accent: Color(0xFF5C3357),
    accentNight: Color(0xFFCDA2C5),
    brass: Color(0xFF93681D),
    brassNight: Color(0xFFD4A85A),
  );

  /// Madder red, the prayer-rug red.
  static const rosewood = AppPalette(
    id: 'rosewood',
    accent: Color(0xFF8E2F2E),
    accentNight: Color(0xFFE8978D),
    brass: Color(0xFF93681D),
    brassNight: Color(0xFFD4A85A),
  );

  /// Andalusi teal, with terracotta in the lamp's place. Deep enough that
  /// cream text holds on the field.
  static const lagoon = AppPalette(
    id: 'lagoon',
    accent: Color(0xFF0A5552),
    accentNight: Color(0xFF63CFC5),
    brass: Color(0xFFA4532F),
    brassNight: Color(0xFFE58F69),
  );

  /// Mud-brick sienna.
  static const desert = AppPalette(
    id: 'desert',
    accent: Color(0xFF683E1D),
    accentNight: Color(0xFFDDA36C),
    brass: Color(0xFF8A6A1F),
    brassNight: Color(0xFFD0B061),
  );

  /// All palettes, in display order.
  static const List<AppPalette> all = [
    qibla,
    emerald,
    sapphire,
    amethyst,
    rosewood,
    lagoon,
    desert,
  ];

  /// The default palette, used when nothing is saved or an id is unknown.
  static const AppPalette fallback = qibla;

  static AppPalette byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => fallback);
}
