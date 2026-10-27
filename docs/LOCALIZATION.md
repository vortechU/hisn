# Adding and maintaining languages

The language registry is `lib/l10n/app_language.dart`. It defines each language's
native name, direction, script, UI font, native font fallback, geocoder locale,
and content coverage. The language picker and supported locales derive from it.
Saved codes (`en`, `ar`, `id`, `ur`, `sq`) must stay stable across releases.

UI wording belongs in `lib/i18n/<code>.i18n.json`. Slang generates the Dart
catalogs; `AppStrings` keeps the interface used by screens and background work.
Use plural objects (`one`, `two`, `few`, `many`, `other`, etc.) instead of choosing
forms in Dart. Each language supplies its own categories and must include `other`.
Count parameters can be omitted in zero, singular and dual forms when the wording
expresses the count. Other interpolated parameters must be preserved.

Religious content belongs in `assets/data/`. Keep the original Arabic, IDs,
repeat counts and source records intact. Translate descriptions through
`duas.<code>.json`, `categories.<code>.json`, and `tasbih.<code>.json`, using entry
IDs as keys and translated field names inside each entry. Register a dataset
and its required fields in `AppLang.overlays` when it is ready to ship. Every
applicable base entry must have those fields; optional base fields only require
a translation when they exist. `_meta` may carry provenance, which must survive
content updates. Albanian content provenance is in `ALBANIAN_LOCALIZATION.md`.
Existing Urdu category and tasbih overlays were moved verbatim
from the models; the dua provenance remains in `docs/URDU_DUA_PROVENANCE.md`.

Datasets omitted from a language's declaration deliberately use base content.
For example, Indonesian currently uses English category names and tasbih meanings.
Production loading falls back if an overlay is missing or malformed and logs the
asset and error. Validation rejects incomplete declared datasets and invalid files.

Quran meanings remain independently described by
`assets/data/quran/trans/editions.json`, including translator credits and source.
An interface language can ship without a Quran edition; in that case no meaning
is shown. Use `tool/gen_quran_translations.py` to maintain those assets. Preserve
the existing provenance and licensing requirements when adding an edition.

To add a language:

1. Create its UI catalog using English as the key/placeholder reference and
   register it in `AppLang`, including direction, script and fonts. Check that
   `intl` supports its CLDR plural rules. `AppStrings` supplies these rules to
   Slang so a missing Slang built-in resolver cannot silently use English rules.
2. Add and declare the content overlays that are ready. Register their paths in
   `pubspec.yaml`, together with any new fonts or Quran translation directories.
   Flutter asset directory declarations are not recursive.
3. Regenerate and validate from the project root:

   ```powershell
   dart run slang
   dart run tool/sync_native_localizations.dart
   dart run tool/validate_localizations.dart
   flutter test --no-pub
   ```

`sync_native_localizations.dart` generates the bundled
`assets/data/native_localizations.json` from the registry and UI catalogs.
Android widgets and adhan playback read that file even when Flutter is closed.
Do not add language switches or translated text in Kotlin. English literals
there are emergency fallbacks for an unreadable bundle. Commit generated files.
`dart run tool/sync_native_localizations.dart --check` detects stale output.

The regular Flutter suite validates every registered language's catalog,
placeholders, declared content, fonts, asset packaging, and generated native data.
It also checks that Slang's generated locales match the registry. Layout checks
must include every language at narrow widths and large text sizes. For Android
changes run `./gradlew.bat :app:testDebugUnitTest --tests com.vortech.dua_app.NativeLocalizationsTest`
from the `android` directory.

Arabic source content, interface direction and font coverage are separate choices.
An RTL language must not automatically inherit Arabic-only behavior such as hiding
dua meanings. The Arabic interface intentionally suppresses duplicate dua
translations/transliterations; Quran tafsir remains visible.
