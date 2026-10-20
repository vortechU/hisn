---
name: Hisn
description: A daily-adhkar companion set as a quiet, daylit prayer hall, with one mihrab per screen, calm rows on plaster, and brass lamplight for what is done.
colors:
  qibla-ink: "#0F3D4C"
  qibla-ink-night: "#86C5CC"
  mihrab-night: "#1B4B59"
  on-field: "#F4F1E8"
  on-field-quiet: "#F4F1E8E0"
  field-passed: "#F4F1E8CC"
  field-rule: "#F4F1E829"
  field-band: "#F4F1E81F"
  lamp-brass: "#93681D"
  lamp-brass-night: "#D4A85A"
  lamp-on-field: "#D7C8AB"
  lamp-on-field-night: "#EADBBD"
  lamp-panel: "#F0ECE3"
  lamp-panel-night: "#2F413E"
  lamp-text: "#6E511D"
  lamp-text-night: "#DABA81"
  plaster: "#EBECE7"
  stone: "#F8F8F5"
  hall-night: "#0D262F"
  stone-night: "#15313A"
  ink: "#161A1C"
  ink-muted: "#5E6161"
  ink-night: "#E9E5DB"
  ink-muted-night: "#A1A8A4"
  on-rubric: "#F7F5EF"
  on-rubric-night: "#111416"
  accent-tint: "#E1E5E4"
  accent-tint-night: "#274951"
  well: "#DFE3E2"
  well-night: "#2A4C54"
  nav-indicator: "#CFD5D3"
  nav-indicator-night: "#284951"
  rule: "#161A1C14"
  rule-night: "#E9E5DB17"
  rule-strong: "#C6C7C5"
  rule-strong-night: "#516367"
  error: "#A3322A"
  error-night: "#EE9A8E"
  plaster-base: "#F2F1EC"
  sheet-base: "#FBFAF7"
  night-base: "#0B0F11"
typography:
  numeral-tasbih:
    fontFamily: "Readex Pro, Amiri, sans-serif"
    fontSize: "68px"
    fontWeight: 500
    lineHeight: 1.05
    letterSpacing: "-1.36px"
  numeral-countdown:
    fontFamily: "Readex Pro, Amiri, sans-serif"
    fontSize: "52px"
    fontWeight: 500
    lineHeight: 1.05
    letterSpacing: "-1.04px"
  display-sm:
    fontFamily: "Readex Pro, Amiri, sans-serif"
    fontSize: "34px"
    fontWeight: 500
    lineHeight: 1.06
    letterSpacing: "-0.6px"
  headline-md:
    fontFamily: "Readex Pro, Amiri, sans-serif"
    fontSize: "25px"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "-0.3px"
  headline-sm:
    fontFamily: "Readex Pro, Amiri, sans-serif"
    fontSize: "21px"
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: "-0.2px"
  title-lg:
    fontFamily: "Readex Pro, Amiri, sans-serif"
    fontSize: "21px"
    fontWeight: 600
    lineHeight: 1.25
    letterSpacing: "-0.2px"
  title-md:
    fontFamily: "Readex Pro, Amiri, sans-serif"
    fontSize: "17px"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "-0.1px"
  title-sm:
    fontFamily: "Readex Pro, Amiri, sans-serif"
    fontSize: "15.5px"
    fontWeight: 500
    lineHeight: 1.32
    letterSpacing: "0"
  body-lg:
    fontFamily: "Readex Pro, Amiri, sans-serif"
    fontSize: "16.5px"
    fontWeight: 400
    lineHeight: 1.6
    letterSpacing: "0"
  body-md:
    fontFamily: "Readex Pro, Amiri, sans-serif"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "0"
  body-sm:
    fontFamily: "Readex Pro, Amiri, sans-serif"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.45
    letterSpacing: "0"
  label-lg:
    fontFamily: "Readex Pro, Amiri, sans-serif"
    fontSize: "14.5px"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "0.1px"
  label-md:
    fontFamily: "Readex Pro, Amiri, sans-serif"
    fontSize: "13px"
    fontWeight: 500
    lineHeight: 1.3
    letterSpacing: "0.1px"
  label-sm:
    fontFamily: "Readex Pro, Amiri, sans-serif"
    fontSize: "12px"
    fontWeight: 500
    lineHeight: 1.3
    letterSpacing: "0.2px"
  sacred-block:
    fontFamily: "Amiri, Scheherazade New, Noto Naskh Arabic, serif"
    fontSize: "26px"
    fontWeight: 400
    lineHeight: 1.9
    letterSpacing: "0"
  sacred-field:
    fontFamily: "Amiri, Scheherazade New, Noto Naskh Arabic, serif"
    fontSize: "28px"
    fontWeight: 400
    lineHeight: 1.45
    letterSpacing: "0"
  sacred-name:
    fontFamily: "Amiri, Scheherazade New, Noto Naskh Arabic, serif"
    fontSize: "18px"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "0"
rounded:
  small: "10px"
  note: "14px"
  input: "16px"
  panel-row: "16px"
  panel: "22px"
  sheet: "28px"
  button: "100px"
spacing:
  gap-xs: "4px"
  gap-sm: "8px"
  gap: "10px"
  section-below: "12px"
  row-y: "14px"
  row-x: "16px"
  panel: "18px"
  margin: "20px"
  section-above: "30px"
  scroll-end: "32px"
  separator-indent: "72px"
