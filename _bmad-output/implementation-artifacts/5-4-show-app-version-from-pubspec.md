---
baseline_commit: 2f3c602071ae900258f80429fb8a26bff0457d1d
---

# Story 5.4: Show App Version From Pubspec

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a store owner or tester,
I want to see the app version,
so that support and testing can identify which build is installed.

## Acceptance Criteria

1. Given the user opens Settings, when the App Version row is displayed, then it shows the installed app version from package metadata or `pubspec.yaml`, and the visible version is not hardcoded separately in UI copy.
2. Given the app runs in debug or release mode, when Settings displays app version, then the version display works consistently and can support build identification during testing.
3. Given MVP scope is enforced, when app version display is implemented, then no login, cloud sync, remote API, analytics, release-channel service, persistence table, Android permission, or unrelated Settings/app-shell behavior is added.

## Tasks / Subtasks

- [x] Task 1: Replace hardcoded Settings app-version copy with canonical version data (AC: 1, 2)
  - [x] Update `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart`; do not create a parallel Settings screen or route.
  - [x] Preserve `Key('settings-screen')` and `Key('settings-app-version-section')`.
  - [x] Keep the section title `App Version` unless there is a strong local UI reason to adjust punctuation only.
  - [x] Replace the current value `MVP preview` with the canonical app version from `tindatrack/pubspec.yaml` (`0.1.0+1` at story creation time) or package metadata derived from that version.
  - [x] Keep the visible value suitable for support/testing, preferably including both version and build number such as `0.1.0+1`.
  - [x] Do not duplicate the version as an unrelated UI-only constant that can drift from `pubspec.yaml`.

- [x] Task 2: Keep implementation local, simple, and offline (AC: 1-3)
  - [x] Prefer the smallest implementation that keeps `pubspec.yaml` as the canonical source.
  - [x] If reading `pubspec.yaml` at runtime, include only the minimum asset/configuration needed and parse only the top-level `version:` field.
  - [x] If using package metadata instead, keep the dependency/platform integration justified and tested; do not add release-channel, analytics, crash reporting, or network behavior.
  - [x] Preserve the synchronous/lightweight Settings layout where possible; if async loading is needed, show stable, friendly copy and no raw technical errors.
  - [x] Do not add Drift schema changes, settings repositories, providers, migrations, remote clients, login/account routes, Android permissions, or app-shell routes for this story.

- [x] Task 3: Preserve existing Settings and app shell behavior (AC: 1-3)
  - [x] Keep the four Settings sections visible: Currency, Backup / Export, App Version, and Local Data.
  - [x] Preserve PHP currency context from `CurrencyFormatter.php()`.
  - [x] Preserve Story 5.3 Backup / Export copy, including local-device and no-account/no-internet wording.
  - [x] Preserve the existing four-tab app shell: Dashboard, Products, History, Settings.
  - [x] Do not alter product, stock, history, dashboard, currency formatter, router, database, generated migrations, or Android platform files unless strictly required by the chosen version-source mechanism.

- [x] Task 4: Add focused Settings tests (AC: 1-3)
  - [x] Update `tindatrack/test/features/settings/presentation/screens/settings_screen_test.dart`.
  - [x] Assert the App Version section renders the canonical `pubspec.yaml` version (`0.1.0+1` at story creation time) or injected package metadata equivalent.
  - [x] Assert stale placeholder text such as `MVP preview` is no longer used as the App Version value.
  - [x] Keep assertions for Currency, Backup / Export, Local Data, MVP exclusion copy, small-phone/high-text-scale layout, and offline app-shell route access.
  - [x] If version loading is async, test the loading/success path without requiring network or platform channels in widget tests.

- [x] Task 5: Verify Story 5.4 completion (AC: 1-3)
  - [x] Run Dart format for touched `lib`, `test`, and config files.
  - [x] Run focused Settings tests.
  - [x] Run `dart analyze`.
  - [x] Run the full Flutter test suite if focused tests and analyzer pass.
  - [x] Run `git diff --check`.

### Review Findings

- [x] [Review][Patch] Pubspec version extraction should only accept the top-level scalar and ignore inline comments [tindatrack/lib/features/settings/presentation/screens/settings_screen.dart:102]

## Dev Notes

### Source Requirements

