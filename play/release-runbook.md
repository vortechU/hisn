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
version: 1.16.1+32
#        ^name  ^code
```

- `versionName` (`1.16.1`) is what users see. It must match `kAppVersion` in
  `lib/l10n/app_strings.dart`, which the About screen and every backup file
  record — bump both together.
- `versionCode` (`32`) is what Play orders releases by. It must **increase on
  every upload**, including uploads to a test track that never reach
  production. Play permanently rejects a code it has already seen. Code 31
  was reported as already used by Play; this replacement package uses 32.
  Confirm 32 is available in Play Console before uploading.

---

## 3. Pre-flight

```bash
flutter analyze
flutter test
```

Both must be clean.

**Target API level.** Play refuses new apps and updates below its current
floor. The build takes `targetSdk` from the Flutter toolchain rather than
pinning it. The local Flutter 3.47.7 toolchain resolves it to **36** for
1.16.1 (32). If you upgrade Flutter, that number can move; check the resolved
value in the bundle manifest, rather than only the Gradle assignment.

Then check the things a build will not tell you:

- `versionCode` incremented.
- `kAppVersion` matches `pubspec.yaml`.
- Privacy and terms pages regenerated if either policy changed:
  `python tool/gen_policy_pages.py`.
- `https://vortechu.github.io/hisn/privacy.html` loads in a private window.
- Nothing half-finished is reachable in the UI. For 1.16.1 that means
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
jarsigner -verify -verbose:summary -certs build/app/outputs/bundle/release/app-release.aab
```

Also compare the bundle signer's SHA-256 certificate fingerprint with the
configured upload key. A valid JAR signature alone does not distinguish the
upload key from a debug key. Never copy signing passwords or `key.properties`
into the upload package or verification logs.

### Keep the deobfuscation files

R8 is on (`isMinifyEnabled`), so crash reports arrive obfuscated unless you
retain `build/app/outputs/mapping/release/mapping.txt` and
`build/app/outputs/native-debug-symbols/release/native-debug-symbols.zip`
alongside the bundle. Check the bundle's `BUNDLE-METADATA/` entries for embedded
mapping and native symbols. If the standalone symbols ZIP is stale (for
example, from a previous APK build), stage a ZIP of the symbol entries from
this exact AAB instead, preserving the `<abi>/<library>.sym` paths. Retain the
separate files for manual attachment
if Play requests them. See the [native-symbols guidance](https://developer.android.com/build/include-native-symbols).

Stage 1.16.1 (32) in `build/play-upload/1.16.1-32/`: the signed
`hisn-1.16.1-32.aab`, `mapping.txt`, `native-debug-symbols.zip`, the current
English/Arabic/Indonesian notes from [release-notes.md](release-notes.md),
verification results, and SHA-256 checksums. All three build assets must come
from the same build: do not pair an old bundle with newer mapping or symbols.
This directory is ignored by Git; archive it somewhere durable before a
`flutter clean`. Preparing it does not upload or publish anything.

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

### Install a separate test app on a phone

To keep the installed Play app and its data, opt in to a separate release APK.
It is labelled **Hisn Test**, uses `com.vortech.hisn.test`, and has its own
settings and storage. Dart AOT compilation, R8, resource shrinking, and release
signing are the same as a normal release. The version name ends in `-test`.

From PowerShell at the repository root:

```powershell
flutter build apk --release --target-platform android-arm64 --android-project-arg=hisnSideBySide=true
if ($LASTEXITCODE -ne 0) { throw 'Test APK build failed' }
Copy-Item build/app/outputs/flutter-apk/app-release.apk build/hisn-test-release.apk
adb install -r build/hisn-test-release.apk
```

The example targets an ARM64 phone; adjust `--target-platform` for other devices.
Verify the APK package is `com.vortech.hisn.test` before installing. Regular builds
without this opt-in retain the production package and label.

---

## 5. Upload

The current target is **1.16.1 (32), production**. When upload is separately
authorized, use **Test and release → Production → Create new release**, select
the verified bundle from `build/play-upload/1.16.1-32/`, and use release name
`32 (1.16.1)`. Paste the three production notes from
[release-notes.md](release-notes.md). Review the mapping and native symbols
associated with this exact bundle. Stop before rollout until publishing is
authorized. Official [track and release guidance](https://support.google.com/googleplay/android-developer/answer/9859348).

For a closed-testing release:

1. Play Console → **Testing → Closed testing → Create new release**.
2. Upload the `.aab`, the mapping file, and the symbols.
3. Release name: the version code and name, e.g. `32 (1.16.1)`.
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

1. **Production → Create new release**. If this exact 1.16.1 (32) bundle has
   already been tested on a Play track, promote it. Otherwise use the verified
   staged 1.16.1 (32) bundle; 1.16.0 (30) has different production notes and is
   not the target of this package. Do not rebuild between validation and upload.
2. Countries: all, unless you have a reason.
3. Staged rollout: start at **20%**. A crash in the pre-launch report is cheap;
   a crash in front of every user is not.
4. Watch **Quality → Android vitals** for a couple of days, then go to 100%.

Review for a first release commonly takes several days, occasionally longer for
an app that declares a sensitive permission such as a foreground service (see
[app-content.md](app-content.md)).

---

## 8. After it is live

- Once the released source is committed and the release is live, tag it:
  `git tag v1.16.1 && git push origin v1.16.1`.
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
jarsigner -verify -verbose:summary -certs build/app/outputs/bundle/release/app-release.aab
```