components:
  mihrab-field:
    backgroundColor: "{colors.qibla-ink}"
    textColor: "{colors.on-field}"
    rounded: "{rounded.panel}"
    padding: "18px 20px 20px 20px"
  mihrab-field-night:
    backgroundColor: "{colors.mihrab-night}"
    textColor: "{colors.on-field}"
    rounded: "{rounded.panel}"
    padding: "18px 20px 20px 20px"
  button-primary:
    backgroundColor: "{colors.qibla-ink}"
    textColor: "{colors.on-rubric}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.button}"
    padding: "13px 22px"
    height: "48px"
  button-tonal:
    backgroundColor: "{colors.accent-tint}"
    textColor: "{colors.qibla-ink}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.button}"
    padding: "13px 22px"
    height: "48px"
  button-tonal-night:
    backgroundColor: "{colors.accent-tint-night}"
    textColor: "{colors.ink-night}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.button}"
    padding: "13px 22px"
    height: "48px"
  button-on-field:
    backgroundColor: "{colors.on-field}"
    textColor: "{colors.qibla-ink}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.button}"
    padding: "13px 22px"
    height: "48px"
  button-text:
    textColor: "{colors.qibla-ink}"
    typography: "{typography.label-lg}"
    rounded: "{rounded.button}"
    padding: "10px 14px"
    height: "44px"
  search-pill:
    backgroundColor: "{colors.stone}"
    textColor: "{colors.ink-muted}"
    typography: "{typography.body-md}"
    rounded: "{rounded.button}"
    padding: "0 18px"
    height: "52px"
  input:
    backgroundColor: "{colors.stone}"
    textColor: "{colors.ink}"
    typography: "{typography.body-md}"
    rounded: "{rounded.input}"
    padding: "15px 18px"
  chip:
    backgroundColor: "{colors.stone}"
    textColor: "{colors.ink}"
    typography: "{typography.label-md}"
    rounded: "{rounded.button}"
    padding: "8px 12px"
  chip-selected:
    backgroundColor: "{colors.accent-tint}"
    textColor: "{colors.qibla-ink}"
    typography: "{typography.label-md}"
    rounded: "{rounded.button}"
    padding: "8px 12px"
  row-group:
    backgroundColor: "{colors.stone}"
    textColor: "{colors.ink}"
    rounded: "{rounded.panel}"
  row:
    textColor: "{colors.ink}"
    typography: "{typography.title-sm}"
    padding: "14px 18px 14px 16px"
  row-done:
    backgroundColor: "{colors.lamp-panel}"
    textColor: "{colors.ink}"
    typography: "{typography.title-sm}"
    rounded: "{rounded.panel}"
    padding: "14px 18px 14px 16px"
  icon-well:
    backgroundColor: "{colors.well}"
    textColor: "{colors.qibla-ink}"
    rounded: "{rounded.button}"
    size: "40px"
  icon-well-done:
    backgroundColor: "{colors.lamp-brass}"
    textColor: "{colors.stone}"
    rounded: "{rounded.button}"
    size: "40px"
  cartouche:
    backgroundColor: "{colors.well}"
    textColor: "{colors.qibla-ink}"
    typography: "{typography.label-md}"
    rounded: "{rounded.button}"
    padding: "5px 11px"
  cartouche-done:
    backgroundColor: "{colors.lamp-brass}"
    textColor: "{colors.stone}"
    typography: "{typography.label-md}"
    rounded: "{rounded.button}"
    padding: "5px 11px"
  dua-card:
    backgroundColor: "{colors.stone}"
    textColor: "{colors.ink}"
    rounded: "{rounded.panel}"
    padding: "16px 12px 10px 20px"
  dua-card-done:
    backgroundColor: "{colors.lamp-panel}"
    textColor: "{colors.ink}"
    rounded: "{rounded.panel}"
    padding: "16px 12px 10px 20px"
  timetable-row:
    textColor: "{colors.ink}"
    typography: "{typography.title-sm}"
    rounded: "{rounded.panel-row}"
    padding: "12px 14px"
  timetable-row-next:
    backgroundColor: "{colors.qibla-ink}"
    textColor: "{colors.on-field}"
    typography: "{typography.title-sm}"
    rounded: "{rounded.panel-row}"
    padding: "12px 14px"
  timetable-row-in-field:
    textColor: "{colors.on-field}"
    typography: "{typography.title-sm}"
    rounded: "{rounded.panel-row}"
    padding: "12px 14px"
  timetable-row-next-in-field:
    backgroundColor: "{colors.field-band}"
    textColor: "{colors.on-field}"
    typography: "{typography.title-sm}"
    rounded: "{rounded.panel-row}"
    padding: "12px 14px"
  app-bar:
    backgroundColor: "{colors.plaster}"
    textColor: "{colors.ink}"
    typography: "{typography.title-lg}"
  nav-bar:
    backgroundColor: "{colors.plaster}"
    textColor: "{colors.ink-muted}"
    typography: "{typography.label-md}"
    height: "74px"
  nav-indicator:
    backgroundColor: "{colors.nav-indicator}"
    textColor: "{colors.qibla-ink}"
    rounded: "{rounded.button}"
  bottom-sheet:
    backgroundColor: "{colors.stone}"
    textColor: "{colors.ink}"
    rounded: "{rounded.sheet}"
  dialog:
    backgroundColor: "{colors.stone}"
    textColor: "{colors.ink}"
    typography: "{typography.headline-sm}"
    rounded: "{rounded.sheet}"
  snackbar:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.stone}"
    typography: "{typography.body-md}"
    rounded: "{rounded.note}"
---

# Design System: Hisn

Sizes are Flutter logical pixels (dp), written as `px` for the format. Hex values are the default **Qibla & Brass** palette; light-mode tokens carry no suffix and dark-mode tokens end in `-night`. Every other palette is the same formulas over four different inputs (see Colors). Source of truth: `lib/theme/app_palette.dart`, `lib/theme/app_theme.dart`, `lib/theme/motion.dart`, `lib/widgets/ornament.dart`, `lib/widgets/prayer_header.dart`.

