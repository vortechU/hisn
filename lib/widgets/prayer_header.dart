import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/prayer_service.dart';
import '../theme/app_theme.dart';
import 'arabic_text.dart';
import 'islamic_pattern.dart';

/// The home header: live clock, current location, current prayer, and a
/// countdown to the next adhan. Tap to see the full day's schedule.
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
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(s.todaysPrayers(s.place(service.locationLabel)),
                          style: theme.textTheme.titleMedium),
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
                  title: Text(timing.prayer.englishName),
                  trailing: Text(
                    _clock(timing.time, s),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                      color: isNext ? theme.colorScheme.primary : null,
                    ),
                  ),
                  selected: isNext,
                  selectedTileColor:
                      theme.colorScheme.primary.withValues(alpha: 0.08),
                );
              }),
              const SizedBox(height: 8),
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

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        gradient: BrandTheme.of(context),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: const IslamicPattern(color: Colors.white),
            ),
          ),
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => _showSchedule(context, service),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _clockBlock(service, s)),
                        if (current != null) ...[
                          const SizedBox(width: 10),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 170),
                            child: _currentPrayerBlock(current, s),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (next != null) _nextBanner(current, next, s),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _clockBlock(PrayerService service, AppStrings s) {
    final hour12 = _hour12(_now.hour);
    final minute = _now.minute.toString().padLeft(2, '0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$hour12:$minute',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  s.ampm(_now.hour),
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.location_on_outlined,
                size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '${s.dateLabel(_now)} · ${s.place(service.locationLabel)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            const Icon(Icons.nightlight_round, size: 13, color: Colors.white60),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                s.hijriDate(_now),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _currentPrayerBlock(PrayerTiming current, AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(s.now,
            style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: ArabicText(current.prayer.arabicName,
              fontSize: 22, color: Colors.white),
        ),
        Text(
          s.ar
              ? _clock(current.time, s)
              : '${current.prayer.englishName} · ${_clock(current.time, s)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _nextBanner(PrayerTiming? current, PrayerTiming next, AppStrings s) {
    final total = current == null
        ? Duration.zero
        : next.time.difference(current.time);
    final elapsed = current == null ? Duration.zero : _now.difference(current.time);
    final progress = total.inSeconds <= 0
        ? 0.0
        : (elapsed.inSeconds / total.inSeconds).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined,
              color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.nextPrayerLine(
                      s.prayerName(next.prayer), _clock(next.time, s)),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _countdown(next.time.difference(_now), s),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700),
              ),
              Text(s.remaining,
                  style: const TextStyle(color: Colors.white60, fontSize: 10)),
            ],
          ),
        ],
      ),
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
