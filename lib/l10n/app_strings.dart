import 'package:adhan/adhan.dart';
import 'package:flutter/widgets.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:provider/provider.dart';

import '../i18n/strings.g.dart';
import 'locale_controller.dart';

/// Bump this when shipping a build so the About screen confirms what's running.
const String kAppVersion = '1.9.0';

/// UI strings facade. The actual text lives in per-language files under
/// `lib/i18n/` (`en.i18n.json`, `ar.i18n.json`, `id.i18n.json`) and is compiled
/// to type-safe Dart by the `slang` package (run `dart run slang` after edits).
///
/// This class adapts that generated API to the rest of the app: it keeps the
/// stable `AppStrings.of(context).xyz` call sites, and houses the bits slang
/// can't express directly — switching on Dart enums ([Prayer]/[Madhab]) and
/// formatting dates. **Adding a language = add one `<locale>.i18n.json` file,
/// run slang, and add the locale here + in [LocaleController].**
class AppStrings {
  AppStrings(this.lang) : _t = _translationsFor(lang);

  /// The active UI language.
  final AppLang lang;

  /// The generated translations for [lang].
  final Translations _t;

  /// Whether the app is currently in Arabic (drives RTL + Arabic-title display).
  bool get ar => lang == AppLang.ar;

  /// Whether the app is currently in Indonesian.
  bool get id => lang == AppLang.id;

  static AppStrings of(BuildContext context) =>
      AppStrings(context.watch<LocaleController>().lang);

  /// Non-reactive read for use inside callbacks.
  static AppStrings read(BuildContext context) =>
      AppStrings(context.read<LocaleController>().lang);

  // One Translations instance per language, built once and reused.
  static final Map<AppLang, Translations> _cache = {};
  static Translations _translationsFor(AppLang lang) =>
      _cache.putIfAbsent(lang, () => _appLocaleFor(lang).buildSync());

  static AppLocale _appLocaleFor(AppLang lang) {
    switch (lang) {
      case AppLang.ar:
        return AppLocale.ar;
      case AppLang.id:
        return AppLocale.id;
      case AppLang.en:
        return AppLocale.en;
    }
  }

  // ---- generic ----
  String get appName => 'Hisn';

  // ---- navigation ----
  String get navAdhkar => _t.navAdhkar;
  String get navQuran => _t.navQuran;
  String get navTasbih => _t.navTasbih;
  String get navQibla => _t.navQibla;
  String get navSaved => _t.navSaved;
  String get navSettings => _t.navSettings;
  String get navPrayer => _t.navPrayer;

  // ---- adhkar home ----
  String get searchDuas => _t.searchDuas;
  String get allAdhkar => _t.allAdhkar;
  String get groupDaily => _t.groupDaily;
  String get groupSituational => _t.groupSituational;
  String get groupMine => _t.groupMine;

  // ---- muhassan (daily streak meter) ----
  String get muhassanHeading => _t.muhassanHeading;
  String muhassanToday(int percent) => _t.muhassanToday(percent: percent);
  String get muhassanComplete => _t.muhassanComplete;
  String get muhassanMorning => _t.muhassanMorning;
  String get muhassanEvening => _t.muhassanEvening;
  String streakDays(int n) =>
      n == 1 ? _t.streakDaysOne : _t.streakDaysOther(n: n);
  String get streakStart => _t.streakStart;
  String streakBest(int n) => _t.streakBest(n: n);

  // ---- streak stats page ----
  String get streakTitle => _t.streakTitle;
  String get streakWord => _t.streakWord;
  String get statCurrent => _t.statCurrent;
  String get statBest => _t.statBest;
  String get statTotal => _t.statTotal;
  String daysValue(int n) =>
      n == 1 ? _t.daysValueOne : _t.daysValueOther(n: n);
  String get streakOnFire => _t.streakOnFire;
  String get streakTodayPending => _t.streakTodayPending;
  String get streakBroken => _t.streakBroken;
  String get last4Weeks => _t.last4Weeks;
  String get todayLabel => _t.todayLabel;
  String get fortifiedLegend => _t.fortifiedLegend;

  /// Single-letter weekday headers, Monday-first.
  List<String> get weekdayLetters => _t.weekdayLetters;

