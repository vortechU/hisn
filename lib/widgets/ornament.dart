import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/theme_controller.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';

/// The prayer-hall vocabulary: the mihrab field, soft panels, rings and bars,
/// and the few marks the app draws itself.
///
/// The rule the pieces share: nothing is outlined. A group is a fill a shade
/// off the ground, the one thing a screen is about sits in the mihrab, and
/// completion is the lamp colour arriving — not a frame thickening.

// ---------------------------------------------------------------------------
// The mihrab
// ---------------------------------------------------------------------------

/// The niche a screen is built around: a field whose top edge rises to a low
/// pointed arch, the way a mihrab marks the qibla wall.
///
/// One per screen, at most. Filled with the qibla ink by default, with its
/// content in [ManuscriptTheme.onField]; [soft] fills it with the raised paper
/// instead, for a niche that holds something drawn in page colours (the Qibla
/// compass).
class MihrabField extends StatelessWidget {
  const MihrabField({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 20),
    this.onTap,
    this.soft = false,
    this.pattern = true,
    this.rise,
  });

  final Widget child;

  /// Overrides the arch's height, for a compact field. By default the arch
  /// rises in proportion to the field's width ([riseFor]).
  final double? rise;

  /// Padding inside the field, below the arch. The arch's own rise is added
  /// to the top on top of this.
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool soft;

  /// Whether the carved-screen pattern shows faintly under the arch.
  final bool pattern;

  /// How high the arch rises for a field [width] wide.
  static double riseFor(double width) => math.min(60, width * 0.15);

  @override
  Widget build(BuildContext context) {
    final ms = ManuscriptTheme.of(context);
    final fill = soft ? ms.paper : ms.field;
    final ink = soft ? ms.rubric : ms.onField;

    return LayoutBuilder(
      builder: (context, constraints) {
        final rise = this.rise ?? riseFor(constraints.maxWidth);
        final shape = MihrabBorder(rise: rise);

        Widget body = Padding(
          padding: EdgeInsets.only(top: rise).add(padding),
          child: child,
        );

        if (pattern) {
          body = Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: rise + 70,
                child: GirihField(
                  color: ink,
                  opacity: soft ? 0.05 : 0.075,
                  side: 15,
                  fade: true,
                ),
              ),
              body,
            ],
          );
        }

        return Material(
          color: fill,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: onTap == null ? body : InkWell(onTap: onTap, child: body),
        );
      },
    );
  }
}

/// The outline of a [MihrabField]: straight jambs with softened foot corners,
/// rising into a low two-centred arch that meets in a gentle point.
class MihrabBorder extends OutlinedBorder {
  const MihrabBorder({this.rise = 40, this.radius = Ms.rPanel, super.side});

  /// Height of the arch above its springing line.
  final double rise;

  /// Radius of the two foot corners.
  final double radius;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect.deflate(side.width), textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final l = rect.left, t = rect.top, r = rect.right, b = rect.bottom;
    final w = rect.width;
    final mid = l + w / 2;
    final h = math.min(rise, rect.height / 3);
    final rad = math.min(radius, math.min(w, rect.height) / 4);

    return Path()
      ..moveTo(l, b - rad)
      ..lineTo(l, t + h)
      // Left half of the arch: up off the jamb, flattening, then turning in
      // to meet its twin at the apex at an angle — the point.
      ..cubicTo(l, t + h * 0.30, mid - w * 0.14, t + h * 0.26, mid, t)
      ..cubicTo(mid + w * 0.14, t + h * 0.26, r, t + h * 0.30, r, t + h)
      ..lineTo(r, b - rad)
      ..arcToPoint(Offset(r - rad, b), radius: Radius.circular(rad))
      ..lineTo(l + rad, b)
      ..arcToPoint(Offset(l, b - rad), radius: Radius.circular(rad))
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawPath(
      getOuterPath(rect, textDirection: textDirection),
      side.toPaint(),
    );
  }

  @override
  MihrabBorder scale(double t) =>
      MihrabBorder(rise: rise * t, radius: radius * t, side: side.scale(t));

  @override
  MihrabBorder copyWith({BorderSide? side, double? rise, double? radius}) =>
      MihrabBorder(
        rise: rise ?? this.rise,
        radius: radius ?? this.radius,
        side: side ?? this.side,
      );

  @override
  bool operator ==(Object other) =>
      other is MihrabBorder &&
      other.rise == rise &&
      other.radius == radius &&
      other.side == side;

  @override
  int get hashCode => Object.hash(rise, radius, side);
}

