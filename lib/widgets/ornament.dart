import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/theme_controller.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';

/// The manuscript ornament vocabulary: ruled frames, illuminated headpieces,
/// verse rosettes, and the geometric ground.
///
/// These are the pieces that carry the app's identity, so they are drawn
/// rather than approximated with borders and emoji. Everything here is
/// constructed from the real geometry — the tessellation is a genuine
/// octagon-and-square (*khātam*) tiling, and the rosettes are lobed the way
/// verse markers are lobed — because an approximation of a geometric tradition
/// reads as an approximation.

// ---------------------------------------------------------------------------
// Ruled frames
// ---------------------------------------------------------------------------

/// A *jadwal*: the ruled frame that borders a manuscript text block.
///
/// Two rules — a heavier outer and a hairline inner, separated by a narrow
/// gutter — instead of a drop shadow. This is the app's primary container, and
/// the reason nothing in the theme needs elevation.
class JadwalFrame extends StatelessWidget {
  const JadwalFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.background,
    this.accent,
    this.emphasis = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Fill for the inner block. Defaults to the palette's paper.
  final Color? background;

  /// Overrides the rule colour — used to mark a block as belonging to a
  /// particular section, or as complete.
  final Color? accent;

  /// Draws the outer rule at full strength. Used for the one dominant block
  /// on a screen, so that a page has a clear first read.
  final bool emphasis;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ms = ManuscriptTheme.of(context);
    final outer = accent?.withValues(alpha: emphasis ? 0.85 : 0.5) ??
        (emphasis ? ms.ruleStrong : ms.rule);
    final inner = accent?.withValues(alpha: 0.32) ?? ms.rule;

    Widget content = Container(
      decoration: BoxDecoration(
        color: background ?? ms.paper,
        border: Border.all(color: inner, width: Ms.hair),
        borderRadius: BorderRadius.circular(Ms.rPanel - 1),
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Ms.rPanel - 1),
          child: content,
        ),
      );
    }

    // The heavier rule is taken out of the gutter, not out of the block it
    // frames. A border widens inwards, so letting it grow would narrow the
    // content by the difference — and a card that gains emphasis while it is
    // being read (a dua reaching its count) would reflow its text and pick up
    // a line. The gutter gives the extra pixel back, leaving the inner block
    // the same size whether the frame is emphasised or not.
    final rule = emphasis ? Ms.stroke : Ms.hair;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: outer, width: rule),
        borderRadius: BorderRadius.circular(Ms.rPanel),
      ),
      padding: EdgeInsets.all(Ms.gutter + Ms.hair - rule),
      child: content,
    );
  }
}

// ---------------------------------------------------------------------------
// Rosettes and rules
// ---------------------------------------------------------------------------

/// A lobed verse-rosette, the marker that separates āyāt in a mushaf.
///
/// This is a *mark in its own right* — a bullet, a divider's centre, a
/// completion tick. It deliberately takes no child: wrapping an icon in it put
/// two ornaments on the same job and made every list read as a row of medallions.
/// Icons in this app stand on their own, tinted, with no container.
class Rosette extends StatelessWidget {
  const Rosette({
    super.key,
    this.size = 18,
    this.color,
    this.lobes = 8,
    this.filled = false,
  });

  final double size;
  final Color? color;
  final int lobes;

  /// Fills the centre with [color] at low alpha — used to mark completion.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? ManuscriptTheme.of(context).gilt;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RosettePainter(tint, lobes, filled),
      ),
    );
  }
}

class _RosettePainter extends CustomPainter {
  _RosettePainter(this.color, this.lobes, this.filled);

  final Color color;
  final int lobes;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    // The lobe radius that makes adjacent lobes just touch on the ring.
    final ring = outer * 0.74;
    final lobe = ring * math.sin(math.pi / lobes) * 1.05;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, outer * 0.075)
      ..isAntiAlias = true;

    for (var i = 0; i < lobes; i++) {
      final a = (i / lobes) * 2 * math.pi - math.pi / 2;
      canvas.drawCircle(
        centre + Offset(math.cos(a) * ring, math.sin(a) * ring),
        lobe,
        stroke,
      );
    }

    final inner = ring - lobe * 0.35;
    if (filled) {
      canvas.drawCircle(
        centre,
        inner,
        Paint()..color = color.withValues(alpha: 0.16),
      );
    }
    canvas.drawCircle(centre, inner, stroke);
  }

  @override
  bool shouldRepaint(_RosettePainter old) =>
      old.color != color || old.lobes != lobes || old.filled != filled;
}

