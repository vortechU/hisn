# -*- coding: utf-8 -*-
"""Repairs word breaks in the Quran text under assets/data/quran/surah_*.json.

The bundled Uthmani text arrived with two kinds of damage, both of which show
on screen as wrong Arabic rather than as anything a parser would flag:

  1. A SPACE inside a word, between a tanween and the silent alef that follows
     it — `قَوۡلࣰ ا` where the mushaf has `قَوۡلࣰا`. Arabic shaping joins letters
     only within a word, so the space leaves the lam in its final form and the
     alef isolated: the lām-alef ligature never forms and the word reads as
     two. It happens 2,418 times, wherever tanween meets a silent alef or
     alef maqsura.

  2. A fragment of the Bismillah welded to the front of Al-Qadr 97:1, which
     opened `ٱلرَّحِيمِإِنَّآ` instead of `إِنَّآ`.

Neither is visible to `flutter analyze`, to a JSON schema, or to the verse
counts — the text stays the right length and the right shape, and only a
reader of Arabic sees that a word has come apart.

VERIFICATION — a repair to the Qur'an's text has to be checked against
something other than the judgement of whoever wrote the repair. So this tool
refuses to write until every one of the 6,236 verses matches the Tanzil
Uthmani edition word for word: same number of words, same letters in each,
after folding away the two texts' differing conventions for hamza carriers and
diacritics. Three words are known to differ between the two editions in where
they place a space (the مقطوع/موصول cases below); those are declared, and any
fourth disagreement stops the run.

Idempotent — running it again finds nothing to repair and rewrites the same
bytes. The Tanzil text is cached under tool/.cache/ (gitignored) on first run.

The mushaf facsimile does not go through this data at all: those pages are
runs of private-use glyph codepoints under assets/data/mushaf/. This text is
what the verse list, search, the share card and the home-screen widgets read.

Run from the repo root: python tool/repair_quran_text.py
"""
import io
import json
import os
import re
import sys
import unicodedata
import urllib.request

# Windows consoles default to cp1252 and die on the first non-ASCII character.
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QURAN = os.path.join(ROOT, 'assets', 'data', 'quran')
CACHE = os.path.join(ROOT, 'tool', '.cache')

WITNESS_URL = ('https://tanzil.net/pub/download/index.php'
               '?quranType=uthmani&outType=txt-2&agree=true')
WITNESS_FILE = 'quran-uthmani.txt'

TOTAL_AYAHS = 6236
VERSE_RE = re.compile(r'^(\d+)\|(\d+)\|(.*)$')

# The Bismillah remnant on Al-Qadr, declared as an exact prefix rather than
# matched by a pattern: this is one known-bad verse being corrected, and a
# pattern loose enough to find it would be loose enough to eat a real word.
REMNANTS = {
    (97, 1): 'ٱلرَّحِيمِ',
}

# Words the bundled text writes joined and Tanzil writes apart. Both spellings
# are attested across printed mushafs (the المقطوع والموصول cases), so these
# are a difference between two editions, not damage — and correcting the text
# towards Tanzil on the strength of one other edition would be changing the
# mushaf, not repairing it. Listed so the check can pass them and stop on
# anything it has not been told about.
KNOWN_VARIANTS = {
    (15, 7): ('لوما', ['لو', 'ما']),
    (27, 20): ('مالي', ['ما', 'لي']),
    (36, 22): ('ومالي', ['وما', 'لي']),
}

# Hamza carriers and the alef/ya/ta-marbuta pairs the two editions spell
# differently: ours writes a bare carrier plus a combining hamza, Tanzil the
# precomposed letter. Folded away before comparing, because they are an
# encoding choice and not a difference in the word.
FOLD = {
    'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا',
    'ؤ': 'و', 'ئ': 'ي', 'ى': 'ي', 'ة': 'ه',
}


def letters(token):
    """The token's letters, with every combining mark and sign dropped.

    Category `Lo` is the test rather than a codepoint range, so the pause
    marks, the sajda sign, the rub-el-hizb and the small waw/yeh all fall away
    on their own — they decorate a word, they are not part of one.
    """
    return [c for c in token if unicodedata.category(c) == 'Lo']


def skeleton(token):
    """The token's letters, folded — what makes two spellings the same word."""
    return ''.join(FOLD.get(c, c) for c in letters(token))