// ---------------------------------------------------------------------------
// Panels
// ---------------------------------------------------------------------------

/// The app's container: a soft panel a shade off the ground, no outline.
///
/// [accent] tints the fill toward a colour — the lamp, when what it holds is
/// finished — and [emphasis] deepens that tint. The fill eases between states,
/// because it changes under the reader's thumb (a dua reaching its count), and
/// the geometry never changes with it, so nothing reflows.
///
/// The name is kept from the manuscript frame this replaced.
class JadwalFrame extends StatelessWidget {
  const JadwalFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.background,
    this.accent,
    this.emphasis = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Fill for the panel. Defaults to the palette's paper.
  final Color? background;

  /// Tints the fill toward this colour.
  final Color? accent;

  /// Deepens the [accent] tint.
  final bool emphasis;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ms = ManuscriptTheme.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = background ?? ms.paper;
    final fill = accent == null
        ? base
        : Color.alphaBlend(
            accent!.withValues(
              alpha: (emphasis ? 0.085 : 0.05) * (dark ? 1.6 : 1),
            ),
            base,
          );

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: fill),
      duration: Motion.of(context, Motion.settle),
      curve: Curves.easeOut,
      builder: (context, color, inner) => Material(
        color: color,
        borderRadius: BorderRadius.circular(Ms.rPanel),
        clipBehavior: Clip.antiAlias,
        child: inner,
      ),
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : InkWell(
              onTap: onTap,
              child: Padding(padding: padding, child: child),
            ),
    );
  }
}

/// A group of rows on one panel, with faint separators inset past the rows'
/// leading marks — the settings list, the category lists, the timetable.
class RowGroup extends StatelessWidget {
  const RowGroup({super.key, required this.children, this.indent = 72});

  final List<Widget> children;

  /// Where the separators start, so they line up with the row titles rather
  /// than running under the icons.
  final double indent;

  @override
  Widget build(BuildContext context) {
    final ms = ManuscriptTheme.of(context);
    return Material(
      color: ms.paper,
      borderRadius: BorderRadius.circular(Ms.rPanel),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Padding(
                padding: EdgeInsetsDirectional.only(start: indent),
                child: Container(height: Ms.hair, color: ms.rule),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A round, tinted well for a row's leading icon.
class IconWell extends StatelessWidget {
  const IconWell({
    super.key,
    required this.icon,
    this.color,
    this.size = 40,
    this.filled = false,
  });

  final IconData icon;
  final Color? color;
  final double size;

  /// Fills the well solid with [color] and sets the icon in the page colour —
  /// the completed state.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ms = ManuscriptTheme.of(context);
    final tint = color ?? ms.rubric;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: Motion.of(context, Motion.settle),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? tint : tint.withValues(alpha: dark ? 0.18 : 0.11),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: filled ? ms.paper : tint,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Marks, rings and bars
// ---------------------------------------------------------------------------

/// A small round mark: an open ring, or — [filled] — a solid disc with a
/// check, for something finished.
///
/// The name and [lobes] are kept from the verse rosette this replaced; the
/// lobes no longer draw.
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
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ms = ManuscriptTheme.of(context);
    final tint = color ?? ms.gilt;
    return AnimatedContainer(
      duration: Motion.of(context, Motion.settle),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? tint : Colors.transparent,
        border: Border.all(
          color: filled ? tint : tint.withValues(alpha: 0.55),
          width: math.max(1.2, size * 0.09),
        ),
      ),
      child: filled
          ? Icon(Icons.check_rounded, size: size * 0.7, color: ms.paper)
          : null,
    );
  }
}

/// A round meter.
///
/// A continuous arc for the exact fraction; with [lobes] above zero, beads
/// around it that fill one at a time, so partial progress is countable at a
/// glance — that belongs on the tasbih, where the beads are the subject. Pass
/// `lobes: 0` everywhere else.
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
    final rail = track ?? tint.withValues(alpha: 0.16);

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        duration: Motion.of(context, Motion.settle),
        curve: Curves.easeOut,
        tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
        builder: (context, value, inner) => CustomPaint(
          painter: _RingPainter(value, tint, rail, lobes),
          child: inner,
        ),
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.color, this.track, this.lobes);

