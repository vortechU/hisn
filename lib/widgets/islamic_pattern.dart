import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/theme_controller.dart';

/// A subtle, tiling eight-point-star (khātam) motif for hero surfaces — the
/// prayer header, the tasbih counter, the onboarding badge. It paints only when
/// the user has geometric patterns enabled (Appearance settings); otherwise it
/// collapses to nothing. Drop it into a [Stack] behind the hero content and let
/// the parent clip it.
class IslamicPattern extends StatelessWidget {
  const IslamicPattern({
    super.key,
    required this.color,
    this.opacity = 0.07,
    this.cell = 46,
  });

  /// Base colour of the strokes (alpha is applied via [opacity]).
  final Color color;
  final double opacity;

  /// Side length of each repeated star cell, in logical pixels.
  final double cell;

  @override
  Widget build(BuildContext context) {
    final enabled =
        context.select<ThemeController, bool>((c) => c.patternsEnabled);
    if (!enabled) return const SizedBox.shrink();
    return CustomPaint(
      size: Size.infinite,
      painter: _StarFieldPainter(color.withValues(alpha: opacity), cell),
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  _StarFieldPainter(this.color, this.cell);

  final Color color;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final r = cell * 0.46;
    for (double y = 0; y <= size.height + cell; y += cell) {
      for (double x = 0; x <= size.width + cell; x += cell) {
        _star(canvas, Offset(x, y), r, paint);
      }
    }
  }

  // An eight-point star drawn as two overlapping squares (one rotated 45°).
  void _star(Canvas canvas, Offset o, double r, Paint paint) {
    for (final base in const [0.0, pi / 4]) {
      final path = Path();
      for (var i = 0; i < 4; i++) {
        final a = base + i * (pi / 2);
        final point = Offset(o.dx + r * cos(a), o.dy + r * sin(a));
        i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_StarFieldPainter old) =>
      old.color != color || old.cell != cell;
}
