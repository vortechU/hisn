# -*- coding: utf-8 -*-
"""Generates assets/data/duas.ar.json: the Arabic overlay of each dua's SOURCE
and VIRTUE.

No `translation` field: the dua text is already Arabic, so an Arabic interface
drops the meaning line rather than rendering Arabic back into Arabic.

Sources are written here with Western digits and converted to Arabic-Indic at
the end, so no hadith number is ever transcribed by hand twice. Re-runnable:
rewrites the file from duas.json, and fails loudly if a source contains a
fragment it has no Arabic for, or if the virtue list has drifted out of step
with the base data.

Run from the repo root: python tool/gen_ar_overlay.py
"""
import io
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'assets', 'data', 'duas.json')
OUT = os.path.join(ROOT, 'assets', 'data', 'duas.ar.json')

# Collection names, longest first so "Sunan at-Tirmidhi" wins over "Tirmidhi".
COLLECTIONS = [
    ("An-Nasa'i, 'Amal al-Yawm wa al-Laylah", 'النسائي، عمل اليوم والليلة'),
    ("At-Tabarani, al-Mu'jam al-Awsat", 'الطبراني، المعجم الأوسط'),
    ('Sahih al-Bukhari', 'صحيح البخاري'),
    ('Sunan at-Tirmidhi', 'سنن الترمذي'),
    ('Sunan Abi Dawud', 'سنن أبي داود'),
    ('Sahih Muslim', 'صحيح مسلم'),
    ('Musnad Ahmad', 'مسند أحمد'),
    ('al-Bukhari', 'البخاري'),
    ('Ibn Majah', 'ابن ماجه'),
    ('Tirmidhi', 'الترمذي'),
    ('Muslim', 'مسلم'),
    ("an-Nasa'i", 'النسائي'),
]

# Surah names for the four Qur'anic citations, which are cited by name in
# Arabic convention rather than by number.
SURAHS = {'2': 'البقرة', '21': 'الأنبياء', '3': 'آل عمران'}

PHRASES = [
    ('(graded hasan)', '(حسن)'),
    ('(recited after each prayer)', '(تُقرأ دبر كل صلاة)'),
]


def arabize_reference(ref: str) -> str:
    out = ref
    # Qur'an citations: "Qur'an 2:255" -> "القرآن الكريم، البقرة: 255"
    def quran(m):
        return f"القرآن الكريم، {SURAHS[m.group(1)]}: {m.group(2)}"
    out = re.sub(r"Qur'an (\d+):(\d+)", quran, out)
    for en, ar in COLLECTIONS:
        out = out.replace(en, ar)
    for en, ar in PHRASES:
        out = out.replace(en, ar)
    out = out.replace(';', '؛').replace(',', '،')
    if re.search('[A-Za-z]', out):
        raise SystemExit(f'untranslated fragment in reference: {ref!r} -> {out!r}')
    return out