  final double value;
  final Color color;
  final Color track;
  final int lobes;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    final weight = math.max(3.0, outer * 0.075);
    final bead = lobes == 0 ? 0.0 : math.max(2.5, outer * 0.035);
    final arcR = outer - weight / 2 - (lobes == 0 ? 0 : bead * 2 + 6);

    final rail = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = weight
      ..isAntiAlias = true;
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
          ..strokeWidth = weight
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true,
      );
    }

    if (lobes > 0) {
      final ringR = outer - bead - 1;
      final filled = (value * lobes).floor();
      for (var i = 0; i < lobes; i++) {
        final a = (i / lobes) * 2 * math.pi - math.pi / 2;
        canvas.drawCircle(
          centre + Offset(math.cos(a) * ringR, math.sin(a) * ringR),
          bead,
          Paint()
            ..color = i < filled ? color : track
            ..isAntiAlias = true,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.color != color ||
      old.track != track ||
      old.lobes != lobes;
}

/// The app's linear meter: a rounded bar that fills from the leading edge.
class ProgressRule extends StatelessWidget {
  const ProgressRule({
    super.key,
    required this.value,
    this.color,
    this.track,
    this.thickness = 4,
  });

  final double value;
  final Color? color;
  final Color? track;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final ms = ManuscriptTheme.of(context);
    final tint = color ?? ms.gilt;
    final radius = BorderRadius.circular(thickness);
    return SizedBox(
      height: thickness,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: track ?? tint.withValues(alpha: 0.15),
                borderRadius: radius,
              ),
            ),
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              child: AnimatedContainer(
                duration: Motion.of(context, Motion.settle),
                curve: Curves.easeOut,
                width: constraints.maxWidth * value.clamp(0.0, 1.0),
                decoration: BoxDecoration(color: tint, borderRadius: radius),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A quiet break between two blocks: space with a faint line through it.
///
/// [ornament] is kept from the manuscript divider this replaced and no longer
/// draws anything extra.
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: indent, vertical: 12),
      child: Container(height: Ms.hair, color: color ?? ms.rule),
    );
  }
}

/// A section heading: a title in sentence case, with an optional trailing
/// widget at the far end. The heading speaks for itself — no rule, no caps.
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(Ms.margin + 4, 30, Ms.margin + 4, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(color: color),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// A title band: a centred heading on a light tint of [color].
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Ms.rSmall),
      ),
      child: Center(child: child),
    );
  }
}

// ---------------------------------------------------------------------------
// The geometric ground
// ---------------------------------------------------------------------------

/// The *khātam* ground: a true octagon-and-square tessellation with the
/// eight-point star polygon inscribed in each octagon — here only ever a faint
/// carved screen under a mihrab's arch.
///
/// Regular octagons on a square lattice of spacing `s(1+√2)`, the gaps filled
/// by squares of the same side, and the {8/3} star drawn inside each octagon by
/// joining every third vertex. It paints only when the user has patterns
/// enabled (Appearance settings).
class GirihField extends StatelessWidget {
  const GirihField({
    super.key,
    required this.color,
    this.opacity = 0.08,
    this.side = 19,
    this.fade = false,
  });

  /// Base colour of the strokes; [opacity] is applied to it.
  final Color color;
  final double opacity;

  /// Side length of the octagons, in logical pixels.
  final double side;

  /// Fades the strokes out toward the bottom edge, so the screen dissolves
  /// into the field rather than stopping at a line.
  final bool fade;

  @override
  Widget build(BuildContext context) {
    final enabled =
        context.select<ThemeController?, bool>((c) => c?.patternsEnabled ?? true);
    if (!enabled) return const SizedBox.shrink();
    return CustomPaint(
      size: Size.infinite,
      isComplex: true,
      willChange: false,
      painter: _KhatamPainter(color.withValues(alpha: opacity), side, fade),
    );
  }
}

class _KhatamPainter extends CustomPainter {
  _KhatamPainter(this.color, this.side, this.fade);

  final Color color;
  final double side;
  final bool fade;

