---
baseline_commit: eb878cb81f8039bdd0fe175a53716baf37de2ece
---

# Story 1.4: Add Main Navigation Shell

Status: done

<!-- Note: Validation is optional. Run validate-create-story for an independent readiness check before dev-story. -->

## Story

As a store owner,
I want simple navigation between Dashboard, Products, History, and Settings,
so that I can move around the inventory app without confusion.

## Acceptance Criteria

1. **Given** local initialization is still loading or has failed  
   **When** the root application renders  
   **Then** the Story 1.3 splash or retry state is shown before main navigation  
   **And** no bottom navigation destination or shell content is exposed until bootstrap succeeds.

2. **Given** local initialization succeeds and the app shell loads  
   **When** the user views the main app  
   **Then** a fixed Material navigation bar shows exactly four destinations in this order: Dashboard, Products, History, and Settings  
   **And** all four labels remain visible.

3. **Given** the user selects Dashboard, Products, History, or Settings  
   **When** a navigation destination is tapped  
   **Then** `go_router` activates the matching named branch and placeholder screen  
   **And** the selected destination is visually clear from router-owned shell state.

4. **Given** the user switches repeatedly between primary sections  
   **When** a previously visited destination is selected again  
   **Then** each branch preserves its own navigator state  
   **And** reselecting the already active destination returns that branch to its initial location without creating a duplicate route.

5. **Given** the user navigates among the four sections  
   **When** tab changes, reselection, or Android Back handling occurs  
   **Then** bootstrap is not rerun, the app database is not reopened or closed, and the router is not recreated  
   **And** default `go_router` branch/back behavior is preserved without custom tab-history interception.

6. **Given** MVP navigation is reviewed  
   **When** the route configuration and placeholder screens are inspected  
   **Then** the route table contains only the Dashboard, Products, History, and Settings branch roots introduced by this story  
   **And** no login, account, barcode scanner, cloud sync, POS, supplier, accounting, backup/export, product-detail, stock-movement, or other future route/feature is exposed.

7. **Given** Story 1.4 implementation is complete  
   **When** quality checks run  
   **Then** focused router/navigation widget tests, all Story 1.3 bootstrap/lifecycle regressions, strict formatting, Flutter analysis, and an Android debug build pass  
   **And** no dependency, permission, Drift schema, DAO, migration, or generated database change is introduced.

## Tasks / Subtasks

- [x] Preserve the completed Story 1.3 baseline and bound Story 1.4 scope (AC: 1, 5, 6, 7)
  - [x] Treat the current uncommitted Story 1.3 implementation and review fixes as existing user work; do not reset, rewrite, stage, or claim them as Story 1.4 work.
  - [x] Preserve `ProviderScope`, bootstrap readiness, safe retry, serialized database close-before-reopen, app title, disabled debug banner, Android-only output, and `com.rkuhonta.tindatrack`.
  - [x] Add no packages; use the already resolved `go_router 17.3.0` and Flutter Material 3 `NavigationBar`.
  - [x] Do not add feature data, repositories, use cases, forms, search, summaries, settings values, backup UI, final theme tokens, shared base-state components, network code, permissions, or future routes.

- [x] Add explicit route names and the stateful router configuration (AC: 2-6)
  - [x] Add `lib/app/router/app_routes.dart` with canonical names and absolute branch-root paths for `/dashboard`, `/products`, `/history`, and `/settings`.
  - [x] Add `lib/app/router/app_router.dart` with a testable router factory and an app-scoped Riverpod provider that creates one `GoRouter`, starts at Dashboard, and disposes it with the root provider scope.
  - [x] Use `StatefulShellRoute.indexedStack` with exactly four `StatefulShellBranch` instances in the canonical destination order.
  - [x] Give each branch a stable navigator key and one named root route. Do not add bootstrap to the route table; bootstrap remains a root builder gate outside router destinations.
  - [x] Do not recreate the router when `bootstrapProvider`, `databaseProvider`, or tab state changes.

