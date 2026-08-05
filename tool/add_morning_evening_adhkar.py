# -*- coding: utf-8 -*-
"""One-off: add the well-known Hisn al-Muslim morning/evening adhkar that were
missing (fitrah, ush-hiduka x4, ya Hayyu ya Qayyum, salawat x10) to
assets/data/duas.json, plus DRAFT Indonesian meanings to assets/data/duas.id.json.

Re-runnable: skips ids that already exist.
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DUAS = os.path.join(ROOT, "assets", "data", "duas.json")
DUAS_ID = os.path.join(ROOT, "assets", "data", "duas.id.json")

SALLA = "صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ"

# New entries keyed by the existing id they should be inserted *after*.
NEW = {
    # ---- morning ----
    "morning_sayyidul_istighfar": {
        "id": "morning_ushhiduka",
        "categoryId": "morning",
        "title": "Calling Allah to witness (four times)",
        "titleArabic": "اللَّهُمَّ إِنِّي أَصْبَحْتُ أُشْهِدُكَ",
        "arabic": "اللَّهُمَّ إِنِّي أَصْبَحْتُ أُشْهِدُكَ، وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، وَمَلَائِكَتَكَ، وَجَمِيعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللَّهُ لَا إِلَهَ إِلَّا أَنْتَ وَحْدَكَ لَا شَرِيكَ لَكَ، وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُولُكَ",
        "transliteration": "Allahumma inni asbahtu ush-hiduka, wa ush-hidu hamalata 'arshik, wa mala'ikatak, wa jami'a khalqik, annaka antallahu la ilaha illa anta wahdaka la sharika lak, wa anna Muhammadan 'abduka wa rasuluk",
        "translation": "O Allah, I have entered the morning calling You to witness, and calling to witness the bearers of Your Throne, Your angels, and all Your creation, that You are Allah — there is no deity but You alone, without partner — and that Muhammad is Your servant and Messenger.",
        "reference": "Sunan Abi Dawud 5069",
        "repeat": 4,
        "virtue": "Whoever says it four times in the morning or evening, Allah will free him from the Fire.",
    },
    "morning_bika_asbahna": {
        "id": "morning_fitrah",
        "categoryId": "morning",
        "title": "Upon the natural way of Islam",
        "titleArabic": "أَصْبَحْنَا عَلَى فِطْرَةِ الْإِسْلَامِ",
        "arabic": "أَصْبَحْنَا عَلَى فِطْرَةِ الْإِسْلَامِ، وَعَلَى كَلِمَةِ الْإِخْلَاصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ "
        + SALLA
        + "، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ، حَنِيفًا مُسْلِمًا، وَمَا كَانَ مِنَ الْمُشْرِكِينَ",
        "transliteration": "Asbahna 'ala fitratil-Islam, wa 'ala kalimatil-ikhlas, wa 'ala dini nabiyyina Muhammadin sallallahu 'alayhi wa sallam, wa 'ala millati abina Ibrahima, hanifan musliman, wa ma kana minal-mushrikin",
        "translation": "We have entered the morning upon the natural way of Islam, the word of sincere devotion (the testimony of faith), the religion of our Prophet Muhammad (peace be upon him), and the creed of our father Ibrahim — upright, a Muslim, and he was not of those who associate partners with Allah.",
        "reference": "Musnad Ahmad 15367",
        "repeat": 1,
    },
    "morning_afwa_afiyah": {
        "id": "morning_ya_hayyu",
        "categoryId": "morning",
        "title": "O Ever-Living, O Sustainer",
        "titleArabic": "يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ",
        "arabic": "يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ",
        "transliteration": "Ya Hayyu ya Qayyumu bi-rahmatika astaghith, aslih li sha'ni kullah, wa la takilni ila nafsi tarfata 'ayn",
        "translation": "O Ever-Living, O Sustainer of all, by Your mercy I seek relief. Set right all of my affairs, and do not leave me to myself for the blink of an eye.",
        "reference": "An-Nasa'i, 'Amal al-Yawm wa al-Laylah 575 (graded hasan)",
        "repeat": 1,
    },
    "morning_ma_asbaha_nimah": {
        "id": "morning_salah_nabi",
        "categoryId": "morning",
        "title": "Blessings upon the Prophet ﷺ (ten times)",
        "titleArabic": "الصَّلَاةُ عَلَى النَّبِيِّ",
        "arabic": "اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ",
        "transliteration": "Allahumma salli wa sallim 'ala nabiyyina Muhammad",
        "translation": "O Allah, send Your prayers and peace upon our Prophet Muhammad.",
        "reference": "At-Tabarani, al-Mu'jam al-Awsat (graded hasan)",
        "repeat": 10,
        "virtue": "Whoever sends blessings upon the Prophet ﷺ ten times in the morning and ten in the evening will attain his intercession on the Day of Resurrection.",
    },
    # ---- evening ----
    "evening_sayyidul_istighfar": {
        "id": "evening_ushhiduka",
        "categoryId": "evening",
        "title": "Calling Allah to witness (four times)",
        "titleArabic": "اللَّهُمَّ إِنِّي أَمْسَيْتُ أُشْهِدُكَ",
        "arabic": "اللَّهُمَّ إِنِّي أَمْسَيْتُ أُشْهِدُكَ، وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، وَمَلَائِكَتَكَ، وَجَمِيعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللَّهُ لَا إِلَهَ إِلَّا أَنْتَ وَحْدَكَ لَا شَرِيكَ لَكَ، وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُولُكَ",
        "transliteration": "Allahumma inni amsaytu ush-hiduka, wa ush-hidu hamalata 'arshik, wa mala'ikatak, wa jami'a khalqik, annaka antallahu la ilaha illa anta wahdaka la sharika lak, wa anna Muhammadan 'abduka wa rasuluk",
        "translation": "O Allah, I have entered the evening calling You to witness, and calling to witness the bearers of Your Throne, Your angels, and all Your creation, that You are Allah — there is no deity but You alone, without partner — and that Muhammad is Your servant and Messenger.",
        "reference": "Sunan Abi Dawud 5069",
        "repeat": 4,
        "virtue": "Whoever says it four times in the morning or evening, Allah will free him from the Fire.",
    },
    "evening_bika_amsayna": {
        "id": "evening_fitrah",
        "categoryId": "evening",
        "title": "Upon the natural way of Islam",
        "titleArabic": "أَمْسَيْنَا عَلَى فِطْرَةِ الْإِسْلَامِ",
        "arabic": "أَمْسَيْنَا عَلَى فِطْرَةِ الْإِسْلَامِ، وَعَلَى كَلِمَةِ الْإِخْلَاصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ "
        + SALLA
        + "، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ، حَنِيفًا مُسْلِمًا، وَمَا كَانَ مِنَ الْمُشْرِكِينَ",
        "transliteration": "Amsayna 'ala fitratil-Islam, wa 'ala kalimatil-ikhlas, wa 'ala dini nabiyyina Muhammadin sallallahu 'alayhi wa sallam, wa 'ala millati abina Ibrahima, hanifan musliman, wa ma kana minal-mushrikin",
        "translation": "We have entered the evening upon the natural way of Islam, the word of sincere devotion (the testimony of faith), the religion of our Prophet Muhammad (peace be upon him), and the creed of our father Ibrahim — upright, a Muslim, and he was not of those who associate partners with Allah.",
        "reference": "Musnad Ahmad 15367",
        "repeat": 1,
    },
    "evening_afwa_afiyah": {
        "id": "evening_ya_hayyu",
        "categoryId": "evening",
        "title": "O Ever-Living, O Sustainer",
        "titleArabic": "يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ",
        "arabic": "يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ",
        "transliteration": "Ya Hayyu ya Qayyumu bi-rahmatika astaghith, aslih li sha'ni kullah, wa la takilni ila nafsi tarfata 'ayn",
        "translation": "O Ever-Living, O Sustainer of all, by Your mercy I seek relief. Set right all of my affairs, and do not leave me to myself for the blink of an eye.",
        "reference": "An-Nasa'i, 'Amal al-Yawm wa al-Laylah 575 (graded hasan)",
        "repeat": 1,
    },
    "evening_ma_amsa_nimah": {
        "id": "evening_salah_nabi",
        "categoryId": "evening",
        "title": "Blessings upon the Prophet ﷺ (ten times)",
        "titleArabic": "الصَّلَاةُ عَلَى النَّبِيِّ",
        "arabic": "اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ",
        "transliteration": "Allahumma salli wa sallim 'ala nabiyyina Muhammad",
        "translation": "O Allah, send Your prayers and peace upon our Prophet Muhammad.",
        "reference": "At-Tabarani, al-Mu'jam al-Awsat (graded hasan)",
        "repeat": 10,
        "virtue": "Whoever sends blessings upon the Prophet ﷺ ten times in the morning and ten in the evening will attain his intercession on the Day of Resurrection.",
    },
}

# DRAFT Indonesian meanings for the new ids.
NEW_ID = {
    "morning_ushhiduka": {
        "translation": "Ya Allah, sesungguhnya di pagi ini aku mempersaksikan Engkau, dan mempersaksikan para pemikul 'Arsy-Mu, para malaikat-Mu, dan seluruh makhluk-Mu, bahwa sesungguhnya Engkau adalah Allah, tidak ada tuhan yang berhak disembah selain Engkau semata, tiada sekutu bagi-Mu, dan bahwa Muhammad adalah hamba dan utusan-Mu.",
        "virtue": "Siapa mengucapkannya empat kali pada pagi atau petang, Allah membebaskannya dari neraka.",
    },
    "morning_fitrah": {
        "translation": "Kami memasuki waktu pagi di atas fitrah Islam, di atas kalimat ikhlas (syahadat), di atas agama Nabi kami Muhammad (semoga selawat dan salam atasnya), dan di atas agama bapak kami Ibrahim, yang lurus lagi berserah diri, dan beliau bukan termasuk orang-orang musyrik.",
    },
    "morning_ya_hayyu": {
        "translation": "Wahai Yang Maha Hidup, wahai Yang Maha Berdiri sendiri, dengan rahmat-Mu aku memohon pertolongan. Perbaikilah seluruh urusanku, dan janganlah Engkau serahkan aku kepada diriku sendiri walau sekejap mata.",
    },
    "morning_salah_nabi": {
        "translation": "Ya Allah, limpahkanlah selawat dan salam kepada Nabi kami Muhammad.",
        "virtue": "Siapa bersalawat kepada Nabi sepuluh kali pada pagi dan sepuluh kali pada petang, ia akan memperoleh syafaat beliau pada hari kiamat.",
    },
    "evening_ushhiduka": {
        "translation": "Ya Allah, sesungguhnya di petang ini aku mempersaksikan Engkau, dan mempersaksikan para pemikul 'Arsy-Mu, para malaikat-Mu, dan seluruh makhluk-Mu, bahwa sesungguhnya Engkau adalah Allah, tidak ada tuhan yang berhak disembah selain Engkau semata, tiada sekutu bagi-Mu, dan bahwa Muhammad adalah hamba dan utusan-Mu.",
        "virtue": "Siapa mengucapkannya empat kali pada pagi atau petang, Allah membebaskannya dari neraka.",
    },
    "evening_fitrah": {
        "translation": "Kami memasuki waktu petang di atas fitrah Islam, di atas kalimat ikhlas (syahadat), di atas agama Nabi kami Muhammad (semoga selawat dan salam atasnya), dan di atas agama bapak kami Ibrahim, yang lurus lagi berserah diri, dan beliau bukan termasuk orang-orang musyrik.",
    },
    "evening_ya_hayyu": {
        "translation": "Wahai Yang Maha Hidup, wahai Yang Maha Berdiri sendiri, dengan rahmat-Mu aku memohon pertolongan. Perbaikilah seluruh urusanku, dan janganlah Engkau serahkan aku kepada diriku sendiri walau sekejap mata.",
    },
    "evening_salah_nabi": {
        "translation": "Ya Allah, limpahkanlah selawat dan salam kepada Nabi kami Muhammad.",
        "virtue": "Siapa bersalawat kepada Nabi sepuluh kali pada pagi dan sepuluh kali pada petang, ia akan memperoleh syafaat beliau pada hari kiamat.",
    },
}


def main():
    duas = json.load(open(DUAS, encoding="utf-8"))
    existing = {d["id"] for d in duas}
    out = []
    added = 0
    for d in duas:
        out.append(d)
        ins = NEW.get(d["id"])
        if ins and ins["id"] not in existing:
            out.append(ins)
            existing.add(ins["id"])
            added += 1
    json.dump(out, open(DUAS, "w", encoding="utf-8"), ensure_ascii=False, indent=2)

    overlay = json.load(open(DUAS_ID, encoding="utf-8"))
    for k, v in NEW_ID.items():
        overlay.setdefault(k, v)
    json.dump(overlay, open(DUAS_ID, "w", encoding="utf-8"), ensure_ascii=False, indent=2)

    morning = sum(1 for d in out if d["categoryId"] == "morning")
    evening = sum(1 for d in out if d["categoryId"] == "evening")
    print(f"added {added} entries; total {len(out)}; morning {morning}; evening {evening}")


if __name__ == "__main__":
    main()
