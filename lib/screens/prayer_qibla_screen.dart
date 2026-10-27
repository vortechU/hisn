import 'dart:async';

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
                  _LivePrayerTimetable(onTap: openSchedule),
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

/// Only the timetable wakes at a prayer/day boundary. The compass keeps its
/// own frame and sensor lifecycle, independent of the clock.
class _LivePrayerTimetable extends StatefulWidget {
  const _LivePrayerTimetable({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_LivePrayerTimetable> createState() => _LivePrayerTimetableState();
}

class _LivePrayerTimetableState extends State<_LivePrayerTimetable>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _now = DateTime.now();
  bool _visible = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Also reschedule when the location or calculation settings change.
    context.watch<PrayerService>();
    final visible =
        Visibility.of(context) && TickerMode.valuesOf(context).enabled;
    final becameVisible = visible && !_visible;
    _visible = visible;
    _now = DateTime.now();
    _schedule();
    if (becameVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tick(refresh: true);
      });
    }
  }

  void _schedule() {
    _timer?.cancel();
    if (!_visible || !_foreground) return;
    final next = context.read<PrayerService>().nextPrayer(_now)?.time;
    final midnight = DateTime(_now.year, _now.month, _now.day + 1);
    final boundary = next != null && next.isBefore(midnight) ? next : midnight;
    final delay = boundary.difference(_now) + const Duration(milliseconds: 1);
    _timer = Timer(delay.isNegative ? Duration.zero : delay, _tick);
  }

  void _tick({bool refresh = false}) {
    if (!mounted || !_visible || !_foreground) return;
    final now = DateTime.now();
    final prayer = context.read<PrayerService>();
    if (refresh ||
        now.day != _now.day ||
        now.month != _now.month ||
        now.year != _now.year ||
        prayer.nextPrayer(now) == null) {
      prayer.refresh();
    }
    setState(() => _now = now);
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _tick(refresh: true);
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prayer = context.read<PrayerService>();
    return PrayerTimetable(
      prayers: prayer.todaysPrayers,
      marks: prayer.todaysMarks,
      next: prayer.nextPrayer(_now),
      now: _now,
      onTap: widget.onTap,
      inField: true,
    );
  }
}