  // ---- quran ----
  String get quranTitle => _t.quranTitle;
  String get searchSurah => _t.searchSurah;
  String get continueReading => _t.continueReading;
  String get surahWord => _t.surahWord;
  String revelationLabel(String revelation) =>
      revelation == 'meccan' ? _t.revelationMeccan : _t.revelationMedinan;
  String versesCount(int n) =>
      n == 1 ? _t.versesCountOne : _t.versesCountOther(n: n);
  String juzLabel(int n) => _t.juzLabel(n: n);
  String get quranBookmarks => _t.quranBookmarks;
  String get noBookmarks => _t.noBookmarks;
  String get bookmarkAdded => _t.bookmarkAdded;
  String get bookmarkRemoved => _t.bookmarkRemoved;
  String get goToAyah => _t.goToAyah;
  String get chooseSurah => _t.chooseSurah;
  String get verseNumber => _t.verseNumber;
  String verseRange(int n) => _t.verseRange(n: n);
  String get goAction => _t.goAction;

  // ---- my duas (custom) ----
  String get myDuas => _t.myDuas;
  String get myDuasArabic => 'أدعيتي';
  String get myDuasSub => _t.myDuasSub;
  String get addDua => _t.addDua;
  String get newDua => _t.newDua;
  String get fieldArabic => _t.fieldArabic;
  String get fieldArabicRequired => _t.fieldArabicRequired;
  String get fieldTitle => _t.fieldTitle;
  String get fieldTransliteration => _t.fieldTransliteration;
  String get fieldTranslation => _t.fieldTranslation;
  String get fieldReference => _t.fieldReference;
  String get fieldRepeat => _t.fieldRepeat;
  String get save => _t.save;
  String get cancel => _t.cancel;
  String get delete => _t.delete;
  String get edit => _t.edit;
  String get deleteDua => _t.deleteDua;
  String get editDua => _t.editDua;
  String get deleteDuaConfirm => _t.deleteDuaConfirm;
  String get duaSaved => _t.duaSaved;
  String get duaUpdated => _t.duaUpdated;
  String get noCustomTitle => _t.noCustomTitle;
  String get noCustomBody => _t.noCustomBody;
  String get recommendedNow => _t.recommendedNow;
  String readNow(int count) =>
      count == 1 ? _t.readNowOne : _t.readNowOther(count: count);
  String duaCount(int count) =>
      count == 1 ? _t.duaCountOne : _t.duaCountOther(count: count);

  // ---- prayer header ----
  String get now => _t.now;
  String get next => _t.next;
  String get remaining => _t.remaining;
  String get countdownNow => _t.countdownNow;
  String todaysPrayers(String location) =>
      _t.todaysPrayers(location: location);

  // ---- search ----
  String get searchHint => _t.searchHint;
  String get clear => _t.clear;
  String get searchPrompt => _t.searchPrompt;
  String noResults(String query) => _t.noResults(query: query);
  String resultsCount(int n) =>
      n == 1 ? _t.resultsCountOne : _t.resultsCountOther(n: n);

  // ---- saved ----
  String get noSavedTitle => _t.noSavedTitle;
  String get noSavedBody => _t.noSavedBody;

  // ---- tasbih ----
  String get resetCount => _t.resetCount;
  String get tapToCount => _t.tapToCount;
  String setsCompleted(int n) =>
      n == 1 ? _t.setsCompletedOne : _t.setsCompletedOther(n: n);
  String ofTarget(int n) => _t.ofTarget(n: n);

  // ---- read & count ----
  String get resetProgress => _t.resetProgress;
  String get setComplete => _t.setComplete;
  String get tapEachDua => _t.tapEachDua;

  // ---- dua card ----
  String get duaCopied => _t.duaCopied;
  String get removeBookmark => _t.removeBookmark;
  String get bookmark => _t.bookmark;
  String get copy => _t.copy;
  String get done => _t.done;

  // ---- settings ----
  String get settings => _t.settings;
  String get secPrayerTimes => _t.secPrayerTimes;
  String get secReminders => _t.secReminders;
  String get secDisplay => _t.secDisplay;
  String get secLanguage => _t.secLanguage;
  String get secAbout => _t.secAbout;

  String get location => _t.location;
  String get locYourLocationGps => _t.locYourLocationGps;
  String locDeviceGps(String label) => _t.locDeviceGps(label: label);
  String locFixedCity(String label) => _t.locFixedCity(label: label);

  String get calcMethod => _t.calcMethod;
  String get asrCalc => _t.asrCalc;

  String get prayerReminders => _t.prayerReminders;
  String get prayerRemindersSub => _t.prayerRemindersSub;