## Overview

**Creative North Star: "The Prayer Hall"**

Hisn is a quiet, daylit prayer hall. Each screen is built around one mihrab: a single arch-topped field filled with the qibla ink, holding the one thing the screen is about (the next prayer and the adhkar for now, the day's prayer times, the set being read, the place to resume the Quran, the tasbih count). Everything else sits unboxed on plaster in calm rows, like the saff, grouped by a pale stone fill and never by an outline. Night is the same hall after Isha: the ground a deep shade of the accent itself, the mihrab lifted a step toward the lit accent so it still stands out of the dark, and the text in a warm lamplit off-white.

The interface speaks in two voices. Readex Pro carries every piece of apparatus in Latin and in Arabic at four weights, in sentence case, ordered by size and weight alone. The reader's chosen Naskh (Amiri by default) carries the sacred text and the Arabic names, so the text and the machinery around it are never confused. Brass is the lamp, and it is lit only when something is finished.

Density is a one-handed phone at Fajr: one column, 20px margins, 48px-plus touch rows, a counter pushed into the thumb's reach, and a text-size setting that reflows rather than clips. Depth comes from fill and space; the theme's shadow colour is transparent everywhere except the popup menu. Motion is short fades and settles that collapse to nothing under the platform's reduce-motion setting; the one longer beat is a completed tasbih set. The hall refuses the category default (green and gold, a mosque-photo header, a grid of shadowed cards) and the incumbent manuscript it replaced (cream paper, double-ruled frames, tracked capitals everywhere).

**Key Characteristics:**
- One arch-topped mihrab field per screen, in qibla ink, with a faint carved khatam screen under the arch.
- Plaster ground, stone groups told apart by value alone, hairline rules only between rows inside a group.
- One accent per palette, derived neutrals, brass reserved for completion.
- Readex Pro for all chrome, Naskh for sacred text and Arabic names, no capitals or tracked labels.
- Soft graded corners (10 to 28px) and stadium controls; no frames, no drop shadows.
- Full mirroring for Arabic and Urdu, with letter-spacing removed and leading opened.

## Colors

One accent and one completion colour laid over a family of neutrals computed from the accent, the way a mosque interior is one tiled qibla wall in a hall of plaster and stone.

### Primary
- **Qibla Ink** (#0F3D4C): the petrol of the Hisn mark. In light mode it is both the mihrab's fill and the accent drawn on the page (the code's `rubric`): wayfinding icons in their wells, interactive labels, the repeat and in-progress tallies, the saved bookmark, the active state, and the next-prayer row when the timetable sits on stone.
- **Qibla Ink, Night** (#86C5CC): the accent lifted until it reads as a foreground on the night ground. Never a fill for a large area.
- **Mihrab, Night** (#1B4B59): the mihrab's fill after dark, the accent moved 10% toward its night foreground, a clear step above the hall's ground.
- **On-Field Linen** (#F4F1E8): every mark and word set on the mihrab, in both modes. On the field it also comes in three strengths: **quiet** (#F4F1E8E0, 88%) for secondary lines, **passed** (#F4F1E8CC, 80%) for prayers already gone in the field timetable, and as hairline and band fills (**field rule** #F4F1E829 at 16%, **field band** #F4F1E81F at 12%).

### Tertiary
- **Lamp Brass** (#93681D, night #D4A85A): completion. A dua's count reached, a set finished, a fortified day, a living streak, a full tasbih set. In the ColorScheme it is `tertiary`; tonal buttons and selected chips never take it.
- **Lamp on Field** (#D7C8AB, night #EADBBD): brass mixed 70% of the way toward on-field linen, for completion drawn on the mihrab (a finished set's tally, rule and check). The tasbih mixes 65% instead.
- **Lamp Panel** (#F0ECE3, night #2F413E): brass at 8.5% (13.6% at night) laid over stone, the fill a finished dua card or set row eases into.
- **Lamp Text** (#6E511D, night #DABA81): brass mixed 30% toward ink, for the "Done · n / n" status set on a finished row's lamp panel.

### Neutral
- **Plaster** (#EBECE7): the page, app bar and navigation bar in light mode; the plaster base with a 3% breath of the accent.
- **Stone** (#F8F8F5): a raised group of rows, a card, a field, a sheet; one step lighter than plaster, told apart by value alone.
- **Hall at Night** (#0D262F) and **Stone at Night** (#15313A): the dark ground (halfway from the night base to the accent, a deep navy in the family of the mark's #072C3E) and its raised groups.
- **Ink** (#161A1C, night #E9E5DB): body text. The night ink is warm, never pure white.
- **Muted Ink** (#5E6161, night #A1A8A4): metadata, captions, unselected navigation, hint text, passed prayers on stone. Clears 4.5:1 on ground and stone in both modes on every palette, as the theme requires.
- **On-Accent** (#F7F5EF, night #111416): text on a full accent fill (primary button, badge, switch thumb), whichever of the two inks contrasts more.
- **Accent Tint** (#E1E5E4, night #274951): the accent at 10% (16% at night) over stone; tonal buttons and selected chips.
- **Well** (#DFE3E2, night #2A4C54): the accent at 11% (18% at night) over stone; icon wells and counter pills.
- **Navigation Indicator** (#CFD5D3, night #284951): the accent at 13% (22% at night) over the ground.
- **Rule** (#161A1C14, night #E9E5DB17): the hairline between rows inside a group, and nowhere else by default.
- **Strong Rule** (#C6C7C5, night #516367): the few marks that must hold against the ground (an unselected radio ring).
- **Error** (#A3322A, night #EE9A8E): destructive actions, field errors, and the qibla's magnetic-only warning.
- **Bases** (plaster #F2F1EC, sheet #FBFAF7, night #0B0F11): the fixed inputs every palette's neutrals are derived from.

### Derivation

All mixes are Flutter `Color.lerp` per sRGB channel in floating point, rounded to 8 bits only at the end. `accent`, `accentNight`, `brass` and `brassNight` are the palette's four inputs.

| Token | Light | Dark |
|---|---|---|
| ground (`groundFor`) | lerp(#F2F1EC, accent, 0.03) | lerp(#0B0F11, accent, 0.5) |
| paper / stone (`paperFor`) | lerp(#FBFAF7, accent, 0.012) | lerp(ground, accentNight, 0.07) |
| ink (`inkFor`) | #161A1C | #E9E5DB |
| rubric (`rubricFor`) | accent | accentNight |
| gilt / brass (`giltFor`) | brass | brassNight |
| field (`fieldFor`) | accent | lerp(accent, accentNight, 0.10) |
| onField | #F4F1E8 | #F4F1E8 |
| rule | #161A1C at 8% alpha | #E9E5DB at 9% alpha |
| ink-muted (`onSurfaceVariant`) | lerp(ink, paper, 0.32) | lerp(ink, paper, 0.34) |
| on-rubric (`onPrimary`), on-gilt (`onTertiary`) | whichever of #111416 and #F7F5EF has the higher contrast ratio against the fill | same rule |
| accent-tint (`primaryContainer`, `secondaryContainer`) | lerp(paper, rubric, 0.10) | lerp(paper, rubric, 0.16) |
| on-accent-tint | rubric | ink |
| brass container (`tertiaryContainer`) | lerp(paper, gilt, 0.14) | lerp(paper, gilt, 0.20) |
| rule-strong | lerp(paper, ink, 0.22) | lerp(paper, ink, 0.28) |
| nav indicator | lerp(ground, rubric, 0.13) | lerp(ground, rubric, 0.22) |
| surfaceContainerLow / High / Highest | lerp(ground, paper, 0.5) / lerp(paper, ink, 0.035) / lerp(paper, ink, 0.065) | lerp(ground, paper, 0.5) / lerp(paper, ink, 0.05) / lerp(paper, ink, 0.09) |
| outline | lerp(ink, paper, 0.6) | lerp(ink, paper, 0.6) |
| on-field quiet / passed | onField at 88% / 80% | same |
| field rule / field band | onField at 16% / 12% | same |
| lamp on field | lerp(gilt, onField, 0.7); tasbih 0.65 | same |
| lamp text (done status on the lamp panel) | lerp(gilt, onSurface, 0.3) | same |
| well / pill tint | rubric at 11% | rubric at 18% |
| lamp panel | gilt at 8.5% over paper | gilt at 13.6% over paper |
| switch track, off | lerp(paper, ink, 0.10) | lerp(paper, ink, 0.16) |
| snackbar action | lerp(gilt, paper, 0.3) | lerp(gilt, paper, 0.3) |

### Palettes

Offered in Appearance, in this order; Qibla is the default and the fallback for an unknown id. Derived values below are computed from the formulas above.

| Palette (id, display name) | accent | accentNight | brass | brassNight | ground light / dark | stone light / dark | field dark |
|---|---|---|---|---|---|---|---|
| `qibla`, Qibla & Brass | #0F3D4C | #86C5CC | #93681D | #D4A85A | #EBECE7 / #0D262F | #F8F8F5 / #15313A | #1B4B59 |
| `emerald`, Emerald & Gold | #0C5A4C | #6CCBB4 | #93681D | #D4A85A | #EBECE7 / #0C342F | #F8F8F5 / #123F38 | #166556 |
| `sapphire`, Sapphire & Sky | #1B4B8F | #94B7EE | #93681D | #D4A85A | #ECECE9 / #132D50 | #F8F8F6 / #1C375B | #275698 |
| `amethyst`, Amethyst & Rose | #5C3357 | #CDA2C5 | #93681D | #D4A85A | #EDEBE8 / #342134 | #F9F8F5 / #3E2A3E | #673E62 |
| `rosewood`, Rosewood | #8E2F2E | #E8978D | #93681D | #D4A85A | #EFEBE6 / #4D1F20 | #FAF8F5 / #572727 | #973938 |
| `lagoon`, Lagoon | #0A5552 | #63CFC5 | #A4532F | #E58F69 | #EBECE7 / #0A3232 | #F8F8F5 / #113D3C | #13615E |
| `desert`, Desert | #683E1D | #DDA36C | #8A6A1F | #D0B061 | #EEECE6 / #392717 | #F9F8F4 / #452F1D | #744825 |

The light field is the accent itself in every palette. The home-screen widget reads the same palette through `prayer_widget_service.dart`. Dua cards may additionally take a per-card reading surface from Display settings (sepia: #F3E7CC page, #3E2E1E ink, #6E5C42 muted; night: #15140F page, #E6DECB ink, #A79E88 muted); the accent and brass stay the palette's own on those pages.

### Named Rules
**The Quarantined Ink Rule.** The qibla ink is a full-strength fill only in the mihrab field, the next-prayer row of a timetable set on stone, and a control in its on state (switch track, checkbox, badge, the primary button in a dialog). Everywhere else it is a foreground mark or a tint of 16% or less. It never decorates.

**The Lamp Rule.** Brass means done, and nothing else. It is lit when a dua's count is reached, a set is complete, the day is fortified, a streak is alive, or a tasbih set is full; on the mihrab it is mixed 70% of the way toward on-field linen, and as text on a lamp panel it is deepened 30% toward ink. Progress toward something is drawn in the accent (on the page) or in on-field linen (on the mihrab), never in brass. Brass is never body text.

**The Derived Hall Rule.** Neutrals are computed from the accent, never tuned per palette. A new palette supplies exactly four colours (accent, accentNight, brass, brassNight); the plaster, stone, night ground, mihrab and every tint follow from the formulas.

## Typography

**Interface Font:** Readex Pro (static 400/500/600/700, Latin and Arabic), falling back to the chosen Arabic face. An Urdu interface sets its chrome in Noto Naskh Arabic, because Readex Pro lacks the Urdu letters.
**Sacred Font:** the Naskh chosen in Display settings: Amiri (default), Scheherazade New or Noto Naskh Arabic, always set right-to-left through `ArabicText`.
**Mushaf:** the KFGQPC QCF v4 page fonts keep the Quran pages a facsimile and sit outside this system.

**Character:** a soft, open geometric sans that speaks the same voice in English and Arabic, beside a classical Naskh that is only ever the text itself. The contrast between them is the hierarchy between apparatus and scripture.

### Hierarchy
- **Numerals** (500, 52px countdown and 68px tasbih count, line-height 1.05, tracking -2% of size in left-to-right text): figures that update in place, always on the mihrab. Built on the display style so a localised countdown ("1 س 6 د") still falls back to Arabic.
- **Display** (500, 34px, 1.06, -0.6px): the base the numerals derive from. The theme also defines 56px and 44px display steps, unused today.
- **Headline** (600, 21px, 1.25, -0.2px for dialog titles; 25px, 1.2, -0.3px for the app's name in About). A 30px step exists in the theme, unused today.
- **Title** (600, 21px, 1.25 for app bars, sheet titles, empty-page headings and the resume surah on the Quran mihrab; 600, 17px, 1.3 for section headings, dua titles, card headings and the timetable's "Today"; 500, 15.5px, 1.32 for every list row title, the timetable and the "Next · Isha 7:21 PM" line under the countdown).
- **Body** (400, 16.5px at 1.6 for translations and empty-page text; 15px at 1.5 for prose, hints and the search pill; 13px at 1.45 in muted ink for subtitles, status lines and references).
- **Label** (600, 14.5px, +0.1px for buttons and chips; 500, 13px, +0.1px for navigation labels and the Hijri date; 500, 12px, +0.2px in muted ink for small metadata). Sentence case, always.
- **Sacred block** (Naskh 400, 26px, line-height 1.9, full width, right-aligned): the dua text. Generous leading so harakat never clip.
- **Sacred names** (Naskh, 18px at 1.5 in rows and the timetable; 22 to 23px on the session head and the adhkar-for-now; 28 to 30px for the current prayer and the resume surah): the Arabic name beside a Latin one.

### Named Rules
**The Two Voices Rule.** Readex Pro for everything that is apparatus; Naskh for the sacred text and the Arabic names that echo a Latin title. Never a Naskh button label in a Latin or Arabic interface, never Readex for a dua.

**The Sentence-Case Rule.** Hierarchy is carried by size and weight, never by capitals, tracking or eyebrow labels. Labels are set in sentence case with at most +0.2px of tracking in Latin; display sizes close up slightly instead. A figure's caption follows it on one line ("Next · Isha 7:21 PM", "Continue reading · Juz 1") rather than standing above it.

**The Cursive Rule.** When the interface is right-to-left, every style drops its letter-spacing to 0 and multiplies its line-height by 1.2, and numerals lose their negative tracking, so joined letters stay joined and marks above and below the line never collide.

## Layout

One column on a phone, no breakpoints. Every scrolling surface keeps a 20px page margin. Groups of rows sit on a full-width stone panel inside that margin; a section heading stands 24px in from the screen edge with 30px of air above and 12px below it. Two groups with no heading between them sit 14px apart.

The Adhkar tab has no app bar: the mihrab opens the page 12px below the status bar and fills about half the first viewport (50% on a 1080x2400 phone at default text size). Inside it, from top to bottom: the Hijri date centred under the apex; the countdown, large, with "Next · Isha 7:21 PM" on one line beneath it and the current prayer in Arabic at the trailing side; the day strip; the date and place; then, under a 1px field rule, the adhkar for now, set straight on the field with its progress and a full-width "Read now" button within thumb reach. Below the field: the search pill with the appearance switch beside it, then Tasbih and Saved as a matched pair of tonal buttons, then the sets as rows in three headed groups (Daily, For every situation, Mine), with the Muhassan tally as the first row of the daily group. Other tabs open with a start-aligned app bar on the ground.

The Prayer tab's mihrab holds the day's timetable ("Today" at the start of its header row and the place set at the far end, over the time column, then the five prayers); the Qibla compass stands on the plain ground below it, its heading and location folded into one title and one subtitle line. The Tasbih gathers the phrase and its counter together at the foot of the viewport (the column is at least the viewport's height less 48px, aligned to its end), so the counter sits under the thumb.

A row is 68px tall at default text size: 14px of vertical padding around a 40px icon well. Separators inside a group start 72px in (70px on Home), lined up with the row titles rather than running under the icons. The dua reader stacks cards with 14px between them and 34px of space after the last; long lists end with 32px. A fixed-column timetable keeps a 16px leading column for the "now" mark, the Arabic name in a 72px column and the time in a 96px end-aligned column, so the minutes line up whatever the names' widths. Arabic names beside Latin titles sit in a capped column (118 to 130px) and scale down rather than push the title off; numerals that could overflow scale down inside their box.

The text-size setting (0.9, 1.0, 1.15 or 1.3) sets the text scale inside every dua card and the adhkar player; the system font scale reflows everything else (see Open Issues). Nothing on a counting surface changes width as it fills: the tally pill reserves the width of its widest state.

### Named Rules
**The One Mihrab Rule.** A screen has at most one arched field, and it holds the one thing that screen is for. Home: the next prayer and the adhkar for now. Prayer & Qibla: the day's timetable. A set: its progress. Quran: where to resume. Tasbih: the count. Nothing is nested inside the mihrab as a card of its own; its parts are separated by space and a field rule.

**The Saff Rule.** Everything that is not the mihrab is a calm row in a group on plaster. Only one item on a screen is expanded (the adhkar for now); every other set is a compact row below it.

## Elevation & Depth

The hall is flat. Depth is tonal: plaster ground, stone groups one step lighter, the mihrab as the one dark saturated field, and on the field itself a 12% linen band for the next prayer. The theme sets `shadowColor` and the ColorScheme `shadow` to fully transparent and every app bar, card, sheet, dialog, navigation bar, button and snackbar to elevation 0 with no surface tint. Completion deepens a fill (stone to lamp panel), never a frame or a lift.

### Shadow Vocabulary
- **Popup menu** (elevation 2, shadow colour #00000033): the only shadow the theme draws, so a menu floating over the page separates from it. See Open Issues.

### Named Rules
**The Fill-Not-Frame Rule.** Groups and cards are separated by fill and space, never by an outline. A hairline rule appears only between rows inside one group, inset past the leading marks, or across the mihrab between its parts. State changes move the fill (and ease over 260ms); the geometry never changes, so nothing reflows.

## Shapes

Corners are soft and graded by size, so containers read as one family: 10px for badges, small tiles, list tiles and the adhkar-for-now's ripple; 14px for the virtue note and the snackbar; 16px for editable fields, popup menus and the timetable's row highlight; 22px for groups, cards and the mihrab's feet; 28px for sheets (top corners) and dialogs. Buttons, chips, the search pill, the navigation indicator and counter pills are stadiums. Icon wells, progress rings, the day strip's marks and the completion mark are circles. Tooltips use 8px and checkboxes 5px.

The mihrab is the signature silhouette: straight jambs with 22px feet rising into a low two-centred arch that meets in a gentle point. The arch rises min(60px, 15% of the field's width) by default (about 56px on a 411px-wide phone), is clamped to a third of the field's height, and drops to 30px on the set's session head and 34px on the Quran resume banner. Each half is one cubic curve from the top of the jamb to the apex, with one control point straight above the jamb at 30% of the rise below the apex line and the other 14% of the width from the centre at 26%, so the two halves meet at an angle rather than a round crown.

Under the arch, when the Geometric pattern setting is on (the default), a khatam screen shows faintly: regular octagons of 15px side on a square lattice with squares in the gaps and the {8/3} star inside each octagon, stroked 1px in on-field linen at 7.5%, fading out over the rise plus 70px. The set's session head omits it. Surah numbers sit in an eight-point star medallion: two squares at 94% of the radius, one turned 45 degrees, filled with the accent at 11% (22% when filled, both 1.6x at night).

## Components

### Buttons
Quiet and confident: stadiums with no outline at rest and no lift.
- **Shape:** stadium (100px radius), minimum 64 by 48px, label in the 14.5px/600 label style.
- **Primary (filled):** qibla ink fill, on-accent text, 13px by 22px padding. Used chiefly for the confirming action in dialogs.
- **Tonal:** accent-tint fill with qibla-ink text (ink text at night), optionally with a 20px leading icon. The ways in on Home (Tasbih, Saved) and secondary starts (the after-prayer tasbih).
- **On-field:** on-field linen fill with qibla-ink text: the "Read now" button on the Home mihrab, the screen's primary action.
- **Text:** qibla-ink label, 10px by 14px padding, minimum 48 by 44px.
- **Outlined:** qibla-ink label with a 35% qibla-ink edge; exists in the theme for secondary choices on secondary screens (see Open Issues).
- **Press:** Material ink ripple; icon buttons highlight with the accent at 10%.

### Chips
- **Style:** stone fill, no border, stadium, 12px by 8px padding, no checkmark, label in the 13px label style in ink.
- **State:** selected takes the accent-tint fill. The tasbih's phrase selector, a horizontal row of choice chips with 8px gaps, sets its labels at 14.5px/600: qibla ink when selected, muted ink otherwise.

### Cards / Containers
- **Corner Style:** 22px.
- **Background:** stone (`JadwalFrame`, `RowGroup`, Material cards); rows inside a group are transparent on the group's fill. A finished item eases to the lamp panel over 260ms.
- **Shadow Strategy:** none (see Elevation & Depth).
- **Border:** none. Hairline rules only between rows of one group.
- **Internal Padding:** 18px for a standalone panel; 14px vertical by 16px leading and 18px trailing for a row; 16, 20, 10 and 12px (top, leading, bottom, trailing) for a dua card.

### Inputs / Fields
- **Style:** stone fill, no border at rest, 16px radius, 15px by 18px padding, hint in muted ink at 15px. The Quran search is a stadium variant.
- **Focus:** a 1.5px qibla-ink edge appears; cursor and selection handles in qibla ink, selection at 22%.
- **Error / Disabled:** a 1px error edge (1.5px focused) in the error colour.

### Navigation
- **Bottom bar:** four destinations (Adhkar, Quran, Prayer, Settings) on the plaster ground with no top edge, 74px tall, labels always shown in the 13px label style. The selected destination sits in a stadium indicator (accent at 13% over the ground, 22% at night) with a filled qibla-ink icon and an ink label at 600; the rest are outlined icons and labels in muted ink at 500.
- **App bar:** plaster ground, no elevation or scroll-under tint, start-aligned title at 21px/600 with 20px title spacing, ink icons at 24px (22px for actions).
- **Mirroring:** chevrons and arrows flip in right-to-left interfaces.

### Mihrab Field
The niche each screen is built around (`MihrabField`). Filled with the field colour with content in on-field linen; padding 20px at the sides and 18 to 20px below, plus the arch's rise above (the Prayer tab tightens the sides to 8px so its timetable rows reach the jambs). Secondary text on it uses the 88% quiet linen; progress rules on it run on-field linen over a track of the same at 18%; parts are divided by a 1px field rule. A tappable field takes an ink ripple clipped to the arch. `MihrabField` also has a `soft` variant (stone fill, accent marks) that no screen uses now.

### Adhkar for Now
The one expanded entry, at the foot of the Home mihrab and set straight on the field under a 1px field rule: the set's Arabic name in Naskh at 23px, its Latin name at 17px/600, a one-line quiet subtitle, a 4px progress rule in on-field linen with an isolated "1 / 20" tally, and the full-width on-field "Read now" button. When the set is finished the rule, a check and the tally take the lamp on field. A headphone action appears beside the title only when the set has recorded audio. The whole block is one tap target with a 10px-radius ripple.

### Day Strip
The day drawn as an 18px line inside the mihrab: each prayer a 4.5px dot at its true clock position across the span from 50 minutes before Fajr to 50 minutes after Isha. The rail is on-field linen at 22%, the elapsed part at 60%; passed prayers are solid, upcoming ones at 45%, the next prayer an open linen ring (14px across, its centre hollowed in the field colour), and now a 14px upright bar 2.5px wide. The strip runs right to left in right-to-left interfaces and announces every prayer and time to screen readers.

### Prayer Timetable
Fixed-column rows (16px leading mark column, the name at 15.5px, the Arabic name in a 72px column omitted in the Arabic interface, the time in a 96px end-aligned column), each 12px by 14px with a 16px-radius highlight. Four states: **passed** recedes; **now** is full strength at 600 with a 7px dot in the leading column; **next** is lifted at 600; **later** is full strength at the regular weights (500 for the name, 400 for the time).
- **On stone** (the Home schedule sheet): a stone panel (22px, 6px inner padding); passed in muted ink, now and later in ink, the now dot in qibla ink, and the next row filled with the field colour with on-field text.
- **In the field** (the Prayer tab's mihrab): no panel; everything in on-field linen, passed at 80%, the now dot in linen, and the next row on a 12% linen band.

### Rows (Category, Settings, Muhassan)
A 40px icon well (the accent at 11% with a 20px outlined icon in the accent, for every category alike), 14 to 16px gap, the title at 15.5px and a status or subtitle at 13px, a trailing Arabic name in muted Naskh (category rows) or a 20px chevron (settings, Muhassan). A started set shows its tally in qibla ink at 500 beside a 56px, 3px progress rule; a finished set fills the well with brass and a check in stone, warms the row to the lamp panel and reads "Done · n / n" in lamp text. The Muhassan row leads with a 40px progress ring in the accent (brass once the day is fortified) and carries the streak as a brass pill.

### Dua Card
A stone panel in reading order: the title at 17px/600 (Naskh in right-to-left interfaces) with the tally pill (or, outside counting mode, a "×N" repeat pill in the accent) at the trailing end; the Arabic block; transliteration at 15px in muted ink; the translation at 16.5px; a virtue note (see Open Issues); then the reference at 13px and 44px icon actions (save, which turns qibla ink when saved; copy; share; plus edit and delete for the user's own duas). In counting mode the whole card is the tap target; reaching the count fills the pill with brass and eases the card to the lamp panel. In the Arabic interface transliteration and translation drop out.

### Cartouche (counter pill)
A stadium pill (5px by 11px, 9px leading with an optional 14px icon) with its label at 12.5px/600: the accent at 11% (18% at night) for a count or repeat number, its label the pill's colour mixed 30% toward the body ink (#11333E on Qibla; brass pills #6E511D) so it clears 4.5:1 on every palette, and solid brass with a stone label for a finished count. Used for the dua tally, the repeat count and the streak.

### Progress Ring and Rule
- **Ring** (`ProgressRosette`): a stroked arc from twelve o'clock with a round cap, stroke max(3px, 7.5% of the radius), track at 16% of its colour. With beads (`lobes` above 0, only on the tasbih: 11 beads around a 244px ring) each bead fills as the count passes it. On the tasbih the arc and beads are on-field linen at 90% until the set is full, then the lamp; each completed set adds a 9px lamp bead to the tally beneath (up to eight, then a "+n" numeral).
- **Rule** (`ProgressRule`): a 4px rounded bar (3px in rows) filling from the leading edge over a 15% track.
- Both ease to a new value over 260ms.

### Section Mark, Empty Page, Surfaces
- **Section mark:** a 17px/600 heading in sentence case with an optional trailing widget; no rule, no capitals.
- **Empty page:** a 72px icon well, a 21px heading, one 16.5px line of muted explanation, an optional action, centred with 36px padding.
- **Sheets and dialogs:** stone, elevation 0; sheets have a 28px top radius and a drag handle (stone toward ink at 20%); dialogs have a 28px radius and 21px titles.
- **Snackbar and tooltip:** ink fill with stone text; the snackbar floats with a 14px radius and a brass-tinted action, the tooltip has an 8px radius.

### Motion
Durations come from `Motion`: 120ms for state inside a control (a counter ticking, a chip selecting), 260ms for fills, rings and rules settling, 420ms for the one flourish, a completed tasbih set. Page transitions fade with a 4% horizontal settle, easing out cubic and in cubic on return; nothing scales or bounces between pages. The tasbih numeral rolls (the new figure rises 34% as the old one sinks, 120ms) and the ring swells 3.5% on each tap and 9% on a completed set. With the platform's reduce-motion setting every duration becomes zero. Haptics accompany counting: a selection click per dua tap and a medium impact on reaching its count; a light impact per tasbih bead and a heavy one per set.

## Do's and Don'ts

### Do:
- **Do** give a screen at most one `MihrabField`, filled with the field colour, and put the screen's primary content and action straight on it, divided by space and field rules.
- **Do** group rows on a stone `RowGroup` (22px radius) inside the 20px page margin, with hairline rules only between rows, inset 72px.
- **Do** take every neutral from the palette's derivation functions (`groundFor`, `paperFor`, `fieldFor`, `ruleFor`) or the ManuscriptTheme tokens; never hard-code a palette hex in a widget.
- **Do** keep brass for completion: the finished dua, the finished set, the fortified day, the streak, the full tasbih set.
- **Do** draw progress in the accent on the page and in on-field linen on the mihrab.
- **Do** set sacred text and Arabic names with `ArabicText` in the reader's chosen Naskh, and everything else in the theme's Readex Pro styles.
- **Do** write labels and headings in sentence case, order them by size and weight, and put a figure's caption on the line after it.
- **Do** use directional insets and alignments, wrap numeric tallies in a left-to-right isolate (U+2066 before, U+2069 after) so "1 / 20" keeps its order, mirror chevrons and arrows, and drop letter-spacing in right-to-left interfaces.
- **Do** take animation durations from `Motion` so reduce-motion stops them, and change fills rather than geometry when state changes.

### Don't:
- **Don't** add a second arched or field-filled hero to a screen, nest a card inside the mihrab, or fill a large area with the accent outside it.
- **Don't** outline a group, card or panel; separate with fill and space.
- **Don't** add drop shadows or elevation to cards, sheets, dialogs, bars or buttons.
- **Don't** set labels in capitals, add tracking to them, or stack an eyebrow label over a heading or figure; never letter-space Arabic or Urdu.
- **Don't** give each category its own hue; the category icon is wayfinding in the palette's accent, not a colour code.
- **Don't** use brass for progress, selection, decoration, body text, or any state that is not completion.
- **Don't** reproduce the green-and-gold category default, a mosque-photo header, or a grid of shadowed cards.
- **Don't** bring back the manuscript look: cream paper, double-ruled frames, tracked capitals.

## Open Issues

Where the direction contract and the build disagree, this file documents the build. Defects and drift found while documenting are recorded here, not adopted as rules.

**Contract and build disagree**
- **Tabular numerals.** The contract asks for a timetable with tabular numerals. The bundled Readex Pro statics carry no `tnum` feature, so the build aligns times with a fixed 96px end-aligned column instead (only the qibla screen requests tabular figures).
- **No drop shadows.** The contract says none; the theme gives popup menus elevation 2 with a #00000033 shadow.
- **Naskh for sacred text only.** The build also sets the Arabic names of prayers, categories and surahs in Naskh, sets category and dua titles in Naskh in right-to-left interfaces, and sets all Urdu chrome in Noto Naskh Arabic.
- **First viewport.** The contract specifies the Home mihrab at about 45% of the viewport; the build's field is about 50% at default text size, and its primary action reads "Read now · N duas" rather than "Continue".

**Drift and defects not adopted**
- **Brass outside completion.** Brass still appears for things that are not completion: the virtue note on dua cards (a 9% brass tint, 14% at night, with a brass sparkle), the filled "Today" pill on the weekly schedule, selection marks in the location picker and in Display and Backup settings, the qibla dial's optional "gold" tone, the feature-tour spotlight, onboarding's hero and granted states, recommended fasts on the Sunnah calendar, the verse-row star, the share card, and the rosette in About.
- **Text scale.** The dua card and the adhkar player replace the system font scale with the app's text-size step instead of multiplying it, so a reader with a large system font scale gets 1.0 inside the cards unless they also raise the in-app setting.
- **Outlines off the core screens.** The weekly schedule outlines today's panel, the streak calendar outlines its cells, the Appearance theme picker uses Material's default outlined segmented button (no `segmentedButtonTheme` is set), the outlined button theme is still used on onboarding, backup, notifications, prayer silence and the share sheet, and the share card draws a 2px frame. The palette swatch's 2px selection ring is a selected state rather than a frame.
- **Capitals.** The home-screen widget uppercases its "recommended now" label (`prayer_widget_service.dart`).
- **Leftover fonts.** Crimson Pro and Karla remain bundled in `pubspec.yaml` and credited in About because the store-graphics tool (`tool/gen_play_graphics.py`) and test capture helpers load them. No screen uses them; they are not part of this system.
- **Khatam geometry.** `_KhatamPainter` draws each gap's square with a 45-degree twist, but the gap between four octagons on this lattice is a diamond (vertices on the axes, twist 0), so the painted squares cross the octagons' diagonal sides instead of tiling with them. At 7.5% opacity it reads as texture, but it is not the "true octagon-and-square tessellation" its comment describes.
- **Legacy names.** Several types keep the names of the manuscript system they replaced, with new behaviour: `ManuscriptTheme` (with `rubric` for the accent and `gilt` for brass), `JadwalFrame` (a soft panel), `Rosette` (`lobes` no longer draws), `Numeral.serif` (picks the display style), `AppTheme.serif` (an alias of Readex Pro), `UnwanBand`, `RuleDivider.ornament`, `CategoryTone` (its rubric/gilt tone no longer changes the colour), and `MihrabField.soft` (unused). `ProgressRosette`, `ProgressRule` and `Rosette` default to brass when no colour is passed.
