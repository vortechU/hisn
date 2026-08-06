///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations

	/// en: 'Adhkar'
	String get navAdhkar => 'Adhkar';

	/// en: 'Quran'
	String get navQuran => 'Quran';

	/// en: 'Tasbih'
	String get navTasbih => 'Tasbih';

	/// en: 'Qibla'
	String get navQibla => 'Qibla';

	/// en: 'Saved'
	String get navSaved => 'Saved';

	/// en: 'Settings'
	String get navSettings => 'Settings';

	/// en: 'Prayer'
	String get navPrayer => 'Prayer';

	/// en: 'Prayer & Qibla'
	String get prayerQiblaTitle => 'Prayer & Qibla';

	/// en: 'Weekly schedule'
	String get weeklySchedule => 'Weekly schedule';

	/// en: 'Search duas…'
	String get searchDuas => 'Search duas…';

	/// en: 'ALL ADHKAR'
	String get allAdhkar => 'ALL ADHKAR';

	/// en: 'DAILY ADHKAR'
	String get groupDaily => 'DAILY ADHKAR';

	/// en: 'FOR EVERY SITUATION'
	String get groupSituational => 'FOR EVERY SITUATION';

	/// en: 'MINE'
	String get groupMine => 'MINE';

	/// en: 'Muhassan'
	String get muhassanHeading => 'Muhassan';

	/// en: 'You're $percent% fortified today'
	String muhassanToday({required Object percent}) => 'You\'re ${percent}% fortified today';

	/// en: 'Fully fortified — masha'Allah'
	String get muhassanComplete => 'Fully fortified — masha\'Allah';

	/// en: 'Morning'
	String get muhassanMorning => 'Morning';

	/// en: 'Evening'
	String get muhassanEvening => 'Evening';

	/// en: '1 day streak'
	String get streakDaysOne => '1 day streak';

	/// en: '$n day streak'
	String streakDaysOther({required Object n}) => '${n} day streak';

	/// en: 'Start your streak'
	String get streakStart => 'Start your streak';

	/// en: 'Best: $n'
	String streakBest({required Object n}) => 'Best: ${n}';

	/// en: 'Your streak'
	String get streakTitle => 'Your streak';

	/// en: 'day streak'
	String get streakWord => 'day streak';

	/// en: 'Current'
	String get statCurrent => 'Current';

	/// en: 'Best'
	String get statBest => 'Best';

	/// en: 'Total days'
	String get statTotal => 'Total days';

	/// en: '1 day'
	String get daysValueOne => '1 day';

	/// en: '$n days'
	String daysValueOther({required Object n}) => '${n} days';

	/// en: 'You're on fire — keep it up!'
	String get streakOnFire => 'You\'re on fire — keep it up!';

	/// en: 'Finish today's adhkar to extend your streak'
	String get streakTodayPending => 'Finish today\'s adhkar to extend your streak';

	/// en: 'Complete morning & evening adhkar to begin again'
	String get streakBroken => 'Complete morning & evening adhkar to begin again';

	/// en: 'Last 4 weeks'
	String get last4Weeks => 'Last 4 weeks';

	/// en: 'Today'
	String get todayLabel => 'Today';

	/// en: 'Fortified'
	String get fortifiedLegend => 'Fortified';

	List<String> get weekdayLetters => [
		'M',
		'T',
		'W',
		'T',
		'F',
		'S',
		'S',
	];

	/// en: 'Quran'
	String get quranTitle => 'Quran';

	/// en: 'Search surahs…'
	String get searchSurah => 'Search surahs…';

	/// en: 'Continue reading'
	String get continueReading => 'Continue reading';

	/// en: 'Surah'
	String get surahWord => 'Surah';

	/// en: 'Meccan'
	String get revelationMeccan => 'Meccan';

	/// en: 'Medinan'
	String get revelationMedinan => 'Medinan';

	/// en: '1 verse'
	String get versesCountOne => '1 verse';

	/// en: '$n verses'
	String versesCountOther({required Object n}) => '${n} verses';

	/// en: 'Juz $n'
	String juzLabel({required Object n}) => 'Juz ${n}';

	/// en: 'Bookmarks'
	String get quranBookmarks => 'Bookmarks';

	/// en: 'No bookmarks yet'
	String get noBookmarks => 'No bookmarks yet';

	/// en: 'Bookmarked'
	String get bookmarkAdded => 'Bookmarked';

	/// en: 'Bookmark removed'
	String get bookmarkRemoved => 'Bookmark removed';

	/// en: 'Go to verse'
	String get goToAyah => 'Go to verse';

	/// en: 'Surah'
	String get chooseSurah => 'Surah';

	/// en: 'Verse number'
	String get verseNumber => 'Verse number';

	/// en: '1–$n'
	String verseRange({required Object n}) => '1–${n}';

	/// en: 'Go'
	String get goAction => 'Go';

	/// en: 'My Duas'
	String get myDuas => 'My Duas';

	/// en: 'Duas you add yourself'
	String get myDuasSub => 'Duas you add yourself';

	/// en: 'Add dua'
	String get addDua => 'Add dua';

	/// en: 'New dua'
	String get newDua => 'New dua';

	/// en: 'Arabic text'
	String get fieldArabic => 'Arabic text';

	/// en: 'Please enter the Arabic text'
	String get fieldArabicRequired => 'Please enter the Arabic text';

	/// en: 'Title (optional)'
	String get fieldTitle => 'Title (optional)';

	/// en: 'Transliteration (optional)'
	String get fieldTransliteration => 'Transliteration (optional)';

	/// en: 'Translation / meaning (optional)'
	String get fieldTranslation => 'Translation / meaning (optional)';

	/// en: 'Source (optional)'
	String get fieldReference => 'Source (optional)';

	/// en: 'Repetitions'
	String get fieldRepeat => 'Repetitions';

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Delete'
	String get delete => 'Delete';

	/// en: 'Delete dua'
	String get deleteDua => 'Delete dua';

	/// en: 'Remove this dua from My Duas?'
	String get deleteDuaConfirm => 'Remove this dua from My Duas?';

	/// en: 'Dua saved'
	String get duaSaved => 'Dua saved';

	/// en: 'Dua updated'
	String get duaUpdated => 'Dua updated';

	/// en: 'Edit dua'
	String get editDua => 'Edit dua';

	/// en: 'Edit'
	String get edit => 'Edit';

	/// en: 'No duas yet'
	String get noCustomTitle => 'No duas yet';

	/// en: 'Tap + to add your own dua and keep it here.'
	String get noCustomBody => 'Tap + to add your own dua and keep it here.';

	/// en: 'RECOMMENDED NOW'
	String get recommendedNow => 'RECOMMENDED NOW';

	/// en: 'Read now · 1 dua'
	String get readNowOne => 'Read now · 1 dua';

	/// en: 'Read now · $count duas'
	String readNowOther({required Object count}) => 'Read now · ${count} duas';

	/// en: '1 dua'
	String get duaCountOne => '1 dua';

	/// en: '$count duas'
	String duaCountOther({required Object count}) => '${count} duas';

	/// en: 'NOW'
	String get now => 'NOW';

	/// en: 'NEXT'
	String get next => 'NEXT';

	/// en: 'remaining'
	String get remaining => 'remaining';

	/// en: 'now'
	String get countdownNow => 'now';

	/// en: 'Today's prayers · $location'
	String todaysPrayers({required Object location}) => 'Today\'s prayers · ${location}';

	/// en: 'Search duas, meanings, sources…'
	String get searchHint => 'Search duas, meanings, sources…';

	/// en: 'Clear'
	String get clear => 'Clear';

	/// en: 'Search by title, meaning, transliteration, or source.'
	String get searchPrompt => 'Search by title, meaning, transliteration, or source.';

	/// en: 'No duas found for “$query”.'
	String noResults({required Object query}) => 'No duas found for “${query}”.';

	/// en: '1 result'
	String get resultsCountOne => '1 result';

	/// en: '$n results'
	String resultsCountOther({required Object n}) => '${n} results';

	/// en: 'No saved duas yet'
	String get noSavedTitle => 'No saved duas yet';

	/// en: 'Tap the bookmark on any dua to keep it here for quick access.'
	String get noSavedBody => 'Tap the bookmark on any dua to keep it here for quick access.';

	/// en: 'Reset count'
	String get resetCount => 'Reset count';

	/// en: 'Tap anywhere to count'
	String get tapToCount => 'Tap anywhere to count';

	/// en: '1 set completed'
	String get setsCompletedOne => '1 set completed';

	/// en: '$n sets completed'
	String setsCompletedOther({required Object n}) => '${n} sets completed';

	/// en: 'of $n'
	String ofTarget({required Object n}) => 'of ${n}';

	/// en: 'Reset progress'
	String get resetProgress => 'Reset progress';

	/// en: 'Set complete — taqabbal Allah'
	String get setComplete => 'Set complete — taqabbal Allah';

	/// en: 'Tap each dua to count its repetitions'
	String get tapEachDua => 'Tap each dua to count its repetitions';

	/// en: 'Dua copied'
	String get duaCopied => 'Dua copied';

	/// en: 'Remove bookmark'
	String get removeBookmark => 'Remove bookmark';

	/// en: 'Bookmark'
	String get bookmark => 'Bookmark';

	/// en: 'Copy'
	String get copy => 'Copy';

	/// en: 'Done'
	String get done => 'Done';

	/// en: 'Settings'
	String get settings => 'Settings';

	/// en: 'Prayer times'
	String get secPrayerTimes => 'Prayer times';

	/// en: 'Reminders'
	String get secReminders => 'Reminders';

	/// en: 'Display'
	String get secDisplay => 'Display';

	/// en: 'Language'
	String get secLanguage => 'Language';

	/// en: 'About'
	String get secAbout => 'About';

	/// en: 'Location'
	String get location => 'Location';

	/// en: 'Your location (GPS)'
	String get locYourLocationGps => 'Your location (GPS)';

	/// en: 'Device GPS · $label'
	String locDeviceGps({required Object label}) => 'Device GPS · ${label}';

	/// en: '$label (fixed city)'
	String locFixedCity({required Object label}) => '${label} (fixed city)';

	/// en: 'Calculation method'
	String get calcMethod => 'Calculation method';

	/// en: 'Asr calculation'
	String get asrCalc => 'Asr calculation';

	/// en: 'Notifications'
	String get notifications => 'Notifications';

	/// en: 'Prayer reminders'
	String get prayerReminders => 'Prayer reminders';

	/// en: 'Get notified at each prayer time'
	String get prayerRemindersSub => 'Get notified at each prayer time';

	/// en: 'Daily remembrance'
	String get dailyRemembrance => 'Daily remembrance';

	/// en: 'Morning & evening adhkar (repeating until done), plus Friday & nightly sunnahs'
	String get dailyRemembranceSub => 'Morning & evening adhkar (repeating until done), plus Friday & nightly sunnahs';

	/// en: 'Adhan sound'
	String get adhanSound => 'Adhan sound';

	/// en: 'Play the call to prayer at each time'
	String get adhanSoundSub => 'Play the call to prayer at each time';

	/// en: 'Turn on Prayer reminders above for the adhan to play at prayer time.'
	String get adhanNeedsReminders => 'Turn on Prayer reminders above for the adhan to play at prayer time.';

	/// en: 'Adhan volume'
	String get adhanVolume => 'Adhan volume';

	List<String> get streamLabels => [
		'Media',
		'Ringer',
		'Alarm',
	];
	List<String> get streamHints => [
		'Controlled by your media volume',
		'Controlled by your ringer volume',
		'Controlled by your alarm volume',
	];

	/// en: 'Preview adhan'
	String get previewAdhan => 'Preview adhan';

	/// en: 'Stop'
	String get stopAdhan => 'Stop';

	/// en: 'Playing adhan…'
	String get adhanPlaying => 'Playing adhan…';

	/// en: 'Notifications are blocked. Enable them for Hisn in your device settings.'
	String get notifBlocked => 'Notifications are blocked. Enable them for Hisn in your device settings.';

	/// en: 'Text size'
	String get textSize => 'Text size';

	List<String> get fontScaleLabels => [
		'Small',
		'Default',
		'Large',
		'X-Large',
	];

	/// en: 'Show transliteration'
	String get showTransliteration => 'Show transliteration';

	/// en: 'The Latin-letter pronunciation line'
	String get showTransliterationSub => 'The Latin-letter pronunciation line';

	/// en: 'Show translation'
	String get showTranslation => 'Show translation';

	/// en: 'The English meaning'
	String get showTranslationSub => 'The English meaning';

	/// en: 'Dua & Adhkar companion · prototype Prayer times via the Adhan library.'
	String get aboutBody => 'Dua & Adhkar companion · prototype\nPrayer times via the Adhan library.';

	/// en: 'AUTOMATIC'
	String get automatic => 'AUTOMATIC';

	/// en: 'Use my device location'
	String get useDeviceLocation => 'Use my device location';

	/// en: 'Active · times match where you are'
	String get gpsActive => 'Active · times match where you are';

	/// en: 'Detect via GPS (asks for permission)'
	String get gpsDetect => 'Detect via GPS (asks for permission)';

	/// en: 'CHOOSE A CITY'
	String get chooseCity => 'CHOOSE A CITY';

	/// en: 'A chosen city's times are shown in your device's current timezone — accurate when the city is in your region.'
	String get cityNote => 'A chosen city\'s times are shown in your device\'s current timezone — accurate when the city is in your region.';

	/// en: 'Standard (Shafi, Maliki, Hanbali)'
	String get madhabStandard => 'Standard (Shafi, Maliki, Hanbali)';

	/// en: 'Hanafi'
	String get madhabHanafi => 'Hanafi';

	/// en: 'Asr begins when an object's shadow equals its length'
	String get asrHintStandard => 'Asr begins when an object\'s shadow equals its length';

	/// en: 'Asr begins when an object's shadow is twice its length'
	String get asrHintHanafi => 'Asr begins when an object\'s shadow is twice its length';

	/// en: 'Fajr'
	String get prayerFajr => 'Fajr';

	/// en: 'Sunrise'
	String get prayerSunrise => 'Sunrise';

	/// en: 'Dhuhr'
	String get prayerDhuhr => 'Dhuhr';

	/// en: 'Asr'
	String get prayerAsr => 'Asr';

	/// en: 'Maghrib'
	String get prayerMaghrib => 'Maghrib';

	/// en: 'Isha'
	String get prayerIsha => 'Isha';

	/// en: '—'
	String get prayerNone => '—';

	/// en: '$name prayer'
	String notifTitle({required Object name}) => '${name} prayer';

	/// en: 'It's time for $name prayer — $place.'
	String notifBody({required Object name, required Object place}) => 'It\'s time for ${name} prayer — ${place}.';

	/// en: '$name iqāmah — $place.'
	String notifIqamahBody({required Object name, required Object place}) => '${name} iqāmah — ${place}.';

	/// en: 'Iqāmah delay'
	String get iqamahOffset => 'Iqāmah delay';

	/// en: 'At adhan'
	String get iqamahAtAdhan => 'At adhan';

	/// en: '+$minutes min'
	String iqamahPlusMinutes({required Object minutes}) => '+${minutes} min';

	/// en: 'Test reminder'
	String get testNotifTitle => 'Test reminder';

	/// en: 'If you can read this, prayer reminders are working. 🌙'
	String get testNotifBody => 'If you can read this, prayer reminders are working. 🌙';

	/// en: 'Send a test notification'
	String get sendTestNotif => 'Send a test notification';

	/// en: 'Test sent — you should see one now, and another in 12s (lock your phone).'
	String get testSent => 'Test sent — you should see one now, and another in 12s (lock your phone).';

	/// en: 'Sent, but your phone reports notifications are OFF for Hisn. Enable them in Settings → Apps → Hisn → Notifications.'
	String get testBlocked => 'Sent, but your phone reports notifications are OFF for Hisn. Enable them in Settings → Apps → Hisn → Notifications.';

	/// en: 'Some phones (e.g. Xiaomi/MIUI, Samsung) block scheduled reminders when the app is closed. If reminders don't arrive, allow Autostart and set battery usage to "No restrictions" for Hisn.'
	String get batteryHint => 'Some phones (e.g. Xiaomi/MIUI, Samsung) block scheduled reminders when the app is closed. If reminders don\'t arrive, allow Autostart and set battery usage to "No restrictions" for Hisn.';

	/// en: 'Morning adhkar'
	String get adhkarMorningTitle => 'Morning adhkar';

	/// en: 'Begin your morning with remembrance — fortify your day.'
	String get adhkarMorningBody => 'Begin your morning with remembrance — fortify your day.';

	/// en: 'Evening adhkar'
	String get adhkarEveningTitle => 'Evening adhkar';

	/// en: 'End your day with remembrance — fortify your evening.'
	String get adhkarEveningBody => 'End your day with remembrance — fortify your evening.';

	/// en: 'Surah Al-Kahf'
	String get kahfTitle => 'Surah Al-Kahf';

	/// en: 'It's Friday — read Surah Al-Kahf for light between the two Fridays.'
	String get kahfBody => 'It\'s Friday — read Surah Al-Kahf for light between the two Fridays.';

	/// en: 'Send blessings on the Prophet ﷺ'
	String get salawatTitle => 'Send blessings on the Prophet ﷺ';

	/// en: 'Take a moment to send salawat upon the Prophet ﷺ.'
	String get salawatBody => 'Take a moment to send salawat upon the Prophet ﷺ.';

	/// en: 'Send blessings on the Prophet ﷺ'
	String get salawatFridayTitle => 'Send blessings on the Prophet ﷺ';

	/// en: 'It's Friday — increase your salawat upon the Prophet ﷺ.'
	String get salawatFridayBody => 'It\'s Friday — increase your salawat upon the Prophet ﷺ.';

	/// en: 'Surah Al-Mulk'
	String get mulkTitle => 'Surah Al-Mulk';

	/// en: 'Before you sleep — read Surah Al-Mulk.'
	String get mulkBody => 'Before you sleep — read Surah Al-Mulk.';

	/// en: 'Qibla · $degrees° from North'
	String qiblaFromNorth({required Object degrees}) => 'Qibla · ${degrees}° from North';

	/// en: 'You are facing the Qibla'
	String get facingQibla => 'You are facing the Qibla';

	/// en: 'Turn right $degrees°'
	String turnRight({required Object degrees}) => 'Turn right ${degrees}°';

	/// en: 'Turn left $degrees°'
	String turnLeft({required Object degrees}) => 'Turn left ${degrees}°';

	/// en: 'Move in a figure-8 to calibrate'
	String get calibrateHint => 'Move in a figure-8 to calibrate';

	/// en: 'Compass unavailable'
	String get compassUnavailable => 'Compass unavailable';

	/// en: 'This device has no compass sensor, or it needs calibration. Try moving it in a figure-8 motion.'
	String get compassUnavailableBody => 'This device has no compass sensor, or it needs calibration. Try moving it in a figure-8 motion.';

	/// en: 'Location needed'
	String get qiblaNoLocation => 'Location needed';

	/// en: 'The Qibla direction can't be calculated until your location is known. Turn on location services, or choose your city in Settings.'
	String get qiblaNoLocationBody => 'The Qibla direction can\'t be calculated until your location is known. Turn on location services, or choose your city in Settings.';

	/// en: 'Your location'
	String get placeYourLocation => 'Your location';

	/// en: 'Selected city'
	String get placeSelectedCity => 'Selected city';

	/// en: 'Makkah'
	String get placeMakkah => 'Makkah';

	/// en: 'Skip'
	String get onboardSkip => 'Skip';

	/// en: 'Next'
	String get onboardNext => 'Next';

	/// en: 'Get started'
	String get onboardGetStarted => 'Get started';

	/// en: 'Welcome to Hisn'
	String get onboardWelcomeTitle => 'Welcome to Hisn';

	/// en: 'Your daily companion for remembrance, Qur'an, and prayer. Here's a quick tour to get you started.'
	String get onboardWelcomeBody => 'Your daily companion for remembrance, Qur\'an, and prayer. Here\'s a quick tour to get you started.';

	/// en: 'Adhkar & Duas'
	String get onboardAdhkarTitle => 'Adhkar & Duas';

	/// en: 'Morning and evening remembrances, a tasbih counter, and your own custom duas. Tap a dua to count through its repetitions.'
	String get onboardAdhkarBody => 'Morning and evening remembrances, a tasbih counter, and your own custom duas. Tap a dua to count through its repetitions.';

	/// en: 'The Holy Qur'an'
	String get onboardQuranTitle => 'The Holy Qur\'an';

	/// en: 'Read the entire Qur'an in a beautiful mushaf, pick up where you left off, and bookmark the verses you love.'
	String get onboardQuranBody => 'Read the entire Qur\'an in a beautiful mushaf, pick up where you left off, and bookmark the verses you love.';

	/// en: 'Prayer & Qibla'
	String get onboardPrayerTitle => 'Prayer & Qibla';

	/// en: 'Accurate prayer times for your location, a countdown to the next salah, and a compass pointing to the Qibla.'
	String get onboardPrayerBody => 'Accurate prayer times for your location, a countdown to the next salah, and a compass pointing to the Qibla.';

	/// en: 'A couple of permissions'
	String get onboardPermsTitle => 'A couple of permissions';

	/// en: 'Allow these so Hisn works at its best. You can change them anytime in Settings.'
	String get onboardPermsBody => 'Allow these so Hisn works at its best. You can change them anytime in Settings.';

	/// en: 'Location'
	String get onboardLocationTitle => 'Location';

	/// en: 'To calculate accurate prayer times and the Qibla direction for where you are.'
	String get onboardLocationBody => 'To calculate accurate prayer times and the Qibla direction for where you are.';

	/// en: 'Allow location'
	String get onboardLocationAction => 'Allow location';

	/// en: 'Notifications'
	String get onboardNotifTitle => 'Notifications';

	/// en: 'A gentle reminder at each prayer time so you never miss a salah.'
	String get onboardNotifBody => 'A gentle reminder at each prayer time so you never miss a salah.';

	/// en: 'Enable reminders'
	String get onboardNotifAction => 'Enable reminders';

	/// en: 'Enabled'
	String get onboardGranted => 'Enabled';

	/// en: 'Appearance'
	String get secAppearance => 'Appearance';

	/// en: 'Color palette'
	String get appearanceColors => 'Color palette';

	/// en: 'Theme'
	String get appearanceTheme => 'Theme';

	/// en: 'Light'
	String get themeLight => 'Light';

	/// en: 'Dark'
	String get themeDark => 'Dark';

	/// en: 'System'
	String get themeSystem => 'System';

	/// en: 'Emerald & Gold'
	String get paletteEmerald => 'Emerald & Gold';

	/// en: 'Sapphire & Sky'
	String get paletteSapphire => 'Sapphire & Sky';

	/// en: 'Amethyst & Rose'
	String get paletteAmethyst => 'Amethyst & Rose';

	/// en: 'Rosewood'
	String get paletteRosewood => 'Rosewood';

	/// en: 'Lagoon'
	String get paletteLagoon => 'Lagoon';

	/// en: 'Desert'
	String get paletteDesert => 'Desert';

	/// en: 'Arabic font'
	String get arabicFont => 'Arabic font';

	/// en: 'Reading background'
	String get readingTheme => 'Reading background';

	/// en: 'Match app'
	String get readingSystem => 'Match app';

	/// en: 'Sepia'
	String get readingSepia => 'Sepia';

	/// en: 'Night'
	String get readingNight => 'Night';

	/// en: 'Geometric pattern'
	String get patterns => 'Geometric pattern';

	/// en: 'Subtle ornament on headers and counter'
	String get patternsSub => 'Subtle ornament on headers and counter';

	List<String> get ampm => [
		'AM',
		'PM',
	];
	List<String> get weekdaysShort => [
		'Mon',
		'Tue',
		'Wed',
		'Thu',
		'Fri',
		'Sat',
		'Sun',
	];
	List<String> get monthsShort => [
		'Jan',
		'Feb',
		'Mar',
		'Apr',
		'May',
		'Jun',
		'Jul',
		'Aug',
		'Sep',
		'Oct',
		'Nov',
		'Dec',
	];

	/// en: '$weekday, $day $month'
	String dateFormat({required Object weekday, required Object day, required Object month}) => '${weekday}, ${day} ${month}';

	List<String> get hijriMonths => [
		'Muharram',
		'Safar',
		'Rabi al-Awwal',
		'Rabi al-Thani',
		'Jumada al-Ula',
		'Jumada al-Akhirah',
		'Rajab',
		'Sha\'ban',
		'Ramadan',
		'Shawwal',
		'Dhul-Qa\'dah',
		'Dhul-Hijjah',
	];

	/// en: '$day $month $year AH'
	String hijriDateFormat({required Object day, required Object month, required Object year}) => '${day} ${month} ${year} AH';

	/// en: 'AH'
	String get hijriSuffix => 'AH';

	/// en: 'Backup & restore'
	String get secBackup => 'Backup & restore';

	/// en: 'Save your progress to a file'
	String get backupSub => 'Save your progress to a file';

	/// en: 'On this device'
	String get backupOnThisDevice => 'On this device';

	/// en: 'Save a backup'
	String get backupSave => 'Save a backup';

	/// en: 'Writes everything below to a file you can keep in Drive or Files, or send to yourself.'
	String get backupSaveHint => 'Writes everything below to a file you can keep in Drive or Files, or send to yourself.';

	/// en: 'Restore'
	String get backupRestoreHeading => 'Restore';

	/// en: 'Restore from a file'
	String get backupRestore => 'Restore from a file';

	/// en: 'Replaces what is on this device with the contents of a backup file.'
	String get backupRestoreHint => 'Replaces what is on this device with the contents of a backup file.';

	/// en: 'A backup is a plain text file. It stays on this device unless you send it somewhere yourself — Hisn never uploads it.'
	String get backupPrivacy => 'A backup is a plain text file. It stays on this device unless you send it somewhere yourself — Hisn never uploads it.';

	/// en: 'Current streak'
	String get backupStatStreak => 'Current streak';

	/// en: 'Best streak'
	String get backupStatBest => 'Best streak';

	/// en: 'Days fortified'
	String get backupStatDays => 'Days fortified';

	/// en: 'Saved duas'
	String get backupStatFavorites => 'Saved duas';

	/// en: 'My duas'
	String get backupStatCustom => 'My duas';

	/// en: 'Quran bookmarks'
	String get backupStatQuran => 'Quran bookmarks';

	/// en: 'Restore this backup?'
	String get restoreTitle => 'Restore this backup?';

	/// en: 'Saved $date'
	String restoreSavedOn({required Object date}) => 'Saved ${date}';

	/// en: 'Saved $date · v$version'
	String restoreSavedOnVersion({required Object date, required Object version}) => 'Saved ${date} · v${version}';

	/// en: 'Everything'
	String get restoreScopeEverything => 'Everything';

	/// en: 'Progress and settings'
	String get restoreScopeEverythingSub => 'Progress and settings';

	/// en: 'Progress only'
	String get restoreScopeProgress => 'Progress only';

	/// en: 'Keep this phone's location, reminders and language'
	String get restoreScopeProgressSub => 'Keep this phone\'s location, reminders and language';

	/// en: 'This replaces what is currently on this device.'
	String get restoreWarning => 'This replaces what is currently on this device.';

	/// en: 'Restore'
	String get restoreAction => 'Restore';

	/// en: 'Restored 1 item'
	String get restoreDoneOne => 'Restored 1 item';

	/// en: 'Restored $n items'
	String restoreDoneOther({required Object n}) => 'Restored ${n} items';

	/// en: 'Backup ready to save'
	String get backupSaved => 'Backup ready to save';

	/// en: 'Could not create the backup'
	String get backupFailed => 'Could not create the backup';

	/// en: 'That file could not be read.'
	String get restoreErrMalformed => 'That file could not be read.';

	/// en: 'That is not a Hisn backup file.'
	String get restoreErrNotABackup => 'That is not a Hisn backup file.';

	/// en: 'That backup was made by a newer version of Hisn. Update the app first.'
	String get restoreErrTooNew => 'That backup was made by a newer version of Hisn. Update the app first.';

	/// en: 'That backup has nothing to restore.'
	String get restoreErrEmpty => 'That backup has nothing to restore.';

	/// en: 'Could not restore. Nothing was changed.'
	String get restoreFailed => 'Could not restore. Nothing was changed.';

	/// en: 'Verses on this page'
	String get versesOnThisPage => 'Verses on this page';

	/// en: 'Saved verses'
	String get savedVerses => 'Saved verses';

	/// en: 'Saved pages'
	String get savedPages => 'Saved pages';

	/// en: 'Save verse'
	String get saveVerse => 'Save verse';

	/// en: 'Remove saved verse'
	String get unsaveVerse => 'Remove saved verse';

	/// en: 'Islamic calendar'
	String get secCalendar => 'Islamic calendar';

	/// en: 'Sunnah fasts and Hijri occasions'
	String get calendarSub => 'Sunnah fasts and Hijri occasions';

	/// en: 'Fasts & occasions'
	String get sunnahCalendarTitle => 'Fasts & occasions';

	/// en: 'Upcoming'
	String get upcomingLabel => 'Upcoming';

	/// en: 'Nothing marked in the next two months.'
	String get nothingUpcoming => 'Nothing marked in the next two months.';

	/// en: 'Dates are calculated (Umm al-Qura) and can differ from your local sighting by a day.'
	String get calendarNote => 'Dates are calculated (Umm al-Qura) and can differ from your local sighting by a day.';

	/// en: 'Sunnah to fast'
	String get fastingRecommended => 'Sunnah to fast';

	/// en: 'Obligatory fast'
	String get fastingObligatory => 'Obligatory fast';

	/// en: 'Not a day to fast'
	String get fastingForbidden => 'Not a day to fast';

	/// en: 'No particular fast today.'
	String get fastingNoneToday => 'No particular fast today.';

	/// en: 'Ramadan'
	String get fastRamadan => 'Ramadan';

	/// en: 'Monday fast'
	String get fastMonday => 'Monday fast';

	/// en: 'Thursday fast'
	String get fastThursday => 'Thursday fast';

	/// en: 'The white days'
	String get fastWhiteDay => 'The white days';

	/// en: 'Tasu'a'
	String get fastTasua => 'Tasu\'a';

	/// en: 'Ashura'
	String get fastAshura => 'Ashura';

	/// en: 'The ten of Dhul Hijjah'
	String get fastDhulHijjah => 'The ten of Dhul Hijjah';

	/// en: 'The Day of Arafah'
	String get fastArafah => 'The Day of Arafah';

	/// en: 'Six of Shawwal'
	String get fastSixOfShawwal => 'Six of Shawwal';

	/// en: 'The obligatory fast of the month.'
	String get fastRamadanSub => 'The obligatory fast of the month.';

	/// en: 'Deeds are presented on Mondays and Thursdays. — Tirmidhi'
	String get fastMondaySub => 'Deeds are presented on Mondays and Thursdays. — Tirmidhi';

	/// en: 'Deeds are presented on Mondays and Thursdays. — Tirmidhi'
	String get fastThursdaySub => 'Deeds are presented on Mondays and Thursdays. — Tirmidhi';

	/// en: 'The 13th, 14th and 15th of every Hijri month. — Bukhari & Muslim'
	String get fastWhiteDaySub => 'The 13th, 14th and 15th of every Hijri month. — Bukhari & Muslim';

	/// en: 'Fasted along with the tenth. — Muslim'
	String get fastTasuaSub => 'Fasted along with the tenth. — Muslim';

	/// en: 'It expiates the year before it. — Muslim'
	String get fastAshuraSub => 'It expiates the year before it. — Muslim';

	/// en: 'No days are more beloved to Allah for righteous deeds than these. — Bukhari'
	String get fastDhulHijjahSub => 'No days are more beloved to Allah for righteous deeds than these. — Bukhari';

	/// en: 'It expiates the year before and the year after — for those not on Hajj. — Muslim'
	String get fastArafahSub => 'It expiates the year before and the year after — for those not on Hajj. — Muslim';

	/// en: 'Whoever fasts Ramadan and follows it with six of Shawwal, it is as fasting the whole year. — Muslim'
	String get fastSixOfShawwalSub => 'Whoever fasts Ramadan and follows it with six of Shawwal, it is as fasting the whole year. — Muslim';

	/// en: 'Islamic New Year'
	String get eventNewYear => 'Islamic New Year';

	/// en: 'Ashura'
	String get eventAshura => 'Ashura';

	/// en: 'Ramadan begins'
	String get eventRamadan => 'Ramadan begins';

	/// en: 'The last ten nights'
	String get eventLastTen => 'The last ten nights';

	/// en: 'Eid al-Fitr'
	String get eventEidFitr => 'Eid al-Fitr';

	/// en: 'Dhul Hijjah begins'
	String get eventDhulHijjah => 'Dhul Hijjah begins';

	/// en: 'The Day of Arafah'
	String get eventArafah => 'The Day of Arafah';

	/// en: 'Eid al-Adha'
	String get eventEidAdha => 'Eid al-Adha';

	/// en: 'Laylat al-Qadr is sought in the odd nights of these ten.'
	String get eventLastTenSub => 'Laylat al-Qadr is sought in the odd nights of these ten.';

	/// en: 'Fasting is not allowed on Eid al-Fitr.'
	String get barEidAlFitr => 'Fasting is not allowed on Eid al-Fitr.';

	/// en: 'Fasting is not allowed on Eid al-Adha.'
	String get barEidAlAdha => 'Fasting is not allowed on Eid al-Adha.';

	/// en: 'Fasting is not allowed on the days of Tashriq.'
	String get barTashriq => 'Fasting is not allowed on the days of Tashriq.';

	/// en: 'Hijri date adjustment'
	String get hijriAdjust => 'Hijri date adjustment';

	/// en: 'The calculated date can run a day ahead of or behind your local sighting. Adjust it to match your community.'
	String get hijriAdjustHint => 'The calculated date can run a day ahead of or behind your local sighting. Adjust it to match your community.';

	List<String> get hijriOffsetLabels => [
		'−2 days',
		'−1 day',
		'No adjustment',
		'+1 day',
		'+2 days',
	];

	/// en: 'Fasting reminders'
	String get fastingReminders => 'Fasting reminders';

	/// en: 'A reminder the evening before a sunnah fast'
	String get fastingRemindersSub => 'A reminder the evening before a sunnah fast';

	/// en: 'Fasting tomorrow'
	String get notifFastTitle => 'Fasting tomorrow';

	/// en: 'Tomorrow is $name — a fast from the Sunnah.'
	String notifFastBody({required Object name}) => 'Tomorrow is ${name} — a fast from the Sunnah.';

	/// en: 'Tomorrow, in sha' Allah.'
	String get notifOccasionBody => 'Tomorrow, in sha\' Allah.';

	/// en: 'Share'
	String get share => 'Share';

	/// en: 'Share card'
	String get shareAsImage => 'Share card';

	/// en: 'Share text'
	String get shareAsText => 'Share text';

	/// en: 'The card wasn't ready to capture — sharing the text instead.'
	String get shareImageFailedNotReady => 'The card wasn\'t ready to capture — sharing the text instead.';

	/// en: 'This device couldn't make an image — sharing the text instead.'
	String get shareImageFailedUnsupported => 'This device couldn\'t make an image — sharing the text instead.';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'navAdhkar' => 'Adhkar',
			'navQuran' => 'Quran',
			'navTasbih' => 'Tasbih',
			'navQibla' => 'Qibla',
			'navSaved' => 'Saved',
			'navSettings' => 'Settings',
			'navPrayer' => 'Prayer',
			'prayerQiblaTitle' => 'Prayer & Qibla',
			'weeklySchedule' => 'Weekly schedule',
			'searchDuas' => 'Search duas…',
			'allAdhkar' => 'ALL ADHKAR',
			'groupDaily' => 'DAILY ADHKAR',
			'groupSituational' => 'FOR EVERY SITUATION',
			'groupMine' => 'MINE',
			'muhassanHeading' => 'Muhassan',
			'muhassanToday' => ({required Object percent}) => 'You\'re ${percent}% fortified today',
			'muhassanComplete' => 'Fully fortified — masha\'Allah',
			'muhassanMorning' => 'Morning',
			'muhassanEvening' => 'Evening',
			'streakDaysOne' => '1 day streak',
			'streakDaysOther' => ({required Object n}) => '${n} day streak',
			'streakStart' => 'Start your streak',
			'streakBest' => ({required Object n}) => 'Best: ${n}',
			'streakTitle' => 'Your streak',
			'streakWord' => 'day streak',
			'statCurrent' => 'Current',
			'statBest' => 'Best',
			'statTotal' => 'Total days',
			'daysValueOne' => '1 day',
			'daysValueOther' => ({required Object n}) => '${n} days',
			'streakOnFire' => 'You\'re on fire — keep it up!',
			'streakTodayPending' => 'Finish today\'s adhkar to extend your streak',
			'streakBroken' => 'Complete morning & evening adhkar to begin again',
			'last4Weeks' => 'Last 4 weeks',
			'todayLabel' => 'Today',
			'fortifiedLegend' => 'Fortified',
			'weekdayLetters.0' => 'M',
			'weekdayLetters.1' => 'T',
			'weekdayLetters.2' => 'W',
			'weekdayLetters.3' => 'T',
			'weekdayLetters.4' => 'F',
			'weekdayLetters.5' => 'S',
			'weekdayLetters.6' => 'S',
			'quranTitle' => 'Quran',
			'searchSurah' => 'Search surahs…',
			'continueReading' => 'Continue reading',
			'surahWord' => 'Surah',
			'revelationMeccan' => 'Meccan',
			'revelationMedinan' => 'Medinan',
			'versesCountOne' => '1 verse',
			'versesCountOther' => ({required Object n}) => '${n} verses',
			'juzLabel' => ({required Object n}) => 'Juz ${n}',
			'quranBookmarks' => 'Bookmarks',
			'noBookmarks' => 'No bookmarks yet',
			'bookmarkAdded' => 'Bookmarked',
			'bookmarkRemoved' => 'Bookmark removed',
			'goToAyah' => 'Go to verse',
			'chooseSurah' => 'Surah',
			'verseNumber' => 'Verse number',
			'verseRange' => ({required Object n}) => '1–${n}',
			'goAction' => 'Go',
			'myDuas' => 'My Duas',
			'myDuasSub' => 'Duas you add yourself',
			'addDua' => 'Add dua',
			'newDua' => 'New dua',
			'fieldArabic' => 'Arabic text',
			'fieldArabicRequired' => 'Please enter the Arabic text',
			'fieldTitle' => 'Title (optional)',
			'fieldTransliteration' => 'Transliteration (optional)',
			'fieldTranslation' => 'Translation / meaning (optional)',
			'fieldReference' => 'Source (optional)',
			'fieldRepeat' => 'Repetitions',
			'save' => 'Save',
			'cancel' => 'Cancel',
			'delete' => 'Delete',
			'deleteDua' => 'Delete dua',
			'deleteDuaConfirm' => 'Remove this dua from My Duas?',
			'duaSaved' => 'Dua saved',
			'duaUpdated' => 'Dua updated',
			'editDua' => 'Edit dua',
			'edit' => 'Edit',
			'noCustomTitle' => 'No duas yet',
			'noCustomBody' => 'Tap + to add your own dua and keep it here.',
			'recommendedNow' => 'RECOMMENDED NOW',
			'readNowOne' => 'Read now · 1 dua',
			'readNowOther' => ({required Object count}) => 'Read now · ${count} duas',
			'duaCountOne' => '1 dua',
			'duaCountOther' => ({required Object count}) => '${count} duas',
			'now' => 'NOW',
			'next' => 'NEXT',
			'remaining' => 'remaining',
			'countdownNow' => 'now',
			'todaysPrayers' => ({required Object location}) => 'Today\'s prayers · ${location}',
			'searchHint' => 'Search duas, meanings, sources…',
			'clear' => 'Clear',
			'searchPrompt' => 'Search by title, meaning, transliteration, or source.',
			'noResults' => ({required Object query}) => 'No duas found for “${query}”.',
			'resultsCountOne' => '1 result',
			'resultsCountOther' => ({required Object n}) => '${n} results',
			'noSavedTitle' => 'No saved duas yet',
			'noSavedBody' => 'Tap the bookmark on any dua to keep it here for quick access.',
			'resetCount' => 'Reset count',
			'tapToCount' => 'Tap anywhere to count',
			'setsCompletedOne' => '1 set completed',
			'setsCompletedOther' => ({required Object n}) => '${n} sets completed',
			'ofTarget' => ({required Object n}) => 'of ${n}',
			'resetProgress' => 'Reset progress',
			'setComplete' => 'Set complete — taqabbal Allah',
			'tapEachDua' => 'Tap each dua to count its repetitions',
			'duaCopied' => 'Dua copied',
			'removeBookmark' => 'Remove bookmark',
			'bookmark' => 'Bookmark',
			'copy' => 'Copy',
			'done' => 'Done',
			'settings' => 'Settings',
			'secPrayerTimes' => 'Prayer times',
			'secReminders' => 'Reminders',
			'secDisplay' => 'Display',
			'secLanguage' => 'Language',
			'secAbout' => 'About',
			'location' => 'Location',
			'locYourLocationGps' => 'Your location (GPS)',
			'locDeviceGps' => ({required Object label}) => 'Device GPS · ${label}',
			'locFixedCity' => ({required Object label}) => '${label} (fixed city)',
			'calcMethod' => 'Calculation method',
			'asrCalc' => 'Asr calculation',
			'notifications' => 'Notifications',
			'prayerReminders' => 'Prayer reminders',
			'prayerRemindersSub' => 'Get notified at each prayer time',
			'dailyRemembrance' => 'Daily remembrance',
			'dailyRemembranceSub' => 'Morning & evening adhkar (repeating until done), plus Friday & nightly sunnahs',
			'adhanSound' => 'Adhan sound',
			'adhanSoundSub' => 'Play the call to prayer at each time',
			'adhanNeedsReminders' => 'Turn on Prayer reminders above for the adhan to play at prayer time.',
			'adhanVolume' => 'Adhan volume',
			'streamLabels.0' => 'Media',
			'streamLabels.1' => 'Ringer',
			'streamLabels.2' => 'Alarm',
			'streamHints.0' => 'Controlled by your media volume',
			'streamHints.1' => 'Controlled by your ringer volume',
			'streamHints.2' => 'Controlled by your alarm volume',
			'previewAdhan' => 'Preview adhan',
			'stopAdhan' => 'Stop',
			'adhanPlaying' => 'Playing adhan…',
			'notifBlocked' => 'Notifications are blocked. Enable them for Hisn in your device settings.',
			'textSize' => 'Text size',
			'fontScaleLabels.0' => 'Small',
			'fontScaleLabels.1' => 'Default',
			'fontScaleLabels.2' => 'Large',
			'fontScaleLabels.3' => 'X-Large',
			'showTransliteration' => 'Show transliteration',
			'showTransliterationSub' => 'The Latin-letter pronunciation line',
			'showTranslation' => 'Show translation',
			'showTranslationSub' => 'The English meaning',
			'aboutBody' => 'Dua & Adhkar companion · prototype\nPrayer times via the Adhan library.',
			'automatic' => 'AUTOMATIC',
			'useDeviceLocation' => 'Use my device location',
			'gpsActive' => 'Active · times match where you are',
			'gpsDetect' => 'Detect via GPS (asks for permission)',
			'chooseCity' => 'CHOOSE A CITY',
			'cityNote' => 'A chosen city\'s times are shown in your device\'s current timezone — accurate when the city is in your region.',
			'madhabStandard' => 'Standard (Shafi, Maliki, Hanbali)',
			'madhabHanafi' => 'Hanafi',
			'asrHintStandard' => 'Asr begins when an object\'s shadow equals its length',
			'asrHintHanafi' => 'Asr begins when an object\'s shadow is twice its length',
			'prayerFajr' => 'Fajr',
			'prayerSunrise' => 'Sunrise',
			'prayerDhuhr' => 'Dhuhr',
			'prayerAsr' => 'Asr',
			'prayerMaghrib' => 'Maghrib',
			'prayerIsha' => 'Isha',
			'prayerNone' => '—',
			'notifTitle' => ({required Object name}) => '${name} prayer',
			'notifBody' => ({required Object name, required Object place}) => 'It\'s time for ${name} prayer — ${place}.',
			'notifIqamahBody' => ({required Object name, required Object place}) => '${name} iqāmah — ${place}.',
			'iqamahOffset' => 'Iqāmah delay',
			'iqamahAtAdhan' => 'At adhan',
			'iqamahPlusMinutes' => ({required Object minutes}) => '+${minutes} min',
			'testNotifTitle' => 'Test reminder',
			'testNotifBody' => 'If you can read this, prayer reminders are working. 🌙',
			'sendTestNotif' => 'Send a test notification',
			'testSent' => 'Test sent — you should see one now, and another in 12s (lock your phone).',
			'testBlocked' => 'Sent, but your phone reports notifications are OFF for Hisn. Enable them in Settings → Apps → Hisn → Notifications.',
			'batteryHint' => 'Some phones (e.g. Xiaomi/MIUI, Samsung) block scheduled reminders when the app is closed. If reminders don\'t arrive, allow Autostart and set battery usage to "No restrictions" for Hisn.',
			'adhkarMorningTitle' => 'Morning adhkar',
			'adhkarMorningBody' => 'Begin your morning with remembrance — fortify your day.',
			'adhkarEveningTitle' => 'Evening adhkar',
			'adhkarEveningBody' => 'End your day with remembrance — fortify your evening.',
			'kahfTitle' => 'Surah Al-Kahf',
			'kahfBody' => 'It\'s Friday — read Surah Al-Kahf for light between the two Fridays.',
			'salawatTitle' => 'Send blessings on the Prophet ﷺ',
			'salawatBody' => 'Take a moment to send salawat upon the Prophet ﷺ.',
			'salawatFridayTitle' => 'Send blessings on the Prophet ﷺ',
			'salawatFridayBody' => 'It\'s Friday — increase your salawat upon the Prophet ﷺ.',
			'mulkTitle' => 'Surah Al-Mulk',
			'mulkBody' => 'Before you sleep — read Surah Al-Mulk.',
			'qiblaFromNorth' => ({required Object degrees}) => 'Qibla · ${degrees}° from North',
			'facingQibla' => 'You are facing the Qibla',
			'turnRight' => ({required Object degrees}) => 'Turn right ${degrees}°',
			'turnLeft' => ({required Object degrees}) => 'Turn left ${degrees}°',
			'calibrateHint' => 'Move in a figure-8 to calibrate',
			'compassUnavailable' => 'Compass unavailable',
			'compassUnavailableBody' => 'This device has no compass sensor, or it needs calibration. Try moving it in a figure-8 motion.',
			'qiblaNoLocation' => 'Location needed',
			'qiblaNoLocationBody' => 'The Qibla direction can\'t be calculated until your location is known. Turn on location services, or choose your city in Settings.',
			'placeYourLocation' => 'Your location',
			'placeSelectedCity' => 'Selected city',
			'placeMakkah' => 'Makkah',
			'onboardSkip' => 'Skip',
			'onboardNext' => 'Next',
			'onboardGetStarted' => 'Get started',
			'onboardWelcomeTitle' => 'Welcome to Hisn',
			'onboardWelcomeBody' => 'Your daily companion for remembrance, Qur\'an, and prayer. Here\'s a quick tour to get you started.',
			'onboardAdhkarTitle' => 'Adhkar & Duas',
			'onboardAdhkarBody' => 'Morning and evening remembrances, a tasbih counter, and your own custom duas. Tap a dua to count through its repetitions.',
			'onboardQuranTitle' => 'The Holy Qur\'an',
			'onboardQuranBody' => 'Read the entire Qur\'an in a beautiful mushaf, pick up where you left off, and bookmark the verses you love.',
			'onboardPrayerTitle' => 'Prayer & Qibla',
			'onboardPrayerBody' => 'Accurate prayer times for your location, a countdown to the next salah, and a compass pointing to the Qibla.',
			'onboardPermsTitle' => 'A couple of permissions',
			'onboardPermsBody' => 'Allow these so Hisn works at its best. You can change them anytime in Settings.',
			'onboardLocationTitle' => 'Location',
			'onboardLocationBody' => 'To calculate accurate prayer times and the Qibla direction for where you are.',
			'onboardLocationAction' => 'Allow location',
			'onboardNotifTitle' => 'Notifications',
			'onboardNotifBody' => 'A gentle reminder at each prayer time so you never miss a salah.',
			'onboardNotifAction' => 'Enable reminders',
			'onboardGranted' => 'Enabled',
			'secAppearance' => 'Appearance',
			'appearanceColors' => 'Color palette',
			'appearanceTheme' => 'Theme',
			'themeLight' => 'Light',
			'themeDark' => 'Dark',
			'themeSystem' => 'System',
			'paletteEmerald' => 'Emerald & Gold',
			'paletteSapphire' => 'Sapphire & Sky',
			'paletteAmethyst' => 'Amethyst & Rose',
			'paletteRosewood' => 'Rosewood',
			'paletteLagoon' => 'Lagoon',
			'paletteDesert' => 'Desert',
			'arabicFont' => 'Arabic font',
			'readingTheme' => 'Reading background',
			'readingSystem' => 'Match app',
			'readingSepia' => 'Sepia',
			'readingNight' => 'Night',
			'patterns' => 'Geometric pattern',
			'patternsSub' => 'Subtle ornament on headers and counter',
			'ampm.0' => 'AM',
			'ampm.1' => 'PM',
			'weekdaysShort.0' => 'Mon',
			'weekdaysShort.1' => 'Tue',
			'weekdaysShort.2' => 'Wed',
			'weekdaysShort.3' => 'Thu',
			'weekdaysShort.4' => 'Fri',
			'weekdaysShort.5' => 'Sat',
			'weekdaysShort.6' => 'Sun',
			'monthsShort.0' => 'Jan',
			'monthsShort.1' => 'Feb',
			'monthsShort.2' => 'Mar',
			'monthsShort.3' => 'Apr',
			'monthsShort.4' => 'May',
			'monthsShort.5' => 'Jun',
			'monthsShort.6' => 'Jul',
			'monthsShort.7' => 'Aug',
			'monthsShort.8' => 'Sep',
			'monthsShort.9' => 'Oct',
			'monthsShort.10' => 'Nov',
			'monthsShort.11' => 'Dec',
			'dateFormat' => ({required Object weekday, required Object day, required Object month}) => '${weekday}, ${day} ${month}',
			'hijriMonths.0' => 'Muharram',
			'hijriMonths.1' => 'Safar',
			'hijriMonths.2' => 'Rabi al-Awwal',
			'hijriMonths.3' => 'Rabi al-Thani',
			'hijriMonths.4' => 'Jumada al-Ula',
			'hijriMonths.5' => 'Jumada al-Akhirah',
			'hijriMonths.6' => 'Rajab',
			'hijriMonths.7' => 'Sha\'ban',
			'hijriMonths.8' => 'Ramadan',
			'hijriMonths.9' => 'Shawwal',
			'hijriMonths.10' => 'Dhul-Qa\'dah',
			'hijriMonths.11' => 'Dhul-Hijjah',
			'hijriDateFormat' => ({required Object day, required Object month, required Object year}) => '${day} ${month} ${year} AH',
			'hijriSuffix' => 'AH',
			'secBackup' => 'Backup & restore',
			'backupSub' => 'Save your progress to a file',
			'backupOnThisDevice' => 'On this device',
			'backupSave' => 'Save a backup',
			'backupSaveHint' => 'Writes everything below to a file you can keep in Drive or Files, or send to yourself.',
			'backupRestoreHeading' => 'Restore',
			'backupRestore' => 'Restore from a file',
			'backupRestoreHint' => 'Replaces what is on this device with the contents of a backup file.',
			'backupPrivacy' => 'A backup is a plain text file. It stays on this device unless you send it somewhere yourself — Hisn never uploads it.',
			'backupStatStreak' => 'Current streak',
			'backupStatBest' => 'Best streak',
			'backupStatDays' => 'Days fortified',
			'backupStatFavorites' => 'Saved duas',
			'backupStatCustom' => 'My duas',
			'backupStatQuran' => 'Quran bookmarks',
			'restoreTitle' => 'Restore this backup?',
			'restoreSavedOn' => ({required Object date}) => 'Saved ${date}',
			'restoreSavedOnVersion' => ({required Object date, required Object version}) => 'Saved ${date} · v${version}',
			'restoreScopeEverything' => 'Everything',
			'restoreScopeEverythingSub' => 'Progress and settings',
			'restoreScopeProgress' => 'Progress only',
			'restoreScopeProgressSub' => 'Keep this phone\'s location, reminders and language',
			'restoreWarning' => 'This replaces what is currently on this device.',
			'restoreAction' => 'Restore',
			'restoreDoneOne' => 'Restored 1 item',
			'restoreDoneOther' => ({required Object n}) => 'Restored ${n} items',
			'backupSaved' => 'Backup ready to save',
			'backupFailed' => 'Could not create the backup',
			'restoreErrMalformed' => 'That file could not be read.',
			'restoreErrNotABackup' => 'That is not a Hisn backup file.',
			'restoreErrTooNew' => 'That backup was made by a newer version of Hisn. Update the app first.',
			'restoreErrEmpty' => 'That backup has nothing to restore.',
			'restoreFailed' => 'Could not restore. Nothing was changed.',
			'versesOnThisPage' => 'Verses on this page',
			'savedVerses' => 'Saved verses',
			'savedPages' => 'Saved pages',
			'saveVerse' => 'Save verse',
			'unsaveVerse' => 'Remove saved verse',
			'secCalendar' => 'Islamic calendar',
			'calendarSub' => 'Sunnah fasts and Hijri occasions',
			'sunnahCalendarTitle' => 'Fasts & occasions',
			'upcomingLabel' => 'Upcoming',
			'nothingUpcoming' => 'Nothing marked in the next two months.',
			'calendarNote' => 'Dates are calculated (Umm al-Qura) and can differ from your local sighting by a day.',
			'fastingRecommended' => 'Sunnah to fast',
			'fastingObligatory' => 'Obligatory fast',
			'fastingForbidden' => 'Not a day to fast',
			'fastingNoneToday' => 'No particular fast today.',
			'fastRamadan' => 'Ramadan',
			'fastMonday' => 'Monday fast',
			'fastThursday' => 'Thursday fast',
			'fastWhiteDay' => 'The white days',
			'fastTasua' => 'Tasu\'a',
			'fastAshura' => 'Ashura',
			'fastDhulHijjah' => 'The ten of Dhul Hijjah',
			'fastArafah' => 'The Day of Arafah',
			'fastSixOfShawwal' => 'Six of Shawwal',
			'fastRamadanSub' => 'The obligatory fast of the month.',
			'fastMondaySub' => 'Deeds are presented on Mondays and Thursdays. — Tirmidhi',
			'fastThursdaySub' => 'Deeds are presented on Mondays and Thursdays. — Tirmidhi',
			'fastWhiteDaySub' => 'The 13th, 14th and 15th of every Hijri month. — Bukhari & Muslim',
			'fastTasuaSub' => 'Fasted along with the tenth. — Muslim',
			'fastAshuraSub' => 'It expiates the year before it. — Muslim',
			'fastDhulHijjahSub' => 'No days are more beloved to Allah for righteous deeds than these. — Bukhari',
			'fastArafahSub' => 'It expiates the year before and the year after — for those not on Hajj. — Muslim',
			'fastSixOfShawwalSub' => 'Whoever fasts Ramadan and follows it with six of Shawwal, it is as fasting the whole year. — Muslim',
			'eventNewYear' => 'Islamic New Year',
			'eventAshura' => 'Ashura',
			'eventRamadan' => 'Ramadan begins',
			'eventLastTen' => 'The last ten nights',
			'eventEidFitr' => 'Eid al-Fitr',
			'eventDhulHijjah' => 'Dhul Hijjah begins',
			'eventArafah' => 'The Day of Arafah',
			'eventEidAdha' => 'Eid al-Adha',
			'eventLastTenSub' => 'Laylat al-Qadr is sought in the odd nights of these ten.',
			'barEidAlFitr' => 'Fasting is not allowed on Eid al-Fitr.',
			'barEidAlAdha' => 'Fasting is not allowed on Eid al-Adha.',
			'barTashriq' => 'Fasting is not allowed on the days of Tashriq.',
			'hijriAdjust' => 'Hijri date adjustment',
			'hijriAdjustHint' => 'The calculated date can run a day ahead of or behind your local sighting. Adjust it to match your community.',
			'hijriOffsetLabels.0' => '−2 days',
			'hijriOffsetLabels.1' => '−1 day',
			'hijriOffsetLabels.2' => 'No adjustment',
			'hijriOffsetLabels.3' => '+1 day',
			'hijriOffsetLabels.4' => '+2 days',
			'fastingReminders' => 'Fasting reminders',
			'fastingRemindersSub' => 'A reminder the evening before a sunnah fast',
			'notifFastTitle' => 'Fasting tomorrow',
			'notifFastBody' => ({required Object name}) => 'Tomorrow is ${name} — a fast from the Sunnah.',
			'notifOccasionBody' => 'Tomorrow, in sha\' Allah.',
			'share' => 'Share',
			'shareAsImage' => 'Share card',
			'shareAsText' => 'Share text',
			'shareImageFailedNotReady' => 'The card wasn\'t ready to capture — sharing the text instead.',
			'shareImageFailedUnsupported' => 'This device couldn\'t make an image — sharing the text instead.',
			_ => null,
		};
	}
}
