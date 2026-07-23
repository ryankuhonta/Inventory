---
baseline_commit: 06b6e7e4028b0ec21f255ef4055c789dd9b70a8a
---

# Story 5.3: Add Honest Backup/Export Placeholder

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a store owner,
I want to know backup/export is planned but not active yet,
so that I am not misled about data protection.

## Acceptance Criteria

1. Given the user opens Settings, when the Backup/Export item is displayed, then it is clearly labeled as "Coming soon" or equivalent plain copy, and it does not imply that backup is currently active.
2. Given the user taps or views the Backup/Export placeholder, when explanatory copy is shown, then it explains that MVP data is stored locally on the device, and it does not require login or network access.
3. Given MVP scope is enforced, when backup/export placeholder is implemented, then no fake export file, cloud sync service, login route, or remote API client is added, and future backup/export remains a separately scoped feature.

## Tasks / Subtasks

- [x] Task 1: Strengthen the Settings Backup / Export placeholder copy (AC: 1, 2)
  - [x] Update `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart`; do not create a parallel Settings screen or route.
  - [x] Preserve `Key('settings-screen')` and `Key('settings-backup-export-section')`.
  - [x] Keep the section title `Backup / Export` unless there is a strong local UI reason to adjust punctuation only.
  - [x] Keep the value as `Coming soon` or equally plain future-state copy.
  - [x] Update the description so it explicitly says MVP inventory data stays on this device/local device for now.
  - [x] Make the copy honest and Filipino-friendly; avoid jargon like sync provider, remote client, or cloud account.

- [x] Task 2: Add non-fake explanatory behavior only if useful (AC: 2, 3)
  - [x] The current synchronous Settings screen may satisfy "views" with visible row copy; do not add tap behavior unless it improves clarity without scope creep.
  - [x] If adding tap behavior, keep it local-only, such as a Material dialog/bottom sheet with explanatory copy.
  - [x] If a dialog/sheet is added, use stable keys such as `Key('settings-backup-export-details')` and ensure it requires no provider, login, network call, permission, or file picker.
  - [x] Do not add an enabled Export button that creates, downloads, shares, or writes a file.
  - [x] Do not add cloud sync, backup schedule, auth, account setup, remote API, or storage service placeholders that look active.

- [x] Task 3: Preserve existing Settings and app shell behavior (AC: 1-3)
  - [x] Keep the four Settings sections visible: Currency, Backup / Export, App Version, and Local Data.
  - [x] Preserve current PHP currency context from `CurrencyFormatter.php()` and do not change product price behavior.
  - [x] Preserve the existing four-tab app shell: Dashboard, Products, History, Settings.
  - [x] Do not add Drift schema, `app_settings` table, migrations, repositories, or providers for this placeholder unless implementation proves synchronous copy is impossible.
  - [x] Do not add dependencies or Android permissions.

- [x] Task 4: Add focused Settings tests (AC: 1-3)
  - [x] Update `tindatrack/test/features/settings/presentation/screens/settings_screen_test.dart`.
  - [x] Assert the Backup / Export section renders future-state copy and local-device explanatory copy.
  - [x] Assert visible Settings copy does not imply active backup/export, cloud sync, login, account management, remote API, file creation, or export success.
  - [x] If tap behavior is added, test the tap opens only explanatory UI and does not navigate away from Settings.
  - [x] Keep or extend the small-phone/high-text-scale Settings regression so longer placeholder copy does not overflow.
  - [x] Keep the app-shell Settings route test passing offline.

- [x] Task 5: Verify Story 5.3 completion (AC: 1-3)
  - [x] Run Dart format for touched `lib` and `test` files.
  - [x] Run focused Settings tests.
  - [x] Run `dart analyze`.
  - [x] Run the full Flutter test suite if focused tests and analyzer pass.
  - [x] Run `git diff --check`.

## Dev Notes

### Source Requirements