/// A round meter that illuminates as a count advances.
///
/// With [lobes] above zero it reads twice: a continuous arc for the exact
/// fraction, and beads that ink in one at a time so partial progress is
/// countable at a glance. That belongs on the tasbih, where the beads *are*
/// the subject. Pass `lobes: 0` everywhere else for the plain arc — a ring of
/// beads around every meter in the app is too much ornament for the job.
class ProgressRosette extends StatelessWidget {
  const ProgressRosette({
    super.key,
    required this.fraction,
    this.size = 64,
    this.lobes = 8,
    this.color,
    this.track,
    this.child,
  });

  final double fraction;
  final double size;
  final int lobes;
  final Color? color;
  final Color? track;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final ms = ManuscriptTheme.of(context);
    final tint = color ?? ms.gilt;
    final rail = track ?? ms.rule;

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        duration: Motion.of(context, Motion.settle),
        curve: Curves.easeOut,
        tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
        builder: (context, value, inner) => CustomPaint(
          painter: _ProgressRosettePainter(value, tint, rail, lobes),
          child: inner,
        ),
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

class _ProgressRosettePainter extends CustomPainter {
  _ProgressRosettePainter(this.value, this.color, this.track, this.lobes);

  final double value;
  final Color color;
  final Color track;
  final int lobes;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    final ring = outer * 0.80;
    final lobe = lobes == 0 ? 0.0 : ring * math.sin(math.pi / lobes);
    final weight = math.max(1.0, outer * 0.055);

    final rail = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = weight
      ..isAntiAlias = true;
    final inked = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = weight
      ..isAntiAlias = true;
    final solid = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..isAntiAlias = true;

    final filled = (value * lobes).floor();
    for (var i = 0; i < lobes; i++) {
      final a = (i / lobes) * 2 * math.pi - math.pi / 2;
      final at = centre + Offset(math.cos(a) * ring, math.sin(a) * ring);
      final done = i < filled;
      if (done) canvas.drawCircle(at, lobe, solid);
      canvas.drawCircle(at, lobe, done ? inked : rail);
    }

    // The exact fraction, as an arc — just inside the beads when there are
    // any, otherwise out at the rim on its own.
    final arcR = lobes == 0 ? ring : ring - lobe - weight;
    if (arcR > 0) {
      canvas.drawCircle(centre, arcR, rail);
      if (value > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: centre, radius: arcR),
          -math.pi / 2,
          value * 2 * math.pi,
          false,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = weight * 1.2
            ..strokeCap = StrokeCap.butt
            ..isAntiAlias = true,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ProgressRosettePainter old) =>
      old.value != value ||
      old.color != color ||
      old.track != track ||
      old.lobes != lobes;
}

/// A rule that inks in from the leading edge as a value advances — the app's
/// linear meter. A 2px mark, not a capsule.
class ProgressRule extends StatelessWidget {
  const ProgressRule({
    super.key,
    required this.value,
    this.color,
    this.track,
    this.thickness = 2,
  });

  final double value;
  final Color? color;
  final Color? track;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final ms = ManuscriptTheme.of(context);
    return SizedBox(
      height: thickness,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            Container(color: track ?? ms.rule),
            AnimatedContainer(
              duration: Motion.of(context, Motion.settle),
              curve: Curves.easeOut,
              width: constraints.maxWidth * value.clamp(0.0, 1.0),
              color: color ?? ms.gilt,
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontal rule, optionally broken at the centre by a rosette — the way a
/// manuscript separates one movement of text from the next.
class RuleDivider extends StatelessWidget {
  const RuleDivider({
    super.key,
    this.ornament = true,
    this.color,
    this.indent = 0,
  });

  final bool ornament;
  final Color? color;
  final double indent;

  @override
  Widget build(BuildContext context) {
    final ms = ManuscriptTheme.of(context);
    final line = color ?? ms.rule;
    final side = Expanded(child: Container(height: Ms.hair, color: line));

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: indent, vertical: 10),
      child: Row(
        children: ornament
            ? [
                side,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Rosette(size: 13, color: color ?? ms.gilt, lobes: 6),
                ),
                side,
              ]
            : [side],
      ),
    );
  }
}

/// A section mark: a short rule, a label in the apparatus face, and a trailing
/// rule that runs to the page edge. Replaces the free-floating uppercase
/// caption that every list section otherwise gets.
class SectionMark extends StatelessWidget {
  const SectionMark({
    super.key,
    required this.label,
    this.trailing,
    this.color,
  });

  final String label;
  final Widget? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final tint = color ?? ms.rubric;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Ms.margin, 26, Ms.margin, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(width: 14, height: Ms.stroke, color: tint),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: tint),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: Ms.hair, color: ms.rule)),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The illuminated headpiece
// ---------------------------------------------------------------------------

