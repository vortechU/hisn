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
class TranslationsAr extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsAr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ar,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ar>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsAr _root = this; // ignore: unused_field

	@override 
	TranslationsAr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsAr(meta: meta ?? this.$meta);

	// Translations
	@override String get navAdhkar => 'الأذكار';
	@override String get navQuran => 'القرآن';
	@override String get navTasbih => 'المسبحة';
	@override String get navQibla => 'القبلة';
	@override String get navSaved => 'المحفوظة';
	@override String get navSettings => 'الإعدادات';
	@override String get navPrayer => 'الصلاة';
	@override String get prayerQiblaTitle => 'الصلاة والقبلة';
	@override String get weeklySchedule => 'جدول الأسبوع';
	@override String get searchDuas => 'ابحث في الأدعية…';
	@override String get allAdhkar => 'كل الأذكار';
	@override String get groupDaily => 'الأذكار اليومية';
	@override String get groupSituational => 'لكل حال';
	@override String get groupMine => 'الخاصة بي';
	@override String get muhassanHeading => 'مُحَصَّن';
	@override String muhassanToday({required Object percent}) => 'محصَّن اليوم بنسبة ${percent}٪';
	@override String get muhassanComplete => 'محصَّن بالكامل — ما شاء الله';
	@override String get muhassanMorning => 'الصباح';
	@override String get muhassanEvening => 'المساء';
	@override String get streakDaysOne => 'سلسلة يوم واحد';
	@override String streakDaysOther({required Object n}) => 'سلسلة ${n} أيام';
	@override String get streakStart => 'ابدأ سلسلتك';
	@override String streakBest({required Object n}) => 'الأفضل: ${n}';
	@override String get streakTitle => 'سلسلتك';
	@override String get streakWord => 'يوم متتابع';
	@override String get statCurrent => 'الحالية';
	@override String get statBest => 'الأفضل';
	@override String get statTotal => 'إجمالي الأيام';
	@override String get daysValueOne => 'يوم واحد';
	@override String daysValueOther({required Object n}) => '${n} يوم';
	@override String get streakOnFire => 'أنت في تتابع رائع — واصل!';
	@override String get streakTodayPending => 'أكمل أذكار اليوم لتمديد سلسلتك';
	@override String get streakBroken => 'أكمل أذكار الصباح والمساء لتبدأ من جديد';
	@override String get last4Weeks => 'آخر ٤ أسابيع';
	@override String get todayLabel => 'اليوم';
	@override String get fortifiedLegend => 'محصَّن';
	@override List<String> get weekdayLetters => [
		'ن',
		'ث',
		'ر',
		'خ',
		'ج',
		'س',
		'ح',
	];
	@override String get quranTitle => 'القرآن الكريم';
	@override String get searchSurah => 'ابحث في السور…';
	@override String get continueReading => 'متابعة القراءة';
	@override String get surahWord => 'سورة';
	@override String get revelationMeccan => 'مكية';
	@override String get revelationMedinan => 'مدنية';
	@override String get versesCountOne => 'آية واحدة';
	@override String versesCountOther({required Object n}) => '${n} آيات';
	@override String juzLabel({required Object n}) => 'الجزء ${n}';
	@override String get quranBookmarks => 'العلامات المرجعية';
	@override String get noBookmarks => 'لا توجد علامات مرجعية بعد';
	@override String get bookmarkAdded => 'تمت الإضافة إلى العلامات';
	@override String get bookmarkRemoved => 'أُزيلت العلامة';
	@override String get goToAyah => 'الانتقال إلى آية';
	@override String get chooseSurah => 'السورة';
	@override String get verseNumber => 'رقم الآية';
	@override String verseRange({required Object n}) => '١–${n}';
	@override String get goAction => 'انتقال';
	@override String get myDuas => 'أدعيتي';
	@override String get myDuasSub => 'أدعية تضيفها بنفسك';
	@override String get addDua => 'إضافة دعاء';
	@override String get newDua => 'دعاء جديد';
	@override String get fieldArabic => 'النص العربي';
	@override String get fieldArabicRequired => 'يرجى إدخال النص العربي';
	@override String get fieldTitle => 'العنوان (اختياري)';
	@override String get fieldTransliteration => 'النطق بالحروف اللاتينية (اختياري)';
	@override String get fieldTranslation => 'الترجمة / المعنى (اختياري)';
	@override String get fieldReference => 'المصدر (اختياري)';
	@override String get fieldRepeat => 'عدد التكرار';
	@override String get save => 'حفظ';
	@override String get cancel => 'إلغاء';
	@override String get delete => 'حذف';
	@override String get deleteDua => 'حذف الدعاء';
	@override String get deleteDuaConfirm => 'إزالة هذا الدعاء من أدعيتي؟';
	@override String get duaSaved => 'تم حفظ الدعاء';
	@override String get duaUpdated => 'تم تحديث الدعاء';
	@override String get editDua => 'تعديل الدعاء';
	@override String get edit => 'تعديل';
	@override String get noCustomTitle => 'لا توجد أدعية بعد';
	@override String get noCustomBody => 'اضغط + لإضافة دعائك والاحتفاظ به هنا.';
	@override String get recommendedNow => 'مُقترَحٌ الآن';
	@override String get readNowOne => 'اقرأ الآن · دعاء واحد';
	@override String readNowOther({required Object count}) => 'اقرأ الآن · ${count}';
	@override String get duaCountOne => 'ذِكْر واحد';
	@override String duaCountOther({required Object count}) => '${count} ذِكْر';
	@override String get now => 'الآن';
	@override String get next => 'التالي';
	@override String get remaining => 'متبقٍّ';
	@override String get countdownNow => 'الآن';
	@override String nextPrayerLine({required Object name, required Object time}) => 'التالي · ${name}  ${time}';
	@override String todaysPrayers({required Object location}) => 'صلوات اليوم · ${location}';
	@override String get searchHint => 'ابحث في الأدعية والمعاني والمصادر…';
	@override String get clear => 'مسح';
	@override String get searchPrompt => 'ابحث بالعنوان أو المعنى أو النطق أو المصدر.';
	@override String noResults({required Object query}) => 'لا توجد أدعية لـ «${query}».';
	@override String get resultsCountOne => 'نتيجة واحدة';
	@override String resultsCountOther({required Object n}) => '${n} نتيجة';
	@override String get noSavedTitle => 'لا توجد أدعية محفوظة بعد';
	@override String get noSavedBody => 'اضغط على علامة الحفظ في أي دعاء لتحتفظ به هنا.';
	@override String get resetCount => 'إعادة العدّ';
	@override String get tapToCount => 'اضغط في أي مكان للعدّ';
	@override String get setsCompletedOne => 'اكتملت جولة واحدة';
	@override String setsCompletedOther({required Object n}) => 'اكتمل ${n} جولات';
	@override String ofTarget({required Object n}) => 'من ${n}';
	@override String get resetProgress => 'إعادة التقدّم';
	@override String get setComplete => 'اكتملت — تقبّل الله';
	@override String get tapEachDua => 'اضغط كل دعاء لعدّ تكراره';
	@override String get duaCopied => 'تم نسخ الدعاء';
	@override String get removeBookmark => 'إزالة الحفظ';
	@override String get bookmark => 'حفظ';
	@override String get copy => 'نسخ';
	@override String get done => 'تمّ';
	@override String get settings => 'الإعدادات';
	@override String get secPrayerTimes => 'مواقيت الصلاة';
	@override String get secReminders => 'التذكيرات';
	@override String get secDisplay => 'العرض';
	@override String get secLanguage => 'اللغة';
	@override String get secAbout => 'حول التطبيق';
	@override String get location => 'الموقع';
	@override String get locYourLocationGps => 'موقعك (GPS)';
	@override String locDeviceGps({required Object label}) => 'موقع الجهاز · ${label}';
	@override String locFixedCity({required Object label}) => '${label} (مدينة ثابتة)';
	@override String get calcMethod => 'طريقة الحساب';
	@override String get asrCalc => 'حساب العصر';
	@override String get notifications => 'الإشعارات';
	@override String get prayerReminders => 'تذكيرات الصلاة';
	@override String get prayerRemindersSub => 'تنبيه عند كل وقت صلاة';
	@override String get dailyRemembrance => 'الذكر اليومي';
	@override String get dailyRemembranceSub => 'أذكار الصباح والمساء (تتكرر حتى تُتمّها) مع سنن الجمعة والليل';
	@override String get adhanSound => 'صوت الأذان';
	@override String get adhanSoundSub => 'تشغيل الأذان عند كل وقت صلاة';
	@override String get adhanNeedsReminders => 'فعّل تذكيرات الصلاة بالأعلى ليُشغَّل الأذان عند وقت الصلاة.';
	@override String get adhanVolume => 'مستوى صوت الأذان';
	@override List<String> get streamLabels => [
		'الوسائط',
		'الرنين',
		'المنبّه',
	];
	@override List<String> get streamHints => [
		'يتحكّم به مستوى صوت الوسائط',
		'يتحكّم به مستوى صوت الرنين',
		'يتحكّم به مستوى صوت المنبّه',
	];
	@override String get previewAdhan => 'تجربة الأذان';
	@override String get stopAdhan => 'إيقاف';
	@override String get adhanPlaying => 'جارٍ تشغيل الأذان…';
	@override String get notifBlocked => 'الإشعارات محظورة. فعّلها لتطبيق Hisn من إعدادات جهازك.';
	@override String get textSize => 'حجم الخط';
	@override List<String> get fontScaleLabels => [
		'صغير',
		'افتراضي',
		'كبير',
		'كبير جدًا',
	];
	@override String get showTransliteration => 'إظهار النطق اللاتيني';
	@override String get showTransliterationSub => 'سطر النطق بالحروف اللاتينية';
	@override String get showTranslation => 'إظهار الترجمة';
	@override String get showTranslationSub => 'المعنى بالإنجليزية';
	@override String get aboutBody => 'رفيق الأدعية والأذكار · نموذج أولي\nمواقيت الصلاة عبر مكتبة Adhan.';
	@override String get automatic => 'تلقائي';
	@override String get useDeviceLocation => 'استخدام موقع جهازي';
	@override String get gpsActive => 'مُفعّل · المواقيت حسب مكانك';
	@override String get gpsDetect => 'تحديد عبر GPS (يطلب الإذن)';
	@override String get chooseCity => 'اختر مدينة';
	@override String get cityNote => 'تُعرض مواقيت المدينة المختارة بتوقيت جهازك الحالي — وهي دقيقة عندما تكون المدينة في منطقتك.';
	@override String get madhabStandard => 'الجمهور (الشافعي، المالكي، الحنبلي)';
	@override String get madhabHanafi => 'الحنفي';
	@override String get asrHintStandard => 'يبدأ العصر عندما يساوي ظلّ الشيء طوله';
	@override String get asrHintHanafi => 'يبدأ العصر عندما يبلغ ظلّ الشيء مِثلَيْ طوله';
	@override String get prayerFajr => 'الفَجْر';
	@override String get prayerSunrise => 'الشُّرُوق';
	@override String get prayerDhuhr => 'الظُّهْر';
	@override String get prayerAsr => 'العَصْر';
	@override String get prayerMaghrib => 'المَغْرِب';
	@override String get prayerIsha => 'العِشَاء';
	@override String get prayerNone => '—';
	@override String notifTitle({required Object name}) => 'صلاة ${name}';
	@override String notifBody({required Object name, required Object place}) => 'حان وقت صلاة ${name} — ${place}.';
	@override String get testNotifTitle => 'تنبيه تجريبي';
	@override String get testNotifBody => 'إذا رأيت هذا، فإن تذكيرات الصلاة تعمل. 🌙';
	@override String get sendTestNotif => 'إرسال تنبيه تجريبي';
	@override String get testSent => 'تم الإرسال — يجب أن يظهر واحد الآن، وآخر خلال ١٢ ثانية (اقفل هاتفك).';
	@override String get testBlocked => 'تم الإرسال، لكن هاتفك يقول إن إشعارات Hisn مُعطّلة. فعّلها من الإعدادات ← التطبيقات ← Hisn ← الإشعارات.';
	@override String get batteryHint => 'بعض الهواتف (مثل شاومي/MIUI وسامسونج) تمنع التذكيرات المجدولة عند إغلاق التطبيق. إن لم تصل التذكيرات، فعّل "التشغيل التلقائي" واضبط استهلاك البطارية على "بدون قيود" لتطبيق Hisn.';
	@override String get adhkarMorningTitle => 'أذكار الصباح';
	@override String get adhkarMorningBody => 'ابدأ صباحك بالذكر — حصِّن يومك.';
	@override String get adhkarEveningTitle => 'أذكار المساء';
	@override String get adhkarEveningBody => 'اختم يومك بالذكر — حصِّن مساءك.';
	@override String get kahfTitle => 'سورة الكهف';
	@override String get kahfBody => 'إنه يوم الجمعة — اقرأ سورة الكهف يكن لك نورٌ بين الجمعتين.';
	@override String get salawatTitle => 'الصلاة على النبي ﷺ';
	@override String get salawatBody => 'خذ لحظةً للصلاة على النبي ﷺ.';
	@override String get salawatFridayTitle => 'الصلاة على النبي ﷺ';
	@override String get salawatFridayBody => 'إنه يوم الجمعة — أكثِر من الصلاة على النبي ﷺ.';
	@override String get mulkTitle => 'سورة الملك';
	@override String get mulkBody => 'قبل أن تنام — اقرأ سورة الملك.';
	@override String qiblaFromNorth({required Object degrees}) => 'القبلة · ${degrees}° من الشمال';
	@override String get facingQibla => 'أنت تواجه القبلة';
	@override String turnRight({required Object degrees}) => 'استدر يمينًا ${degrees}°';
	@override String turnLeft({required Object degrees}) => 'استدر يسارًا ${degrees}°';
	@override String get calibrateHint => 'حرّك الجهاز على شكل ٨ للمعايرة';
	@override String get compassUnavailable => 'البوصلة غير متاحة';
	@override String get compassUnavailableBody => 'لا يحتوي هذا الجهاز على مستشعر بوصلة، أو يحتاج إلى معايرة. جرّب تحريكه على شكل الرقم ٨.';
	@override String get qiblaNoLocation => 'الموقع مطلوب';
	@override String get qiblaNoLocationBody => 'لا يمكن حساب اتجاه القبلة قبل معرفة موقعك. فعّل خدمات الموقع، أو اختر مدينتك من الإعدادات.';
	@override String get placeYourLocation => 'موقعك';
	@override String get placeSelectedCity => 'مدينة مختارة';
	@override String get placeMakkah => 'مكة';
	@override String get onboardSkip => 'تخطّي';
	@override String get onboardNext => 'التالي';
	@override String get onboardGetStarted => 'ابدأ الآن';
	@override String get onboardWelcomeTitle => 'مرحبًا بك في حصن';
	@override String get onboardWelcomeBody => 'رفيقك اليومي للذكر والقرآن والصلاة. إليك جولة سريعة للبدء.';
	@override String get onboardAdhkarTitle => 'الأذكار والأدعية';
	@override String get onboardAdhkarBody => 'أذكار الصباح والمساء، وعدّاد تسبيح، وأدعيتك الخاصة. انقر على الدعاء لتعدّ تكراراته.';
	@override String get onboardQuranTitle => 'القرآن الكريم';
	@override String get onboardQuranBody => 'اقرأ القرآن كاملًا في مصحف جميل، وتابع من حيث توقّفت، وضع علامة على الآيات التي تحبّها.';
	@override String get onboardPrayerTitle => 'الصلاة والقبلة';
	@override String get onboardPrayerBody => 'أوقات صلاة دقيقة لموقعك، وعدّ تنازلي للصلاة القادمة، وبوصلة تشير إلى القبلة.';
	@override String get onboardPermsTitle => 'بعض الأذونات';
	@override String get onboardPermsBody => 'اسمح بهذه الأذونات ليعمل حصن على أكمل وجه. يمكنك تغييرها في أي وقت من الإعدادات.';
	@override String get onboardLocationTitle => 'الموقع';
	@override String get onboardLocationBody => 'لحساب أوقات الصلاة الدقيقة واتجاه القبلة حسب مكانك.';
	@override String get onboardLocationAction => 'السماح بالموقع';
	@override String get onboardNotifTitle => 'الإشعارات';
	@override String get onboardNotifBody => 'تذكير لطيف عند كل وقت صلاة كي لا تفوتك صلاة.';
	@override String get onboardNotifAction => 'تفعيل التذكيرات';
	@override String get onboardGranted => 'مُفعّل';
	@override String get secAppearance => 'المظهر';
	@override String get appearanceColors => 'لوحة الألوان';
	@override String get appearanceTheme => 'السمة';
	@override String get themeLight => 'فاتح';
	@override String get themeDark => 'داكن';
	@override String get themeSystem => 'النظام';
	@override String get paletteEmerald => 'زمرّدي وذهبي';
	@override String get paletteSapphire => 'أزرق ياقوتي وسماوي';
	@override String get paletteAmethyst => 'أرجواني ووردي';
	@override String get paletteRosewood => 'خشب الورد';
	@override String get paletteLagoon => 'بحيرة';
	@override String get paletteDesert => 'صحراء';
	@override String get arabicFont => 'خط العربية';
	@override String get readingTheme => 'خلفية القراءة';
	@override String get readingSystem => 'حسب التطبيق';
	@override String get readingSepia => 'ورقي';
	@override String get readingNight => 'ليلي';
	@override String get patterns => 'زخرفة هندسية';
	@override String get patternsSub => 'زخرفة خفيفة على العناوين والعدّاد';
	@override List<String> get ampm => [
		'ص',
		'م',
	];
	@override List<String> get weekdaysShort => [
		'الاثنين',
		'الثلاثاء',
		'الأربعاء',
		'الخميس',
		'الجمعة',
		'السبت',
		'الأحد',
	];
	@override List<String> get monthsShort => [
		'يناير',
		'فبراير',
		'مارس',
		'أبريل',
		'مايو',
		'يونيو',
		'يوليو',
		'أغسطس',
		'سبتمبر',
		'أكتوبر',
		'نوفمبر',
		'ديسمبر',
	];
	@override String dateFormat({required Object weekday, required Object day, required Object month}) => '${weekday}، ${day} ${month}';
	@override List<String> get hijriMonths => [
		'محرم',
		'صفر',
		'ربيع الأول',
		'ربيع الآخر',
		'جمادى الأولى',
		'جمادى الآخرة',
		'رجب',
		'شعبان',
		'رمضان',
		'شوال',
		'ذو القعدة',
		'ذو الحجة',
	];
	@override String hijriDateFormat({required Object day, required Object month, required Object year}) => '${day} ${month} ${year} هـ';
	@override String get hijriSuffix => 'هـ';
}

