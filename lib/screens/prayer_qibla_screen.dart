import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/prayer_service.dart';
import '../theme/app_theme.dart';
import '../widgets/prayer_header.dart';
import '../widgets/ornament.dart';
import 'prayer_schedule_screen.dart';
import 'qibla_screen.dart';
import 'sunnah_calendar_screen.dart';

/// The combined Prayer & Qibla tab: today's prayers in the screen's one niche,
/// as a timetable, then the live compass on the plain ground below. Tapping a
/// prayer opens the weekly schedule.
///
/// The times lead because they are what this tab is opened for most; the
/// compass is a turn of the phone away.
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
    // Worked out once: each read of [PrayerService.todaysPrayers] runs the
    // astronomy for the day again.
    final today = service.todaysPrayers;

    void openSchedule() => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PrayerScheduleScreen()));

    return Scaffold(
      appBar: AppBar(
        title: Text(s.prayerQiblaTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.nights_stay_outlined),
            tooltip: s.sunnahCalendarTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SunnahCalendarScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: s.weeklySchedule,
            onPressed: openSchedule,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Ms.margin, 8, Ms.margin, 0),
            child: MihrabField(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    child: Row(
                      children: [
                        Text(
                          s.todayLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: ms.onField,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Takes the rest of the row and sets the place at its
                        // far end, over the time column.
                        Expanded(
                          child: Text(
                            s.place(service.locationLabel),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: ms.onField.withValues(alpha: 0.88),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PrayerTimetable(
                    prayers: today,
                    marks: service.todaysMarks,
                    next: next,
                    now: now,
                    onTap: openSchedule,
                    inField: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const QiblaCompass(),
        ],
      ),
    );
  }
}