/// An *ʿunwān*: the illuminated panel that opens a manuscript.
///
/// A framed band carrying a title between two rosettes, laid over the
/// geometric ground. Used for the app's one hero surface per screen.
class UnwanPlate extends StatelessWidget {
  const UnwanPlate({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 18),
    this.onTap,
    this.pattern = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Whether the geometric ground shows behind the content.
  final bool pattern;

  @override
  Widget build(BuildContext context) {
    final ms = ManuscriptTheme.of(context);

    Widget body = Stack(
      children: [
        if (pattern)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Ms.rPanel - 1),
              // Kept faint and on a large cell: the ground should be felt
              // rather than read, and a tight tessellation behind a clock
              // starts competing with it.
              child: GirihField(color: ms.rubric, opacity: 0.055, side: 26),
            ),
          ),
        Padding(padding: padding, child: child),
      ],
    );

    if (onTap != null) {
      body = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Ms.rPanel - 1),
          child: body,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: ms.rubric.withValues(alpha: 0.55), width: Ms.stroke),
        borderRadius: BorderRadius.circular(Ms.rPanel),
      ),
      padding: const EdgeInsets.all(Ms.gutter),
      child: Container(
        decoration: BoxDecoration(
          color: ms.paper,
          border: Border.all(color: ms.gilt.withValues(alpha: 0.45), width: Ms.hair),
          borderRadius: BorderRadius.circular(Ms.rPanel - 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: body,
      ),
    );
  }
}

/// The title band of an [UnwanPlate]: a centred heading flanked by rosettes,
/// on a tinted ground.
class UnwanBand extends StatelessWidget {
  const UnwanBand({super.key, required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ms = ManuscriptTheme.of(context);
    final tint = color ?? ms.rubric;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        border: Border.symmetric(
          horizontal: BorderSide(color: tint.withValues(alpha: 0.35)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Rosette(size: 15, color: ms.gilt, lobes: 8),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: child,
            ),
          ),
          Rosette(size: 15, color: ms.gilt, lobes: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The geometric ground
// ---------------------------------------------------------------------------

/// The *khātam* ground: a true octagon-and-square tessellation with the
/// eight-point star polygon inscribed in each octagon.
///
/// This is the classical construction — regular octagons on a square lattice
/// of spacing `s(1+√2)`, the gaps filled by squares of the same side, and the
/// {8/3} star drawn inside each octagon by joining every third vertex. It
/// paints only when the user has patterns enabled (Appearance settings).
class GirihField extends StatelessWidget {
  const GirihField({
    super.key,
    required this.color,
    this.opacity = 0.08,
    this.side = 19,
  });

  /// Base colour of the strokes; [opacity] is applied to it.
  final Color color;
  final double opacity;

  /// Side length of the octagons, in logical pixels.
  final double side;

  @override
  Widget build(BuildContext context) {
    final enabled =
        context.select<ThemeController, bool>((c) => c.patternsEnabled);
    if (!enabled) return const SizedBox.shrink();
    return CustomPaint(
      size: Size.infinite,
      isComplex: true,
      willChange: false,
      painter: _KhatamPainter(color.withValues(alpha: opacity), side),
    );
  }
}

class _KhatamPainter extends CustomPainter {
  _KhatamPainter(this.color, this.side);

  final Color color;
  final double side;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeJoin = StrokeJoin.miter
      ..isAntiAlias = true;

    // Regular octagon of side `side`: circumradius, and the lattice spacing
    // that lets the octagons meet edge-to-edge with square gaps between.
    final r = side / (2 * math.sin(math.pi / 8));
    final pitch = side * (1 + math.sqrt2);
    final squareR = side / math.sqrt2;

    final path = Path();

    for (double cy = 0; cy <= size.height + pitch; cy += pitch) {
      for (double cx = 0; cx <= size.width + pitch; cx += pitch) {
        _octagonAndStar(path, Offset(cx, cy), r);
        // The square that fills the gap sits at the lattice half-offset,
        // rotated 45° so its corners meet the octagons' edges.
        _polygon(path, Offset(cx + pitch / 2, cy + pitch / 2), squareR, 4,
            math.pi / 4);
      }
    }
    canvas.drawPath(path, paint);
  }

  /// A regular octagon plus the {8/3} star polygon inscribed in it — the
  /// eight-point *khātam* formed by joining every third vertex.
  void _octagonAndStar(Path path, Offset c, double r) {
    // Rotated by half a step so the octagon presents flat top and sides.
    const twist = math.pi / 8;
    final v = List<Offset>.generate(8, (i) {
      final a = twist + i * math.pi / 4;
      return Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
    });

    path.addPolygon(v, true);
    for (var i = 0; i < 8; i++) {
      path.moveTo(v[i].dx, v[i].dy);
      final j = (i + 3) % 8;
      path.lineTo(v[j].dx, v[j].dy);
    }
  }

  void _polygon(Path path, Offset c, double r, int sides, double twist) {
    final v = List<Offset>.generate(sides, (i) {
      final a = twist + i * 2 * math.pi / sides;
      return Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
    });
    path.addPolygon(v, true);
  }

  @override
  bool shouldRepaint(_KhatamPainter old) =>
      old.color != color || old.side != side;
}

// ---------------------------------------------------------------------------
// Small marks
// ---------------------------------------------------------------------------

/// The app's empty and hint page: a rosette mark, a heading, a rule, and one
/// line of explanation.
///
/// One shared component so that "nothing saved yet", "no results", and "start
/// typing" all read as the same blank leaf rather than as four differently
/// improvised screens.
class EmptyPage extends StatelessWidget {
  const EmptyPage({
    super.key,
    required this.icon,
    required this.body,
    this.title,
    this.action,
  });

  final IconData icon;
  final String body;
  final String? title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: ms.rubric.withValues(alpha: 0.55)),
            const SizedBox(height: 18),
            if (title != null) ...[
              Text(title!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge),
              const RuleDivider(indent: 46),
            ],
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// An eight-point *khātam* medallion with a numeral inside — the mark a mushaf
/// uses to number a sūrah or a juzʾ.
///
/// The star is the real {8/3} polygon (every third vertex of an octagon
/// joined), not a rounded square turned 45°.
class StarMedallion extends StatelessWidget {
  const StarMedallion({
    super.key,
    this.number,
    this.size = 40,
    this.color,
    this.filled = false,
    this.child,
  });

  /// The numeral to set inside the star. Ignored when [child] is given.
  final int? number;
  final double size;
  final Color? color;
  final bool filled;

  /// Arbitrary content for the centre — used where the numeral needs to be in
  /// Arabic-Indic digits rather than Latin ones.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? ManuscriptTheme.of(context).rubric;
    final inner = child ??
        (number == null
            ? null
            : Text(
                '$number',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: size * 0.3,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      letterSpacing: 0,
                      color: tint,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ));

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StarMedallionPainter(tint, filled),
        child: inner == null ? null : Center(child: inner),
      ),
    );
  }
}

