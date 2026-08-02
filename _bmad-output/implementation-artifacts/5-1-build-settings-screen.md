---
baseline_commit: 4683c9762797d6a31e8dbc5f9f4f08fe6a973d80
---

# Story 5.1: Build Settings Screen

Status: done

## Story

As a store owner,
I want to see basic app settings,
so that I understand the app's local setup and future options.

## Acceptance Criteria

1. Given the user opens Settings, when the screen loads, then it shows basic settings sections for currency, backup/export, app version, and local data/privacy note where appropriate, and the screen works without internet.
2. Given MVP scope is enforced, when Settings is implemented, then it does not require login, and it does not expose fake cloud sync, account management, supplier, POS, barcode scanner, or accounting settings.
3. Given Settings data is unavailable or fails to load, when the screen displays an error state, then the app shows friendly recovery copy, and raw technical errors are not shown.

## Tasks / Subtasks

- [x] Task 1: Replace the Settings placeholder with a real Settings root screen (AC: 1-3)
  - [x] Update `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart`; do not create a parallel Settings route or feature root.
  - [x] Preserve `Key('settings-screen')`.
  - [x] Keep the existing four-tab app shell and `AppRoute.settings` route unchanged.
  - [x] Use a single-column Android layout with `AppSpacing`, `AppDimensions.componentRadius`, and Material theme colors.

- [x] Task 2: Render MVP-safe Settings sections (AC: 1, 2)
  - [x] Show a clear screen title such as `Settings`.
  - [x] Add visible sections/rows for `Currency`, `Backup / Export`, `App Version`, and `Local Data`.
  - [x] For this story, show stable placeholder values/copy only where later stories own the exact behavior:
    - Currency can show `PHP` or `Philippine Peso`; Story 5.2 owns central formatting behavior.
    - Backup / Export can show `Coming soon`; Story 5.3 owns the fuller honest placeholder flow/copy.
    - App Version can show a temporary non-misleading value only if needed for UI structure; Story 5.4 owns reading from `pubspec.yaml` or package metadata.
    - Local Data should explain that inventory data is stored on this device for MVP.
  - [x] Keep copy plain, helpful, and Filipino-friendly English.

- [x] Task 3: Enforce MVP exclusions in visible Settings UI (AC: 2)
  - [x] Do not add login, account, cloud sync, staff roles, supplier, POS, barcode scanner, accounting, reporting, remote API, or fake export behavior.
  - [x] Do not add new dependencies, network calls, permissions, backend clients, cloud SDKs, scanner SDKs, or auth routes.
  - [x] Do not add schema changes for Story 5.1 unless implementation proves a simple local read model is impossible without them; static/read-only Settings content should not need Drift changes.

- [x] Task 4: Add friendly loading/error seams only if Settings uses async data (AC: 1, 3)
  - [x] Prefer simple synchronous presentation for Story 5.1 if all values are static placeholders.
  - [x] If a provider/repository is introduced, widgets must consume providers and show `AppLoadingView`/`AppErrorView` or an equivalent shared pattern.
  - [x] Error copy must not expose raw exceptions, SQL, Drift, stack traces, file paths, or package internals.
  - [x] Add a Retry action only when there is real data to re-read.

- [x] Task 5: Add focused Settings tests (AC: 1-3)
  - [x] Add `tindatrack/test/features/settings/presentation/screens/settings_screen_test.dart`.
  - [x] Test the Settings screen renders the title and all four MVP sections.
  - [x] Test the visible copy does not include forbidden future-scope terms implying active support, such as login, cloud sync, account management, supplier, POS, barcode scanner, accounting, or active export.
  - [x] Test small-phone/high-text-scale rendering for the populated Settings screen.
  - [x] Add an app-shell or router test proving the Settings tab/route still opens the Settings branch offline with local widget/provider overrides only.
  - [x] If an error state is implemented, test friendly recovery copy and assert raw diagnostics are not visible.

- [x] Task 6: Verify Story 5.1 completion (AC: 1-3)
  - [x] Run Dart format for touched `lib` and `test` files.
  - [x] Run focused Settings tests.
  - [x] Run `dart analyze`.
  - [x] Run the full Flutter test suite if focused tests and analyzer pass.
  - [x] Run `git diff --check`.

## Dev Notes

### Source Requirements

