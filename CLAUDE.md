# Iraq Pharma Guide (Flutter)

Pharmacy reference app for Iraq. Arabic-first UI, English supported. The owner
is a clinical pharmacist, not a developer: do the work end to end, keep replies
short and in Arabic, and never start a store build or a store submission before
telling him what is still unfinished. When a step needs his hands (passwords,
sign-in, credential files), teach it one step at a time.

## Branches
- `main`: old published 2.3.0.
- `release/3.1`: current release line. Merge into `main` once both stores carry 3.1.

## Commands
- `flutter analyze` must report 0 errors.
- `flutter test test/layout_smoke_test.dart test/en_dict_test.dart`
- `flutter test test/screens_smoke_test.dart` writes `screens_report.txt`;
  every line must be `OK` (51 routes x 4 configs, real fonts from `test/fonts`).
- The tests have no network, camera or database: screens with live data and
  notifications still need a real phone.

## Rules
- Public repository: never commit secrets, keystores or `google-services.json`.
- Do not touch the notification setup or any `google-services*.json`.
- iOS must not expose dose calculators (App Store guideline 1.4.1, rejected
  before): dose, creatinine clearance, chemo dose adjustment and fluids stay
  behind `FeatureFlags.doseToolsOnThisPlatform` (tiles, drawer and routes).
- Drug data stays in English. Do not import proprietary Lexicomp content.
- Barcode linking is admin-only; ordinary users only suggest.
- Access control lives in Supabase RLS (`is_db_admin()`), not in the client.
- User-submitted listings (jobs, availability) are pre-moderated and carry a
  report button (`lib/shared/widgets/report_listing.dart`).

## Conventions
- User-facing text: `context.s.isAr ? ar : en` (strings in
  `lib/core/l10n/app_strings.dart`), or `TText` / `trS` / `trN` from
  `lib/shared/widgets/t_text.dart` with an entry in `lib/core/l10n/en_dict.dart`
  for const Arabic tables. Strings with `$` interpolation cannot use the dictionary.
- Store links come only from `lib/core/config/store_links.dart`.
- Never use `Row(crossAxisAlignment: stretch)` or `Expanded` inside an
  unbounded list item; it paints nothing in release builds.
- go_router already decodes path parameters; do not decode them again.
- Working tree has CRLF files: stage with `git -c core.autocrlf=input add`.

## Builds
- Pushing does not build. Codemagic builds are started manually:
  `ios-testflight`, `android-test` (debug-signed APK), `android-release`
  (signed AAB, keystore reference `iraq_pharma_upload`).
- iOS build number = latest TestFlight + 1. `android-release` build number =
  100 + Codemagic build number.

More context (IDs, server changes, open work) is in `CLAUDE.local.md` when present.
