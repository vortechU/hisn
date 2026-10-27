import 'package:flutter/foundation.dart' show mergeSort;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/prayer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/arabic_text.dart';
import '../widgets/ornament.dart';

/// The full weekly prayer schedule: the five daily prayers, with sunrise and any
/// chosen night times, for each of the next seven days, with today highlighted.
///
/// Pure presentation — the times come from the existing
/// [PrayerService.prayersForDay] (the same computation used elsewhere); no new
/// data fetching is introduced.
class PrayerScheduleScreen extends StatelessWidget {
  const PrayerScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final service = context.watch<PrayerService>();
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    return Scaffold(
      appBar: AppBar(title: Text(s.weeklySchedule)),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 30),
        itemCount: 7,
        itemBuilder: (context, dayIndex) {
          final day = startOfToday.add(Duration(days: dayIndex));
          final isToday = dayIndex == 0;
          // Prayers and the day's marks in one list by the hour; marks are
          // set fainter, as times to know rather than prayers to keep.
          final rows = <(String, String, DateTime, bool)>[
            for (final p in service.prayersForDay(day))
              (s.prayerName(p.prayer), p.prayer.arabicName, p.time, false),
            for (final m in service.marksForDay(day))
              (s.dayMarkName(m.mark), m.mark.arabicName, m.time, true),
          ];
          mergeSort(rows, compare: (a, b) => a.$3.compareTo(b.$3));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Each day is headed like a dated entry in a register.
              SectionMark(
                label: s.dateLabel(day),
                color: isToday ? ms.rubric : null,
                trailing: isToday
                    ? Cartouche(
                        label: s.todayLabel, color: ms.gilt, filled: true)
                    : null,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: Ms.margin),
                decoration: BoxDecoration(
                  color: ms.paper,
                  border: isToday
                      ? Border.all(color: ms.rubric.withValues(alpha: 0.45))
                      : null,
                  borderRadius: BorderRadius.circular(Ms.rPanel),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < rows.length; i++)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 13, vertical: rows[i].$4 ? 7 : 10),
                        decoration: BoxDecoration(
                          border: i == 0
                              ? null
                              : Border(top: BorderSide(color: ms.rule)),
                        ),
                        // Every cell is flexible: at a large text scale on a
                        // narrow screen the name, the Arabic and the time all
                        // grow, and a fixed cell would push the row over.
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                rows[i].$1,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: rows[i].$4
                                    ? theme.textTheme.bodyMedium?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant)
                                    : theme.textTheme.titleSmall,
                              ),
                            ),
                            if (!s.ar) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                flex: 2,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: ArabicText(rows[i].$2,
                                      fontSize: rows[i].$4 ? 15 : 18,
                                      color: rows[i].$4
                                          ? theme.colorScheme.onSurfaceVariant
                                          : ms.rubric,
                                      height: 1.6),
                                ),
                              ),
                            ],
                            const SizedBox(width: 12),
                            Flexible(
                              flex: 3,
                              child: Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: Numeral(
                                  _clock(rows[i].$3, s),
                                  size: 14,
                                  serif: false,
                                  weight: FontWeight.w500,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static int _hour12(int hour24) {
    final h = hour24 % 12;
    return h == 0 ? 12 : h;
  }

  static String _clock(DateTime t, AppStrings s) {
    final m = t.minute.toString().padLeft(2, '0');
    return '${_hour12(t.hour)}:$m ${s.ampm(t.hour)}';
  }
}
