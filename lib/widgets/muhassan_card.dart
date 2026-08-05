import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dua_repository.dart';
import '../l10n/app_strings.dart';
import '../models/dua_category.dart';
import '../screens/category_duas_screen.dart';
import '../screens/streak_stats_screen.dart';
import '../services/muhassan_service.dart';

/// The daily "muhassan" (fortified) meter: a ring that fills as the user
/// completes their morning and evening adhkar, plus the running streak. Tapping
/// a session pill jumps straight into that set.
class MuhassanCard extends StatelessWidget {
  const MuhassanCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = AppStrings.of(context);
    final m = context.watch<MuhassanService>();

    // Don't render until the set sizes are known.
    if (m.morningTotal == 0 && m.eveningTotal == 0) {
      return const SizedBox.shrink();
    }

    final complete = m.fraction >= 1.0;
    final ringColor = complete ? scheme.primary : scheme.secondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (complete ? scheme.primary : scheme.outlineVariant)
                .withValues(alpha: complete ? 0.5 : 0.4),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _Ring(fraction: m.fraction, color: ringColor, complete: complete),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + streak chip share a line when they fit, but on
                      // narrow screens (or a large system font scale) the chip
                      // would otherwise overflow the right edge — so let it wrap
                      // onto its own line instead. spaceBetween keeps the wide
                      // layout (title left, chip right) unchanged.
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  complete
                                      ? Icons.verified
                                      : Icons.shield_outlined,
                                  size: 18,
                                  color: ringColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  s.muhassanHeading,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            _StreakChip(streak: m.streak, best: m.best),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        complete ? s.muhassanComplete : s.muhassanToday(m.percent),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SessionPill(
                    label: s.muhassanMorning,
                    icon: Icons.wb_sunny_outlined,
                    done: m.morningDone,
                    count: m.morningCount,
                    total: m.morningTotal,
                    categoryId: MuhassanService.morningId,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SessionPill(
                    label: s.muhassanEvening,
                    icon: Icons.bedtime_outlined,
                    done: m.eveningDone,
                    count: m.eveningCount,
                    total: m.eveningTotal,
                    categoryId: MuhassanService.eveningId,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({
    required this.fraction,
    required this.color,
    required this.complete,
  });

  final double fraction;
  final Color color;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 64,
      height: 64,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
        tween: Tween(begin: 0, end: fraction),
        builder: (context, value, _) => Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            complete
                ? Icon(Icons.check, color: color, size: 26)
                : Text(
                    '${(value * 100).round()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: scheme.onSurface,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak, required this.best});

  final int streak;
  final int best;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = AppStrings.of(context);
    final active = streak > 0;
    final color = active ? const Color(0xFFEF6C00) : scheme.onSurfaceVariant;

    return Tooltip(
      message: best > 0 ? s.streakBest(best) : s.streakStart,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StreakStatsScreen()),
          ),
          child: Container(
            padding: const EdgeInsetsDirectional.only(
                start: 10, end: 6, top: 5, bottom: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active
                      ? Icons.local_fire_department
                      : Icons.sentiment_dissatisfied_outlined,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    active ? s.streakDays(streak) : s.streakStart,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                  size: 16,
                  color: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionPill extends StatelessWidget {
  const _SessionPill({
    required this.label,
    required this.icon,
    required this.done,
    required this.count,
    required this.total,
    required this.categoryId,
  });

  final String label;
  final IconData icon;
  final bool done;
  final int count;
  final int total;
  final String categoryId;

  void _open(BuildContext context) {
    final DuaCategory? category =
        context.read<DuaRepository>().categoryById(categoryId);
    if (category == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CategoryDuasScreen(category: category)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = done ? scheme.primary : scheme.onSurfaceVariant;

    return Material(
      color: (done ? scheme.primary : scheme.surfaceContainerHighest)
          .withValues(alpha: done ? 0.12 : 0.5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(done ? Icons.check_circle : icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Text(
                done ? '✓' : '$count/$total',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
