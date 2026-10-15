import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// A live spotlight. The highlighted rectangle is measured from the real
/// control; the barrier prevents a tour tap from launching another screen.
class FeatureTourOverlay extends StatelessWidget {
  const FeatureTourOverlay({
    super.key,
    required this.targetRect,
    required this.title,
    required this.body,
    required this.step,
    required this.total,
    required this.onNext,
    required this.onSkip,
  });

  final Rect? targetRect;
  final String title;
  final String body;
  final int step;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final padding = MediaQuery.paddingOf(context);
    return BlockSemantics(
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): onSkip},
        child: FocusScope(
          autofocus: true,
          child: LayoutBuilder(
            builder: (context, bounds) {
              final size = bounds.biggest;
              final safeTop = padding.top + 12;
              final safeBottom = size.height - padding.bottom - 12;
              final hole = targetRect?.inflate(6).intersect(Offset.zero & size);
              final below = hole == null
                  ? safeBottom - safeTop
                  : safeBottom - hole.bottom - 14;
              final above = hole == null ? 0.0 : hole.top - safeTop - 14;
              final placeBelow = below >= above;
              final available = math.max(72.0, placeBelow ? below : above);
              final panel = ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 520,
                  maxHeight: available,
                ),
                child: Material(
                  key: const ValueKey('feature_tour_panel'),
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Ms.rSheet),
                    side: BorderSide(color: ms.ruleStrong),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                          child: Semantics(
                            liveRegion: true,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.guideProgress(step, total),
                                  style: theme.textTheme.labelMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(title, style: theme.textTheme.titleLarge),
                                const SizedBox(height: 10),
                                Text(body, style: theme.textTheme.bodyLarge),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              TextButton(
                                key: const ValueKey('feature_tour_skip'),
                                onPressed: onSkip,
                                child: Text(s.onboardSkip),
                              ),
                              FilledButton(
                                key: const ValueKey('feature_tour_next'),
                                autofocus: true,
                                onPressed: targetRect == null ? null : onNext,
                                child: Text(
                                  step == total ? s.guideDone : s.onboardNext,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
              return Stack(
                children: [
                  const Positioned.fill(
                    child: ModalBarrier(
                      dismissible: false,
                      color: Colors.transparent,
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _SpotlightPainter(hole, ms.gilt, placeBelow),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    top: placeBelow ? (hole?.bottom ?? safeTop) + 14 : null,
                    bottom: placeBelow
                        ? null
                        : size.height - (hole?.top ?? safeBottom) + 14,
                    child: Align(alignment: Alignment.topCenter, child: panel),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter(this.hole, this.color, this.panelBelow);
  final Rect? hole;
  final Color color;
  final bool panelBelow;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    final target = hole;
    if (target != null) {
      path.addRRect(RRect.fromRectAndRadius(target, const Radius.circular(12)));
    }
    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withValues(alpha: 0.72),
    );
    if (target == null) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(target, const Radius.circular(12)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final x = target.center.dx;
    final y = panelBelow ? target.bottom + 3 : target.top - 3;
    final direction = panelBelow ? 1.0 : -1.0;
    canvas.drawPath(
      Path()
        ..moveTo(x, y)
        ..lineTo(x - 6, y + direction * 9)
        ..lineTo(x + 6, y + direction * 9)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.hole != hole || old.color != color || old.panelBelow != panelBelow;
}