class _StarMedallionPainter extends CustomPainter {
  _StarMedallionPainter(this.color, this.filled);

  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 1;

    // The khātam is two squares of equal circumradius, one turned 45° over the
    // other — an octagram {8/2}, which leaves a regular octagon at the centre
    // for the numeral to sit in.
    final path = Path()..fillType = PathFillType.nonZero;
    for (final twist in [0.0, math.pi / 4]) {
      path.addPolygon(
        List<Offset>.generate(4, (i) {
          final a = twist + i * math.pi / 2;
          return Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
        }),
        true,
      );
    }

    if (filled) {
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.15));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeJoin = StrokeJoin.miter
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_StarMedallionPainter old) =>
      old.color != color || old.filled != filled;
}

/// A quantity set in the apparatus face inside a hairline cartouche — the
/// app's counter, repeat badge, and tally mark.
class Cartouche extends StatelessWidget {
  const Cartouche({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.filled = false,
  });

  final String label;
  final Color? color;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ms = ManuscriptTheme.of(context);
    final tint = color ?? ms.rubric;

    return Container(
      padding: EdgeInsets.fromLTRB(icon == null ? 7 : 6, 3, 7, 3),
      decoration: BoxDecoration(
        color: filled ? tint.withValues(alpha: 0.13) : null,
        border: Border.all(color: tint.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(Ms.rSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12.5, color: tint),
            const SizedBox(width: 4),
          ],
          // Derived from the theme's label style rather than built from
          // scratch, so it inherits the Arabic fallback — a cartouche can hold
          // a translated word ("تم"), not only a numeral.
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: tint,
                  // Tabular figures keep a live counter from reflowing.
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
        ],
      ),
    );
  }
}

/// A numeral set in the serif with tabular figures — for clocks, counters and
/// anything that updates in place without shifting its neighbours.
class Numeral extends StatelessWidget {
  const Numeral(
    this.text, {
    super.key,
    this.size = 20,
    this.weight = FontWeight.w600,
    this.color,
    this.serif = true,
  });

  final String text;
  final double size;
  final FontWeight weight;
  final Color? color;
  final bool serif;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Built on a theme style so the Arabic fallback comes along; numerals are
    // Latin, but a countdown string like "2 س 14 د" is not.
    final base =
        serif ? theme.textTheme.displaySmall : theme.textTheme.labelLarge;
    return Text(
      text,
      style: base?.copyWith(
        fontSize: size,
        fontWeight: weight,
        height: 1.05,
        letterSpacing: 0,
        color: color ?? theme.colorScheme.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
