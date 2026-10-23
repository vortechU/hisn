import 'dart:async';

import 'package:flutter/foundation.dart' show mergeSort;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/notification_service.dart';
import '../services/prayer_service.dart';
import '../services/sunnah_calendar_service.dart';
import '../theme/app_theme.dart';
import 'arabic_text.dart';
import 'ornament.dart';
import 'recommended_adhkar.dart';

/// The mihrab of the Adhkar tab: today's date, the wait until the next adhan —
/// or, just after an adhan, the time since it — the prayer now in force, the
/// day drawn as a strip with each prayer at its true hour, and at the foot the
/// adhkar to read now.
///
/// This is the one filled field on the screen; everything below it sits on the
/// plain ground. Tap it for the day's full schedule.
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
      // Everything this field shows is drawn to the minute — the countdown,
      // the strip's marker. Rebuilding it on the other fifty-nine ticks
      // redraws the same picture, at the head of the app's busiest scroll.
      if (now.minute == _now.minute && now.hour == _now.hour) return;
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
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Ms.margin, 0, Ms.margin, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
                  child: Text(
                    s.todaysPrayers(s.place(service.locationLabel)),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                PrayerTimetable(
                  prayers: service.todaysPrayers,
                  marks: service.todaysMarks,
                  next: next,
                  now: _now,
                ),
              ],
            ),
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
    final window = current == null
        ? Duration.zero
        : context.watch<NotificationService>().iqamahWindow(current.prayer);
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final quiet = ms.onField.withValues(alpha: 0.88);

    final elapsed =
        current == null ? Duration.zero : _now.difference(current.time);
    final sinceAdhan = current != null && elapsed < window;
    final shown = sinceAdhan ? current : next;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Ms.margin, 12, Ms.margin, 0),
      child: MihrabField(
        onTap: () => _showSchedule(context, service),
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Today, under the apex.
            Text(
              s.hijriDate(
                _now,
                offset: context.watch<SunnahCalendarService>().offset,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(color: quiet),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: shown == null
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Numeral(
                                _countdown(
                                  sinceAdhan
                                      ? elapsed
                                      : shown.time.difference(_now),
                                  s,
                                ),
                                size: 52,
                                weight: FontWeight.w500,
                                color: ms.onField,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${sinceAdhan ? s.sinceAdhan : s.next} · '
                              '${s.prayerName(shown.prayer)} '
                              '${_clock(shown.time, s)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(color: ms.onField),
                            ),
                          ],
                        ),
                ),
                if (current != null) ...[
                  const SizedBox(width: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: ArabicText(
                            current.prayer.arabicName,
                            fontSize: 28,
                            color: ms.onField,
                            height: 1.45,
                          ),
                        ),
                        Text(
                          s.rtl
                              ? s.now
                              : '${s.now} · ${s.prayerName(current.prayer)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: quiet),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            DayStrip(
              prayers: service.todaysPrayers,
              now: _now,
              next: next,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.place_outlined, size: 14, color: quiet),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${s.dateLabel(_now)} · ${s.place(service.locationLabel)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: quiet),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const RecommendedAdhkar(),
          ],
        ),
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
    if (s.lang.name == 'ur') {
      return h > 0 ? '$h گھنٹے $m منٹ' : '$m منٹ';
    }
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}

/// The day as a line: each prayer a mark at its true hour, so the long wait
/// from Fajr to Dhuhr and the short one from Maghrib to Isha are visibly long
/// and short. What has passed is drawn solid; the next prayer is an open
/// ring; a small bar stands at now.
class DayStrip extends StatelessWidget {
  const DayStrip({
    super.key,
    required this.prayers,
    required this.now,
    required this.next,
  });

  final List<PrayerTiming> prayers;
  final DateTime now;
  final PrayerTiming? next;