- [x] Build the app-owned navigation shell (AC: 2-5)
  - [x] Add `lib/app/navigation/app_shell.dart`; it owns the shell `Scaffold`, router child, and bottom `NavigationBar`.
  - [x] Configure exactly four `NavigationDestination` entries with familiar Material icons and labels: Dashboard, Products, History, Settings.
  - [x] Keep labels always visible and derive `selectedIndex` only from `StatefulNavigationShell.currentIndex`; do not maintain a second mutable tab index.
  - [x] Switch destinations through `navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex)`.
  - [x] Do not add custom `PopScope`, manual tab-history stacks, transition packages, badges, FABs, drawers, top-level actions, or theme polish.

- [x] Integrate routing with the existing bootstrap gate without nested apps (AC: 1, 3, 5)
  - [x] Convert the root app to one `MaterialApp.router` using the app-scoped router.
  - [x] Use `MaterialApp.router.builder` so the existing launch gate wraps the router child: loading/failure hides shell content; bootstrap success reveals the router child.
  - [x] Update `_LaunchGate` to accept and return the router child on `Success<void>` instead of directly constructing `DashboardScreen`.
  - [x] Preserve retry behavior exactly: retry may rotate database/bootstrap providers but must not invalidate or recreate the router.
  - [x] Ensure router/shell widgets do not read Drift directly and tab switches never trigger database lifecycle operations.

- [x] Add only skeletal feature-owned branch screens (AC: 2, 3, 6)
  - [x] Keep the existing `DashboardScreen` as the Dashboard branch root; do not add Epic 4 content.
  - [x] Add a Products placeholder under `lib/features/products/presentation/screens/` with only a clear Products identity and neutral placeholder copy; do not implement Story 2.x behavior.
  - [x] Add a History placeholder under `lib/features/history/presentation/screens/` with only a clear History identity and neutral placeholder copy; do not add movement schema/query/history-state behavior.
  - [x] Add a Settings placeholder under `lib/features/settings/presentation/screens/` with only a clear Settings identity and neutral placeholder copy; do not add PHP currency, backup/export, app version, preferences, or privacy content.
  - [x] Feature screens must not own, duplicate, or configure the bottom navigation shell.

- [x] Add focused router and navigation tests (AC: 1-7)
  - [x] Preserve all Story 1.3 splash, failure, retry, close-before-reopen, programming-error, and provider-disposal tests.
  - [x] Verify pending and failed bootstrap states show no `NavigationBar` or main-section content.
  - [x] Verify successful bootstrap initially shows Dashboard, exactly four visible labels, and selected index `0`.
  - [x] Tap Products, History, Settings, and Dashboard; verify the matching placeholder, router location/name, and selected indexes `1`, `2`, `3`, and `0`.
  - [x] Verify exactly one destination is selected and only the active branch content is visible.
  - [x] Verify reselecting an active destination creates no duplicate route and keeps the correct branch root.
  - [x] Verify branch state survives switching away and back using a deterministic stateful/scroll test seam rather than relying only on text.
  - [x] Verify direct router initialization at each authorized root maps to the matching selected index when testing the router independently of bootstrap.
  - [x] Verify tab taps/reselection do not rerun bootstrap, recreate the database, close the database, or replace the router instance.
  - [x] Verify the declared route-name/path set contains no excluded MVP/future route.

- [x] Run regression and Android build verification (AC: 1-7)
  - [x] Run `dart format --output=none --set-exit-if-changed .`.
  - [x] Run `flutter analyze`.
  - [x] Run `flutter test --reporter expanded`.
  - [x] Run `flutter build apk --debug`.
  - [x] If an Android target is attached, manually confirm offline splash -> Dashboard shell and all four tab changes; otherwise record the check as not run rather than checking it complete.
  - [x] Record exact commands, effective versions, test count, build result, and UNC mirror use in the Dev Agent Record.

### Review Findings

- [x] [Review][Patch] Add Android Back regression coverage proving default router behavior does not rerun bootstrap, replace/close the database, or recreate the router [tindatrack/test/widget_test.dart:205]
- [x] [Review][Patch] Strengthen failed-bootstrap isolation coverage to assert that no branch screen or main-section content is exposed [tindatrack/test/widget_test.dart:63]
- [x] [Review][Patch] Make the router-stability test capable of detecting provider-driven router recreation instead of overriding the provider with a fixed value [tindatrack/test/widget_test.dart:211]
- [x] [Review][Defer] A database close that hangs, throws, or completes with a Dart `Error` can strand retry in a disabled state [tindatrack/lib/app/app.dart:68] — deferred, pre-existing Story 1.3 lifecycle behavior
- [x] [Review][Defer] `closeManagedDatabase` permanently caches a rejected close future, preventing a later close attempt from recovering [tindatrack/lib/app/providers.dart:40] — deferred, pre-existing shared lifecycle helper

