///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsUr extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsUr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ur,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ur>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsUr _root = this; // ignore: unused_field

	@override 
	TranslationsUr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsUr(meta: meta ?? this.$meta);

	// Translations
	@override String get navAdhkar => 'اذکار';
	@override String get navQuran => 'قرآن';
	@override String get navTasbih => 'تسبیح';
	@override String get navQibla => 'قبلہ';
	@override String get navSaved => 'محفوظ';
	@override String get navSettings => 'ترتیبات';
	@override String get navPrayer => 'نماز';
	@override String get prayerQiblaTitle => 'نماز اور قبلہ';
	@override String get weeklySchedule => 'ہفتہ وار اوقات';
	@override String get searchDuas => 'دعائیں تلاش کریں…';
	@override String get allAdhkar => 'تمام اذکار';
	@override String get groupDaily => 'روزانہ کے اذکار';
	@override String get groupSituational => 'مختلف مواقع کے لیے';
	@override String get groupMine => 'میرے اذکار';
	@override String get muhassanHeading => 'محصّن';
	@override String muhassanToday({required Object percent}) => 'آج آپ کی تکمیل ${percent}% ہے';
	@override String get muhassanComplete => 'مکمل — ما شاء اللہ';
	@override String get muhassanMorning => 'صبح';
	@override String get muhassanEvening => 'شام';
	@override String streakDays({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ur'))(n,
		one: 'مسلسل 1 دن',
		other: 'مسلسل ${n} دن',
	);
	@override String get streakStart => 'اپنا تسلسل شروع کریں';
	@override String streakBest({required Object n}) => 'بہترین: ${n}';
	@override String get streakTitle => 'آپ کا تسلسل';
	@override String get streakWord => 'دن کا تسلسل';
	@override String get statCurrent => 'موجودہ';
	@override String get statBest => 'بہترین';
	@override String get statTotal => 'کل دن';
	@override String daysValue({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ur'))(n,
		one: '1 دن',
		other: '${n} دن',
	);
	@override String get streakOnFire => 'آپ کا تسلسل بہت اچھا ہے — جاری رکھیں!';
	@override String get streakTodayPending => 'تسلسل بڑھانے کے لیے آج کے اذکار مکمل کریں';
	@override String get streakBroken => 'دوبارہ شروع کرنے کے لیے صبح اور شام کے اذکار مکمل کریں';
	@override String get last4Weeks => 'گزشتہ 4 ہفتے';
	@override String get todayLabel => 'آج';
	@override String get fortifiedLegend => 'مکمل';
	@override List<String> get weekdayLetters => [
		'پ',
		'م',
		'ب',
		'ج',
		'ج',
		'ہ',
		'ا',
	];
	@override String get quranTitle => 'قرآن';
	@override String get searchSurah => 'سورت تلاش کریں…';
	@override String get searchQuran => 'سورت یا عربی الفاظ تلاش کریں';
	@override String get quranSearchSurahs => 'سورتیں';
	@override String get quranSearchVerses => 'آیات';
	@override String get quranSearchFailed => 'آیات تلاش نہیں ہو سکیں۔ دوبارہ کوشش کریں۔';
	@override String get quranSearchLimit => 'آیات کے پہلے 50 نتائج دکھائے جا رہے ہیں';
	@override String get retrySearch => 'دوبارہ تلاش کریں';
	@override String get afterPrayerTasbih => 'نماز کے بعد تسبیح';
	@override String get startAfterPrayerTasbih => 'نماز کے بعد کے اذکار گنیں';
	@override String get currentPhrase => 'موجودہ ذکر';
	@override String get afterPrayerComplete => 'نماز کے بعد کے اذکار مکمل ہو گئے ہیں۔';
	@override String get continueReading => 'پڑھنا جاری رکھیں';
	@override String get surahWord => 'سورت';
	@override String get revelationMeccan => 'مکی';
	@override String get revelationMedinan => 'مدنی';
	@override String versesCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ur'))(n,
		one: '1 آیت',
		other: '${n} آیات',
	);
	@override String juzLabel({required Object n}) => 'پارہ ${n}';
	@override String get quranBookmarks => 'بک مارکس';
	@override String get noBookmarks => 'ابھی کوئی بک مارک نہیں';
	@override String get bookmarkAdded => 'بک مارک محفوظ ہو گیا';
	@override String get bookmarkRemoved => 'بک مارک ہٹا دیا گیا';
	@override String get goToAyah => 'آیت پر جائیں';
	@override String get chooseSurah => 'سورت';
	@override String get verseNumber => 'آیت نمبر';
	@override String verseRange({required Object n}) => '1–${n}';
	@override String get goAction => 'جائیں';
	@override String get myDuas => 'میری دعائیں';
	@override String get myDuasSub => 'آپ کی شامل کردہ دعائیں';
	@override String get addDua => 'دعا شامل کریں';
	@override String get newDua => 'نئی دعا';
	@override String get fieldArabic => 'عربی متن';
	@override String get fieldArabicRequired => 'عربی متن درج کریں';
	@override String get fieldTitle => 'عنوان (اختیاری)';
	@override String get fieldTransliteration => 'تلفظ (اختیاری)';
	@override String get fieldTranslation => 'ترجمہ / مفہوم (اختیاری)';
	@override String get fieldReference => 'حوالہ (اختیاری)';
	@override String get fieldRepeat => 'تعداد';
	@override String get fieldRepeatPositiveRequired => '1 یا اس سے بڑی صحیح تعداد درج کریں۔';
	@override String get addDhikr => 'ذکر شامل کریں';
	@override String get editDhikr => 'ذکر میں ترمیم کریں';
	@override String get deleteDhikr => 'ذکر حذف کریں';
	@override String get deleteDhikrConfirm => 'یہ ذکر اور اس کی محفوظ گنتی حذف کر دیں؟';
	@override String get fieldDhikrName => 'نام';
	@override String get fieldDhikrNameRequired => 'اس ذکر کا نام درج کریں۔';
	@override String get fieldDhikrTargetRequired => '1 سے 1,000,000 تک صحیح تعداد درج کریں۔';
	@override String get nextSetOnTap => 'دور مکمل ہوا۔ اگلا دور شروع کرنے کے لیے دبائیں۔';
	@override String get customDhikrTargetNote => 'اپنی نشست کے لیے تکرار کی تعداد منتخب کریں۔';
	@override String get save => 'محفوظ کریں';
	@override String get cancel => 'منسوخ کریں';
	@override String get delete => 'حذف کریں';
	@override String get deleteDua => 'دعا حذف کریں';
	@override String get deleteDuaConfirm => 'یہ دعا میری دعاؤں سے حذف کر دیں؟';
	@override String get duaSaved => 'دعا محفوظ ہو گئی';
	@override String get duaUpdated => 'دعا کی ترمیم محفوظ ہو گئی';
	@override String get editDua => 'دعا میں ترمیم کریں';
	@override String get edit => 'ترمیم';
	@override String get noCustomTitle => 'ابھی کوئی دعا نہیں';
	@override String get noCustomBody => 'اپنی دعا شامل کرنے کے لیے + دبائیں۔';
	@override String get recommendedNow => 'اس وقت کے لیے';
	@override String readNow({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ur'))(count,
		one: 'ابھی پڑھیں · 1 دعا',
		other: 'ابھی پڑھیں · ${count} دعائیں',
	);
	@override String duaCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ur'))(count,
		one: '1 دعا',
		other: '${count} دعائیں',
	);
	@override String get now => 'ابھی';
	@override String get next => 'اگلی';
	@override String get remaining => 'باقی';
	@override String get countdownNow => 'ابھی';
	@override String get sinceAdhan => 'اذان کے بعد سے';
	@override String todaysPrayers({required Object location}) => 'آج کی نمازیں · ${location}';
	@override String get searchHint => 'دعائیں، معانی یا حوالے تلاش کریں…';
	@override String get clear => 'صاف کریں';
	@override String get searchPrompt => 'عنوان، مفہوم، تلفظ یا حوالے سے تلاش کریں۔';
	@override String noResults({required Object query}) => '“${query}” کے لیے کوئی دعا نہیں ملی۔';
	@override String quranNoResults({required Object query}) => '“${query}” کے لیے کوئی سورت یا آیت نہیں ملی۔';
	@override String resultsCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ur'))(n,
		one: '1 نتیجہ',
		other: '${n} نتائج',
	);
	@override String get noSavedTitle => 'ابھی کوئی دعا محفوظ نہیں';
	@override String get noSavedBody => 'فوری رسائی کے لیے کسی دعا کا بک مارک دبائیں۔';
	@override String get resetCount => 'گنتی صفر کریں';
	@override String get tapToCount => 'گنتی کے لیے کہیں بھی دبائیں';
	@override String setsCompleted({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ur'))(n,
		one: '1 دور مکمل',
		other: '${n} دور مکمل',
	);
	@override String ofTarget({required Object n}) => 'کل ${n} میں سے';
	@override String get resetProgress => 'پیش رفت از سر نو شروع کریں';
	@override String get setComplete => 'دور مکمل — تقبّل اللہ';
	@override String get tapEachDua => 'ہر دعا کی تکرار گننے کے لیے اسے دبائیں';
	@override String get listenAction => 'سنیں';
	@override String get listenStart => 'اذکار چلائیں';
	@override String get listenRestart => 'شروع سے دوبارہ چلائیں';
	@override String get listenHint => 'تلاوت جاری ہے — آپ فون لاک کر سکتے ہیں';
	@override String get listenIdleTitle => 'کچھ نہیں چل رہا';
	@override String get listenIdleBody => 'اذکار چلائیں؛ ہر تکرار کی گنتی خود بخود ہو گی۔';
	@override String listenMissing({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ur'))(n,
		one: '1 دعا کی ریکارڈنگ ابھی موجود نہیں',
		other: '${n} دعاؤں کی ریکارڈنگ ابھی موجود نہیں',
	);
	@override String get listenPrevious => 'پچھلا ذکر';
	@override String get listenNext => 'اگلا ذکر';
	@override String get listenPause => 'وقفہ کریں';
	@override String get listenResume => 'جاری رکھیں';
	@override String get secListen => 'سماعت';
	@override String get listenSub => 'ہاتھ استعمال کیے بغیر اذکار سنیں';
	@override String get listenGap => 'تکرار کے درمیان وقفہ';
	@override List<String> get listenGapLabels => [
		'بغیر وقفے',
		'1 سیکنڈ',
		'2 سیکنڈ',
		'3 سیکنڈ',
	];
	@override String get listenAppendix => 'طویل ذکر شامل کریں';
	@override String get listenAppendixSub => 'آخر میں 100 بار تہلیل اور تسبیح شامل کریں۔ تقریباً 20 منٹ۔';
	@override String get listenKeepScreenOn => 'اسکرین روشن رکھیں';
	@override String get listenKeepScreenOnSub => 'مصروف ہاتھوں کے ساتھ پڑھنے کے لیے۔ بند ہو تو فون سو جاتا ہے مگر تلاوت جاری رہتی ہے۔';
	@override String get listenReciter => 'قاری';
	@override String get duaCopied => 'دعا نقل ہو گئی';
	@override String get removeBookmark => 'بک مارک ہٹائیں';
	@override String get bookmark => 'بک مارک';
	@override String get copy => 'نقل کریں';
	@override String get done => 'مکمل';
	@override String get settings => 'ترتیبات';
	@override String get secPrayerTimes => 'نماز کے اوقات';
	@override String get secReminders => 'یاد دہانیاں';
	@override String get secDisplay => 'نمائش';
	@override String get secLanguage => 'زبان';
	@override String get secAbout => 'تعارف';
	@override String get location => 'مقام';
	@override String get locYourLocationGps => 'آپ کا مقام (GPS)';
	@override String locDeviceGps({required Object label}) => 'آلے کا GPS · ${label}';
	@override String locFixedCity({required Object label}) => '${label} (مقررہ شہر)';
	@override String get calcMethod => 'حساب کا طریقہ';
	@override String get asrCalc => 'عصر کا حساب';
	@override String get nightTimes => 'رات کے اوقات';
	@override String get showMidnight => 'آدھی رات دکھائیں';
	@override String get showMidnightSub => 'مغرب اور فجر کے درمیان کا نصف';
	@override String get showLastThird => 'رات کا آخری تہائی دکھائیں';
	@override String get showLastThirdSub => 'مغرب اور فجر کے درمیان آخری تہائی کا آغاز: تہجد کا وقت';
	@override String get notifications => 'اطلاعات';
	@override String get prayerReminders => 'نماز کی یاد دہانیاں';
	@override String get prayerRemindersSub => 'ہر نماز کے وقت اطلاع پائیں';
	@override String get dailyRemembrance => 'روزانہ کے اذکار';
	@override String get dailyRemembranceSub => 'صبح اور شام کے اذکار کی تکمیل تک یاد دہانی، نیز جمعہ اور رات کی سنتیں';
	@override String get adhanSound => 'اذان کی آواز';
	@override String get adhanSoundSub => 'ہر نماز کے وقت اذان چلائیں';
	@override String get adhanNeedsReminders => 'نماز کے وقت اذان کے لیے اوپر نماز کی یاد دہانیاں فعال کریں۔';
	@override String get adhanExactAlarmsOff => 'نماز کے وقت اذان کے لیے Hisn کو الارم اور یاد دہانیوں کی اجازت دیں۔';
	@override String get allowAlarms => 'اجازت دیں';
	@override String get adhanFlipToSilence => 'الٹا کر کے خاموش کریں';
	@override String get adhanFlipToSilenceSub => 'چلتی اذان روکنے کے لیے فون کو الٹا رکھ دیں۔ آواز کا کوئی بھی بٹن دبانے سے بھی اذان رک جاتی ہے۔';
	@override String get adhanVolume => 'اذان کی آواز کا کنٹرول';
	@override List<String> get streamLabels => [
		'میڈیا',
		'رنگر / اطلاعات',
		'الارم',
	];
	@override List<String> get streamHints => [
		'میڈیا: فون کا موسیقی اور ویڈیو کی آواز والا کنٹرول استعمال ہوتا ہے۔ خاموش رنگر اسے لازماً بند نہیں کرتا؛ میڈیا کی آواز اور ڈو ناٹ ڈسٹرب کی ترتیب بھی دیکھیں۔',
		'رنگر: فون کا رنگ ٹون یا اطلاعات کی آواز والا کنٹرول استعمال ہوتا ہے۔ خاموش یا وائبریشن موڈ اور ڈو ناٹ ڈسٹرب اذان کو خاموش کر سکتے ہیں۔',
		'الارم: فون کا الارم کی آواز والا کنٹرول استعمال ہوتا ہے۔ خاموش رنگر عموماً اسے بند نہیں کرتا؛ ڈو ناٹ ڈسٹرب میں الارم کی اجازت بھی دیکھیں۔',
	];
	@override String get previewAdhan => 'اذان سن کر دیکھیں';
	@override String get stopAdhan => 'اذان بند کریں';
	@override String get adhanVoice => 'اذان کی آواز';
	@override String get adhanVoiceDefault => 'ایپ کی اپنی اذان';
	@override String get adhanVoiceCustom => 'آپ کی اپنی آڈیو فائل';
	@override String get adhanVoiceCustomHint => 'ہر نماز کے لیے چلے گی، فجر سمیت';
	@override String get adhanVoiceChooseFile => 'فائل منتخب کریں…';
	@override String get adhanVoiceChangeFile => 'دوسری فائل منتخب کریں';
	@override String get adhanVoiceUnreadable => 'یہ فائل پڑھی نہیں جا سکی۔';
	@override String get adhanVoiceTooLarge => 'فائل بہت بڑی ہے۔ 20 MB سے چھوٹی آڈیو فائل منتخب کریں۔';
	@override String get adhanVoiceNotPlayable => 'یہ فائل چل نہیں سکی۔ MP3 یا OGG جیسی آڈیو فائل منتخب کریں۔';
	@override String get adhanPlaying => 'اذان چل رہی ہے…';
	@override String get notifBlocked => 'اطلاعات بند ہیں۔ فون کی ترتیبات میں Hisn کی اطلاعات فعال کریں۔';
	@override String get textSize => 'متن کا سائز';
	@override List<String> get fontScaleLabels => [
		'چھوٹا',
		'معمول',
		'بڑا',
		'بہت بڑا',
	];
	@override String get showTransliteration => 'تلفظ دکھائیں';
	@override String get showTransliterationSub => 'لاطینی حروف میں ادائیگی';
	@override String get showTranslation => 'ترجمہ دکھائیں';
	@override String get showTranslationSub => 'اردو مفہوم';
	@override String get aboutBody => 'دعاؤں اور اذکار کا ساتھی · ابتدائی نسخہ\nنماز کے اوقات Adhan لائبریری سے۔';
	@override String get automatic => 'خودکار';
	@override String get useDeviceLocation => 'میرے آلے کا مقام استعمال کریں';
	@override String get gpsActive => 'فعال · اوقات آپ کے مقام کے مطابق ہیں';
	@override String get gpsDetect => 'GPS سے مقام معلوم کریں (اجازت درکار ہے)';
	@override String get chooseCity => 'شہر منتخب کریں';
	@override String get cityNote => 'منتخب شہر کے اوقات فون کے موجودہ ٹائم زون میں دکھائے جاتے ہیں؛ شہر آپ کے علاقے میں ہو تو درست رہتے ہیں۔';
	@override String get madhabStandard => 'معمول (شافعی، مالکی، حنبلی)';
	@override String get madhabHanafi => 'حنفی';
	@override String get asrHintStandard => 'عصر اس وقت شروع ہوتی ہے جب کسی چیز کا سایہ اس کی لمبائی کے برابر ہو';
	@override String get asrHintHanafi => 'عصر اس وقت شروع ہوتی ہے جب کسی چیز کا سایہ اس کی لمبائی کا دوگنا ہو';
	@override String get prayerFajr => 'فجر';
	@override String get prayerSunrise => 'طلوع آفتاب';
	@override String get markMidnight => 'آدھی رات';
	@override String get markLastThird => 'آخری تہائی';
	@override String get prayerDhuhr => 'ظہر';
	@override String get prayerAsr => 'عصر';
	@override String get prayerMaghrib => 'مغرب';
	@override String get prayerIsha => 'عشاء';
	@override String get prayerNone => '—';
	@override String notifTitle({required Object name}) => 'نماز ${name}';
	@override String notifBody({required Object name, required Object place}) => 'نماز ${name} کا وقت ہے — ${place}۔';
	@override String notifIqamahBody({required Object name, required Object place}) => 'نماز ${name} کی اقامت — ${place}۔';
	@override String get iqamahOffset => 'اقامت کا وقفہ';
	@override String get iqamahAtAdhan => 'اذان کے وقت';
	@override String iqamahPlusMinutes({required Object minutes}) => '+${minutes} منٹ';
	@override String get testNotifTitle => 'آزمائشی یاد دہانی';
	@override String get testNotifBody => 'اگر یہ اطلاع نظر آ رہی ہے تو نماز کی یاد دہانیاں کام کر رہی ہیں۔ 🌙';
	@override String get sendTestNotif => 'آزمائشی اطلاع بھیجیں';
	@override String get testSent => 'آزمائش بھیج دی گئی — ایک اطلاع ابھی اور دوسری 12 سیکنڈ بعد آئے گی (فون لاک کریں)۔';
	@override String get testBlocked => 'بھیج دی گئی، لیکن فون میں Hisn کی اطلاعات بند ہیں۔ ترتیبات ← ایپس ← Hisn ← اطلاعات میں فعال کریں۔';
	@override String get batteryHint => 'بعض فون (مثلاً Xiaomi/MIUI یا Samsung) ایپ بند ہونے پر مقررہ یاد دہانیاں روکتے ہیں۔ اگر یاد دہانی نہ آئے تو Hisn کے لیے خودکار آغاز اور بیٹری کا غیر محدود استعمال فعال کریں۔';
	@override String get adhkarMorningTitle => 'صبح کے اذکار';
	@override String get adhkarMorningBody => 'اپنی صبح کا آغاز اللہ کے ذکر سے کریں۔';
	@override String get adhkarEveningTitle => 'شام کے اذکار';
	@override String get adhkarEveningBody => 'اپنی شام اللہ کے ذکر کے ساتھ گزاریں۔';
	@override String get kahfTitle => 'سورۃ الکہف';
	@override String get kahfBody => 'آج جمعہ ہے — دو جمعوں کے درمیان نور کے لیے سورۃ الکہف پڑھیں۔';
	@override String get salawatTitle => 'نبی ﷺ پر درود بھیجیں';
	@override String get salawatBody => 'کچھ وقت نکال کر نبی ﷺ پر درود بھیجیں۔';
	@override String get salawatFridayTitle => 'نبی ﷺ پر درود بھیجیں';
	@override String get salawatFridayBody => 'آج جمعہ ہے — نبی ﷺ پر کثرت سے درود بھیجیں۔';
	@override String get mulkTitle => 'سورۃ الملک';
	@override String get mulkBody => 'سونے سے پہلے سورۃ الملک پڑھیں۔';
	@override String qiblaFromNorth({required Object degrees}) => 'قبلہ · شمال سے ${degrees}°';
	@override String get facingQibla => 'آپ قبلہ رخ ہیں';
	@override String turnRight({required Object degrees}) => '${degrees}° دائیں مڑیں';
	@override String turnLeft({required Object degrees}) => '${degrees}° بائیں مڑیں';
	@override String get calibrateHint => 'درستگی کے لیے فون کو 8 کی شکل میں حرکت دیں';
	@override String get qiblaHoldFlat => 'قطب نما پڑھنے کے لیے فون ہموار رکھیں';
	@override String get qiblaInterference => 'دھات یا مقناطیس سے دور ہو جائیں';
	@override String get qiblaTrueNorth => 'حقیقی شمال کے مطابق درست کیا گیا';
	@override String get qiblaMagneticOnly => 'مقناطیسی شمال — درستگی کی معلومات دستیاب نہیں';
	@override String get compassUnavailable => 'قطب نما دستیاب نہیں';
	@override String get compassUnavailableBody => 'اس آلے میں مقناطیسی حسّاس نہیں، اس لیے قبلے کی متحرک سوئی نہیں دکھائی جا سکتی۔';
	@override String get qiblaNoLocation => 'مقام درکار ہے';
	@override String get qiblaNoLocationBody => 'مقام معلوم ہوئے بغیر قبلے کی سمت کا حساب نہیں ہو سکتا۔ مقام کی خدمات فعال کریں یا ترتیبات میں شہر منتخب کریں۔';
	@override String get placeYourLocation => 'آپ کا مقام';
	@override String get placeSelectedCity => 'منتخب شہر';
	@override String get placeMakkah => 'مکہ';
	@override String get onboardSkip => 'چھوڑیں';
	@override String get onboardNext => 'اگلا';
	@override String get onboardGetStarted => 'شروع کریں';
	@override String get onboardWelcomeTitle => 'Hisn میں خوش آمدید';
	@override String get onboardWelcomeBody => 'ذکر، قرآن اور نماز کا روزانہ ساتھی۔ شروع کرنے کے لیے مختصر تعارف دیکھیں۔';
	@override String get onboardAdhkarTitle => 'اذکار اور دعائیں';
	@override String get onboardAdhkarBody => 'صبح اور شام کے اذکار، تسبیح کا شمار اور آپ کی اپنی دعائیں۔ ہر دعا کی تکرار گننے کے لیے اسے دبائیں۔';
	@override String get onboardQuranTitle => 'قرآن کریم';
	@override String get onboardQuranBody => 'مکمل قرآن مصحف میں پڑھیں، جہاں چھوڑا تھا وہیں سے جاری رکھیں، اور پسندیدہ آیات محفوظ کریں۔';
	@override String get onboardPrayerTitle => 'نماز اور قبلہ';
	@override String get onboardPrayerBody => 'آپ کے مقام کے مطابق نماز کے اوقات، اگلی نماز تک باقی وقت اور قبلے کی سمت دکھانے والا قطب نما۔';
	@override String get onboardPermsTitle => 'چند اجازتیں';
	@override String get onboardPermsBody => 'بہتر کارکردگی کے لیے یہ اجازتیں دیں۔ انہیں ترتیبات میں کبھی بھی بدل سکتے ہیں۔';
	@override String get onboardLocationTitle => 'مقام';
	@override String get onboardLocationBody => 'آپ کے مقام کے مطابق نماز کے اوقات اور قبلے کی سمت کے حساب کے لیے۔';
	@override String get onboardLocationAction => 'مقام کی اجازت دیں';
	@override String get onboardNotifTitle => 'اطلاعات';
	@override String get onboardNotifBody => 'ہر نماز کے وقت نرم یاد دہانی۔';
	@override String get onboardNotifAction => 'یاد دہانیاں فعال کریں';
	@override String get onboardGranted => 'فعال';
	@override String get secAppearance => 'ظاہری انداز';
	@override String get appearanceColors => 'رنگوں کا مجموعہ';
	@override String get appearanceTheme => 'تھیم';
	@override String get themeLight => 'روشن';
	@override String get themeDark => 'تاریک';
	@override String get themeSystem => 'آلے کے مطابق';
	@override String get paletteQibla => 'قبلہ اور پیتل';
	@override String get paletteEmerald => 'زمردی اور سنہری';
	@override String get paletteSapphire => 'نیلمی اور آسمانی';
	@override String get paletteAmethyst => 'بنفشی اور گلابی';
	@override String get paletteRosewood => 'گلابی لکڑی';
	@override String get paletteLagoon => 'لاجوردی';
	@override String get paletteDesert => 'صحرائی';
	@override String get arabicFont => 'عربی خط';
	@override String get readingTheme => 'پڑھنے کا پس منظر';
	@override String get readingSystem => 'ایپ کے مطابق';
	@override String get readingSepia => 'سیپیا';
	@override String get readingNight => 'رات';
	@override String get patterns => 'ہندسی نقش';
	@override String get patternsSub => 'عنوانات اور شمار میں ہلکی آرائش';
	@override List<String> get ampm => [
		'قبل دوپہر',
		'بعد دوپہر',
	];
	@override List<String> get weekdaysShort => [
		'پیر',
		'منگل',
		'بدھ',
		'جمعرات',
		'جمعہ',
		'ہفتہ',
		'اتوار',
	];
	@override List<String> get monthsShort => [
		'جنوری',
		'فروری',
		'مارچ',
		'اپریل',
		'مئی',
		'جون',
		'جولائی',
		'اگست',
		'ستمبر',
		'اکتوبر',
		'نومبر',
		'دسمبر',
	];
	@override String dateFormat({required Object weekday, required Object day, required Object month}) => '${weekday}، ${day} ${month}';
	@override List<String> get hijriMonths => [
		'محرم',
		'صفر',
		'ربیع الاول',
		'ربیع الآخر',
		'جمادی الاول',
		'جمادی الآخر',
		'رجب',
		'شعبان',
		'رمضان',
		'شوال',
		'ذوالقعدہ',
		'ذوالحجہ',
	];
	@override String hijriDateFormat({required Object day, required Object month, required Object year}) => '${day} ${month} ${year} ھ';
	@override String get hijriSuffix => 'ھ';
	@override String get secBackup => 'بیک اپ اور بحالی';
	@override String get backupSub => 'اپنی پیش رفت فائل میں محفوظ کریں';
	@override String get backupOnThisDevice => 'اس آلے پر';
	@override String get backupSave => 'بیک اپ محفوظ کریں';
	@override String get backupSaveHint => 'نیچے کی تمام معلومات ایک فائل میں لکھتا ہے جسے Drive یا Files میں رکھ سکتے ہیں یا خود کو بھیج سکتے ہیں۔';
	@override String get backupRestoreHeading => 'بحالی';
	@override String get backupRestore => 'فائل سے بحال کریں';
	@override String get backupRestoreHint => 'اس آلے کی معلومات کو بیک اپ فائل کی معلومات سے بدل دیتا ہے۔';
	@override String get backupPrivacy => 'بیک اپ سادہ متن کی فائل ہے۔ جب تک آپ خود نہ بھیجیں یہ آلے پر رہتی ہے؛ Hisn اسے اپ لوڈ نہیں کرتا۔';
	@override String get backupStatStreak => 'موجودہ تسلسل';
	@override String get backupStatBest => 'بہترین تسلسل';
	@override String get backupStatDays => 'مکمل دن';
	@override String get backupStatFavorites => 'محفوظ دعائیں';
	@override String get backupStatCustom => 'میری دعائیں';
	@override String get backupStatQuran => 'قرآن کے بک مارکس';
	@override String get restoreTitle => 'یہ بیک اپ بحال کریں؟';
	@override String restoreSavedOn({required Object date}) => '${date} کو محفوظ کیا گیا';
	@override String restoreSavedOnVersion({required Object date, required Object version}) => '${date} کو محفوظ کیا گیا · v${version}';
	@override String get restoreScopeEverything => 'سب کچھ';
	@override String get restoreScopeEverythingSub => 'پیش رفت اور ترتیبات';
	@override String get restoreScopeProgress => 'صرف پیش رفت';
	@override String get restoreScopeProgressSub => 'اس فون کا مقام، یاد دہانیاں اور زبان برقرار رکھیں';
	@override String get restoreWarning => 'اس آلے کی موجودہ معلومات بدل جائیں گی۔';
	@override String get restoreAction => 'بحال کریں';
	@override String restoreDone({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ur'))(n,
		one: '1 اندراج بحال ہوا',
		other: '${n} اندراجات بحال ہوئے',
	);
	@override String get backupSaved => 'بیک اپ محفوظ کرنے کے لیے تیار ہے';
	@override String get backupFailed => 'بیک اپ نہیں بنایا جا سکا';
	@override String get restoreErrMalformed => 'یہ فائل پڑھی نہیں جا سکی۔';
	@override String get restoreErrNotABackup => 'یہ Hisn کی بیک اپ فائل نہیں ہے۔';
	@override String get restoreErrTooNew => 'یہ بیک اپ Hisn کے نئے نسخے سے بنایا گیا تھا۔ پہلے ایپ تازہ کریں۔';
	@override String get restoreErrEmpty => 'اس بیک اپ میں بحالی کے لیے کچھ نہیں ہے۔';
	@override String get restoreFailed => 'بحالی نہیں ہو سکی۔ کوئی تبدیلی نہیں ہوئی۔';
	@override String get quranZoomIn => 'بڑا کریں';
	@override String get quranZoomHint => 'بڑا کرنے کے لیے دو انگلیاں پھیلائیں؛ واپس آنے کے لیے انہیں قریب لائیں۔';
	@override String get quranReaderOptions => 'تلاوت کے اختیارات';
	@override String get versesOnThisPage => 'اس صفحے کی آیات';
	@override String get savedVerses => 'محفوظ آیات';
	@override String get savedPages => 'محفوظ صفحات';
	@override String get saveVerse => 'آیت محفوظ کریں';
	@override String get unsaveVerse => 'محفوظ آیت ہٹائیں';
	@override String get secCalendar => 'اسلامی تقویم';
	@override String get calendarSub => 'سنت روزے اور ہجری مواقع';
	@override String get sunnahCalendarTitle => 'روزے اور مواقع';
	@override String get upcomingLabel => 'آنے والے';
	@override String get nothingUpcoming => 'اگلے دو ماہ میں کوئی نشان زد موقع نہیں۔';
	@override String get calendarNote => 'تاریخیں ام القریٰ کے حساب سے ہیں اور مقامی رؤیت سے ایک دن مختلف ہو سکتی ہیں۔';
	@override String get fastingRecommended => 'سنت روزہ';
	@override String get fastingObligatory => 'فرض روزہ';
	@override String get fastingForbidden => 'روزہ رکھنے کا دن نہیں';
	@override String get fastingNoneToday => 'آج کوئی مخصوص روزہ نہیں۔';
	@override String get fastRamadan => 'رمضان';
	@override String get fastMonday => 'پیر کا روزہ';
	@override String get fastThursday => 'جمعرات کا روزہ';
	@override String get fastWhiteDay => 'ایام بیض';
	@override String get fastTasua => 'تاسوعاء';
	@override String get fastAshura => 'عاشوراء';
	@override String get fastDhulHijjah => 'ذوالحجہ کے دس دن';
	@override String get fastArafah => 'یوم عرفہ';
	@override String get fastSixOfShawwal => 'شوال کے چھ روزے';
	@override String get fastRamadanSub => 'اس مہینے کے فرض روزے۔';
	@override String get fastMondaySub => 'اعمال پیر اور جمعرات کو پیش کیے جاتے ہیں۔ — ترمذی';
	@override String get fastThursdaySub => 'اعمال پیر اور جمعرات کو پیش کیے جاتے ہیں۔ — ترمذی';
	@override String get fastWhiteDaySub => 'ہر ہجری مہینے کی 13، 14 اور 15 تاریخ۔ — بخاری اور مسلم';
	@override String get fastTasuaSub => 'دس محرم کے ساتھ رکھا جاتا ہے۔ — مسلم';
	@override String get fastAshuraSub => 'گزشتہ سال کے گناہوں کا کفارہ ہے۔ — مسلم';
	@override String get fastDhulHijjahSub => 'نیک اعمال کے لیے اللہ کو ان دنوں سے زیادہ محبوب دن نہیں۔ — بخاری';
	@override String get fastArafahSub => 'حج پر نہ جانے والوں کے لیے گزشتہ اور آئندہ سال کے گناہوں کا کفارہ ہے۔ — مسلم';
	@override String get fastSixOfShawwalSub => 'رمضان کے بعد شوال کے چھ روزے رکھنا پورے سال کے روزوں کے مانند ہے۔ — مسلم';
	@override String get eventNewYear => 'اسلامی نیا سال';
	@override String get eventAshura => 'عاشوراء';
	@override String get eventRamadan => 'رمضان کا آغاز';
	@override String get eventLastTen => 'آخری دس راتیں';
	@override String get eventEidFitr => 'عید الفطر';
	@override String get eventDhulHijjah => 'ذوالحجہ کا آغاز';
	@override String get eventArafah => 'یوم عرفہ';
	@override String get eventEidAdha => 'عید الاضحیٰ';
	@override String get eventLastTenSub => 'ان دس راتوں کی طاق راتوں میں لیلۃ القدر تلاش کی جاتی ہے۔';
	@override String get barEidAlFitr => 'عید الفطر پر روزہ رکھنا جائز نہیں۔';
	@override String get barEidAlAdha => 'عید الاضحیٰ پر روزہ رکھنا جائز نہیں۔';
	@override String get barTashriq => 'ایام تشریق میں روزہ رکھنا جائز نہیں۔';
	@override String get hijriAdjust => 'ہجری تاریخ کی درستگی';
	@override String get hijriAdjustHint => 'حساب شدہ تاریخ مقامی رؤیت سے ایک دن آگے یا پیچھے ہو سکتی ہے۔ اسے اپنی جماعت کے مطابق درست کریں۔';
	@override List<String> get hijriOffsetLabels => [
		'−2 دن',
		'−1 دن',
		'کوئی تبدیلی نہیں',
		'+1 دن',
		'+2 دن',
	];
	@override String get fastingReminders => 'روزے کی یاد دہانیاں';
	@override String get fastingRemindersSub => 'سنت روزے سے ایک شام پہلے یاد دہانی';
	@override String get notifFastTitle => 'کل روزہ';
	@override String notifFastBody({required Object name}) => 'کل ${name} ہے — سنت روزے کا موقع۔';
	@override String get notifOccasionBody => 'کل، ان شاء اللہ۔';
	@override String get share => 'شیئر کریں';
	@override String get shareAsImage => 'تصویر شیئر کریں';
	@override String get shareAsText => 'متن شیئر کریں';
	@override String get shareImageFailedNotReady => 'تصویر تیار نہیں تھی؛ متن شیئر کیا جا رہا ہے۔';
	@override String get shareImageFailedUnsupported => 'یہ آلہ تصویر نہیں بنا سکا؛ متن شیئر کیا جا رہا ہے۔';
	@override String get nextPhraseOnTap => 'ذکر مکمل ہوا۔ اگلا ذکر گننے کے لیے دبائیں۔';
	@override String get aboutContributors => 'حصن کے پیچھے لوگ';
	@override String get aboutDeveloperCredit => 'ڈویلپر · ایپ کو ڈیزائن کیا اور تیار کیا۔';
	@override String get aboutContentReviewerCredit => 'معاون · ایپ کے مواد میں املا کی غلطیوں اور غلط معلومات کی نشاندہی کے لیے جائزے میں مدد کی۔';
	@override String get aboutProfileLinkCopied => 'GitHub پروفائل کا ربط نقل ہو گیا۔ اسے اپنے براؤزر میں کھولیں۔';
	@override String get aboutTypefaces => 'خطوط';
	@override String get aboutVerseMeanings => 'آیات کے معانی';
	@override String get aboutDuaDraftCredit => 'دعاؤں کے بعض معانی Hisn منصوبے کے مسودے ہیں؛ مستند لسانی اور دینی نظرثانی باقی ہے۔';
	@override String get aboutTranslationSource => 'ترجمے کے مآخذ · تنزیل';
	@override String get aboutLinkCopied => 'ماخذ کا ربط نقل ہو گیا۔ اسے اپنے براؤزر میں کھولیں۔';
	@override String get aboutArabicText => 'عربی متن';
	@override String get aboutLatinText => 'لاطینی متن';
	@override String get aboutLatinApparatus => 'لاطینی انٹرفیس کا متن';
	@override String get aboutMushafPages => 'مصحف کے صفحات · مجمع ملک فہد برائے طباعت قرآن کریم';
	@override String get prayerCountdownTitle => 'اگلی نماز کی الٹی گنتی';
	@override String get prayerCountdownSubtitle => 'اگلی نماز، اذان کے بعد کا وقت اور ہجری تاریخ اپنی اطلاعات میں رکھیں۔';
	@override String get prayerCountdownUnavailable => 'اینڈرائیڈ پر دستیاب ہے۔ الٹی گنتی کی شکل نظام طے کرتا ہے۔';
	@override String get prayerCountdownChannelDescription => 'اگلی نماز تک خاموش الٹی گنتی';
	@override String get guideTitle => 'مختصر رہنما';
	@override String get guideWelcomeTitle => 'حصن ایپ سے واقف ہوں';
	@override String get guideWelcomeBody => 'تسبیح، قرآن کی تلاش، نماز کے اوزار، ظاہری شکل اور یاد دہانیوں کی ترتیبات کی جگہ جانیں۔ یہ رہنما ترتیبات میں دوبارہ کھولا جا سکتا ہے۔';
	@override String get viewGuide => 'رہنما دیکھیں';
	@override String get replayGuide => 'ایپ کا رہنما دیکھیں';
	@override String get replayGuideSub => 'اہم خصوصیات کی رہنمائی';
	@override String get guideDone => 'مکمل';
	@override String guideProgress({required Object total, required Object current}) => '${total} میں سے ${current}';
	@override String get guideTasbihBody => 'ذکر منتخب کرنے، اپنا ذکر شامل کرنے اور تکرار گننے کے لیے تسبیح کھولیں۔';
	@override String get guideQuranBody => 'سورت تلاش کریں یا قرآن کی آیات ڈھونڈنے کے لیے عربی الفاظ لکھیں۔';
	@override String get guidePrayerBody => 'نماز کے اوقات اور قبلہ یہاں ملیں گے۔ مقام تک رسائی کی اجازت نماز کی ترتیبات میں منتخب کی جا سکتی ہے۔';
	@override String get guideAppearanceBody => 'یہاں روشن، تاریک یا نظام کا انداز منتخب کریں۔ رنگ منتخب کرنے کے لیے اسی مینو میں ظاہری شکل کھولیں۔';
	@override String get guideNotificationsBody => 'اطلاعات میں یاد دہانیاں اور اذان منتخب کریں، خاموش اوقات مقرر کریں یا تمام یاد دہانیاں عارضی طور پر روکیں۔ اجازتیں صرف اپنی مرضی سے فعال کریں۔';
	@override String get prayerSilenceTitle => 'نماز کے وقت خاموشی';
	@override String get prayerSilenceSub => 'اذان کے بعد خودکار خاموش وقفہ';
	@override String get prayerSilenceEnable => 'نماز کے وقت خاموشی فعال کریں';
	@override String get prayerSilenceBody => 'ہر اذان کے بعد اپنی منتخب مدت میں کالیں اور اطلاعات خاموش کریں۔ الارم کی اجازت برقرار رہتی ہے۔ ڈو ناٹ ڈسٹرب کے دوسرے موڈ زیادہ سخت پابندیاں لگا سکتے ہیں۔';
	@override String get prayerSilenceTimingHint => 'آغاز اور اختتام اذان کے بعد منٹوں میں ہیں۔ اگر Hisn اذان چلا رہا ہو تو خاموشی اس کے ختم ہونے تک انتظار کرے گی؛ اختتامی وقت وہی رہے گا۔';
	@override String get prayerSilenceStart => 'اذان کے بعد آغاز';
	@override String get prayerSilenceEnd => 'اذان کے بعد اختتام';
	@override String prayerSilenceMinutes({required Object minutes}) => '${minutes} منٹ';
	@override String get prayerSilencePolicyButton => 'ڈو ناٹ ڈسٹرب کی رسائی دیں';
	@override String get prayerSilenceExactButton => 'درست اوقات کی اجازت دیں';
	@override String get prayerSilenceDisabled => 'نماز کے وقت خاموشی بند ہے';
	@override String get prayerSilencePermission => 'نماز کے وقت خاموشی کے لیے ڈو ناٹ ڈسٹرب کی رسائی دیں۔';
	@override String get prayerSilenceExact => 'موقوف: وقت پر آغاز اور اختتام کے لیے درست الارم کی رسائی درکار ہے۔';
	@override String get prayerSilenceLocation => 'نماز کے وقفوں کے حساب کے لیے شہر منتخب کریں یا مقام کی اجازت دیں۔';
	@override String get prayerSilenceReady => 'اگلی نماز کے وقفے کے لیے تیار';
	@override String prayerSilenceActiveUntil({required Object time}) => 'نماز کی خاموشی ${time} تک فعال ہے';
	@override String get prayerSilenceWaiting => 'اذان ختم ہونے کا انتظار ہے';
	@override String get prayerSilenceRuleDisabled => 'Android کی ترتیبات میں Hisn کا نماز موڈ بند ہے۔';
	@override String get prayerSilenceUnavailable => 'نماز کے وقت خاموشی صرف Android پر دستیاب ہے۔';
	@override String get prayerSilenceError => 'نماز کی خاموشی مقرر نہیں ہو سکی۔ رسائی دیکھ کر دوبارہ کوشش کریں۔';
	@override String get prayerSilenceStopNow => 'یہ خاموش وقفہ ختم کریں';
	@override String get prayerSilenceExpiryNote => 'صرف Hisn کا موڈ خودکار ختم ہوتا ہے؛ آپ کا اپنا ڈو ناٹ ڈسٹرب تبدیل نہیں ہوتا۔ درست الارم کی رسائی واپس لینے یا ایپ محدود ہونے پر Android اختتام کی متبادل جانچ میں تاخیر کر سکتا ہے۔';
	@override String get qiblaStyle => 'قطب نما کا انداز';
	@override String get qiblaTone => 'قطب نما کا رنگ';
	@override String get qiblaVibrationOn => 'ارتعاش فعال';
	@override String get qiblaVibrationOff => 'ارتعاش بند';
	@override List<String> get qiblaStyles => [
		'کلاسیکی',
		'سادہ',
		'قطب نما پھول',
	];
	@override List<String> get qiblaTones => [
		'تھیم کا رنگ',
		'سنہری',
		'سیاہی',
	];
	@override String durationMinutes({required Object minutes}) => '${minutes} منٹ';
	@override String durationHoursMinutes({required Object hours, required Object minutes}) => '${hours} گھنٹے ${minutes} منٹ';
}

/// The flat map containing all translations for locale <ur>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsUr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'navAdhkar' => 'اذکار',
			'navQuran' => 'قرآن',
			'navTasbih' => 'تسبیح',
			'navQibla' => 'قبلہ',
			'navSaved' => 'محفوظ',
			'navSettings' => 'ترتیبات',
			'navPrayer' => 'نماز',
			'prayerQiblaTitle' => 'نماز اور قبلہ',
			'weeklySchedule' => 'ہفتہ وار اوقات',
			'searchDuas' => 'دعائیں تلاش کریں…',
			'allAdhkar' => 'تمام اذکار',
			'groupDaily' => 'روزانہ کے اذکار',
			'groupSituational' => 'مختلف مواقع کے لیے',
			'groupMine' => 'میرے اذکار',
			'muhassanHeading' => 'محصّن',
			'muhassanToday' => ({required Object percent}) => 'آج آپ کی تکمیل ${percent}% ہے',
			'muhassanComplete' => 'مکمل — ما شاء اللہ',
			'muhassanMorning' => 'صبح',
			'muhassanEvening' => 'شام',
			'streakDays' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ur'))(n, one: 'مسلسل 1 دن', other: 'مسلسل ${n} دن', ), 
			'streakStart' => 'اپنا تسلسل شروع کریں',
			'streakBest' => ({required Object n}) => 'بہترین: ${n}',
			'streakTitle' => 'آپ کا تسلسل',
			'streakWord' => 'دن کا تسلسل',
			'statCurrent' => 'موجودہ',
			'statBest' => 'بہترین',
			'statTotal' => 'کل دن',
			'daysValue' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ur'))(n, one: '1 دن', other: '${n} دن', ), 
			'streakOnFire' => 'آپ کا تسلسل بہت اچھا ہے — جاری رکھیں!',
			'streakTodayPending' => 'تسلسل بڑھانے کے لیے آج کے اذکار مکمل کریں',
			'streakBroken' => 'دوبارہ شروع کرنے کے لیے صبح اور شام کے اذکار مکمل کریں',
			'last4Weeks' => 'گزشتہ 4 ہفتے',
			'todayLabel' => 'آج',
			'fortifiedLegend' => 'مکمل',
			'weekdayLetters.0' => 'پ',
			'weekdayLetters.1' => 'م',
			'weekdayLetters.2' => 'ب',
			'weekdayLetters.3' => 'ج',
			'weekdayLetters.4' => 'ج',
			'weekdayLetters.5' => 'ہ',
			'weekdayLetters.6' => 'ا',
			'quranTitle' => 'قرآن',
			'searchSurah' => 'سورت تلاش کریں…',
			'searchQuran' => 'سورت یا عربی الفاظ تلاش کریں',
			'quranSearchSurahs' => 'سورتیں',
			'quranSearchVerses' => 'آیات',
			'quranSearchFailed' => 'آیات تلاش نہیں ہو سکیں۔ دوبارہ کوشش کریں۔',
			'quranSearchLimit' => 'آیات کے پہلے 50 نتائج دکھائے جا رہے ہیں',
			'retrySearch' => 'دوبارہ تلاش کریں',
			'afterPrayerTasbih' => 'نماز کے بعد تسبیح',
			'startAfterPrayerTasbih' => 'نماز کے بعد کے اذکار گنیں',
			'currentPhrase' => 'موجودہ ذکر',
			'afterPrayerComplete' => 'نماز کے بعد کے اذکار مکمل ہو گئے ہیں۔',
			'continueReading' => 'پڑھنا جاری رکھیں',
			'surahWord' => 'سورت',
			'revelationMeccan' => 'مکی',
			'revelationMedinan' => 'مدنی',
			'versesCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ur'))(n, one: '1 آیت', other: '${n} آیات', ), 
			'juzLabel' => ({required Object n}) => 'پارہ ${n}',
			'quranBookmarks' => 'بک مارکس',
			'noBookmarks' => 'ابھی کوئی بک مارک نہیں',
			'bookmarkAdded' => 'بک مارک محفوظ ہو گیا',
			'bookmarkRemoved' => 'بک مارک ہٹا دیا گیا',
			'goToAyah' => 'آیت پر جائیں',
			'chooseSurah' => 'سورت',
			'verseNumber' => 'آیت نمبر',
			'verseRange' => ({required Object n}) => '1–${n}',
			'goAction' => 'جائیں',
			'myDuas' => 'میری دعائیں',
			'myDuasSub' => 'آپ کی شامل کردہ دعائیں',
			'addDua' => 'دعا شامل کریں',
			'newDua' => 'نئی دعا',
			'fieldArabic' => 'عربی متن',
			'fieldArabicRequired' => 'عربی متن درج کریں',
			'fieldTitle' => 'عنوان (اختیاری)',
			'fieldTransliteration' => 'تلفظ (اختیاری)',
			'fieldTranslation' => 'ترجمہ / مفہوم (اختیاری)',
			'fieldReference' => 'حوالہ (اختیاری)',
			'fieldRepeat' => 'تعداد',
			'fieldRepeatPositiveRequired' => '1 یا اس سے بڑی صحیح تعداد درج کریں۔',
			'addDhikr' => 'ذکر شامل کریں',
			'editDhikr' => 'ذکر میں ترمیم کریں',
			'deleteDhikr' => 'ذکر حذف کریں',
			'deleteDhikrConfirm' => 'یہ ذکر اور اس کی محفوظ گنتی حذف کر دیں؟',
			'fieldDhikrName' => 'نام',
			'fieldDhikrNameRequired' => 'اس ذکر کا نام درج کریں۔',
			'fieldDhikrTargetRequired' => '1 سے 1,000,000 تک صحیح تعداد درج کریں۔',
			'nextSetOnTap' => 'دور مکمل ہوا۔ اگلا دور شروع کرنے کے لیے دبائیں۔',
			'customDhikrTargetNote' => 'اپنی نشست کے لیے تکرار کی تعداد منتخب کریں۔',
			'save' => 'محفوظ کریں',
			'cancel' => 'منسوخ کریں',
			'delete' => 'حذف کریں',
			'deleteDua' => 'دعا حذف کریں',
			'deleteDuaConfirm' => 'یہ دعا میری دعاؤں سے حذف کر دیں؟',
			'duaSaved' => 'دعا محفوظ ہو گئی',
			'duaUpdated' => 'دعا کی ترمیم محفوظ ہو گئی',
			'editDua' => 'دعا میں ترمیم کریں',
			'edit' => 'ترمیم',
			'noCustomTitle' => 'ابھی کوئی دعا نہیں',
			'noCustomBody' => 'اپنی دعا شامل کرنے کے لیے + دبائیں۔',
			'recommendedNow' => 'اس وقت کے لیے',
			'readNow' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ur'))(count, one: 'ابھی پڑھیں · 1 دعا', other: 'ابھی پڑھیں · ${count} دعائیں', ), 
			'duaCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ur'))(count, one: '1 دعا', other: '${count} دعائیں', ), 
			'now' => 'ابھی',
			'next' => 'اگلی',
			'remaining' => 'باقی',
			'countdownNow' => 'ابھی',
			'sinceAdhan' => 'اذان کے بعد سے',
			'todaysPrayers' => ({required Object location}) => 'آج کی نمازیں · ${location}',
			'searchHint' => 'دعائیں، معانی یا حوالے تلاش کریں…',
			'clear' => 'صاف کریں',
			'searchPrompt' => 'عنوان، مفہوم، تلفظ یا حوالے سے تلاش کریں۔',
			'noResults' => ({required Object query}) => '“${query}” کے لیے کوئی دعا نہیں ملی۔',
			'quranNoResults' => ({required Object query}) => '“${query}” کے لیے کوئی سورت یا آیت نہیں ملی۔',
			'resultsCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ur'))(n, one: '1 نتیجہ', other: '${n} نتائج', ), 
			'noSavedTitle' => 'ابھی کوئی دعا محفوظ نہیں',
			'noSavedBody' => 'فوری رسائی کے لیے کسی دعا کا بک مارک دبائیں۔',
			'resetCount' => 'گنتی صفر کریں',
			'tapToCount' => 'گنتی کے لیے کہیں بھی دبائیں',
			'setsCompleted' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ur'))(n, one: '1 دور مکمل', other: '${n} دور مکمل', ), 
			'ofTarget' => ({required Object n}) => 'کل ${n} میں سے',
			'resetProgress' => 'پیش رفت از سر نو شروع کریں',
			'setComplete' => 'دور مکمل — تقبّل اللہ',
			'tapEachDua' => 'ہر دعا کی تکرار گننے کے لیے اسے دبائیں',
			'listenAction' => 'سنیں',
			'listenStart' => 'اذکار چلائیں',
			'listenRestart' => 'شروع سے دوبارہ چلائیں',
			'listenHint' => 'تلاوت جاری ہے — آپ فون لاک کر سکتے ہیں',
			'listenIdleTitle' => 'کچھ نہیں چل رہا',
			'listenIdleBody' => 'اذکار چلائیں؛ ہر تکرار کی گنتی خود بخود ہو گی۔',
			'listenMissing' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ur'))(n, one: '1 دعا کی ریکارڈنگ ابھی موجود نہیں', other: '${n} دعاؤں کی ریکارڈنگ ابھی موجود نہیں', ), 
			'listenPrevious' => 'پچھلا ذکر',
			'listenNext' => 'اگلا ذکر',
			'listenPause' => 'وقفہ کریں',
			'listenResume' => 'جاری رکھیں',
			'secListen' => 'سماعت',
			'listenSub' => 'ہاتھ استعمال کیے بغیر اذکار سنیں',
			'listenGap' => 'تکرار کے درمیان وقفہ',
			'listenGapLabels.0' => 'بغیر وقفے',
			'listenGapLabels.1' => '1 سیکنڈ',
			'listenGapLabels.2' => '2 سیکنڈ',
			'listenGapLabels.3' => '3 سیکنڈ',
			'listenAppendix' => 'طویل ذکر شامل کریں',
			'listenAppendixSub' => 'آخر میں 100 بار تہلیل اور تسبیح شامل کریں۔ تقریباً 20 منٹ۔',
			'listenKeepScreenOn' => 'اسکرین روشن رکھیں',
			'listenKeepScreenOnSub' => 'مصروف ہاتھوں کے ساتھ پڑھنے کے لیے۔ بند ہو تو فون سو جاتا ہے مگر تلاوت جاری رہتی ہے۔',
			'listenReciter' => 'قاری',
			'duaCopied' => 'دعا نقل ہو گئی',
			'removeBookmark' => 'بک مارک ہٹائیں',
			'bookmark' => 'بک مارک',
			'copy' => 'نقل کریں',
			'done' => 'مکمل',
			'settings' => 'ترتیبات',
			'secPrayerTimes' => 'نماز کے اوقات',
			'secReminders' => 'یاد دہانیاں',
			'secDisplay' => 'نمائش',
			'secLanguage' => 'زبان',
			'secAbout' => 'تعارف',
			'location' => 'مقام',
			'locYourLocationGps' => 'آپ کا مقام (GPS)',
			'locDeviceGps' => ({required Object label}) => 'آلے کا GPS · ${label}',
			'locFixedCity' => ({required Object label}) => '${label} (مقررہ شہر)',
			'calcMethod' => 'حساب کا طریقہ',
			'asrCalc' => 'عصر کا حساب',
			'nightTimes' => 'رات کے اوقات',
			'showMidnight' => 'آدھی رات دکھائیں',
			'showMidnightSub' => 'مغرب اور فجر کے درمیان کا نصف',
			'showLastThird' => 'رات کا آخری تہائی دکھائیں',
			'showLastThirdSub' => 'مغرب اور فجر کے درمیان آخری تہائی کا آغاز: تہجد کا وقت',
			'notifications' => 'اطلاعات',
			'prayerReminders' => 'نماز کی یاد دہانیاں',
			'prayerRemindersSub' => 'ہر نماز کے وقت اطلاع پائیں',
			'dailyRemembrance' => 'روزانہ کے اذکار',
			'dailyRemembranceSub' => 'صبح اور شام کے اذکار کی تکمیل تک یاد دہانی، نیز جمعہ اور رات کی سنتیں',
			'adhanSound' => 'اذان کی آواز',
			'adhanSoundSub' => 'ہر نماز کے وقت اذان چلائیں',
			'adhanNeedsReminders' => 'نماز کے وقت اذان کے لیے اوپر نماز کی یاد دہانیاں فعال کریں۔',
			'adhanExactAlarmsOff' => 'نماز کے وقت اذان کے لیے Hisn کو الارم اور یاد دہانیوں کی اجازت دیں۔',
			'allowAlarms' => 'اجازت دیں',
			'adhanFlipToSilence' => 'الٹا کر کے خاموش کریں',
			'adhanFlipToSilenceSub' => 'چلتی اذان روکنے کے لیے فون کو الٹا رکھ دیں۔ آواز کا کوئی بھی بٹن دبانے سے بھی اذان رک جاتی ہے۔',
			'adhanVolume' => 'اذان کی آواز کا کنٹرول',
			'streamLabels.0' => 'میڈیا',
			'streamLabels.1' => 'رنگر / اطلاعات',
			'streamLabels.2' => 'الارم',
			'streamHints.0' => 'میڈیا: فون کا موسیقی اور ویڈیو کی آواز والا کنٹرول استعمال ہوتا ہے۔ خاموش رنگر اسے لازماً بند نہیں کرتا؛ میڈیا کی آواز اور ڈو ناٹ ڈسٹرب کی ترتیب بھی دیکھیں۔',
			'streamHints.1' => 'رنگر: فون کا رنگ ٹون یا اطلاعات کی آواز والا کنٹرول استعمال ہوتا ہے۔ خاموش یا وائبریشن موڈ اور ڈو ناٹ ڈسٹرب اذان کو خاموش کر سکتے ہیں۔',
			'streamHints.2' => 'الارم: فون کا الارم کی آواز والا کنٹرول استعمال ہوتا ہے۔ خاموش رنگر عموماً اسے بند نہیں کرتا؛ ڈو ناٹ ڈسٹرب میں الارم کی اجازت بھی دیکھیں۔',
			'previewAdhan' => 'اذان سن کر دیکھیں',
			'stopAdhan' => 'اذان بند کریں',
			'adhanVoice' => 'اذان کی آواز',
			'adhanVoiceDefault' => 'ایپ کی اپنی اذان',
			'adhanVoiceCustom' => 'آپ کی اپنی آڈیو فائل',
			'adhanVoiceCustomHint' => 'ہر نماز کے لیے چلے گی، فجر سمیت',
			'adhanVoiceChooseFile' => 'فائل منتخب کریں…',
			'adhanVoiceChangeFile' => 'دوسری فائل منتخب کریں',
			'adhanVoiceUnreadable' => 'یہ فائل پڑھی نہیں جا سکی۔',
			'adhanVoiceTooLarge' => 'فائل بہت بڑی ہے۔ 20 MB سے چھوٹی آڈیو فائل منتخب کریں۔',
			'adhanVoiceNotPlayable' => 'یہ فائل چل نہیں سکی۔ MP3 یا OGG جیسی آڈیو فائل منتخب کریں۔',
			'adhanPlaying' => 'اذان چل رہی ہے…',
			'notifBlocked' => 'اطلاعات بند ہیں۔ فون کی ترتیبات میں Hisn کی اطلاعات فعال کریں۔',
			'textSize' => 'متن کا سائز',
			'fontScaleLabels.0' => 'چھوٹا',
			'fontScaleLabels.1' => 'معمول',
			'fontScaleLabels.2' => 'بڑا',
			'fontScaleLabels.3' => 'بہت بڑا',
			'showTransliteration' => 'تلفظ دکھائیں',
			'showTransliterationSub' => 'لاطینی حروف میں ادائیگی',
			'showTranslation' => 'ترجمہ دکھائیں',
			'showTranslationSub' => 'اردو مفہوم',
			'aboutBody' => 'دعاؤں اور اذکار کا ساتھی · ابتدائی نسخہ\nنماز کے اوقات Adhan لائبریری سے۔',
			'automatic' => 'خودکار',
			'useDeviceLocation' => 'میرے آلے کا مقام استعمال کریں',
			'gpsActive' => 'فعال · اوقات آپ کے مقام کے مطابق ہیں',
			'gpsDetect' => 'GPS سے مقام معلوم کریں (اجازت درکار ہے)',
			'chooseCity' => 'شہر منتخب کریں',
			'cityNote' => 'منتخب شہر کے اوقات فون کے موجودہ ٹائم زون میں دکھائے جاتے ہیں؛ شہر آپ کے علاقے میں ہو تو درست رہتے ہیں۔',
			'madhabStandard' => 'معمول (شافعی، مالکی، حنبلی)',
			'madhabHanafi' => 'حنفی',
			'asrHintStandard' => 'عصر اس وقت شروع ہوتی ہے جب کسی چیز کا سایہ اس کی لمبائی کے برابر ہو',
			'asrHintHanafi' => 'عصر اس وقت شروع ہوتی ہے جب کسی چیز کا سایہ اس کی لمبائی کا دوگنا ہو',
			'prayerFajr' => 'فجر',
			'prayerSunrise' => 'طلوع آفتاب',
			'markMidnight' => 'آدھی رات',
			'markLastThird' => 'آخری تہائی',
			'prayerDhuhr' => 'ظہر',
			'prayerAsr' => 'عصر',
			'prayerMaghrib' => 'مغرب',
			'prayerIsha' => 'عشاء',
			'prayerNone' => '—',
			'notifTitle' => ({required Object name}) => 'نماز ${name}',
			'notifBody' => ({required Object name, required Object place}) => 'نماز ${name} کا وقت ہے — ${place}۔',
			'notifIqamahBody' => ({required Object name, required Object place}) => 'نماز ${name} کی اقامت — ${place}۔',
			'iqamahOffset' => 'اقامت کا وقفہ',
			'iqamahAtAdhan' => 'اذان کے وقت',
			'iqamahPlusMinutes' => ({required Object minutes}) => '+${minutes} منٹ',
			'testNotifTitle' => 'آزمائشی یاد دہانی',
			'testNotifBody' => 'اگر یہ اطلاع نظر آ رہی ہے تو نماز کی یاد دہانیاں کام کر رہی ہیں۔ 🌙',
			'sendTestNotif' => 'آزمائشی اطلاع بھیجیں',
			'testSent' => 'آزمائش بھیج دی گئی — ایک اطلاع ابھی اور دوسری 12 سیکنڈ بعد آئے گی (فون لاک کریں)۔',
			'testBlocked' => 'بھیج دی گئی، لیکن فون میں Hisn کی اطلاعات بند ہیں۔ ترتیبات ← ایپس ← Hisn ← اطلاعات میں فعال کریں۔',
			'batteryHint' => 'بعض فون (مثلاً Xiaomi/MIUI یا Samsung) ایپ بند ہونے پر مقررہ یاد دہانیاں روکتے ہیں۔ اگر یاد دہانی نہ آئے تو Hisn کے لیے خودکار آغاز اور بیٹری کا غیر محدود استعمال فعال کریں۔',
			'adhkarMorningTitle' => 'صبح کے اذکار',
			'adhkarMorningBody' => 'اپنی صبح کا آغاز اللہ کے ذکر سے کریں۔',
			'adhkarEveningTitle' => 'شام کے اذکار',
			'adhkarEveningBody' => 'اپنی شام اللہ کے ذکر کے ساتھ گزاریں۔',
			'kahfTitle' => 'سورۃ الکہف',
			'kahfBody' => 'آج جمعہ ہے — دو جمعوں کے درمیان نور کے لیے سورۃ الکہف پڑھیں۔',
			'salawatTitle' => 'نبی ﷺ پر درود بھیجیں',
			'salawatBody' => 'کچھ وقت نکال کر نبی ﷺ پر درود بھیجیں۔',
			'salawatFridayTitle' => 'نبی ﷺ پر درود بھیجیں',
			'salawatFridayBody' => 'آج جمعہ ہے — نبی ﷺ پر کثرت سے درود بھیجیں۔',
			'mulkTitle' => 'سورۃ الملک',
			'mulkBody' => 'سونے سے پہلے سورۃ الملک پڑھیں۔',
			'qiblaFromNorth' => ({required Object degrees}) => 'قبلہ · شمال سے ${degrees}°',
			'facingQibla' => 'آپ قبلہ رخ ہیں',
			'turnRight' => ({required Object degrees}) => '${degrees}° دائیں مڑیں',
			'turnLeft' => ({required Object degrees}) => '${degrees}° بائیں مڑیں',
			'calibrateHint' => 'درستگی کے لیے فون کو 8 کی شکل میں حرکت دیں',
			'qiblaHoldFlat' => 'قطب نما پڑھنے کے لیے فون ہموار رکھیں',
			'qiblaInterference' => 'دھات یا مقناطیس سے دور ہو جائیں',
			'qiblaTrueNorth' => 'حقیقی شمال کے مطابق درست کیا گیا',
			'qiblaMagneticOnly' => 'مقناطیسی شمال — درستگی کی معلومات دستیاب نہیں',
			'compassUnavailable' => 'قطب نما دستیاب نہیں',
			'compassUnavailableBody' => 'اس آلے میں مقناطیسی حسّاس نہیں، اس لیے قبلے کی متحرک سوئی نہیں دکھائی جا سکتی۔',
			'qiblaNoLocation' => 'مقام درکار ہے',
			'qiblaNoLocationBody' => 'مقام معلوم ہوئے بغیر قبلے کی سمت کا حساب نہیں ہو سکتا۔ مقام کی خدمات فعال کریں یا ترتیبات میں شہر منتخب کریں۔',
			'placeYourLocation' => 'آپ کا مقام',
			'placeSelectedCity' => 'منتخب شہر',
			'placeMakkah' => 'مکہ',
			'onboardSkip' => 'چھوڑیں',
			'onboardNext' => 'اگلا',
			'onboardGetStarted' => 'شروع کریں',
			'onboardWelcomeTitle' => 'Hisn میں خوش آمدید',
			'onboardWelcomeBody' => 'ذکر، قرآن اور نماز کا روزانہ ساتھی۔ شروع کرنے کے لیے مختصر تعارف دیکھیں۔',
			'onboardAdhkarTitle' => 'اذکار اور دعائیں',
			'onboardAdhkarBody' => 'صبح اور شام کے اذکار، تسبیح کا شمار اور آپ کی اپنی دعائیں۔ ہر دعا کی تکرار گننے کے لیے اسے دبائیں۔',
			'onboardQuranTitle' => 'قرآن کریم',
			'onboardQuranBody' => 'مکمل قرآن مصحف میں پڑھیں، جہاں چھوڑا تھا وہیں سے جاری رکھیں، اور پسندیدہ آیات محفوظ کریں۔',
			'onboardPrayerTitle' => 'نماز اور قبلہ',
			'onboardPrayerBody' => 'آپ کے مقام کے مطابق نماز کے اوقات، اگلی نماز تک باقی وقت اور قبلے کی سمت دکھانے والا قطب نما۔',
			'onboardPermsTitle' => 'چند اجازتیں',
			'onboardPermsBody' => 'بہتر کارکردگی کے لیے یہ اجازتیں دیں۔ انہیں ترتیبات میں کبھی بھی بدل سکتے ہیں۔',
			'onboardLocationTitle' => 'مقام',
			'onboardLocationBody' => 'آپ کے مقام کے مطابق نماز کے اوقات اور قبلے کی سمت کے حساب کے لیے۔',
			'onboardLocationAction' => 'مقام کی اجازت دیں',
			'onboardNotifTitle' => 'اطلاعات',
			'onboardNotifBody' => 'ہر نماز کے وقت نرم یاد دہانی۔',
			'onboardNotifAction' => 'یاد دہانیاں فعال کریں',
			'onboardGranted' => 'فعال',
			'secAppearance' => 'ظاہری انداز',
			'appearanceColors' => 'رنگوں کا مجموعہ',
			'appearanceTheme' => 'تھیم',
			'themeLight' => 'روشن',
			'themeDark' => 'تاریک',
			'themeSystem' => 'آلے کے مطابق',
			'paletteQibla' => 'قبلہ اور پیتل',
			'paletteEmerald' => 'زمردی اور سنہری',
			'paletteSapphire' => 'نیلمی اور آسمانی',
			'paletteAmethyst' => 'بنفشی اور گلابی',
			'paletteRosewood' => 'گلابی لکڑی',
			'paletteLagoon' => 'لاجوردی',
			'paletteDesert' => 'صحرائی',
			'arabicFont' => 'عربی خط',
			'readingTheme' => 'پڑھنے کا پس منظر',
			'readingSystem' => 'ایپ کے مطابق',
			'readingSepia' => 'سیپیا',
			'readingNight' => 'رات',
			'patterns' => 'ہندسی نقش',
			'patternsSub' => 'عنوانات اور شمار میں ہلکی آرائش',
			'ampm.0' => 'قبل دوپہر',
			'ampm.1' => 'بعد دوپہر',
			'weekdaysShort.0' => 'پیر',
			'weekdaysShort.1' => 'منگل',
			'weekdaysShort.2' => 'بدھ',
			'weekdaysShort.3' => 'جمعرات',
			'weekdaysShort.4' => 'جمعہ',
			'weekdaysShort.5' => 'ہفتہ',
			'weekdaysShort.6' => 'اتوار',
			'monthsShort.0' => 'جنوری',
			'monthsShort.1' => 'فروری',
			'monthsShort.2' => 'مارچ',
			'monthsShort.3' => 'اپریل',
			'monthsShort.4' => 'مئی',
			'monthsShort.5' => 'جون',
			'monthsShort.6' => 'جولائی',
			'monthsShort.7' => 'اگست',
			'monthsShort.8' => 'ستمبر',
			'monthsShort.9' => 'اکتوبر',
			'monthsShort.10' => 'نومبر',
			'monthsShort.11' => 'دسمبر',
			'dateFormat' => ({required Object weekday, required Object day, required Object month}) => '${weekday}، ${day} ${month}',
			'hijriMonths.0' => 'محرم',
			'hijriMonths.1' => 'صفر',
			'hijriMonths.2' => 'ربیع الاول',
			'hijriMonths.3' => 'ربیع الآخر',
			'hijriMonths.4' => 'جمادی الاول',
			'hijriMonths.5' => 'جمادی الآخر',
			'hijriMonths.6' => 'رجب',
			'hijriMonths.7' => 'شعبان',
			'hijriMonths.8' => 'رمضان',
			'hijriMonths.9' => 'شوال',
			'hijriMonths.10' => 'ذوالقعدہ',
			'hijriMonths.11' => 'ذوالحجہ',
			'hijriDateFormat' => ({required Object day, required Object month, required Object year}) => '${day} ${month} ${year} ھ',
			'hijriSuffix' => 'ھ',
			'secBackup' => 'بیک اپ اور بحالی',
			'backupSub' => 'اپنی پیش رفت فائل میں محفوظ کریں',
			'backupOnThisDevice' => 'اس آلے پر',
			'backupSave' => 'بیک اپ محفوظ کریں',
			'backupSaveHint' => 'نیچے کی تمام معلومات ایک فائل میں لکھتا ہے جسے Drive یا Files میں رکھ سکتے ہیں یا خود کو بھیج سکتے ہیں۔',
			'backupRestoreHeading' => 'بحالی',
			'backupRestore' => 'فائل سے بحال کریں',
			'backupRestoreHint' => 'اس آلے کی معلومات کو بیک اپ فائل کی معلومات سے بدل دیتا ہے۔',
			'backupPrivacy' => 'بیک اپ سادہ متن کی فائل ہے۔ جب تک آپ خود نہ بھیجیں یہ آلے پر رہتی ہے؛ Hisn اسے اپ لوڈ نہیں کرتا۔',
			'backupStatStreak' => 'موجودہ تسلسل',
			'backupStatBest' => 'بہترین تسلسل',
			'backupStatDays' => 'مکمل دن',
			'backupStatFavorites' => 'محفوظ دعائیں',
			'backupStatCustom' => 'میری دعائیں',
			'backupStatQuran' => 'قرآن کے بک مارکس',
			'restoreTitle' => 'یہ بیک اپ بحال کریں؟',
			'restoreSavedOn' => ({required Object date}) => '${date} کو محفوظ کیا گیا',
			'restoreSavedOnVersion' => ({required Object date, required Object version}) => '${date} کو محفوظ کیا گیا · v${version}',
			'restoreScopeEverything' => 'سب کچھ',
			'restoreScopeEverythingSub' => 'پیش رفت اور ترتیبات',
			'restoreScopeProgress' => 'صرف پیش رفت',
			'restoreScopeProgressSub' => 'اس فون کا مقام، یاد دہانیاں اور زبان برقرار رکھیں',
			'restoreWarning' => 'اس آلے کی موجودہ معلومات بدل جائیں گی۔',
			'restoreAction' => 'بحال کریں',
			'restoreDone' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ur'))(n, one: '1 اندراج بحال ہوا', other: '${n} اندراجات بحال ہوئے', ), 
			'backupSaved' => 'بیک اپ محفوظ کرنے کے لیے تیار ہے',
			'backupFailed' => 'بیک اپ نہیں بنایا جا سکا',
			'restoreErrMalformed' => 'یہ فائل پڑھی نہیں جا سکی۔',
			'restoreErrNotABackup' => 'یہ Hisn کی بیک اپ فائل نہیں ہے۔',
			'restoreErrTooNew' => 'یہ بیک اپ Hisn کے نئے نسخے سے بنایا گیا تھا۔ پہلے ایپ تازہ کریں۔',
			'restoreErrEmpty' => 'اس بیک اپ میں بحالی کے لیے کچھ نہیں ہے۔',
			'restoreFailed' => 'بحالی نہیں ہو سکی۔ کوئی تبدیلی نہیں ہوئی۔',
			'quranZoomIn' => 'بڑا کریں',
			'quranZoomHint' => 'بڑا کرنے کے لیے دو انگلیاں پھیلائیں؛ واپس آنے کے لیے انہیں قریب لائیں۔',
			'quranReaderOptions' => 'تلاوت کے اختیارات',
			'versesOnThisPage' => 'اس صفحے کی آیات',
			'savedVerses' => 'محفوظ آیات',
			'savedPages' => 'محفوظ صفحات',
			'saveVerse' => 'آیت محفوظ کریں',
			'unsaveVerse' => 'محفوظ آیت ہٹائیں',
			'secCalendar' => 'اسلامی تقویم',
			'calendarSub' => 'سنت روزے اور ہجری مواقع',
			'sunnahCalendarTitle' => 'روزے اور مواقع',
			'upcomingLabel' => 'آنے والے',
			'nothingUpcoming' => 'اگلے دو ماہ میں کوئی نشان زد موقع نہیں۔',
			'calendarNote' => 'تاریخیں ام القریٰ کے حساب سے ہیں اور مقامی رؤیت سے ایک دن مختلف ہو سکتی ہیں۔',
			'fastingRecommended' => 'سنت روزہ',
			'fastingObligatory' => 'فرض روزہ',
			'fastingForbidden' => 'روزہ رکھنے کا دن نہیں',
			'fastingNoneToday' => 'آج کوئی مخصوص روزہ نہیں۔',
			'fastRamadan' => 'رمضان',
			'fastMonday' => 'پیر کا روزہ',
			'fastThursday' => 'جمعرات کا روزہ',
			'fastWhiteDay' => 'ایام بیض',
			'fastTasua' => 'تاسوعاء',
			'fastAshura' => 'عاشوراء',
			'fastDhulHijjah' => 'ذوالحجہ کے دس دن',
			'fastArafah' => 'یوم عرفہ',
			'fastSixOfShawwal' => 'شوال کے چھ روزے',
			'fastRamadanSub' => 'اس مہینے کے فرض روزے۔',
			'fastMondaySub' => 'اعمال پیر اور جمعرات کو پیش کیے جاتے ہیں۔ — ترمذی',
			'fastThursdaySub' => 'اعمال پیر اور جمعرات کو پیش کیے جاتے ہیں۔ — ترمذی',
			'fastWhiteDaySub' => 'ہر ہجری مہینے کی 13، 14 اور 15 تاریخ۔ — بخاری اور مسلم',
			'fastTasuaSub' => 'دس محرم کے ساتھ رکھا جاتا ہے۔ — مسلم',
			'fastAshuraSub' => 'گزشتہ سال کے گناہوں کا کفارہ ہے۔ — مسلم',
			'fastDhulHijjahSub' => 'نیک اعمال کے لیے اللہ کو ان دنوں سے زیادہ محبوب دن نہیں۔ — بخاری',
			'fastArafahSub' => 'حج پر نہ جانے والوں کے لیے گزشتہ اور آئندہ سال کے گناہوں کا کفارہ ہے۔ — مسلم',
			'fastSixOfShawwalSub' => 'رمضان کے بعد شوال کے چھ روزے رکھنا پورے سال کے روزوں کے مانند ہے۔ — مسلم',
			'eventNewYear' => 'اسلامی نیا سال',
			'eventAshura' => 'عاشوراء',
			'eventRamadan' => 'رمضان کا آغاز',
			'eventLastTen' => 'آخری دس راتیں',
			'eventEidFitr' => 'عید الفطر',
			'eventDhulHijjah' => 'ذوالحجہ کا آغاز',
			'eventArafah' => 'یوم عرفہ',
			'eventEidAdha' => 'عید الاضحیٰ',
			'eventLastTenSub' => 'ان دس راتوں کی طاق راتوں میں لیلۃ القدر تلاش کی جاتی ہے۔',
			'barEidAlFitr' => 'عید الفطر پر روزہ رکھنا جائز نہیں۔',
			'barEidAlAdha' => 'عید الاضحیٰ پر روزہ رکھنا جائز نہیں۔',
			'barTashriq' => 'ایام تشریق میں روزہ رکھنا جائز نہیں۔',
			'hijriAdjust' => 'ہجری تاریخ کی درستگی',
			'hijriAdjustHint' => 'حساب شدہ تاریخ مقامی رؤیت سے ایک دن آگے یا پیچھے ہو سکتی ہے۔ اسے اپنی جماعت کے مطابق درست کریں۔',
			'hijriOffsetLabels.0' => '−2 دن',
			'hijriOffsetLabels.1' => '−1 دن',
			'hijriOffsetLabels.2' => 'کوئی تبدیلی نہیں',
			'hijriOffsetLabels.3' => '+1 دن',
			'hijriOffsetLabels.4' => '+2 دن',
			'fastingReminders' => 'روزے کی یاد دہانیاں',
			'fastingRemindersSub' => 'سنت روزے سے ایک شام پہلے یاد دہانی',
			'notifFastTitle' => 'کل روزہ',
			'notifFastBody' => ({required Object name}) => 'کل ${name} ہے — سنت روزے کا موقع۔',
			'notifOccasionBody' => 'کل، ان شاء اللہ۔',
			'share' => 'شیئر کریں',
			'shareAsImage' => 'تصویر شیئر کریں',
			'shareAsText' => 'متن شیئر کریں',
			'shareImageFailedNotReady' => 'تصویر تیار نہیں تھی؛ متن شیئر کیا جا رہا ہے۔',
			'shareImageFailedUnsupported' => 'یہ آلہ تصویر نہیں بنا سکا؛ متن شیئر کیا جا رہا ہے۔',
			'nextPhraseOnTap' => 'ذکر مکمل ہوا۔ اگلا ذکر گننے کے لیے دبائیں۔',
			'aboutContributors' => 'حصن کے پیچھے لوگ',
			'aboutDeveloperCredit' => 'ڈویلپر · ایپ کو ڈیزائن کیا اور تیار کیا۔',
			'aboutContentReviewerCredit' => 'معاون · ایپ کے مواد میں املا کی غلطیوں اور غلط معلومات کی نشاندہی کے لیے جائزے میں مدد کی۔',
			'aboutProfileLinkCopied' => 'GitHub پروفائل کا ربط نقل ہو گیا۔ اسے اپنے براؤزر میں کھولیں۔',
			'aboutTypefaces' => 'خطوط',
			'aboutVerseMeanings' => 'آیات کے معانی',
			'aboutDuaDraftCredit' => 'دعاؤں کے بعض معانی Hisn منصوبے کے مسودے ہیں؛ مستند لسانی اور دینی نظرثانی باقی ہے۔',
			'aboutTranslationSource' => 'ترجمے کے مآخذ · تنزیل',
			'aboutLinkCopied' => 'ماخذ کا ربط نقل ہو گیا۔ اسے اپنے براؤزر میں کھولیں۔',
			'aboutArabicText' => 'عربی متن',
			'aboutLatinText' => 'لاطینی متن',
			'aboutLatinApparatus' => 'لاطینی انٹرفیس کا متن',
			'aboutMushafPages' => 'مصحف کے صفحات · مجمع ملک فہد برائے طباعت قرآن کریم',
			'prayerCountdownTitle' => 'اگلی نماز کی الٹی گنتی',
			'prayerCountdownSubtitle' => 'اگلی نماز، اذان کے بعد کا وقت اور ہجری تاریخ اپنی اطلاعات میں رکھیں۔',
			'prayerCountdownUnavailable' => 'اینڈرائیڈ پر دستیاب ہے۔ الٹی گنتی کی شکل نظام طے کرتا ہے۔',
			'prayerCountdownChannelDescription' => 'اگلی نماز تک خاموش الٹی گنتی',
			'guideTitle' => 'مختصر رہنما',
			'guideWelcomeTitle' => 'حصن ایپ سے واقف ہوں',
			'guideWelcomeBody' => 'تسبیح، قرآن کی تلاش، نماز کے اوزار، ظاہری شکل اور یاد دہانیوں کی ترتیبات کی جگہ جانیں۔ یہ رہنما ترتیبات میں دوبارہ کھولا جا سکتا ہے۔',
			'viewGuide' => 'رہنما دیکھیں',
			'replayGuide' => 'ایپ کا رہنما دیکھیں',
			'replayGuideSub' => 'اہم خصوصیات کی رہنمائی',
			'guideDone' => 'مکمل',
			'guideProgress' => ({required Object total, required Object current}) => '${total} میں سے ${current}',
			'guideTasbihBody' => 'ذکر منتخب کرنے، اپنا ذکر شامل کرنے اور تکرار گننے کے لیے تسبیح کھولیں۔',
			'guideQuranBody' => 'سورت تلاش کریں یا قرآن کی آیات ڈھونڈنے کے لیے عربی الفاظ لکھیں۔',
			'guidePrayerBody' => 'نماز کے اوقات اور قبلہ یہاں ملیں گے۔ مقام تک رسائی کی اجازت نماز کی ترتیبات میں منتخب کی جا سکتی ہے۔',
			'guideAppearanceBody' => 'یہاں روشن، تاریک یا نظام کا انداز منتخب کریں۔ رنگ منتخب کرنے کے لیے اسی مینو میں ظاہری شکل کھولیں۔',
			'guideNotificationsBody' => 'اطلاعات میں یاد دہانیاں اور اذان منتخب کریں، خاموش اوقات مقرر کریں یا تمام یاد دہانیاں عارضی طور پر روکیں۔ اجازتیں صرف اپنی مرضی سے فعال کریں۔',
			'prayerSilenceTitle' => 'نماز کے وقت خاموشی',
			'prayerSilenceSub' => 'اذان کے بعد خودکار خاموش وقفہ',
			'prayerSilenceEnable' => 'نماز کے وقت خاموشی فعال کریں',
			'prayerSilenceBody' => 'ہر اذان کے بعد اپنی منتخب مدت میں کالیں اور اطلاعات خاموش کریں۔ الارم کی اجازت برقرار رہتی ہے۔ ڈو ناٹ ڈسٹرب کے دوسرے موڈ زیادہ سخت پابندیاں لگا سکتے ہیں۔',
			'prayerSilenceTimingHint' => 'آغاز اور اختتام اذان کے بعد منٹوں میں ہیں۔ اگر Hisn اذان چلا رہا ہو تو خاموشی اس کے ختم ہونے تک انتظار کرے گی؛ اختتامی وقت وہی رہے گا۔',
			'prayerSilenceStart' => 'اذان کے بعد آغاز',
			'prayerSilenceEnd' => 'اذان کے بعد اختتام',
			'prayerSilenceMinutes' => ({required Object minutes}) => '${minutes} منٹ',
			'prayerSilencePolicyButton' => 'ڈو ناٹ ڈسٹرب کی رسائی دیں',
			'prayerSilenceExactButton' => 'درست اوقات کی اجازت دیں',
			'prayerSilenceDisabled' => 'نماز کے وقت خاموشی بند ہے',
			'prayerSilencePermission' => 'نماز کے وقت خاموشی کے لیے ڈو ناٹ ڈسٹرب کی رسائی دیں۔',
			'prayerSilenceExact' => 'موقوف: وقت پر آغاز اور اختتام کے لیے درست الارم کی رسائی درکار ہے۔',
			'prayerSilenceLocation' => 'نماز کے وقفوں کے حساب کے لیے شہر منتخب کریں یا مقام کی اجازت دیں۔',
			'prayerSilenceReady' => 'اگلی نماز کے وقفے کے لیے تیار',
			'prayerSilenceActiveUntil' => ({required Object time}) => 'نماز کی خاموشی ${time} تک فعال ہے',
			'prayerSilenceWaiting' => 'اذان ختم ہونے کا انتظار ہے',
			'prayerSilenceRuleDisabled' => 'Android کی ترتیبات میں Hisn کا نماز موڈ بند ہے۔',
			'prayerSilenceUnavailable' => 'نماز کے وقت خاموشی صرف Android پر دستیاب ہے۔',
			'prayerSilenceError' => 'نماز کی خاموشی مقرر نہیں ہو سکی۔ رسائی دیکھ کر دوبارہ کوشش کریں۔',
			'prayerSilenceStopNow' => 'یہ خاموش وقفہ ختم کریں',
			'prayerSilenceExpiryNote' => 'صرف Hisn کا موڈ خودکار ختم ہوتا ہے؛ آپ کا اپنا ڈو ناٹ ڈسٹرب تبدیل نہیں ہوتا۔ درست الارم کی رسائی واپس لینے یا ایپ محدود ہونے پر Android اختتام کی متبادل جانچ میں تاخیر کر سکتا ہے۔',
			'qiblaStyle' => 'قطب نما کا انداز',
			'qiblaTone' => 'قطب نما کا رنگ',
			'qiblaVibrationOn' => 'ارتعاش فعال',
			'qiblaVibrationOff' => 'ارتعاش بند',
			'qiblaStyles.0' => 'کلاسیکی',
			'qiblaStyles.1' => 'سادہ',
			'qiblaStyles.2' => 'قطب نما پھول',
			'qiblaTones.0' => 'تھیم کا رنگ',
			'qiblaTones.1' => 'سنہری',
			'qiblaTones.2' => 'سیاہی',
			'durationMinutes' => ({required Object minutes}) => '${minutes} منٹ',
			'durationHoursMinutes' => ({required Object hours, required Object minutes}) => '${hours} گھنٹے ${minutes} منٹ',
			_ => null,
		};
	}
}