VIRTUES = {
    'morning_ayat_kursi':
        'من قرأها حين يُصبح أُجير من الجن حتى يُمسي.',
    'morning_muawwidhat':
        'من قرأهنّ ثلاث مرات حين يُصبح وحين يُمسي كفَتْه من كل شيء.',
    'morning_sayyidul_istighfar':
        'من قالها من النهار موقنًا بها فمات من يومه قبل أن يُمسي فهو من أهل الجنة.',
    'morning_ushhiduka':
        'من قالها أربع مرات حين يُصبح أو حين يُمسي أعتقه الله من النار.',
    'morning_hasbiyallah':
        'من قالها سبع مرات حين يُصبح وحين يُمسي كفاه الله ما أهمّه.',
    'morning_bismillah_la_yadurr':
        'من قالها ثلاث مرات لم تُصبه فجأةُ بلاء.',
    'morning_radeetu':
        'من قالها ثلاث مرات حين يُصبح وحين يُمسي كان حقًّا على الله أن يُرضيه يوم القيامة.',
    'morning_ma_asbaha_nimah':
        'من قالها فقد أدّى شكر يومه.',
    'morning_salah_nabi':
        'من صلّى على النبي ﷺ عشرًا حين يُصبح وعشرًا حين يُمسي أدركته شفاعته يوم القيامة.',
    'morning_tahlil_100':
        'من قالها مائة مرة في يوم كانت له عدل عشر رقاب، وكُتبت له مائة حسنة، '
        'ومُحيت عنه مائة سيئة، وكانت له حِرزًا من الشيطان يومه ذلك.',
    'morning_subhanallah_adada':
        'كلمات لو وُزنت بكل ما قيل من الذكر منذ الصباح لرجحتهنّ.',
    'morning_subhanallah_bihamdihi':
        'من قالها مائة مرة في اليوم حُطّت خطاياه وإن كانت مثل زبد البحر.',
    'evening_muawwidhat':
        'من قرأهنّ ثلاث مرات حين يُصبح وحين يُمسي كفَتْه من كل شيء.',
    'evening_sayyidul_istighfar':
        'من قالها من الليل موقنًا بها فمات من ليلته قبل أن يُصبح فهو من أهل الجنة.',
    'evening_ushhiduka':
        'من قالها أربع مرات حين يُصبح أو حين يُمسي أعتقه الله من النار.',
    'evening_audhu_kalimat':
        'من قالها ثلاث مرات حين يُمسي لم يضرّه شيء تلك الليلة.',
    'evening_hasbiyallah':
        'من قالها سبع مرات حين يُصبح وحين يُمسي كفاه الله ما أهمّه.',
    'evening_bismillah_la_yadurr':
        'من قالها ثلاث مرات لم تُصبه فجأةُ بلاء.',
    'evening_radeetu':
        'من قالها ثلاث مرات حين يُصبح وحين يُمسي كان حقًّا على الله أن يُرضيه يوم القيامة.',
    'evening_salah_nabi':
        'من صلّى على النبي ﷺ عشرًا حين يُصبح وعشرًا حين يُمسي أدركته شفاعته يوم القيامة.',
    'evening_subhanallah_bihamdihi':
        'من قالها مائة مرة حُطّت خطاياه وإن كانت مثل زبد البحر.',
    'salah_allahu_akbar':
        'من تمّم المائة بالتهليل غُفرت خطاياه وإن كانت مثل زبد البحر.',
    'salah_ayat_kursi':
        'من قرأها دبر كل صلاة مكتوبة لم يمنعه من دخول الجنة إلا أن يموت.',
    'sleep_ayat_kursi':
        'من قرأها إذا أوى إلى فراشه لم يزل عليه من الله حافظ، ولا يقربه شيطان حتى يُصبح.',
    'sleep_aslamtu':
        'من قالها فمات من ليلته مات على الفطرة.',
    'daily_after_eating':
        'من قالها بعد الطعام غُفر له ما تقدّم من ذنبه.',
    'daily_leaving_home':
        'يُقال له: هُديتَ وكُفيتَ ووُقيتَ، وتنحّى عنه الشيطان.',
    'forgiveness_astaghfirullah_azim':
        'من قالها غُفر له وإن كان فرّ من الزحف.',
    'forgiveness_yunus':
        'ما دعا بها مسلم في شيء قط إلا استجاب الله له.',
    'distress_hasbunallah':
        'قالها إبراهيم عليه السلام حين أُلقي في النار، وقالها النبي ﷺ والمؤمنون.',
    'travel_stopping':
        'من نزل منزلًا فقالها لم يضرّه شيء حتى يرتحل.',
    'mosque_after_adhan':
        'من قالها بعد الأذان حلّت له الشفاعة يوم القيامة.',
}

ARABIC_DIGITS = str.maketrans('0123456789', '٠١٢٣٤٥٦٧٨٩')

duas = json.load(open(SRC, encoding='utf-8'))

# Every dua that carries a virtue must have an Arabic one, and vice versa.
with_virtue = {d['id'] for d in duas if d.get('virtue')}
missing = with_virtue - set(VIRTUES)
extra = set(VIRTUES) - with_virtue
if missing or extra:
    raise SystemExit(f'virtue mismatch: missing={sorted(missing)} extra={sorted(extra)}')

out = {
    '_meta': {
        'status': 'DRAFT — requires review by a qualified person before release',
        'scope': 'Arabic rendering of the SOURCE and the VIRTUE only. No '
                 'translation field: the dua text is already Arabic, so the '
                 'card drops the meaning line entirely in an Arabic interface.',
        'source': 'Collection names and hadith numbering as they appear in the '
                  'Arabic editions; virtues follow the wording of Hisn '
                  "al-Muslim (Sa'id al-Qahtani).",
    }
}

for d in duas:
    entry = {'reference': arabize_reference(d['reference']).translate(ARABIC_DIGITS)}
    if d.get('virtue'):
        entry['virtue'] = VIRTUES[d['id']]
    out[d['id']] = entry

with io.open(OUT, 'w', encoding='utf-8', newline='\n') as f:
    json.dump(out, f, ensure_ascii=False, indent=2)
    f.write('\n')

print(f'wrote {OUT}: {len(duas)} references, {len(VIRTUES)} virtues')
