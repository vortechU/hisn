import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/sunnah_day.dart';
import '../services/sunnah_calendar_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ornament.dart';

/// Today's standing in the Islamic year, then the notable days ahead.
///
/// The list is the point: sunnah fasts are easy to intend and easy to miss,
/// and they are only findable if something tells you they are coming.
class SunnahCalendarScreen extends StatelessWidget {
  const SunnahCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final calendar = context.watch<SunnahCalendarService>();
    final today = calendar.today;
    // Today is shown in its own block above, so it isn't repeated in the list.
    final upcoming = calendar
        .upcoming()
        .where((d) => d.date.isAfter(today.date))
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.sunnahCalendarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: s.hijriAdjust,
            onPressed: () => _adjust(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          SectionMark(label: s.todayLabel),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Ms.margin),
            child: _TodayBlock(day: today),
          ),
          SectionMark(label: s.upcomingLabel),
          if (upcoming.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Ms.margin),
              child: Text(s.nothingUpcoming, style: theme.textTheme.bodySmall),
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(horizontal: Ms.margin),
              decoration: BoxDecoration(
                border: Border.all(color: ManuscriptTheme.of(context).rule),
                borderRadius: BorderRadius.circular(Ms.rPanel),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < upcoming.length; i++)
                    _DayRow(day: upcoming[i], first: i == 0),
                ],
              ),
            ),
          const RuleDivider(indent: Ms.margin),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Ms.margin),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(s.calendarNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _adjust(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => const _OffsetSheet(),
      );
}

/// Today, in full: the Hijri date, how fasting stands, and why.
class _TodayBlock extends StatelessWidget {
  const _TodayBlock({required this.day});

  final SunnahDay day;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final fast = day.primaryFast;

    return JadwalFrame(
      emphasis: true,
      accent: day.ruling == FastingRuling.recommended ? ms.gilt : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.hijriDateOf(day), style: theme.textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(s.dateLabel(day.date), style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final event in day.events)
                Cartouche(
                    label: s.eventName(event),
                    icon: Icons.brightness_2_outlined,
                    filled: true),
              if (fast != null)
                Cartouche(
                    label: s.fastName(fast),
                    icon: Icons.nights_stay_outlined,
                    color: ms.gilt,
                    filled: true),
            ],
          ),
          if (day.events.isNotEmpty || fast != null)
            const SizedBox(height: 12),
          Text(
            switch (day.ruling) {
              FastingRuling.forbidden => s.fastingBar(day.bar!),
              FastingRuling.none => s.fastingNoneToday,
              _ => fast == null
                  ? s.fastingRuling(day.ruling)
                  : s.fastVirtue(fast),
            },
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// One upcoming day: its date, what falls on it, and how fasting stands.
class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.first});

  final SunnahDay day;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final fast = day.primaryFast;
    final forbidden = day.ruling == FastingRuling.forbidden;

    // An occasion names the day where there is one; otherwise the fast does.
    final title = day.events.isNotEmpty
        ? s.eventName(day.events.first)
        : fast != null
            ? s.fastName(fast)
            : s.hijriDateOf(day);
    final note = day.events.isNotEmpty
        ? (s.eventNote(day.events.first) ??
            (forbidden
                ? s.fastingBar(day.bar!)
                : fast != null
                    ? s.fastName(fast)
                    : s.hijriDateOf(day)))
        : s.hijriDateOf(day);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: ms.rule)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Numeral('${day.date.day}', size: 20, serif: false),
                Text(
                  s.dateLabel(day.date).split(' ').first,
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(note, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (fast != null && !forbidden) ...[
            const SizedBox(width: 8),
            Icon(Icons.nights_stay_outlined, size: 17, color: ms.gilt),
          ] else if (forbidden) ...[
            const SizedBox(width: 8),
            Icon(Icons.block, size: 17, color: theme.colorScheme.error),
          ],
        ],
      ),
    );
  }
}

/// Nudges the calculated Hijri date onto the local sighting.
class _OffsetSheet extends StatelessWidget {
  const _OffsetSheet();

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final calendar = context.watch<SunnahCalendarService>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Ms.margin, 0, Ms.margin, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.hijriAdjust, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(s.hijriAdjustHint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var offset = SunnahCalendarRules.minOffset;
                    offset <= SunnahCalendarRules.maxOffset;
                    offset++)
                  ChoiceChip(
                    label: Text(s.hijriOffsetLabel(offset)),
                    selected: calendar.offset == offset,
                    onSelected: (_) => context
                        .read<SunnahCalendarService>()
                        .setOffset(offset),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // The result of the choice, so it can be checked against a
            // calendar on the wall rather than taken on trust.
            Text(s.hijriDate(DateTime.now(), offset: calendar.offset),
                style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
