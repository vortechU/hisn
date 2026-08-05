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
class TranslationsId extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsId({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.id,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <id>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsId _root = this; // ignore: unused_field

	@override 
	TranslationsId $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsId(meta: meta ?? this.$meta);

	// Translations
	@override String get navAdhkar => 'Zikir';
	@override String get navQuran => 'Quran';
	@override String get navTasbih => 'Tasbih';
	@override String get navQibla => 'Kiblat';
	@override String get navSaved => 'Tersimpan';
	@override String get navSettings => 'Pengaturan';
	@override String get navPrayer => 'Salat';
	@override String get prayerQiblaTitle => 'Salat & Kiblat';
	@override String get weeklySchedule => 'Jadwal mingguan';
	@override String get searchDuas => 'Cari doa…';
	@override String get allAdhkar => 'SEMUA ZIKIR';
	@override String get groupDaily => 'ZIKIR HARIAN';
	@override String get groupSituational => 'UNTUK SETIAP KEADAAN';
	@override String get groupMine => 'MILIK SAYA';
	@override String get muhassanHeading => 'Muhassan';
	@override String muhassanToday({required Object percent}) => 'Anda ${percent}% terbentengi hari ini';
	@override String get muhassanComplete => 'Terbentengi penuh — masha Allah';
	@override String get muhassanMorning => 'Pagi';
	@override String get muhassanEvening => 'Petang';
	@override String get streakDaysOne => '1 hari beruntun';
	@override String streakDaysOther({required Object n}) => '${n} hari beruntun';
	@override String get streakStart => 'Mulai rentetan Anda';
	@override String streakBest({required Object n}) => 'Terbaik: ${n}';
	@override String get streakTitle => 'Rentetan Anda';
	@override String get streakWord => 'hari beruntun';
	@override String get statCurrent => 'Saat ini';
	@override String get statBest => 'Terbaik';
	@override String get statTotal => 'Total hari';
	@override String get daysValueOne => '1 hari';
	@override String daysValueOther({required Object n}) => '${n} hari';
	@override String get streakOnFire => 'Luar biasa — pertahankan!';
	@override String get streakTodayPending => 'Selesaikan zikir hari ini untuk menambah rentetan';
	@override String get streakBroken => 'Selesaikan zikir pagi & petang untuk memulai lagi';
	@override String get last4Weeks => '4 minggu terakhir';
	@override String get todayLabel => 'Hari ini';
	@override String get fortifiedLegend => 'Terbentengi';
	@override List<String> get weekdayLetters => [
		'S',
		'S',
		'R',
		'K',
		'J',
		'S',
		'M',
	];
	@override String get quranTitle => 'Al-Qur\'an';
	@override String get searchSurah => 'Cari surah…';
	@override String get continueReading => 'Lanjutkan membaca';
	@override String get surahWord => 'Surah';
	@override String get revelationMeccan => 'Makkiyah';
	@override String get revelationMedinan => 'Madaniyah';
	@override String get versesCountOne => '1 ayat';
	@override String versesCountOther({required Object n}) => '${n} ayat';
	@override String juzLabel({required Object n}) => 'Juz ${n}';
	@override String get quranBookmarks => 'Penanda';
	@override String get noBookmarks => 'Belum ada penanda';
	@override String get bookmarkAdded => 'Ditandai';
	@override String get bookmarkRemoved => 'Penanda dihapus';
	@override String get goToAyah => 'Ke ayat';
	@override String get chooseSurah => 'Surah';
	@override String get verseNumber => 'Nomor ayat';
	@override String verseRange({required Object n}) => '1–${n}';
	@override String get goAction => 'Buka';
	@override String get myDuas => 'Doa Saya';
	@override String get myDuasSub => 'Doa yang Anda tambahkan sendiri';
	@override String get addDua => 'Tambah doa';
	@override String get newDua => 'Doa baru';
	@override String get fieldArabic => 'Teks Arab';
	@override String get fieldArabicRequired => 'Mohon masukkan teks Arab';
	@override String get fieldTitle => 'Judul (opsional)';
	@override String get fieldTransliteration => 'Transliterasi (opsional)';
	@override String get fieldTranslation => 'Terjemahan / makna (opsional)';
	@override String get fieldReference => 'Sumber (opsional)';
	@override String get fieldRepeat => 'Pengulangan';
	@override String get save => 'Simpan';
	@override String get cancel => 'Batal';
	@override String get delete => 'Hapus';
	@override String get deleteDua => 'Hapus doa';
	@override String get deleteDuaConfirm => 'Hapus doa ini dari Doa Saya?';
	@override String get duaSaved => 'Doa disimpan';
	@override String get duaUpdated => 'Doa diperbarui';
	@override String get editDua => 'Edit doa';
	@override String get edit => 'Edit';
	@override String get noCustomTitle => 'Belum ada doa';
	@override String get noCustomBody => 'Ketuk + untuk menambah doa Anda dan menyimpannya di sini.';
	@override String get recommendedNow => 'DISARANKAN SEKARANG';
	@override String get readNowOne => 'Baca sekarang · 1 doa';
	@override String readNowOther({required Object count}) => 'Baca sekarang · ${count} doa';
	@override String get duaCountOne => '1 doa';
	@override String duaCountOther({required Object count}) => '${count} doa';
	@override String get now => 'SEKARANG';
	@override String get next => 'BERIKUTNYA';
	@override String get remaining => 'tersisa';
	@override String get countdownNow => 'sekarang';
	@override String todaysPrayers({required Object location}) => 'Salat hari ini · ${location}';
	@override String get searchHint => 'Cari doa, makna, sumber…';
	@override String get clear => 'Hapus';
	@override String get searchPrompt => 'Cari berdasarkan judul, makna, transliterasi, atau sumber.';
	@override String noResults({required Object query}) => 'Tidak ada doa untuk "${query}".';
	@override String get resultsCountOne => '1 hasil';
	@override String resultsCountOther({required Object n}) => '${n} hasil';
	@override String get noSavedTitle => 'Belum ada doa tersimpan';
	@override String get noSavedBody => 'Ketuk penanda pada doa mana pun untuk menyimpannya di sini.';
	@override String get resetCount => 'Atur ulang hitungan';
	@override String get tapToCount => 'Ketuk di mana saja untuk menghitung';
	@override String get setsCompletedOne => '1 putaran selesai';
	@override String setsCompletedOther({required Object n}) => '${n} putaran selesai';
	@override String ofTarget({required Object n}) => 'dari ${n}';
	@override String get resetProgress => 'Atur ulang progres';
	@override String get setComplete => 'Selesai — taqabbalallah';
	@override String get tapEachDua => 'Ketuk tiap doa untuk menghitung pengulangannya';
	@override String get duaCopied => 'Doa disalin';
	@override String get removeBookmark => 'Hapus penanda';
	@override String get bookmark => 'Tandai';
	@override String get copy => 'Salin';
	@override String get done => 'Selesai';
	@override String get settings => 'Pengaturan';
	@override String get secPrayerTimes => 'Waktu salat';
	@override String get secReminders => 'Pengingat';
	@override String get secDisplay => 'Tampilan';
	@override String get secLanguage => 'Bahasa';
	@override String get secAbout => 'Tentang';
	@override String get location => 'Lokasi';
	@override String get locYourLocationGps => 'Lokasi Anda (GPS)';
	@override String locDeviceGps({required Object label}) => 'GPS perangkat · ${label}';
	@override String locFixedCity({required Object label}) => '${label} (kota tetap)';
	@override String get calcMethod => 'Metode perhitungan';
	@override String get asrCalc => 'Perhitungan Asar';
	@override String get notifications => 'Notifikasi';
	@override String get prayerReminders => 'Pengingat salat';
	@override String get prayerRemindersSub => 'Dapatkan notifikasi di tiap waktu salat';
	@override String get dailyRemembrance => 'Zikir harian';
	@override String get dailyRemembranceSub => 'Zikir pagi & petang (berulang sampai selesai), plus sunah Jumat & malam';
	@override String get adhanSound => 'Suara azan';
	@override String get adhanSoundSub => 'Putar azan di tiap waktu salat';
	@override String get adhanNeedsReminders => 'Aktifkan Pengingat salat di atas agar azan berbunyi saat waktu salat.';
	@override String get adhanVolume => 'Volume azan';
	@override List<String> get streamLabels => [
		'Media',
		'Dering',
		'Alarm',
	];
	@override List<String> get streamHints => [
		'Dikontrol oleh volume media Anda',
		'Dikontrol oleh volume dering Anda',
		'Dikontrol oleh volume alarm Anda',
	];
	@override String get previewAdhan => 'Pratinjau azan';
	@override String get stopAdhan => 'Berhenti';
	@override String get adhanPlaying => 'Memutar azan…';
	@override String get notifBlocked => 'Notifikasi diblokir. Aktifkan untuk Hisn di pengaturan perangkat Anda.';
	@override String get textSize => 'Ukuran teks';
	@override List<String> get fontScaleLabels => [
		'Kecil',
		'Standar',
		'Besar',
		'Sangat besar',
	];
	@override String get showTransliteration => 'Tampilkan transliterasi';
	@override String get showTransliterationSub => 'Baris pelafalan huruf Latin';
	@override String get showTranslation => 'Tampilkan terjemahan';
	@override String get showTranslationSub => 'Makna dalam bahasa Inggris';
	@override String get aboutBody => 'Pendamping Doa & Zikir · prototipe\nWaktu salat via pustaka Adhan.';
	@override String get automatic => 'OTOMATIS';
	@override String get useDeviceLocation => 'Gunakan lokasi perangkat saya';
	@override String get gpsActive => 'Aktif · waktu sesuai lokasi Anda';
	@override String get gpsDetect => 'Deteksi via GPS (meminta izin)';
	@override String get chooseCity => 'PILIH KOTA';
	@override String get cityNote => 'Waktu kota yang dipilih ditampilkan dalam zona waktu perangkat Anda saat ini — akurat bila kota berada di wilayah Anda.';
	@override String get madhabStandard => 'Standar (Syafi\'i, Maliki, Hanbali)';
	@override String get madhabHanafi => 'Hanafi';
	@override String get asrHintStandard => 'Asar dimulai saat bayangan benda sama dengan panjangnya';
	@override String get asrHintHanafi => 'Asar dimulai saat bayangan benda dua kali panjangnya';
	@override String get prayerFajr => 'Subuh';
	@override String get prayerSunrise => 'Syuruk';
	@override String get prayerDhuhr => 'Zuhur';
	@override String get prayerAsr => 'Asar';
	@override String get prayerMaghrib => 'Magrib';
	@override String get prayerIsha => 'Isya';
	@override String get prayerNone => '—';
	@override String notifTitle({required Object name}) => 'Salat ${name}';
	@override String notifBody({required Object name, required Object place}) => 'Sudah masuk waktu salat ${name} — ${place}.';
	@override String get testNotifTitle => 'Pengingat percobaan';
	@override String get testNotifBody => 'Jika Anda membaca ini, pengingat salat berfungsi. 🌙';
	@override String get sendTestNotif => 'Kirim notifikasi percobaan';
	@override String get testSent => 'Percobaan terkirim — satu muncul sekarang, satu lagi dalam 12 dtk (kunci ponsel Anda).';
	@override String get testBlocked => 'Terkirim, tetapi ponsel Anda melaporkan notifikasi MATI untuk Hisn. Aktifkan di Pengaturan → Aplikasi → Hisn → Notifikasi.';
	@override String get batteryHint => 'Beberapa ponsel (mis. Xiaomi/MIUI, Samsung) memblokir pengingat terjadwal saat aplikasi ditutup. Jika pengingat tidak muncul, izinkan Autostart dan atur penggunaan baterai ke "Tanpa batasan" untuk Hisn.';
	@override String get adhkarMorningTitle => 'Zikir pagi';
	@override String get adhkarMorningBody => 'Awali pagimu dengan zikir — bentengi harimu.';
	@override String get adhkarEveningTitle => 'Zikir petang';
	@override String get adhkarEveningBody => 'Akhiri harimu dengan zikir — bentengi malammu.';
	@override String get kahfTitle => 'Surah Al-Kahfi';
	@override String get kahfBody => 'Hari ini Jumat — bacalah Surah Al-Kahfi.';
	@override String get salawatTitle => 'Bersalawat kepada Nabi ﷺ';
	@override String get salawatBody => 'Sempatkan bersalawat kepada Nabi ﷺ.';
	@override String get salawatFridayTitle => 'Bersalawat kepada Nabi ﷺ';
	@override String get salawatFridayBody => 'Hari ini Jumat — perbanyak salawat kepada Nabi ﷺ.';
	@override String get mulkTitle => 'Surah Al-Mulk';
	@override String get mulkBody => 'Sebelum tidur — bacalah Surah Al-Mulk.';
	@override String qiblaFromNorth({required Object degrees}) => 'Kiblat · ${degrees}° dari Utara';
	@override String get facingQibla => 'Anda menghadap kiblat';
	@override String turnRight({required Object degrees}) => 'Putar kanan ${degrees}°';
	@override String turnLeft({required Object degrees}) => 'Putar kiri ${degrees}°';
	@override String get calibrateHint => 'Gerakkan membentuk angka 8 untuk kalibrasi';
	@override String get compassUnavailable => 'Kompas tidak tersedia';
	@override String get compassUnavailableBody => 'Perangkat ini tidak memiliki sensor kompas, atau perlu kalibrasi. Coba gerakkan membentuk angka 8.';
	@override String get qiblaNoLocation => 'Lokasi diperlukan';
	@override String get qiblaNoLocationBody => 'Arah kiblat belum dapat dihitung sebelum lokasi Anda diketahui. Aktifkan layanan lokasi, atau pilih kota Anda di Pengaturan.';
	@override String get placeYourLocation => 'Lokasi Anda';
	@override String get placeSelectedCity => 'Kota terpilih';
	@override String get placeMakkah => 'Makkah';
	@override String get onboardSkip => 'Lewati';
	@override String get onboardNext => 'Lanjut';
	@override String get onboardGetStarted => 'Mulai';
	@override String get onboardWelcomeTitle => 'Selamat datang di Hisn';
	@override String get onboardWelcomeBody => 'Pendamping harian Anda untuk zikir, Al-Qur\'an, dan salat. Berikut panduan singkat untuk memulai.';
	@override String get onboardAdhkarTitle => 'Zikir & Doa';
	@override String get onboardAdhkarBody => 'Zikir pagi dan petang, penghitung tasbih, dan doa Anda sendiri. Ketuk sebuah doa untuk menghitung pengulangannya.';
	@override String get onboardQuranTitle => 'Al-Qur\'an';
	@override String get onboardQuranBody => 'Baca seluruh Al-Qur\'an dalam mushaf yang indah, lanjutkan dari tempat terakhir, dan tandai ayat favorit Anda.';
	@override String get onboardPrayerTitle => 'Salat & Kiblat';
	@override String get onboardPrayerBody => 'Waktu salat akurat untuk lokasi Anda, hitung mundur ke salat berikutnya, dan kompas penunjuk arah kiblat.';
	@override String get onboardPermsTitle => 'Beberapa izin';
	@override String get onboardPermsBody => 'Izinkan ini agar Hisn bekerja optimal. Anda dapat mengubahnya kapan saja di Pengaturan.';
	@override String get onboardLocationTitle => 'Lokasi';
	@override String get onboardLocationBody => 'Untuk menghitung waktu salat yang akurat dan arah kiblat sesuai tempat Anda.';
	@override String get onboardLocationAction => 'Izinkan lokasi';
	@override String get onboardNotifTitle => 'Notifikasi';
	@override String get onboardNotifBody => 'Pengingat lembut di setiap waktu salat agar Anda tidak melewatkan salat.';
	@override String get onboardNotifAction => 'Aktifkan pengingat';
	@override String get onboardGranted => 'Aktif';
	@override String get secAppearance => 'Tampilan';
	@override String get appearanceColors => 'Palet warna';
	@override String get appearanceTheme => 'Tema';
	@override String get themeLight => 'Terang';
	@override String get themeDark => 'Gelap';
	@override String get themeSystem => 'Sistem';
	@override String get paletteEmerald => 'Zamrud & Emas';
	@override String get paletteSapphire => 'Safir & Langit';
	@override String get paletteAmethyst => 'Kecubung & Mawar';
	@override String get paletteRosewood => 'Kayu Mawar';
	@override String get paletteLagoon => 'Laguna';
	@override String get paletteDesert => 'Gurun';
	@override String get arabicFont => 'Font Arab';
	@override String get readingTheme => 'Latar baca';
	@override String get readingSystem => 'Ikuti aplikasi';
	@override String get readingSepia => 'Sepia';
	@override String get readingNight => 'Malam';
	@override String get patterns => 'Pola geometris';
	@override String get patternsSub => 'Ornamen halus di header dan penghitung';
	@override List<String> get ampm => [
		'AM',
		'PM',
	];
	@override List<String> get weekdaysShort => [
		'Sen',
		'Sel',
		'Rab',
		'Kam',
		'Jum',
		'Sab',
		'Min',
	];
	@override List<String> get monthsShort => [
		'Jan',
		'Feb',
		'Mar',
		'Apr',
		'Mei',
		'Jun',
		'Jul',
		'Agu',
		'Sep',
		'Okt',
		'Nov',
		'Des',
	];
	@override String dateFormat({required Object weekday, required Object day, required Object month}) => '${weekday}, ${day} ${month}';
	@override List<String> get hijriMonths => [
		'Muharram',
		'Safar',
		'Rabiulawal',
		'Rabiulakhir',
		'Jumadilawal',
		'Jumadilakhir',
		'Rajab',
		'Syaban',
		'Ramadan',
		'Syawal',
		'Zulkaidah',
		'Zulhijah',
	];
	@override String hijriDateFormat({required Object day, required Object month, required Object year}) => '${day} ${month} ${year} H';
	@override String get hijriSuffix => 'H';
	@override String get secBackup => 'Cadangan & pemulihan';
	@override String get backupSub => 'Simpan kemajuan Anda ke sebuah berkas';
	@override String get backupOnThisDevice => 'Di perangkat ini';
	@override String get backupSave => 'Simpan cadangan';
	@override String get backupSaveHint => 'Menulis semua yang ada di bawah ke sebuah berkas yang bisa Anda simpan di Drive atau Files, atau kirim ke diri sendiri.';
	@override String get backupRestoreHeading => 'Pemulihan';
	@override String get backupRestore => 'Pulihkan dari berkas';
	@override String get backupRestoreHint => 'Mengganti apa yang ada di perangkat ini dengan isi berkas cadangan.';
	@override String get backupPrivacy => 'Cadangan adalah berkas teks biasa. Berkas itu tetap di perangkat ini kecuali Anda sendiri mengirimkannya — Hisn tidak pernah mengunggahnya.';
	@override String get backupStatStreak => 'Rentetan saat ini';
	@override String get backupStatBest => 'Rentetan terbaik';
	@override String get backupStatDays => 'Hari terbentengi';
	@override String get backupStatFavorites => 'Doa tersimpan';
	@override String get backupStatCustom => 'Doa saya';
	@override String get backupStatQuran => 'Penanda Quran';
	@override String get restoreTitle => 'Pulihkan cadangan ini?';
	@override String restoreSavedOn({required Object date}) => 'Disimpan ${date}';
	@override String restoreSavedOnVersion({required Object date, required Object version}) => 'Disimpan ${date} · v${version}';
	@override String get restoreScopeEverything => 'Semuanya';
	@override String get restoreScopeEverythingSub => 'Kemajuan dan pengaturan';
	@override String get restoreScopeProgress => 'Hanya kemajuan';
	@override String get restoreScopeProgressSub => 'Pertahankan lokasi, pengingat, dan bahasa ponsel ini';
	@override String get restoreWarning => 'Ini akan mengganti apa yang ada di perangkat ini sekarang.';
	@override String get restoreAction => 'Pulihkan';
	@override String get restoreDoneOne => '1 item dipulihkan';
	@override String restoreDoneOther({required Object n}) => '${n} item dipulihkan';
	@override String get backupSaved => 'Cadangan siap disimpan';
	@override String get backupFailed => 'Tidak dapat membuat cadangan';
	@override String get restoreErrMalformed => 'Berkas itu tidak dapat dibaca.';
	@override String get restoreErrNotABackup => 'Itu bukan berkas cadangan Hisn.';
	@override String get restoreErrTooNew => 'Cadangan itu dibuat oleh versi Hisn yang lebih baru. Perbarui aplikasi terlebih dahulu.';
	@override String get restoreErrEmpty => 'Tidak ada yang bisa dipulihkan dari cadangan itu.';
	@override String get restoreFailed => 'Tidak dapat memulihkan. Tidak ada yang diubah.';
	@override String get versesOnThisPage => 'Ayat di halaman ini';
	@override String get savedVerses => 'Ayat tersimpan';
	@override String get savedPages => 'Halaman tersimpan';
	@override String get saveVerse => 'Simpan ayat';
	@override String get unsaveVerse => 'Hapus ayat tersimpan';
}

/// The flat map containing all translations for locale <id>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsId {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'navAdhkar' => 'Zikir',
			'navQuran' => 'Quran',
			'navTasbih' => 'Tasbih',
			'navQibla' => 'Kiblat',
			'navSaved' => 'Tersimpan',
			'navSettings' => 'Pengaturan',
			'navPrayer' => 'Salat',
			'prayerQiblaTitle' => 'Salat & Kiblat',
			'weeklySchedule' => 'Jadwal mingguan',
			'searchDuas' => 'Cari doa…',
			'allAdhkar' => 'SEMUA ZIKIR',
			'groupDaily' => 'ZIKIR HARIAN',
			'groupSituational' => 'UNTUK SETIAP KEADAAN',
			'groupMine' => 'MILIK SAYA',
			'muhassanHeading' => 'Muhassan',
			'muhassanToday' => ({required Object percent}) => 'Anda ${percent}% terbentengi hari ini',
			'muhassanComplete' => 'Terbentengi penuh — masha Allah',
			'muhassanMorning' => 'Pagi',
			'muhassanEvening' => 'Petang',
			'streakDaysOne' => '1 hari beruntun',
			'streakDaysOther' => ({required Object n}) => '${n} hari beruntun',
			'streakStart' => 'Mulai rentetan Anda',
			'streakBest' => ({required Object n}) => 'Terbaik: ${n}',
			'streakTitle' => 'Rentetan Anda',
			'streakWord' => 'hari beruntun',
			'statCurrent' => 'Saat ini',
			'statBest' => 'Terbaik',
			'statTotal' => 'Total hari',
			'daysValueOne' => '1 hari',
			'daysValueOther' => ({required Object n}) => '${n} hari',
			'streakOnFire' => 'Luar biasa — pertahankan!',
			'streakTodayPending' => 'Selesaikan zikir hari ini untuk menambah rentetan',
			'streakBroken' => 'Selesaikan zikir pagi & petang untuk memulai lagi',
			'last4Weeks' => '4 minggu terakhir',
			'todayLabel' => 'Hari ini',
			'fortifiedLegend' => 'Terbentengi',
			'weekdayLetters.0' => 'S',
			'weekdayLetters.1' => 'S',
			'weekdayLetters.2' => 'R',
			'weekdayLetters.3' => 'K',
			'weekdayLetters.4' => 'J',
			'weekdayLetters.5' => 'S',
			'weekdayLetters.6' => 'M',
			'quranTitle' => 'Al-Qur\'an',
			'searchSurah' => 'Cari surah…',
			'continueReading' => 'Lanjutkan membaca',
			'surahWord' => 'Surah',
			'revelationMeccan' => 'Makkiyah',
			'revelationMedinan' => 'Madaniyah',
			'versesCountOne' => '1 ayat',
			'versesCountOther' => ({required Object n}) => '${n} ayat',
			'juzLabel' => ({required Object n}) => 'Juz ${n}',
			'quranBookmarks' => 'Penanda',
			'noBookmarks' => 'Belum ada penanda',
			'bookmarkAdded' => 'Ditandai',
			'bookmarkRemoved' => 'Penanda dihapus',
			'goToAyah' => 'Ke ayat',
			'chooseSurah' => 'Surah',
			'verseNumber' => 'Nomor ayat',
			'verseRange' => ({required Object n}) => '1–${n}',
			'goAction' => 'Buka',
			'myDuas' => 'Doa Saya',
			'myDuasSub' => 'Doa yang Anda tambahkan sendiri',
			'addDua' => 'Tambah doa',
			'newDua' => 'Doa baru',
			'fieldArabic' => 'Teks Arab',
			'fieldArabicRequired' => 'Mohon masukkan teks Arab',
			'fieldTitle' => 'Judul (opsional)',
			'fieldTransliteration' => 'Transliterasi (opsional)',
			'fieldTranslation' => 'Terjemahan / makna (opsional)',
			'fieldReference' => 'Sumber (opsional)',
			'fieldRepeat' => 'Pengulangan',
			'save' => 'Simpan',
			'cancel' => 'Batal',
			'delete' => 'Hapus',
			'deleteDua' => 'Hapus doa',
			'deleteDuaConfirm' => 'Hapus doa ini dari Doa Saya?',
			'duaSaved' => 'Doa disimpan',
			'duaUpdated' => 'Doa diperbarui',
			'editDua' => 'Edit doa',
			'edit' => 'Edit',
			'noCustomTitle' => 'Belum ada doa',
			'noCustomBody' => 'Ketuk + untuk menambah doa Anda dan menyimpannya di sini.',
			'recommendedNow' => 'DISARANKAN SEKARANG',
			'readNowOne' => 'Baca sekarang · 1 doa',
			'readNowOther' => ({required Object count}) => 'Baca sekarang · ${count} doa',
			'duaCountOne' => '1 doa',
			'duaCountOther' => ({required Object count}) => '${count} doa',
			'now' => 'SEKARANG',
			'next' => 'BERIKUTNYA',
			'remaining' => 'tersisa',
			'countdownNow' => 'sekarang',
			'todaysPrayers' => ({required Object location}) => 'Salat hari ini · ${location}',
			'searchHint' => 'Cari doa, makna, sumber…',
			'clear' => 'Hapus',
			'searchPrompt' => 'Cari berdasarkan judul, makna, transliterasi, atau sumber.',
			'noResults' => ({required Object query}) => 'Tidak ada doa untuk "${query}".',
			'resultsCountOne' => '1 hasil',
			'resultsCountOther' => ({required Object n}) => '${n} hasil',
			'noSavedTitle' => 'Belum ada doa tersimpan',
			'noSavedBody' => 'Ketuk penanda pada doa mana pun untuk menyimpannya di sini.',
			'resetCount' => 'Atur ulang hitungan',
			'tapToCount' => 'Ketuk di mana saja untuk menghitung',
			'setsCompletedOne' => '1 putaran selesai',
			'setsCompletedOther' => ({required Object n}) => '${n} putaran selesai',
			'ofTarget' => ({required Object n}) => 'dari ${n}',
			'resetProgress' => 'Atur ulang progres',
			'setComplete' => 'Selesai — taqabbalallah',
			'tapEachDua' => 'Ketuk tiap doa untuk menghitung pengulangannya',
			'duaCopied' => 'Doa disalin',
			'removeBookmark' => 'Hapus penanda',
			'bookmark' => 'Tandai',
			'copy' => 'Salin',
			'done' => 'Selesai',
			'settings' => 'Pengaturan',
			'secPrayerTimes' => 'Waktu salat',
			'secReminders' => 'Pengingat',
			'secDisplay' => 'Tampilan',
			'secLanguage' => 'Bahasa',
			'secAbout' => 'Tentang',
			'location' => 'Lokasi',
			'locYourLocationGps' => 'Lokasi Anda (GPS)',
			'locDeviceGps' => ({required Object label}) => 'GPS perangkat · ${label}',
			'locFixedCity' => ({required Object label}) => '${label} (kota tetap)',
			'calcMethod' => 'Metode perhitungan',
			'asrCalc' => 'Perhitungan Asar',
			'notifications' => 'Notifikasi',
			'prayerReminders' => 'Pengingat salat',
			'prayerRemindersSub' => 'Dapatkan notifikasi di tiap waktu salat',
			'dailyRemembrance' => 'Zikir harian',
			'dailyRemembranceSub' => 'Zikir pagi & petang (berulang sampai selesai), plus sunah Jumat & malam',
			'adhanSound' => 'Suara azan',
			'adhanSoundSub' => 'Putar azan di tiap waktu salat',
			'adhanNeedsReminders' => 'Aktifkan Pengingat salat di atas agar azan berbunyi saat waktu salat.',
			'adhanVolume' => 'Volume azan',
			'streamLabels.0' => 'Media',
			'streamLabels.1' => 'Dering',
			'streamLabels.2' => 'Alarm',
			'streamHints.0' => 'Dikontrol oleh volume media Anda',
			'streamHints.1' => 'Dikontrol oleh volume dering Anda',
			'streamHints.2' => 'Dikontrol oleh volume alarm Anda',
			'previewAdhan' => 'Pratinjau azan',
			'stopAdhan' => 'Berhenti',
			'adhanPlaying' => 'Memutar azan…',
			'notifBlocked' => 'Notifikasi diblokir. Aktifkan untuk Hisn di pengaturan perangkat Anda.',
			'textSize' => 'Ukuran teks',
			'fontScaleLabels.0' => 'Kecil',
			'fontScaleLabels.1' => 'Standar',
			'fontScaleLabels.2' => 'Besar',
			'fontScaleLabels.3' => 'Sangat besar',
			'showTransliteration' => 'Tampilkan transliterasi',
			'showTransliterationSub' => 'Baris pelafalan huruf Latin',
			'showTranslation' => 'Tampilkan terjemahan',
			'showTranslationSub' => 'Makna dalam bahasa Inggris',
			'aboutBody' => 'Pendamping Doa & Zikir · prototipe\nWaktu salat via pustaka Adhan.',
			'automatic' => 'OTOMATIS',
			'useDeviceLocation' => 'Gunakan lokasi perangkat saya',
			'gpsActive' => 'Aktif · waktu sesuai lokasi Anda',
			'gpsDetect' => 'Deteksi via GPS (meminta izin)',
			'chooseCity' => 'PILIH KOTA',
			'cityNote' => 'Waktu kota yang dipilih ditampilkan dalam zona waktu perangkat Anda saat ini — akurat bila kota berada di wilayah Anda.',
			'madhabStandard' => 'Standar (Syafi\'i, Maliki, Hanbali)',
			'madhabHanafi' => 'Hanafi',
			'asrHintStandard' => 'Asar dimulai saat bayangan benda sama dengan panjangnya',
			'asrHintHanafi' => 'Asar dimulai saat bayangan benda dua kali panjangnya',
			'prayerFajr' => 'Subuh',
			'prayerSunrise' => 'Syuruk',
			'prayerDhuhr' => 'Zuhur',
			'prayerAsr' => 'Asar',
			'prayerMaghrib' => 'Magrib',
			'prayerIsha' => 'Isya',
			'prayerNone' => '—',
			'notifTitle' => ({required Object name}) => 'Salat ${name}',
			'notifBody' => ({required Object name, required Object place}) => 'Sudah masuk waktu salat ${name} — ${place}.',
			'testNotifTitle' => 'Pengingat percobaan',
			'testNotifBody' => 'Jika Anda membaca ini, pengingat salat berfungsi. 🌙',
			'sendTestNotif' => 'Kirim notifikasi percobaan',
			'testSent' => 'Percobaan terkirim — satu muncul sekarang, satu lagi dalam 12 dtk (kunci ponsel Anda).',
			'testBlocked' => 'Terkirim, tetapi ponsel Anda melaporkan notifikasi MATI untuk Hisn. Aktifkan di Pengaturan → Aplikasi → Hisn → Notifikasi.',
			'batteryHint' => 'Beberapa ponsel (mis. Xiaomi/MIUI, Samsung) memblokir pengingat terjadwal saat aplikasi ditutup. Jika pengingat tidak muncul, izinkan Autostart dan atur penggunaan baterai ke "Tanpa batasan" untuk Hisn.',
			'adhkarMorningTitle' => 'Zikir pagi',
			'adhkarMorningBody' => 'Awali pagimu dengan zikir — bentengi harimu.',
			'adhkarEveningTitle' => 'Zikir petang',
			'adhkarEveningBody' => 'Akhiri harimu dengan zikir — bentengi malammu.',
			'kahfTitle' => 'Surah Al-Kahfi',
			'kahfBody' => 'Hari ini Jumat — bacalah Surah Al-Kahfi.',
			'salawatTitle' => 'Bersalawat kepada Nabi ﷺ',
			'salawatBody' => 'Sempatkan bersalawat kepada Nabi ﷺ.',
			'salawatFridayTitle' => 'Bersalawat kepada Nabi ﷺ',
			'salawatFridayBody' => 'Hari ini Jumat — perbanyak salawat kepada Nabi ﷺ.',
			'mulkTitle' => 'Surah Al-Mulk',
			'mulkBody' => 'Sebelum tidur — bacalah Surah Al-Mulk.',
			'qiblaFromNorth' => ({required Object degrees}) => 'Kiblat · ${degrees}° dari Utara',
			'facingQibla' => 'Anda menghadap kiblat',
			'turnRight' => ({required Object degrees}) => 'Putar kanan ${degrees}°',
			'turnLeft' => ({required Object degrees}) => 'Putar kiri ${degrees}°',
			'calibrateHint' => 'Gerakkan membentuk angka 8 untuk kalibrasi',
			'compassUnavailable' => 'Kompas tidak tersedia',
			'compassUnavailableBody' => 'Perangkat ini tidak memiliki sensor kompas, atau perlu kalibrasi. Coba gerakkan membentuk angka 8.',
			'qiblaNoLocation' => 'Lokasi diperlukan',
			'qiblaNoLocationBody' => 'Arah kiblat belum dapat dihitung sebelum lokasi Anda diketahui. Aktifkan layanan lokasi, atau pilih kota Anda di Pengaturan.',
			'placeYourLocation' => 'Lokasi Anda',
			'placeSelectedCity' => 'Kota terpilih',
			'placeMakkah' => 'Makkah',
			'onboardSkip' => 'Lewati',
			'onboardNext' => 'Lanjut',
			'onboardGetStarted' => 'Mulai',
			'onboardWelcomeTitle' => 'Selamat datang di Hisn',
			'onboardWelcomeBody' => 'Pendamping harian Anda untuk zikir, Al-Qur\'an, dan salat. Berikut panduan singkat untuk memulai.',
			'onboardAdhkarTitle' => 'Zikir & Doa',
			'onboardAdhkarBody' => 'Zikir pagi dan petang, penghitung tasbih, dan doa Anda sendiri. Ketuk sebuah doa untuk menghitung pengulangannya.',
			'onboardQuranTitle' => 'Al-Qur\'an',
			'onboardQuranBody' => 'Baca seluruh Al-Qur\'an dalam mushaf yang indah, lanjutkan dari tempat terakhir, dan tandai ayat favorit Anda.',
			'onboardPrayerTitle' => 'Salat & Kiblat',
			'onboardPrayerBody' => 'Waktu salat akurat untuk lokasi Anda, hitung mundur ke salat berikutnya, dan kompas penunjuk arah kiblat.',
			'onboardPermsTitle' => 'Beberapa izin',
			'onboardPermsBody' => 'Izinkan ini agar Hisn bekerja optimal. Anda dapat mengubahnya kapan saja di Pengaturan.',
			'onboardLocationTitle' => 'Lokasi',
			'onboardLocationBody' => 'Untuk menghitung waktu salat yang akurat dan arah kiblat sesuai tempat Anda.',
			'onboardLocationAction' => 'Izinkan lokasi',
			'onboardNotifTitle' => 'Notifikasi',
			'onboardNotifBody' => 'Pengingat lembut di setiap waktu salat agar Anda tidak melewatkan salat.',
			'onboardNotifAction' => 'Aktifkan pengingat',
			'onboardGranted' => 'Aktif',
			'secAppearance' => 'Tampilan',
			'appearanceColors' => 'Palet warna',
			'appearanceTheme' => 'Tema',
			'themeLight' => 'Terang',
			'themeDark' => 'Gelap',
			'themeSystem' => 'Sistem',
			'paletteEmerald' => 'Zamrud & Emas',
			'paletteSapphire' => 'Safir & Langit',
			'paletteAmethyst' => 'Kecubung & Mawar',
			'paletteRosewood' => 'Kayu Mawar',
			'paletteLagoon' => 'Laguna',
			'paletteDesert' => 'Gurun',
			'arabicFont' => 'Font Arab',
			'readingTheme' => 'Latar baca',
			'readingSystem' => 'Ikuti aplikasi',
			'readingSepia' => 'Sepia',
			'readingNight' => 'Malam',
			'patterns' => 'Pola geometris',
			'patternsSub' => 'Ornamen halus di header dan penghitung',
			'ampm.0' => 'AM',
			'ampm.1' => 'PM',
			'weekdaysShort.0' => 'Sen',
			'weekdaysShort.1' => 'Sel',
			'weekdaysShort.2' => 'Rab',
			'weekdaysShort.3' => 'Kam',
			'weekdaysShort.4' => 'Jum',
			'weekdaysShort.5' => 'Sab',
			'weekdaysShort.6' => 'Min',
			'monthsShort.0' => 'Jan',
			'monthsShort.1' => 'Feb',
			'monthsShort.2' => 'Mar',
			'monthsShort.3' => 'Apr',
			'monthsShort.4' => 'Mei',
			'monthsShort.5' => 'Jun',
			'monthsShort.6' => 'Jul',
			'monthsShort.7' => 'Agu',
			'monthsShort.8' => 'Sep',
			'monthsShort.9' => 'Okt',
			'monthsShort.10' => 'Nov',
			'monthsShort.11' => 'Des',
			'dateFormat' => ({required Object weekday, required Object day, required Object month}) => '${weekday}, ${day} ${month}',
			'hijriMonths.0' => 'Muharram',
			'hijriMonths.1' => 'Safar',
			'hijriMonths.2' => 'Rabiulawal',
			'hijriMonths.3' => 'Rabiulakhir',
			'hijriMonths.4' => 'Jumadilawal',
			'hijriMonths.5' => 'Jumadilakhir',
			'hijriMonths.6' => 'Rajab',
			'hijriMonths.7' => 'Syaban',
			'hijriMonths.8' => 'Ramadan',
			'hijriMonths.9' => 'Syawal',
			'hijriMonths.10' => 'Zulkaidah',
			'hijriMonths.11' => 'Zulhijah',
			'hijriDateFormat' => ({required Object day, required Object month, required Object year}) => '${day} ${month} ${year} H',
			'hijriSuffix' => 'H',
			'secBackup' => 'Cadangan & pemulihan',
			'backupSub' => 'Simpan kemajuan Anda ke sebuah berkas',
			'backupOnThisDevice' => 'Di perangkat ini',
			'backupSave' => 'Simpan cadangan',
			'backupSaveHint' => 'Menulis semua yang ada di bawah ke sebuah berkas yang bisa Anda simpan di Drive atau Files, atau kirim ke diri sendiri.',
			'backupRestoreHeading' => 'Pemulihan',
			'backupRestore' => 'Pulihkan dari berkas',
			'backupRestoreHint' => 'Mengganti apa yang ada di perangkat ini dengan isi berkas cadangan.',
			'backupPrivacy' => 'Cadangan adalah berkas teks biasa. Berkas itu tetap di perangkat ini kecuali Anda sendiri mengirimkannya — Hisn tidak pernah mengunggahnya.',
			'backupStatStreak' => 'Rentetan saat ini',
			'backupStatBest' => 'Rentetan terbaik',
			'backupStatDays' => 'Hari terbentengi',
			'backupStatFavorites' => 'Doa tersimpan',
			'backupStatCustom' => 'Doa saya',
			'backupStatQuran' => 'Penanda Quran',
			'restoreTitle' => 'Pulihkan cadangan ini?',
			'restoreSavedOn' => ({required Object date}) => 'Disimpan ${date}',
			'restoreSavedOnVersion' => ({required Object date, required Object version}) => 'Disimpan ${date} · v${version}',
			'restoreScopeEverything' => 'Semuanya',
			'restoreScopeEverythingSub' => 'Kemajuan dan pengaturan',
			'restoreScopeProgress' => 'Hanya kemajuan',
			'restoreScopeProgressSub' => 'Pertahankan lokasi, pengingat, dan bahasa ponsel ini',
			'restoreWarning' => 'Ini akan mengganti apa yang ada di perangkat ini sekarang.',
			'restoreAction' => 'Pulihkan',
			'restoreDoneOne' => '1 item dipulihkan',
			'restoreDoneOther' => ({required Object n}) => '${n} item dipulihkan',
			'backupSaved' => 'Cadangan siap disimpan',
			'backupFailed' => 'Tidak dapat membuat cadangan',
			'restoreErrMalformed' => 'Berkas itu tidak dapat dibaca.',
			'restoreErrNotABackup' => 'Itu bukan berkas cadangan Hisn.',
			'restoreErrTooNew' => 'Cadangan itu dibuat oleh versi Hisn yang lebih baru. Perbarui aplikasi terlebih dahulu.',
			'restoreErrEmpty' => 'Tidak ada yang bisa dipulihkan dari cadangan itu.',
			'restoreFailed' => 'Tidak dapat memulihkan. Tidak ada yang diubah.',
			'versesOnThisPage' => 'Ayat di halaman ini',
			'savedVerses' => 'Ayat tersimpan',
			'savedPages' => 'Halaman tersimpan',
			'saveVerse' => 'Simpan ayat',
			'unsaveVerse' => 'Hapus ayat tersimpan',
			_ => null,
		};
	}
}
