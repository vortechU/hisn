# -*- coding: utf-8 -*-
"""Generates the Quran translation overlays under assets/data/quran/trans/.

The mushaf pages are glyph runs with no verse identity, so a translation can
only ever be joined to them through the surah files — which means the join is
only as trustworthy as the alignment between this data and the app's own surah
index. A translation silently off by one verse is worse than no translation at
all: every meaning would be attached to its neighbour, and nothing on screen
would look wrong. So this tool refuses to write anything until the downloaded
edition matches assets/data/quran/surahs.json exactly — same 114 surahs, same
ayah count in each, no gaps and no duplicates.

Source data comes from Tanzil in their `txt-2` form (`sura|aya|text`), NOT the
plain `txt` form. Plain `txt` is one verse per line with no identifiers, so a
single dropped line would shift every subsequent verse undetectably; the
identified form makes that failure loud.

LICENCE — the translations Tanzil hosts are offered for NON-COMMERCIAL use
only. This is stricter than the Quran text itself (CC-BY 3.0) and it binds the
whole app: bundling this data means Hisn cannot become paid or ad-supported
without re-sourcing it. See TERMS.md section 6.

Re-runnable. Downloads each edition to tool/.cache/ (gitignored) on first run
and reuses it after, so regenerating is offline and reproducible.

Run from the repo root: python tool/gen_quran_translations.py
"""
import io
import json
import os
import re
import sys
import urllib.request

# Windows consoles default to cp1252 and die on the first non-ASCII character.
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INDEX = os.path.join(ROOT, 'assets', 'data', 'quran', 'surahs.json')
OUT_DIR = os.path.join(ROOT, 'assets', 'data', 'quran', 'trans')
CACHE = os.path.join(ROOT, 'tool', '.cache')

SOURCE_NAME = 'Tanzil.net'
SOURCE_URL = 'https://tanzil.net'
DOWNLOAD = 'https://tanzil.net/trans/?transID={id}&type=txt-2'

TOTAL_AYAHS = 6236

# The editions the app bundles. `lang` matches AppLang.name on the Dart side;
# Arabic deliberately has no entry — the text is already Arabic, so an Arabic
# interface drops the meaning line rather than rendering Arabic into Arabic.
EDITIONS = [
    {
        'lang': 'en',
        'id': 'en.hilali',
        'name': 'The Noble Qur’an',
        'translator': 'Muhammad Taqi-ud-Din al-Hilali '
                      'and Muhammad Muhsin Khan',
        # The short citation, for places too tight for the full names — the
        # foot of a share card, mainly.
        'credit': 'Hilali & Khan',
    },
    {
        'lang': 'id',
        'id': 'id.indonesian',
        'name': 'Al-Qur’an dan Terjemahannya',
        'translator': 'Kementerian Agama Republik Indonesia',
        'credit': 'Kemenag RI',
    },
]

VERSE_RE = re.compile(r'^(\d+)\|(\d+)\|(.*)$')

# Transport damage in the upstream text, repaired to the reading the printed
# edition has. This is restoring the text, not editing it — each of these is an
# encoding artifact with exactly one sensible resolution, verified in context
# across every occurrence:
#
#   U+0085 NEXT LINE  — sits where a space belongs every time it appears
#                       ("just dealings,<NEL>announce to them"). It is also a
#                       line break to str.splitlines(), which is why the text
#                       must be repaired BEFORE it is split into lines, or
#                       seven verses arrive truncated.
#   U+0094            — a raw Windows-1252 byte that never got decoded; that
#                       position is a closing curly quote, and it only ever
#                       occurs at the end of a verse that opened a quote.
#   U+00AD SOFT HYPHEN— meant as a real hyphen ("Oft-Pardoning",
#                       "All-Powerful"); left alone it renders as nothing at
#                       all in most text engines, silently welding the words
#                       together.
REPAIRS = {
    '\u0085': ' ',
    '\u0094': '"',
    '\u00ad': '-',
}

# Anything still in the C0/C1 control ranges after repair is damage this tool
# has not seen before. Legitimate non-ASCII (accents, curly quotes) is fine and
# deliberately not caught here — control characters are the corruption class.
CONTROL_RE = re.compile(r'[\x00-\x08\x0b-\x1f\x7f-\x9f]')


def fetch(edition):
    """The edition's raw text, downloading it once and caching it after."""
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, edition['id'] + '.txt')
    if not os.path.exists(path):
        url = DOWNLOAD.format(id=edition['id'])
        print('  downloading {0}'.format(url))
        with urllib.request.urlopen(url) as response:
            raw = response.read()
        with open(path, 'wb') as handle:
            handle.write(raw)
    with io.open(path, encoding='utf-8') as handle:
        return handle.read()


