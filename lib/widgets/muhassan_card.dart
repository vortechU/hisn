import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dua_repository.dart';
import '../l10n/app_strings.dart';
import '../models/dua_category.dart';
import '../screens/category_duas_screen.dart';
import '../screens/streak_stats_screen.dart';
import '../services/muhassan_service.dart';
import '../theme/app_theme.dart';
import 'ornament.dart';

/// The daily *muhassan* (fortified) tally: a rosette that illuminates as the
/// morning and evening adhkar are completed, over a ruled two-line register of
/// the day's sessions.
///
/// The register is set as ruled rows rather than as two pills, so the numbers
/// line up in a column and can actually be compared — a tally is a table, not
/// a pair of buttons.
class MuhassanCard extends StatelessWidget {
  const MuhassanCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final s = AppStrings.of(context);
    final m = context.watch<MuhassanService>();

    // Don't render until the set sizes are known.
    if (m.morningTotal == 0 && m.eveningTotal == 0) {
      return const SizedBox.shrink();
    }

    final complete = m.fraction >= 1.0;
    final tint = complete ? ms.gilt : ms.rubric;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Ms.margin, 12, Ms.margin, 0),
      child: JadwalFrame(
        accent: complete ? ms.gilt : null,
        padding: const EdgeInsets.fromLTRB(15, 14, 15, 6),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ProgressRosette(
                  fraction: m.fraction,
                  size: 58,
                  // Plain arc: the two session rules below already give the
                  // breakdown, so this only needs to carry the total.
                  lobes: 0,
                  color: tint,
                  child: complete
                      ? Icon(Icons.check, size: 20, color: tint)
                      : Numeral('${m.percent}%',
                          size: 15, weight: FontWeight.w700, serif: false),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.muhassanHeading,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        complete ? s.muhassanComplete : s.muhassanToday(m.percent),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 9),
                      _StreakMark(streak: m.streak, best: m.best),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SessionRow(
              label: s.muhassanMorning,
              done: m.morningDone,
              count: m.morningCount,
              total: m.morningTotal,
              categoryId: MuhassanService.morningId,
              lobes: 12,
            ),
            _SessionRow(
              label: s.muhassanEvening,
              done: m.eveningDone,
              count: m.eveningCount,
              total: m.eveningTotal,
              categoryId: MuhassanService.eveningId,
              lobes: 10,
              last: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// One session in the day's register: mark, name, tally, and the rule beneath.
class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.label,
    required this.done,
    required this.count,
    required this.total,
    required this.categoryId,
    required this.lobes,
    this.last = false,
  });

  final String label;
  final bool done;
  final int count;
  final int total;
  final String categoryId;
  final int lobes;
  final bool last;

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
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final tint = done ? ms.gilt : ms.rubric;
    final fraction = total == 0 ? 0.0 : count / total;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => _open(context),
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: ms.rule)),
          ),
          padding: EdgeInsets.only(top: 9, bottom: last ? 10 : 9),
          child: Column(
            children: [
              Row(
                children: [
                  Rosette(size: 15, color: tint, lobes: lobes, filled: done),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(label, style: theme.textTheme.titleSmall),
                  ),
                  const SizedBox(width: 8),
                  Numeral(
                    '$count/$total',
                    size: 13,
                    serif: false,
                    weight: FontWeight.w700,
                    color: done ? tint : theme.colorScheme.onSurfaceVariant,
                  ),
                  if (done) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.check, size: 14, color: tint),
                  ],
                ],
              ),
              const SizedBox(height: 7),
              ProgressRule(value: fraction, color: tint, thickness: 1.5),
            ],
          ),
        ),
      ),
    );
  }
}

/// The running streak, marked the way a scribe marks a count: a numeral in the
/// apparatus face against a small rule, not a coloured pill with a flame.
class _StreakMark extends StatelessWidget {
  const _StreakMark({required this.streak, required this.best});

  final int streak;
  final int best;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final s = AppStrings.of(context);
    final active = streak > 0;
    final tint = active ? ms.gilt : theme.colorScheme.onSurfaceVariant;

    return Tooltip(
      message: best > 0 ? s.streakBest(best) : s.streakStart,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(Ms.rSmall),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const StreakStatsScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: Ms.stroke, color: tint),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    (active ? s.streakDays(streak) : s.streakStart)
                        .toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(color: tint),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                  size: 15,
                  color: tint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
