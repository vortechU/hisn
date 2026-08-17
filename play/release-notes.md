# Release notes ("What's new")

Play takes up to **500 characters per language, per release**. Keep them short
and concrete — nobody reads "bug fixes and improvements", and Play shows the
first two lines in the update card.

Add each new version at the top. Paste the three languages into the matching
listing-language fields on the release screen.

---

## 1.15.1 (versionCode 26) — first release

### English

```
The first release of Hisn.

• Morning, evening and everyday adhkar, each with its source and repetition count
• The Madani Mushaf page by page, with every verse's meaning in your language
• Prayer times, opt-in reminders with an iqamah delay, and a corrected qibla compass
• Tasbih counter, five home-screen widgets, sunnah fasts, and backup to a file
• Works entirely offline. No accounts, no ads, no tracking.
```

*(411 / 500 characters; the Arabic is 328 and the Indonesian 406.)*

### العربية

```
الإصدار الأول من حصن.

• أذكار الصباح والمساء واليوم، كلٌّ بمصدره وعدد تكراره
• المصحف المدني صفحةً صفحة، مع تفسير ميسّر لكل آية
• مواقيت الصلاة، وتنبيهات اختيارية بمهلة إقامة، وبوصلة قبلة مصحَّحة
• سبحة، وخمس أدوات للشاشة الرئيسية، وصيام السنّة، ونسخة احتياطية في ملف
• يعمل دون إنترنت تمامًا. بلا حسابات ولا إعلانات ولا تتبّع.
```

### Bahasa Indonesia

```
Rilis pertama Hisn.

• Zikir pagi, petang, dan keseharian, masing-masing dengan sumber dan jumlahnya
• Mushaf Madinah halaman demi halaman, dengan terjemahan setiap ayat
• Jadwal salat, pengingat opsional dengan jeda iqamah, dan kompas kiblat terkoreksi
• Tasbih, lima widget layar utama, puasa sunah, dan pencadangan ke berkas
• Bekerja sepenuhnya tanpa internet. Tanpa akun, tanpa iklan, tanpa pelacakan.
```

---

## Writing the next one

- Name what changed, in the words a user would use — "the qibla needle no
  longer points confidently in the wrong direction", not "fixed `geomag`
  declination sign".
- Three to five bullets. If a release has one real change, one bullet.
- Translate all three. A release note left in English on the Arabic listing is
  the most visible sign of an abandoned app.
- Never announce a feature the build does not ship. Hands-free adhkar
  recitation is held back (`kAdhkarAudioEnabled`) and belongs in the notes of
  the release that turns it on, not before.