- Story 5.4 covers FR-040: the app shall show app version information. [Source: `_bmad-output/planning-artifacts/epics.md#Story 5.4: Show App Version From Pubspec`; `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#8. Functional Requirements`]
- Epic 5 goal is Settings and release readiness: users can view basic settings and future backup/export expectations while the MVP receives polish and release-quality safeguards. [Source: `_bmad-output/planning-artifacts/epics.md#Epic 5: Settings And Release Readiness`]
- The architecture explicitly resolves app version display to use `pubspec.yaml` as the canonical source, not hardcoded copy. [Source: `_bmad-output/planning-artifacts/architecture.md#Resolved During Validation`; `_bmad-output/planning-artifacts/architecture.md#Implementation Handoff`]
- The epics summary says app version display should read from `pubspec.yaml`, not hardcoded copy. [Source: `_bmad-output/planning-artifacts/epics.md#Technical Guidance Summary`]
- Settings UX includes an App version item. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Settings`]

### Current System State

- `tindatrack/pubspec.yaml` currently declares `version: 0.1.0+1`.
- `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart` is a synchronous local-only screen.
- The App Version section already exists with `Key('settings-app-version-section')`, title `App Version`, value `MVP preview`, and description `Version details will be shown here before release.`
- `MVP preview` is now stale for Story 5.4 because AC1 requires visible version information from package metadata or `pubspec.yaml`.
- Current Settings tests live in `tindatrack/test/features/settings/presentation/screens/settings_screen_test.dart` and already cover the four sections, MVP exclusion copy, small-phone/high-text-scale layout, and app-shell Settings route access.
- No existing `package_info` or app-version helper is present in `tindatrack/lib` at story creation time.

### Architecture Compliance

- Keep feature code under `tindatrack/lib/features/settings`; shared UI/constants stay under `tindatrack/lib/core`; app routing and shell stay under `tindatrack/lib/app`. [Source: `_bmad-output/planning-artifacts/architecture.md#Project Structure & Boundaries`]
- Settings owns local preferences, app info, and honest backup/export placeholder; it must not own login, cloud sync, scanner, POS, or business rules. [Source: `_bmad-output/planning-artifacts/architecture.md#Feature Responsibility Map`]
- MVP structure must not include login/signup/account feature folders, cloud sync feature folders, POS/cart/checkout feature folders, barcode scanner screen/route/service/dependency, remote API client layer, supplier management, or accounting/profit reports. [Source: `_bmad-output/planning-artifacts/architecture.md#MVP Exclusions Enforced By Structure`]
- Settings screen boundary is `settings_screen.dart`: local preferences and honest backup/export placeholder only. [Source: `_bmad-output/planning-artifacts/architecture.md#UX Flow Boundaries`]
- `pubspec.yaml` is the configuration file for dependencies and assets. [Source: `_bmad-output/planning-artifacts/architecture.md#File Organization Patterns`]

### UX And Layout Guardrails

