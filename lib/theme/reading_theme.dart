import 'package:flutter/material.dart';

import 'app_theme.dart';

/// An optional reading-surface tint applied to dua cards, independent of the
/// app's light/dark theme — like the page modes on an e-reader. [system] keeps
/// whatever the active theme provides.
enum ReadingTheme { system, sepia, night }

/// Derived themes, hung off the base theme they were derived from.
///
/// [ReadingThemeX.apply] is called by every dua card on every build, and a
/// screen of cards rebuilds on every tap — but the answer only changes when the
/// app's own theme does. Deriving it is not cheap: `copyWith` rebuilds a
/// hundred-odd fields and `textTheme.apply` re-inks fifteen styles, so the
/// uncached version was constructing a full [ThemeData] per visible card per
/// frame.
///
/// An [Expando] rather than a map because it keys on the base theme's identity
/// and lets the entry go when that theme does — a palette or brightness change
/// replaces the base instance, and nothing has to remember to evict the old
/// one.
final _derived = Expando<Map<ReadingTheme, ThemeData>>('reading themes');

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
          Color(0xFF3E2E1E), // brown ink
          Color(0xFF6E5C42),
        );
      case ReadingTheme.night:
        return const _ReadingColors(
          Color(0xFF15140F), // near-black, faint warmth
          Color(0xFFE6DECB), // soft off-white
          Color(0xFFA79E88),
        );
    }
  }

  /// [base] with the reading-surface colours layered in.
  ///
  /// The accent roles — rubric and gilt — are left untouched so a card keeps
  /// the active palette's inks even on a sepia or night page. The rules are
  /// re-derived from the new ink so frames stay visible against the tinted
  /// paper instead of disappearing into it. Returns [base] unchanged for
  /// [ReadingTheme.system].
  ThemeData apply(ThemeData base) {
    final colors = _colors;
    if (colors == null) return base;

    final cache = _derived[base] ??= <ReadingTheme, ThemeData>{};
    final cached = cache[this];
    if (cached != null) return cached;

    final scheme = base.colorScheme.copyWith(
      surface: colors.surface,
      onSurface: colors.onSurface,
      onSurfaceVariant: colors.onSurfaceVariant,
    );
    final ms = base.extension<ManuscriptTheme>()!;
    final rule = Color.lerp(colors.onSurface, colors.surface, 0.62)!;

    return cache[this] = base.copyWith(
      colorScheme: scheme,
      cardColor: colors.surface,
      cardTheme: base.cardTheme.copyWith(color: colors.surface),
      // Re-ink the type for the tinted page, then restore the two muted roles
      // that `apply` would otherwise flatten into full-strength ink.
      textTheme: base.textTheme
          .apply(
            bodyColor: colors.onSurface,
            displayColor: colors.onSurface,
          )
          .copyWith(
            bodySmall: base.textTheme.bodySmall!
                .copyWith(color: colors.onSurfaceVariant),
            labelSmall: base.textTheme.labelSmall!
                .copyWith(color: colors.onSurfaceVariant),
          ),
      extensions: [
        ms.copyWith(
          paper: colors.surface,
          ground: Color.lerp(colors.surface, colors.onSurface, 0.06)!,
          rule: rule,
          ruleStrong: Color.lerp(rule, colors.onSurface, 0.4)!,
        ),
      ],
    );
  }
}
