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
class TranslationsSq extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsSq({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.sq,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <sq>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsSq _root = this; // ignore: unused_field

	@override 
	TranslationsSq $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsSq(meta: meta ?? this.$meta);

	// Translations
	@override String get navAdhkar => 'Dhikri';
	@override String get navQuran => 'Kurani';
	@override String get navTasbih => 'Tesbih';
	@override String get navQibla => 'Kibla';
	@override String get navSaved => 'Të ruajtura';
	@override String get navSettings => 'Cilësimet';
	@override String get navPrayer => 'Namazi';
	@override String get prayerQiblaTitle => 'Namazi dhe kibla';
	@override String get weeklySchedule => 'Orari javor';
	@override String get searchDuas => 'Kërko lutje…';
	@override String get allAdhkar => 'Të gjitha dhikret';
	@override String get groupDaily => 'Dhikret ditore';
	@override String get groupSituational => 'Për çdo rast';
	@override String get groupMine => 'Të miat';
	@override String get muhassanHeading => 'Muhassan';
	@override String muhassanToday({required Object percent}) => 'Sot je ${percent}% i mbrojtur';
	@override String get muhassanComplete => 'Plotësisht i mbrojtur — mashaAllah';
	@override String get muhassanMorning => 'Mëngjesi';
	@override String get muhassanEvening => 'Mbrëmja';
	@override String streakDays({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('sq'))(n,
		one: '1 ditë radhazi',
		other: '${n} ditë radhazi',
	);
	@override String get streakStart => 'Fillo vargun tënd';
	@override String streakBest({required Object n}) => 'Më i miri: ${n}';
	@override String get streakTitle => 'Vargu yt';
	@override String get streakWord => 'ditë radhazi';
	@override String get statCurrent => 'Aktual';
	@override String get statBest => 'Më i miri';
	@override String get statTotal => 'Ditë gjithsej';
	@override String daysValue({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('sq'))(n,
		one: '1 ditë',
		other: '${n} ditë',
	);
	@override String get streakOnFire => 'Po ecën shumë mirë — vazhdo!';
	@override String get streakTodayPending => 'Përfundo dhikret e sotme për të vazhduar vargun';
	@override String get streakBroken => 'Përfundo dhikret e mëngjesit dhe mbrëmjes për të rifilluar';
	@override String get last4Weeks => '4 javët e fundit';
	@override String get todayLabel => 'Sot';
	@override String get fortifiedLegend => 'I mbrojtur';
	@override List<String> get weekdayLetters => [
		'H',
		'M',
		'M',
		'E',
		'P',
		'S',
		'D',
	];
	@override String get quranTitle => 'Kurani';
	@override String get searchSurah => 'Kërko sure…';
	@override String get searchQuran => 'Kërko sure ose fjalë arabe';
	@override String get quranSearchSurahs => 'Suret';
	@override String get quranSearchVerses => 'Ajetet';
	@override String get quranSearchFailed => 'Kërkimi i ajeteve dështoi. Provo sërish.';
	@override String get quranSearchLimit => 'Shfaqen 50 rezultatet e para të ajeteve';
	@override String get retrySearch => 'Kërko sërish';
	@override String get afterPrayerTasbih => 'Tesbihu pas namazit';
	@override String get startAfterPrayerTasbih => 'Numëro dhikrin pas namazit';
	@override String get currentPhrase => 'Shprehja aktuale';
	@override String get afterPrayerComplete => 'Dhikri pas namazit përfundoi.';
	@override String get continueReading => 'Vazhdo leximin';
	@override String get surahWord => 'Sure';
	@override String get revelationMeccan => 'Mekase';
	@override String get revelationMedinan => 'Medinase';
	@override String versesCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('sq'))(n,
		one: '1 ajet',
		other: '${n} ajete',
	);
	@override String juzLabel({required Object n}) => 'Xhuzi ${n}';
	@override String get quranBookmarks => 'Shënuesit';
	@override String get noBookmarks => 'Ende pa shënues';
	@override String get bookmarkAdded => 'Shënuesi u shtua';
	@override String get bookmarkRemoved => 'Shënuesi u hoq';
	@override String get goToAyah => 'Shko te ajeti';
	@override String get chooseSurah => 'Surja';
	@override String get verseNumber => 'Numri i ajetit';
	@override String verseRange({required Object n}) => '1–${n}';
	@override String get goAction => 'Shko';
	@override String get myDuas => 'Lutjet e mia';
	@override String get myDuasSub => 'Lutjet që shton vetë';
	@override String get addDua => 'Shto lutje';
	@override String get newDua => 'Lutje e re';
	@override String get fieldArabic => 'Teksti arabisht';
	@override String get fieldArabicRequired => 'Shkruaj tekstin arabisht';
	@override String get fieldTitle => 'Titulli (opsional)';
	@override String get fieldTransliteration => 'Transliterimi (opsional)';
	@override String get fieldTranslation => 'Përkthimi / kuptimi (opsional)';
	@override String get fieldReference => 'Burimi (opsional)';
	@override String get fieldRepeat => 'Përsëritjet';
	@override String get fieldRepeatPositiveRequired => 'Shkruaj një numër të plotë, të paktën 1.';
	@override String get addDhikr => 'Shto dhikër';
	@override String get editDhikr => 'Ndrysho dhikrin';
	@override String get deleteDhikr => 'Fshi dhikrin';
	@override String get deleteDhikrConfirm => 'Ta heq këtë dhikër dhe numërimin e tij të ruajtur?';
	@override String get fieldDhikrName => 'Emri';
	@override String get fieldDhikrNameRequired => 'Shkruaj një emër për këtë dhikër.';
	@override String get fieldDhikrTargetRequired => 'Shkruaj një numër të plotë nga 1 deri në 1 000 000.';
	@override String get nextSetOnTap => 'Cikli përfundoi. Prek për të nisur ciklin tjetër.';
	@override String get customDhikrTargetNote => 'Zgjidh numrin e përsëritjeve për seancën tënde.';
	@override String get save => 'Ruaj';
	@override String get cancel => 'Anulo';
	@override String get delete => 'Fshi';
	@override String get deleteDua => 'Fshi lutjen';
	@override String get deleteDuaConfirm => 'Ta heq këtë lutje nga Lutjet e mia?';
	@override String get duaSaved => 'Lutja u ruajt';
	@override String get duaUpdated => 'Lutja u përditësua';
	@override String get editDua => 'Ndrysho lutjen';
	@override String get edit => 'Ndrysho';
	@override String get noCustomTitle => 'Ende pa lutje';
	@override String get noCustomBody => 'Prek + për të shtuar dhe ruajtur lutjen tënde këtu.';
	@override String get recommendedNow => 'Rekomandohet tani';
	@override String readNow({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('sq'))(count,
		one: 'Lexo tani · 1 lutje',
		other: 'Lexo tani · ${count} lutje',
	);
	@override String duaCount({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('sq'))(count,
		one: '1 lutje',
		other: '${count} lutje',
	);
	@override String get now => 'Tani';
	@override String get next => 'Më pas';
	@override String get remaining => 'mbeten';
	@override String get countdownNow => 'tani';
	@override String get sinceAdhan => 'Nga ezani';
	@override String todaysPrayers({required Object location}) => 'Namazet e sotme · ${location}';
	@override String get searchHint => 'Kërko lutje, kuptime, burime…';
	@override String get clear => 'Pastro';
	@override String get searchPrompt => 'Kërko sipas titullit, kuptimit, transliterimit ose burimit.';
	@override String noResults({required Object query}) => 'Nuk u gjetën lutje për «${query}».';
	@override String quranNoResults({required Object query}) => 'Nuk u gjetën sure ose ajete për «${query}».';
	@override String resultsCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('sq'))(n,
		one: '1 rezultat',
		other: '${n} rezultate',
	);
	@override String get noSavedTitle => 'Ende pa lutje të ruajtura';
	@override String get noSavedBody => 'Prek shënuesin te një lutje për ta ruajtur këtu dhe për ta gjetur shpejt.';
	@override String get resetCount => 'Nis numërimin nga zero';
	@override String get tapToCount => 'Prek kudo për të numëruar';
	@override String setsCompleted({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('sq'))(n,
		one: '1 cikël i përfunduar',
		other: '${n} cikle të përfunduara',
	);
	@override String ofTarget({required Object n}) => 'nga ${n}';
	@override String get resetProgress => 'Nis përparimin nga e para';
	@override String get setComplete => 'Cikli përfundoi — Allahu ta pranoftë';
	@override String get tapEachDua => 'Prek çdo lutje për të numëruar përsëritjet';
	@override String get listenAction => 'Dëgjo';
	@override String get listenStart => 'Luaj grupin';
	@override String get listenRestart => 'Rifillo nga e para';
	@override String get listenHint => 'Po luhet — mund ta kyçësh telefonin';
	@override String get listenIdleTitle => 'Asgjë nuk po luhet';
	@override String get listenIdleBody => 'Luaj grupin për ta dëgjuar me zë. Përsëritjet numërohen automatikisht.';
	@override String listenMissing({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('sq'))(n,
		one: '1 lutje ende pa regjistrim',
		other: '${n} lutje ende pa regjistrim',
	);
	@override String get listenPrevious => 'Dhikri i mëparshëm';
	@override String get listenNext => 'Dhikri tjetër';
	@override String get listenPause => 'Ndalo përkohësisht';
	@override String get listenResume => 'Vazhdo';
	@override String get secListen => 'Dëgjimi';
	@override String get listenSub => 'Lexim me zë pa përdorur duart';
	@override String get listenGap => 'Pauza mes përsëritjeve';
	@override List<String> get listenGapLabels => [
		'Pa pauzë',
		'1 sek',
		'2 sek',
		'3 sek',
	];
	@override String get listenAppendix => 'Lexo dhikrin e gjatë';
	@override String get listenAppendixSub => 'Tehlili dhe tesbihu 100 herë, në fund të grupit. Rreth 20 minuta.';
	@override String get listenKeepScreenOn => 'Mbaje ekranin ndezur';
	@override String get listenKeepScreenOnSub => 'Për ta ndjekur leximin kur i ke duart të zëna. Kur është joaktiv, telefoni fik ekranin dhe vazhdon leximin.';
	@override String get listenReciter => 'Lexuesi';
	@override String get duaCopied => 'Lutja u kopjua';
	@override String get removeBookmark => 'Hiq shënuesin';
	@override String get bookmark => 'Shto shënues';
	@override String get copy => 'Kopjo';
	@override String get done => 'U krye';
	@override String get settings => 'Cilësimet';
	@override String get secPrayerTimes => 'Kohët e namazit';
	@override String get secReminders => 'Kujtuesit';
	@override String get secDisplay => 'Shfaqja';
	@override String get secLanguage => 'Gjuha';
	@override String get secAbout => 'Rreth aplikacionit';
	@override String get location => 'Vendndodhja';
	@override String get locYourLocationGps => 'Vendndodhja jote (GPS)';
	@override String locDeviceGps({required Object label}) => 'GPS i pajisjes · ${label}';
	@override String locFixedCity({required Object label}) => '${label} (qytet i caktuar)';
	@override String get calcMethod => 'Mënyra e llogaritjes';
	@override String get asrCalc => 'Llogaritja e ikindisë';
	@override String get nightTimes => 'Kohët e natës';
	@override String get showMidnight => 'Shfaq mesin e natës';
	@override String get showMidnightSub => 'Në mes të akshamit dhe sabahut';
	@override String get showLastThird => 'Shfaq të tretën e fundit të natës';
	@override String get showLastThirdSub => 'Kur fillon e treta e fundit mes akshamit dhe sabahut: koha për namazin e natës';
	@override String get notifications => 'Njoftimet';
	@override String get prayerReminders => 'Kujtuesit e namazit';
	@override String get prayerRemindersSub => 'Merr njoftim në çdo kohë namazi';
	@override String get dailyRemembrance => 'Dhikri ditor';
	@override String get dailyRemembranceSub => 'Dhikret e mëngjesit dhe mbrëmjes deri në përfundim, si dhe sunetet e së premtes dhe të natës';
	@override String get adhanSound => 'Zëri i ezanit';
	@override String get adhanSoundSub => 'Luaj ezanin në çdo kohë namazi';
	@override String get adhanNeedsReminders => 'Aktivizo Kujtuesit e namazit më sipër që ezani të luhet në kohët e namazit.';
	@override String get adhanExactAlarmsOff => 'Aktivizo «Alarmet dhe kujtuesit» për Hisn që ezani të luhet në kohën e namazit.';
	@override String get allowAlarms => 'Lejo';
	@override String get adhanFlipToSilence => 'Ktheje për ta heshtur';
	@override String get adhanFlipToSilenceSub => 'Ktheje telefonin me ekran poshtë për ta ndalur ezanin. Mund ta ndalësh edhe me njërin buton të zërit.';
	@override String get adhanVolume => 'Volumi i ezanit';
	@override List<String> get streamLabels => [
		'Media',
		'Zilja / njoftimet',
		'Alarmi',
	];
	@override List<String> get streamHints => [
		'Media: përdor volumin e muzikës dhe videove. Heshtja e ziles nuk e hesht domosdoshmërisht; kontrollo edhe volumin e medias dhe cilësimet «Mos shqetëso».',
		'Zilja: përdor volumin e ziles ose të njoftimeve. Modaliteti i heshtur, dridhja dhe «Mos shqetëso» mund ta heshtin ezanin.',
		'Alarmi: përdor volumin e alarmeve. Heshtja e ziles zakonisht nuk i hesht alarmet; kontrollo nëse «Mos shqetëso» i lejon alarmet.',
	];
	@override String get previewAdhan => 'Dëgjo ezanin provë';
	@override String get stopAdhan => 'Ndal ezanin';
	@override String get adhanVoice => 'Lexuesi i ezanit';
	@override String get adhanVoiceDefault => 'Ezani i përfshirë';
	@override String get adhanVoiceCustom => 'Skedari yt zanor';
	@override String get adhanVoiceCustomHint => 'Luhet për çdo namaz, përfshirë sabahun';
	@override String get adhanVoiceChooseFile => 'Zgjidh një skedar…';
	@override String get adhanVoiceChangeFile => 'Zgjidh një skedar tjetër';
	@override String get adhanVoiceUnreadable => 'Ky skedar nuk mund të lexohej.';
	@override String get adhanVoiceTooLarge => 'Skedari është tepër i madh. Zgjidh një skedar zanor nën 20 MB.';
	@override String get adhanVoiceNotPlayable => 'Ky skedar nuk mund të luhej. Zgjidh një skedar zanor, si MP3 ose OGG.';
	@override String get adhanPlaying => 'Po luhet ezani…';
	@override String get notifBlocked => 'Njoftimet janë bllokuar. Aktivizoji për Hisn te cilësimet e pajisjes.';
	@override String get textSize => 'Madhësia e tekstit';
	@override List<String> get fontScaleLabels => [
		'I vogël',
		'Standard',
		'I madh',
		'Shumë i madh',
	];
	@override String get showTransliteration => 'Shfaq transliterimin';
	@override String get showTransliterationSub => 'Shqiptimi me shkronja latine';
	@override String get showTranslation => 'Shfaq përkthimin';
	@override String get showTranslationSub => 'Kuptimi në shqip';
	@override String get aboutBody => 'Shoqërues për lutje dhe dhikër · prototip\nKohët e namazit llogariten me bibliotekën Adhan.';
	@override String get automatic => 'Automatike';
	@override String get useDeviceLocation => 'Përdor vendndodhjen e pajisjes';
	@override String get gpsActive => 'Aktiv · orari përputhet me vendndodhjen tënde';
	@override String get gpsDetect => 'Gjej me GPS (kërkon leje)';
	@override String get chooseCity => 'Zgjidh një qytet';
	@override String get cityNote => 'Orari i qytetit të zgjedhur shfaqet sipas zonës kohore të pajisjes. Është i saktë kur qyteti është në të njëjtën zonë kohore.';
	@override String get madhabStandard => 'Standard (Shafi, Maliki, Hanbeli)';
	@override String get madhabHanafi => 'Hanefi';
	@override String get asrHintStandard => 'Ikindia fillon kur hija e një objekti është sa gjatësia e tij';
	@override String get asrHintHanafi => 'Ikindia fillon kur hija e një objekti është sa dyfishi i gjatësisë së tij';
	@override String get prayerFajr => 'Sabahu';
	@override String get prayerSunrise => 'Lindja e diellit';
	@override String get markMidnight => 'Mesi i natës';
	@override String get markLastThird => 'E treta e fundit';
	@override String get prayerDhuhr => 'Dreka';
	@override String get prayerAsr => 'Ikindia';
	@override String get prayerMaghrib => 'Akshami';
	@override String get prayerIsha => 'Jacia';
	@override String get prayerNone => '—';
	@override String notifTitle({required Object name}) => 'Namazi: ${name}';
	@override String notifBody({required Object name, required Object place}) => 'Është koha e namazit: ${name} — ${place}.';
	@override String notifIqamahBody({required Object name, required Object place}) => 'Ikameti: ${name} — ${place}.';
	@override String get iqamahOffset => 'Vonesa e ikametit';
	@override String get iqamahAtAdhan => 'Në kohën e ezanit';
	@override String iqamahPlusMinutes({required Object minutes}) => '+${minutes} min';
	@override String get testNotifTitle => 'Kujtues provë';
	@override String get testNotifBody => 'Nëse e lexon këtë, kujtuesit e namazit po punojnë. 🌙';
	@override String get sendTestNotif => 'Dërgo njoftim provë';
	@override String get testSent => 'Prova u dërgua. Një njoftim duhet të shfaqet tani dhe një tjetër pas 12 sekondash. Kyçe telefonin.';
	@override String get testBlocked => 'U dërgua, por telefoni tregon se njoftimet për Hisn janë të fikura. Aktivizoji te Cilësimet → Aplikacionet → Hisn → Njoftimet.';
	@override String get batteryHint => 'Disa telefona, si Xiaomi/MIUI dhe Samsung, bllokojnë kujtuesit kur aplikacioni është i mbyllur. Nëse nuk mbërrijnë, lejo nisjen automatike dhe zgjidh «Pa kufizime» për baterinë e Hisn.';
	@override String get adhkarMorningTitle => 'Dhikret e mëngjesit';
	@override String get adhkarMorningBody => 'Filloje mëngjesin me përmendjen e Allahut — mbroje ditën tënde.';
	@override String get adhkarEveningTitle => 'Dhikret e mbrëmjes';
	@override String get adhkarEveningBody => 'Mbylle ditën me përmendjen e Allahut — mbroje mbrëmjen tënde.';
	@override String get kahfTitle => 'Surja El-Kehf';
	@override String get kahfBody => 'Është e premte. Lexo suren El-Kehf për dritë mes dy të premteve.';
	@override String get salawatTitle => 'Dërgo salavate mbi Profetin ﷺ';
	@override String get salawatBody => 'Merr pak kohë për të dërguar salavate mbi Profetin ﷺ.';
	@override String get salawatFridayTitle => 'Dërgo salavate mbi Profetin ﷺ';
	@override String get salawatFridayBody => 'Është e premte. Shtoji salavatet mbi Profetin ﷺ.';
	@override String get mulkTitle => 'Surja El-Mulk';
	@override String get mulkBody => 'Para gjumit, lexo suren El-Mulk.';
	@override String qiblaFromNorth({required Object degrees}) => 'Kibla · ${degrees}° nga veriu';
	@override String get facingQibla => 'Je përballë kiblës';
	@override String turnRight({required Object degrees}) => 'Kthehu djathtas ${degrees}°';
	@override String turnLeft({required Object degrees}) => 'Kthehu majtas ${degrees}°';
	@override String get calibrateHint => 'Lëvize në formën e numrit 8 për ta kalibruar';
	@override String get qiblaHoldFlat => 'Mbaje telefonin rrafsh për të lexuar busullën';
	@override String get qiblaInterference => 'Largohu nga metalet ose magnetet';
	@override String get qiblaTrueNorth => 'Korrigjuar sipas veriut gjeografik';
	@override String get qiblaMagneticOnly => 'Veriu magnetik — korrigjimi nuk është i mundur';
	@override String get compassUnavailable => 'Busulla nuk është e disponueshme';
	@override String get compassUnavailableBody => 'Kjo pajisje nuk ka magnetometër, prandaj nuk mund të tregojë drejtimin e kiblës në kohë reale.';
	@override String get qiblaNoLocation => 'Nevojitet vendndodhja';
	@override String get qiblaNoLocationBody => 'Drejtimi i kiblës nuk mund të llogaritet pa vendndodhjen tënde. Aktivizo vendndodhjen ose zgjidh qytetin te Cilësimet.';
	@override String get placeYourLocation => 'Vendndodhja jote';
	@override String get placeSelectedCity => 'Qyteti i zgjedhur';
	@override String get placeMakkah => 'Meka';
	@override String get onboardSkip => 'Kalo';
	@override String get onboardNext => 'Vazhdo';
	@override String get onboardGetStarted => 'Fillo';
	@override String get onboardWelcomeTitle => 'Mirë se erdhe në Hisn';
	@override String get onboardWelcomeBody => 'Shoqëruesi yt i përditshëm për dhikër, Kuran dhe namaz. Një udhëzim i shkurtër për të filluar.';
	@override String get onboardAdhkarTitle => 'Dhikret dhe lutjet';
	@override String get onboardAdhkarBody => 'Dhikret e mëngjesit dhe mbrëmjes, numëruesi i tesbihut dhe lutjet e tua. Prek një lutje për të numëruar përsëritjet.';
	@override String get onboardQuranTitle => 'Kurani i Shenjtë';
	@override String get onboardQuranBody => 'Lexo të gjithë Kuranin në mus\'haf, vazhdo aty ku e le dhe shëno ajetet që dëshiron t\'i ruash.';
	@override String get onboardPrayerTitle => 'Namazi dhe kibla';
	@override String get onboardPrayerBody => 'Kohët e namazit për vendndodhjen tënde, koha e mbetur deri te namazi tjetër dhe një busull drejt kiblës.';
	@override String get onboardPermsTitle => 'Disa leje';
	@override String get onboardPermsBody => 'Lejoji që Hisn të funksionojë sa më mirë. Mund t\'i ndryshosh kurdo te Cilësimet.';
	@override String get onboardLocationTitle => 'Vendndodhja';
	@override String get onboardLocationBody => 'Për të llogaritur saktë kohët e namazit dhe drejtimin e kiblës aty ku je.';
	@override String get onboardLocationAction => 'Lejo vendndodhjen';
	@override String get onboardNotifTitle => 'Njoftimet';
	@override String get onboardNotifBody => 'Një kujtues në çdo kohë namazi që të mos e humbasësh namazin.';
	@override String get onboardNotifAction => 'Aktivizo kujtuesit';
	@override String get onboardGranted => 'U aktivizua';
	@override String get secAppearance => 'Pamja';
	@override String get appearanceColors => 'Paleta e ngjyrave';
	@override String get appearanceTheme => 'Tema';
	@override String get themeLight => 'E çelët';
	@override String get themeDark => 'E errët';
	@override String get themeSystem => 'Sipas sistemit';
	@override String get paletteQibla => 'Kibël dhe tunxh';
	@override String get paletteEmerald => 'Smerald dhe ar';
	@override String get paletteSapphire => 'Safir dhe qiell';
	@override String get paletteAmethyst => 'Ametist dhe rozë';
	@override String get paletteRosewood => 'Dru palisandri';
	@override String get paletteLagoon => 'Lagunë';
	@override String get paletteDesert => 'Shkretëtirë';
	@override String get arabicFont => 'Shkronjat arabe';
	@override String get readingTheme => 'Sfondi i leximit';
	@override String get readingSystem => 'Sipas aplikacionit';
	@override String get readingSepia => 'Sepia';
	@override String get readingNight => 'Natë';
	@override String get patterns => 'Motivi gjeometrik';
	@override String get patternsSub => 'Zbukurim i lehtë në krye dhe te numëruesi';
	@override List<String> get ampm => [
		'PD',
		'MD',
	];
	@override List<String> get weekdaysShort => [
		'Hën',
		'Mar',
		'Mër',
		'Enj',
		'Pre',
		'Sht',
		'Die',
	];
	@override List<String> get monthsShort => [
		'Jan',
		'Shk',
		'Mar',
		'Pri',
		'Maj',
		'Qer',
		'Kor',
		'Gsh',
		'Sht',
		'Tet',
		'Nën',
		'Dhj',
	];
	@override String dateFormat({required Object weekday, required Object day, required Object month}) => '${weekday}, ${day} ${month}';
	@override List<String> get hijriMonths => [
		'Muharrem',
		'Safer',
		'Rebiul-evvel',
		'Rebiul-ahir',
		'Xhumadel-ula',
		'Xhumadel-ahire',
		'Rexheb',
		'Shaban',
		'Ramazan',
		'Sheval',
		'Dhul-kade',
		'Dhul-hixhe',
	];
	@override String hijriDateFormat({required Object day, required Object month, required Object year}) => '${day} ${month} ${year} H';
	@override String get hijriSuffix => 'H';
	@override String get secBackup => 'Kopja rezervë dhe rikthimi';
	@override String get backupSub => 'Ruaj përparimin në një skedar';
	@override String get backupOnThisDevice => 'Në këtë pajisje';
	@override String get backupSave => 'Ruaj një kopje rezervë';
	@override String get backupSaveHint => 'Ruaj të dhënat më poshtë në një skedar. Mund ta mbash te Drive ose Skedarët, ose t\'ia dërgosh vetes.';
	@override String get backupRestoreHeading => 'Rikthimi';
	@override String get backupRestore => 'Rikthe nga një skedar';
	@override String get backupRestoreHint => 'Zëvendëson të dhënat e pajisjes me përmbajtjen e kopjes rezervë.';
	@override String get backupPrivacy => 'Kopja rezervë është skedar teksti. Mbetet në pajisje nëse nuk e dërgon vetë diku. Hisn nuk e ngarkon kurrë.';
	@override String get backupStatStreak => 'Vargu aktual';
	@override String get backupStatBest => 'Vargu më i gjatë';
	@override String get backupStatDays => 'Ditë të mbrojtura';
	@override String get backupStatFavorites => 'Lutjet e ruajtura';
	@override String get backupStatCustom => 'Lutjet e mia';
	@override String get backupStatQuran => 'Shënuesit e Kuranit';
	@override String get restoreTitle => 'Ta rikthej këtë kopje rezervë?';
	@override String restoreSavedOn({required Object date}) => 'Ruajtur më ${date}';
	@override String restoreSavedOnVersion({required Object date, required Object version}) => 'Ruajtur më ${date} · v${version}';
	@override String get restoreScopeEverything => 'Gjithçka';
	@override String get restoreScopeEverythingSub => 'Përparimin dhe cilësimet';
	@override String get restoreScopeProgress => 'Vetëm përparimin';
	@override String get restoreScopeProgressSub => 'Mbaj vendndodhjen, kujtuesit dhe gjuhën e këtij telefoni';
	@override String get restoreWarning => 'Kjo zëvendëson të dhënat që ndodhen aktualisht në pajisje.';
	@override String get restoreAction => 'Rikthe';
	@override String restoreDone({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('sq'))(n,
		one: 'U rikthye 1 element',
		other: 'U rikthyen ${n} elemente',
	);
	@override String get backupSaved => 'Kopja rezervë është gati për t\'u ruajtur';
	@override String get backupFailed => 'Kopja rezervë nuk mund të krijohej';
	@override String get restoreErrMalformed => 'Ky skedar nuk mund të lexohej.';
	@override String get restoreErrNotABackup => 'Ky nuk është skedar kopjeje rezervë i Hisn.';
	@override String get restoreErrTooNew => 'Kjo kopje u krijua me një version më të ri të Hisn. Përditëso fillimisht aplikacionin.';
	@override String get restoreErrEmpty => 'Kjo kopje rezervë nuk ka asgjë për t\'u rikthyer.';
	@override String get restoreFailed => 'Rikthimi dështoi. Asgjë nuk ndryshoi.';
	@override String get quranZoomIn => 'Zmadho';
	@override String get quranZoomHint => 'Largo dy gishtat për ta zmadhuar; afroji për t’u kthyer.';
	@override String get quranReaderOptions => 'Opsionet e leximit';
	@override String get versesOnThisPage => 'Ajetet në këtë faqe';
	@override String get savedVerses => 'Ajetet e ruajtura';
	@override String get savedPages => 'Faqet e ruajtura';
	@override String get saveVerse => 'Ruaj ajetin';
	@override String get unsaveVerse => 'Hiq ajetin e ruajtur';
	@override String get secCalendar => 'Kalendari islam';
	@override String get calendarSub => 'Agjërimet sunet dhe datat hixhri';
	@override String get sunnahCalendarTitle => 'Agjërimet dhe datat';
	@override String get upcomingLabel => 'Në vijim';
	@override String get nothingUpcoming => 'Nuk ka data të shënuara në dy muajt e ardhshëm.';
	@override String get calendarNote => 'Datat llogariten sipas Umm al-Kura dhe mund të ndryshojnë me një ditë nga vrojtimi vendor i hënës.';
	@override String get fastingRecommended => 'Agjërimi është sunet';
	@override String get fastingObligatory => 'Agjërim i detyrueshëm';
	@override String get fastingForbidden => 'Ditë kur nuk lejohet agjërimi';
	@override String get fastingNoneToday => 'Sot nuk ka agjërim të veçantë.';
	@override String get fastRamadan => 'Ramazani';
	@override String get fastMonday => 'Agjërimi i së hënës';
	@override String get fastThursday => 'Agjërimi i së enjtes';
	@override String get fastWhiteDay => 'Ditët e bardha';
	@override String get fastTasua => 'Tasuaja';
	@override String get fastAshura => 'Ashuraja';
	@override String get fastDhulHijjah => 'Dhjetë ditët e Dhul-hixhes';
	@override String get fastArafah => 'Dita e Arafatit';
	@override String get fastSixOfShawwal => 'Gjashtë ditët e Shevalit';
	@override String get fastRamadanSub => 'Agjërimi i detyrueshëm i muajit.';
	@override String get fastMondaySub => 'Veprat paraqiten të hënën dhe të enjten. — Tirmidhiu';
	@override String get fastThursdaySub => 'Veprat paraqiten të hënën dhe të enjten. — Tirmidhiu';
	@override String get fastWhiteDaySub => 'Dita e 13-të, e 14-të dhe e 15-të e çdo muaji hixhri. — Buhariu dhe Muslimi';
	@override String get fastTasuaSub => 'Agjërohet bashkë me ditën e dhjetë. — Muslimi';
	@override String get fastAshuraSub => 'Shlyen gjynahet e vitit të kaluar. — Muslimi';
	@override String get fastDhulHijjahSub => 'Nuk ka ditë kur veprat e mira janë më të dashura tek Allahu se këto. — Buhariu';
	@override String get fastArafahSub => 'Shlyen gjynahet e vitit të kaluar dhe të ardhshëm, për ata që nuk janë në haxh. — Muslimi';
	@override String get fastSixOfShawwalSub => 'Kush agjëron Ramazanin dhe e pason me gjashtë ditë të Shevalit, është sikur të ketë agjëruar gjithë vitin. — Muslimi';
	@override String get eventNewYear => 'Viti i ri hixhri';
	@override String get eventAshura => 'Ashuraja';
	@override String get eventRamadan => 'Fillon Ramazani';
	@override String get eventLastTen => 'Dhjetë netët e fundit';
	@override String get eventEidFitr => 'Fitër Bajrami';
	@override String get eventDhulHijjah => 'Fillon Dhul-hixheja';
	@override String get eventArafah => 'Dita e Arafatit';
	@override String get eventEidAdha => 'Kurban Bajrami';
	@override String get eventLastTenSub => 'Nata e Kadrit kërkohet në netët teke të këtyre dhjetë netëve.';
	@override String get barEidAlFitr => 'Agjërimi nuk lejohet në Fitër Bajram.';
	@override String get barEidAlAdha => 'Agjërimi nuk lejohet në Kurban Bajram.';
	@override String get barTashriq => 'Agjërimi nuk lejohet në ditët e Teshrikut.';
	@override String get hijriAdjust => 'Përshtatja e datës hixhri';
	@override String get hijriAdjustHint => 'Data e llogaritur mund të jetë një ditë para ose pas vrojtimit vendor. Përshtate me bashkësinë tënde.';
	@override List<String> get hijriOffsetLabels => [
		'−2 ditë',
		'−1 ditë',
		'Pa ndryshim',
		'+1 ditë',
		'+2 ditë',
	];
	@override String get fastingReminders => 'Kujtuesit e agjërimit';
	@override String get fastingRemindersSub => 'Kujtues mbrëmjen para një agjërimi sunet';
	@override String get notifFastTitle => 'Agjërimi nesër';
	@override String notifFastBody({required Object name}) => 'Nesër është ${name} — agjërim nga Suneti.';
	@override String get notifOccasionBody => 'Nesër, në dashtë Allahu.';
	@override String get share => 'Ndaj';
	@override String get shareAsImage => 'Ndaj kartën';
	@override String get shareAsText => 'Ndaj tekstin';
	@override String get shareImageFailedNotReady => 'Karta nuk ishte gati për t\'u kthyer në imazh. Po ndahet teksti.';
	@override String get shareImageFailedUnsupported => 'Pajisja nuk mund të krijonte imazhin. Po ndahet teksti.';
	@override String get nextPhraseOnTap => 'Shprehja përfundoi. Prek për të numëruar shprehjen tjetër.';
	@override String get aboutContributors => 'Njerëzit pas Hisn';
	@override String get aboutDeveloperCredit => 'Zhvillues · Projektoi dhe zhvilloi aplikacionin.';
	@override String get aboutContentReviewerCredit => 'Kontribues · Ndihmoi në shqyrtimin e përmbajtjes së aplikacionit për gabime shtypi dhe pasaktësi faktike.';
	@override String get aboutProfileLinkCopied => 'Lidhja e profilit në GitHub u kopjua. Hape në shfletues.';
	@override String get aboutTypefaces => 'Shkronjat';
	@override String get aboutVerseMeanings => 'Kuptimet e ajeteve';
	@override String get aboutDuaDraftCredit => 'Disa kuptime të lutjeve janë përkthime paraprake të Hisn; në pritje të shqyrtimit gjuhësor dhe fetar nga specialistë.';
	@override String get aboutTranslationSource => 'Burimet e përkthimit · Tanzil';
	@override String get aboutLinkCopied => 'Lidhja e burimit u kopjua. Hape në shfletues.';
	@override String get aboutArabicText => 'Teksti arabisht';
	@override String get aboutLatinText => 'Teksti me shkronja latine';
	@override String get aboutLatinApparatus => 'Teksti i ndërfaqes me shkronja latine';
	@override String get aboutMushafPages => 'Faqet e mus\'hafit · Kompleksi Mbreti Fehd për Shtypjen e Kuranit Fisnik';
	@override String get prayerCountdownTitle => 'Koha deri te namazi tjetër';
	@override String get prayerCountdownSubtitle => 'Mbaj te njoftimet namazin tjetër, kohën nga ezani dhe datën hixhri.';
	@override String get prayerCountdownUnavailable => 'Disponohet në Android. Sistemi vendos si shfaqet numërimi.';
	@override String get prayerCountdownChannelDescription => 'Numërim i heshtur deri te namazi tjetër';
	@override String get guideTitle => 'Udhëzues i shkurtër';
	@override String get guideWelcomeTitle => 'Njihu me Hisn';
	@override String get guideWelcomeBody => 'Shih ku gjenden tesbihu, kërkimi në Kuran, mjetet e namazit, pamja dhe kujtuesit. Mund ta hapësh sërish udhëzuesin te Cilësimet.';
	@override String get viewGuide => 'Shih udhëzuesin';
	@override String get replayGuide => 'Shih udhëzuesin e aplikacionit';
	@override String get replayGuideSub => 'Një prezantim i veçorive kryesore';
	@override String get guideDone => 'U krye';
	@override String guideProgress({required Object current, required Object total}) => '${current} nga ${total}';
	@override String get guideTasbihBody => 'Hap Tesbihun për të zgjedhur një shprehje, për të shtuar tënden dhe për të numëruar përsëritjet.';
	@override String get guideQuranBody => 'Kërko një sure ose shkruaj fjalë arabe për të gjetur ajete në Kuran.';
	@override String get guidePrayerBody => 'Këtu gjen kohët e namazit dhe kiblën. Lejen e vendndodhjes e zgjedh te cilësimet e namazit.';
	@override String get guideAppearanceBody => 'Zgjidh temën e çelët, të errët ose sipas sistemit. Hap Pamjen në këtë meny për të zgjedhur ngjyrat.';
	@override String get guideNotificationsBody => 'Zgjidh kujtuesit dhe ezanin, cakto oraret e heshtjes ose ndali të gjithë kujtuesit te Njoftimet. Lejet aktivizoji kur të duash.';
	@override String get prayerSilenceTitle => 'Heshtja gjatë namazit';
	@override String get prayerSilenceSub => 'Heshtje automatike pas ezanit';
	@override String get prayerSilenceEnable => 'Aktivizo heshtjen për namaz';
	@override String get prayerSilenceBody => 'Hesht thirrjet dhe njoftimet gjatë intervalit që zgjedh pas çdo ezani. Alarmet mbeten të lejuara. Modalitete të tjera «Mos shqetëso» mund të zbatojnë kufizime më të rrepta.';
	@override String get prayerSilenceTimingHint => 'Fillimi dhe fundi maten në minuta pas ezanit. Nëse Hisn ende po luan ezanin, heshtja pret derisa të mbarojë; ora e përfundimit nuk ndryshon.';
	@override String get prayerSilenceStart => 'Fillo pas ezanit';
	@override String get prayerSilenceEnd => 'Përfundo pas ezanit';
	@override String prayerSilenceMinutes({required Object minutes}) => '${minutes} min';
	@override String get prayerSilencePolicyButton => 'Lejo qasjen te «Mos shqetëso»';
	@override String get prayerSilenceExactButton => 'Lejo orarin e saktë';
	@override String get prayerSilenceDisabled => 'Heshtja për namaz është joaktive';
	@override String get prayerSilencePermission => 'Lejo qasjen te «Mos shqetëso» për të përdorur heshtjen për namaz.';
	@override String get prayerSilenceExact => 'Në pauzë: nevojitet leja për alarme të sakta që të fillojë dhe të përfundojë në kohë.';
	@override String get prayerSilenceLocation => 'Zgjidh qytetin ose lejo vendndodhjen për të llogaritur intervalet e namazit.';
	@override String get prayerSilenceReady => 'Gati për intervalin e namazit tjetër';
	@override String prayerSilenceActiveUntil({required Object time}) => 'Heshtja për namaz është aktive deri në ${time}';
	@override String get prayerSilenceWaiting => 'Në pritje të përfundimit të ezanit';
	@override String get prayerSilenceRuleDisabled => 'Modaliteti i namazit i Hisn është çaktivizuar te cilësimet e Android.';
	@override String get prayerSilenceUnavailable => 'Heshtja për namaz disponohet vetëm në Android.';
	@override String get prayerSilenceError => 'Heshtja për namaz nuk mund të caktohej. Kontrollo lejet dhe provo sërish.';
	@override String get prayerSilenceStopNow => 'Përfundo këtë interval heshtjeje';
	@override String get prayerSilenceExpiryNote => 'Vetëm modaliteti i Hisn përfundon vetvetiu; modaliteti yt «Mos shqetëso» nuk ndryshon. Android mund ta vonojë kontrollin rezervë të përfundimit nëse hiqet leja për alarme të sakta ose kufizohet aplikacioni.';
	@override String get qiblaStyle => 'Pamja e busullës';
	@override String get qiblaTone => 'Ngjyra e busullës';
	@override String get qiblaVibrationOn => 'Dridhja aktive';
	@override String get qiblaVibrationOff => 'Dridhja joaktive';
	@override List<String> get qiblaStyles => [
		'Klasike',
		'E thjeshtë',
		'Trëndafili i erërave',
	];
	@override List<String> get qiblaTones => [
		'Ngjyra e temës',
		'Ar',
		'Bojë',
	];
	@override String durationMinutes({required Object minutes}) => '${minutes} min';
	@override String durationHoursMinutes({required Object hours, required Object minutes}) => '${hours} orë ${minutes} min';
}

/// The flat map containing all translations for locale <sq>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsSq {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'navAdhkar' => 'Dhikri',
			'navQuran' => 'Kurani',
			'navTasbih' => 'Tesbih',
			'navQibla' => 'Kibla',
			'navSaved' => 'Të ruajtura',
			'navSettings' => 'Cilësimet',
			'navPrayer' => 'Namazi',
			'prayerQiblaTitle' => 'Namazi dhe kibla',
			'weeklySchedule' => 'Orari javor',
			'searchDuas' => 'Kërko lutje…',
			'allAdhkar' => 'Të gjitha dhikret',
			'groupDaily' => 'Dhikret ditore',
			'groupSituational' => 'Për çdo rast',
			'groupMine' => 'Të miat',
			'muhassanHeading' => 'Muhassan',
			'muhassanToday' => ({required Object percent}) => 'Sot je ${percent}% i mbrojtur',
			'muhassanComplete' => 'Plotësisht i mbrojtur — mashaAllah',
			'muhassanMorning' => 'Mëngjesi',
			'muhassanEvening' => 'Mbrëmja',
			'streakDays' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('sq'))(n, one: '1 ditë radhazi', other: '${n} ditë radhazi', ), 
			'streakStart' => 'Fillo vargun tënd',
			'streakBest' => ({required Object n}) => 'Më i miri: ${n}',
			'streakTitle' => 'Vargu yt',
			'streakWord' => 'ditë radhazi',
			'statCurrent' => 'Aktual',
			'statBest' => 'Më i miri',
			'statTotal' => 'Ditë gjithsej',
			'daysValue' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('sq'))(n, one: '1 ditë', other: '${n} ditë', ), 
			'streakOnFire' => 'Po ecën shumë mirë — vazhdo!',
			'streakTodayPending' => 'Përfundo dhikret e sotme për të vazhduar vargun',
			'streakBroken' => 'Përfundo dhikret e mëngjesit dhe mbrëmjes për të rifilluar',
			'last4Weeks' => '4 javët e fundit',
			'todayLabel' => 'Sot',
			'fortifiedLegend' => 'I mbrojtur',
			'weekdayLetters.0' => 'H',
			'weekdayLetters.1' => 'M',
			'weekdayLetters.2' => 'M',
			'weekdayLetters.3' => 'E',
			'weekdayLetters.4' => 'P',
			'weekdayLetters.5' => 'S',
			'weekdayLetters.6' => 'D',
			'quranTitle' => 'Kurani',
			'searchSurah' => 'Kërko sure…',
			'searchQuran' => 'Kërko sure ose fjalë arabe',
			'quranSearchSurahs' => 'Suret',
			'quranSearchVerses' => 'Ajetet',
			'quranSearchFailed' => 'Kërkimi i ajeteve dështoi. Provo sërish.',
			'quranSearchLimit' => 'Shfaqen 50 rezultatet e para të ajeteve',
			'retrySearch' => 'Kërko sërish',
			'afterPrayerTasbih' => 'Tesbihu pas namazit',
			'startAfterPrayerTasbih' => 'Numëro dhikrin pas namazit',
			'currentPhrase' => 'Shprehja aktuale',
			'afterPrayerComplete' => 'Dhikri pas namazit përfundoi.',
			'continueReading' => 'Vazhdo leximin',
			'surahWord' => 'Sure',
			'revelationMeccan' => 'Mekase',
			'revelationMedinan' => 'Medinase',
			'versesCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('sq'))(n, one: '1 ajet', other: '${n} ajete', ), 
			'juzLabel' => ({required Object n}) => 'Xhuzi ${n}',
			'quranBookmarks' => 'Shënuesit',
			'noBookmarks' => 'Ende pa shënues',
			'bookmarkAdded' => 'Shënuesi u shtua',
			'bookmarkRemoved' => 'Shënuesi u hoq',
			'goToAyah' => 'Shko te ajeti',
			'chooseSurah' => 'Surja',
			'verseNumber' => 'Numri i ajetit',
			'verseRange' => ({required Object n}) => '1–${n}',
			'goAction' => 'Shko',
			'myDuas' => 'Lutjet e mia',
			'myDuasSub' => 'Lutjet që shton vetë',
			'addDua' => 'Shto lutje',
			'newDua' => 'Lutje e re',
			'fieldArabic' => 'Teksti arabisht',
			'fieldArabicRequired' => 'Shkruaj tekstin arabisht',
			'fieldTitle' => 'Titulli (opsional)',
			'fieldTransliteration' => 'Transliterimi (opsional)',
			'fieldTranslation' => 'Përkthimi / kuptimi (opsional)',
			'fieldReference' => 'Burimi (opsional)',
			'fieldRepeat' => 'Përsëritjet',
			'fieldRepeatPositiveRequired' => 'Shkruaj një numër të plotë, të paktën 1.',
			'addDhikr' => 'Shto dhikër',
			'editDhikr' => 'Ndrysho dhikrin',
			'deleteDhikr' => 'Fshi dhikrin',
			'deleteDhikrConfirm' => 'Ta heq këtë dhikër dhe numërimin e tij të ruajtur?',
			'fieldDhikrName' => 'Emri',
			'fieldDhikrNameRequired' => 'Shkruaj një emër për këtë dhikër.',
			'fieldDhikrTargetRequired' => 'Shkruaj një numër të plotë nga 1 deri në 1 000 000.',
			'nextSetOnTap' => 'Cikli përfundoi. Prek për të nisur ciklin tjetër.',
			'customDhikrTargetNote' => 'Zgjidh numrin e përsëritjeve për seancën tënde.',
			'save' => 'Ruaj',
			'cancel' => 'Anulo',
			'delete' => 'Fshi',
			'deleteDua' => 'Fshi lutjen',
			'deleteDuaConfirm' => 'Ta heq këtë lutje nga Lutjet e mia?',
			'duaSaved' => 'Lutja u ruajt',
			'duaUpdated' => 'Lutja u përditësua',
			'editDua' => 'Ndrysho lutjen',
			'edit' => 'Ndrysho',
			'noCustomTitle' => 'Ende pa lutje',
			'noCustomBody' => 'Prek + për të shtuar dhe ruajtur lutjen tënde këtu.',
			'recommendedNow' => 'Rekomandohet tani',
			'readNow' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('sq'))(count, one: 'Lexo tani · 1 lutje', other: 'Lexo tani · ${count} lutje', ), 
			'duaCount' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('sq'))(count, one: '1 lutje', other: '${count} lutje', ), 
			'now' => 'Tani',
			'next' => 'Më pas',
			'remaining' => 'mbeten',
			'countdownNow' => 'tani',
			'sinceAdhan' => 'Nga ezani',
			'todaysPrayers' => ({required Object location}) => 'Namazet e sotme · ${location}',
			'searchHint' => 'Kërko lutje, kuptime, burime…',
			'clear' => 'Pastro',
			'searchPrompt' => 'Kërko sipas titullit, kuptimit, transliterimit ose burimit.',
			'noResults' => ({required Object query}) => 'Nuk u gjetën lutje për «${query}».',
			'quranNoResults' => ({required Object query}) => 'Nuk u gjetën sure ose ajete për «${query}».',
			'resultsCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('sq'))(n, one: '1 rezultat', other: '${n} rezultate', ), 
			'noSavedTitle' => 'Ende pa lutje të ruajtura',
			'noSavedBody' => 'Prek shënuesin te një lutje për ta ruajtur këtu dhe për ta gjetur shpejt.',
			'resetCount' => 'Nis numërimin nga zero',
			'tapToCount' => 'Prek kudo për të numëruar',
			'setsCompleted' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('sq'))(n, one: '1 cikël i përfunduar', other: '${n} cikle të përfunduara', ), 
			'ofTarget' => ({required Object n}) => 'nga ${n}',
			'resetProgress' => 'Nis përparimin nga e para',
			'setComplete' => 'Cikli përfundoi — Allahu ta pranoftë',
			'tapEachDua' => 'Prek çdo lutje për të numëruar përsëritjet',
			'listenAction' => 'Dëgjo',
			'listenStart' => 'Luaj grupin',
			'listenRestart' => 'Rifillo nga e para',
			'listenHint' => 'Po luhet — mund ta kyçësh telefonin',
			'listenIdleTitle' => 'Asgjë nuk po luhet',
			'listenIdleBody' => 'Luaj grupin për ta dëgjuar me zë. Përsëritjet numërohen automatikisht.',
			'listenMissing' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('sq'))(n, one: '1 lutje ende pa regjistrim', other: '${n} lutje ende pa regjistrim', ), 
			'listenPrevious' => 'Dhikri i mëparshëm',
			'listenNext' => 'Dhikri tjetër',
			'listenPause' => 'Ndalo përkohësisht',
			'listenResume' => 'Vazhdo',
			'secListen' => 'Dëgjimi',
			'listenSub' => 'Lexim me zë pa përdorur duart',
			'listenGap' => 'Pauza mes përsëritjeve',
			'listenGapLabels.0' => 'Pa pauzë',
			'listenGapLabels.1' => '1 sek',
			'listenGapLabels.2' => '2 sek',
			'listenGapLabels.3' => '3 sek',
			'listenAppendix' => 'Lexo dhikrin e gjatë',
			'listenAppendixSub' => 'Tehlili dhe tesbihu 100 herë, në fund të grupit. Rreth 20 minuta.',
			'listenKeepScreenOn' => 'Mbaje ekranin ndezur',
			'listenKeepScreenOnSub' => 'Për ta ndjekur leximin kur i ke duart të zëna. Kur është joaktiv, telefoni fik ekranin dhe vazhdon leximin.',
			'listenReciter' => 'Lexuesi',
			'duaCopied' => 'Lutja u kopjua',
			'removeBookmark' => 'Hiq shënuesin',
			'bookmark' => 'Shto shënues',
			'copy' => 'Kopjo',
			'done' => 'U krye',
			'settings' => 'Cilësimet',
			'secPrayerTimes' => 'Kohët e namazit',
			'secReminders' => 'Kujtuesit',
			'secDisplay' => 'Shfaqja',
			'secLanguage' => 'Gjuha',
			'secAbout' => 'Rreth aplikacionit',
			'location' => 'Vendndodhja',
			'locYourLocationGps' => 'Vendndodhja jote (GPS)',
			'locDeviceGps' => ({required Object label}) => 'GPS i pajisjes · ${label}',
			'locFixedCity' => ({required Object label}) => '${label} (qytet i caktuar)',
			'calcMethod' => 'Mënyra e llogaritjes',
			'asrCalc' => 'Llogaritja e ikindisë',
			'nightTimes' => 'Kohët e natës',
			'showMidnight' => 'Shfaq mesin e natës',
			'showMidnightSub' => 'Në mes të akshamit dhe sabahut',
			'showLastThird' => 'Shfaq të tretën e fundit të natës',
			'showLastThirdSub' => 'Kur fillon e treta e fundit mes akshamit dhe sabahut: koha për namazin e natës',
			'notifications' => 'Njoftimet',
			'prayerReminders' => 'Kujtuesit e namazit',
			'prayerRemindersSub' => 'Merr njoftim në çdo kohë namazi',
			'dailyRemembrance' => 'Dhikri ditor',
			'dailyRemembranceSub' => 'Dhikret e mëngjesit dhe mbrëmjes deri në përfundim, si dhe sunetet e së premtes dhe të natës',
			'adhanSound' => 'Zëri i ezanit',
			'adhanSoundSub' => 'Luaj ezanin në çdo kohë namazi',
			'adhanNeedsReminders' => 'Aktivizo Kujtuesit e namazit më sipër që ezani të luhet në kohët e namazit.',
			'adhanExactAlarmsOff' => 'Aktivizo «Alarmet dhe kujtuesit» për Hisn që ezani të luhet në kohën e namazit.',
			'allowAlarms' => 'Lejo',
			'adhanFlipToSilence' => 'Ktheje për ta heshtur',
			'adhanFlipToSilenceSub' => 'Ktheje telefonin me ekran poshtë për ta ndalur ezanin. Mund ta ndalësh edhe me njërin buton të zërit.',
			'adhanVolume' => 'Volumi i ezanit',
			'streamLabels.0' => 'Media',
			'streamLabels.1' => 'Zilja / njoftimet',
			'streamLabels.2' => 'Alarmi',
			'streamHints.0' => 'Media: përdor volumin e muzikës dhe videove. Heshtja e ziles nuk e hesht domosdoshmërisht; kontrollo edhe volumin e medias dhe cilësimet «Mos shqetëso».',
			'streamHints.1' => 'Zilja: përdor volumin e ziles ose të njoftimeve. Modaliteti i heshtur, dridhja dhe «Mos shqetëso» mund ta heshtin ezanin.',
			'streamHints.2' => 'Alarmi: përdor volumin e alarmeve. Heshtja e ziles zakonisht nuk i hesht alarmet; kontrollo nëse «Mos shqetëso» i lejon alarmet.',
			'previewAdhan' => 'Dëgjo ezanin provë',
			'stopAdhan' => 'Ndal ezanin',
			'adhanVoice' => 'Lexuesi i ezanit',
			'adhanVoiceDefault' => 'Ezani i përfshirë',
			'adhanVoiceCustom' => 'Skedari yt zanor',
			'adhanVoiceCustomHint' => 'Luhet për çdo namaz, përfshirë sabahun',
			'adhanVoiceChooseFile' => 'Zgjidh një skedar…',
			'adhanVoiceChangeFile' => 'Zgjidh një skedar tjetër',
			'adhanVoiceUnreadable' => 'Ky skedar nuk mund të lexohej.',
			'adhanVoiceTooLarge' => 'Skedari është tepër i madh. Zgjidh një skedar zanor nën 20 MB.',
			'adhanVoiceNotPlayable' => 'Ky skedar nuk mund të luhej. Zgjidh një skedar zanor, si MP3 ose OGG.',
			'adhanPlaying' => 'Po luhet ezani…',
			'notifBlocked' => 'Njoftimet janë bllokuar. Aktivizoji për Hisn te cilësimet e pajisjes.',
			'textSize' => 'Madhësia e tekstit',
			'fontScaleLabels.0' => 'I vogël',
			'fontScaleLabels.1' => 'Standard',
			'fontScaleLabels.2' => 'I madh',
			'fontScaleLabels.3' => 'Shumë i madh',
			'showTransliteration' => 'Shfaq transliterimin',
			'showTransliterationSub' => 'Shqiptimi me shkronja latine',
			'showTranslation' => 'Shfaq përkthimin',
			'showTranslationSub' => 'Kuptimi në shqip',
			'aboutBody' => 'Shoqërues për lutje dhe dhikër · prototip\nKohët e namazit llogariten me bibliotekën Adhan.',
			'automatic' => 'Automatike',
			'useDeviceLocation' => 'Përdor vendndodhjen e pajisjes',
			'gpsActive' => 'Aktiv · orari përputhet me vendndodhjen tënde',
			'gpsDetect' => 'Gjej me GPS (kërkon leje)',
			'chooseCity' => 'Zgjidh një qytet',
			'cityNote' => 'Orari i qytetit të zgjedhur shfaqet sipas zonës kohore të pajisjes. Është i saktë kur qyteti është në të njëjtën zonë kohore.',
			'madhabStandard' => 'Standard (Shafi, Maliki, Hanbeli)',
			'madhabHanafi' => 'Hanefi',
			'asrHintStandard' => 'Ikindia fillon kur hija e një objekti është sa gjatësia e tij',
			'asrHintHanafi' => 'Ikindia fillon kur hija e një objekti është sa dyfishi i gjatësisë së tij',
			'prayerFajr' => 'Sabahu',
			'prayerSunrise' => 'Lindja e diellit',
			'markMidnight' => 'Mesi i natës',
			'markLastThird' => 'E treta e fundit',
			'prayerDhuhr' => 'Dreka',
			'prayerAsr' => 'Ikindia',
			'prayerMaghrib' => 'Akshami',
			'prayerIsha' => 'Jacia',
			'prayerNone' => '—',
			'notifTitle' => ({required Object name}) => 'Namazi: ${name}',
			'notifBody' => ({required Object name, required Object place}) => 'Është koha e namazit: ${name} — ${place}.',
			'notifIqamahBody' => ({required Object name, required Object place}) => 'Ikameti: ${name} — ${place}.',
			'iqamahOffset' => 'Vonesa e ikametit',
			'iqamahAtAdhan' => 'Në kohën e ezanit',
			'iqamahPlusMinutes' => ({required Object minutes}) => '+${minutes} min',
			'testNotifTitle' => 'Kujtues provë',
			'testNotifBody' => 'Nëse e lexon këtë, kujtuesit e namazit po punojnë. 🌙',
			'sendTestNotif' => 'Dërgo njoftim provë',
			'testSent' => 'Prova u dërgua. Një njoftim duhet të shfaqet tani dhe një tjetër pas 12 sekondash. Kyçe telefonin.',
			'testBlocked' => 'U dërgua, por telefoni tregon se njoftimet për Hisn janë të fikura. Aktivizoji te Cilësimet → Aplikacionet → Hisn → Njoftimet.',
			'batteryHint' => 'Disa telefona, si Xiaomi/MIUI dhe Samsung, bllokojnë kujtuesit kur aplikacioni është i mbyllur. Nëse nuk mbërrijnë, lejo nisjen automatike dhe zgjidh «Pa kufizime» për baterinë e Hisn.',
			'adhkarMorningTitle' => 'Dhikret e mëngjesit',
			'adhkarMorningBody' => 'Filloje mëngjesin me përmendjen e Allahut — mbroje ditën tënde.',
			'adhkarEveningTitle' => 'Dhikret e mbrëmjes',
			'adhkarEveningBody' => 'Mbylle ditën me përmendjen e Allahut — mbroje mbrëmjen tënde.',
			'kahfTitle' => 'Surja El-Kehf',
			'kahfBody' => 'Është e premte. Lexo suren El-Kehf për dritë mes dy të premteve.',
			'salawatTitle' => 'Dërgo salavate mbi Profetin ﷺ',
			'salawatBody' => 'Merr pak kohë për të dërguar salavate mbi Profetin ﷺ.',
			'salawatFridayTitle' => 'Dërgo salavate mbi Profetin ﷺ',
			'salawatFridayBody' => 'Është e premte. Shtoji salavatet mbi Profetin ﷺ.',
			'mulkTitle' => 'Surja El-Mulk',
			'mulkBody' => 'Para gjumit, lexo suren El-Mulk.',
			'qiblaFromNorth' => ({required Object degrees}) => 'Kibla · ${degrees}° nga veriu',
			'facingQibla' => 'Je përballë kiblës',
			'turnRight' => ({required Object degrees}) => 'Kthehu djathtas ${degrees}°',
			'turnLeft' => ({required Object degrees}) => 'Kthehu majtas ${degrees}°',
			'calibrateHint' => 'Lëvize në formën e numrit 8 për ta kalibruar',
			'qiblaHoldFlat' => 'Mbaje telefonin rrafsh për të lexuar busullën',
			'qiblaInterference' => 'Largohu nga metalet ose magnetet',
			'qiblaTrueNorth' => 'Korrigjuar sipas veriut gjeografik',
			'qiblaMagneticOnly' => 'Veriu magnetik — korrigjimi nuk është i mundur',
			'compassUnavailable' => 'Busulla nuk është e disponueshme',
			'compassUnavailableBody' => 'Kjo pajisje nuk ka magnetometër, prandaj nuk mund të tregojë drejtimin e kiblës në kohë reale.',
			'qiblaNoLocation' => 'Nevojitet vendndodhja',
			'qiblaNoLocationBody' => 'Drejtimi i kiblës nuk mund të llogaritet pa vendndodhjen tënde. Aktivizo vendndodhjen ose zgjidh qytetin te Cilësimet.',
			'placeYourLocation' => 'Vendndodhja jote',
			'placeSelectedCity' => 'Qyteti i zgjedhur',
			'placeMakkah' => 'Meka',
			'onboardSkip' => 'Kalo',
			'onboardNext' => 'Vazhdo',
			'onboardGetStarted' => 'Fillo',
			'onboardWelcomeTitle' => 'Mirë se erdhe në Hisn',
			'onboardWelcomeBody' => 'Shoqëruesi yt i përditshëm për dhikër, Kuran dhe namaz. Një udhëzim i shkurtër për të filluar.',
			'onboardAdhkarTitle' => 'Dhikret dhe lutjet',
			'onboardAdhkarBody' => 'Dhikret e mëngjesit dhe mbrëmjes, numëruesi i tesbihut dhe lutjet e tua. Prek një lutje për të numëruar përsëritjet.',
			'onboardQuranTitle' => 'Kurani i Shenjtë',
			'onboardQuranBody' => 'Lexo të gjithë Kuranin në mus\'haf, vazhdo aty ku e le dhe shëno ajetet që dëshiron t\'i ruash.',
			'onboardPrayerTitle' => 'Namazi dhe kibla',
			'onboardPrayerBody' => 'Kohët e namazit për vendndodhjen tënde, koha e mbetur deri te namazi tjetër dhe një busull drejt kiblës.',
			'onboardPermsTitle' => 'Disa leje',
			'onboardPermsBody' => 'Lejoji që Hisn të funksionojë sa më mirë. Mund t\'i ndryshosh kurdo te Cilësimet.',
			'onboardLocationTitle' => 'Vendndodhja',
			'onboardLocationBody' => 'Për të llogaritur saktë kohët e namazit dhe drejtimin e kiblës aty ku je.',
			'onboardLocationAction' => 'Lejo vendndodhjen',
			'onboardNotifTitle' => 'Njoftimet',
			'onboardNotifBody' => 'Një kujtues në çdo kohë namazi që të mos e humbasësh namazin.',
			'onboardNotifAction' => 'Aktivizo kujtuesit',
			'onboardGranted' => 'U aktivizua',
			'secAppearance' => 'Pamja',
			'appearanceColors' => 'Paleta e ngjyrave',
			'appearanceTheme' => 'Tema',
			'themeLight' => 'E çelët',
			'themeDark' => 'E errët',
			'themeSystem' => 'Sipas sistemit',
			'paletteQibla' => 'Kibël dhe tunxh',
			'paletteEmerald' => 'Smerald dhe ar',
			'paletteSapphire' => 'Safir dhe qiell',
			'paletteAmethyst' => 'Ametist dhe rozë',
			'paletteRosewood' => 'Dru palisandri',
			'paletteLagoon' => 'Lagunë',
			'paletteDesert' => 'Shkretëtirë',
			'arabicFont' => 'Shkronjat arabe',
			'readingTheme' => 'Sfondi i leximit',
			'readingSystem' => 'Sipas aplikacionit',
			'readingSepia' => 'Sepia',
			'readingNight' => 'Natë',
			'patterns' => 'Motivi gjeometrik',
			'patternsSub' => 'Zbukurim i lehtë në krye dhe te numëruesi',
			'ampm.0' => 'PD',
			'ampm.1' => 'MD',
			'weekdaysShort.0' => 'Hën',
			'weekdaysShort.1' => 'Mar',
			'weekdaysShort.2' => 'Mër',
			'weekdaysShort.3' => 'Enj',
			'weekdaysShort.4' => 'Pre',
			'weekdaysShort.5' => 'Sht',
			'weekdaysShort.6' => 'Die',
			'monthsShort.0' => 'Jan',
			'monthsShort.1' => 'Shk',
			'monthsShort.2' => 'Mar',
			'monthsShort.3' => 'Pri',
			'monthsShort.4' => 'Maj',
			'monthsShort.5' => 'Qer',
			'monthsShort.6' => 'Kor',
			'monthsShort.7' => 'Gsh',
			'monthsShort.8' => 'Sht',
			'monthsShort.9' => 'Tet',
			'monthsShort.10' => 'Nën',
			'monthsShort.11' => 'Dhj',
			'dateFormat' => ({required Object weekday, required Object day, required Object month}) => '${weekday}, ${day} ${month}',
			'hijriMonths.0' => 'Muharrem',
			'hijriMonths.1' => 'Safer',
			'hijriMonths.2' => 'Rebiul-evvel',
			'hijriMonths.3' => 'Rebiul-ahir',
			'hijriMonths.4' => 'Xhumadel-ula',
			'hijriMonths.5' => 'Xhumadel-ahire',
			'hijriMonths.6' => 'Rexheb',
			'hijriMonths.7' => 'Shaban',
			'hijriMonths.8' => 'Ramazan',
			'hijriMonths.9' => 'Sheval',
			'hijriMonths.10' => 'Dhul-kade',
			'hijriMonths.11' => 'Dhul-hixhe',
			'hijriDateFormat' => ({required Object day, required Object month, required Object year}) => '${day} ${month} ${year} H',
			'hijriSuffix' => 'H',
			'secBackup' => 'Kopja rezervë dhe rikthimi',
			'backupSub' => 'Ruaj përparimin në një skedar',
			'backupOnThisDevice' => 'Në këtë pajisje',
			'backupSave' => 'Ruaj një kopje rezervë',
			'backupSaveHint' => 'Ruaj të dhënat më poshtë në një skedar. Mund ta mbash te Drive ose Skedarët, ose t\'ia dërgosh vetes.',
			'backupRestoreHeading' => 'Rikthimi',
			'backupRestore' => 'Rikthe nga një skedar',
			'backupRestoreHint' => 'Zëvendëson të dhënat e pajisjes me përmbajtjen e kopjes rezervë.',
			'backupPrivacy' => 'Kopja rezervë është skedar teksti. Mbetet në pajisje nëse nuk e dërgon vetë diku. Hisn nuk e ngarkon kurrë.',
			'backupStatStreak' => 'Vargu aktual',
			'backupStatBest' => 'Vargu më i gjatë',
			'backupStatDays' => 'Ditë të mbrojtura',
			'backupStatFavorites' => 'Lutjet e ruajtura',
			'backupStatCustom' => 'Lutjet e mia',
			'backupStatQuran' => 'Shënuesit e Kuranit',
			'restoreTitle' => 'Ta rikthej këtë kopje rezervë?',
			'restoreSavedOn' => ({required Object date}) => 'Ruajtur më ${date}',
			'restoreSavedOnVersion' => ({required Object date, required Object version}) => 'Ruajtur më ${date} · v${version}',
			'restoreScopeEverything' => 'Gjithçka',
			'restoreScopeEverythingSub' => 'Përparimin dhe cilësimet',
			'restoreScopeProgress' => 'Vetëm përparimin',
			'restoreScopeProgressSub' => 'Mbaj vendndodhjen, kujtuesit dhe gjuhën e këtij telefoni',
			'restoreWarning' => 'Kjo zëvendëson të dhënat që ndodhen aktualisht në pajisje.',
			'restoreAction' => 'Rikthe',
			'restoreDone' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('sq'))(n, one: 'U rikthye 1 element', other: 'U rikthyen ${n} elemente', ), 
			'backupSaved' => 'Kopja rezervë është gati për t\'u ruajtur',
			'backupFailed' => 'Kopja rezervë nuk mund të krijohej',
			'restoreErrMalformed' => 'Ky skedar nuk mund të lexohej.',
			'restoreErrNotABackup' => 'Ky nuk është skedar kopjeje rezervë i Hisn.',
			'restoreErrTooNew' => 'Kjo kopje u krijua me një version më të ri të Hisn. Përditëso fillimisht aplikacionin.',
			'restoreErrEmpty' => 'Kjo kopje rezervë nuk ka asgjë për t\'u rikthyer.',
			'restoreFailed' => 'Rikthimi dështoi. Asgjë nuk ndryshoi.',
			'quranZoomIn' => 'Zmadho',
			'quranZoomHint' => 'Largo dy gishtat për ta zmadhuar; afroji për t’u kthyer.',
			'quranReaderOptions' => 'Opsionet e leximit',
			'versesOnThisPage' => 'Ajetet në këtë faqe',
			'savedVerses' => 'Ajetet e ruajtura',
			'savedPages' => 'Faqet e ruajtura',
			'saveVerse' => 'Ruaj ajetin',
			'unsaveVerse' => 'Hiq ajetin e ruajtur',
			'secCalendar' => 'Kalendari islam',
			'calendarSub' => 'Agjërimet sunet dhe datat hixhri',
			'sunnahCalendarTitle' => 'Agjërimet dhe datat',
			'upcomingLabel' => 'Në vijim',
			'nothingUpcoming' => 'Nuk ka data të shënuara në dy muajt e ardhshëm.',
			'calendarNote' => 'Datat llogariten sipas Umm al-Kura dhe mund të ndryshojnë me një ditë nga vrojtimi vendor i hënës.',
			'fastingRecommended' => 'Agjërimi është sunet',
			'fastingObligatory' => 'Agjërim i detyrueshëm',
			'fastingForbidden' => 'Ditë kur nuk lejohet agjërimi',
			'fastingNoneToday' => 'Sot nuk ka agjërim të veçantë.',
			'fastRamadan' => 'Ramazani',
			'fastMonday' => 'Agjërimi i së hënës',
			'fastThursday' => 'Agjërimi i së enjtes',
			'fastWhiteDay' => 'Ditët e bardha',
			'fastTasua' => 'Tasuaja',
			'fastAshura' => 'Ashuraja',
			'fastDhulHijjah' => 'Dhjetë ditët e Dhul-hixhes',
			'fastArafah' => 'Dita e Arafatit',
			'fastSixOfShawwal' => 'Gjashtë ditët e Shevalit',
			'fastRamadanSub' => 'Agjërimi i detyrueshëm i muajit.',
			'fastMondaySub' => 'Veprat paraqiten të hënën dhe të enjten. — Tirmidhiu',
			'fastThursdaySub' => 'Veprat paraqiten të hënën dhe të enjten. — Tirmidhiu',
			'fastWhiteDaySub' => 'Dita e 13-të, e 14-të dhe e 15-të e çdo muaji hixhri. — Buhariu dhe Muslimi',
			'fastTasuaSub' => 'Agjërohet bashkë me ditën e dhjetë. — Muslimi',
			'fastAshuraSub' => 'Shlyen gjynahet e vitit të kaluar. — Muslimi',
			'fastDhulHijjahSub' => 'Nuk ka ditë kur veprat e mira janë më të dashura tek Allahu se këto. — Buhariu',
			'fastArafahSub' => 'Shlyen gjynahet e vitit të kaluar dhe të ardhshëm, për ata që nuk janë në haxh. — Muslimi',
			'fastSixOfShawwalSub' => 'Kush agjëron Ramazanin dhe e pason me gjashtë ditë të Shevalit, është sikur të ketë agjëruar gjithë vitin. — Muslimi',
			'eventNewYear' => 'Viti i ri hixhri',
			'eventAshura' => 'Ashuraja',
			'eventRamadan' => 'Fillon Ramazani',
			'eventLastTen' => 'Dhjetë netët e fundit',
			'eventEidFitr' => 'Fitër Bajrami',
			'eventDhulHijjah' => 'Fillon Dhul-hixheja',
			'eventArafah' => 'Dita e Arafatit',
			'eventEidAdha' => 'Kurban Bajrami',
			'eventLastTenSub' => 'Nata e Kadrit kërkohet në netët teke të këtyre dhjetë netëve.',
			'barEidAlFitr' => 'Agjërimi nuk lejohet në Fitër Bajram.',
			'barEidAlAdha' => 'Agjërimi nuk lejohet në Kurban Bajram.',
			'barTashriq' => 'Agjërimi nuk lejohet në ditët e Teshrikut.',
			'hijriAdjust' => 'Përshtatja e datës hixhri',
			'hijriAdjustHint' => 'Data e llogaritur mund të jetë një ditë para ose pas vrojtimit vendor. Përshtate me bashkësinë tënde.',
			'hijriOffsetLabels.0' => '−2 ditë',
			'hijriOffsetLabels.1' => '−1 ditë',
			'hijriOffsetLabels.2' => 'Pa ndryshim',
			'hijriOffsetLabels.3' => '+1 ditë',
			'hijriOffsetLabels.4' => '+2 ditë',
			'fastingReminders' => 'Kujtuesit e agjërimit',
			'fastingRemindersSub' => 'Kujtues mbrëmjen para një agjërimi sunet',
			'notifFastTitle' => 'Agjërimi nesër',
			'notifFastBody' => ({required Object name}) => 'Nesër është ${name} — agjërim nga Suneti.',
			'notifOccasionBody' => 'Nesër, në dashtë Allahu.',
			'share' => 'Ndaj',
			'shareAsImage' => 'Ndaj kartën',
			'shareAsText' => 'Ndaj tekstin',
			'shareImageFailedNotReady' => 'Karta nuk ishte gati për t\'u kthyer në imazh. Po ndahet teksti.',
			'shareImageFailedUnsupported' => 'Pajisja nuk mund të krijonte imazhin. Po ndahet teksti.',
			'nextPhraseOnTap' => 'Shprehja përfundoi. Prek për të numëruar shprehjen tjetër.',
			'aboutContributors' => 'Njerëzit pas Hisn',
			'aboutDeveloperCredit' => 'Zhvillues · Projektoi dhe zhvilloi aplikacionin.',
			'aboutContentReviewerCredit' => 'Kontribues · Ndihmoi në shqyrtimin e përmbajtjes së aplikacionit për gabime shtypi dhe pasaktësi faktike.',
			'aboutProfileLinkCopied' => 'Lidhja e profilit në GitHub u kopjua. Hape në shfletues.',
			'aboutTypefaces' => 'Shkronjat',
			'aboutVerseMeanings' => 'Kuptimet e ajeteve',
			'aboutDuaDraftCredit' => 'Disa kuptime të lutjeve janë përkthime paraprake të Hisn; në pritje të shqyrtimit gjuhësor dhe fetar nga specialistë.',
			'aboutTranslationSource' => 'Burimet e përkthimit · Tanzil',
			'aboutLinkCopied' => 'Lidhja e burimit u kopjua. Hape në shfletues.',
			'aboutArabicText' => 'Teksti arabisht',
			'aboutLatinText' => 'Teksti me shkronja latine',
			'aboutLatinApparatus' => 'Teksti i ndërfaqes me shkronja latine',
			'aboutMushafPages' => 'Faqet e mus\'hafit · Kompleksi Mbreti Fehd për Shtypjen e Kuranit Fisnik',
			'prayerCountdownTitle' => 'Koha deri te namazi tjetër',
			'prayerCountdownSubtitle' => 'Mbaj te njoftimet namazin tjetër, kohën nga ezani dhe datën hixhri.',
			'prayerCountdownUnavailable' => 'Disponohet në Android. Sistemi vendos si shfaqet numërimi.',
			'prayerCountdownChannelDescription' => 'Numërim i heshtur deri te namazi tjetër',
			'guideTitle' => 'Udhëzues i shkurtër',
			'guideWelcomeTitle' => 'Njihu me Hisn',
			'guideWelcomeBody' => 'Shih ku gjenden tesbihu, kërkimi në Kuran, mjetet e namazit, pamja dhe kujtuesit. Mund ta hapësh sërish udhëzuesin te Cilësimet.',
			'viewGuide' => 'Shih udhëzuesin',
			'replayGuide' => 'Shih udhëzuesin e aplikacionit',
			'replayGuideSub' => 'Një prezantim i veçorive kryesore',
			'guideDone' => 'U krye',
			'guideProgress' => ({required Object current, required Object total}) => '${current} nga ${total}',
			'guideTasbihBody' => 'Hap Tesbihun për të zgjedhur një shprehje, për të shtuar tënden dhe për të numëruar përsëritjet.',
			'guideQuranBody' => 'Kërko një sure ose shkruaj fjalë arabe për të gjetur ajete në Kuran.',
			'guidePrayerBody' => 'Këtu gjen kohët e namazit dhe kiblën. Lejen e vendndodhjes e zgjedh te cilësimet e namazit.',
			'guideAppearanceBody' => 'Zgjidh temën e çelët, të errët ose sipas sistemit. Hap Pamjen në këtë meny për të zgjedhur ngjyrat.',
			'guideNotificationsBody' => 'Zgjidh kujtuesit dhe ezanin, cakto oraret e heshtjes ose ndali të gjithë kujtuesit te Njoftimet. Lejet aktivizoji kur të duash.',
			'prayerSilenceTitle' => 'Heshtja gjatë namazit',
			'prayerSilenceSub' => 'Heshtje automatike pas ezanit',
			'prayerSilenceEnable' => 'Aktivizo heshtjen për namaz',
			'prayerSilenceBody' => 'Hesht thirrjet dhe njoftimet gjatë intervalit që zgjedh pas çdo ezani. Alarmet mbeten të lejuara. Modalitete të tjera «Mos shqetëso» mund të zbatojnë kufizime më të rrepta.',
			'prayerSilenceTimingHint' => 'Fillimi dhe fundi maten në minuta pas ezanit. Nëse Hisn ende po luan ezanin, heshtja pret derisa të mbarojë; ora e përfundimit nuk ndryshon.',
			'prayerSilenceStart' => 'Fillo pas ezanit',
			'prayerSilenceEnd' => 'Përfundo pas ezanit',
			'prayerSilenceMinutes' => ({required Object minutes}) => '${minutes} min',
			'prayerSilencePolicyButton' => 'Lejo qasjen te «Mos shqetëso»',
			'prayerSilenceExactButton' => 'Lejo orarin e saktë',
			'prayerSilenceDisabled' => 'Heshtja për namaz është joaktive',
			'prayerSilencePermission' => 'Lejo qasjen te «Mos shqetëso» për të përdorur heshtjen për namaz.',
			'prayerSilenceExact' => 'Në pauzë: nevojitet leja për alarme të sakta që të fillojë dhe të përfundojë në kohë.',
			'prayerSilenceLocation' => 'Zgjidh qytetin ose lejo vendndodhjen për të llogaritur intervalet e namazit.',
			'prayerSilenceReady' => 'Gati për intervalin e namazit tjetër',
			'prayerSilenceActiveUntil' => ({required Object time}) => 'Heshtja për namaz është aktive deri në ${time}',
			'prayerSilenceWaiting' => 'Në pritje të përfundimit të ezanit',
			'prayerSilenceRuleDisabled' => 'Modaliteti i namazit i Hisn është çaktivizuar te cilësimet e Android.',
			'prayerSilenceUnavailable' => 'Heshtja për namaz disponohet vetëm në Android.',
			'prayerSilenceError' => 'Heshtja për namaz nuk mund të caktohej. Kontrollo lejet dhe provo sërish.',
			'prayerSilenceStopNow' => 'Përfundo këtë interval heshtjeje',
			'prayerSilenceExpiryNote' => 'Vetëm modaliteti i Hisn përfundon vetvetiu; modaliteti yt «Mos shqetëso» nuk ndryshon. Android mund ta vonojë kontrollin rezervë të përfundimit nëse hiqet leja për alarme të sakta ose kufizohet aplikacioni.',
			'qiblaStyle' => 'Pamja e busullës',
			'qiblaTone' => 'Ngjyra e busullës',
			'qiblaVibrationOn' => 'Dridhja aktive',
			'qiblaVibrationOff' => 'Dridhja joaktive',
			'qiblaStyles.0' => 'Klasike',
			'qiblaStyles.1' => 'E thjeshtë',
			'qiblaStyles.2' => 'Trëndafili i erërave',
			'qiblaTones.0' => 'Ngjyra e temës',
			'qiblaTones.1' => 'Ar',
			'qiblaTones.2' => 'Bojë',
			'durationMinutes' => ({required Object minutes}) => '${minutes} min',
			'durationHoursMinutes' => ({required Object hours, required Object minutes}) => '${hours} orë ${minutes} min',
			_ => null,
		};
	}
}
