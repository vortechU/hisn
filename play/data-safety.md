# Data safety form

**Play Console → Policy → App content → Data safety.**

The answers below are what the code actually does, checked against the app's
dependencies and its merged Android manifest. They must stay consistent with
<https://vortechu.github.io/hisn/privacy.html> — Play compares the two, and a
mismatch between the form and the linked policy is a common rejection.

---

## The one judgement call: location

Play defines **"collected"** as *data transmitted off the device*. Hisn stores
your coordinates only in its own local settings and has no server — so on the
face of it, nothing is collected.

But the app calls the platform geocoder (the `geocoding` plugin → Android's
`Geocoder`) to turn coordinates into the place name shown beside your prayer
times, and on most devices that call goes to Google's servers. That is a
transmission off the device, made by this app, and the privacy policy already
discloses it.

**Declare it.** The cost of declaring is one honest line on your store page.
The cost of *not* declaring, if a reviewer reads the privacy policy that sits
one click away and describes exactly this transmission, is a rejected
submission and a flagged account. The answers below take the declaring route.

---

## Section 1 — Data collection and security

| Question | Answer |
| --- | --- |
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** — the app opens no sockets of its own; the single transmission is the platform geocoder call, which the OS makes over its own secured channel |
| Do you provide a way for users to request that their data is deleted? | **No** — nothing is retained off the device to delete. The account-deletion requirement behind this question applies to apps that let users create accounts; Hisn has none. |

---

## Section 2 — Data types

Tick **exactly one** type. Everything else on the list is **not** collected and
**not** shared.

### Location → Precise location — ✅ collected

| Field | Answer |
| --- | --- |
| Collected | **Yes** |
| Shared | **No** — the app sends it to no third party for their own use; the geocoder resolves and returns |
| Processed ephemerally | **Yes** — held in memory for the request only, never retained off the device |
| Required or optional | **Optional** — the user can pick a city from a built-in list and never grant location |
| Purposes | **App functionality** only |

Do **not** also tick *Approximate location*: the app requests
`ACCESS_FINE_LOCATION`, so precise is the honest single answer.

### Everything else — not collected, not shared

Answer **No** to every one of these; each is listed because a reviewer will
expect a religious/lifestyle app of this size to have tripped at least one.

| Category | Why not |
| --- | --- |
| Personal info (name, email, address, phone, race, religious beliefs…) | There are no accounts and no sign-in. **Note:** using a religious app is not the app collecting your religious beliefs — nothing is transmitted or recorded off device. |
| Financial info | No payments, no IAP, no ads. The app is free and must stay free. |
| Health and fitness | None. |
| Messages | None. |
| Photos and videos | None. |
| Audio files | None. The adhan is a bundled asset; the app records nothing and holds no microphone permission. |
| Files and docs | Backup export and restore are user-initiated, go through the system share sheet and file picker, and never leave the device except where the user sends them. Play does not treat user-initiated sharing as collection. |
| Calendar | None. |
| Contacts | None. |
| App activity (interactions, search history, installed apps, other actions) | Streaks, dua progress, tasbih counts, favourites and in-app search all stay in `shared_preferences` on the device. |
| Web browsing history | None. |
| App info and performance (crash logs, diagnostics, performance) | **No crash reporting and no analytics SDK of any kind.** |
| Device or other IDs | None. No advertising ID — the merged manifest carries no `com.google.android.gms.permission.AD_ID`. |

---

## Section 3 — Advertising ID

Answer **No** to *"Does your app use advertising ID?"*.

Verify before you submit, since a dependency can add the permission silently:

```bash
grep -r "AD_ID" build/app/intermediates/merged_manifest/release/
```

Nothing should match. (Checked for version 1.15.1: no match.)

---

## Reference: what the app actually holds, and where

| Kind | Stored where | Leaves the device? |
| --- | --- | --- |
| Coordinates / chosen city | `shared_preferences`, on device | Only to the OS geocoder, for a place name |
| Calculation method, madhab, iqamah offsets | `shared_preferences` | No |
| Favourites, custom duas, Quran bookmarks | `shared_preferences` | Only inside a backup file the user exports themselves |
| Dua progress, streaks, tasbih counts | `shared_preferences` | Same |
| Language, palette, text size | `shared_preferences` | No |
| Everything else | — | There is no analytics, no crash reporter, no ad SDK, and no backend |

Network permissions in the merged manifest are `INTERNET` and
`ACCESS_NETWORK_STATE`; the only thing that uses them is the platform geocoder
call above. All content — duas, the Mushaf, the translations, the fonts, the
adhan audio — is bundled in the APK and read from assets.

---

## Keep this true

Re-check this form whenever you add a dependency, and specifically when:

- **hands-free adhkar recitation is turned on** (`kAdhkarAudioEnabled`) — the
  recordings are bundled assets, so nothing here changes, but confirm no
  streaming was added;
- any crash reporter, analytics, or remote-config SDK is ever added — that
  changes the answer to Section 1's first question and to *App info and
  performance*;
- backup ever gains a cloud destination of its own, rather than handing a file
  to the system share sheet.