## Dev Notes

### Developer Context

Stories 1.1-1.3 established the Android app, app/core/feature boundaries, local services, and a tested bootstrap/retry gate. Story 1.4 adds only the permanent main navigation structure. It must not replace bootstrap with a route redirect, nest another `MaterialApp`, or let tab selection own database lifecycle.

The approved composition is:

```text
ProviderScope
`-- MaterialApp.router
    `-- builder: LaunchGate(routerChild)
        |-- loading -> TindaTrack splash
        |-- failure -> safe retry state
        `-- success -> StatefulShellRoute router child
            `-- AppShell + NavigationBar
                |-- Dashboard branch
                |-- Products branch
                |-- History branch
                `-- Settings branch
```

`MaterialApp.router.builder` keeps splash/failure outside the route table while preserving exactly one root Material app. The router must be a stable app-scoped object; rebuilding bootstrap state must not recreate it.

### Story Boundaries

- **Story 1.4 owns:** route constants, app router, four stateful branches, app shell, four labeled destinations, and skeletal section placeholders.
- **Story 1.5 owns:** final design tokens, theme, typography, spacing, reusable state widgets, and accessibility polish beyond standard Material behavior.
- **Epic 2 owns Products:** tables/repositories, Add/Edit/List/Search/Archive, status badges, and product actions.
- **Epic 3 owns History/Stock:** stock screens, movement persistence, and history content.
- **Epic 4 owns Dashboard:** summaries, low-stock preview, activity, and Dashboard empty states/actions.
- **Epic 5 owns Settings:** PHP context, backup/export placeholder, app version, and privacy/settings content.

The UX document mentions a Future Login destination, but the later Architecture/Epics decision is authoritative: no login route or UI exists in MVP.

### Current Files To Update

#### `tindatrack/lib/app/app.dart`

- **Current state:** one `MaterialApp` wraps a private Riverpod launch gate. Loading and failure render splash/retry; success directly renders `DashboardScreen`. Retry serializes database close, invalidates database/bootstrap providers, and guards duplicate taps.
- **This story changes:** convert to `MaterialApp.router`, read a stable router, pass the router child into the launch gate through `builder`, and return that child on bootstrap success.
- **Must preserve:** every loading/failure/retry behavior, `TindaTrack`, `debugShowCheckedModeBanner: false`, failure mapping, duplicate-tap protection, close-before-reopen ordering, and no raw technical UI errors.
- **Must avoid:** nested `MaterialApp`, router creation inside `build`, router invalidation during retry, or navigating from bootstrap through a fake/auth route.

#### `tindatrack/lib/app/providers.dart`

- **Current state:** owns lazy/disposable database, ID generator, UTC clock, and shared close completion.
- **This story changes:** normally none unless router provider placement is deliberately centralized here; prefer router ownership in `app/router/app_router.dart`.
- **Must preserve:** database lifecycle tests and the rule that navigation cannot close or recreate the database.

#### `tindatrack/lib/features/dashboard/presentation/screens/dashboard_screen.dart`

- **Current state:** skeletal Dashboard `Scaffold` with `Dashboard` and `Offline inventory tracker`.
- **This story changes:** normally none; use it as the Dashboard branch root.
- **Must preserve:** no real Dashboard data, actions, queries, cards, or Epic 4 behavior.

#### `tindatrack/test/widget_test.dart`

- **Current state:** contains Story 1.3 launch-state, retry, duplicate-tap, and database-rotation widget tests.
- **This story changes:** adapt successful bootstrap expectations for the shell and add navigation regression coverage.
- **Must preserve:** all launch/error/retry/lifecycle assertions. Tests must continue using provider overrides and in-memory Drift, never the production Android database.

### Technical Requirements

- Use existing Flutter `3.44.0`, Dart `3.12.x`, Riverpod `3.3.2`, and `go_router 17.3.0`; do not upgrade dependencies.
- Use `StatefulShellRoute.indexedStack`, not a plain `ShellRoute` or manual `IndexedStack`, because each primary section needs a separate persistent navigator branch for future nested routes.
- Use four absolute branch roots: `/dashboard`, `/products`, `/history`, `/settings`.
- Use named routes and centralized constants/enum values; widgets must not scatter raw path strings.
- Initial shell location is Dashboard.
- `StatefulNavigationShell.currentIndex` is the selected-state source of truth.
- Active-tab reselection calls `goBranch` with `initialLocation: true`; other tab selections restore the branch's last location.
- Do not intercept Android Back to cycle tabs. Default router behavior should pop a future nested route in the active branch; at a branch root, platform Back may exit.
- Use standard Material icons and `NavigationBar`/`NavigationDestination`; Story 1.5 will apply approved colors, typography, sizes, and final visual polish.
- Keep the router alive for the root provider scope and dispose it once. A Riverpod `Provider<GoRouter>` with `ref.onDispose(router.dispose)` or equivalent testable root ownership is preferred.
- Let the router factory accept optional branch-root builders/widgets for tests while defaulting to production placeholders. This provides a deterministic seam for proving branch-state preservation without adding test-only production routes.
- No database/schema/codegen action is required. Do not run or alter Drift migrations unless an unrelated defect is discovered and separately scoped.

### Architecture Compliance

- `lib/app/router`: route identities and `GoRouter` construction.
- `lib/app/navigation`: app shell and bottom navigation.
- `lib/app/app.dart`: root Material/router/bootstrap composition.
- `lib/features/{feature}/presentation/screens`: branch-root placeholder owned by each feature.
- Feature screens may depend on Flutter presentation APIs but must not configure app routing or own the persistent navigation bar.
- Router and shell must not import Drift/database infrastructure.
- `core` must not import app navigation or features.

### Library And Framework Requirements

| Package | Current resolved version | Story 1.4 use |
| --- | --- | --- |
| `go_router` | `17.3.0` | Named routes, `StatefulShellRoute.indexedStack`, branch navigation, router lifecycle |
| `flutter_riverpod` | `3.3.2` | App-scoped router creation/disposal and existing bootstrap state |
| Flutter Material | SDK 3.44.0 | `MaterialApp.router`, `NavigationBar`, `NavigationDestination`, standard icons |
| `drift` / `drift_flutter` | `2.34.0` / `0.3.0` | Existing bootstrap only; no Story 1.4 persistence changes |

Do not add auto_route, beamer, another router, another state manager, navigation code generation, transition packages, connectivity packages, or feature SDKs.

### File Structure Requirements

Expected new or updated files are approximately:

```text
tindatrack/
|-- lib/
|   |-- app/
|   |   |-- app.dart
|   |   |-- navigation/
|   |   |   `-- app_shell.dart
|   |   `-- router/
|   |       |-- app_router.dart
|   |       `-- app_routes.dart
|   `-- features/
|       |-- dashboard/presentation/screens/dashboard_screen.dart
|       |-- products/presentation/screens/product_list_screen.dart
|       |-- history/presentation/screens/movement_history_screen.dart
|       `-- settings/presentation/screens/settings_screen.dart
`-- test/
    |-- app/
    |   |-- navigation/app_shell_test.dart
    |   `-- router/app_router_test.dart
    `-- widget_test.dart
