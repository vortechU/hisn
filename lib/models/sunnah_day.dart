import 'package:hijri/hijri_calendar.dart';

/// A fast the Sunnah encourages, that a given day may fall on.
///
/// Only fasts with well-established grounding are listed. Each carries its
/// reference in [SunnahFast.source] so the screen can cite it, in keeping with
/// the rest of the app's content.
enum SunnahFast {
  /// Ramadan — obligatory, not voluntary; present so the calendar can say so
  /// rather than suggesting a voluntary fast on top of it.
  ramadan,

  monday,
  thursday,

  /// The "white days" — 13th, 14th and 15th of every Hijri month.
  whiteDay,

  /// 9th Muharram, fasted with Ashura so as to differ from the practice of
  /// the People of the Book.
  tasua,

  /// 10th Muharram.
  ashura,

  /// The first nine days of Dhul Hijjah (excluding the 10th, which is Eid).
  dhulHijjah,

  /// 9th Dhul Hijjah — for those not performing Hajj.
  arafah,

  /// Six days of Shawwal, following Ramadan.
  sixOfShawwal,
}

/// A day in the Islamic year worth marking.
///
/// Deliberately limited to occasions whose date and observance are agreed on.
/// Days whose date is not authentically established (the Mawlid on 12 Rabiʿ
/// al-Awwal, the Isrāʾ and Miʿrāj on 27 Rajab, mid-Shaʿbān) are left out
/// rather than asserted — see the project's content-authenticity note.
enum IslamicEvent {
  islamicNewYear,
  ashuraDay,
  ramadanBegins,
  lastTenNights,
  eidAlFitr,
  dhulHijjahBegins,
  dayOfArafah,
  eidAlAdha,
}

/// Whether fasting on a day is obligatory, encouraged, or not allowed.
enum FastingRuling {
  /// Nothing particular about this day.
  none,

  /// Ramadan.
  obligatory,

  /// One or more voluntary fasts fall here.
  recommended,

  /// The two Eids and the days of Tashrīq, on which fasting is forbidden.
  forbidden,
}

/// Why fasting is not allowed on a given day.
enum FastingBar { eidAlFitr, eidAlAdha, tashriq }

/// One day, resolved to its Hijri date and everything the calendar knows
/// about it.
class SunnahDay {
  const SunnahDay({
    required this.date,
    required this.hijriDay,
    required this.hijriMonth,
    required this.hijriYear,
    required this.fasts,
    required this.events,
    required this.ruling,
    this.bar,
  });

  /// The Gregorian date, at midnight local time.
  final DateTime date;

  /// The Hijri date this day falls on, after the user's sighting offset.
  final int hijriDay;

  /// 1 = Muharram … 12 = Dhul Hijjah.
  final int hijriMonth;
  final int hijriYear;

  /// The sunnah fasts falling on this day, most specific first. Empty when
  /// fasting is forbidden.
  final List<SunnahFast> fasts;

  /// Occasions falling on this day.
  final List<IslamicEvent> events;

  final FastingRuling ruling;

  /// Set only when [ruling] is [FastingRuling.forbidden].
  final FastingBar? bar;

  /// Whether this day is worth showing in a list of upcoming days.
  bool get isNotable => fasts.isNotEmpty || events.isNotEmpty;

  /// The fast to lead with when the day carries more than one.
  SunnahFast? get primaryFast => fasts.isEmpty ? null : fasts.first;
}

/// Resolves Gregorian dates to [SunnahDay]s.
///
/// Hijri dates come from the tabular Umm al-Qura calculation, which can differ
/// from a local moon sighting by a day either way. [offset] shifts the
/// conversion so the user can align it with their own community — which
/// matters here more than it does for a date display, because getting it wrong
/// means suggesting a fast on Eid.
class SunnahCalendarRules {
  const SunnahCalendarRules({this.offset = 0});

  /// Days added to the Gregorian date before converting, in [-2, 2].
  final int offset;

  /// The range the offset may take.
  static const int minOffset = -2;
  static const int maxOffset = 2;

  static const int _muharram = 1;
  static const int _ramadan = 9;
  static const int _shawwal = 10;
  static const int _dhulHijjah = 12;

  /// Strip the time and pin to midday before doing any date arithmetic, so
  /// adding days can't land on a skipped or repeated hour across a DST change.
  static DateTime _noon(DateTime date) =>
      DateTime(date.year, date.month, date.day, 12);

