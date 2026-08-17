# Release runbook

Build, sign, and ship. Everything here is repeatable; the only irreversible
step is the first one.

---

## 1. The upload key — do this once, and do not lose it

**Whoever holds this key can publish an update to Hisn, and Play will refuse an
update signed with any other key for the life of the listing. There is no
recovery.**

```bash
keytool -genkey -v -keystore V:/keys/hisn-upload.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias hisn
```

Keep the keystore **outside the repository**. Then create
`android/key.properties` (gitignored, and it must stay that way):

```properties
storeFile=V:/keys/hisn-upload.jks
storePassword=…
keyAlias=hisn
keyPassword=…
```

`android/app/build.gradle.kts` reads that file and signs release builds with
it. If the file is absent the build **falls back to the debug key** and prints
a warning — that APK installs and runs, but it cannot be published, and it can
never be upgraded in place by a properly signed build.

**Back up the keystore and both passwords to two places you control** (an
encrypted archive plus a password manager entry). Do this before you build, not
after you ship.

> Enrol in **Play App Signing** when you create the app — it is the default and
> it is the safety net: Google holds the *app signing key* and your `.jks`
> becomes only the *upload key*, which Google can reset for you if it is lost.
> Without it, a lost key ends the listing.

---

## 2. Version numbers

Set in `pubspec.yaml`:

```yaml
version: 1.15.1+26
#        ^name  ^code
```

- `versionName` (`1.15.1`) is what users see. It must match `kAppVersion` in
  `lib/l10n/app_strings.dart`, which the About screen and every backup file
  record — bump both together.
- `versionCode` (`26`) is what Play orders releases by. It must **increase on
  every upload**, including uploads to a test track that never reach
  production. Play permanently rejects a code it has already seen.

---

## 3. Pre-flight

```bash
flutter analyze
flutter test
```

Both must be clean.

**Target API level.** Play refuses new apps and updates below its current
floor. The build takes `targetSdk` from the Flutter toolchain rather than
pinning it, so it follows whatever the installed Flutter defaults to — **36**
on Flutter 3.44, comfortably above the floor. If you upgrade Flutter, that
number moves; check it with `grep targetSdk android/app/build.gradle.kts` and
the resolved value in the merged manifest before assuming.

Then check the things a build will not tell you:

- `versionCode` incremented.
- `kAppVersion` matches `pubspec.yaml`.
- Privacy and terms pages regenerated if either policy changed:
  `python tool/gen_policy_pages.py`.
- `https://vortechu.github.io/hisn/privacy.html` loads in a private window.
- Nothing half-finished is reachable in the UI. As of 1.15.1 that means
  `kAdhkarAudioEnabled` is `false` in
  `lib/services/adhkar_audio_library.dart`, and the `audio_service` entries in
  `android/app/src/main/AndroidManifest.xml` are still commented out.

---

## 4. Build the bundle

Play takes an **App Bundle** (`.aab`), not an APK.

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`.

Confirm it is signed with your key and not the debug key — the build logs a
loud warning if `key.properties` was missing, and this reads the certificate
back:

```bash
jarsigner -verify -verbose:summary build/app/outputs/bundle/release/app-release.aab
```

### Keep the deobfuscation files

R8 is on (`isMinifyEnabled`), so crash reports arrive obfuscated unless you
upload the mapping. Play Console → your release → **upload**
`build/app/outputs/mapping/release/mapping.txt`, and the native symbols from
`build/app/outputs/native-debug-symbols/release/` alongside it.

### Sanity-check the artefact

```bash
# What the store will actually ask for at install time
bundletool build-apks --bundle=build/app/outputs/bundle/release/app-release.aab --output=/tmp/hisn.apks
```

Or simply install the release APK on the phone and use it for ten minutes:

```bash
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

`adb install -r` preserves app data. **Never `flutter install`** — it wipes it.

---

## 5. Upload

1. Play Console → **Testing → Closed testing → Create new release**.
2. Upload the `.aab`, the mapping file, and the symbols.
3. Release name: the version code and name, e.g. `26 (1.15.1)`.
4. Release notes: paste from [release-notes.md](release-notes.md), for each of
   the three listing languages.
5. Save → Review release → **Start rollout to Closed testing**.

Play runs pre-launch reports on real devices for a few hours after upload.
**Read them** — they catch crashes on API levels and screen sizes you do not
own, and an accessibility scan you would otherwise never run.

---

## 6. Closed testing, if this is a personal developer account

A personal account opened after 13 November 2023 must run a closed test with
**at least 12 testers opted in continuously for 14 days** before it can apply
for production access. Testers must actually *have* the app installed for the
period; people who opt in and immediately leave do not count.

Practicalities:

- Create the tester list from email addresses (a Google Group is easier to
  manage than a raw list).
- Send them the opt-in link from the track page; each has to accept before the
  Play link resolves for them.
- Ask them to leave it installed for the fortnight and to actually use it —
  Play surfaces engagement to the reviewer of your production application.
- After 14 days a **Apply for production access** button appears. The
  application asks what you tested and what you learned; answer it from the
  pre-launch reports and tester feedback rather than in generalities.

---

## 7. Production

1. **Production → Create new release**, promote the tested bundle rather than
   building a new one.
2. Countries: all, unless you have a reason.
3. Staged rollout: start at **20%**. A crash in the pre-launch report is cheap;
   a crash in front of every user is not.
4. Watch **Quality → Android vitals** for a couple of days, then go to 100%.

Review for a first release commonly takes several days, occasionally longer for
an app that declares a restricted permission — which this one does
(`USE_EXACT_ALARM`, see [app-content.md](app-content.md)).

---

## 8. After it is live

- Tag the release: `git tag v1.15.1 && git push --tags`.
- Keep `mapping.txt` for any version still in the field; without it the vitals
  stack traces are unreadable.
- Answer reviews. For this app most of them will be about prayer-time accuracy
  in a particular city — the answer is nearly always the calculation method,
  which is user-configurable in Settings.

---

## Cheat sheet

```bash
flutter analyze && flutter test
python tool/gen_policy_pages.py
python tool/gen_play_graphics.py
flutter build appbundle --release
jarsigner -verify -verbose:summary build/app/outputs/bundle/release/app-release.aab
```
