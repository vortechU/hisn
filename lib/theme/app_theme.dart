import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Manuscript design tokens that have no home in a [ColorScheme].
///
/// The app's surfaces are organised by *rules* and by small differences in
/// paper value — the way a printed page is — rather than by elevation. There
/// are no drop shadows anywhere in this theme, so these tokens (and the radius
/// scale on [Ms]) carry most of the visual structure.
@immutable
class ManuscriptTheme extends ThemeExtension<ManuscriptTheme> {
  const ManuscriptTheme({
    required this.rule,
    required this.ruleStrong,
    required this.rubric,
    required this.gilt,
    required this.paper,
    required this.ground,
  });

  /// Hairline rules: frame inners, dividers, table lines.
  final Color rule;

  /// The heavier outer rule of a jadwal frame.
  final Color ruleStrong;

  /// The second ink — headings, active state, emphasis.
  final Color rubric;

  /// Illumination: ornament, counters, completion marks.
  final Color gilt;

  /// The ground of a text block.
  final Color paper;

  /// The page behind the blocks.
  final Color ground;

  @override
  ManuscriptTheme copyWith({
    Color? rule,
    Color? ruleStrong,
    Color? rubric,
    Color? gilt,
    Color? paper,
    Color? ground,
  }) =>
      ManuscriptTheme(
        rule: rule ?? this.rule,
        ruleStrong: ruleStrong ?? this.ruleStrong,
        rubric: rubric ?? this.rubric,
        gilt: gilt ?? this.gilt,
        paper: paper ?? this.paper,
        ground: ground ?? this.ground,
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
    );
  }

  /// The manuscript tokens for [context].
  static ManuscriptTheme of(BuildContext context) =>
      Theme.of(context).extension<ManuscriptTheme>()!;
}

/// Shared manuscript constants: the radius and rule scales.
///
/// Radii are deliberately tiny. A printed page has cut corners, not rounded
/// ones; the small values here exist only to keep antialiasing clean, and the
/// scale is *differentiated* — a badge is not framed like a sheet.
class Ms {
  Ms._();

  /// Badges, chips, inputs, counters.
  static const double rSmall = 2;

  /// Ruled panels and cards.
  static const double rPanel = 3;

  /// Sheets, dialogs, bottom sheets.
  static const double rSheet = 5;

  /// Hairline rule weight.
  static const double hair = 1;

  /// The heavier outer rule of a frame.
  static const double stroke = 2;

  /// The gutter between an outer and inner rule in a jadwal frame.
  static const double gutter = 3;

  /// The page margin used by every scrolling surface.
  static const double margin = 18;
}

/// Centralised fonts and [ThemeData].
///
/// Two Latin faces, used for different jobs, the way a critical edition is
/// set: **Crimson Pro** carries content (headings, prose, translations) and
/// **Karla** carries the apparatus (labels, numerals, buttons, metadata).
/// Crimson Pro is not an arbitrary pick — it is the Latin companion Khaled
/// Hosny designed Amiri, the app's Arabic face, to sit beside.
///
/// Both Latin faces are subset to Latin ranges and carry **no Arabic glyphs**,
/// so every style here declares an Arabic fallback. Without it, Arabic UI
/// strings — the whole of the chrome when the app is in Arabic — silently drop
/// to whatever Arabic font the platform happens to ship, which sits badly
/// beside the Amiri-set dua text.
class AppTheme {
  AppTheme._();

  /// Default Arabic family. The active one comes from Display settings and is
  /// passed into [light]/[dark] so the chrome matches the dua text.
  static const String arabicFont = 'Amiri';

  /// The content serif: headings, prose, translations.
  static const String serif = 'Crimson Pro';

  /// The apparatus sans: labels, numerals, buttons, metadata.
  static const String sans = 'Karla';

  /// [palette] in light mode.
  ///
  /// [arabicFamily] is the bundled Arabic face to fall back to; [arabicUi] is
  /// whether the interface language itself is Arabic, which changes how the
  /// label styles are set (see [_textTheme]).
  static ThemeData light(
    AppPalette palette, {
    String arabicFamily = arabicFont,
    bool arabicUi = false,
  }) =>
      _build(palette, Brightness.light, arabicFamily, arabicUi);

  /// [palette] in dark mode. See [light] for the parameters.
  static ThemeData dark(
    AppPalette palette, {
    String arabicFamily = arabicFont,
    bool arabicUi = false,
  }) =>
      _build(palette, Brightness.dark, arabicFamily, arabicUi);

