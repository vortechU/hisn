import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:dua_app/theme/arabic_fonts.dart';

/// Guards the Arabic fallback on the text theme.
///
/// Crimson Pro and Karla are subset to Latin ranges and contain no Arabic
/// glyphs at all. Without an explicit fallback, every Arabic interface string
/// — which is the entire chrome when the app runs in Arabic — silently renders
/// in whatever Arabic font the platform substitutes, beside dua text set in
/// Amiri. Nothing about that failure is visible to the analyzer, and it looks
/// merely "slightly off" rather than broken, so it is easy to reintroduce.
void main() {
  /// Every style on a [TextTheme], named, so a failure says which one.
  Map<String, TextStyle?> stylesOf(TextTheme t) => {
        'displayLarge': t.displayLarge,
        'displayMedium': t.displayMedium,
        'displaySmall': t.displaySmall,
        'headlineLarge': t.headlineLarge,
        'headlineMedium': t.headlineMedium,
        'headlineSmall': t.headlineSmall,
        'titleLarge': t.titleLarge,
        'titleMedium': t.titleMedium,
        'titleSmall': t.titleSmall,
        'bodyLarge': t.bodyLarge,
        'bodyMedium': t.bodyMedium,
        'bodySmall': t.bodySmall,
        'labelLarge': t.labelLarge,
        'labelMedium': t.labelMedium,
        'labelSmall': t.labelSmall,
      };

  test('every text style falls back to the bundled Arabic face', () {
    for (final font in ArabicFonts.all) {
      for (final palette in AppPalettes.all) {
        for (final theme in [
          AppTheme.light(palette, arabicFamily: font.family),
          AppTheme.dark(palette, arabicFamily: font.family),
        ]) {
          stylesOf(theme.textTheme).forEach((name, style) {
            expect(style, isNotNull, reason: '$name is missing');
            expect(
              style!.fontFamilyFallback,
              contains(font.family),
              reason: '$name has no Arabic fallback '
                  '(palette ${palette.id}, font ${font.family})',
            );
          });
        }
      }
    }
  });

  test('ThemeData itself carries the Arabic fallback', () {
    final theme = AppTheme.light(AppPalettes.emerald,
        arabicFamily: ArabicFonts.scheherazade.family);
    expect(theme.textTheme.bodyMedium!.fontFamilyFallback,
        contains(ArabicFonts.scheherazade.family));
  });

  group('an Arabic interface', () {
    final latin = AppTheme.light(AppPalettes.emerald, arabicUi: false);
    final arabic = AppTheme.light(AppPalettes.emerald, arabicUi: true);

    test('drops letter-spacing, which breaks cursive joining', () {
      // The Latin label styles are deliberately tracked; Arabic must not be.
      expect(latin.textTheme.labelSmall!.letterSpacing, greaterThan(0));
      for (final entry in stylesOf(arabic.textTheme).entries) {
        expect(entry.value!.letterSpacing, 0,
            reason: '${entry.key} is tracked in Arabic');
      }
    });

    test('opens the leading so harakat are not clipped', () {
      stylesOf(arabic.textTheme).forEach((name, style) {
        final latinHeight = stylesOf(latin.textTheme)[name]!.height!;
        expect(style!.height, greaterThan(latinHeight),
            reason: '$name has no extra leading in Arabic');
      });
    });
  });
}
