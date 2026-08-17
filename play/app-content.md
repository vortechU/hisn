# App content declarations

**Play Console → Policy → App content.** Every item on that page, in the order
it appears, plus the sensitive-permission declarations that surface when you
upload a bundle. Data safety and content ratings have their own files
([data-safety.md](data-safety.md), [content-rating.md](content-rating.md)).

---

## Privacy policy

| Field | Value |
| --- | --- |
| Privacy policy URL | `https://vortechu.github.io/hisn/privacy.html` |

Generated from [`PRIVACY.md`](../PRIVACY.md) by `tool/gen_policy_pages.py` and
served from `docs/` by GitHub Pages. **Confirm the URL loads in a private
window before submitting** — Play fetches it, and a repository that is private,
or a Pages deployment that was never enabled, fails the check silently from
your side.

Enabling Pages, once: repository **Settings → Pages → Source: Deploy from a
branch → Branch: `master`, Folder: `/docs` → Save.** First publish takes a
couple of minutes.

---

## App access

**All functionality is available without special access.**

There are no accounts, no login, no region lock, and no paywall. Nothing to
give a reviewer.

---

## Ads

**No, my app does not contain ads.**

And it cannot acquire them: the bundled Quran translations are licensed for
non-commercial use only (`TERMS.md` §6).

---

## Content ratings

See [content-rating.md](content-rating.md).

---

## Target audience and content

| Question | Answer |
| --- | --- |
| Target age groups | **18 and over** (and 16–17 if you want it; do **not** tick any band below 13) |
| Is your app designed for children? | **No** |
| Store presence appeal to children | **No** — the listing graphics use manuscript typography and ornament, nothing child-directed |

> Ticking any under-13 band puts the app under **Families policy**, which
> brings a separate content review, a stricter ads/SDK regime, and a
> requirement that the app's data practices be verified against the Families
> requirements. The privacy policy already states the app is not directed at
> children under 16. Keep the two consistent.

---

## News app

**No.** Hisn is a devotional reference app; the Hijri calendar and prayer
schedule are calculations, not reporting.

---

## Data safety

See [data-safety.md](data-safety.md).

---

## Government apps

**No.** Not affiliated with, endorsed by, or produced on behalf of any
government body. (The app *renders* texts published by the King Fahd Complex —
that is attribution, not affiliation.)

---

## Financial features

**My app doesn't provide any financial features.** No payments, no lending, no
crypto, no insurance.

---

## Health apps

**No.** Prayer times and fasting days are religious observances, not health
tracking, and the app records nothing about the user's body.

---

# Sensitive permission declarations

These appear either on the App content page or as a blocking form when you
upload a bundle that declares them. All four apply to Hisn.

## 1. Exact alarms — `USE_EXACT_ALARM` + `SCHEDULE_EXACT_ALARM`

**The riskiest declaration in this submission.** `USE_EXACT_ALARM` is a
restricted permission: Play grants it to apps whose *core* function is alarms,
timers, or calendar/reminder scheduling. A reviewer who reads "prayer times
app" and stops there may refuse it.

Declaration text to paste:

```
Hisn's core function is notifying the user at the five daily Islamic prayer
times, which are astronomical events computed for the user's location and
change every day. A reminder that arrives late is worthless: the user is being
told that a time-bounded religious obligation has begun, and a few minutes'
drift means they miss it or perform it out of its window.

The app uses exact alarms only to (a) post the user's opt-in prayer reminder
at the calculated time, optionally offset by a user-configured iqamah delay,
and (b) start playback of the adhan at the calculated time. It schedules
nothing else. Reminders are off by default and are enabled by the user per
prayer. Inexact alarms and WorkManager were evaluated and are unsuitable: both
are batched by the system and routinely fire many minutes late, which for this
use case is the same as not firing.
```

**Verify before you rely on it:** open Play Console's *Policy → App content*
page and check whether an "Alarms & reminders" or "Exact alarm permission"
declaration is listed for your app. If none appears, the declaration is made
at upload time against the bundle — the wording above serves either way.