/// The flat map containing all translations for locale <ar>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsAr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'navAdhkar' => 'الأذكار',
			'navQuran' => 'القرآن',
			'navTasbih' => 'المسبحة',
			'navQibla' => 'القبلة',
			'navSaved' => 'المحفوظة',
			'navSettings' => 'الإعدادات',
			'navPrayer' => 'الصلاة',
			'prayerQiblaTitle' => 'الصلاة والقبلة',
			'weeklySchedule' => 'جدول الأسبوع',
			'searchDuas' => 'ابحث في الأدعية…',
			'allAdhkar' => 'كل الأذكار',
			'groupDaily' => 'الأذكار اليومية',
			'groupSituational' => 'لكل حال',
			'groupMine' => 'الخاصة بي',
			'muhassanHeading' => 'مُحَصَّن',
			'muhassanToday' => ({required Object percent}) => 'محصَّن اليوم بنسبة ${percent}٪',
			'muhassanComplete' => 'محصَّن بالكامل — ما شاء الله',
			'muhassanMorning' => 'الصباح',
			'muhassanEvening' => 'المساء',
			'streakDaysOne' => 'سلسلة يوم واحد',
			'streakDaysOther' => ({required Object n}) => 'سلسلة ${n} أيام',
			'streakStart' => 'ابدأ سلسلتك',
			'streakBest' => ({required Object n}) => 'الأفضل: ${n}',
			'streakTitle' => 'سلسلتك',
			'streakWord' => 'يوم متتابع',
			'statCurrent' => 'الحالية',
			'statBest' => 'الأفضل',
			'statTotal' => 'إجمالي الأيام',
			'daysValueOne' => 'يوم واحد',
			'daysValueOther' => ({required Object n}) => '${n} يوم',
			'streakOnFire' => 'أنت في تتابع رائع — واصل!',
			'streakTodayPending' => 'أكمل أذكار اليوم لتمديد سلسلتك',
			'streakBroken' => 'أكمل أذكار الصباح والمساء لتبدأ من جديد',
			'last4Weeks' => 'آخر ٤ أسابيع',
			'todayLabel' => 'اليوم',
			'fortifiedLegend' => 'محصَّن',
			'weekdayLetters.0' => 'ن',
			'weekdayLetters.1' => 'ث',
			'weekdayLetters.2' => 'ر',
			'weekdayLetters.3' => 'خ',
			'weekdayLetters.4' => 'ج',
			'weekdayLetters.5' => 'س',
			'weekdayLetters.6' => 'ح',
			'quranTitle' => 'القرآن الكريم',
			'searchSurah' => 'ابحث في السور…',
			'continueReading' => 'متابعة القراءة',
			'surahWord' => 'سورة',
			'revelationMeccan' => 'مكية',
			'revelationMedinan' => 'مدنية',
			'versesCountOne' => 'آية واحدة',
			'versesCountOther' => ({required Object n}) => '${n} آيات',
			'juzLabel' => ({required Object n}) => 'الجزء ${n}',
			'quranBookmarks' => 'العلامات المرجعية',
			'noBookmarks' => 'لا توجد علامات مرجعية بعد',
			'bookmarkAdded' => 'تمت الإضافة إلى العلامات',
			'bookmarkRemoved' => 'أُزيلت العلامة',
			'goToAyah' => 'الانتقال إلى آية',
			'chooseSurah' => 'السورة',
			'verseNumber' => 'رقم الآية',
			'verseRange' => ({required Object n}) => '١–${n}',
			'goAction' => 'انتقال',
			'myDuas' => 'أدعيتي',
			'myDuasSub' => 'أدعية تضيفها بنفسك',
			'addDua' => 'إضافة دعاء',
			'newDua' => 'دعاء جديد',
			'fieldArabic' => 'النص العربي',
			'fieldArabicRequired' => 'يرجى إدخال النص العربي',
			'fieldTitle' => 'العنوان (اختياري)',
			'fieldTransliteration' => 'النطق بالحروف اللاتينية (اختياري)',
			'fieldTranslation' => 'الترجمة / المعنى (اختياري)',
			'fieldReference' => 'المصدر (اختياري)',
			'fieldRepeat' => 'عدد التكرار',
			'save' => 'حفظ',
			'cancel' => 'إلغاء',
			'delete' => 'حذف',
			'deleteDua' => 'حذف الدعاء',
			'deleteDuaConfirm' => 'إزالة هذا الدعاء من أدعيتي؟',
			'duaSaved' => 'تم حفظ الدعاء',
			'duaUpdated' => 'تم تحديث الدعاء',
			'editDua' => 'تعديل الدعاء',
			'edit' => 'تعديل',
			'noCustomTitle' => 'لا توجد أدعية بعد',
			'noCustomBody' => 'اضغط + لإضافة دعائك والاحتفاظ به هنا.',
			'recommendedNow' => 'مُقترَحٌ الآن',
			'readNowOne' => 'اقرأ الآن · دعاء واحد',
			'readNowOther' => ({required Object count}) => 'اقرأ الآن · ${count}',
			'duaCountOne' => 'ذِكْر واحد',
			'duaCountOther' => ({required Object count}) => '${count} ذِكْر',
			'now' => 'الآن',
			'next' => 'التالي',
			'remaining' => 'متبقٍّ',
			'countdownNow' => 'الآن',
			'nextPrayerLine' => ({required Object name, required Object time}) => 'التالي · ${name}  ${time}',
			'todaysPrayers' => ({required Object location}) => 'صلوات اليوم · ${location}',
			'searchHint' => 'ابحث في الأدعية والمعاني والمصادر…',
			'clear' => 'مسح',
			'searchPrompt' => 'ابحث بالعنوان أو المعنى أو النطق أو المصدر.',
			'noResults' => ({required Object query}) => 'لا توجد أدعية لـ «${query}».',
			'resultsCountOne' => 'نتيجة واحدة',
			'resultsCountOther' => ({required Object n}) => '${n} نتيجة',
			'noSavedTitle' => 'لا توجد أدعية محفوظة بعد',
			'noSavedBody' => 'اضغط على علامة الحفظ في أي دعاء لتحتفظ به هنا.',
			'resetCount' => 'إعادة العدّ',
			'tapToCount' => 'اضغط في أي مكان للعدّ',
			'setsCompletedOne' => 'اكتملت جولة واحدة',
			'setsCompletedOther' => ({required Object n}) => 'اكتمل ${n} جولات',
			'ofTarget' => ({required Object n}) => 'من ${n}',
			'resetProgress' => 'إعادة التقدّم',
			'setComplete' => 'اكتملت — تقبّل الله',
			'tapEachDua' => 'اضغط كل دعاء لعدّ تكراره',
			'duaCopied' => 'تم نسخ الدعاء',
			'removeBookmark' => 'إزالة الحفظ',
			'bookmark' => 'حفظ',
			'copy' => 'نسخ',
			'done' => 'تمّ',
			'settings' => 'الإعدادات',
			'secPrayerTimes' => 'مواقيت الصلاة',
			'secReminders' => 'التذكيرات',
			'secDisplay' => 'العرض',
			'secLanguage' => 'اللغة',
			'secAbout' => 'حول التطبيق',
			'location' => 'الموقع',
			'locYourLocationGps' => 'موقعك (GPS)',
			'locDeviceGps' => ({required Object label}) => 'موقع الجهاز · ${label}',
			'locFixedCity' => ({required Object label}) => '${label} (مدينة ثابتة)',
			'calcMethod' => 'طريقة الحساب',
			'asrCalc' => 'حساب العصر',
			'notifications' => 'الإشعارات',
			'prayerReminders' => 'تذكيرات الصلاة',
			'prayerRemindersSub' => 'تنبيه عند كل وقت صلاة',
			'dailyRemembrance' => 'الذكر اليومي',
			'dailyRemembranceSub' => 'أذكار الصباح والمساء (تتكرر حتى تُتمّها) مع سنن الجمعة والليل',
			'adhanSound' => 'صوت الأذان',
			'adhanSoundSub' => 'تشغيل الأذان عند كل وقت صلاة',
			'adhanNeedsReminders' => 'فعّل تذكيرات الصلاة بالأعلى ليُشغَّل الأذان عند وقت الصلاة.',
			'adhanVolume' => 'مستوى صوت الأذان',
			'streamLabels.0' => 'الوسائط',
			'streamLabels.1' => 'الرنين',
			'streamLabels.2' => 'المنبّه',
			'streamHints.0' => 'يتحكّم به مستوى صوت الوسائط',
			'streamHints.1' => 'يتحكّم به مستوى صوت الرنين',
			'streamHints.2' => 'يتحكّم به مستوى صوت المنبّه',
			'previewAdhan' => 'تجربة الأذان',
			'stopAdhan' => 'إيقاف',
			'adhanPlaying' => 'جارٍ تشغيل الأذان…',
			'notifBlocked' => 'الإشعارات محظورة. فعّلها لتطبيق Hisn من إعدادات جهازك.',
			'textSize' => 'حجم الخط',
			'fontScaleLabels.0' => 'صغير',
			'fontScaleLabels.1' => 'افتراضي',
			'fontScaleLabels.2' => 'كبير',
			'fontScaleLabels.3' => 'كبير جدًا',
			'showTransliteration' => 'إظهار النطق اللاتيني',
			'showTransliterationSub' => 'سطر النطق بالحروف اللاتينية',
			'showTranslation' => 'إظهار الترجمة',
			'showTranslationSub' => 'المعنى بالإنجليزية',
			'aboutBody' => 'رفيق الأدعية والأذكار · نموذج أولي\nمواقيت الصلاة عبر مكتبة Adhan.',
			'automatic' => 'تلقائي',
			'useDeviceLocation' => 'استخدام موقع جهازي',
			'gpsActive' => 'مُفعّل · المواقيت حسب مكانك',
			'gpsDetect' => 'تحديد عبر GPS (يطلب الإذن)',
			'chooseCity' => 'اختر مدينة',
			'cityNote' => 'تُعرض مواقيت المدينة المختارة بتوقيت جهازك الحالي — وهي دقيقة عندما تكون المدينة في منطقتك.',
			'madhabStandard' => 'الجمهور (الشافعي، المالكي، الحنبلي)',
			'madhabHanafi' => 'الحنفي',
			'asrHintStandard' => 'يبدأ العصر عندما يساوي ظلّ الشيء طوله',
			'asrHintHanafi' => 'يبدأ العصر عندما يبلغ ظلّ الشيء مِثلَيْ طوله',
			'prayerFajr' => 'الفَجْر',
			'prayerSunrise' => 'الشُّرُوق',
			'prayerDhuhr' => 'الظُّهْر',
			'prayerAsr' => 'العَصْر',
			'prayerMaghrib' => 'المَغْرِب',
			'prayerIsha' => 'العِشَاء',
			'prayerNone' => '—',
			'notifTitle' => ({required Object name}) => 'صلاة ${name}',
			'notifBody' => ({required Object name, required Object place}) => 'حان وقت صلاة ${name} — ${place}.',
			'testNotifTitle' => 'تنبيه تجريبي',
			'testNotifBody' => 'إذا رأيت هذا، فإن تذكيرات الصلاة تعمل. 🌙',
			'sendTestNotif' => 'إرسال تنبيه تجريبي',
			'testSent' => 'تم الإرسال — يجب أن يظهر واحد الآن، وآخر خلال ١٢ ثانية (اقفل هاتفك).',
			'testBlocked' => 'تم الإرسال، لكن هاتفك يقول إن إشعارات Hisn مُعطّلة. فعّلها من الإعدادات ← التطبيقات ← Hisn ← الإشعارات.',
			'batteryHint' => 'بعض الهواتف (مثل شاومي/MIUI وسامسونج) تمنع التذكيرات المجدولة عند إغلاق التطبيق. إن لم تصل التذكيرات، فعّل "التشغيل التلقائي" واضبط استهلاك البطارية على "بدون قيود" لتطبيق Hisn.',
			'adhkarMorningTitle' => 'أذكار الصباح',
			'adhkarMorningBody' => 'ابدأ صباحك بالذكر — حصِّن يومك.',
			'adhkarEveningTitle' => 'أذكار المساء',
			'adhkarEveningBody' => 'اختم يومك بالذكر — حصِّن مساءك.',
			'kahfTitle' => 'سورة الكهف',
			'kahfBody' => 'إنه يوم الجمعة — اقرأ سورة الكهف يكن لك نورٌ بين الجمعتين.',
			'salawatTitle' => 'الصلاة على النبي ﷺ',
			'salawatBody' => 'خذ لحظةً للصلاة على النبي ﷺ.',
			'salawatFridayTitle' => 'الصلاة على النبي ﷺ',
			'salawatFridayBody' => 'إنه يوم الجمعة — أكثِر من الصلاة على النبي ﷺ.',
			'mulkTitle' => 'سورة الملك',
			'mulkBody' => 'قبل أن تنام — اقرأ سورة الملك.',
			'qiblaFromNorth' => ({required Object degrees}) => 'القبلة · ${degrees}° من الشمال',
			'facingQibla' => 'أنت تواجه القبلة',
			'turnRight' => ({required Object degrees}) => 'استدر يمينًا ${degrees}°',
			'turnLeft' => ({required Object degrees}) => 'استدر يسارًا ${degrees}°',
			'calibrateHint' => 'حرّك الجهاز على شكل ٨ للمعايرة',
			'compassUnavailable' => 'البوصلة غير متاحة',
			'compassUnavailableBody' => 'لا يحتوي هذا الجهاز على مستشعر بوصلة، أو يحتاج إلى معايرة. جرّب تحريكه على شكل الرقم ٨.',
			'qiblaNoLocation' => 'الموقع مطلوب',
			'qiblaNoLocationBody' => 'لا يمكن حساب اتجاه القبلة قبل معرفة موقعك. فعّل خدمات الموقع، أو اختر مدينتك من الإعدادات.',
			'placeYourLocation' => 'موقعك',
			'placeSelectedCity' => 'مدينة مختارة',
			'placeMakkah' => 'مكة',
			'onboardSkip' => 'تخطّي',
			'onboardNext' => 'التالي',
			'onboardGetStarted' => 'ابدأ الآن',
			'onboardWelcomeTitle' => 'مرحبًا بك في حصن',
			'onboardWelcomeBody' => 'رفيقك اليومي للذكر والقرآن والصلاة. إليك جولة سريعة للبدء.',
			'onboardAdhkarTitle' => 'الأذكار والأدعية',
			'onboardAdhkarBody' => 'أذكار الصباح والمساء، وعدّاد تسبيح، وأدعيتك الخاصة. انقر على الدعاء لتعدّ تكراراته.',
			'onboardQuranTitle' => 'القرآن الكريم',
			'onboardQuranBody' => 'اقرأ القرآن كاملًا في مصحف جميل، وتابع من حيث توقّفت، وضع علامة على الآيات التي تحبّها.',
			'onboardPrayerTitle' => 'الصلاة والقبلة',
			'onboardPrayerBody' => 'أوقات صلاة دقيقة لموقعك، وعدّ تنازلي للصلاة القادمة، وبوصلة تشير إلى القبلة.',
			'onboardPermsTitle' => 'بعض الأذونات',
			'onboardPermsBody' => 'اسمح بهذه الأذونات ليعمل حصن على أكمل وجه. يمكنك تغييرها في أي وقت من الإعدادات.',
			'onboardLocationTitle' => 'الموقع',
			'onboardLocationBody' => 'لحساب أوقات الصلاة الدقيقة واتجاه القبلة حسب مكانك.',
			'onboardLocationAction' => 'السماح بالموقع',
			'onboardNotifTitle' => 'الإشعارات',
			'onboardNotifBody' => 'تذكير لطيف عند كل وقت صلاة كي لا تفوتك صلاة.',
			'onboardNotifAction' => 'تفعيل التذكيرات',
			'onboardGranted' => 'مُفعّل',
			'secAppearance' => 'المظهر',
			'appearanceColors' => 'لوحة الألوان',
			'appearanceTheme' => 'السمة',
			'themeLight' => 'فاتح',
			'themeDark' => 'داكن',
			'themeSystem' => 'النظام',
			'paletteEmerald' => 'زمرّدي وذهبي',
			'paletteSapphire' => 'أزرق ياقوتي وسماوي',
			'paletteAmethyst' => 'أرجواني ووردي',
			'paletteRosewood' => 'خشب الورد',
			'paletteLagoon' => 'بحيرة',
			'paletteDesert' => 'صحراء',
			'arabicFont' => 'خط العربية',
			'readingTheme' => 'خلفية القراءة',
			'readingSystem' => 'حسب التطبيق',
			'readingSepia' => 'ورقي',
			'readingNight' => 'ليلي',
			'patterns' => 'زخرفة هندسية',
			'patternsSub' => 'زخرفة خفيفة على العناوين والعدّاد',
			'ampm.0' => 'ص',
			'ampm.1' => 'م',
			'weekdaysShort.0' => 'الاثنين',
			'weekdaysShort.1' => 'الثلاثاء',
			'weekdaysShort.2' => 'الأربعاء',
			'weekdaysShort.3' => 'الخميس',
			'weekdaysShort.4' => 'الجمعة',
			'weekdaysShort.5' => 'السبت',
			'weekdaysShort.6' => 'الأحد',
			'monthsShort.0' => 'يناير',
			'monthsShort.1' => 'فبراير',
			'monthsShort.2' => 'مارس',
			'monthsShort.3' => 'أبريل',
			'monthsShort.4' => 'مايو',
			'monthsShort.5' => 'يونيو',
			'monthsShort.6' => 'يوليو',
			'monthsShort.7' => 'أغسطس',
			'monthsShort.8' => 'سبتمبر',
			'monthsShort.9' => 'أكتوبر',
			'monthsShort.10' => 'نوفمبر',
			'monthsShort.11' => 'ديسمبر',
			'dateFormat' => ({required Object weekday, required Object day, required Object month}) => '${weekday}، ${day} ${month}',
			'hijriMonths.0' => 'محرم',
			'hijriMonths.1' => 'صفر',
			'hijriMonths.2' => 'ربيع الأول',
			'hijriMonths.3' => 'ربيع الآخر',
			'hijriMonths.4' => 'جمادى الأولى',
			'hijriMonths.5' => 'جمادى الآخرة',
			'hijriMonths.6' => 'رجب',
			'hijriMonths.7' => 'شعبان',
			'hijriMonths.8' => 'رمضان',
			'hijriMonths.9' => 'شوال',
			'hijriMonths.10' => 'ذو القعدة',
			'hijriMonths.11' => 'ذو الحجة',
			'hijriDateFormat' => ({required Object day, required Object month, required Object year}) => '${day} ${month} ${year} هـ',
			'hijriSuffix' => 'هـ',
			_ => null,
		};
	}
}