  @override
  Widget build(BuildContext context) {
    if (prayers.isEmpty) return const SizedBox.shrink();
    final ms = ManuscriptTheme.of(context);
    final s = AppStrings.of(context);
    return Semantics(
      label: prayers
          .map((p) => '${s.prayerName(p.prayer)} ${_PrayerHeaderState._clock(p.time, s)}')
          .join(', '),
      child: SizedBox(
        height: 18,
        width: double.infinity,
        child: CustomPaint(
          painter: _DayStripPainter(
            prayers: prayers,
            now: now,
            next: next,
            ink: ms.onField,
            field: ms.field,
            rtl: Directionality.of(context) == TextDirection.rtl,
          ),
        ),
      ),
    );
  }
}

class _DayStripPainter extends CustomPainter {
  _DayStripPainter({
    required this.prayers,
    required this.now,
    required this.next,
    required this.ink,
    required this.field,
    required this.rtl,
  });

  final List<PrayerTiming> prayers;
  final DateTime now;
  final PrayerTiming? next;
  final Color ink;

  /// The field behind the strip, to hollow out the next prayer's ring.
  final Color field;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    // The strip spans the praying day with a little air at each end, so Fajr
    // and Isha don't sit on the edges.
    const pad = Duration(minutes: 50);
    final start = prayers.first.time.subtract(pad);
    final end = prayers.last.time.add(pad);
    final span = end.difference(start).inSeconds.toDouble();
    const r = 4.5;
    double xOf(DateTime t) {
      final f = (t.difference(start).inSeconds / span).clamp(0.0, 1.0);
      final x = r + f * (size.width - 2 * r);
      return rtl ? size.width - x : x;
    }

    final y = size.height / 2;
    final nowX = xOf(now);
    final line = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(r, y),
      Offset(size.width - r, y),
      line..color = ink.withValues(alpha: 0.22),
    );
    canvas.drawLine(
      Offset(rtl ? size.width - r : r, y),
      Offset(nowX, y),
      line..color = ink.withValues(alpha: 0.6),
    );

    for (final p in prayers) {
      final x = xOf(p.time);
      final isNext = next != null && next!.time == p.time;
      final passed = !p.time.isAfter(now);
      if (isNext) {
        canvas.drawCircle(Offset(x, y), r + 2.5, Paint()..color = ink);
        canvas.drawCircle(Offset(x, y), r - 0.5, Paint()..color = field);
      } else if (passed) {
        canvas.drawCircle(Offset(x, y), r, Paint()..color = ink);
      } else {
        canvas.drawCircle(
          Offset(x, y),
          r,
          Paint()..color = Color.lerp(ink, const Color(0x00000000), 0.55)!,
        );
      }
    }

    // Now: a short upright bar through the line.
    canvas.drawLine(
      Offset(nowX, y - 7),
      Offset(nowX, y + 7),
      Paint()
        ..color = ink
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_DayStripPainter old) =>
      old.now != now ||
      old.next != next ||
      old.prayers != prayers ||
      old.ink != ink ||
      old.field != field ||
      old.rtl != rtl;
}

/// The day's prayers as a timetable: the name, the Arabic name and the time in
/// columns that never move, whatever the names' widths. Passed prayers recede,
/// the prayer in force carries a mark, and the next one is lifted.
class PrayerTimetable extends StatelessWidget {
  const PrayerTimetable({
    super.key,
    required this.prayers,
    required this.next,
    required this.now,
    this.marks = const [],
    this.onTap,
    this.inField = false,
  });

  final List<PrayerTiming> prayers;

  /// Sunrise and the night's times, set in among the prayers by the hour but
  /// in a quieter hand: they are times to know, not prayers to keep.
  final List<DayMarkTiming> marks;
  final PrayerTiming? next;
  final DateTime now;
  final VoidCallback? onTap;

  /// Sets the table straight onto a [MihrabField], in the field's ink, rather
  /// than on a paper panel of its own.
  final bool inField;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ms = ManuscriptTheme.of(context);
    final s = AppStrings.of(context);
    // The prayer in force: the last one whose time has come.
    final current = prayers.lastIndexWhere((p) => !p.time.isAfter(now));

