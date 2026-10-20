import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../screens/streak_stats_screen.dart';
import '../services/muhassan_service.dart';
import '../theme/app_theme.dart';
import 'ornament.dart';

/// The day's *muhassan* (fortified) tally, as the first row of the daily
/// group: a ring that fills as the morning and evening adhkar are completed,
/// what that means today, and the running streak. Tap for the history.
///
/// The morning and evening sets have their own rows directly beneath it, each
/// with its own progress, so this row carries only the total.
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
    final active = m.streak > 0;

    return Tooltip(
      message: m.best > 0 ? s.streakBest(m.best) : s.streakStart,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const StreakStatsScreen()),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 14, 14),
          child: Row(
            children: [
              ProgressRosette(
                fraction: m.fraction,
                size: 40,
                lobes: 0,
                color: tint,
                child: complete
                    ? Icon(Icons.check_rounded, size: 18, color: tint)
                    : Numeral(
                        '${m.percent}%',
                        size: 11,
                        weight: FontWeight.w600,
                        serif: false,
                        color: tint,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.muhassanHeading,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      complete
                          ? s.muhassanComplete
                          : s.muhassanToday(m.percent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (active) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Cartouche(
                    label: s.streakDays(m.streak),
                    color: ms.gilt,
                  ),
                ),
              ],
              const SizedBox(width: 4),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
