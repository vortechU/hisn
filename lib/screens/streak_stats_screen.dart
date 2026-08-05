import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/muhassan_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ornament.dart';

/// The daily-adhkar streak: the running count, the three totals as one ruled
/// register, and four weeks of fortified days.
///
/// The totals share a single framed table split by vertical rules rather than
/// three separate cards — they are one set of related figures, and a table is
/// what a set of related figures wants to be.
class StreakStatsScreen extends StatelessWidget {
  const StreakStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final m = context.watch<MuhassanService>();

    return Scaffold(
      appBar: AppBar(title: Text(s.streakTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Ms.margin, 4, Ms.margin, 34),
        children: [
          _Hero(streak: m.streak, fortifiedToday: m.fortifiedToday),
          const SizedBox(height: 18),
          _Register(
            entries: [
              (s.statCurrent, '${m.streak}'),
              (s.statBest, '${m.best}'),
              (s.statTotal, '${m.totalFortified}'),
            ],
          ),
          const SizedBox(height: 22),
          const _Calendar(),
        ],
      ),
    );
  }
}

/// The streak itself: the numeral inside an illuminated medallion, with the
/// day's standing spelled out beneath.
class _Hero extends StatelessWidget {
  const _Hero({required this.streak, required this.fortifiedToday});

  final int streak;
  final bool fortifiedToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final s = AppStrings.of(context);
    final active = streak > 0;
    final tint = active ? ms.gilt : theme.colorScheme.onSurfaceVariant;

    final message = !active
        ? s.streakBroken
        : (fortifiedToday ? s.streakOnFire : s.streakTodayPending);

    return JadwalFrame(
      emphasis: active,
      accent: active ? ms.gilt : null,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        children: [
          // The number is the whole point, so it is set large and plain
          // rather than framed inside a medallion.
          Numeral('$streak', size: 76, weight: FontWeight.w600, color: tint),
          const SizedBox(height: 8),
          Text(
            s.streakWord.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(color: tint),
          ),
          const RuleDivider(indent: 40),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

/// A framed table of figures, split by vertical rules.
class _Register extends StatelessWidget {
  const _Register({required this.entries});

  final List<(String, String)> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: ms.rule),
        borderRadius: BorderRadius.circular(Ms.rPanel),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < entries.length; i++) ...[
              if (i > 0) VerticalDivider(width: 1, color: ms.rule),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Numeral(entries[i].$2, size: 27),
                      const SizedBox(height: 4),
                      Text(
                        entries[i].$1.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Four weeks of days, each cell inked when the day was fortified.
class _Calendar extends StatelessWidget {
  const _Calendar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final s = AppStrings.of(context);
    final m = context.watch<MuhassanService>();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Monday of the current week, then back three more weeks → 28 days.
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final start = monday.subtract(const Duration(days: 21));
    final days = List.generate(28, (i) => start.add(Duration(days: i)));

    return JadwalFrame(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.last4Weeks, style: theme.textTheme.titleSmall),
          const SizedBox(height: 11),
          Row(
            children: [
              for (final d in s.weekdayLetters)
                Expanded(
                  child: Center(
                    child: Text(d, style: theme.textTheme.labelSmall),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            children: [
              for (final day in days)
                _DayCell(
                  day: day,
                  today: today,
                  fortified: m.wasFortified(day),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: Ms.hair, color: ms.rule),
          const SizedBox(height: 10),
          // Wrap, not Row: the two labels are translated, and in Indonesian
          // they are long enough to need a second line on a narrow screen.
          Wrap(
            spacing: 18,
            runSpacing: 6,
            children: [
              _Legend(
                label: s.fortifiedLegend,
                swatch: Container(
                  width: 13,
                  height: 13,
                  color: ms.gilt.withValues(alpha: 0.28),
                ),
              ),
              _Legend(
                label: s.todayLabel,
                swatch: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    border: Border.all(color: ms.rubric, width: Ms.stroke),
                  ),
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
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final isToday = day == today;
    final isFuture = day.isAfter(today);

    return Container(
      decoration: BoxDecoration(
        color: fortified ? ms.gilt.withValues(alpha: 0.28) : null,
        border: Border.all(
          color: isToday
              ? ms.rubric
              : fortified
                  ? ms.gilt.withValues(alpha: 0.55)
                  : ms.rule,
          width: isToday ? Ms.stroke : Ms.hair,
        ),
        borderRadius: BorderRadius.circular(Ms.rSmall),
      ),
      alignment: Alignment.center,
      child: Numeral(
        '${day.day}',
        size: 12,
        serif: false,
        weight: isToday || fortified ? FontWeight.w700 : FontWeight.w500,
        color: isFuture
            ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45)
            : theme.colorScheme.onSurface,
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.label, required this.swatch});

  final String label;
  final Widget swatch;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          swatch,
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}
