# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

Flutter, shipped to Google Play (application id `com.vortech.hisn`). An `ios/` runner exists but Play is the release target. One Material design language across both.

## Users

Muslims who keep the daily remembrances. The confirmed main uses, in order:

1. **Morning and evening adhkar.** Reading and counting the set, often half-awake at Fajr or tired after Maghrib, phone in one hand.
2. **Checking prayer times.** Quick glances at the current prayer, the next one, and the countdown.
3. **Reading Quran** in the Madani mushaf, in longer sittings.

Tasbih counting is a secondary use. Interface languages: English, Arabic, Indonesian, Urdu (Arabic and Urdu are right-to-left).

## Product Purpose

A Fortress-of-the-Muslim style companion: the authentic duas of the day with their sources, a counter for each dua's repetitions, prayer times with reminders and adhan, a Qibla compass, the mushaf with meanings, a Tasbih, and a Sunnah-fast calendar. Success is a user who opens it at Fajr and at Maghrib every day because it is the calmest, quickest way to get through their adhkar.

## Positioning

Every text travels with its reference: source on every dua card, on share cards and shared text; the translator travels with every verse meaning. Disputed dates and gradings are omitted or qualified rather than asserted. Offline-first, no account, no ads, nothing leaves the device unless the user sends it.

## Operating Context

- Fajr and pre-sleep use: low light, often dark mode, one-handed.
- Reading-and-counting loop: tap a dua to count down its repetitions with haptics; daily progress ("Muhassan", the fortified percentage) and a streak.
- Time-aware recommendation of which adhkar to read now, derived from the current prayer period.
- Adhan playback, prayer reminders, a home-screen widget.

## Capabilities and Constraints

- Content is data (JSON in `assets/data/`); the UI must handle long Arabic, long translations, and four languages including two RTL.
- Arabic faces: Amiri (default), Scheherazade New, Noto Naskh Arabic, chosen in Display settings. The mushaf uses KFGQPC QCF v4 page fonts and stays a facsimile.
- User settings that change layout: text size, show/hide transliteration and meaning, light/dark following the system, a palette choice in Appearance.
- Quran meanings (Tanzil) are licensed non-commercial; that binds the whole app.
- 495+ widget/unit tests exist; some golden/screenshot tests.

## Brand Commitments

- Name **Hisn** (حصن) and the existing calligraphic logo on deep navy `#072C3E` (launcher icon, splash).
- On 2026-10-20 the owner declared the rest of the visual identity open: colours, fonts, ornament and palette choices may all be replaced. Brief: "clean, modern, and pleasing to the eye."

## Evidence on Hand

- Real content: duas (en/ar/id/ur), categories, tasbih presets, the full Quran text and four meaning editions, adhkar recitation audio.
- Tester feedback log: `docs/FEEDBACK-2026-10-15.md`.
- Store assets: `play/graphics/`.
- No testimonials, ratings or user counts exist; none may be invented.

## Product Principles

1. The text comes first: Arabic legibility and the reference outrank decoration.
2. Fast at Fajr: the next action (which adhkar now, the next prayer) is visible without scrolling.
3. Calm, never gamified: progress encourages, it does not nag or score.
4. Truthful: omit what is not established; cite what is shown.

## Accessibility & Inclusion

- Text-size setting and system font scale must reflow, not clip.
- Full RTL for Arabic and Urdu; no letter-spacing on Arabic.
- Body text at WCAG AA (4.5:1) on every palette, light and dark.
