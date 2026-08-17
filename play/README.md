# Publishing Hisn on Google Play

Everything Play asks for, written down so a submission is a matter of pasting
rather than inventing. Each file below is one console section; work top to
bottom.

| File | Play Console section |
| --- | --- |
| [store-listing.md](store-listing.md) | Grow → Store presence → **Main store listing** (+ per-language listings) |
| [graphics.md](graphics.md) | The same screen's **Graphics** block — icon, feature graphic, screenshots |
| [data-safety.md](data-safety.md) | Policy → App content → **Data safety** |
| [content-rating.md](content-rating.md) | Policy → App content → **Content ratings** (IARC questionnaire) |
| [app-content.md](app-content.md) | Policy → App content → everything else, incl. the **permission declarations** |
| [release-runbook.md](release-runbook.md) | Build, sign, upload — and the keystore rules |
| [release-notes.md](release-notes.md) | "What's new" for each release, in all three listing languages |

The hosted legal pages are generated from the repo's own policy files by
`tool/gen_policy_pages.py` into `docs/`, and served by GitHub Pages:

- Privacy policy — <https://vortechu.github.io/hisn/privacy.html> (from [`PRIVACY.md`](../PRIVACY.md))
- Terms of service — <https://vortechu.github.io/hisn/terms.html> (from [`TERMS.md`](../TERMS.md))

Re-run that script after editing either policy, or the hosted page goes stale
against the committed one.

---

## Blocking items — settle these before you submit

These are the things that can cost you a rejection, an account strike, or
weeks of waiting. None of them is fixed by writing a better description.

### 1. Closed testing, if this is a personal developer account

A **personal** (non-organisation) developer account opened after 13 November
2023 cannot publish to production until it has run a **closed test with at
least 12 testers who stayed opted in for 14 continuous days**, and then been
granted production access on application. Organisation accounts are exempt.

This is the single longest lead time in the whole process — start the closed
track *first* and write the listing while it runs. The runbook covers the
mechanics.

### 2. The KFGQPC (QCF v4) Mushaf font licence

The app bundles the King Fahd Complex page fonts to render the Mushaf. The
Complex distributes them freely — they are the faces of the printed mushafs it
gives away — so the expected outcome is a grant, not a refusal. Obtain it
anyway, in writing, from qurancomplex.gov.sa: free *distribution* of a printed
book is not by itself a licence to *redistribute the font files* inside a
published application, and this is the one item here that no Play form will
catch for you. Keep whatever you receive with the release files.

Attribution — the Complex's usual condition — is already satisfied: Settings →
About credits "KFGQPC Hafs (QCF v4) · King Fahd Glorious Quran Printing
Complex", and `TERMS.md` §6 names them again.

Status: **licence pending, attribution done.**

### 3. The app must stay free — no price, no ads, no in-app purchases

The Quran translations come from the Tanzil Project under a **non-commercial
only** licence, which binds the whole app for as long as it ships them. Set the
app to **Free** at creation: on Play a free app can never later be switched to
paid. See `TERMS.md` §6.

### 4. Exact-alarm permissions

The app declares both `SCHEDULE_EXACT_ALARM` and `USE_EXACT_ALARM`. The second
is a *restricted* permission Play limits to apps whose core purpose is alarms,
timers, or calendar/reminder scheduling, and it needs a declaration. Prayer
reminders are a defensible use — they are user-set, time-critical reminders and
the app schedules nothing else — but this is the likeliest place for a
reviewer to push back. [app-content.md](app-content.md) has the wording to
submit and the fallback if it is refused.

### 5. Foreground service type declaration

`FOREGROUND_SERVICE_MEDIA_PLAYBACK` (the adhan player) must be declared, with a
description and usually a short demo video. Filming that clip takes ten
minutes and blocks the release if you leave it to the last hour — do it while
you are capturing screenshots.

---

## Order of operations

1. **Play Console → Create app.** Name, default language (English – United
   States), App (not Game), **Free**, and accept the declarations.
2. **Set up your app** checklist → work through *App content* using
   [app-content.md](app-content.md), [data-safety.md](data-safety.md) and
   [content-rating.md](content-rating.md).
3. **Main store listing** from [store-listing.md](store-listing.md), then add
   Arabic (`ar`) and Indonesian (`id`) listings — the app is fully translated
   into both, and a listing in the user's own language is the cheapest install
   rate you will ever buy.
4. **Graphics** per [graphics.md](graphics.md).
5. **Build and upload** an `.aab` per [release-runbook.md](release-runbook.md)
   to the **closed testing** track. Recruit the 12 testers.
6. Fourteen days later: **apply for production access**, then promote the
   release with the notes from [release-notes.md](release-notes.md).

## What is deliberately not here

- **iOS / App Store.** The repo builds for iOS but this folder is Play only.
- **The hidden adhkar recitation feature.** Held back until the recordings
  exist (`kAdhkarAudioEnabled` in `lib/services/adhkar_audio_library.dart`), so
  it is absent from the listing copy, the screenshots and the permission
  declarations. When it ships it adds a second media session — that changes
  the foreground-service declaration and nothing else.
