# Hisn — Dua & Adhkar companion

A Flutter mobile app for the duas Muslims recite through the day, with a built-in
**Tasbih** (dhikr counter). This is an early prototype: the structure is in place,
the content is authentic but intentionally small, and it's built to grow.

## Features (prototype)

- **Prayer-time header** — live clock, current prayer, and a countdown to the next
  adhan, with a tap-to-open full daily schedule. Uses GPS (falls back to Makkah) and
  the Umm al-Qura calculation method by default.
- **Prayer reminders** — opt-in local notifications at each prayer time, with a master
  switch and per-prayer toggles, and an optional per-prayer iqāmah delay so the
  reminder fires a few minutes after adhan (matching a mosque's fixed gap) instead
  of at adhan time — the adhan audio itself always plays right on time. Re-scheduled
  (a rolling few-day window) on every launch and whenever the prayer settings change.
- **Settings** — change the location (device GPS or a built-in city), the calculation
  method, the Asr/madhab rule, and notification preferences from inside the app; all
  choices persist.
- **Recommended now** — a time-aware suggestion at the top of the home screen that points
  to the most relevant adhkar for the current part of the day (based on the current prayer
  period: Fajr/Dhuhr → Morning, Asr/Maghrib → Evening, Isha → Before Sleep).
- **Sunnah fasts & occasions** — today's Hijri date with how fasting stands on it,
  then the notable days ahead: Mondays and Thursdays, the white days, ʿĀshūrāʾ and
  Tāsūʿāʾ, the ten of Dhul Hijjah and the Day of ʿArafah, the six of Shawwāl, and
  the occasions of the Islamic year. Each fast is shown with its reference.
  Days on which fasting is **forbidden** — the two Eids and the days of Tashrīq —
  are marked as such and never suggested, even when a Monday or a white day falls
  on one. Opt-in reminders arrive at Maghrib the evening before. Because the
  calculated (Umm al-Qura) date can run a day either side of a local sighting,
  it can be nudged ±2 days to match your community.
- **Search** — full-text search across every dua (title, transliteration, translation,
  source, and Arabic).
- **Qibla compass** — a live compass pointing to the Ka'bah using the device magnetometer
  and the Qibla bearing for the current location (needs a device with a magnetometer).
  The heading is corrected from magnetic to **true** north with the World Magnetic Model,
  and every reading is checked before it is shown: a phone that is tilted too far, whose
  magnetometer is uncalibrated, or that is sitting near metal gets told what is wrong
  instead of a confident needle pointing the wrong way.
- **Display options** — adjustable text size and toggles to show/hide the transliteration
  and translation lines (e.g. for Arabic-only reading).
- **Adhkar library** — duas grouped into categories (Morning, Evening, After Prayer,
  Before Sleep, Upon Waking, Everyday Life). Each dua shows Arabic, transliteration,
  translation, repetition count, source reference, and (where relevant) its virtue.
- **Read & count** — inside a category, tap a dua to count down its repetitions (×3, ×7,
  ×100…); a progress bar tracks completion across the whole set, with haptics on each tap
  and on finishing a dua. Progress is per-session.
- **Tasbih counter** — tap-anywhere counter with presets (SubhanAllah, Alhamdulillah,
  Allahu Akbar, Tahlil, Istighfar, Salawat…), an animated progress ring, set tracking,
  and haptic feedback. Counts persist between launches.
- **Bookmarks** — save any dua to the *Saved* tab for quick access.
- **Share** — send a dua or a verse out as a card set in the app's own hand, or as
  plain text. The card is previewed before it goes, at a fixed size that ignores the
  reader's text-size setting so the image comes out the same everywhere. **The source
  is on the card and in the accompanying message** — a passage that leaves without its
  reference is the thing this app exists not to produce.
- **Mushaf reader** — the Madani Mushaf page by page in the King Fahd (QCF v4) page
  fonts, swiped right-to-left like the printed copy, with a go-to-verse jump and
  pinch-to-fullscreen. The page keeps its own proportions at any orientation:
  in landscape it is letterboxed rather than stretched, so the lines stay justified.
- **Verses on a page** — the reader lists the verses printed on the page in view as
  text, each with its citation, so a particular āyah can be read, copied, or saved.
  Saved verses are kept apart from saved pages: one records an āyah worth returning
  to, the other records where reading stopped.
- **Verse meanings** — each verse carries its meaning in the interface language:
  *The Noble Qur'an* (Hilali & Khan) in English, the Kementerian Agama rendering in
  Indonesian, both from the [Tanzil Project](https://tanzil.net). An Arabic interface
  shows none — the verse above it is already Arabic. The mushaf page itself stays a
  facsimile; the meanings live in the verse list beside it, never interleaved into
  the glyph page. **The translator travels with the meaning**, onto the share card
  and into the shared text, on the same principle the citation does.
  > These translations are licensed for **non-commercial use only**, which binds the
  > whole app for as long as it ships them. See [TERMS.md](TERMS.md) §6.
- **Backup & restore** — writes everything the app knows (streak and history, saved
  duas, your own duas, Quran bookmarks, and all settings) to a single readable JSON
  file, handed to the system share sheet so it can go to Drive, Files, or yourself.
  Restoring reads one back, shows what is in it, and lets you take either the whole
  snapshot or only the progress — keeping this phone's location, reminders and
  language. Nothing leaves the device unless you send it. A restore is all or
  nothing: the previous state is journalled first, so a failed write rolls back,
  and a restore interrupted by the app being killed is undone at the next launch.
- **Offline-first** — all content and the Amiri Arabic font are bundled; no network needed.
- Light/dark theme that follows the system.

## Project structure

```
lib/
  main.dart                 App entry; loads data + prefs, then runs DuaApp
  app.dart                  Providers (repository, favorites, tasbih) + MaterialApp
  models/                   Dua, DuaCategory, Dhikr (plain data classes)
  data/dua_repository.dart  Loads & queries the JSON content
  services/                 FavoritesService, TasbihController (ChangeNotifier + prefs)
  theme/                    Palette, ThemeData, per-category icon/colour
  screens/                  Home (nav), Adhkar grid, category list, Tasbih, Saved
  widgets/                  ArabicText, CategoryCard, DuaCard
assets/
  data/duas.json            The dua content  ← add more here
  data/categories.json      Category definitions
  data/tasbih.json          Tasbih presets
  fonts/Amiri-*.ttf         Bundled Arabic font
```

**To add content**, edit the JSON in `assets/data/` — no Dart changes needed. The UI
reads everything through `DuaRepository`.

## Architecture notes

- **State**: `provider` with `ChangeNotifier`. Kept deliberately light for a prototype.
- **Persistence**: `shared_preferences` for bookmarks and Tasbih counts.
- **Content as data**: duas live in JSON, not Dart, so the catalogue can grow (or move
  to a database / remote source) without touching the UI.
- **Prayer times**: the `adhan` package computes times from coordinates; `geolocator`
  supplies the location (permissions are declared in the Android manifest and iOS
  Info.plist). Location mode, method, and madhab are user-configurable in Settings and
  persisted; the seed defaults live in `lib/services/prayer_service.dart`, and the city
  list / method labels in `lib/services/prayer_settings.dart`.
- **Notifications**: `flutter_local_notifications` + `timezone` schedule reminders
  (`lib/services/notification_service.dart`). Because local notifications need concrete
  times, the service keeps a rolling ~3-day window and re-schedules on launch / when
  prayer settings change — no background work needed. Android requires core-library
  desugaring (set in `android/app/build.gradle.kts`) plus the POST_NOTIFICATIONS /
  exact-alarm permissions and FLN receivers in the manifest. Reminders are **off by
  default** (opt-in). Actual delivery can only be tested on a real device/emulator.

## Running

```bash
flutter pub get
flutter run            # on a connected Android/iOS device or emulator
```

The project also has web enabled for quick previews (`flutter run -d chrome`), but it's
designed as a mobile app.

## Content & authenticity

Duas are sourced from the Qur'an and well-known hadith collections (Bukhari, Muslim,
Abu Dawud, Tirmidhi, an-Nasa'i), with references shown on each card. Before release,
the Arabic text and references should be reviewed by a qualified person.

The same applies to the calendar. The short lines describing each fast's virtue are
renderings of well-known hadith, not quotations, and carry their collection — they
need the same review. Occasions whose date is **not** authentically established are
deliberately absent (the Mawlid on 12 Rabiʿ al-Awwal, the Isrāʾ and Miʿrāj on
27 Rajab, mid-Shaʿbān): the app would rather omit a date than assert one. The
fasting rulings encoded in `lib/models/sunnah_day.dart` — in particular which days
fasting is forbidden on — should be checked by a qualified person too, since the
app acts on them by sending reminders.