  /// Midnight on [date]'s day — the canonical form stored on [SunnahDay].
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Everything known about the day [date] falls on.
  SunnahDay dayFor(DateTime date) {
    final shifted = _noon(date).add(Duration(days: offset));
    final h = HijriCalendar.fromDate(shifted);
    final hDay = h.hDay;
    final hMonth = h.hMonth;
    final weekday = date.weekday;

    final events = <IslamicEvent>[];
    if (hMonth == _muharram && hDay == 1) {
      events.add(IslamicEvent.islamicNewYear);
    }
    if (hMonth == _muharram && hDay == 10) events.add(IslamicEvent.ashuraDay);
    if (hMonth == _ramadan && hDay == 1) events.add(IslamicEvent.ramadanBegins);
    if (hMonth == _ramadan && hDay == 21) {
      events.add(IslamicEvent.lastTenNights);
    }
    if (hMonth == _shawwal && hDay == 1) events.add(IslamicEvent.eidAlFitr);
    if (hMonth == _dhulHijjah && hDay == 1) {
      events.add(IslamicEvent.dhulHijjahBegins);
    }
    if (hMonth == _dhulHijjah && hDay == 9) events.add(IslamicEvent.dayOfArafah);
    if (hMonth == _dhulHijjah && hDay == 10) events.add(IslamicEvent.eidAlAdha);

    // Fasting is forbidden on the two Eids and the three days of Tashrīq that
    // follow Eid al-Adha. Checked before anything else, so a Monday or a white
    // day falling here is never suggested: the 13th of Dhul Hijjah is both a
    // white day and a day of Tashrīq, and the prohibition wins.
    final bar = _barFor(hMonth, hDay);
    if (bar != null) {
      return SunnahDay(
        date: dateOnly(date),
        hijriDay: hDay,
        hijriMonth: hMonth,
        hijriYear: h.hYear,
        fasts: const [],
        events: events,
        ruling: FastingRuling.forbidden,
        bar: bar,
      );
    }

    // Ramadan's fast is obligatory, so voluntary fasts aren't suggested on top
    // of it — a Monday in Ramadan is simply a day of Ramadan.
    if (hMonth == _ramadan) {
      return SunnahDay(
        date: dateOnly(date),
        hijriDay: hDay,
        hijriMonth: hMonth,
        hijriYear: h.hYear,
        fasts: const [SunnahFast.ramadan],
        events: events,
        ruling: FastingRuling.obligatory,
      );
    }

    // Most specific first, so the day is labelled by its strongest occasion.
    final fasts = <SunnahFast>[];
    if (hMonth == _dhulHijjah && hDay == 9) fasts.add(SunnahFast.arafah);
    if (hMonth == _muharram && hDay == 10) fasts.add(SunnahFast.ashura);
    if (hMonth == _muharram && hDay == 9) fasts.add(SunnahFast.tasua);
    if (hMonth == _dhulHijjah && hDay <= 9) fasts.add(SunnahFast.dhulHijjah);
    // The six of Shawwal may be fasted on any days of the month; the 2nd to the
    // 7th is the common way of doing it, and is what gets suggested.
    if (hMonth == _shawwal && hDay >= 2 && hDay <= 7) {
      fasts.add(SunnahFast.sixOfShawwal);
    }
    if (hDay >= 13 && hDay <= 15) fasts.add(SunnahFast.whiteDay);
    if (weekday == DateTime.monday) fasts.add(SunnahFast.monday);
    if (weekday == DateTime.thursday) fasts.add(SunnahFast.thursday);

    return SunnahDay(
      date: dateOnly(date),
      hijriDay: hDay,
      hijriMonth: hMonth,
      hijriYear: h.hYear,
      fasts: fasts,
      events: events,
      ruling:
          fasts.isEmpty ? FastingRuling.none : FastingRuling.recommended,
    );
  }

  static FastingBar? _barFor(int hMonth, int hDay) {
    if (hMonth == _shawwal && hDay == 1) return FastingBar.eidAlFitr;
    if (hMonth == _dhulHijjah && hDay == 10) return FastingBar.eidAlAdha;
    if (hMonth == _dhulHijjah && hDay >= 11 && hDay <= 13) {
      return FastingBar.tashriq;
    }
    return null;
  }

  /// The notable days in the [days] starting at [from], in order.
  List<SunnahDay> upcoming(DateTime from, {int days = 60}) {
    final start = _noon(from);
    final out = <SunnahDay>[];
    for (var i = 0; i < days; i++) {
      final day = dayFor(start.add(Duration(days: i)));
      if (day.isNotable) out.add(day);
    }
    return out;
  }
}
