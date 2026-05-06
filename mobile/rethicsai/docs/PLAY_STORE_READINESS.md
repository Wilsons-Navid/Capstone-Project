## Rethicssec – Engineering & Play Store Readiness

This guide summarizes the engineering improvements, performance/a11y polish, localization workflow, and release steps needed to ship a reliable, efficient Play Store build of Rethicssec.

### High‑Level Status
- Localization: End‑to‑end wired via EasyLocalization. Languages: en, sw, fr, ar, ha, yo, ig, zu, xh, af, dua (Sawa/Duala).
- Translation tooling: Free auto‑translate (LibreTranslate/MyMemory), CSV export/import, and key coverage checks are in `tool/`.
- UI wiring: Dashboard, drawer, language page use translation keys. Language flags are computed (no garbled emojis).

---

## Engineering Plan (Focus Areas)

1) Architecture & Code Health
- Modularize very large screens (e.g., dashboard) into smaller widgets.
- Narrow rebuild scope using `Selector`/`BlocBuilder` around small subtrees.
- Keep DTO/domain models pure; standardize on Freezed/JSON generated code.
- Tighten lints; elevate warnings to errors in CI.

2) Performance & Efficiency
- Compress/optimize images; remove zero‑byte/unused assets.
- Defer heavy work; precache above‑the‑fold visuals.
- Use `const`, `RepaintBoundary` where helpful; avoid heavy shadows in lists.
- Build size: obfuscate and split debug info (symbol mapping) for AAB.

3) Localization & Accessibility
- Add high‑quality fonts for Arabic/RTL; verify glyph coverage for African languages.
- Support text scaling (0.8–1.6); ensure layout resiliency.
- Add semantics for buttons/icons, minimum 48px touch targets, color contrast.
- RTL audit for Arabic (mirroring, chevrons, paddings, icon directions).

4) Networking & Data
- Centralize Dio config (timeout, interceptors, retry/backoff).
- Use ETags/If‑Modified‑Since where possible; add on‑device cache (Hive) for read‑heavy resources.
- Offline: ensure cached views show with clear “syncing/offline” banners.

5) Security & Privacy
- Secrets out of repo; ship release config via CI/CD.
- Enable Firebase App Check (with Play Integrity) for Firestore/Functions/Storage.
- Encrypt sensitive local data (Hive box encryption). Disable cleartext traffic.
- Minimize data collection; surface analytics consent.

6) Firebase & Backend
- Harden Firestore rules; add emulator tests for common reads/writes.
- Verify indexes for all compound queries.
- Enable Crashlytics/Performance in release builds; gate with user consent.

7) QA & Testing
- Unit/widget tests for mappers, providers/blocs, and key widgets.
- Integration tests: auth → dashboard → language switch → incident flow.
- Golden tests for critical screens (light/dark/RTL/large text).
- Device matrix coverage incl. low‑end Android Go.

---

## Localization Workflow (CLI Tools)

Location: `tool/`

- `translate_assets.dart`: Auto‑fills missing keys using free providers (LibreTranslate/MyMemory). Keeps app offline at runtime.
- `check_translations.dart`: Verifies that required UI keys exist across all locales.
- `export_translations.dart`: Exports a CSV of all keys × languages for translators.
- `import_translations.dart`: Merges translator‑edited CSV back into JSON assets.

Supported languages today: `en, sw, fr, ar, ha, yo, ig, zu, xh, af, dua` (Duala is manual; most free engines don’t support it).

### Auto‑Translate (Free)
Public instances are rate‑limited. Prefer a self‑hosted LibreTranslate for reliability.

1) LibreTranslate
- macOS/Linux: `export LIBRE_URL=https://libretranslate.com`
- Windows (PowerShell): `$env:LIBRE_URL='https://libretranslate.com'`
- Run: `dart run tool/translate_assets.dart --provider=libre --to=fr,ar,ha,yo,ig,zu,xh,af,sw`

2) MyMemory (fallback)
- Optional contact email for fairness: `export MYMEMORY_EMAIL=you@example.com`
- Run: `dart run tool/translate_assets.dart --provider=mymemory --to=ha,yo,ig,zu,xh,af,sw`

3) Auto mode (tries free first, then paid if configured)
- `dart run tool/translate_assets.dart --provider=auto --to=fr,ar,ha,yo,ig,zu,xh,af,sw`

### Validate Coverage
`dart run tool/check_translations.dart`

### CSV Export/Import
- Export: `dart run tool/export_translations.dart --out=translations_export.csv --bom=true`
- Edit in Excel/Google Sheets (keep UTF‑8).
- Dry‑run import: `dart run tool/import_translations.dart --in=translations_export.csv --dry-run=true`
- Import: `dart run tool/import_translations.dart --in=translations_export.csv`

Notes:
- Only non‑empty CSV cells overwrite JSON values. Empty cells are ignored.
- Arabic/RTL strings: keep punctuation/direction consistent; prefer neutral collation.

---

## Android Play Store – Build & Release Steps

1) App/Manifest/Gradle
- Target SDK 34.
- Set `android:usesCleartextTraffic="false"`.
- Ensure `android:exported` is set appropriately for activities.
- Configure release signing in `android/app/build.gradle`.

2) Build AAB (with obfuscation + symbol mapping)
```
flutter build appbundle \
  --release \
  --obfuscate \
  --split-debug-info=build/symbols
```
- Keep mapping files in a secure location (for Crashlytics symbolication).

3) Shrink/Minify
- Ensure R8 is enabled (default in release). Consider `shrinkResources true` to reduce APK splits (if you build APKs for internal tests).

4) Firebase
- App Check with Play Integrity; Crashlytics/Performance enabled in release.

5) Store Listing
- App icon + adaptive icon, feature graphic, screenshots (phone/tablet), privacy policy URL.
- Content rating, Data Safety form, target audience.

---

## Security & Privacy Checklist
- [ ] No secrets in repo; CI supplies release keys.
- [ ] App Check enabled for Firestore/Functions/Storage.
- [ ] Min data collecteion; analytics behind consent.
- [ ] Encrypted local storage for sensitive user data.
- [ ] Permissions: just‑in‑time with clear rationale; remove unused.

---

## UX & Accessibility Checklist
- [ ] Arabic/RTL mirrored layouts verified.
- [ ] Fonts include Arabic and African language coverage.
- [ ] Text scaling up to 1.6 without layout breakage.
- [ ] Buttons/icons have semantics; 48dp min target.
- [ ] Sufficient color contrast in light/dark modes.

---

## Useful Notes
- Language flags are computed in code (no stored emojis) to avoid encoding issues.
- Douala (Duala/`dua`) translations are maintained manually in `assets/translations/dua.json`.
- Run `flutter pub get` before using tools in `tool/`.

---

## Suggested Next Tasks (Quick Wins)
- Clean assets: remove 0‑byte/unused files; compress images.
- Add Arabic font + test RTL layouts.
- Add a release build script and CI workflow for analysis/tests/build.
- Add Dio retry/backoff and caching headers.
- Write a few golden tests for critical screens.