- Story 5.1 covers FR-037, FR-038, FR-039, FR-040, and UX-DR24. [Source: `_bmad-output/planning-artifacts/epics.md#Story 5.1: Build Settings Screen`]
- Epic 5 goal: users can view basic app settings and future backup/export expectations while MVP receives polish and release-quality safeguards. [Source: `_bmad-output/planning-artifacts/epics.md#Epic 5: Settings And Release Readiness`]
- PRD scope includes a Settings screen with a future-ready backup/export placeholder and local offline persistence. [Source: `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#6. MVP Scope`]
- MVP excludes login, online account management, cloud backup/sync, supplier management, barcode scanning, POS, and accounting/reporting. [Source: `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#4. Non-Goals For MVP`]
- Settings UX content includes business name placeholder future, currency PHP, backup/export placeholder, app version, and privacy/data note future. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Settings`]
- Backup/export item can show `Coming soon`. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Settings`]

### Current System State

- `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart` is a placeholder that renders `Settings` and `Settings are coming in a later story.`
- `SettingsScreen` is already wired into the app router through `AppRoute.settings.path` (`/settings`) and the fourth `StatefulShellRoute` branch.
- There are no existing Settings tests under `tindatrack/test/features/settings`.
- There is no current `app_settings` Drift table in `tindatrack/lib/core/database/tables`; Story 5.1 should not introduce persistence unless the implementation truly needs it.
- Shared UI helpers already exist:
  - `tindatrack/lib/core/widgets/app_loading_view.dart`
  - `tindatrack/lib/core/widgets/app_error_view.dart`
  - `tindatrack/lib/core/widgets/app_empty_state.dart`
  - `tindatrack/lib/core/ui/app_spacing.dart`
  - `tindatrack/lib/core/ui/app_dimensions.dart`

### Architecture Compliance

- Use Flutter Material 3, Riverpod only if state is needed, and go_router's existing `AppRoute.settings` route. [Source: `_bmad-output/planning-artifacts/architecture.md#Frontend Architecture`]
- Keep feature code under `tindatrack/lib/features/settings`; shared UI stays in `tindatrack/lib/core`; app shell/routing stays in `tindatrack/lib/app`. [Source: `_bmad-output/planning-artifacts/architecture.md#Project Structure Patterns`]
- MVP has no required authentication and no fake login screen. Future authentication can be added for cloud backup/sync later, but must not block local-only usage. [Source: `_bmad-output/planning-artifacts/architecture.md#Authentication & Security`]
- MVP has no remote API, no backend hosting, and no cloud database. [Source: `_bmad-output/planning-artifacts/architecture.md#API & Communication Patterns`]
- Do not expose raw database errors directly to users; use plain-language error mapping at the presentation boundary. [Source: `_bmad-output/planning-artifacts/architecture.md#Local Data Protection`]
- `flutter_secure_storage` is reserved for future secrets such as cloud tokens, not normal inventory records. Do not add it for Story 5.1. [Source: `_bmad-output/planning-artifacts/architecture.md#Local Data Protection`]
- Drift schema changes require a version bump, migration, migration test, and data preservation check. Story 5.1 should avoid schema changes because basic Settings content can be presentational. [Source: `_bmad-output/planning-artifacts/architecture.md#Rules`]

### UX And Layout Guardrails

