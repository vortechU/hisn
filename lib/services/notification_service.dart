import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The ten-year dataset rather than `latest_all`. Decoding the full history of
// every zone back to the nineteenth century costs the best part of a tenth of
// a second on a phone, and carries about a megabyte of code, to schedule
// notifications that never reach further than a fortnight ahead. Every zone is
// still present — only the history is trimmed.
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/dua_repository.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../models/sunnah_day.dart';
import '../screens/category_duas_screen.dart';
import '../util/app_navigator.dart';
import 'adhan_audio.dart';
import 'adhan_scheduler.dart';
import 'dua_progress_service.dart';
import 'prayer_service.dart';
import 'sunnah_calendar_service.dart';

/// Schedules local notifications at prayer times.
///
/// Local notifications can only be scheduled for concrete moments, so we keep a
/// rolling window: every time the app launches or the prayer settings change we
/// work out the next few days' reminders and, if that is not what the OS
/// already holds, cancel everything and schedule them afresh. That stays
/// accurate as long as the app is opened occasionally, with no background work
/// required.
///
/// All native calls are guarded for web (where the plugin is a no-op), so the
/// settings UI still works in a browser preview.
class NotificationService extends ChangeNotifier {
  NotificationService(this._prefs, this._repository) {
    _masterEnabled = _prefs.getBool(_kMaster) ?? false;
    for (final prayer in notifiablePrayers) {
      _enabled[prayer] = _prefs.getBool(_keyFor(prayer)) ?? true;
      _iqamahOffset[prayer] = _prefs.getInt(_iqamahKeyFor(prayer)) ?? 0;
    }
    _dailyRemembrance = _prefs.getBool(_kDailyRemembrance) ?? false;
  }

  final SharedPreferences _prefs;
  final DuaRepository _repository;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _kMaster = 'notif_master_enabled';

  /// Whether the last run left anything scheduled with the OS.
  ///
  /// Read at launch to decide whether [reschedule] has to set the plugin up at
  /// all — see the early return there.
  static const _kOutstanding = 'notif_outstanding';
  static const _kLanguage = 'app_language';
  static String _keyFor(Prayer p) => 'notif_prayer_${p.name}';

  // Minutes after the adhan that the reminder fires (0 = at adhan time). Lets
  // the notification match iqāmah rather than adhan for mosques with a fixed
  // gap. The adhan audio itself always plays at the real prayer time —
  // only the reminder notification (and its text) shifts.
  static String _iqamahKeyFor(Prayer p) => 'notif_iqamah_${p.name}';
  static const iqamahOffsetChoices = [0, 5, 10, 15, 20, 25, 30, 45, 60];

  /// The count-up used for a prayer with no iqāmah delay of its own.
  static const defaultIqamahWindow = Duration(minutes: 20);

  // The single "daily remembrance" bundle toggle (morning/evening adhkar +
  // Friday & nightly sunnah reminders).
  static const _kDailyRemembrance = 'notif_daily_remembrance';

  // The default (system-tone) reminder channel — used when the adhan is OFF.
  static const _channelId = 'prayer_times';
  static const _channelName = 'Prayer times';
  static const _channelDescription = 'A reminder at each prayer time';

  // A silent variant — used when the adhan is ON, so the native adhan player is
  // the only sound (no clashing notification tone). Neither channel carries a
  // custom sound, so both display reliably (unlike OEM-dropped custom-sound
  // channels). The adhan audio itself is played by [AdhanScheduler] (a native
  // foreground service), fully decoupled from the notification.
  static const _channelIdSilent = 'prayer_times_silent';
  static const _channelNameSilent = 'Prayer times (silent)';

  // The remembrance reminder channel — a plain system-tone notification,
  // separate from the prayer-time channels so the user can manage it
  // independently in the system settings.
  static const _adhkarChannelId = 'adhkar_reminders';
  static const _adhkarChannelName = 'Remembrance reminders';
  static const _adhkarChannelDescription =
      'Morning/evening adhkar and Friday & nightly sunnah reminders';

