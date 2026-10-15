import 'package:dua_app/theme/app_palette.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('editable fields keep rounded corners in every interaction state', () {
    for (final theme in [
      AppTheme.light(AppPalettes.emerald),
      AppTheme.dark(AppPalettes.emerald),
    ]) {
      final input = theme.inputDecorationTheme;
      for (final border in [
        input.border,
        input.enabledBorder,
        input.focusedBorder,
        input.errorBorder,
        input.focusedErrorBorder,
      ]) {
        expect(border, isA<OutlineInputBorder>());
        expect(
          (border! as OutlineInputBorder).borderRadius,
          BorderRadius.circular(12),
        );
      }
    }
  });
}