**If it is refused:** drop `USE_EXACT_ALARM` from
`android/app/src/main/AndroidManifest.xml` and keep `SCHEDULE_EXACT_ALARM`
alone. The app already handles this path — `NotificationService` calls
`canScheduleExactNotifications()` and falls back, and
`requestExactAlarmsPermission()` sends the user to the system setting. The cost
is one extra tap during onboarding for users on Android 13+, not a broken
feature.

## 2. Foreground service — `FOREGROUND_SERVICE_MEDIA_PLAYBACK`

Required since August 2024 for every declared foreground service type.

| Field | Answer |
| --- | --- |
| Service type | **mediaPlayback** |
| Is it user-initiated? | Yes — the user enables adhan playback per prayer in Settings |

Declaration text:

```
Hisn plays the adhan (the Islamic call to prayer) as audio at the five daily
prayer times, when the user has enabled it. Playback is a media playback of a
bundled audio file, started by an exact alarm at the calculated prayer time and
lasting the length of the recording. A foreground service is used because the
audio must play reliably while the app is in the background and the screen is
off — that is the entire point of the feature — and because the user must be
able to see and stop it from the notification while it plays.
```

**Demo video.** Play usually asks for a public URL (unlisted YouTube is fine)
showing the feature in use. Film, in one take, roughly 30 seconds:

1. Settings → Notifications → enable the adhan for one prayer.
2. Set the device clock so that prayer is a minute away, or use a prayer that
   is imminent.
3. Leave the app, lock the screen.
4. The adhan starts; show the notification on the lock screen, and stop it
   from there.

Upload it unlisted, paste the link, and keep the link alive — Play re-checks it
on later reviews.

> When `kAdhkarAudioEnabled` is turned on, a **second** media session (the
> hands-free adhkar recitation, via `audio_service`) starts using the same
> permission. Amend this declaration and re-film in the same release.

## 3. Location — `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION`

There is no separate console form for foreground-only location, but the policy
requirements still apply, and Play's automated review checks them:

- **Prominent disclosure before the request.** Already satisfied: the
  onboarding permissions page explains that location is used for prayer times
  and qibla *before* the system dialog is raised, and the app is fully usable
  if it is refused (pick a city instead).
- **No background location.** The app declares no `ACCESS_BACKGROUND_LOCATION`
  and must not gain one — that would trigger a separate, much heavier review.
- **The declared use must match the listing and the policy.** All three say
  prayer times and qibla, and nothing else.

## 4. Full permission inventory

Every permission in the merged release manifest of 1.15.1, and what needs
saying about it. Regenerate with:

```bash
grep -o 'android:name="android.permission.[A-Z_]*"' build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml | sort -u
```

| Permission | Used for | Declaration |
| --- | --- | --- |
| `ACCESS_FINE_LOCATION` | Prayer times, qibla bearing | §3 above |
| `ACCESS_COARSE_LOCATION` | Same, when precise is refused | §3 above |
| `INTERNET` | Platform geocoding of coordinates → place name | Data safety |
| `ACCESS_NETWORK_STATE` | Pulled in by a dependency; no direct use | None |
| `POST_NOTIFICATIONS` | Prayer reminders (opt-in) | None |
| `SCHEDULE_EXACT_ALARM` | Firing a reminder at the calculated time | §1 |
| `USE_EXACT_ALARM` | Same, without a per-user grant | §1 — **restricted** |
| `RECEIVE_BOOT_COMPLETED` | Re-arming alarms after a reboot (AlarmManager drops them) | None |
| `FOREGROUND_SERVICE` | The adhan player | §2 |
| `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Same | §2 |
| `WAKE_LOCK` | Keeping the device awake for the length of the adhan | None |
| `VIBRATE` | Haptics on tasbih and dua counting | None |

No advertising ID permission, no storage permissions (backup uses the system
file picker and share sheet), no microphone, no camera, no contacts, no SMS,
and no `QUERY_ALL_PACKAGES`.