  // How the morning/evening adhkar reminders repeat within their window, and a
  // safety cap on how many pings to schedule per window per day.
  static const _repeatEvery = Duration(hours: 2);
  static const _maxPings = 6;
  // Adhkar with this many repetitions (e.g. the 100× tahlīl/tasbīḥ) are treated
  // as optional when deciding whether a set is "done" — they shouldn't keep the
  // reminders going for someone who finished everything else.
  static const _highRepeatThreshold = 100;

  // Notification-id namespaces, chosen so they never collide with the prayer
  // ids (≤24) or the test ids (99998/99999). Morning/evening reserve 10 ids per
  // day (one per ping); the others need one per day.
  static const _morningPingBase = 7000; // 7000 + day*10 + pingIndex
  static const _eveningPingBase = 7100; // 7100 + day*10 + pingIndex
  static const _kahfIdBase = 7300; // 7300 + day
  static const _salawatFridayIdBase = 7400; // 7400 + day
  static const _mulkIdBase = 7500; // 7500 + day
  static const _salawatDailyIdBase = 7600; // 7600 + day
  static const _fastingIdBase = 7700; // 7700 + day

  static const _daysAhead = 3;

  /// The five obligatory prayers (Sunrise is not a prayer).
  static const List<Prayer> notifiablePrayers = [
    Prayer.fajr,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ];

  bool _masterEnabled = false;
  final Map<Prayer, bool> _enabled = {};
  final Map<Prayer, int> _iqamahOffset = {};
  bool _dailyRemembrance = false;
  bool _initialized = false;
  bool _permissionDenied = false;
  bool _exactAlarmsAllowed = true;

  PrayerService? _prayer;
  AdhanAudioService? _adhan;
  DuaProgressService? _progress;
  SunnahCalendarService? _calendar;
  Timer? _debounce;

  bool get masterEnabled => _masterEnabled;
  bool get permissionDenied => _permissionDenied;

  /// Whether the OS lets the app set exact alarms, as of the last
  /// [checkExactAlarms]. The adhan depends on it, not just its timing: since
  /// Android 12 a foreground service may only be started from the background
  /// by an exact alarm, so without one the adhan does not play at all.
  bool get exactAlarmsAllowed => _exactAlarmsAllowed;
  bool isPrayerEnabled(Prayer prayer) => _enabled[prayer] ?? true;
  int iqamahOffset(Prayer prayer) => _iqamahOffset[prayer] ?? 0;

  /// How long after [prayer]'s adhan the time since it is shown — on the
  /// Adhkar tab's header and the compact home-screen widget — before the
  /// countdown to the next adhan takes over.
  ///
  /// The prayer's iqāmah delay, while its reminder is on: that is the wait the
  /// user has told us about. Otherwise — a reminder at the adhan itself, or
  /// one switched off, whose delay is hidden in Settings and so cannot be
  /// what the user expects — [defaultIqamahWindow].
  Duration iqamahWindow(Prayer prayer) {
    final offset = _masterEnabled && isPrayerEnabled(prayer)
        ? iqamahOffset(prayer)
        : 0;
    return offset > 0 ? Duration(minutes: offset) : defaultIqamahWindow;
  }

  /// Whether the daily-remembrance bundle (morning/evening adhkar + Friday &
  /// nightly sunnah reminders) is on. Independent of the prayer-time master.
  bool get dailyRemembranceEnabled => _dailyRemembrance;