- Story 5.3 covers FR-039: the app shall show backup/export as a future-ready placeholder. [Source: `_bmad-output/planning-artifacts/epics.md#Story 5.3: Add Honest Backup/Export Placeholder`; `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#8. Functional Requirements`]
- Epic 5 goal is Settings and release readiness: users can view basic app settings and future backup/export expectations while the MVP receives polish and safeguards. [Source: `_bmad-output/planning-artifacts/epics.md#Epic 5: Settings And Release Readiness`]
- PRD MVP scope includes a Settings screen with a future-ready backup/export placeholder and local offline data persistence. [Source: `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#6. MVP Scope`]
- PRD out of scope includes login requirement, online account management, real cloud backup, sales reports, multi-branch management, staff permissions, and push notifications. [Source: `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#6. MVP Scope`]
- NFRs require MVP features to work offline and persist data locally after app restart. Story 5.3 must not depend on internet access. [Source: `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#9. Non-Functional Requirements`]
- Settings UX lists a backup/export placeholder and says the item can show `Coming soon`. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Settings`]

### Current System State

- `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart` is a synchronous local-only screen.
- The Backup / Export section already exists with `Key('settings-backup-export-section')`, title `Backup / Export`, value `Coming soon`, and description `A simple file option will be added in a future update.`
- The current copy is not false, but it does not explicitly explain that MVP data stays local/on-device for now, which Story 5.3 requires.
- Current Settings tests live in `tindatrack/test/features/settings/presentation/screens/settings_screen_test.dart`.
- Existing Settings tests already cover the four sections, MVP exclusion copy, small-phone/high-text-scale layout, and app-shell Settings route access.
- There is no `app_settings` Drift table in the current codebase, and this story should not introduce one for static explanatory copy.

### Architecture Compliance

- Keep feature code under `tindatrack/lib/features/settings`; shared UI/constants stay under `tindatrack/lib/core`; app routing and shell stay under `tindatrack/lib/app`. [Source: `_bmad-output/planning-artifacts/architecture.md#Project Structure & Boundaries`]
- Settings owns local preferences, app info, and honest backup/export placeholder; it must not own login, cloud sync, scanner, POS, or business rules. [Source: `_bmad-output/planning-artifacts/architecture.md#Feature Responsibility Map`]
- MVP structure must not include login/signup/account feature folders, cloud sync feature folders, POS/cart/checkout feature folders, barcode scanner screen/route/service/dependency, remote API client layer, supplier management, or accounting/profit reports. [Source: `_bmad-output/planning-artifacts/architecture.md#MVP Exclusions Enforced By Structure`]
- Settings screen boundary is `settings_screen.dart`: local preferences and honest backup/export placeholder only. [Source: `_bmad-output/planning-artifacts/architecture.md#UX Flow Boundaries`]
- Tests should mirror `lib/` paths. [Source: `_bmad-output/planning-artifacts/architecture.md#File Organization Patterns`]

### UX And Layout Guardrails

- Keep Settings single-column, calm, practical, direct, and lightweight for low-end Android phones. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Brand & Style`]
- Use the existing app spacing and modest 8dp component radius pattern; avoid nested cards, decorative floating panels, heavy shadows, and extra routes. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Layout & Spacing`; `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Elevation & Depth`; `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Shapes`]
- Bottom navigation remains fixed to Dashboard, Products, History, and Settings. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Layout & Spacing`]
- Avoid future-login presentation in MVP. The UX notes describe future backup/sign-in as future-ready, not required by default. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Future Login Screen`]

### Suggested Implementation Shape

- Likely update only:
  - `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart`
  - `tindatrack/test/features/settings/presentation/screens/settings_screen_test.dart`
- Minimum implementation can be a copy-only change to the existing `_SettingsSection` for Backup / Export.
- Strong candidate copy:
  - value: `Coming soon`
  - description: `For now, inventory data stays on this device. Backup and export will be added in a future update.`
- If using a tap detail, prefer making `_SettingsSection` accept an optional callback/details affordance rather than adding a new feature layer. Keep it accessible and test it.
- Do not add a fake disabled export flow if plain visible copy satisfies AC 2.

### Testing Requirements

- Update the existing Settings widget test to assert:
  - `Backup / Export`
  - `Coming soon`
  - local/on-device explanatory copy
  - no active export/success/cloud/login/network wording
- Extend the forbidden visible-copy terms carefully. `backup` and `export` are allowed because they are the feature label, but forbidden phrases should include active implications such as `backed up`, `exported`, `sync enabled`, `cloud sync`, `login`, `account management`, `remote api`, and `export complete`.
- Keep the existing small-phone/high-text-scale test because Story 5.3 likely lengthens Settings copy.
- If a dialog/sheet is introduced, test that it appears under a stable key, contains local-only explanatory copy, and does not push a login/export route.
- Verification commands may need to run from a Windows temp copy under `C:\tmp` because Flutter can fail from the UNC workspace.

