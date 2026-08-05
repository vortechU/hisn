import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Carries brand colours that don't fit in a [ColorScheme] — currently the
/// deep gradient used on coloured hero surfaces (prayer header, tasbih screen,
/// onboarding). It rides on [ThemeData.extensions] so any widget can read the
/// active palette's gradient via [BrandTheme.of] without touching a controller.
@immutable
class BrandTheme extends ThemeExtension<BrandTheme> {
  const BrandTheme({required this.heroGradient});

  final LinearGradient heroGradient;

  @override
  BrandTheme copyWith({LinearGradient? heroGradient}) =>
      BrandTheme(heroGradient: heroGradient ?? this.heroGradient);

  @override
  BrandTheme lerp(ThemeExtension<BrandTheme>? other, double t) {
    if (other is! BrandTheme) return this;
    return BrandTheme(
      heroGradient: LinearGradient.lerp(heroGradient, other.heroGradient, t)!,
    );
  }

  /// The active hero gradient for [context].
  static LinearGradient of(BuildContext context) =>
      Theme.of(context).extension<BrandTheme>()!.heroGradient;
}

/// Centralised fonts and [ThemeData] for the app. Colours come from the chosen
/// [AppPalette] (see Appearance settings); Material 3 derives the rest of the
/// scheme — and its light/dark contrast — from the palette's seed.
class AppTheme {
  AppTheme._();

  /// Font family bundled for Arabic script (see pubspec.yaml).
  static const String arabicFont = 'Amiri';

  /// The light theme for [palette]. A soft, paper-like surface is kept across
  /// all palettes to preserve the calm long-reading feel.
  static ThemeData light(AppPalette palette) {
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      primary: palette.primary,
      secondary: palette.secondary,
      brightness: Brightness.light,
    ).copyWith(surface: const Color(0xFFFBF9F3));

    return _base(scheme, palette).copyWith(
      scaffoldBackgroundColor: const Color(0xFFF6F3EA),
    );
  }

  /// The dark theme for [palette], using its brighter [AppPalette.darkPrimary].
  static ThemeData dark(AppPalette palette) {
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      primary: palette.darkPrimary,
      secondary: palette.secondary,
      brightness: Brightness.dark,
    ).copyWith(surface: const Color(0xFF13201D));

    return _base(scheme, palette).copyWith(
      scaffoldBackgroundColor: const Color(0xFF0C1614),
    );
  }

  static ThemeData _base(ColorScheme scheme, AppPalette palette) {
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      brightness: scheme.brightness,
    );

    return base.copyWith(
      extensions: [BrandTheme(heroGradient: palette.gradient)],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0.5,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
