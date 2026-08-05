import 'package:flutter/material.dart';

/// An optional reading-surface tint applied to dua cards, independent of the
/// app's light/dark theme — like the page modes on an e-reader. [system] keeps
/// whatever the active theme provides.
enum ReadingTheme { system, sepia, night }

class _ReadingColors {
  const _ReadingColors(this.surface, this.onSurface, this.onSurfaceVariant);
  final Color surface;
  final Color onSurface;
  final Color onSurfaceVariant;
}

extension ReadingThemeX on ReadingTheme {
  static ReadingTheme fromName(String? name) {
    switch (name) {
      case 'sepia':
        return ReadingTheme.sepia;
      case 'night':
        return ReadingTheme.night;
      default:
        return ReadingTheme.system;
    }
  }

  _ReadingColors? get _colors {
    switch (this) {
      case ReadingTheme.system:
        return null;
      case ReadingTheme.sepia:
        return const _ReadingColors(
          Color(0xFFF3E7CC), // warm paper
          Color(0xFF463524), // brown ink
          Color(0xFF7C6A4E),
        );
      case ReadingTheme.night:
        return const _ReadingColors(
          Color(0xFF15140F), // near-black, faint warmth
          Color(0xFFE6DECB), // soft off-white
          Color(0xFFA39B86),
        );
    }
  }

  /// [base] with the reading-surface colours layered in. The accent roles
  /// (primary/secondary) are left untouched so badges and highlights keep the
  /// active palette. Returns [base] unchanged for [ReadingTheme.system].
  ThemeData apply(ThemeData base) {
    final colors = _colors;
    if (colors == null) return base;
    final scheme = base.colorScheme.copyWith(
      surface: colors.surface,
      onSurface: colors.onSurface,
      onSurfaceVariant: colors.onSurfaceVariant,
    );
    return base.copyWith(
      colorScheme: scheme,
      cardColor: colors.surface,
      cardTheme: base.cardTheme.copyWith(color: colors.surface),
    );
  }
}
