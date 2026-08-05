import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/muhassan_service.dart';

const _flameColor = Color(0xFFEF6C00);

/// A dedicated page for the daily-adhkar streak: current/best/total stats and a
/// four-week calendar heatmap of fortified days. Opened from the streak chip on
/// the home muhassan card.
class StreakStatsScreen extends StatelessWidget {
  const StreakStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final m = context.watch<MuhassanService>();

    return Scaffold(
      appBar: AppBar(title: Text(s.streakTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _Hero(streak: m.streak, fortifiedToday: m.fortifiedToday),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.local_fire_department,
                  color: _flameColor,
                  label: s.statCurrent,
                  value: '${m.streak}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.emoji_events_outlined,
                  color: const Color(0xFFB8860B),
                  label: s.statBest,
                  value: '${m.best}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.shield_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  label: s.statTotal,
                  value: '${m.totalFortified}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _CalendarCard(),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.streak, required this.fortifiedToday});

  final int streak;
  final bool fortifiedToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppStrings.of(context);
    final active = streak > 0;
    final color = active ? _flameColor : theme.colorScheme.onSurfaceVariant;

    final message = !active
        ? s.streakBroken
        : (fortifiedToday ? s.streakOnFire : s.streakTodayPending);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(
            active
                ? Icons.local_fire_department
                : Icons.sentiment_dissatisfied_outlined,
            size: 56,
            color: color,
          ),
          const SizedBox(height: 6),
          Text(
            '$streak',
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              height: 1.0,
            ),
          ),
          Text(
            s.streakWord,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = AppStrings.of(context);
    final m = context.watch<MuhassanService>();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Monday of the current week, then back three more weeks → 28 days.
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final start = monday.subtract(const Duration(days: 21));
    final days = List.generate(28, (i) => start.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.last4Weeks,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final d in s.weekdayLetters)
                Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              for (final day in days)
                _DayCell(
                  day: day,
                  today: today,
                  fortified: m.wasFortified(day),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _LegendDot(color: scheme.primary, filled: true),
              const SizedBox(width: 6),
              Text(
                s.fortifiedLegend,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              _LegendDot(color: scheme.primary, filled: false),
              const SizedBox(width: 6),
              Text(
                s.todayLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.today,
    required this.fortified,
  });

  final DateTime day;
  final DateTime today;
  final bool fortified;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isToday = day == today;
    final isFuture = day.isAfter(today);

    final Color bg;
    final Color fg;
    if (fortified) {
      bg = scheme.primary;
      fg = scheme.onPrimary;
    } else if (isFuture) {
      bg = scheme.surfaceContainerHighest.withValues(alpha: 0.25);
      fg = scheme.onSurfaceVariant.withValues(alpha: 0.4);
    } else {
      bg = scheme.surfaceContainerHighest.withValues(alpha: 0.6);
      fg = scheme.onSurfaceVariant;
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: isToday
            ? Border.all(color: scheme.primary, width: 2)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.filled});

  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: filled ? 0 : 2),
      ),
    );
  }
}
