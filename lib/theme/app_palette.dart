import 'package:flutter/material.dart';

/// A selectable colour scheme for the app. [primary] + [secondary] seed the
/// light theme; [darkPrimary] is a brighter primary tuned for dark surfaces.
/// The deep hero [gradient] (prayer header, tasbih, onboarding) is derived from
/// [primary] so it follows whichever palette is active.
@immutable
class AppPalette {
  const AppPalette({
    required this.id,
    required this.primary,
    required this.darkPrimary,
    required this.secondary,
  });

  /// Stable key persisted in preferences and used for translated names.
  final String id;

  /// The light-theme primary (also the [ColorScheme.fromSeed] seed).
  final Color primary;

  /// A lighter, more luminous primary used in dark mode.
  final Color darkPrimary;

  /// The accent / secondary colour (badges, counters, highlights).
  final Color secondary;

  /// Two-stop deep gradient used on coloured hero surfaces, in both modes.
  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, Color.lerp(primary, Colors.black, 0.32)!],
      );
}

/// The curated set of palettes offered in Appearance settings. [emerald] is the
/// default, reproducing the app's original deep-emerald-and-gold identity.
class AppPalettes {
  AppPalettes._();

  static const emerald = AppPalette(
    id: 'emerald',
    primary: Color(0xFF0E6B5C),
    darkPrimary: Color(0xFF4FD1B8),
    secondary: Color(0xFFC9A227),
  );
  static const sapphire = AppPalette(
    id: 'sapphire',
    primary: Color(0xFF1E5AA8),
    darkPrimary: Color(0xFF6FA8E8),
    secondary: Color(0xFF7FB2DE),
  );
  static const amethyst = AppPalette(
    id: 'amethyst',
    primary: Color(0xFF6A4A8C),
    darkPrimary: Color(0xFFC3A6E6),
    secondary: Color(0xFFC98BB0),
  );
  static const rosewood = AppPalette(
    id: 'rosewood',
    primary: Color(0xFF9B3B5A),
    darkPrimary: Color(0xFFE68BA3),
    secondary: Color(0xFFE0A4B4),
  );
  static const lagoon = AppPalette(
    id: 'lagoon',
    primary: Color(0xFF0E7C7B),
    darkPrimary: Color(0xFF4FD0CE),
    secondary: Color(0xFFE07856),
  );
  static const desert = AppPalette(
    id: 'desert',
    primary: Color(0xFF8A5A3C),
    darkPrimary: Color(0xFFDDB089),
    secondary: Color(0xFFCE9B6E),
  );

  /// All palettes, in display order.
  static const List<AppPalette> all = [
    emerald,
    sapphire,
    amethyst,
    rosewood,
    lagoon,
    desert,
  ];

  /// The default palette, used when nothing is saved or an id is unknown.
  static const AppPalette fallback = emerald;

  static AppPalette byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => fallback);
}