  /// Called by the provider whenever the [PrayerService] (times/location), the
  /// [AdhanAudioService] (sound on/off, volume stream), today's reading
  /// [DuaProgressService], or the [SunnahCalendarService] (fasting reminders,
  /// Hijri offset) changes — keeps the scheduled window in sync (so e.g.
  /// finishing the morning adhkar cancels the rest of today's reminders, and
  /// nudging the Hijri date moves the fasting reminders with it), debounced
  /// against bursts.
  void bind(PrayerService prayer, AdhanAudioService adhan,
      DuaProgressService progress, SunnahCalendarService calendar) {
    _prayer = prayer;
    _adhan = adhan;
    _progress = progress;
    _calendar = calendar;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), reschedule);
  }

  AppLang get _lang {
    switch (_prefs.getString(_kLanguage)) {
      case 'ar':
        return AppLang.ar;
      case 'id':
        return AppLang.id;
      default:
        return AppLang.en;
    }
  }

  /// The notification details. Always a plain (no-custom-sound) channel so it
  /// displays reliably; when the adhan is on we use the silent channel so the
  /// native adhan player provides the sound instead of a clashing tone.
  AndroidNotificationDetails _androidDetails(bool adhanOn) {
    return AndroidNotificationDetails(
      adhanOn ? _channelIdSilent : _channelId,
      adhanOn ? _channelNameSilent : _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      playSound: !adhanOn,
    );
  }

  /// Whether the OS will honour exact alarms (Android 12+ gates this behind a
  /// special permission). When false we fall back to inexact scheduling.
  Future<bool> _canScheduleExact() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    return (await android.canScheduleExactNotifications()) ?? false;
  }

  /// Re-reads [exactAlarmsAllowed] — the user can change it in system
  /// settings at any time — and, if it changed, reschedules so the alarms
  /// already set become exact (or fall back) to match.
  Future<void> checkExactAlarms() async {
    if (kIsWeb) return;
    await _ensureInitialized();
    final allowed = await _canScheduleExact();
    if (allowed == _exactAlarmsAllowed) return;
    _exactAlarmsAllowed = allowed;
    notifyListeners();
    await reschedule();
  }

  /// Opens the system "Alarms & reminders" page for the app.
  Future<void> requestExactAlarms() async {
    if (kIsWeb) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
    } catch (_) {}
    await checkExactAlarms();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> setMasterEnabled(bool value) async {
    _masterEnabled = value;
    await _prefs.setBool(_kMaster, value);
    if (value) {
      _permissionDenied = !await _requestPermissions();
    }
    notifyListeners();
    await reschedule();
  }

  Future<void> setPrayerEnabled(Prayer prayer, bool value) async {
    _enabled[prayer] = value;
    await _prefs.setBool(_keyFor(prayer), value);
    notifyListeners();
    await reschedule();
  }

  Future<void> setIqamahOffset(Prayer prayer, int minutes) async {
    assert(iqamahOffsetChoices.contains(minutes));
    _iqamahOffset[prayer] = minutes;
    await _prefs.setInt(_iqamahKeyFor(prayer), minutes);
    notifyListeners();
    await reschedule();
  }

  Future<void> setDailyRemembrance(bool value) async {
    _dailyRemembrance = value;
    await _prefs.setBool(_kDailyRemembrance, value);
    if (value) _permissionDenied = !await _requestPermissions();
    notifyListeners();
    await reschedule();
  }

  /// Whether [reschedule] has anything to do.
  ///
  /// [reschedule] runs at every launch, wanted or not, and setting the plugin
  /// up means decoding the timezone database on the main isolate — right as
  /// the first frames are being drawn. When nothing is switched on, and
  /// nothing is left over from a run when something was, that whole cost buys
  /// nothing.
  ///
  /// A missing flag is read as "something might be outstanding". On an install
  /// predating it, reminders may well be scheduled with the OS, and leaving
  /// them ringing after they were switched off is far worse than paying for
  /// one more launch.
  bool get hasReminderWork {
    if (_anythingOn) return true;
    return _prefs.getBool(_kOutstanding) ?? true;
  }

  /// Whether any kind of reminder is switched on.
  bool get _anythingOn =>
      _masterEnabled ||
      _dailyRemembrance ||
      (_calendar?.remindersEnabled ?? false);

  /// Bring what the OS holds into line with the rolling window of reminders —
  /// the prayer-time reminders, the morning/evening adhkar reminders, and the
  /// night-before sunnah-fasting reminders.
  ///
  /// Runs one at a time. Two at once would each cancel what the other had just
  /// scheduled, and leave the OS holding a mixture of the two.
  Future<void> reschedule() {
    final run = _queue.then((_) => _reschedule());
    // A run that failed must not hold up the ones queued behind it. Said out
    // loud here, since the debounced runs from [bind] have no caller to tell.
    _queue = run.catchError((Object e) => debugPrint('Reschedule failed: $e'));
    return run;
  }

  Future<void> _queue = Future<void>.value();

  /// The plan last handed to the OS in full, or null if none has been since
  /// launch.
  ReminderPlan? _applied;

  Future<void> _reschedule() async {
    if (kIsWeb) return;
    if (_prayer == null) return;
    if (!hasReminderWork) return;

    await _ensureInitialized();
    final now = DateTime.now();
    // Use exact alarms when allowed; otherwise fall back so scheduling never
    // throws and notifications still arrive (just less precisely).
    final exact = _anythingOn && await _canScheduleExact();
    final plan = planAt(now, exact: exact);

    // Nearly every call asks for what the OS already holds: [bind] fires on
    // every dua counted, every location refresh that lands in the same town,
    // every settings screen opened. Handing the whole window over again for
    // each one is a cancel and some fifty alarms, set on the Android thread
    // that also delivers the next tap.
    if (plan == _applied?.after(now)) return;
    await _apply(plan);
  }

  /// Cancel everything and hand [plan] to the OS.
  Future<void> _apply(ReminderPlan plan) async {
    await _plugin.cancelAll();

    var complete = true;
    for (final reminder in plan.reminders) {
      try {
        await _plugin.zonedSchedule(
          reminder.id,
          reminder.title,
          reminder.body,
          tz.TZDateTime.from(reminder.at, tz.local),
          _detailsFor(reminder.channel),
          androidScheduleMode: plan.exact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
          payload: reminder.payload,
        );
      } catch (e) {
        // Don't let one failed schedule abort the rest of the window — but
        // don't call the window delivered either, so the next run tries again.
        complete = false;
        debugPrint('Failed to schedule reminder ${reminder.id}: $e');
      }
    }

    // The adhan audio plays via a native foreground service (decoupled from
    // the notification, which some OEMs drop when it carries a custom sound).
    if (plan.adhanOn) {
      await AdhanScheduler.schedule([
        for (final reminder in plan.reminders)
          if (reminder.adhan != null) reminder.adhan!,
      ]);
    } else {
      await AdhanScheduler.cancelAll();
    }

    await _prefs.setBool(
        _kOutstanding, plan.reminders.isNotEmpty || plan.adhanOn);
    _applied = complete ? plan : null;
  }

  /// Everything the OS should be holding at [now], worked out without
  /// touching the OS — so that it can be compared with what it already holds,
  /// and tested without a device.
  @visibleForTesting
  ReminderPlan planAt(DateTime now, {required bool exact}) {
    final prayer = _prayer;
    if (prayer == null || !_anythingOn) {
      return const ReminderPlan(reminders: [], adhanOn: false, exact: false);
    }

    final s = AppStrings(_lang);
    final reminders = <PlannedReminder>[];
    final adhanOn = _masterEnabled && (_adhan?.enabled ?? false);

    // ---- prayer-time reminders ----
    if (_masterEnabled) {
      final stream = _adhan?.stream ?? AdhanVolumeStream.ring;
      final place = s.place(prayer.locationLabel);
      for (var day = 0; day < _daysAhead; day++) {
        final prayers = prayer.prayersForDay(now.add(Duration(days: day)));
        for (final timing in prayers) {
          if (!isPrayerEnabled(timing.prayer)) continue;
          final offset = iqamahOffset(timing.prayer);
          final fireTime = offset == 0
              ? timing.time
              : timing.time.add(Duration(minutes: offset));
          if (!fireTime.isAfter(now)) continue;
          final id = day * 10 + notifiablePrayers.indexOf(timing.prayer);
          reminders.add(PlannedReminder(
            id: id,
            at: fireTime,
            title: s.notifTitle(timing.prayer),
            body: offset == 0
                ? s.notifBody(timing.prayer, place)
                : s.notifIqamahBody(timing.prayer, place),
            channel: adhanOn ? _channelIdSilent : _channelId,
            // Not once it has sounded. With an iqāmah delay the reminder is
            // still to come after the adhan has played, and an alarm set for a
            // moment already past goes off the instant it is set — the adhan a
            // second time, late.
            adhan: adhanOn && timing.time.isAfter(now)
                ? AdhanAlarm(
                    id: id,
                    time: timing.time,
                    fajr: timing.prayer == Prayer.fajr,
                    usage: AdhanScheduler.usageFor(stream),
                  )
                : null,
          ));
        }
      }
    }

    // ---- daily-remembrance bundle ----
    if (_dailyRemembrance) _planRemembrance(reminders, prayer, now, s);

    // ---- night-before sunnah-fasting reminders ----
    final calendar = _calendar;
    if (calendar != null && calendar.remindersEnabled) {
      _planFasting(reminders, prayer, calendar, now, s);
    }

    return ReminderPlan(
      reminders: List.unmodifiable(reminders),
      adhanOn: adhanOn,
      exact: exact,
    );
  }

  NotificationDetails _detailsFor(String channel) => NotificationDetails(
        android: switch (channel) {
          _channelIdSilent => _androidDetails(true),
          _channelId => _androidDetails(false),
          _ => const AndroidNotificationDetails(
              _adhkarChannelId,
              _adhkarChannelName,
              channelDescription: _adhkarChannelDescription,
              importance: Importance.high,
              priority: Priority.high,
            ),
        },
        iOS: const DarwinNotificationDetails(),
        macOS: const DarwinNotificationDetails(),
      );

  /// Remind the evening before a day worth fasting, or an occasion worth
  /// knowing about.
  ///
  /// Fires at Maghrib, which is both when the Islamic day it announces
  /// actually begins and late enough to be a useful prompt to form the
  /// intention and eat before Fajr.
  ///
  /// Ramadan is skipped: its fast is obligatory and its rhythm is already
  /// well known, so a nightly "you should fast tomorrow" would be noise. Days
  /// on which fasting is forbidden are never announced as fasts — the calendar
  /// resolves that (see [SunnahCalendarRules]) — but the Eid itself is still
  /// worth an occasion notice.
  void _planFasting(
    List<PlannedReminder> plan,
    PrayerService prayer,
    SunnahCalendarService calendar,
    DateTime now,
    AppStrings s,
  ) {
    for (var day = 0; day < _daysAhead; day++) {
      final evening = now.add(Duration(days: day));
      // Maghrib on the evening *before* the day being announced.
      DateTime? maghrib;
      for (final t in prayer.prayersForDay(evening)) {
        if (t.prayer == Prayer.maghrib) maghrib = t.time;
      }
      if (maghrib == null || !maghrib.isAfter(now)) continue;

      final tomorrow = calendar.dayFor(evening.add(const Duration(days: 1)));

      final fast = tomorrow.ruling == FastingRuling.recommended
          ? tomorrow.primaryFast
          : null;
      if (fast != null) {
        plan.add(_remembrance(_fastingIdBase + day, maghrib, s.notifFastTitle,
            s.notifFastBody(fast)));
      } else if (tomorrow.events.isNotEmpty) {
        plan.add(_remembrance(_fastingIdBase + day, maghrib,
            s.eventName(tomorrow.events.first), s.notifOccasionBody));
      }
    }
  }

  /// Schedule the daily-remembrance bundle across the rolling window:
  /// • morning adhkar — every [_repeatEvery] from Fajr until Dhuhr,
  /// • evening adhkar — every [_repeatEvery] from Asr until Isha,
  ///   both stopping for *today* once the set is essentially done (see
  ///   [_essentiallyComplete]),
  /// • Surah Al-Kahf — Fridays at Dhuhr,
  /// • salawāt on the Prophet ﷺ — Fridays at Asr, and a gentle daily nudge at
  ///   Dhuhr on other days,
  /// • Surah Al-Mulk — nightly at Isha.
  void _planRemembrance(
    List<PlannedReminder> plan,
    PrayerService prayer,
    DateTime now,
    AppStrings s,
  ) {
    // Completion only reflects today's real progress (day 0); future days start
    // fresh, so their reminders are always scheduled.
    final morningDone = _essentiallyComplete('morning');
    final eveningDone = _essentiallyComplete('evening');

    for (var day = 0; day < _daysAhead; day++) {
      final date = now.add(Duration(days: day));
      final prayers = prayer.prayersForDay(date);
      DateTime? at(Prayer p) {
        for (final t in prayers) {
          if (t.prayer == p) return t.time;
        }
        return null;
      }

      final fajr = at(Prayer.fajr);
      final dhuhr = at(Prayer.dhuhr);
      final asr = at(Prayer.asr);
      final isha = at(Prayer.isha);
      final isFriday = date.weekday == DateTime.friday;

      // Morning adhkar — repeating Fajr → Dhuhr (skipped today once done).
      if (fajr != null && dhuhr != null && !(day == 0 && morningDone)) {
        _planPings(plan, _morningPingBase + day * 10, fajr, dhuhr, now,
            s.adhkarMorningTitle, s.adhkarMorningBody, 'adhkar:morning');
      }
      // Evening adhkar — repeating Asr → Isha (skipped today once done).
      if (asr != null && isha != null && !(day == 0 && eveningDone)) {
        _planPings(plan, _eveningPingBase + day * 10, asr, isha, now,
            s.adhkarEveningTitle, s.adhkarEveningBody, 'adhkar:evening');
      }
      // Surah Al-Kahf — Friday midday.
      if (isFriday && dhuhr != null && dhuhr.isAfter(now)) {
        plan.add(
            _remembrance(_kahfIdBase + day, dhuhr, s.kahfTitle, s.kahfBody));
      }
      // Salawāt — Friday afternoon (emphasized), or a daily nudge otherwise.
      if (isFriday) {
        if (asr != null && asr.isAfter(now)) {
          plan.add(_remembrance(_salawatFridayIdBase + day, asr,
              s.salawatFridayTitle, s.salawatFridayBody));
        }
      } else if (dhuhr != null && dhuhr.isAfter(now)) {
        plan.add(_remembrance(
            _salawatDailyIdBase + day, dhuhr, s.salawatTitle, s.salawatBody));
      }
      // Surah Al-Mulk — nightly before sleep.
      if (isha != null && isha.isAfter(now)) {
        plan.add(
            _remembrance(_mulkIdBase + day, isha, s.mulkTitle, s.mulkBody));
      }
    }
  }

  /// A repeating reminder every [_repeatEvery] from [start] until [end]
  /// (exclusive), only for moments still in the future. Ids are [baseId] + the
  /// ping index.
  void _planPings(
    List<PlannedReminder> plan,
    int baseId,
    DateTime start,
    DateTime end,
    DateTime now,
    String title,
    String body,
    String payload,
  ) {
    var time = start;
    var index = 0;
    while (time.isBefore(end) && index < _maxPings) {
      if (time.isAfter(now)) {
        plan.add(_remembrance(baseId + index, time, title, body, payload));
      }
      time = time.add(_repeatEvery);
      index++;
    }
  }

  /// Whether a remembrance set is essentially complete for today: every dua in
  /// it below [_highRepeatThreshold] repetitions has reached its target. The
  /// long 100× tahlīl/tasbīḥ are excluded so they don't keep nagging someone
  /// who finished everything else.
  bool _essentiallyComplete(String categoryId) {
    final progress = _progress;
    if (progress == null) return false;
    final duas = _repository.duasForCategory(categoryId);
    if (duas.isEmpty) return false;
    var hadEssential = false;
    for (final dua in duas) {
      if (dua.repeat >= _highRepeatThreshold) continue;
      hadEssential = true;
      if (progress.countOf(dua.id) < dua.repeat) return false;
    }
    return hadEssential;
  }

  /// One remembrance reminder. A non-null [payload] (`adhkar:<id>`) makes a
  /// tap open that category (see [_handleNotificationTap]); null just opens
  /// the app.
  static PlannedReminder _remembrance(
    int id,
    DateTime at,
    String title,
    String body, [
    String? payload,
  ]) =>
      PlannedReminder(
        id: id,
        at: at,
        title: title,
        body: body,
        channel: _adhkarChannelId,
        payload: payload,
      );

  /// Handle a notification tap: an `adhkar:<categoryId>` payload opens that
  /// category's read-and-count screen via the app-wide navigator key.
  void _handleNotificationTap(String? payload) {
    if (payload == null || !payload.startsWith('adhkar:')) return;
    final category = _repository.categoryById(payload.substring(7));
    if (category == null) return;
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(
      builder: (_) => CategoryDuasScreen(category: category),
    ));
  }

  /// Fire test notifications: one **immediately** (directly tests that the app
  /// can post a notification + play the adhan, with no alarm/permission
  /// guesswork) and one **scheduled ~12s out** (tests background/locked
  /// delivery). Always attempts both; returns the OS's actual
  /// notifications-enabled state (null = unknown) so the UI can hint.
  Future<bool?> sendTestNotification() async {
    if (kIsWeb) return false;
    await _ensureInitialized();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    // Prompt if needed; the result is unreliable on some OEMs so we ignore it.
    try {
      await android?.requestNotificationsPermission();
    } catch (_) {}
    try {
      await android?.requestExactAlarmsPermission();
    } catch (_) {}

    final adhanOn = _adhan?.enabled ?? false;
    final stream = _adhan?.stream ?? AdhanVolumeStream.ring;
    final s = AppStrings(_lang);
    final details = NotificationDetails(
      android: _androidDetails(adhanOn),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );

    // 1) Immediate notification — the truth-teller for "can this app notify?".
    try {
      await _plugin.show(99998, s.testNotifTitle, s.testNotifBody, details);
    } catch (e) {
      debugPrint('Immediate test failed: $e');
    }

    // 2) Scheduled ~12s out — tests notification delivery while screen-locked.
    try {
      final exact = await _canScheduleExact();
      await _plugin.zonedSchedule(
        99999,
        s.testNotifTitle,
        s.testNotifBody,
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 12)),
        details,
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Scheduled test failed: $e');
    }

    // 3) If the adhan is on, play it now via the native foreground service so
    //    the user can confirm the actual adhan-playback path works.
    if (adhanOn) {
      await AdhanScheduler.playNow(
        fajr: false,
        usage: AdhanScheduler.usageFor(stream),
      );
    }

    final enabled = await android?.areNotificationsEnabled();
    _permissionDenied = enabled == false;
    notifyListeners();
    return enabled;
  }

  Future<void> _ensureInitialized() async {
    if (_initialized || kIsWeb) return;

    tzdata.initializeTimeZones();
    try {
      final name = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Leave tz.local at its default (UTC) if the zone can't be resolved.
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) =>
          _handleNotificationTap(response.payload),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      // Default (system tone) channel — used when the adhan is off.
      await android.createNotificationChannel(const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
      ));
      // Silent channel — used when the adhan is on (native player is the sound).
      await android.createNotificationChannel(const AndroidNotificationChannel(
        _channelIdSilent,
        _channelNameSilent,
        description: _channelDescription,
        importance: Importance.max,
        playSound: false,
      ));
      // Adhkar (morning/evening) reminder channel.
      await android.createNotificationChannel(const AndroidNotificationChannel(
        _adhkarChannelId,
        _adhkarChannelName,
        description: _adhkarChannelDescription,
        importance: Importance.high,
      ));
    }

    _initialized = true;

    // If the app was launched by tapping a reminder, honour its payload once the
    // first frame (and thus the navigator) is ready.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final launchPayload = launch?.notificationResponse?.payload;
    if ((launch?.didNotificationLaunchApp ?? false) && launchPayload != null) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _handleNotificationTap(launchPayload));
    }
  }

  Future<bool> _requestPermissions() async {
    if (kIsWeb) return false;
    await _ensureInitialized();
    var granted = true;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      // Prompt (no-op if already decided). The *return value* of this request
      // is unreliable on some OEMs (e.g. MIUI returns false/null even when
      // notifications are on), so we don't gate on it.
      try {
        await android.requestNotificationsPermission();
      } catch (_) {}
      try {
        await android.requestExactAlarmsPermission();
      } catch (_) {}
      // Authoritative source of truth: the actual enabled state.
      granted = await android.areNotificationsEnabled() ?? true;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      granted = await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return granted;
  }
}

