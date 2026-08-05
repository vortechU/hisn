import 'package:flutter/material.dart';

/// A hand-tuned manuscript colour scheme.
///
/// Every palette is built from the five roles a scribe actually works with,
/// rather than from one seed colour run through Material's harmoniser — that
/// is what used to make the palettes read as tinted variants of a single
/// scheme instead of as distinct papers.
///
///   * [paper] / [paperDeep] — the ground. Warm, low-chroma, never pure white.
///   * [ink]                 — the text. Near-black, but carrying the paper's
///                             own temperature so type sits *in* the page.
///   * [rubric]              — the second ink: historically the colour used
///                             for headings, chapter marks and vowel points.
///                             Here it carries emphasis and the active state.
///   * [gilt]                — the illumination. Ornament, counters, and
///                             completion marks only. Never body text.
///
/// Dark mode is not an inversion. It is the same page under lamplight: the
/// ground falls to a deep, faintly warm brown-black, and the inks lift only
/// as far as legibility needs — never far enough to glow.
@immutable
class AppPalette {
  const AppPalette({
    required this.id,
    required this.paper,
    required this.paperDeep,
    required this.ink,
    required this.rubric,
    required this.gilt,
    required this.nightGround,
    required this.nightPaper,
    required this.nightInk,
    required this.nightRubric,
    required this.nightGilt,
  });

  /// Stable key persisted in preferences and used for translated names.
  final String id;

  /// The ground of a text block or ruled panel, in light mode.
  final Color paper;

  /// The page behind those blocks — a shade deeper than [paper], so panels
  /// read as sheets laid on a desk rather than as regions of one flat fill.
  final Color paperDeep;

  /// Primary text colour in light mode.
  final Color ink;

  /// The heading and emphasis ink (the historical rubric).
  final Color rubric;

  /// The illumination accent: ornament, counters, completion.
  final Color gilt;

  /// Dark-mode counterparts of [paperDeep], [paper], [ink], [rubric], [gilt].
  final Color nightGround;
  final Color nightPaper;
  final Color nightInk;
  final Color nightRubric;
  final Color nightGilt;

  Color inkFor(Brightness b) => b == Brightness.light ? ink : nightInk;
  Color rubricFor(Brightness b) => b == Brightness.light ? rubric : nightRubric;
  Color giltFor(Brightness b) => b == Brightness.light ? gilt : nightGilt;
  Color paperFor(Brightness b) => b == Brightness.light ? paper : nightPaper;
  Color groundFor(Brightness b) =>
      b == Brightness.light ? paperDeep : nightGround;

  /// The colour of ruled lines — frames, dividers, table rules. Pulled toward
  /// the ink so rules recede behind the text they organise, while still
  /// belonging to this palette's own ink family.
  Color ruleFor(Brightness b) => b == Brightness.light
      ? Color.lerp(rubric, ink, 0.45)!.withValues(alpha: 0.40)
      : Color.lerp(nightRubric, nightInk, 0.5)!.withValues(alpha: 0.34);
}

/// The six manuscript schemes offered in Appearance settings.
///
/// Each is named for a material tradition and tuned by eye: the papers differ
/// in temperature as well as in value, and no two share a rubric.
class AppPalettes {
  AppPalettes._();

  /// Bulaq Press, Cairo — cream rag paper, sepia-black ink, and the deep
  /// emerald that has been this app's identity from the start. The default.
  static const emerald = AppPalette(
    id: 'emerald',
    paper: Color(0xFFF7F2E6),
    paperDeep: Color(0xFFEDE5D3),
    ink: Color(0xFF221E18),
    rubric: Color(0xFF0C5A4C),
    gilt: Color(0xFF9C7B2E),
    nightGround: Color(0xFF0E1211),
    nightPaper: Color(0xFF161B19),
    nightInk: Color(0xFFE8E1D1),
    nightRubric: Color(0xFF58C3AB),
    nightGilt: Color(0xFFCDA84E),
  );

  /// Timurid Herat — cool ivory and lapis lazuli, the blue of Persian
  /// illumination, with a restrained gold.
  static const sapphire = AppPalette(
    id: 'sapphire',
    paper: Color(0xFFF4F3EE),
    paperDeep: Color(0xFFE6E6DF),
    ink: Color(0xFF1B1E24),
    rubric: Color(0xFF1B4B8F),
    gilt: Color(0xFFA8843A),
    nightGround: Color(0xFF0B0E14),
    nightPaper: Color(0xFF131720),
    nightInk: Color(0xFFDFE3EA),
    nightRubric: Color(0xFF7FAEEC),
    nightGilt: Color(0xFFC9A356),
  );

  /// Deccan aubergine — the muted plum of Bijapur bindings. Deliberately low
  /// in chroma and warm-leaning, so it reads as dyed cloth rather than as a
  /// screen purple.
  static const amethyst = AppPalette(
    id: 'amethyst',
    paper: Color(0xFFF5F0EE),
    paperDeep: Color(0xFFE8E0DF),
    ink: Color(0xFF241C22),
    rubric: Color(0xFF5C3357),
    gilt: Color(0xFF9E7C46),
    nightGround: Color(0xFF120E12),
    nightPaper: Color(0xFF1A151A),
    nightInk: Color(0xFFE7DDE4),
    nightRubric: Color(0xFFC094B8),
    nightGilt: Color(0xFFC6A25C),
  );

  /// Ottoman madder — the blush-cream paper and true red lake of Istanbul
  /// chancery work.
  static const rosewood = AppPalette(
    id: 'rosewood',
    paper: Color(0xFFF8F0E9),
    paperDeep: Color(0xFFEEE0D7),
    ink: Color(0xFF26191A),
    rubric: Color(0xFF94302F),
    gilt: Color(0xFFA57C33),
    nightGround: Color(0xFF130E0E),
    nightPaper: Color(0xFF1C1414),
    nightInk: Color(0xFFEDDFDA),
    nightRubric: Color(0xFFE28A80),
    nightGilt: Color(0xFFCDA35A),
  );

  /// Andalusi zellij — the teal-and-terracotta pairing of Córdoba and Fez.
  /// Here the illumination role is carried by terracotta rather than gold.
  static const lagoon = AppPalette(
    id: 'lagoon',
    paper: Color(0xFFF2F4EF),
    paperDeep: Color(0xFFE2E7E0),
    ink: Color(0xFF17201E),
    rubric: Color(0xFF0F6E6B),
    gilt: Color(0xFFB2603C),
    nightGround: Color(0xFF0A100F),
    nightPaper: Color(0xFF111917),
    nightInk: Color(0xFFDEE7E3),
    nightRubric: Color(0xFF4FC9BF),
    nightGilt: Color(0xFFE08A64),
  );

  /// Ṣanʿāʾ vellum — tan hide, brown-black ink and burnt sienna, after the
  /// earliest Hijazi and Kufic codices.
  static const desert = AppPalette(
    id: 'desert',
    paper: Color(0xFFF4EDDD),
    paperDeep: Color(0xFFE7DBC4),
    ink: Color(0xFF2A2018),
    rubric: Color(0xFF7A4A22),
    // Darker than the other palettes' gilt: the vellum ground is the palest of
    // the six, and a brighter brass fell below 3:1 against it.
    gilt: Color(0xFF96742C),
    nightGround: Color(0xFF12100C),
    nightPaper: Color(0xFF1B1712),
    nightInk: Color(0xFFEBE0CB),
    nightRubric: Color(0xFFD69A62),
    nightGilt: Color(0xFFC9A559),
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