### Previous Story Intelligence

- Story 5.1 created the synchronous Settings screen and intentionally avoided providers, persistence, network calls, auth, cloud, scanner, POS, supplier, accounting, reporting, and dependency changes.
- Story 5.1 established stable Settings keys:
  - `Key('settings-screen')`
  - `Key('settings-currency-section')`
  - `Key('settings-backup-export-section')`
  - `Key('settings-app-version-section')`
  - `Key('settings-local-data-section')`
- Story 5.2 added `tindatrack/lib/core/formatters/currency_formatter.dart`, updated Settings currency copy to consume `CurrencyFormatter.php()`, and updated product price surfaces. Do not regress those changes.
- Story 5.2 review completed cleanly with no actionable findings; sprint status now marks Story 5.2 done.
- Recent verification pattern: focused widget tests, `dart analyze`, full Flutter suite, and `git diff --check`; Flutter commands should run from a Windows temp copy if UNC paths block tooling.

### Git Intelligence

- `06b6e7e Mark Story 5.2 done after review`
- `bf9fd9e Show PHP currency context`
- `1e39a13 Create Story 5.2 currency context`
- `35d06a8 Mark settings story done after review`
- `3bf25f6 Build settings screen`
- `1f9a956 Complete Epic 4 dashboard hardening`
- `4683c97 Create Story 4.6 dashboard test protection`
- `b830427 Fix Story 4.5 review findings`

Recent work favors tightly scoped story files, feature-local widget tests, stable user-visible keys, explicit MVP exclusion assertions, and status-only review completion commits.

### Anti-Scope And Regression Guardrails

- Do not implement actual backup or export.
- Do not create/share/write/download a file.
- Do not add file picker/share plugins, storage permissions, Android manifest changes, or dependency changes.
- Do not add cloud sync, remote API clients, backend URLs, auth/login/account routes, cloud SDKs, or sync status indicators.
- Do not add Drift schema changes, migrations, settings repositories, or providers for static explanatory copy.
- Do not alter product, stock, history, dashboard, currency formatter, router, or app shell behavior.
- Do not imply data is protected by backup today; the point is honest future-state copy.

### Project Structure Notes

- This story should refine the existing Settings screen, not create new Settings architecture.
- Story 5.4 owns reading the installed app version from package metadata or `pubspec.yaml`.
- Story 5.5 owns broader MVP polish/accessibility across all screens.
- Story 5.6 owns release-readiness verification.

## Dev Agent Record

### Agent Model Used

Codex GPT-5

### Debug Log References

- 2026-07-23: Red focused Settings test run from `C:\tmp\Inventory-tindatrack-story-5-3-red-0723a` failed on missing local-device Backup / Export explanatory copy.
- 2026-07-23: Focused Settings tests passed from `C:\tmp\Inventory-tindatrack-story-5-3-green-0723a`.
- 2026-07-23: Formatted touched Settings files from the workspace; formatter reported 0 changed files.
- 2026-07-23: Focused Settings tests passed from `C:\tmp\Inventory-tindatrack-story-5-3-verify-0723a`.
- 2026-07-23: `dart analyze` passed from `C:\tmp\Inventory-tindatrack-story-5-3-verify-0723a` with no issues.
- 2026-07-23: Full Flutter test suite passed from `C:\tmp\Inventory-tindatrack-story-5-3-verify-0723a` with 354 tests.

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.
- Strengthened the Settings Backup / Export placeholder with explicit local-device MVP data copy.
- Preserved the synchronous local-only Settings screen, stable Settings keys, PHP currency context, and four-tab app shell.
- Avoided export files, cloud sync, login/account routes, remote API clients, dependencies, Android permissions, providers, persistence, and Drift schema changes.
- Updated Settings widget tests to assert honest Backup / Export copy, active-scope exclusions, small-phone/high-text-scale behavior, and offline app-shell access.

### File List

- `_bmad-output/implementation-artifacts/5-3-add-honest-backup-export-placeholder.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart`
- `tindatrack/test/features/settings/presentation/screens/settings_screen_test.dart`

### Change Log

- 2026-07-23: Implemented Story 5.3 honest Backup / Export placeholder and focused Settings tests; marked story ready for review.