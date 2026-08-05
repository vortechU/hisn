import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/prayer_service.dart';
import '../services/sunnah_calendar_service.dart';
import '../theme/app_theme.dart';
import 'arabic_text.dart';
import 'ornament.dart';

/// The opening plate of the Adhkar tab: an ʿunwān carrying today's date, the
/// hour, the prayer now in force, and the wait until the next adhan.
///
/// This is the one hero surface of the screen, so it is the only block drawn
/// with a full-strength outer rule. Tap it for the day's full schedule.
class PrayerHeader extends StatefulWidget {
  const PrayerHeader({super.key});

  @override
  State<PrayerHeader> createState() => _PrayerHeaderState();
}

class _PrayerHeaderState extends State<PrayerHeader> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      // Roll the schedule forward once the last cached prayer has passed.
      if (context.read<PrayerService>().nextPrayer(now) == null) {
        context.read<PrayerService>().refresh();
      }
      setState(() => _now = now);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _showSchedule(BuildContext context, PrayerService service) {
    final next = service.nextPrayer(_now);
    final s = AppStrings.read(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final ms = ManuscriptTheme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Ms.margin, 0, Ms.margin, 4),
                child: Text(
                  s.todaysPrayers(s.place(service.locationLabel)),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              const RuleDivider(indent: Ms.margin),
              ...service.todaysPrayers.map((timing) {
                final isNext = next != null &&
                    next.prayer == timing.prayer &&
                    next.time == timing.time;
                return _ScheduleRow(
                  timing: timing,
                  isNext: isNext,
                  colour: isNext ? ms.rubric : theme.colorScheme.onSurface,
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PrayerService>();
    final current = service.currentPrayer(_now);
    final next = service.nextPrayer(_now);
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Ms.margin, 10, Ms.margin, 6),
      child: UnwanPlate(
        padding: EdgeInsets.zero,
        onTap: () => _showSchedule(context, service),
        child: Column(
          children: [
            // The date band — today's page, headed the way a chapter is.
            UnwanBand(
              child: Text(
                s.hijriDate(_now,
                    offset: context.watch<SunnahCalendarService>().offset),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(color: ms.rubric),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _clockBlock(service, s, theme, ms)),
                      if (current != null) ...[
                        const SizedBox(width: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: _currentPrayerBlock(current, s, theme, ms),
                        ),
                      ],
                    ],
                  ),
                  if (next != null) ...[
                    const SizedBox(height: 14),
                    _nextBlock(current, next, s, theme, ms),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _clockBlock(
      PrayerService service, AppStrings s, ThemeData theme, ManuscriptTheme ms) {
    final hour12 = _hour12(_now.hour);
    final minute = _now.minute.toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Numeral('$hour12:$minute', size: 46, weight: FontWeight.w600),
              const SizedBox(width: 7),
              Text(
                s.ampm(_now.hour),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Icon(Icons.place_outlined,
                size: 13, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                '${s.dateLabel(_now)} · ${s.place(service.locationLabel)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _currentPrayerBlock(
      PrayerTiming current, AppStrings s, ThemeData theme, ManuscriptTheme ms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(s.now.toUpperCase(), style: theme.textTheme.labelSmall),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerEnd,
          child: ArabicText(current.prayer.arabicName,
              fontSize: 25, color: ms.rubric, height: 1.5),
        ),
        Text(
          s.ar
              ? _clock(current.time, s)
              : '${current.prayer.englishName} · ${_clock(current.time, s)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  /// The wait until the next adhan, set as a ruled entry: label, name, time,
  /// and a rule that fills as the current interval elapses.
  Widget _nextBlock(PrayerTiming? current, PrayerTiming next, AppStrings s,
      ThemeData theme, ManuscriptTheme ms) {
    final total =
        current == null ? Duration.zero : next.time.difference(current.time);
    final elapsed =
        current == null ? Duration.zero : _now.difference(current.time);
    final progress = total.inSeconds <= 0
        ? 0.0
        : (elapsed.inSeconds / total.inSeconds).clamp(0.0, 1.0);

    return Column(
      children: [
        Container(height: Ms.hair, color: ms.rule),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(s.next.toUpperCase(), style: theme.textTheme.labelSmall),
            const SizedBox(width: 9),
            // The ruled label already says "next", so the name and time are set
            // on their own — no sentence carrying the word a second time.
            Expanded(
              child: Text(
                '${s.prayerName(next.prayer)}  ·  ${_clock(next.time, s)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerEnd,
                child: Numeral(
                  _countdown(next.time.difference(_now), s),
                  size: 16,
                  weight: FontWeight.w700,
                  serif: false,
                  color: ms.rubric,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        // The interval, drawn as a rule that inks in rather than as a bar.
        ProgressRule(value: progress, color: ms.gilt),
      ],
    );
  }

  // ---- formatting helpers ----

  static int _hour12(int hour24) {
    final h = hour24 % 12;
    return h == 0 ? 12 : h;
  }

  static String _clock(DateTime t, AppStrings s) {
    final m = t.minute.toString().padLeft(2, '0');
    return '${_hour12(t.hour)}:$m ${s.ampm(t.hour)}';
  }

  static String _countdown(Duration d, AppStrings s) {
    if (d.isNegative || d.inMinutes < 1) return s.countdownNow;
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (s.ar) {
      return h > 0 ? '$h س $m د' : '$m د';
    }
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}

/// One prayer in the day's schedule sheet: Arabic name, English name, time.
class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.timing,
    required this.isNext,
    required this.colour,
  });

  final PrayerTiming timing;
  final bool isNext;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppStrings.of(context);
    final ms = ManuscriptTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Ms.margin, vertical: 11),
      decoration: BoxDecoration(
        color: isNext ? ms.rubric.withValues(alpha: 0.07) : null,
        border: Border(bottom: BorderSide(color: ms.rule)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: isNext
                ? Rosette(size: 15, color: ms.gilt, lobes: 8)
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: Text(
              s.prayerName(timing.prayer),
              style: isNext
                  ? theme.textTheme.titleSmall?.copyWith(color: colour)
                  : theme.textTheme.titleSmall,
            ),
          ),
          ArabicText(timing.prayer.arabicName,
              fontSize: 19, color: colour, height: 1.6),
          const SizedBox(width: 14),
          Numeral(
            _PrayerHeaderState._clock(timing.time, s),
            size: 14,
            serif: false,
            weight: isNext ? FontWeight.w700 : FontWeight.w500,
            color: isNext ? colour : theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