def repair(text, edition):
    """Undo the upstream encoding damage catalogued in REPAIRS."""
    for bad, good in REPAIRS.items():
        text = text.replace(bad, good)
    left = CONTROL_RE.findall(text.replace('\r', ''))
    if left:
        raise SystemExit(
            '{0}: {1} unrecognised control character(s) after repair: {2} — '
            'the upstream text has changed; inspect it and extend REPAIRS '
            'before regenerating'.format(
                edition['id'], len(left),
                sorted({'U+{0:04X}'.format(ord(c)) for c in left})))
    return text


def parse(text, edition):
    """`{surah: {ayah: text}}`, ignoring the trailing licence comment block."""
    verses = {}
    # Split on real newlines only. str.splitlines() also breaks on U+0085 and
    # friends, which would silently truncate verses if a repair is ever missed.
    for number, line in enumerate(text.split('\n'), start=1):
        line = line.rstrip('\r')
        match = VERSE_RE.match(line)
        if not match:
            # Blank lines and the `#`-prefixed trailer are expected; anything
            # else means the format moved and the parse can't be trusted.
            if line.strip() and not line.startswith('#'):
                raise SystemExit(
                    '{0}: unparseable line {1}: {2!r}'.format(
                        edition['id'], number, line[:80]))
            continue
        surah, ayah = int(match.group(1)), int(match.group(2))
        # Collapse space runs. The repaired U+0085 was padded with a space on
        # each side, so replacing it leaves a visible gap — Flutter renders
        # consecutive spaces literally. Verified to touch only the six verses
        # that carried the artifact and nothing else in either edition.
        body = re.sub(r'[ \t]{2,}', ' ', match.group(3)).strip()
        if not body:
            raise SystemExit('{0}: empty verse at {1}:{2}'.format(
                edition['id'], surah, ayah))
        if ayah in verses.setdefault(surah, {}):
            raise SystemExit('{0}: duplicate verse {1}:{2}'.format(
                edition['id'], surah, ayah))
        verses[surah][ayah] = body
    return verses


def check(verses, index, edition):
    """Fails loudly unless the edition lines up with the app's surah index."""
    expected = {s['number']: s['ayahCount'] for s in index}

    missing = sorted(set(expected) - set(verses))
    extra = sorted(set(verses) - set(expected))
    if missing or extra:
        raise SystemExit('{0}: surah mismatch (missing {1}, extra {2})'.format(
            edition['id'], missing, extra))

    for number in sorted(expected):
        want = expected[number]
        got = verses[number]
        # Every ayah from 1..want present exactly once, and nothing past it.
        gaps = [a for a in range(1, want + 1) if a not in got]
        beyond = sorted(a for a in got if a < 1 or a > want)
        if gaps or beyond:
            raise SystemExit(
                '{0}: surah {1} expects {2} ayahs — missing {3}, unexpected '
                '{4}'.format(edition['id'], number, want, gaps, beyond))

    total = sum(len(v) for v in verses.values())
    if total != TOTAL_AYAHS:
        raise SystemExit('{0}: {1} verses, expected {2}'.format(
            edition['id'], total, TOTAL_AYAHS))


def write(verses, index, edition):
    """One minified file per surah, mirroring surah_<N>.json next to it."""
    out = os.path.join(OUT_DIR, edition['lang'])
    os.makedirs(out, exist_ok=True)
    written = 0
    for surah in index:
        number = surah['number']
        got = verses[number]
        body = {
            'number': number,
            'lang': edition['lang'],
            # Positional: index i holds ayah i+1. The count is verified above,
            # so the position is a safe key and costs nothing to store.
            'ayahs': [got[a] for a in range(1, surah['ayahCount'] + 1)],
        }
        path = os.path.join(out, 'surah_{0}.json'.format(number))
        with io.open(path, 'w', encoding='utf-8') as handle:
            json.dump(body, handle, ensure_ascii=False,
                      separators=(',', ':'))
        written += 1
    return written


def main():
    with io.open(INDEX, encoding='utf-8') as handle:
        index = json.load(handle)

    manifest = []
    for edition in EDITIONS:
        print('{0} ({1})'.format(edition['id'], edition['lang']))
        verses = parse(repair(fetch(edition), edition), edition)
        check(verses, index, edition)
        count = write(verses, index, edition)
        print('  {0} surahs, {1} verses'.format(count, TOTAL_AYAHS))
        manifest.append({
            'lang': edition['lang'],
            'id': edition['id'],
            'name': edition['name'],
            'translator': edition['translator'],
            'credit': edition['credit'],
            'source': SOURCE_NAME,
            'sourceUrl': SOURCE_URL,
        })

    # Attribution is generated from the same run that writes the data, so the
    # credit shown in the app can't drift from the edition actually bundled.
    path = os.path.join(OUT_DIR, 'editions.json')
    with io.open(path, 'w', encoding='utf-8') as handle:
        json.dump(manifest, handle, ensure_ascii=False, separators=(',', ':'))
    print('wrote {0}'.format(os.path.relpath(path, ROOT)))


if __name__ == '__main__':
    main()
