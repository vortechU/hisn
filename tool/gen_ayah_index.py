#!/usr/bin/env python3
"""Generate assets/data/mushaf/ayah_index.json — which verse each page closes.

A mushaf page is a run of private-use glyph codepoints with no verse identity
in it: an āyah rosette is just ``{"t":"end"}``. Anything that wants to name the
verse under a reader's finger needs a way back from a rosette to a citation.

The way back is that the rosettes are the verses. Across the 604 pages there
are exactly 6,236 of them, in order, so the n-th rosette closes the n-th āyah
of the Qur'an. This script walks the pages, counts, and writes the running
total before each one; the app turns that into a citation with the ayah counts
it already has in surahs.json.

It does NOT trust the ``page`` field on each verse in the surah files. That
field disagrees with the printed pages for 56 verses, and where the two differ
it is the field that is wrong — see the anchor check at the foot of this file,
which the rosette count passes and the field does not.

Run from the project root:  python tool/gen_ayah_index.py
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MUSHAF = ROOT / "assets" / "data" / "mushaf"
QURAN = ROOT / "assets" / "data" / "quran"
PAGES = 604
AYAHS = 6236

# Where each juz begins, and the page it begins on in the Madani mushaf. Two of
# these fall mid-page, so they pin the verse-to-page mapping rather than the
# page's first verse.
JUZ_STARTS = [
    (2, 142, 22), (2, 253, 42), (3, 93, 62), (4, 24, 82), (4, 148, 102),
    (5, 83, 121), (6, 111, 142), (7, 88, 162), (8, 41, 182), (9, 93, 201),
    (11, 6, 222), (12, 53, 242), (15, 1, 262), (17, 1, 282), (18, 75, 302),
    (21, 1, 322), (23, 1, 342), (25, 21, 362), (27, 56, 382), (29, 46, 402),
    (33, 31, 422), (36, 28, 442), (39, 32, 462), (41, 47, 482), (46, 1, 502),
    (51, 31, 522), (58, 1, 542), (67, 1, 562), (78, 1, 582),
]


def load_order():
    """Every āyah of the Qur'an in mushaf order, as (surah, ayah)."""
    order = []
    for surah in range(1, 115):
        data = json.loads((QURAN / f"surah_{surah}.json").read_text("utf-8"))
        for ayah in data["ayahs"]:
            order.append((surah, ayah["n"]))
    return order


def rosettes_per_page():
    counts = []
    for page in range(1, PAGES + 1):
        data = json.loads((MUSHAF / f"{page:03d}.json").read_text("utf-8"))
        counts.append(sum(
            1
            for line in data["lines"]
            for word in line["words"]
            if word.get("t") == "end"
        ))
    return counts


def main():
    order = load_order()
    counts = rosettes_per_page()

    if len(order) != AYAHS:
        sys.exit(f"expected {AYAHS} verses in the surah files, found {len(order)}")
    if sum(counts) != AYAHS:
        sys.exit(f"expected {AYAHS} rosettes on the pages, found {sum(counts)}")

    # The running total before each page — the index of the verse its first
    # rosette closes.
    before = []
    total = 0
    for count in counts:
        before.append(total)
        total += count

    page_of = {}
    for page, (start, count) in enumerate(zip(before, counts), start=1):
        for i in range(start, start + count):
            page_of[order[i]] = page

    # Anchors: the 114 surah openings and the 30 juz openings, both of which are
    # fixed and widely published for this mushaf. A regeneration that shifted
    # the mapping by even one verse would fail here rather than quietly send
    # readers to the wrong page.
    failures = []
    index = json.loads((QURAN / "surahs.json").read_text("utf-8"))
    for surah in index:
        found = page_of[(surah["number"], 1)]
        if found != surah["page"]:
            failures.append(
                f"surah {surah['number']} opens on p{surah['page']}, index says p{found}")
    for surah, ayah, page in JUZ_STARTS:
        found = page_of[(surah, ayah)]
        if found != page:
            failures.append(f"juz start {surah}:{ayah} is on p{page}, index says p{found}")
    if failures:
        sys.exit("\n".join(["anchor check failed:"] + failures))

    out = MUSHAF / "ayah_index.json"
    out.write_text(
        json.dumps({"total": total, "before": before}, separators=(",", ":")),
        encoding="utf-8",
    )

    # How far the surah files' own page field strays from the print, for the
    # record — this is the error the index exists to correct.
    declared = {}
    for surah in range(1, 115):
        data = json.loads((QURAN / f"surah_{surah}.json").read_text("utf-8"))
        for ayah in data["ayahs"]:
            declared[(surah, ayah["n"])] = ayah["page"]
    strays = sum(1 for key, page in page_of.items() if declared[key] != page)

    print(f"wrote {out.relative_to(ROOT)}: {PAGES} pages, {total} verses")
    print(f"anchors: 114 surah openings + {len(JUZ_STARTS) + 1} juz openings all agree")
    print(f"verses whose surah-file page field disagrees with the print: {strays}")


if __name__ == "__main__":
    main()