  @override
  void paint(Canvas canvas, Size size) {
    // With a shader the paint's own alpha still multiplies in, so it is held
    // opaque and the gradient alone carries the strokes' strength.
    final paint = Paint()
      ..color = fade ? const Color(0xFF000000) : color
      ..shader = fade
          ? LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withValues(alpha: 0)],
            ).createShader(Offset.zero & size)
          : null
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeJoin = StrokeJoin.miter
      ..isAntiAlias = true;

    final r = side / (2 * math.sin(math.pi / 8));
    final pitch = side * (1 + math.sqrt2);
    final squareR = side / math.sqrt2;

    final path = Path();
    // Centred on the field, so the pattern sits symmetrically under the apex.
    final x0 = (size.width / 2) % pitch - pitch;
    for (double cy = 0; cy <= size.height + pitch; cy += pitch) {
      for (double cx = x0; cx <= size.width + pitch; cx += pitch) {
        _octagonAndStar(path, Offset(cx, cy), r);
        _polygon(path, Offset(cx + pitch / 2, cy + pitch / 2), squareR, 4,
            math.pi / 4);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _octagonAndStar(Path path, Offset c, double r) {
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
      old.color != color || old.side != side || old.fade != fade;
}

// ---------------------------------------------------------------------------
// Small pieces
// ---------------------------------------------------------------------------

/// The app's empty and hint page: an icon in a tinted well, a heading, and one
/// line of explanation.
///
/// One shared component so that "nothing saved yet", "no results", and "start
/// typing" all read as the same quiet page rather than as four differently
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

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconWell(icon: icon, size: 72),
            const SizedBox(height: 20),
            if (title != null) ...[
              Text(title!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
            ],
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 22),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// An eight-point *khātam* with a numeral inside — the mark a mushaf uses to
/// number a sūrah or a juzʾ, here set as a soft tinted star.
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final inner = child ??
        (number == null
            ? null
            : Text(
                '$number',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: size * 0.3,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      letterSpacing: 0,
                      color: tint,
                    ),
              ));

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StarMedallionPainter(
          tint.withValues(alpha: (filled ? 0.22 : 0.11) * (dark ? 1.6 : 1)),
        ),
        child: inner == null ? null : Center(child: inner),
      ),
    );
  }
}

class _StarMedallionPainter extends CustomPainter {
  _StarMedallionPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // Two squares of equal circumradius, one turned 45° over the other, with
    // their corners softened so the star reads as a tile, not a badge.
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    for (final twist in [0.0, math.pi / 4]) {
      final pts = List<Offset>.generate(4, (i) {
        final a = twist + i * math.pi / 2;
        return Offset(c.dx + r * 0.94 * math.cos(a),
            c.dy + r * 0.94 * math.sin(a));
      });
      final rrect = Path()..addPolygon(pts, true);
      canvas.drawPath(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(_StarMedallionPainter old) => old.color != color;
}

/// A quantity in a soft pill — the app's counter, repeat badge, and tally.
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

  /// A solid pill in [color], for a finished count.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final ms = ManuscriptTheme.of(context);
    final tint = color ?? ms.rubric;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // On its own tint the raw colour falls short of 4.5:1 at this size, so
    // the label is deepened toward the body ink.
    final ink = filled
        ? ms.paper
        : Color.lerp(tint, Theme.of(context).colorScheme.onSurface, 0.3)!;

    return AnimatedContainer(
      duration: Motion.of(context, Motion.settle),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(icon == null ? 11 : 9, 5, 11, 5),
      decoration: BoxDecoration(
        color: filled ? tint : tint.withValues(alpha: dark ? 0.18 : 0.11),
        borderRadius: BorderRadius.circular(Ms.rButton),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: ink),
            const SizedBox(width: 4),
          ],
          // Derived from the theme's label style rather than built from
          // scratch, so it inherits the Arabic fallback — a pill can hold a
          // translated word ("تم"), not only a numeral.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                    color: ink,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A numeral set for clocks, counters and anything that updates in place.
///
/// [serif] picks the display style (large figures) over the label style; the
/// name is kept from the serif numerals this replaced.
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
        // Large figures close up; anything set right-to-left keeps its
        // natural spacing so joined letters stay joined.
        letterSpacing:
            serif && Directionality.of(context) == TextDirection.ltr
                ? -size * 0.02
                : 0,
        color: color ?? theme.colorScheme.onSurface,
      ),
    );
  }
}
