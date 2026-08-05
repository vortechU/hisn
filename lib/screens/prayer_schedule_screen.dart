import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/prayer_service.dart';
import '../widgets/arabic_text.dart';

/// The full weekly prayer schedule: the five daily prayers for each of the next
/// seven days, with today highlighted.
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
    final service = context.watch<PrayerService>();
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    return Scaffold(
      appBar: AppBar(title: Text(s.weeklySchedule)),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: 7,
        itemBuilder: (context, dayIndex) {
          final day = startOfToday.add(Duration(days: dayIndex));
          final isToday = dayIndex == 0;
          final prayers = service.prayersForDay(day);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                color: isToday
                    ? theme.colorScheme.primary.withValues(alpha: 0.08)
                    : null,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(
                      s.dateLabel(day),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isToday ? theme.colorScheme.primary : null,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          s.todayLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ...prayers.map(
                (timing) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: ArabicText(timing.prayer.arabicName,
                            fontSize: 17, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(s.prayerName(timing.prayer))),
                      Text(
                        _clock(timing.time, s),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 16),
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
