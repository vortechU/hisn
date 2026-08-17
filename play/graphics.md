# Store graphics

**Play Console → Grow → Store presence → Main store listing → Graphics.**

Two of the assets are generated from the app's own icon and are already in
`play/graphics/`. The screenshots have to come off a real device.

```bash
python tool/gen_play_graphics.py
```

Re-run it whenever `assets/icon/app_icon.png` changes, so the store icon and
the launcher icon never diverge.

---

## Required

| Asset | Spec | Status |
| --- | --- | --- |
| App icon | 512 × 512, 32-bit PNG, ≤ 1 MB, **no transparency**, no rounded corners of your own (Play applies the mask) | ✅ `play/graphics/icon-512.png` |
| Feature graphic | 1024 × 500, PNG or JPEG, ≤ 15 MB, no transparency | ✅ `play/graphics/feature-graphic-1024x500.png` |
| Phone screenshots | 2–8 images, PNG or JPEG, 16:9 or 9:16, each side 320–3840 px | ❌ capture per below |
| 7-inch tablet screenshots | Up to 8, same formats | ❌ optional, but see below |
| 10-inch tablet screenshots | Up to 8, same formats | ❌ optional, but see below |

The feature graphic is what Play shows above the listing and in promotional
placements. It carries no text Play will duplicate, and nothing critical within
32 px of an edge, because Play crops it at some sizes and overlays the app name
at others.

**Tablet screenshots are worth supplying.** Without them the listing carries a
"designed for phones" note on large screens and is excluded from tablet
promotional surfaces. An emulated tablet is fine for capture.

---

## Capturing screenshots

The app is on a real device already (`adb install -r` — never `flutter
install`, which wipes app data). Put the device in a presentable state first:

- Set the location to somewhere recognisable — **Makkah** or **Madinah** reads
  better than your own street, and keeps your address off a public page.
- Turn the tasbih counter to a plausible number, not 0 and not 1.
- Complete part of a morning-adhkar set so the progress rules show something.
- Prefer the default **emerald** palette in **light**, with **one** dark shot
  so the listing shows both.

Capture straight off the device — no chrome, no frame, exact pixels:

```bash
adb exec-out screencap -p > play/graphics/screenshots/01-home.png
```

Repeat per screen. A good eight, in this order — the first two are all most
people see:

1. **Home** — prayer countdown, the recommended-adhkar rubric, category panels.
2. **A dua being counted** — Arabic, meaning, source, repetition ring.
3. **The Mushaf page** — the QCF page in the reader.
4. **Verses beside the page** — an ayah with its translation and citation.
5. **Prayer schedule** — the five times with the next one marked.
6. **Qibla compass** — needle settled, with the location label visible.
7. **Tasbih** — mid-set, ring partly filled.
8. **Home in dark mode**, or the home-screen widgets on the launcher.

Do not add marketing captions, device frames, or drop shadows over them: Play's
own listing chrome already frames each shot, and text baked into a screenshot
is not translated for the Arabic and Indonesian listings.

**Capture each listing language separately if you can.** Switch the app to
Arabic and take shots 1, 2 and 3 again for the `ar` listing — an RTL interface
screenshot is far more persuasive to that audience than an English one, and
Play keeps screenshots per language.

---

## Optional

| Asset | Spec | Worth it? |
| --- | --- | --- |
| Promo video | A YouTube URL | No. It replaces the feature graphic at the top of the listing, and a bad video costs installs. |
| TV / Wear / Auto assets | — | Not applicable; the app targets phones and tablets. |

Note the separate demo video that the **foreground-service declaration** needs
([app-content.md](app-content.md) §2) — that one is required, but it goes into
a policy form, not the listing.

---

## Gitignore

`play/graphics/*.png` are build products of `tool/gen_play_graphics.py`;
screenshots are device captures. Both are ignored — regenerate the first, and
keep the second wherever you keep the release's working files. Only the scripts
and this documentation are tracked.
