import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Prayer-hall design tokens that have no home in a [ColorScheme].
///
/// Surfaces are organised by fill and by space, the way a calm interior is —
/// plaster ground, a lighter stone for grouped rows, and one field of the
/// qibla ink per screen — rather than by outlines or elevation. There are no
/// drop shadows and no ruled frames; [rule] exists only for the faint line
/// between rows inside a group.
@immutable
class ManuscriptTheme extends ThemeExtension<ManuscriptTheme> {
  const ManuscriptTheme({
    required this.rule,
    required this.ruleStrong,
    required this.rubric,
    required this.gilt,
    required this.paper,
    required this.ground,
    required this.field,
    required this.onField,
  });

  /// The faint separator between rows inside a group.
  final Color rule;

  /// A firmer line, for the few marks that must hold against the ground (an
  /// unselected radio ring, a tour card's edge).
  final Color ruleStrong;

  /// The accent as a foreground: emphasis and the active state.
  final Color rubric;

  /// The lamp: completion only.
  final Color gilt;

  /// The fill of a raised group of rows.
  final Color paper;

  /// The page.
  final Color ground;

  /// The mihrab: the one filled focal field on a screen.
  final Color field;

  /// Text and marks on [field].
  final Color onField;

  @override
  ManuscriptTheme copyWith({
    Color? rule,
    Color? ruleStrong,
    Color? rubric,
    Color? gilt,
    Color? paper,
    Color? ground,
    Color? field,
    Color? onField,
  }) =>
      ManuscriptTheme(
        rule: rule ?? this.rule,
        ruleStrong: ruleStrong ?? this.ruleStrong,
        rubric: rubric ?? this.rubric,
        gilt: gilt ?? this.gilt,
        paper: paper ?? this.paper,
        ground: ground ?? this.ground,
        field: field ?? this.field,
        onField: onField ?? this.onField,
      );

  @override
  ManuscriptTheme lerp(ThemeExtension<ManuscriptTheme>? other, double t) {
    if (other is! ManuscriptTheme) return this;
    return ManuscriptTheme(
      rule: Color.lerp(rule, other.rule, t)!,
      ruleStrong: Color.lerp(ruleStrong, other.ruleStrong, t)!,
      rubric: Color.lerp(rubric, other.rubric, t)!,
      gilt: Color.lerp(gilt, other.gilt, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      ground: Color.lerp(ground, other.ground, t)!,
      field: Color.lerp(field, other.field, t)!,
      onField: Color.lerp(onField, other.onField, t)!,
    );
  }

  /// The hall tokens for [context].
  static ManuscriptTheme of(BuildContext context) =>
      Theme.of(context).extension<ManuscriptTheme>()!;
}

/// Shared constants: the radius and line scales, and the page margin.
///
/// Corners are soft and graded by size — a chip is rounder relative to its
/// height than a sheet is — so the eye reads containers as one family.
class Ms {
  Ms._();

  /// Badges, chips, counters, small tiles.
  static const double rSmall = 10;

  /// Editable fields.
  static const double rInput = 16;

  /// Buttons are stadiums.
  static const double rButton = 100;

  /// Groups of rows and cards.
  static const double rPanel = 22;

  /// Sheets and dialogs.
  static const double rSheet = 28;

  /// Hairline weight.
  static const double hair = 1;

  /// A firmer line weight.
  static const double stroke = 2;

  /// The gap a framed page keeps inside its border. Only the mushaf page still
  /// draws a frame; its geometry is measured against this, so it stays fixed.
  static const double gutter = 3;

  /// The page margin used by every scrolling surface.
  static const double margin = 20;
}

/// Centralised fonts and [ThemeData].
///
/// One interface face, **Readex Pro**, carries every piece of chrome in Latin
/// and in Arabic, so the English and Arabic interfaces share one voice. Sacred
/// text — duas and verses — is set apart in the Naskh the reader chose in
/// Display settings (see `ArabicText`), which keeps the text and the apparatus
/// around it from ever being confused.
///
/// Readex Pro has no Urdu-specific letters, so an Urdu interface passes Noto
/// Naskh Arabic as [uiFamily] instead; every style still falls back to the
/// chosen Arabic face for anything the interface face lacks.
class AppTheme {
  AppTheme._();