  static ThemeData _build(AppPalette palette, Brightness brightness,
      String arabicFamily, bool arabicUi) {
    final isLight = brightness == Brightness.light;
    final ink = palette.inkFor(brightness);
    final rubric = palette.rubricFor(brightness);
    final gilt = palette.giltFor(brightness);
    final paper = palette.paperFor(brightness);
    final ground = palette.groundFor(brightness);
    final rule = palette.ruleFor(brightness);

    // Secondary ink for metadata and captions. This is body-weight text, not
    // decoration, so it has to clear 4.5:1 against paper. The light-mode blend
    // is capped at 0.34 because 0.365 is where the palest of the six papers
    // (desert vellum) drops below AA — a single safe value beats six.
    final inkMuted = Color.lerp(ink, paper, isLight ? 0.34 : 0.40)!;
    final onRubric = _readableOn(rubric);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: rubric,
      onPrimary: onRubric,
      primaryContainer: Color.lerp(rubric, paper, isLight ? 0.86 : 0.78)!,
      onPrimaryContainer: isLight ? Color.lerp(rubric, ink, 0.3)! : ink,
      secondary: gilt,
      onSecondary: _readableOn(gilt),
      secondaryContainer: Color.lerp(gilt, paper, isLight ? 0.84 : 0.78)!,
      onSecondaryContainer: isLight ? Color.lerp(gilt, ink, 0.4)! : ink,
      tertiary: gilt,
      onTertiary: _readableOn(gilt),
      error: isLight ? const Color(0xFF8E2C22) : const Color(0xFFE59084),
      onError: isLight ? const Color(0xFFFFF6F3) : const Color(0xFF2A0F0B),
      errorContainer: isLight ? const Color(0xFFF3DCD6) : const Color(0xFF37150F),
      onErrorContainer: isLight ? const Color(0xFF4A150F) : const Color(0xFFF6D8D1),
      surface: paper,
      onSurface: ink,
      onSurfaceVariant: inkMuted,
      surfaceContainerLowest: ground,
      surfaceContainerLow: Color.lerp(ground, paper, 0.5)!,
      surfaceContainer: paper,
      surfaceContainerHigh: Color.lerp(paper, ink, isLight ? 0.04 : 0.06)!,
      surfaceContainerHighest: Color.lerp(paper, ink, isLight ? 0.07 : 0.10)!,
      outline: Color.lerp(ink, paper, 0.55)!,
      outlineVariant: rule,
      inverseSurface: ink,
      onInverseSurface: paper,
      inversePrimary: Color.lerp(rubric, paper, 0.55)!,
      shadow: const Color(0x00000000),
      scrim: ink.withValues(alpha: 0.5),
    );