- Keep Settings single-column, calm, practical, direct, and lightweight for low-end Android phones. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Brand & Style`]
- Use the existing app spacing and modest 8dp component radius pattern; avoid nested cards, decorative floating panels, heavy shadows, and extra routes. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Layout & Spacing`; `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Shapes`]
- Bottom navigation remains fixed to Dashboard, Products, History, and Settings. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Layout & Spacing`]

### Suggested Implementation Shape

- Likely update only:
  - `tindatrack/pubspec.yaml` if choosing to expose it as an asset for runtime reading
  - `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart`
  - `tindatrack/test/features/settings/presentation/screens/settings_screen_test.dart`
- A minimal no-new-package option is to add `pubspec.yaml` as an asset, load it with `rootBundle`, extract the top-level `version:` line, and display that value in the existing App Version section.
- If using async asset loading, keep the App Version row stable and local-only; a short interim value such as `Loading...` is acceptable only if tests cover the final loaded version.
- Avoid adding a new package solely for app version unless there is a clear advantage over the `pubspec.yaml` asset path.
- Avoid YAML parser dependencies for a single top-level `version:` field unless the implementation becomes unsafe without one.

### Testing Requirements

- Add/adjust Settings widget tests to assert:
  - `App Version`
  - canonical version value `0.1.0+1` from `pubspec.yaml` at story creation time
  - no stale App Version value `MVP preview`
  - four Settings sections remain visible
  - Backup / Export still shows honest local-device/no-account/no-internet copy
  - small-phone/high-text-scale Settings regression still passes
  - app-shell Settings route test still passes offline
- If implementation uses `rootBundle`, widget tests may need to pump until the async load completes.
- Do not require platform channels, network access, package metadata plugins, or Android package manager state in focused widget tests.

### Previous Story Intelligence

- Story 5.1 created the synchronous Settings screen and intentionally avoided providers, persistence, network calls, auth, cloud, scanner, POS, supplier, accounting, reporting, and dependency changes.
- Story 5.1 established stable Settings keys:
  - `Key('settings-screen')`
  - `Key('settings-currency-section')`
  - `Key('settings-backup-export-section')`
  - `Key('settings-app-version-section')`
  - `Key('settings-local-data-section')`
- Story 5.2 added `tindatrack/lib/core/formatters/currency_formatter.dart`, updated Settings currency copy to consume `CurrencyFormatter.php()`, and updated product price surfaces. Do not regress those changes.
- Story 5.3 strengthened Backup / Export copy and tests; preserve the no-account/no-internet wording and the broader misleading backup/export phrase guards.
- Story 5.3 review found one AC2 copy gap; the fix was to make required constraints explicit in visible copy and tests. For Story 5.4, make the `pubspec.yaml` source explicit in implementation/tests rather than relying on a hidden hardcoded string.
- Recent verification pattern: focused widget tests, `dart analyze`, full Flutter suite, and `git diff --check`; Flutter commands should run from a Windows temp copy if UNC paths block tooling.

### Git Intelligence

- `2f3c602 Complete Story 5.3 code review`
- `f69878d Implement Story 5.3 backup export placeholder`
- `23eae38 Create Story 5.3 backup export context`
- `06b6e7e Mark Story 5.2 done after review`
- `bf9fd9e Show PHP currency context`
- `1e39a13 Create Story 5.2 currency context`
- `35d06a8 Mark settings story done after review`
- `3bf25f6 Build settings screen`

Recent work favors tightly scoped story files, feature-local widget tests, stable user-visible keys, explicit MVP exclusion assertions, and status-only review completion commits.

### Anti-Scope And Regression Guardrails

- Do not implement release notes, update checks, analytics, crash reporting, telemetry, remote config, or release-channel services.
- Do not add login/account routes, cloud sync, remote API clients, backend URLs, cloud SDKs, or network behavior.
- Do not add Drift schema changes, migrations, settings repositories, providers, persistence tables, or Android permissions for static app-version display.
- Do not alter product, stock, history, dashboard, currency formatter, router, database, generated migrations, or app shell behavior.
- Do not replace the Settings screen or remove stable keys.
- Do not leave `MVP preview` as the App Version value once Story 5.4 is implemented.

### Project Structure Notes

- This story should refine the existing Settings screen, not create new Settings architecture.
- Story 5.5 owns broader MVP polish/accessibility across all screens.
- Story 5.6 owns release-readiness verification.

## Dev Agent Record

### Agent Model Used

Codex GPT-5

### Debug Log References

- 2026-07-23: Red focused Settings test run from `C:\tmp\Inventory-tindatrack-story-5-4-red-0723b` failed as expected because `0.1.0+1` from `pubspec.yaml` was not visible while the UI still showed `MVP preview`.
- 2026-07-23: Focused Settings tests passed from `C:\tmp\Inventory-tindatrack-story-5-4-green-0723a` after loading the app version from the bundled `pubspec.yaml` asset.
- 2026-07-23: Review verification from `C:\tmp\Inventory-tindatrack-story-5-4-verify-0723a` passed: formatter run, focused Settings tests passed, `dart analyze` passed with no issues, full Flutter suite passed with 354 tests, and `git diff --check` passed.
- 2026-07-25: Code review patch verification from `C:\tmp\Inventory-story-5-4-review-fix-0725a` passed: format check, focused Settings tests, `dart analyze`, and full Flutter suite with 355 tests.

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.
- Loaded `pubspec.yaml` as a local Flutter asset and displayed its top-level `version` value in the existing Settings App Version section.
- Replaced stale `MVP preview` app-version copy with canonical version display while preserving Settings keys, sections, Backup / Export copy, PHP currency context, and app-shell behavior.
- Updated focused Settings tests to derive the expected version from `pubspec.yaml` and reject the stale placeholder value.
- Resolved code review patch by extracting only the top-level pubspec version scalar, ignoring inline YAML comments, and returning friendly fallback copy when absent.

### File List

- `_bmad-output/implementation-artifacts/5-4-show-app-version-from-pubspec.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `tindatrack/pubspec.yaml`
- `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart`
- `tindatrack/test/features/settings/presentation/screens/settings_screen_test.dart`

### Change Log

- 2026-07-23: Implemented Story 5.4 app version display from `pubspec.yaml` and marked story ready for review.
- 2026-07-25: Resolved code review patch and marked Story 5.4 done.