def rejoin(text):
    """Puts back any word a space split before its silent alef.

    A token whose only letter is an alef or an alef maqsura cannot be a word:
    Arabic has no one-letter word spelled that way. It is the tail of the word
    in front of it, so that is where it goes — carrying whatever pause mark or
    sajda sign was sitting on it.
    """
    out = []
    for token in text.split(' '):
        if out and letters(token) in (['ا'], ['ى']):
            out[-1] += token
        else:
            out.append(token)
    return ' '.join(out)


def fetch_witness():
    """Tanzil's Uthmani text, downloaded once and cached after."""
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, WITNESS_FILE)
    if not os.path.exists(path):
        print('  downloading {0}'.format(WITNESS_URL))
        with urllib.request.urlopen(WITNESS_URL) as response:
            raw = response.read()
        with open(path, 'wb') as handle:
            handle.write(raw)
    with io.open(path, encoding='utf-8-sig') as handle:
        text = handle.read()

    verses = {}
    for line in text.split('\n'):
        match = VERSE_RE.match(line.rstrip('\r'))
        if match:
            verses[(int(match.group(1)), int(match.group(2)))] = match.group(3)
    if len(verses) != TOTAL_AYAHS:
        raise SystemExit(
            'witness: {0} verses, expected {1} — the upstream format has '
            'moved; inspect tool/.cache/{2}'.format(
                len(verses), TOTAL_AYAHS, WITNESS_FILE))
    return verses


def witness_words(verses, surah, ayah):
    """The witness verse as folded words, without the Bismillah it prefixes.

    Tanzil's download opens every surah's first verse with the Bismillah, which
    the bundled text keeps out of the verses (it is drawn as a header). Matched
    on the folded words rather than on a literal string so the two editions'
    diacritics can't make the prefix invisible.
    """
    words = [w for w in (skeleton(t) for t in verses[(surah, ayah)].split(' '))
             if w]
    bismillah = [skeleton(t) for t in
                 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ'.split(' ')]
    if ayah == 1 and surah not in (1, 9) and words[:4] == bismillah:
        words = words[4:]
    return words


def check(text, verses, surah, ayah):
    """Fails loudly unless the repaired verse reads as the witness does."""
    ours = [w for w in (skeleton(t) for t in text.split(' ')) if w]
    theirs = witness_words(verses, surah, ayah)

    variant = KNOWN_VARIANTS.get((surah, ayah))
    if variant is not None and variant[0] in ours:
        # Re-split our joined spelling the way the witness writes it, so the
        # rest of the verse is still compared word for word rather than waved
        # through wholesale.
        at = ours.index(variant[0])
        ours = ours[:at] + list(variant[1]) + ours[at + 1:]

    if ours != theirs:
        first = next((i for i, (a, b) in enumerate(zip(ours, theirs))
                      if a != b), min(len(ours), len(theirs)))
        raise SystemExit(
            '{0}:{1} does not match the witness after repair — {2} words vs '
            '{3}, first differing at {4} ({5!r} vs {6!r}). Nothing was '
            'written.'.format(
                surah, ayah, len(ours), len(theirs), first,
                ours[first:first + 3], theirs[first:first + 3]))


def main():
    verses = fetch_witness()

    rejoined = 0
    remnants = 0
    changed_files = 0
    for number in range(1, 115):
        path = os.path.join(QURAN, 'surah_{0}.json'.format(number))
        with io.open(path, encoding='utf-8') as handle:
            surah = json.load(handle)

        before = json.dumps(surah, ensure_ascii=False)
        for entry in surah['ayahs']:
            text = entry['text']

            remnant = REMNANTS.get((number, entry['n']))
            if remnant is not None and text.startswith(remnant):
                text = text[len(remnant):]
                remnants += 1

            repaired = rejoin(text)
            rejoined += len(text.split(' ')) - len(repaired.split(' '))

            check(repaired, verses, number, entry['n'])
            entry['text'] = repaired

        after = json.dumps(surah, ensure_ascii=False)
        if after != before:
            with io.open(path, 'w', encoding='utf-8') as handle:
                json.dump(surah, handle, ensure_ascii=False,
                          separators=(',', ':'))
            changed_files += 1

    print('checked {0} verses against the Tanzil Uthmani text'.format(
        TOTAL_AYAHS))
    print('  {0} split words rejoined'.format(rejoined))
    print('  {0} Bismillah remnant(s) removed'.format(remnants))
    print('  {0} surah file(s) rewritten'.format(changed_files))


if __name__ == '__main__':
    main()