    final entries = <(DateTime, Widget)>[
      for (var i = 0; i < prayers.length; i++)
        (
          prayers[i].time,
          _TimetableRow(
            name: s.prayerName(prayers[i].prayer),
            arabicName: prayers[i].prayer.arabicName,
            time: prayers[i].time,
            state: next != null &&
                    next!.prayer == prayers[i].prayer &&
                    next!.time == prayers[i].time
                ? _RowState.next
                : i == current
                    ? _RowState.now
                    : i < current
                        ? _RowState.passed
                        : _RowState.later,
            inField: inField,
            onTap: onTap,
            theme: theme,
            ms: ms,
            s: s,
          ),
        ),
      for (final m in marks)
        (
          m.time,
          _TimetableRow(
            name: s.dayMarkName(m.mark),
            arabicName: m.mark.arabicName,
            time: m.time,
            state: m.time.isAfter(now) ? _RowState.later : _RowState.passed,
            mark: true,
            inField: inField,
            onTap: onTap,
            theme: theme,
            ms: ms,
            s: s,
          ),
        ),
    ];
    // Stable, so a mark at the same minute as a prayer stays after it.
    mergeSort(entries, compare: (a, b) => a.$1.compareTo(b.$1));
    final rows = Column(children: [for (final e in entries) e.$2]);

    if (inField) return rows;
    return Material(
      color: ms.paper,
      borderRadius: BorderRadius.circular(Ms.rPanel),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: const EdgeInsets.all(6), child: rows),
    );
  }
}

enum _RowState { passed, now, next, later }

class _TimetableRow extends StatelessWidget {
  const _TimetableRow({
    required this.name,
    required this.arabicName,
    required this.time,
    required this.state,
    this.mark = false,
    required this.inField,
    required this.onTap,
    required this.theme,
    required this.ms,
    required this.s,
  });

  final String name;
  final String arabicName;
  final DateTime time;
  final _RowState state;

  /// A [DayMark] rather than a prayer: set smaller and fainter.
  final bool mark;
  final bool inField;
  final VoidCallback? onTap;
  final ThemeData theme;
  final ManuscriptTheme ms;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final isNext = state == _RowState.next;
    final strong = isNext || state == _RowState.now;

    // On the field the whole table is in the field's ink, and the next prayer
    // is lifted by a lighter band; on paper the next prayer takes the field.
    Color ink;
    final Color? band;
    if (inField) {
      ink = state == _RowState.passed
          ? ms.onField.withValues(alpha: 0.8)
          : ms.onField;
      band = isNext ? ms.onField.withValues(alpha: 0.12) : null;
    } else {
      ink = isNext
          ? ms.onField
          : state == _RowState.passed
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.onSurface;
      band = isNext ? ms.field : null;
    }
    if (mark) ink = ink.withValues(alpha: ink.a * 0.78);
    final weight = strong ? FontWeight.w600 : FontWeight.w400;
    final text = mark ? theme.textTheme.bodyMedium : theme.textTheme.titleSmall;

    return Material(
      color: band ?? Colors.transparent,
      borderRadius: BorderRadius.circular(Ms.rPanel - 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Ms.rPanel - 6),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: mark ? 7 : 12),
          child: Row(
            children: [
              // The prayer in force carries a small mark, so "now" reads apart
              // from the prayers already passed.
              SizedBox(
                width: 16,
                child: state == _RowState.now
                    ? Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: inField ? ms.onField : ms.rubric,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text?.copyWith(
                    color: ink,
                    fontWeight: strong
                        ? FontWeight.w600
                        : mark
                            ? FontWeight.w400
                            : FontWeight.w500,
                  ),
                ),
              ),
              if (!s.ar)
                SizedBox(
                  width: 72,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: ArabicText(
                      arabicName,
                      fontSize: mark ? 15 : 18,
                      color: ink,
                      height: 1.5,
                    ),
                  ),
                ),
              // A fixed column, aligned to its end, so the minutes line up
              // down the table whatever each time's width.
              SizedBox(
                width: 96,
                child: Text(
                  _PrayerHeaderState._clock(time, s),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  style: text?.copyWith(
                    color: ink,
                    fontWeight: weight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