  // ---- daily remembrance bundle ----
  String get notifications => _t.notifications;
  String get dailyRemembrance => _t.dailyRemembrance;
  String get dailyRemembranceSub => _t.dailyRemembranceSub;

  // ---- adhan sound ----
  String get adhanSound => _t.adhanSound;
  String get adhanSoundSub => _t.adhanSoundSub;
  String get adhanNeedsReminders => _t.adhanNeedsReminders;
  String get adhanVolume => _t.adhanVolume;
  String streamLabel(int index) => _t.streamLabels[index];
  String streamHint(int index) => _t.streamHints[index];
  String get previewAdhan => _t.previewAdhan;
  String get stopAdhan => _t.stopAdhan;
  String get adhanPlaying => _t.adhanPlaying;
  String get notifBlocked => _t.notifBlocked;

  String get textSize => _t.textSize;
  List<String> get fontScaleLabels => _t.fontScaleLabels;
  String get showTransliteration => _t.showTransliteration;
  String get showTransliterationSub => _t.showTransliterationSub;
  String get showTranslation => _t.showTranslation;
  String get showTranslationSub => _t.showTranslationSub;

  String get aboutBody => _t.aboutBody;

  String get languageEnglish => 'English';
  String get languageArabic => 'العربية';
  String get languageIndonesian => 'Bahasa Indonesia';
  String get currentLanguage {
    switch (lang) {
      case AppLang.ar:
        return languageArabic;
      case AppLang.id:
        return languageIndonesian;
      case AppLang.en:
        return languageEnglish;
    }
  }

  // ---- location picker ----
  String get automatic => _t.automatic;
  String get useDeviceLocation => _t.useDeviceLocation;
  String get gpsActive => _t.gpsActive;
  String get gpsDetect => _t.gpsDetect;
  String get chooseCity => _t.chooseCity;
  String get cityNote => _t.cityNote;

  // ---- madhab ----
  String get madhabStandard => _t.madhabStandard;
  String get madhabHanafi => _t.madhabHanafi;
  String madhabLabel(Madhab m) =>
      m == Madhab.hanafi ? madhabHanafi : madhabStandard;
  String get asrHintStandard => _t.asrHintStandard;
  String get asrHintHanafi => _t.asrHintHanafi;
  String madhabHint(Madhab m) =>
      m == Madhab.hanafi ? asrHintHanafi : asrHintStandard;