    final text = _textTheme(ink, inkMuted, arabicFamily, arabicUi);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: ground,
      canvasColor: ground,
      textTheme: text,
      primaryTextTheme: text,
      fontFamily: sans,
      fontFamilyFallback: [arabicFamily],
      splashFactory: InkRipple.splashFactory,
      // No shadows anywhere: structure comes from rules and paper value.
      shadowColor: const Color(0x00000000),
      extensions: [
        ManuscriptTheme(
          rule: rule,
          ruleStrong: Color.lerp(rule, ink, 0.35)!.withValues(alpha: 0.65),
          rubric: rubric,
          gilt: gilt,
          paper: paper,
          ground: ground,
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
        iconTheme: IconThemeData(color: ink, size: 22),
        actionsIconTheme: IconThemeData(color: inkMuted, size: 22),
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: paper,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Ms.rPanel),
          side: BorderSide(color: rule, width: Ms.hair),
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
        indicatorColor: rubric.withValues(alpha: isLight ? 0.11 : 0.18),
        // A cut rectangle, not a pill — the nav follows the same radius scale
        // as every other surface.
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Ms.rSmall),
        ),
        elevation: 0,
        height: 66,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected) ? rubric : inkMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall!.copyWith(
            color: states.contains(WidgetState.selected) ? rubric : inkMuted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Ms.rSmall),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: rubric,
          foregroundColor: onRubric,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Ms.rSmall),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: rubric,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: text.labelLarge,
          side: BorderSide(color: rubric.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Ms.rSmall),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: rubric,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Ms.rSmall),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: inkMuted,
          highlightColor: rubric.withValues(alpha: 0.10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Ms.rSmall),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: rubric.withValues(alpha: isLight ? 0.12 : 0.20),
        checkmarkColor: rubric,
        side: BorderSide(color: rule),
        labelStyle: text.labelMedium!.copyWith(color: ink),
        secondaryLabelStyle: text.labelMedium!.copyWith(color: rubric),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        showCheckmark: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Ms.rSmall),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: paper,
        hintStyle: text.bodyMedium!.copyWith(color: inkMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: _inputBorder(rule),
        enabledBorder: _inputBorder(rule),
        focusedBorder: _inputBorder(rubric, width: 1.4),
        errorBorder: _inputBorder(scheme.error),
        focusedErrorBorder: _inputBorder(scheme.error, width: 1.4),
        prefixIconColor: inkMuted,
        suffixIconColor: inkMuted,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: rubric,
        linearTrackColor: rubric.withValues(alpha: 0.14),
        circularTrackColor: rubric.withValues(alpha: 0.14),
        linearMinHeight: 3,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? onRubric : paper),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? rubric
                : Color.lerp(ground, ink, 0.10)!),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? rubric : rule),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: rubric,
        inactiveTrackColor: rubric.withValues(alpha: 0.16),
        thumbColor: rubric,
        trackHeight: 2,
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
        side: BorderSide(color: inkMuted, width: 1.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Ms.rSmall),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: rule,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Ms.rSheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Ms.rSheet),
          side: BorderSide(color: rule),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: text.bodyMedium!.copyWith(color: paper),
        actionTextColor: gilt,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Ms.rSmall),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(Ms.rSmall),
        ),
        textStyle: text.bodySmall!.copyWith(color: paper),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _LeafTurnTransitions(),
          TargetPlatform.iOS: _LeafTurnTransitions(),
          TargetPlatform.windows: _LeafTurnTransitions(),
          TargetPlatform.macOS: _LeafTurnTransitions(),
          TargetPlatform.linux: _LeafTurnTransitions(),
        },
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Ms.rSmall),
        borderSide: BorderSide(color: color, width: width),
      );

  /// Black or white, whichever reads better on [background].
  static Color _readableOn(Color background) =>
      background.computeLuminance() > 0.45
          ? const Color(0xFF1A1510)
          : const Color(0xFFFBF7EE);

  /// The type scale.
  ///
  /// Content is set in Crimson Pro and apparatus in Karla. Sizes follow a
  /// roughly 1.22 modular scale; only three weights are used across both
  /// faces (400 / 600–500 / 700). Label styles carry the wide tracking that
  /// small caps-height sans text needs to read as a heading rather than as
  /// shrunken body copy.
  ///
  /// When the interface language is Arabic two of those Latin habits have to
  /// go. **Letter-spacing is dropped**: Arabic is cursive, and tracking prises
  /// joined letters apart. **Leading is opened up**: Amiri sets its harakat
  /// well above the baseline, and the tight Latin line heights clip them.
  static TextTheme _textTheme(
      Color ink, Color muted, String arabicFamily, bool arabicUi) {
    // Arabic needs roughly a quarter more leading than the Latin faces before
    // its diacritics stop touching the line above.
    double lead(double h) => arabicUi ? h * 1.28 : h;
    double track(double s) => arabicUi ? 0 : s;

    TextStyle serifStyle(
      double size,
      FontWeight weight, {
      double height = 1.25,
      double spacing = 0,
      Color? color,
    }) =>
        TextStyle(
          fontFamily: serif,
          fontFamilyFallback: [arabicFamily],
          fontSize: size,
          fontWeight: weight,
          height: lead(height),
          letterSpacing: track(spacing),
          color: color ?? ink,
        );

    TextStyle sansStyle(
      double size,
      FontWeight weight, {
      double height = 1.3,
      double spacing = 0,
      Color? color,
    }) =>
        TextStyle(
          fontFamily: sans,
          fontFamilyFallback: [arabicFamily],
          fontSize: size,
          fontWeight: weight,
          height: lead(height),
          letterSpacing: track(spacing),
          color: color ?? ink,
        );

    return TextTheme(
      // Display — the clock, the tasbih count. Set in the serif so the app's
      // largest numerals share the page's voice.
      displayLarge: serifStyle(52, FontWeight.w600, height: 1.0),
      displayMedium: serifStyle(42, FontWeight.w600, height: 1.02),
      displaySmall: serifStyle(34, FontWeight.w600, height: 1.05),

      // Headline — screen titles, ʿunwān plates.
      headlineLarge: serifStyle(30, FontWeight.w600, height: 1.14),
      headlineMedium: serifStyle(25, FontWeight.w600, height: 1.18),
      headlineSmall: serifStyle(21, FontWeight.w600, height: 1.22),

      // Title — card headings and list rows.
      titleLarge: serifStyle(21, FontWeight.w600, height: 1.24),
      titleMedium: serifStyle(18, FontWeight.w600, height: 1.3),
      titleSmall: serifStyle(16.5, FontWeight.w600, height: 1.32),

      // Body — prose, translations, descriptions.
      bodyLarge: serifStyle(17.5, FontWeight.w400, height: 1.52),
      bodyMedium: serifStyle(16, FontWeight.w400, height: 1.5),
      bodySmall: sansStyle(13, FontWeight.w400, height: 1.45, color: muted),

      // Label — the apparatus: buttons, counters, section marks, metadata.
      labelLarge: sansStyle(14, FontWeight.w700, spacing: 0.2),
      labelMedium: sansStyle(12.5, FontWeight.w500, spacing: 0.3),
      labelSmall: sansStyle(11, FontWeight.w700, spacing: 1.3, color: muted),
    );
  }
}

/// A page transition modelled on turning a leaf: a cross-fade with a small
/// directional settle. Limited to opacity and translation — nothing scales or
/// bounces — and it collapses to an instant cut when the platform reports
/// that animations should be reduced.
class _LeafTurnTransitions extends PageTransitionsBuilder {
  const _LeafTurnTransitions();

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
          begin: const Offset(0.035, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