/// One reminder as the OS should hold it.
@immutable
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.channel,
    this.payload,
    this.adhan,
  });

  final int id;

  /// When it fires.
  final DateTime at;
  final String title;
  final String body;

  /// The notification channel it posts on.
  final String channel;

  /// What a tap on it opens; null opens the app.
  final String? payload;

  /// The adhan played at the same prayer, when the adhan is on and has yet to
  /// sound. Its time is the prayer's own, so with an iqāmah delay it comes due
  /// before [at] does.
  final AdhanAlarm? adhan;

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder &&
      other.id == id &&
      other.at == at &&
      other.title == title &&
      other.body == body &&
      other.channel == channel &&
      other.payload == payload &&
      other.adhan == adhan;

  /// This reminder as it stands at [now]: an adhan that has already sounded
  /// is history, the same as a reminder that has.
  PlannedReminder after(DateTime now) {
    final adhan = this.adhan;
    if (adhan == null || adhan.time.isAfter(now)) return this;
    return PlannedReminder(
      id: id,
      at: at,
      title: title,
      body: body,
      channel: channel,
      payload: payload,
    );
  }

  @override
  int get hashCode =>
      Object.hash(id, at, title, body, channel, payload, adhan);
}

/// Everything the OS should be holding: the reminders, whether the native
/// adhan player is scheduled alongside them, and whether they may fire to the
/// minute.
@immutable
class ReminderPlan {
  const ReminderPlan({
    required this.reminders,
    required this.adhanOn,
    required this.exact,
  });

  final List<PlannedReminder> reminders;
  final bool adhanOn;
  final bool exact;

  /// This plan as it stands at [now]. A reminder that has fired is the OS's
  /// history, not something left to schedule — so a plan made an hour ago,
  /// less what fired in that hour, is the plan to compare a new one against.
  ReminderPlan after(DateTime now) => ReminderPlan(
        reminders: [
          for (final reminder in reminders)
            if (reminder.at.isAfter(now)) reminder.after(now),
        ],
        adhanOn: adhanOn,
        exact: exact,
      );

  @override
  bool operator ==(Object other) =>
      other is ReminderPlan &&
      other.adhanOn == adhanOn &&
      other.exact == exact &&
      listEquals(other.reminders, reminders);

  @override
  int get hashCode => Object.hash(adhanOn, exact, Object.hashAll(reminders));
}