- Primary navigation remains Dashboard, Products, History, Settings. Do not add more than four primary tabs. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Bottom Navigation`]
- Voice should be plain, helpful, and action-oriented. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Voice And Tone`]
- Screens use a single-column mobile layout with 16dp outer padding, 8dp related-control spacing, and 16-24dp between sections. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Layout & Spacing`]
- Keep the UI practical, readable, calm, and lightweight for low-end Android phones. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Brand & Style`]
- Avoid nested cards, decorative gradients, heavy shadows, and decorative floating panels. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Elevation & Depth`]
- Common tap targets should meet the 48dp accessibility floor where applicable. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Components`]
- Avoid viewport-scaled text and negative letter spacing. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Typography`]

### Suggested Implementation Shape

- Update:
  - `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart`
- Add:
  - `tindatrack/test/features/settings/presentation/screens/settings_screen_test.dart`
- Optional private widgets inside `settings_screen.dart` are fine:
  - `_SettingsContent`
  - `_SettingsSection`
  - `_SettingsRow`
- Suggested stable keys:
  - `Key('settings-screen')`
  - `Key('settings-currency-section')`
  - `Key('settings-backup-export-section')`
  - `Key('settings-app-version-section')`
  - `Key('settings-local-data-section')`
  - `Key('settings-error-state')` only if an error state exists

### Testing Requirements

- Widget tests should wrap `SettingsScreen` in `MaterialApp` and use the app theme/test helpers if existing tests provide them.
- Add a small-screen/high-text-scale test similar to Dashboard/Product/History regressions so long Settings copy does not overflow.
- App-shell Settings navigation can be tested through `createAppRouter` or existing root app test style; no network, login, cloud, or remote service should be needed.
- If Story 5.1 stays synchronous/static, do not invent provider tests. If providers are introduced, add provider tests and deterministic overrides.
- Verification commands in this project often run from a Windows temp copy under `C:\tmp` because Flutter commands can fail from the UNC workspace.

### Previous Story Intelligence

- Story 4.6 completed Dashboard regression hardening with focused repository/provider/widget/app-shell tests and full-suite verification.
- Story 4.6 review fixes emphasized deterministic time/provider seams and app-shell tests that prove user-visible behavior, not only widget state.
- Epic 4 retrospective action items for Epic 5:
  - Preserve honest local-only Settings scope.
  - Reuse friendly state patterns.
  - Centralize currency/version behavior in Stories 5.2 and 5.4.
  - Carry Dashboard accessibility guardrails into MVP polish.
  - Keep deterministic async overrides in app-level tests.
- Do not regress the four-tab app shell or Dashboard/Products/History behavior while replacing the Settings placeholder.

### Git Intelligence

- `4683c97 Create Story 4.6 dashboard test protection`
- `b830427 Fix Story 4.5 review findings`
- `684d8b5 Complete Story 4.5 dashboard recent activity`
- `21e15db Create Story 4.5 recent activity preview`
- `33083d4 Fix Story 4.4 low-stock filter consistency`

Recent work keeps feature code under `tindatrack/lib/features/{feature}`, mirrors tests under `tindatrack/test/features/{feature}`, uses stable widget keys for user-visible states, and verifies Flutter from a Windows temp copy when UNC tooling blocks direct commands.

### Library And Framework Requirements

- Use current project dependencies only:
  - Dart SDK `^3.12.0`
  - Flutter Material
  - `flutter_riverpod ^3.3.2` only if state/provider seams are needed
  - `go_router ^17.3.0` through existing app routing only
  - `flutter_test`
  - `very_good_analysis ^10.2.0`
- Do not add dependencies for app version, package metadata, storage, auth, cloud, backup/export, barcode scanning, POS, or settings persistence in Story 5.1.
- No web research or dependency upgrade is needed for this story; current pinned local dependencies are sufficient.

### Project Structure Notes

- This story should make Settings visible and useful, but it should not fully implement later Epic 5 stories.
- Story 5.2 owns centralized PHP currency formatting.
- Story 5.3 owns the fuller honest backup/export placeholder behavior.
- Story 5.4 owns app version sourcing from package metadata or `pubspec.yaml`.
- Story 5.5 owns app-wide UX polish/accessibility pass.
- Story 5.6 owns release-readiness verification.
- Avoid creating `features/settings/data` or `features/settings/domain` unless the implementation introduces real data. A presentational Settings screen can remain under `features/settings/presentation`.

## Dev Agent Record

### Agent Model Used

Codex GPT-5

### Debug Log References

- 2026-07-20: Red test run from `C:\tmp\Inventory-tindatrack-story-5-1-red2` failed against the placeholder because required Settings section keys/content were missing.
- 2026-07-20: Formatted touched Dart files from temp verification copy.
- 2026-07-20: Focused Settings tests passed from `C:\tmp\Inventory-tindatrack-story-5-1-verify2`.
- 2026-07-20: `dart analyze` passed from `C:\tmp\Inventory-tindatrack-story-5-1-verify2` with no issues.
- 2026-07-20: Full Flutter test suite passed from `C:\tmp\Inventory-tindatrack-story-5-1-verify2`.
- 2026-07-20: `git diff --check` passed from the workspace.

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.
- Replaced the Settings placeholder with a synchronous local-only Settings screen using app spacing, component radius, and Material theme colors.
- Added MVP-safe Currency, Backup / Export, App Version, and Local Data sections with stable keys and plain Filipino-friendly English copy.
- Avoided providers, persistence, network calls, auth, cloud, scanner, POS, supplier, accounting, reporting, and dependency changes for Story 5.1.
- Added focused widget coverage for section rendering, MVP exclusion copy, small-phone/high-text-scale layout, and existing app-shell Settings route access.

### File List

- `_bmad-output/implementation-artifacts/5-1-build-settings-screen.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart`
- `tindatrack/test/features/settings/presentation/screens/settings_screen_test.dart`

### Change Log

- 2026-07-20: Implemented Story 5.1 Settings screen and focused tests; marked story ready for review.