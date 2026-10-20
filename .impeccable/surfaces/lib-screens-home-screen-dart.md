---
version: 1
slug: "lib-screens-home-screen-dart"
primary_target: "lib/screens/home_screen.dart"
related_targets: ["lib/theme/app_theme.dart","lib/screens/category_duas_screen.dart","lib/screens/quran_screen.dart","lib/screens/prayer_qibla_screen.dart","lib/screens/settings_screen.dart","lib/screens/tasbih_screen.dart"]
---

# App shell and core screens

Scope: the whole app's visual system (theme, shared components) plus Home (Adhkar tab), the dua reader (category screen), Quran list, Prayer & Qibla, Settings, Tasbih. Other screens inherit the components. Mode: Operate.

Audience and job: Muslims at Fajr/Maghrib reading and counting the daily adhkar; quick prayer-time glances; Quran reading. One-handed, often low light.

Constraints: four languages incl. Arabic/Urdu RTL; text-size and font-scale reflow; six palette choices may be replaced; mushaf page stays a facsimile; 495+ tests must keep passing (update goldens/expectations that encode the old look only).

## Direction contract

THESIS: Hisn as a quiet, daylit prayer hall. Each screen owns exactly one mihrab: a single arch-topped focal field in qibla ink. Everything else sits unboxed on plaster in calm rows like the saff. Refuses the category default (green + gold, mosque-photo header, grid of shadowed cards) and the incumbent manuscript (cream paper, double-ruled frames, tracked caps everywhere).

OWN-WORLD: Plaster ground, pale stone for grouped rows (fill, never a border), qibla ink (deep petrol from the logo) as the only accent, lamp brass reserved for completion. Night is the hall after Isha: logo-navy ground, lamp-warm ink. Readex Pro carries all chrome in Latin and Arabic; Naskh (Amiri etc.) carries sacred text only. Soft 20–28dp corners, no hairline frames, no drop shadows. Recognisable with the content removed: one arch, rows, one dark-ink field.

STORY: The visitor sees which prayer it is, how long until the next, and which adhkar to read now, with its progress, in one glance; taps once to read; counts with a thumb; leaves.

FIRST VIEWPORT: Home: top ~45% is the mihrab field: the arch shape in qibla ink, Hijri date small at the top, the current prayer in Arabic and Latin, the next prayer with its countdown large, the day strip with the five prayers at their true clock positions and a "now" marker. The bottom of the field holds the adhkar-for-now row: name, progress ring, and a filled "Continue" button (the primary action, inside thumb reach). Below: search, then the Morning/Evening progress folded into the category rows; categories as compact stone rows.

FORM: Prayer Hall (contemporary mosque interior), position 6 on the ordered grounded list; seed key 3cff55b7. Raises: fixed-column timetable with tabular numerals and passed/now/next row states (split-flap); one owner per screen (Saville); the adhkar-for-now is the one expanded item (streaming wall); accent quarantined to the focal field and active state (lexicon); the day strip draws prayers at true clock positions (labanotation).

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