  /// Default Arabic family. The active one comes from Display settings and is
  /// passed into [light]/[dark] so the chrome matches the dua text.
  static const String arabicFont = 'Amiri';

  /// The interface face.
  static const String sans = 'Readex Pro';

  /// Kept as an alias so surfaces that asked for the old content serif get the
  /// interface face rather than a missing family.
  static const String serif = sans;

  /// The interface face for an Urdu interface.
  static const String urduUiFont = 'Noto Naskh Arabic';

  /// [palette] in light mode.
  ///
  /// [arabicFamily] is the bundled Arabic face to fall back to; [arabicUi] is
  /// whether the interface language is right-to-left, which changes how the
  /// styles are set (see [_textTheme]); [uiFamily] is the interface face.
  static ThemeData light(
    AppPalette palette, {
    String arabicFamily = arabicFont,
    bool arabicUi = false,
    String uiFamily = sans,
  }) =>
      _build(palette, Brightness.light, arabicFamily, arabicUi, uiFamily);

  /// [palette] in dark mode. See [light] for the parameters.
  static ThemeData dark(
    AppPalette palette, {
    String arabicFamily = arabicFont,
    bool arabicUi = false,
    String uiFamily = sans,
  }) =>
      _build(palette, Brightness.dark, arabicFamily, arabicUi, uiFamily);

  static ThemeData _build(
    AppPalette palette,
    Brightness brightness,
    String arabicFamily,
    bool arabicUi,
    String uiFamily,
  ) {
    final isLight = brightness == Brightness.light;
    final ink = palette.inkFor(brightness);
    final rubric = palette.rubricFor(brightness);
    final gilt = palette.giltFor(brightness);
    final paper = palette.paperFor(brightness);
    final ground = palette.groundFor(brightness);
    final rule = palette.ruleFor(brightness);
    final field = palette.fieldFor(brightness);
    final onField = palette.onFieldFor(brightness);

    // Secondary ink for metadata and captions. Body-weight text, so it has to
    // clear 4.5:1 against both the ground and the raised paper.
    final inkMuted = Color.lerp(ink, paper, isLight ? 0.32 : 0.34)!;
    final onRubric = _readableOn(rubric);
    final accentTint =
        Color.lerp(paper, rubric, isLight ? 0.10 : 0.16)!;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: rubric,
      onPrimary: onRubric,
      primaryContainer: accentTint,
      onPrimaryContainer: isLight ? rubric : ink,
      // Tonal buttons and selected chips take the accent's tint; the lamp
      // colour is kept for completion and lives in tertiary.
      secondary: rubric,
      onSecondary: onRubric,
      secondaryContainer: accentTint,
      onSecondaryContainer: isLight ? rubric : ink,
      tertiary: gilt,
      onTertiary: _readableOn(gilt),
      tertiaryContainer: Color.lerp(paper, gilt, isLight ? 0.14 : 0.20)!,
      onTertiaryContainer: isLight ? Color.lerp(gilt, ink, 0.35)! : ink,
      error: isLight ? const Color(0xFFA3322A) : const Color(0xFFEE9A8E),
      onError: isLight ? const Color(0xFFFFF6F3) : const Color(0xFF2A0F0B),
      errorContainer:
          isLight ? const Color(0xFFF6DED9) : const Color(0xFF3A1611),
      onErrorContainer:
          isLight ? const Color(0xFF4A150F) : const Color(0xFFF6D8D1),
      surface: paper,
      onSurface: ink,
      onSurfaceVariant: inkMuted,
      surfaceContainerLowest: ground,
      surfaceContainerLow: Color.lerp(ground, paper, 0.5)!,
      surfaceContainer: paper,
      surfaceContainerHigh: Color.lerp(paper, ink, isLight ? 0.035 : 0.05)!,
      surfaceContainerHighest:
          Color.lerp(paper, ink, isLight ? 0.065 : 0.09)!,
      outline: Color.lerp(ink, paper, 0.6)!,
      outlineVariant: rule,
      inverseSurface: ink,
      onInverseSurface: paper,
      inversePrimary: Color.lerp(rubric, paper, 0.55)!,
      shadow: const Color(0x00000000),
      scrim: const Color(0xFF000000).withValues(alpha: 0.45),
    );

