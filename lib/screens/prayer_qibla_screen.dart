import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/prayer_service.dart';
import '../widgets/arabic_text.dart';
import 'prayer_schedule_screen.dart';
import 'qibla_screen.dart';

/// Combined "Prayer & Qibla" tab: the live Qibla compass on top, then today's
/// prayer times. Tapping any prayer opens the full weekly schedule.
///
/// This only restructures presentation — the compass and all prayer-time data
/// come from the existing [QiblaCompass] widget and [PrayerService].
class PrayerQiblaScreen extends StatelessWidget {
  const PrayerQiblaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final service = context.watch<PrayerService>();
    final now = DateTime.now();
    final next = service.nextPrayer(now);

    void openSchedule() => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PrayerScheduleScreen()),
        );

    return Scaffold(
      appBar: AppBar(title: Text(s.prayerQiblaTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: QiblaCompass(),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(Icons.access_time,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.todaysPrayers(s.place(service.locationLabel)),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          ...service.todaysPrayers.map((timing) {
            final isNext = next != null &&
                next.prayer == timing.prayer &&
                next.time == timing.time;
            return ListTile(
              leading: ArabicText(timing.prayer.arabicName,
                  fontSize: 20, color: theme.colorScheme.primary),
              title: Text(s.prayerName(timing.prayer)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _clock(timing.time, s),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                      color: isNext ? theme.colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right,
                      size: 18, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
              selected: isNext,
              selectedTileColor:
                  theme.colorScheme.primary.withValues(alpha: 0.08),
              onTap: openSchedule,
            );
          }),
        ],
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