```

This is guidance, not permission to create final feature-layer forests. Add only the directories/files with meaningful Story 1.4 code.

### Testing Requirements

- Build router tests from a fresh router instance and dispose it after each test.
- Test selected state through `NavigationBar.selectedIndex` and route state, not icon color.
- Keep labels visible in tests and assert exactly one of each canonical label.
- Use deterministic test seams for branch-state preservation; do not depend on animations or arbitrary delays.
- Do not use `pumpAndSettle` while an intentionally pending bootstrap future or indefinite progress indicator remains active.
- Verify router identity and bootstrap/database call counts across tab switches.
- Keep production database/plugins out of widget/router tests through overrides.
- Preserve all 23 Story 1.3 tests; the final total should increase.
- Platform deep-link configuration and browser URL behavior are out of scope because the Android manifest does not expose browsable deep links in this story.

### Previous Story Intelligence

- Story 1.3's provider waits for a real Drift readiness query and maps only `Exception` values to `PersistenceFailure`; programming `Error`s escape.
- Bootstrap retry is stateful, guards rapid taps, awaits a shared database-close future, then invalidates database/bootstrap providers.
- Navigation must not call or duplicate `closeManagedDatabase`.
- Story 1.3 code review found and fixed a close/reopen race. Recreating the router or moving bootstrap into branch navigation would reintroduce lifecycle risk.
- The existing successful bootstrap branch currently constructs `DashboardScreen` directly. Story 1.4 should replace only that success output with the router child.
- All 23 tests, strict formatting, Flutter analysis, and Android debug build passed after Story 1.3 review.
- A live offline device check was not run because no Android target was attached; do not mark future manual checks complete unless actually executed.
- Windows Flutter tooling cannot run from the UNC workspace. Use a disposable `C:\tmp` mirror for verification while keeping repository files authoritative.
- Deferred shared work remains out of scope: handling asynchronous database-close errors and reviewing transitive EOL SQLite compatibility packages.

### Git Intelligence Summary

- Current branch remains `codex/complete-stories-1-1-and-1-2`; HEAD is `eb878cb Complete Flutter foundation stories`.
- Completed Story 1.3 implementation, review fixes, story record, deferred-work update, and sprint update are still uncommitted in the working tree.
- Because HEAD predates Story 1.3, a Story 1.4 diff against HEAD would include both stories. Prefer committing Story 1.3 before Dev Story 1.4 if the user authorizes it; otherwise preserve and clearly separate the existing file set in the Dev Agent Record and code review.
- Do not reset, clean, checkout, or overwrite the dirty worktree. Existing changes are the working baseline.
- Recent committed patterns use strict analysis, mirrored tests, Riverpod provider overrides, in-memory Drift, and Android debug build validation.

### Latest Technical Information

- `go_router 17.3.0` is the current resolved and published package version as of 2026-06-21.
- Official `go_router` documentation describes `StatefulShellRoute` as separate navigators for parallel branches and recommends `StatefulShellRoute.indexedStack` as the default implementation suitable for most persistent bottom-navigation use cases.
- `StatefulNavigationShell.currentIndex` exposes the active branch, and `goBranch(index, initialLocation: ...)` switches/restores branch navigation state.
- Flutter's Material 3 `NavigationBar` is the persistent primary-destination component; it uses `NavigationDestination` entries and a `selectedIndex`.
- `go_router` is considered feature-complete, so this story should use its stable APIs rather than inventing custom navigation infrastructure.

### Project Structure Notes

- The architecture explicitly assigns app-level navigation ownership to `lib/app/navigation/app_shell.dart`.
- The route table should include only the four root branches in this story. Later stories add nested routes when their screens actually exist.
- Creating skeletal Products, History, and Settings roots is required for navigation acceptance, but their business content remains deferred.
- No `project-context.md` exists; finalized planning artifacts, Story 1.3, current source, and Git state are authoritative.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story-14-Add-Main-Navigation-Shell]
- [Source: _bmad-output/planning-artifacts/epics.md#Story-15-Apply-MVP-Theme-And-Base-UI-States]
- [Source: _bmad-output/planning-artifacts/architecture.md#Frontend-Architecture]
- [Source: _bmad-output/planning-artifacts/architecture.md#Project-Structure--Boundaries]
- [Source: _bmad-output/planning-artifacts/architecture.md#UX-Flow-Boundaries]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Information-Architecture]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Bottom-Navigation]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Layout--Spacing]
- [Source: _bmad-output/planning-artifacts/implementation-readiness-report-2026-06-01.md#UX-To-Architecture-Alignment]
- [Source: _bmad-output/implementation-artifacts/1-3-provide-offline-app-launch-and-splash-initialization.md#Previous-Story-Intelligence]
- [go_router 17.3.0](https://pub.dev/packages/go_router)
- [StatefulShellRoute API](https://pub.dev/documentation/go_router/latest/go_router/StatefulShellRoute-class.html)
- [StatefulNavigationShell API](https://pub.dev/documentation/go_router/latest/go_router/StatefulNavigationShell-class.html)
- [Flutter NavigationBar API](https://api.flutter.dev/flutter/material/NavigationBar-class.html)

## Story Completion Status

- Story file created from finalized Epic 1 requirements.
- Epic, PRD, UX, architecture, implementation-readiness, previous-story, deferred-work, current-code, Git, parallel review, and current official technical guidance analyzed.
- Scope is bounded to the four-section router/shell and skeletal branch roots; final theme and all real feature behavior remain deferred.
- Status set to `ready-for-dev`.
- Completion note: Ultimate context engine analysis completed - comprehensive developer guide created.

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- RED: `flutter test test\app\router\app_router_test.dart test\app\navigation\app_shell_test.dart` failed because the Story 1.4 router files and APIs did not yet exist.
- GREEN/focused: `flutter test test\app\router\app_router_test.dart test\app\navigation\app_shell_test.dart test\widget_test.dart` passed 12 tests.
- Format: `dart format --output=none --set-exit-if-changed .` passed with 29 files and 0 changes.
- Analysis: `flutter analyze` passed with no issues.
- Regression: `flutter test --reporter expanded` passed all 29 tests.
- Build: `flutter build apk --debug` produced `build/app/outputs/flutter-apk/app-debug.apk`.
- Device verification: installed the debug APK on `TindaTrack_API_36` (`emulator-5554`), captured the TindaTrack offline splash, confirmed Dashboard with four tabs, and used Android UI automation to verify Products, History, Settings, and Dashboard each displayed and became selected.
- Environment: Flutter 3.44.0, Dart 3.12.0, `go_router` 17.3.0. Windows Flutter commands ran from disposable mirror `C:\tmp\Inventory-story14-red` because the SDK cannot operate from the UNC workspace.

### Implementation Plan

- Keep bootstrap outside the route table by wrapping the router child with the existing launch gate through `MaterialApp.router.builder`.
- Centralize the four authorized names and paths, then construct one Riverpod-owned `GoRouter` with `StatefulShellRoute.indexedStack`.
- Use router-owned branch state for selection/reselection and add only neutral feature placeholder roots.
- Prove branch persistence, direct-root mapping, bootstrap isolation, database lifecycle isolation, and route scope through focused widget tests.

### Completion Notes List

- Added a stable four-branch router and Material 3 bottom navigation shell for Dashboard, Products, History, and Settings.
- Preserved Story 1.3 loading, safe failure/retry, and database close-before-reopen behavior while hiding navigation until bootstrap succeeds.
- Added skeletal Products, History, and Settings roots without introducing future feature behavior, dependencies, permissions, schema, DAO, migration, or generated database changes.
- Added router/navigation coverage for canonical routes, visible labels, selected indexes, active-only content, active-tab reselection, branch-state preservation, direct initialization, and bootstrap/database/router stability.
- Passed strict formatting, static analysis, all 29 tests, Android debug build, and live API 36 emulator verification.
- Resolved all three Story 1.4 code-review patches: Android Back lifecycle coverage, complete failed-bootstrap shell isolation, and provider-driven router recreation detection. Final regression count is 30 passing tests.

### File List

- `_bmad-output/implementation-artifacts/1-4-add-main-navigation-shell.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `tindatrack/lib/app/app.dart`
- `tindatrack/lib/app/navigation/app_shell.dart`
- `tindatrack/lib/app/router/app_router.dart`
- `tindatrack/lib/app/router/app_routes.dart`
- `tindatrack/lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- `tindatrack/lib/features/history/presentation/screens/movement_history_screen.dart`
- `tindatrack/lib/features/products/presentation/screens/product_list_screen.dart`
- `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart`
- `tindatrack/test/app/navigation/app_shell_test.dart`
- `tindatrack/test/app/router/app_router_test.dart`
- `tindatrack/test/widget_test.dart`

## Change Log

- 2026-06-21: Implemented the Story 1.4 four-section stateful navigation shell, bootstrap integration, placeholder roots, focused regression coverage, Android build, and emulator verification.
- 2026-06-23: Resolved all code-review patches, passed strict formatting and analysis, and passed all 30 regression tests; story marked done.