  // ---- prayer names ----
  String prayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return _t.prayerFajr;
      case Prayer.sunrise:
        return _t.prayerSunrise;
      case Prayer.dhuhr:
        return _t.prayerDhuhr;
      case Prayer.asr:
        return _t.prayerAsr;
      case Prayer.maghrib:
        return _t.prayerMaghrib;
      case Prayer.isha:
        return _t.prayerIsha;
      case Prayer.none:
        return _t.prayerNone;
    }
  }

  // ---- notifications ----
  String notifTitle(Prayer prayer) =>
      _t.notifTitle(name: prayerName(prayer));
  String notifBody(Prayer prayer, String place) =>
      _t.notifBody(name: prayerName(prayer), place: place);
  String get testNotifTitle => _t.testNotifTitle;
  String get testNotifBody => _t.testNotifBody;
  String get sendTestNotif => _t.sendTestNotif;
  String get testSent => _t.testSent;
  String get testBlocked => _t.testBlocked;
  String get batteryHint => _t.batteryHint;

  // ---- daily-remembrance reminder notifications ----
  String get adhkarMorningTitle => _t.adhkarMorningTitle;
  String get adhkarMorningBody => _t.adhkarMorningBody;
  String get adhkarEveningTitle => _t.adhkarEveningTitle;
  String get adhkarEveningBody => _t.adhkarEveningBody;
  String get kahfTitle => _t.kahfTitle;
  String get kahfBody => _t.kahfBody;
  String get salawatTitle => _t.salawatTitle;
  String get salawatBody => _t.salawatBody;
  String get salawatFridayTitle => _t.salawatFridayTitle;
  String get salawatFridayBody => _t.salawatFridayBody;
  String get mulkTitle => _t.mulkTitle;
  String get mulkBody => _t.mulkBody;

  // ---- prayer & qibla page ----
  String get prayerQiblaTitle => _t.prayerQiblaTitle;
  String get weeklySchedule => _t.weeklySchedule;

  // ---- qibla ----
  String get qiblaTitle => navQibla;
  String qiblaFromNorth(String degrees) =>
      _t.qiblaFromNorth(degrees: degrees);
  String get facingQibla => _t.facingQibla;
  String turnRight(String degrees) => _t.turnRight(degrees: degrees);
  String turnLeft(String degrees) => _t.turnLeft(degrees: degrees);
  String get calibrateHint => _t.calibrateHint;
  String get compassUnavailable => _t.compassUnavailable;
  String get compassUnavailableBody => _t.compassUnavailableBody;
  String get qiblaNoLocation => _t.qiblaNoLocation;
  String get qiblaNoLocationBody => _t.qiblaNoLocationBody;

  /// Translates the built-in GPS/fallback location sentinels; city names
  /// (proper nouns) are returned unchanged.
  String place(String label) {
    switch (label) {
      case 'Your location':
        return _t.placeYourLocation;
      case 'Selected city':
        return _t.placeSelectedCity;
      case 'Makkah':
        return _t.placeMakkah;
    }
    return label;
  }

  // ---- onboarding (first-run tour) ----
  String get onboardSkip => _t.onboardSkip;
  String get onboardNext => _t.onboardNext;
  String get onboardGetStarted => _t.onboardGetStarted;
  String get onboardWelcomeTitle => _t.onboardWelcomeTitle;
  String get onboardWelcomeBody => _t.onboardWelcomeBody;
  String get onboardAdhkarTitle => _t.onboardAdhkarTitle;
  String get onboardAdhkarBody => _t.onboardAdhkarBody;
  String get onboardQuranTitle => _t.onboardQuranTitle;
  String get onboardQuranBody => _t.onboardQuranBody;
  String get onboardPrayerTitle => _t.onboardPrayerTitle;
  String get onboardPrayerBody => _t.onboardPrayerBody;
  String get onboardPermsTitle => _t.onboardPermsTitle;
  String get onboardPermsBody => _t.onboardPermsBody;
  String get onboardLocationTitle => _t.onboardLocationTitle;
  String get onboardLocationBody => _t.onboardLocationBody;
  String get onboardLocationAction => _t.onboardLocationAction;
  String get onboardNotifTitle => _t.onboardNotifTitle;
  String get onboardNotifBody => _t.onboardNotifBody;
  String get onboardNotifAction => _t.onboardNotifAction;
  String get onboardGranted => _t.onboardGranted;

  // ---- appearance (theme & colours) ----
  String get secAppearance => _t.secAppearance;
  String get appearanceColors => _t.appearanceColors;
  String get appearanceTheme => _t.appearanceTheme;
  String get themeLight => _t.themeLight;
  String get themeDark => _t.themeDark;
  String get themeSystem => _t.themeSystem;

  /// Localized display name for the palette with [id].
  String paletteName(String id) {
    switch (id) {
      case 'sapphire':
        return _t.paletteSapphire;
      case 'amethyst':
        return _t.paletteAmethyst;
      case 'rosewood':
        return _t.paletteRosewood;
      case 'lagoon':
        return _t.paletteLagoon;
      case 'desert':
        return _t.paletteDesert;
      default:
        return _t.paletteEmerald;
    }
  }

  // ---- reading & fonts ----
  String get arabicFont => _t.arabicFont;
  String get readingTheme => _t.readingTheme;
  String get readingSystem => _t.readingSystem;
  String get readingSepia => _t.readingSepia;
  String get readingNight => _t.readingNight;
  String get patterns => _t.patterns;
  String get patternsSub => _t.patternsSub;

  // ---- clock & date ----
  String ampm(int hour24) => _t.ampm[hour24 >= 12 ? 1 : 0];

  String dateLabel(DateTime t) => _t.dateFormat(
        weekday: _t.weekdaysShort[t.weekday - 1],
        day: t.day,
        month: _t.monthsShort[t.month - 1],
      );

  // ---- hijri (Islamic) date ----

  /// Localized Hijri month names (Umm al-Qura), index 0 = Muharram.
  List<String> get hijriMonths => _t.hijriMonths;

  /// The era suffix shown after the Hijri year ("AH" / "هـ" / "H").
  String get hijriSuffix => _t.hijriSuffix;

  /// The Hijri date for [date], e.g. "12 Ramadan 1447 AH" (Umm al-Qura).
  String hijriDate(DateTime date) {
    final h = HijriCalendar.fromDate(date);
    final month = _t.hijriMonths[(h.hMonth - 1).clamp(0, 11)];
    return _t.hijriDateFormat(day: h.hDay, month: month, year: h.hYear);
  }
}
