"""Build a feedback proposal from the app's existing Quran editions."""

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "assets" / "data" / "quran"
CARD_ID = "waking_imran_190_200"

transliterations = [
    "Inna fi khalqis-samawati wal-ardi wakhtilafil-layli wan-nahari la-ayatin li-ulil-albab.",
    "Alladhina yadhkurunallaha qiyaman wa qu'udan wa 'ala junubihim wa yatafakkaruna fi khalqis-samawati wal-ard. Rabbana ma khalaqta hadha batilan subhanaka faqina 'adhaban-nar.",
    "Rabbana innaka man tudkhilin-nara faqad akhzaytah, wa ma liz-zalimina min ansar.",
    "Rabbana innana sami'na munadiyan yunadi lil-imani an aminu bi-Rabbikum fa-amanna. Rabbana faghfir lana dhunubana wa kaffir 'anna sayyi-atina wa tawaffana ma'al-abrar.",
    "Rabbana wa atina ma wa'adtana 'ala rusulika wa la tukhzina yawmal-qiyamah. Innaka la tukhliful-mi'ad.",
    "Fastajaba lahum Rabbuhum anni la udi'u 'amala 'amilin minkum min dhakarin aw untha, ba'dukum min ba'd. Falladhina hajaru wa ukhriju min diyarihim wa udhu fi sabili wa qatalu wa qutilu la-ukaffiranna 'anhum sayyi-atihim wa la-udkhilannahum jannatin tajri min tahtihal-anharu thawaban min 'indillah. Wallahu 'indahu husnuth-thawab.",
    "La yaghurrannaka taqallubul-ladhina kafaru fil-bilad.",
    "Mata'un qalilun thumma ma'wahum jahannamu wa bi'sal-mihad.",
    "Lakinil-ladhinat-taqaw Rabbahum lahum jannatun tajri min tahtihal-anharu khalidina fiha nuzulan min 'indillah. Wa ma 'indallahi khayrun lil-abrar.",
    "Wa inna min ahlil-kitabi laman yu'minu billahi wa ma unzila ilaykum wa ma unzila ilayhim khashi'ina lillahi la yashtaruna bi-ayatillahi thamanan qalila. Ula'ika lahum ajruhum 'inda Rabbihim. Innallaha sari'ul-hisab.",
    "Ya ayyuhal-ladhina amanusbiru wa sabiru wa rabitu wattaqullaha la'allakum tuflihun.",
]


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def meaning(lang):
    verses = read(DATA / "trans" / lang / "surah_3.json")["ayahs"]
    assert len(verses) == 200
    return "\n\n".join(f"({n}) {verses[n - 1]}" for n in range(190, 201))


verses = [v for v in read(DATA / "surah_3.json")["ayahs"] if 190 <= v["n"] <= 200]
assert [v["n"] for v in verses] == list(range(190, 201))
digits = str.maketrans("0123456789", "٠١٢٣٤٥٦٧٨٩")
arabic = "\n\n".join(f"{v['text']} ﴿{str(v['n']).translate(digits)}﴾" for v in verses)

proposal = {
    "sources": [
        {
            "url": "https://sunnah.com/bukhari:183",
            "reference": "Sahih al-Bukhari 183",
            "note": "Ibn Abbas reports reciting the concluding verses on waking at night. The narration uses 'ten'. Do not label the modern 190–200 range as exactly ten numbered verses.",
        },
        {
            "url": "https://sunnah.com/muslim:763b",
            "reference": "Sahih Muslim 763b",
            "note": "Parallel primary report of recitation on waking at night.",
        },
        {
            "url": "https://sunnah.com/bukhari:4569",
            "reference": "Sahih al-Bukhari 4569",
            "note": "Explicitly names the beginning verse: Inna fi khalqis-samawati (3:190).",
        },
        {
            "url": "https://sunnah.com/hisn:4",
            "reference": "Hisn al-Muslim 4",
            "note": "Established compilation supplies Quran 3:190–200 under waking. This has eleven numbered verses in the bundled Quran; title the range explicitly. No threefold repeat is specified.",
        },
    ],
    "bundledContent": {
        "arabic": "assets/data/quran/surah_3.json",
        "en": "assets/data/quran/trans/en/surah_3.json",
        "id": "assets/data/quran/trans/id/surah_3.json",
        "range": [190, 200],
        "verseCount": 11,
        "note": "Arabic and both meaning editions copied exactly, with verse markers added. Transliteration is a conventional ASCII rendering of the same full verses.",
    },
    "insertAfter": {CARD_ID: "waking_afani"},
    "additions": [
        {
            "id": CARD_ID,
            "categoryId": "waking",
            "title": "Aal Imran (3:190–200)",
            "titleArabic": "آل عمران (١٩٠–٢٠٠)",
            "arabic": arabic,
            "transliteration": "\n\n".join(f"({n}) {text}" for n, text in zip(range(190, 201), transliterations)),
            "translation": meaning("en"),
            "reference": "Qur'an 3:190–200; Sahih al-Bukhari 183, 4569; Sahih Muslim 763b",
            "repeat": 1,
            "instruction": "When waking during the night, recite these concluding verses of Aal Imran (3:190–200).",
        }
    ],
    "ar": {
        CARD_ID: {
            "reference": "القرآن الكريم، آل عمران ١٩٠–٢٠٠؛ صحيح البخاري ١٨٣، ٤٥٦٩؛ صحيح مسلم ٧٦٣",
            "instruction": "عند الاستيقاظ من النوم ليلًا، تُقرأ هذه الآيات من خواتيم سورة آل عمران (١٩٠–٢٠٠).",
        }
    },
    "id": {
        CARD_ID: {
            "translation": meaning("id"),
            "instruction": "Saat terbangun pada malam hari, bacalah ayat-ayat penutup surah Ali Imran ini (3:190–200).",
        }
    },
}

target = ROOT / "tool" / "feedback" / "waking_imran_updates.json"
target.write_text(json.dumps(proposal, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"Created {target.name}: {len(verses)} verses; Arabic {len(arabic)} characters.")