    final text = _textTheme(ink, inkMuted, uiFamily, arabicFamily, arabicUi);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: ground,
      canvasColor: ground,
      textTheme: text,
      primaryTextTheme: text,
      fontFamily: uiFamily,
      fontFamilyFallback: [sans, arabicFamily],
      splashFactory: InkRipple.splashFactory,
      // No shadows anywhere: structure comes from fill and space.
      shadowColor: const Color(0x00000000),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: rubric,
        selectionColor: rubric.withValues(alpha: 0.22),
        selectionHandleColor: rubric,
      ),
      extensions: [
        ManuscriptTheme(
          rule: rule,
          ruleStrong: Color.lerp(paper, ink, isLight ? 0.22 : 0.28)!,
          rubric: rubric,
          gilt: gilt,
          paper: paper,
          ground: ground,
          field: field,
          onField: onField,
        ),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: ground,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: Ms.margin,
        iconTheme: IconThemeData(color: ink, size: 24),
        actionsIconTheme: IconThemeData(color: ink, size: 22),
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: paper,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Ms.rPanel),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: rule,
        thickness: Ms.hair,
        space: Ms.hair,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ground,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Color.lerp(ground, rubric, isLight ? 0.13 : 0.22),
        indicatorShape: const StadiumBorder(),
        elevation: 0,
        height: 74,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected) ? rubric : inkMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium!.copyWith(
            color: states.contains(WidgetState.selected) ? ink : inkMuted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: inkMuted,
        textColor: ink,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        selectedColor: rubric,
        selectedTileColor: rubric.withValues(alpha: isLight ? 0.07 : 0.12),
        contentPadding: const EdgeInsets.symmetric(horizontal: Ms.margin),
        minVerticalPadding: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Ms.rSmall),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          textStyle: text.labelLarge,
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: rubric,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: text.labelLarge,
          side: BorderSide(color: rubric.withValues(alpha: 0.35)),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: rubric,
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: text.labelLarge,
          shape: const StadiumBorder(),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: ink,
          highlightColor: rubric.withValues(alpha: 0.10),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: paper,
        selectedColor: accentTint,
        checkmarkColor: rubric,
        side: BorderSide.none,
        labelStyle: text.labelMedium!.copyWith(color: ink),
        secondaryLabelStyle: text.labelMedium!.copyWith(color: rubric),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        showCheckmark: false,
        shape: const StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: paper,
        hintStyle: text.bodyMedium!.copyWith(color: inkMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        border: _inputBorder(Colors.transparent),
        enabledBorder: _inputBorder(Colors.transparent),
        focusedBorder: _inputBorder(rubric, width: 1.5),
        errorBorder: _inputBorder(scheme.error),
        focusedErrorBorder: _inputBorder(scheme.error, width: 1.5),
        prefixIconColor: inkMuted,
        suffixIconColor: inkMuted,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: rubric,
        linearTrackColor: rubric.withValues(alpha: 0.13),
        circularTrackColor: rubric.withValues(alpha: 0.13),
        linearMinHeight: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? onRubric : inkMuted),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? rubric
                : Color.lerp(paper, ink, isLight ? 0.10 : 0.16)!),
        trackOutlineColor:
            const WidgetStatePropertyAll(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: rubric,
        inactiveTrackColor: rubric.withValues(alpha: 0.16),
        thumbColor: rubric,
        trackHeight: 4,
        overlayColor: rubric.withValues(alpha: 0.10),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? rubric : inkMuted),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? rubric
                : Colors.transparent),
        checkColor: WidgetStatePropertyAll(onRubric),
        side: BorderSide(color: inkMuted, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: Color.lerp(paper, ink, 0.2),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Ms.rSheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Ms.rSheet),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: paper,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: const Color(0x33000000),
        textStyle: text.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: text.bodyMedium!.copyWith(color: paper),
        actionTextColor: Color.lerp(gilt, paper, 0.3),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: text.bodySmall!.copyWith(color: paper),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: rubric,
        textColor: onRubric,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SettleTransitions(),
          TargetPlatform.iOS: _SettleTransitions(),
          TargetPlatform.windows: _SettleTransitions(),
          TargetPlatform.macOS: _SettleTransitions(),
          TargetPlatform.linux: _SettleTransitions(),
        },
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Ms.rInput),
        borderSide: color == Colors.transparent
            ? BorderSide.none
            : BorderSide(color: color, width: width),
      );

  /// The dark or the light ink, whichever contrasts more with [background].
  static Color _readableOn(Color background) {
    const dark = Color(0xFF111416);
    const light = Color(0xFFF7F5EF);
    final bg = background.computeLuminance();
    double contrast(Color c) {
      final l = c.computeLuminance();
      return (l > bg ? l + 0.05 : bg + 0.05) / (l > bg ? bg + 0.05 : l + 0.05);
    }

    return contrast(dark) >= contrast(light) ? dark : light;
  }

  /// The type scale.
  ///
  /// One face at four weights. Hierarchy is carried by size and weight, never
  /// by capitals or tracking: labels are set in sentence case. Display sizes
  /// close up slightly, the way large sans figures need to.
  ///
  /// When the interface language is right-to-left two Latin habits go.
  /// **Letter-spacing is dropped**: Arabic is cursive, and tracking prises
  /// joined letters apart. **Leading is opened up** so marks above and below
  /// the line don't collide.
  static TextTheme _textTheme(
    Color ink,
    Color muted,
    String family,
    String arabicFamily,
    bool arabicUi,
  ) {
    double lead(double h) => arabicUi ? h * 1.2 : h;
    double track(double s) => arabicUi ? 0 : s;

    TextStyle style(
      double size,
      FontWeight weight, {
      double height = 1.3,
      double spacing = 0,
      Color? color,
    }) =>
        TextStyle(
          fontFamily: family,
          fontFamilyFallback: [sans, arabicFamily],
          fontSize: size,
          fontWeight: weight,
          height: lead(height),
          letterSpacing: track(spacing),
          color: color ?? ink,
        );

    return TextTheme(
      // Display — the clock, the countdown, the tasbih count.
      displayLarge: style(56, FontWeight.w500, height: 1.0, spacing: -1.6),
      displayMedium: style(44, FontWeight.w500, height: 1.02, spacing: -1.1),
      displaySmall: style(34, FontWeight.w500, height: 1.06, spacing: -0.6),

      // Headline — screen titles and the focal field's lines.
      headlineLarge: style(30, FontWeight.w600, height: 1.15, spacing: -0.5),
      headlineMedium: style(25, FontWeight.w600, height: 1.2, spacing: -0.3),
      headlineSmall: style(21, FontWeight.w600, height: 1.25, spacing: -0.2),

      // Title — group headings, card headings, and list rows.
      titleLarge: style(21, FontWeight.w600, height: 1.25, spacing: -0.2),
      titleMedium: style(17, FontWeight.w600, height: 1.3, spacing: -0.1),
      titleSmall: style(15.5, FontWeight.w500, height: 1.32),

      // Body — prose, translations, descriptions.
      bodyLarge: style(16.5, FontWeight.w400, height: 1.6),
      bodyMedium: style(15, FontWeight.w400, height: 1.5),
      bodySmall: style(13, FontWeight.w400, height: 1.45, color: muted),

      // Label — buttons, counters, metadata.
      labelLarge: style(14.5, FontWeight.w600, spacing: 0.1),
      labelMedium: style(13, FontWeight.w500, spacing: 0.1),
      labelSmall: style(12, FontWeight.w500, spacing: 0.2, color: muted),
    );
  }
}

/// The page transition: a short fade with a small directional settle. Opacity
/// and translation only — nothing scales or bounces — and it collapses to an
/// instant cut when the platform reports that animations should be reduced.
class _SettleTransitions extends PageTransitionsBuilder {
  const _SettleTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.04, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
