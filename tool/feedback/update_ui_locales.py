"""Apply feedback copy to locale sources; preserve all unrelated keys."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
UPDATES = {
    "en": {
        "aboutTypefaces": "Typefaces",
        "aboutVerseMeanings": "Verse meanings",
        "aboutUrduDuaCredit": "Urdu dua meanings: Hisn project draft; qualified review pending.",
        "aboutTranslationSource": "Translation sources · Tanzil",
        "aboutLinkCopied": "Source link copied. Open it in your browser.",
        "aboutArabicText": "Arabic text",
        "aboutLatinText": "Latin text",
        "aboutLatinApparatus": "Latin interface text",
        "aboutMushafPages": "Mushaf pages · King Fahd Glorious Quran Printing Complex",
        "streamLabels": ["Media", "Ringer / notifications", "Alarm"],
        "nextPhraseOnTap": "Phrase complete. Tap to count the next phrase.",
        "stopAdhan": "Stop adhan",
        "streamHints": [
            "Media: uses your phone's music and video volume slider. A silent ringer does not necessarily mute it; check media volume and Do Not Disturb settings too.",
            "Ringer: uses your phone's ringtone or notification volume slider. Silent or vibrate mode and Do Not Disturb can silence the adhan.",
            "Alarm: uses your phone's alarm volume slider. A silent ringer usually does not mute alarms; check whether Do Not Disturb allows alarms.",
        ],
    },
    "ar": {
        "aboutTypefaces": "الخطوط",
        "aboutVerseMeanings": "معاني الآيات",
        "aboutUrduDuaCredit": "معاني الأدعية بالأردية: مسودة مشروع حصن؛ في انتظار مراجعة مختصّ.",
        "aboutTranslationSource": "مصادر الترجمات · تنزيل",
        "aboutLinkCopied": "نُسخ رابط المصدر. افتحه في متصفحك.",
        "aboutArabicText": "النص العربي",
        "aboutLatinText": "النص اللاتيني",
        "aboutLatinApparatus": "نص الواجهة اللاتيني",
        "aboutMushafPages": "صفحات المصحف · مجمع الملك فهد لطباعة المصحف الشريف",
        "streamLabels": ["الوسائط", "الرنين / الإشعارات", "المنبّه"],
        "nextPhraseOnTap": "اكتمل الذكر. اضغط لعدّ الذكر التالي.",
        "stopAdhan": "إيقاف الأذان",
        "streamHints": [
            "الوسائط: يستخدم مستوى صوت الموسيقى والفيديو في هاتفك. كتم الرنين لا يكتمه بالضرورة؛ راجع صوت الوسائط وإعدادات عدم الإزعاج أيضًا.",
            "الرنين: يستخدم مستوى صوت الرنين أو الإشعارات في هاتفك. قد يكتم الوضع الصامت أو الاهتزاز وعدم الإزعاج صوت الأذان.",
            "المنبّه: يستخدم مستوى صوت المنبّه في هاتفك. كتم الرنين لا يكتم المنبّهات عادةً؛ راجع السماح بالمنبّهات في إعدادات عدم الإزعاج.",
        ],
    },
    "id": {
        "aboutTypefaces": "Jenis huruf",
        "aboutVerseMeanings": "Makna ayat",
        "aboutUrduDuaCredit": "Makna doa Urdu: draf proyek Hisn; menunggu tinjauan ahli.",
        "aboutTranslationSource": "Sumber terjemahan · Tanzil",
        "aboutLinkCopied": "Tautan sumber disalin. Buka di peramban Anda.",
        "aboutArabicText": "Teks Arab",
        "aboutLatinText": "Teks Latin",
        "aboutLatinApparatus": "Teks antarmuka Latin",
        "aboutMushafPages": "Halaman mushaf · Kompleks Percetakan Al-Qur'an Raja Fahd",
        "streamLabels": ["Media", "Dering / notifikasi", "Alarm"],
        "nextPhraseOnTap": "Zikir selesai. Ketuk untuk menghitung zikir berikutnya.",
        "stopAdhan": "Hentikan azan",
        "streamHints": [
            "Media: memakai pengatur volume musik dan video ponsel. Mode dering senyap belum tentu membisukannya; periksa juga volume media dan pengaturan Jangan Ganggu.",
            "Dering: memakai pengatur volume nada dering atau notifikasi ponsel. Mode senyap, getar, dan Jangan Ganggu dapat membisukan azan.",
            "Alarm: memakai pengatur volume alarm ponsel. Mode dering senyap biasanya tidak membisukan alarm; periksa izin alarm dalam pengaturan Jangan Ganggu.",
        ],
    },
    "ur": {
        "nextPhraseOnTap": "ذکر مکمل ہوا۔ اگلا ذکر گننے کے لیے دبائیں۔",
        "aboutTypefaces": "خطوط",
        "aboutVerseMeanings": "آیات کے معانی",
        "aboutUrduDuaCredit": "دعاؤں کے اردو معانی: Hisn منصوبے کا مسودہ؛ اہلِ علم کی نظرثانی باقی ہے۔",
        "aboutTranslationSource": "ترجمے کے مآخذ · تنزیل",
        "aboutLinkCopied": "ماخذ کا ربط نقل ہو گیا۔ اسے اپنے براؤزر میں کھولیں۔",
        "aboutArabicText": "عربی متن",
        "aboutLatinText": "لاطینی متن",
        "aboutLatinApparatus": "لاطینی انٹرفیس کا متن",
        "aboutMushafPages": "مصحف کے صفحات · مجمع ملک فہد برائے طباعت قرآن کریم",
        "streamLabels": ["میڈیا", "رنگر / اطلاعات", "الارم"],
    },
}
for code, updates in UPDATES.items():
    path = ROOT / "lib" / "i18n" / f"{code}.i18n.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    data.update(updates)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print("Updated feedback copy in all four locales.")
