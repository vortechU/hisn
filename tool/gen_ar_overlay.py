# -*- coding: utf-8 -*-
"""Generates assets/data/duas.ar.json: the Arabic overlay of each dua's SOURCE,
VIRTUE and practical INSTRUCTION.

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
    ('Ibn Hibban', 'ابن حبان'),
    ('Sunan Ibn Majah', 'سنن ابن ماجه'),
    ("Jami at-Tirmidhi", "جامع الترمذي"),
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
SURAHS = {'2': 'البقرة', '21': 'الأنبياء', '3': 'آل عمران', '7': 'الأعراف'}

PHRASES = [
    ('(graded sahih by al-Albani)', '(صححه الألباني)'),
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
    # Latin suffixes identify parallel reports (e.g. Muslim 763b).
    suffixes = dict(zip('abcdef', 'أبجدهو'))
    out = re.sub(r'(\d)([a-f])\b', lambda m: m[1] + suffixes[m[2]], out)
    out = out.replace(';', '؛').replace(',', '،')
    if re.search('[A-Za-z]', out):
        raise SystemExit(f'untranslated fragment in reference: {ref!r} -> {out!r}')
    return out


VIRTUES = {
    'morning_ayat_kursi':
        'من قرأها حين يُصبح أُجير من الجن حتى يُمسي.',
    'evening_ayat_kursi':
        'من قرأها حين يُمسي أُجير من الجن حتى يُصبح.',
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

# Each surah keeps the former group's virtue. The bedtime entries retain the
# same nightly-practice note as the former three-Quls card.
for prefix in ('morning', 'evening'):
    virtue = VIRTUES.pop(f'{prefix}_muawwidhat')
    for surah in ('ikhlas', 'falaq', 'nas'):
        VIRTUES[f'{prefix}_{surah}'] = virtue
for surah in ('ikhlas', 'falaq', 'nas'):
    VIRTUES[f'sleep_{surah}'] = 'كان النبي صلى الله عليه وسلم يفعل ذلك كل ليلة قبل أن ينام.'




# BEGIN REVIEWED FEEDBACK TABLES
VIRTUES.update({'mosque_adhan_testimony': 'تُقال عند سماع المؤذن؛ وقد وعد النبي صلى الله عليه وسلم من قالها '
                           'بمغفرة ذنبه.',
 'mosque_after_adhan_salawat': 'بعد الفراغ من إجابة المؤذن يُصلَّى على النبي صلى الله عليه وسلم، '
                               'ثم تُسأل له الوسيلة. ومن صلّى عليه صلاةً صلّى الله عليه بها عشرًا. '
                               'وهذه إحدى الصيغ الثابتة، وحديث الأذان لا يخصّها دون غيرها.',
 'daily_wearing_clothes': 'من قالها عند لبس الثوب غُفر له ما تقدّم من ذنبه.',
 'salah_ilman_nafian': 'كان النبي صلى الله عليه وسلم يقولها إذا سلّم من صلاة الفجر.',
 'sleep_tasbih_fatima': 'علّمه النبي صلى الله عليه وسلم فاطمة رضي الله عنها بدلًا من خادم؛ وهو خير '
                        'لها من خادم.',
 'sleep_night_fear': 'تُقال للصبي أو لمن فزع من النوم.',
 'daily_marketplace': 'من قالها في السوق كتب الله له ألف ألف حسنة، ومحا عنه ألف ألف سيئة، وبنى له '
                      'بيتًا في الجنة.',
 'daily_anger': 'قال النبي صلى الله عليه وسلم: إن الغضب من الشيطان، فمن وجده وهو قائم فليجلس، ومن '
                'وجده وهو جالس فليضطجع.',
 'daily_jazakallah_khayr': 'من قيلت له فقد أُبلغ في الثناء.',
 'daily_seeing_afflicted': 'تُقال سرًّا ولا يسمعها المبتلى؛ من قالها لم يصبه ذلك البلاء.',
 'forgiveness_rabbana_zalamna': 'دعاء آدم وحواء عليهما السلام بعد الخطيئة.',
 'distress_musibah': 'من قالها عند المصيبة أجره الله فيها وأخلف له خيرًا منها.',
 'distress_against_oppressor': 'كان النبي صلى الله عليه وسلم يقولها إذا خاف قومًا.',
 'travel_astawdiuka': 'كان النبي صلى الله عليه وسلم يقولها لمن أراد سفرًا.',
 'mosque_adhan_response_hayya': 'تُقال بدلًا من ترديد قول المؤذن عند حي على الصلاة وحي على الفلاح، '
                                'وما عداهما يُردَّد كما يقوله المؤذن.',
 'mosque_going': 'من دعاء النبي صلى الله عليه وسلم إذا خرج إلى المسجد ليلًا.'})
VIRTUES.pop('daily_entering_home', None)
SURAHS.update({'24': 'النور'})
INSTRUCTIONS = {'salah_tasbih_tahlil_final': 'بعد قول سبحان الله ٣٣ مرة، والحمد لله ٣٣ مرة، والله أكبر ٣٣ مرة، '
                              'يُقال هذا الذكر مرة واحدة لإتمام المائة.',
 'sleep_ikhlas': 'عند النوم، اجمع كفيك وانفث فيهما نفثًا خفيفًا واقرأ سور الإخلاص والفلق والناس، '
                 'ثم امسح بهما ما استطعت من جسدك، بدءًا برأسك ووجهك ومقدمة جسدك. كرر النفث '
                 'والقراءة والمسح ثلاث مرات.',
 'sleep_falaq': 'عند النوم، اجمع كفيك وانفث فيهما نفثًا خفيفًا واقرأ سور الإخلاص والفلق والناس، ثم '
                'امسح بهما ما استطعت من جسدك، بدءًا برأسك ووجهك ومقدمة جسدك. كرر النفث والقراءة '
                'والمسح ثلاث مرات.',
 'sleep_nas': 'عند النوم، اجمع كفيك وانفث فيهما نفثًا خفيفًا واقرأ سور الإخلاص والفلق والناس، ثم '
              'امسح بهما ما استطعت من جسدك، بدءًا برأسك ووجهك ومقدمة جسدك. كرر النفث والقراءة '
              'والمسح ثلاث مرات.',
 'waking_imran_190_200': 'عند الاستيقاظ من النوم ليلًا، تُقرأ هذه الآيات من خواتيم سورة آل عمران '
                         '(١٩٠–٢٠٠).',
 'daily_entering_home': 'اذكر الله عند الدخول وسلّم على أهل بيتك. وقد ثبت هذان الأمران مستقلّين في '
                        'صحيح مسلم ٢٠١٨ والقرآن الكريم، النور: ٦١. واختلف العلماء في درجة هذا '
                        'الدعاء المروي؛ حسّنه ابن باز وضعّفه الألباني.',
 'daily_wearing_clothes': 'هذا الدعاء عند لبس الثوب، سواء أكان جديدًا أم سبق لبسه. وعند لبس النعل '
                          'ابدأ بالقدم اليمنى، وعند خلعه ابدأ باليسرى. وهذه إرشادات للعمل وليست '
                          'ذكرًا يُتلى.',
 'daily_wearing_new_clothes': 'عند لبس النعل ابدأ بالقدم اليمنى، وعند خلعه ابدأ باليسرى (صحيح مسلم '
                              '٢٠٩٧).'}
VIRTUES['mosque_after_wudu'] = 'من أسبغ الوضوء ثم قالها فُتحت له أبواب الجنة الثمانية، يدخل من أيها شاء.'
INSTRUCTIONS['waking_alhamdulillah_ahyana'] = 'عند الاستيقاظ، امسح أثر النوم عن وجهك بيدك، كما فعل النبي صلى الله عليه وسلم (صحيح البخاري ١٨٣). هذا عمل وليس دعاءً يُتلى.'
INSTRUCTIONS['travel_returning'] = 'عند الرجوع من السفر يُقال دعاء السفر نفسه، ويُزاد في آخره: آيبون تائبون عابدون لربنا حامدون.'
INSTRUCTIONS['mosque_adhan_testimony'] = 'يُقال بعد انتهاء المؤذن من الشهادتين، قبل قوله: حي على الصلاة.'
with_instruction = {d["id"] for d in json.load(open(SRC, encoding="utf-8")) if d.get("instruction")}
if with_instruction != set(INSTRUCTIONS):
    raise SystemExit("instruction mismatch")
# END REVIEWED FEEDBACK TABLES

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
        'scope': 'Arabic rendering of the SOURCE, VIRTUE and practical INSTRUCTION. No '
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
    if d.get('instruction'):
        entry['instruction'] = INSTRUCTIONS[d['id']]
    out[d['id']] = entry

with io.open(OUT, 'w', encoding='utf-8', newline='\n') as f:
    json.dump(out, f, ensure_ascii=False, indent=2)
    f.write('\n')

print(f'wrote {OUT}: {len(duas)} references, {len(VIRTUES)} virtues')
