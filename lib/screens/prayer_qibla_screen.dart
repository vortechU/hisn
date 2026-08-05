import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/prayer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/arabic_text.dart';
import '../widgets/ornament.dart';
import 'prayer_schedule_screen.dart';
import 'qibla_screen.dart';

/// The combined Prayer & Qibla tab: the live compass above, then today's
/// prayers as a ruled register. Tapping any entry opens the weekly schedule.
///
/// The register is a table, not a list of tiles — five times that want to be
/// compared read best when their numerals sit in one column.
class PrayerQiblaScreen extends StatelessWidget {
  const PrayerQiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final service = context.watch<PrayerService>();
    final now = DateTime.now();
    final next = service.nextPrayer(now);

    void openSchedule() => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PrayerScheduleScreen()),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(s.prayerQiblaTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: s.weeklySchedule,
            onPressed: openSchedule,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          const QiblaCompass(),
          SectionMark(
            label: s.todayLabel,
            trailing: Text(
              s.place(service.locationLabel),
              style: theme.textTheme.bodySmall,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: Ms.margin),
            decoration: BoxDecoration(
              border: Border.all(color: ms.rule),
              borderRadius: BorderRadius.circular(Ms.rPanel),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < service.todaysPrayers.length; i++)
                  _PrayerRow(
                    timing: service.todaysPrayers[i],
                    isNext: next != null &&
                        next.prayer == service.todaysPrayers[i].prayer &&
                        next.time == service.todaysPrayers[i].time,
                    first: i == 0,
                    onTap: openSchedule,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One row of the day's register: mark, name, Arabic name, time.
class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.timing,
    required this.isNext,
    required this.first,
    required this.onTap,
  });

  final PrayerTiming timing;
  final bool isNext;
  final bool first;
  final VoidCallback onTap;

  static int _hour12(int hour24) {
    final h = hour24 % 12;
    return h == 0 ? 12 : h;
  }

  static String _clock(DateTime t, AppStrings s) {
    final m = t.minute.toString().padLeft(2, '0');
    return '${_hour12(t.hour)}:$m ${s.ampm(t.hour)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final s = AppStrings.of(context);
    final tint = isNext ? ms.rubric : theme.colorScheme.onSurface;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: isNext ? ms.rubric.withValues(alpha: 0.07) : null,
            border: first
                ? null
                : Border(top: BorderSide(color: ms.rule)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: isNext
                    ? Rosette(size: 15, color: ms.gilt, lobes: 8, filled: true)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Text(
                  s.prayerName(timing.prayer),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(color: tint),
                ),
              ),
              if (!s.ar) ...[
                const SizedBox(width: 8),
                Flexible(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: ArabicText(timing.prayer.arabicName,
                        fontSize: 19, color: tint, height: 1.6),
                  ),
                ),
              ],
              const SizedBox(width: 12),
              Numeral(
                _clock(timing.time, s),
                size: 15,
                serif: false,
                weight: isNext ? FontWeight.w700 : FontWeight.w500,
                color: isNext ? tint : theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
