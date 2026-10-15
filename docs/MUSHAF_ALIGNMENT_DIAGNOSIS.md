# Mushaf alignment investigation — 2026-10-15

Report: Quran page 151 (Al-A'raaf) appears misaligned on a tester's Xiaomi 12
Lite 5G. The screenshot came from the uploaded build before the current local
changes. A follow-up device settings screenshot confirms:

- Android 14, build `UKQ1.231003.002`.
- OS version `1.0.34.0.ULIMIXM`.
- Android security update `2026-05-01`.

Font/display size settings and persistence after reopening remain unknown.

## Confirmed defect

The reader measures QCF glyphs with an unscaled `TextPainter`, fits them to the
page, and uses the same unscaled metrics to locate verse taps. Its `Text.rich`
widgets inherited the system text scaler. Enlarging system text therefore
enlarged the printed glyphs after fitting, without enlarging the line slots.
The same mismatch is present in the checked-in reader code.

An unattended widget reproduction loads the real page 151 JSON and bundled QCF
fonts. At DPR 2.75 and text scale 1.3, the first body line measured 439.54 logical
pixels inside a 344.73-pixel slot. The rendered preview showed overflow across
the frame and text from prefetched neighbouring pages intruding on this page.
At text scale 1.0 it fit. Changing density alone did not reproduce the problem.

The narrow correction sets `TextScaler.noScaling` on the two printed QCF text
widgets (body and decorative lines). Their size continues to follow the page
constraints and existing pinch zoom. The app bar, settings, verse sheets and
other ordinary text keep their existing scaling behavior.

Flutter documents the platform text scaling behavior in
[MediaQueryData.textScaler](https://api.flutter.dev/flutter/widgets/MediaQueryData/textScaler.html)
and [TextPainter.textScaler](https://api.flutter.dev/flutter/painting/TextPainter/textScaler.html).

Android 14 supports nonlinear text scaling up to 200%, which is relevant to
the measurement/painting mismatch. It does not prove the tester enabled an
enlarged font size. See Flutter's
[Android 14 scaling migration notes](https://docs.flutter.dev/release/breaking-changes/android-14-nonlinear-text-scaling-migration).

## Evidence and limits

Command (using the installed Flutter tool):

```powershell
flutter test --no-pub test/mushaf_device_alignment_test.dart test/mushaf_layout_test.dart test/mushaf_ayah_test.dart test/mushaf_feedback_test.dart --dart-define=CAPTURE_ALIGNMENT=true
```

- Before correction: 3 density cases passed at normal text size; 6 cases failed
  the line-containment assertion at text scales 1.3 and 1.5.
- After correction: all 35 tests passed. The new tests cover densities 2.0,
  2.75 and 3.0, text scales 1.0, 1.3 and 1.5, frame centring after swipes in both
  directions, and tapping the painted 7:1 rosette with enlarged system text.
- Existing layout, verse mapping/touch and reader feedback tests also passed.
- Before/after previews are generated under `build/mushaf-alignment/`.
- The reproduction uses linear test scalers, not the device's exact Android 14
  nonlinear curve. The correction removes inherited scaling from the printed
  QCF glyphs, so it does not depend on a particular curve.

The screenshot's shifted frame and visible adjacent frame were **not reproduced
as a persistent settled-page defect**. An in-progress swipe could account for
that part, but this is unconfirmed. Desktop widget tests do not exercise the
Xiaomi GPU, Android renderer, or its actual display settings. No device-specific
renderer change was made, and no build was uploaded as part of this work.

Next device check: open page 151 in the next tester build, wait for paging to
settle, swipe away and back, and repeat with both normal and enlarged system
text. If the frame remains shifted, capture a short screen recording starting
with reopening the reader, plus the font size and display size settings.
