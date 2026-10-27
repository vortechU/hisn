# Hisn code and performance audit — 27 October 2026

Reviewed the current working tree, including the existing uncommitted work. No application source was changed by this audit. This is a whole-app inspection, not a comparison against a release or branch.

## Fix follow-up — 27 October 2026

The subsequent implementation fixes **B1–B6** and **O1–O3** below. The original findings and measurements are retained as the before state.

- Custom tasbih widget payloads include the user's phrases, and backups include the selected phrase.
- GPS requests use a generation token and disposal checks; timed-out fixes use the plugin's native cancellation path.
- The prayer timetable updates at prayer/day boundaries and on visibility/resume, without waking the compass for clock updates.
- Quran JSON/model caches share pending work and allow failed loads to retry. Search corpus decoding and index construction run in a worker isolate.
- Saved verses retain their pending future and reserve layout space while loading, so the initial viewport does not start the entire collection.
- A persisted Android renewal job runs every twelve hours when any reminder kind is enabled. Boot/update also queues a one-off refill. It invokes the existing Dart planner in a bounded headless engine, using the saved location without a GPS request, view, or audio preview. Foreground startup stops the worker before applying current settings. Turning reminders off cancels renewal. Scheduling failures request a retry.

The renewal mechanism uses [Android JobScheduler](https://developer.android.com/reference/android/app/job/JobScheduler) and a [Flutter engine without a render surface](https://api.flutter.dev/javadoc/io/flutter/embedding/engine/FlutterEngine.html). Android still controls when background jobs may run; this is independent renewal, not a guarantee against force-stop or OEM background restrictions.

Verification after the fixes:

- `dart analyze`: **No issues found**.
- Complete Flutter suite: **641 passed, 4 skipped, no failures**.
- Android/Robolectric suite: **54 passed, no failures**, including six renewal tests.
- Original diagnostic harness: **10 passed**, replacing the previous eight failed assertions.
- Release APK: **built successfully** at `build/app/outputs/flutter-apk/app-release.apk`. The `renewReminders` entrypoint is present in the compiled arm64 AOT snapshot.
- Native widget refresh routing (**O4**) remains a lower-priority opportunity for device profiling.

The same desktop debug harness measured:

| Run | Indexing elapsed before → after | Largest event-loop gap before → after |
| --- | ---: | ---: |
| 1 | 246.9 → 254.5 ms | 240.1 → 40.0 ms |
| 2 | 180.2 → 191.3 ms | 180.4 → 6.5 ms |
| 3 | 172.1 → 170.9 ms | 172.4 → 6.7 ms |

Total indexing time is similar; the improvement is substantially less blocking of the UI isolate. Warm-query time after the change was 4.3–6.6 ms. Opening 100 pending saved verses started **5 loads rather than 100**. These remain desktop debug measurements, not Android release frame timings.

Regression coverage is now kept in `test/audit_regression_test.dart`, `test/quran_loading_test.dart`, `test/reminder_renewal_test.dart`, and `android/app/src/test/kotlin/com/vortech/dua_app/ReminderRenewalTest.kt`. Existing search and Arabic UI tests were updated to cover the new worker-loading path and the reader's options menu.

Android verification required installing the configured NDK and CMake. The SDK's existing license-hash file had two already-present hashes concatenated on one line; only the missing separator was repaired, preserving the stored hash values. No new license hash was added.

No Android device was connected, so headless engine startup and long-running background delivery still need a device smoke test.

## Evidence and limits

- `dart analyze`: **No issues found.**
- `flutter test --no-pub --reporter expanded`: **627 passed, 4 skipped, 1 failed**. The failure is the existing Arabic go-to-verse test described below.
- A separate diagnostic suite exercises the findings through real services, widget builds, and mocked Android platform boundaries. Its final result is **2 passing observations and 8 deliberately failing assertions**. Those failures reproduce incorrect behavior or redundant work; they are not changes to the normal test suite.
- Diagnostic source: `C:/Dev/hisn/.dart_tool/audit/bug_hunt_test.dart`; output: `C:/Dev/hisn/.dart_tool/audit/bug_hunt.log`. These are disposable, ignored audit artifacts and may be removed by Flutter cleanup.
- Measurements are from Windows Flutter debug tests. They establish work on the UI isolate and excessive requests; they are **not Android release frame timings**. Alarm delivery, OEM background restrictions, and device battery impact were not tested on hardware.
- Hands-free recitation is disabled by `kAdhkarAudioEnabled = false`; it was not treated as an active user-facing performance bottleneck.

Reproduce the focused checks from the project root:

```powershell
flutter test --no-pub --reporter expanded .dart_tool/audit/bug_hunt_test.dart
```

The ordinary Flutter launcher could not acquire the SDK cache file under the restricted filesystem. Tests were run successfully through the installed Flutter snapshot with SDK-cache access. The installed Dart SDK ran analysis directly.

## Correctness and lifecycle findings

### B1 — P2: widget refresh replaces a selected custom tasbih phrase

Location: [prayer_widget_service.dart](C:/Dev/hisn/lib/services/prayer_widget_service.dart:257).

`TasbihController.select()` correctly pushes a custom phrase to Android. However, the next full `PrayerWidgetService` payload resolves the selected ID only against `_repository.dhikr`, which contains the built-in presets. Every custom ID misses and falls back to the first preset.

Reproduction: add a phrase with target 77, select it, then bind/flush the full widget service. The captured native payload changes from the custom ID to `subhanallah`, target 33. The controller still holds the custom selection, so app and widget disagree. Relaunching, changing the palette/language, or another full widget refresh can trigger it.

Fix direction: resolve the selection from both presets and `TasbihController.customDhikr`, preferably through one controller lookup shared with the Tasbih screen.

### B2 — P2: a late GPS lookup overwrites a newer manual city label

Location: [prayer_service.dart](C:/Dev/hisn/lib/services/prayer_service.dart:354).

The service checks GPS mode before reverse geocoding, then awaits `_townName()` and updates the label and GPS flag without checking again. A manual city selected during that await remains the coordinate source but gets the previous GPS city's label.

Reproduction: pause reverse geocoding for Madinah, select Riyadh manually, then finish geocoding. Observed state: `mode=manual`, latitude `24.7136` (Riyadh), `label=Madinah`, `usingDeviceLocation=true`. Prayer times can be presented under the wrong city name.

Fix direction: give location requests a generation/token and discard results when the location mode or request generation changes. Recheck immediately after the geocoder returns, before applying any state or preference writes.

### B3 — P2: GPS completion continues after the service is disposed

Location: [prayer_service.dart](C:/Dev/hisn/lib/services/prayer_service.dart:360), [final notification](C:/Dev/hisn/lib/services/prayer_service.dart:375).

The provider tree is intentionally discarded on backup restore, but `PrayerService` has no cancellation or disposal guard for its in-flight location work. A delayed response still writes GPS preferences and calls `_compute()`/`notifyListeners()` on the old service.

Reproduction: dispose the service while reverse geocoding is pending, then return the result. The future fails with `A PrayerService was used after being disposed.` This is a debug assertion; the release concern is obsolete work continuing to write preferences after state has been restored.

Fix direction: invalidate pending requests on disposal and guard their completion and `finally` blocks. Prevent old service instances from writing into the new provider generation's store.

### B4 — P2: the Prayer & Qibla timetable keeps an old current/next prayer

Location: [prayer_qibla_screen.dart](C:/Dev/hisn/lib/screens/prayer_qibla_screen.dart:27).

The screen samples `DateTime.now()` only when its stateless widget builds. It watches changes to prayer configuration, but there is no clock subscription or timer at prayer boundaries. The home header's minute timer rebuilds only that header, not this timetable. The tab is also kept alive in an `IndexedStack`.

Reproduction: mount the actual screen with a prayer-service fixture whose Dhuhr boundary is two seconds ahead; cross that boundary and pump another frame. The service reports Asr as next, while `PrayerTimetable.next` remains Dhuhr. This can persist while the tab is visible or when returning to a tab built earlier.

Fix direction: update time-dependent presentation at boundaries and on resume/tab visibility. Keep the clock subscription local to the timetable so it does not rebuild the compass and whole screen every second.

### B5 — P2: the eight-second GPS timeout leaves native location work running

Location: [prayer_service.dart](C:/Dev/hisn/lib/services/prayer_service.dart:345).

The timeout wraps the returned Dart future. It does not cancel the underlying Android request. The installed `geolocator_android` implementation sends `cancelGetCurrentPosition` when its own `LocationSettings.timeLimit` expires; the app never supplies that limit.

Reproduction: leave the native position result pending and advance the widget-test clock nine seconds. Observed calls: `isLocationServiceEnabled, checkPermission, getCurrentPosition, getLastKnownPosition`. No cancellation was sent. The UI considers the lookup finished while native work remains outstanding.

Fix direction: set the timeout through the plugin's supported location settings and handle that timeout for the last-known-position fallback. Include disposal/mode changes in the cancellation strategy. Battery impact needs device measurement.

### B6 — P3: backups omit the selected tasbih phrase

Location: [backup_service.dart](C:/Dev/hisn/lib/services/backup_service.dart:112), [selection key](C:/Dev/hisn/lib/services/tasbih_controller.dart:28).

`tasbih_selected` matches neither the explicit backup keys nor any allowed prefix. Custom phrases and counters are backed up, but the current selection is omitted even from a full backup.

Reproduction: store `tasbih_selected`, build a backup, and assert that its data contains the key. It does not. Restoring on a fresh installation loses the chosen phrase; restoring on the same installation can retain an unrelated current choice.

Fix direction: explicitly classify this key as a setting or progress and include it in the corresponding backup scope.

## Reminder reliability limitation — address before relying on long unattended use

Location: [notification_service.dart](C:/Dev/hisn/lib/services/notification_service.dart:120), [planning loop](C:/Dev/hisn/lib/services/notification_service.dart:409), [native rearming](C:/Dev/hisn/android/app/src/main/kotlin/com/vortech/dua_app/AdhanScheduler.kt:50).

Only today and the next two days are scheduled. Neither the adhan receiver nor the reboot receiver creates later dates: reboot rearming only reuses persisted future timestamps. There is no independent replenishment mechanism. Adhan, prayer notifications, and the optional remembrance/fasting notifications therefore run out if the app is not opened or otherwise caused to reschedule within that window.

This is documented in the README and is a current design limitation, not a newly introduced regression. Its user impact is nevertheless high for an app expected to deliver daily reminders without regular opening.

Observation: a plan generated for 27 October 2026 at midnight contained 15 prayer reminders, ending on 29 October, with none on day three or later. Source tracing confirms no native renewal path.

Fix direction: replenish from a native scheduled boundary/background mechanism using the persisted prayer configuration. Reuse the native astronomy already present in `PrayerWidget`; merely increasing the window delays exhaustion. Test rollover, reboot, permission changes, and calendar changes before relying on delivery.

## Performance opportunities, in priority order

### O1 — highest impact observed: move cold Quran word indexing off the UI isolate

Location: [quran_repository.dart](C:/Dev/hisn/lib/data/quran_repository.dart:354).

The first Arabic word query loads all 114 surahs and normalizes/indexes all 6,236 verses on the calling isolate. Async asset reads do not move the JSON parsing, normalization, or index construction to a worker. The 250 ms input debounce delays when this work starts; it does not reduce its blocking cost.

Final three-run measurement, using a fresh repository each time:

| Run | First word search | Largest timer/event-loop gap | Subsequent query |
| --- | ---: | ---: | ---: |
| 1 | 246.9 ms | 240.1 ms | 8.9 ms |
| 2 | 180.2 ms | 180.4 ms | 4.1 ms |
| 3 | 172.1 ms | 172.4 ms | 4.2 ms |

The timer probe records responsiveness of the test isolate, not GPU frame times. Earlier repetitions showed the same substantial cold/warm difference. A fresh repository does not clear the process's asset-string cache, so this is not a cold-storage launch benchmark.

Fix direction: generate the normalized search index with the bundled data, or construct it in a worker isolate. A generated index can also avoid loading the entire verse object corpus merely to return a few matches. Preserve the current shared-future protection for concurrent searches.

Validation target: profile first-query typing and scrolling on Android with a fresh process, and record frame timing and memory alongside elapsed search latency.

### O2 — reserve loading space in saved verses to avoid a full-list load burst

Location: [quran_bookmarks_screen.dart](C:/Dev/hisn/lib/screens/quran_bookmarks_screen.dart:67).

Every unresolved verse row returns `SizedBox.shrink()`. While these zero-height rows are pending, the scroll viewport keeps requesting rows to fill its visible area. This defeats lazy loading for the initial pass and causes the list to change height as results arrive. The future is also recreated on row rebuilds.

Reproduction: render the actual bookmark screen with 100 saved verses and pending repository results. **All 100 verse requests start before any result is returned**, despite only a screenful fitting in the viewport. The fixture deliberately holds loads pending to expose the initial layout behavior; it is not a storage-speed benchmark.

Fix direction: give pending rows a reasonable stable placeholder height, use an indexed builder for long collections, and retain each row's future by verse key/language. A builder alone does not solve zero-height pending rows.

### O3 — deduplicate in-flight repository loads

Location: [loadSurah](C:/Dev/hisn/lib/data/quran_repository.dart:52), [loadTranslation](C:/Dev/hisn/lib/data/quran_repository.dart:97), [loadPage](C:/Dev/hisn/lib/data/quran_repository.dart:119).

The caches store only completed decoded objects. Simultaneous requests for an uncached item all miss before any result lands, then each decodes the same JSON and allocates another model graph. AssetBundle's string cache can share asset reads but does not share this decoding. Prefetch and page rendering can overlap; the saved-verse burst makes concurrent requests for the same surah especially likely.

Reproduction: await two concurrent `loadPage(20)` calls on a fresh repository. They return distinct decoded page objects. The later caller overwrites the same completed-cache entry, proving the duplicate construction.

Fix direction: keep one in-flight future per page, surah, translation, and edition request; remove failed futures to allow retry. Apply completed-cache retention limits only if device memory profiling justifies them.

### O4 — lower priority, source-traced: narrow native widget refreshes

Location: [PrayerWidget.save](C:/Dev/hisn/android/app/src/main/kotlin/com/vortech/dua_app/PrayerWidget.kt:64), [refresh](C:/Dev/hisn/android/app/src/main/kotlin/com/vortech/dua_app/PrayerWidget.kt:73).

Every widget payload calls both prayer-feature configuration handlers and broadcasts updates to all six widget providers, even for a tasbih-only count refresh or a Quran reading-position change. Existing debouncing and a worker executor reduce the cost, but the broadcast receivers still do rendering work for unrelated widgets when those widget types are installed.

Fix direction: route updates by changed keys; refresh only the affected providers and only reconcile prayer alarms when prayer configuration changes. This opportunity is supported by source tracing, without a measured native timing claim.

## Existing test failure

[arabic_ui_test.dart](C:/Dev/hisn/test/arabic_ui_test.dart:136) taps `Icons.my_location` directly. The current reader exposes that action inside a popup menu, so the finder matches zero widgets. Update the test to open the reader-options menu first, then select go-to-verse. The failure currently prevents a clean overall test run; it does not establish that the reader action is broken.

## Suggested implementation order

1. Add independent reminder renewal, with native delivery/rollover tests.
2. Remove cold search indexing from the UI isolate.
3. Fix custom tasbih widget selection and GPS request lifetime/cancellation.
4. Add a local boundary/resume clock to the prayer timetable.
5. Deduplicate repository futures and stabilize pending bookmark rows.
6. Include tasbih selection in backups, repair the stale Arabic test, and profile widget refresh routing on Android.

Keep the existing strengths: per-card counting subscriptions, memoized reading themes and mushaf metrics, bounded search input debouncing, unchanged-payload suppression, and visibility-aware compass sensors. Replacing these with broad rebuilds would lose work the app already avoids.
