---
baseline_commit: eb878cb81f8039bdd0fe175a53716baf37de2ece
---

# Story 1.3: Provide Offline App Launch And Splash Initialization

Status: done

<!-- Note: Validation is optional. Run validate-create-story for an independent readiness check before dev-story. -->

## Story

As a store owner,
I want the app to open without internet and initialize local services,
so that I can use inventory features even when connection is unavailable.

## Acceptance Criteria

1. **Given** the user launches the app with no internet connection  
   **When** the splash screen initializes required local app services  
   **Then** initialization uses only local dependencies and does not request login, network access, cloud setup, permissions, or account state  
   **And** opening the Drift database successfully is enough to proceed.

2. **Given** application initialization is in progress  
   **When** the launch UI is displayed  
   **Then** the user sees a lightweight splash state containing the TindaTrack name and a small loading indicator  
   **And** the app does not add an artificial delay, heavy animation, or blocking task on the UI thread.

3. **Given** local initialization succeeds  
   **When** the splash flow completes  
   **Then** the launch gate transitions to a minimal Dashboard landing screen  
   **And** the app is ready for Story 1.4 to add the `go_router` route table and four-section navigation shell without replacing the bootstrap contract.

4. **Given** local initialization fails  
   **When** the required local database cannot be opened or queried  
   **Then** the app shows a simple inline retry state with plain recovery text and a visible Retry action  
   **And** raw Drift, SQLite, file path, stack trace, or exception text is not exposed.

5. **Given** the user selects Retry after an initialization failure  
   **When** the retry action runs  
   **Then** local initialization is executed again and the UI returns to a loading state while it runs  
   **And** a successful later attempt transitions to the Dashboard without restarting the process or requiring internet.

6. **Given** the Story 1.2 architecture foundation already exists  
   **When** Story 1.3 is implemented and verified  
   **Then** `ProviderScope`, lazy/disposable database ownership, injectable database executors, ULID and UTC clock providers, typed failures, and safe failure messages remain intact  
   **And** focused provider/widget tests, all existing tests, Flutter analysis, formatting, and an Android debug build pass.

## Tasks / Subtasks

- [x] Confirm the Story 1.2 baseline and keep scope bounded (AC: 1, 3, 6)
  - [x] Work only inside the existing `tindatrack/` package plus this story's BMAD records.
  - [x] Preserve Android-only project output, `com.rkuhonta.tindatrack`, app title, disabled debug banner, `ProviderScope`, and all Story 1.2 service abstractions.
  - [x] Do not add a login/future-login screen, account check, connectivity check, HTTP client, cloud service, remote API, scanner permission/dependency, background worker, analytics, or ads.
  - [x] Do not implement Story 1.4 bottom navigation/route table or Story 1.5 final design-token theme and reusable loading/empty/error component library.

- [x] Add an explicit app-bootstrap boundary (AC: 1, 3, 4, 5)
  - [x] Add focused startup code under `lib/app` (use `bootstrap.dart` as the architecture-aligned anchor; split a small launch-gate widget into another `lib/app` file only if that improves clarity).
  - [x] Represent initialization with a Riverpod async provider/controller watched by the launch gate; do not place startup business logic in `main()`, a widget `initState`, or a global mutable singleton.
  - [x] Make initialization consume the existing `databaseProvider`, causing the production database to be created lazily only when bootstrap starts.
  - [x] Prove database readiness with a real, harmless Drift/SQLite operation such as a one-row `SELECT 1` probe or a narrowly named `AppDatabase` readiness method that performs that probe.
  - [x] Treat the ID generator and UTC clock as already-constructed synchronous services; do not generate/discard an ID or timestamp merely to claim they were initialized.
  - [x] Catch database/open failures at the bootstrap boundary and convert them to the existing typed failure/result foundation; never pass raw exception strings into visible UI.

- [x] Implement lightweight launch, success, and failure states (AC: 2, 3, 4)
  - [x] Update `MainApp` so `MaterialApp.home` renders a Riverpod-aware launch gate while preserving the current app title and debug-banner behavior.
  - [x] Loading state: show `TindaTrack` and a small `CircularProgressIndicator` (or equivalent lightweight Material progress indicator); do not impose a minimum splash duration.
  - [x] Success state: render one minimal Dashboard landing screen as the destination required by this story.
  - [x] Keep the Dashboard landing screen intentionally skeletal: no summary cards, product data, low-stock logic, recent activity, Add Product action, bottom navigation, or other Epic 2-4 behavior.
  - [x] Failure state: show calm, plain recovery copy based on `PersistenceFailure`/`FailureMessageMapper` and a Retry button. A suitable message is the existing `"We couldn't access your saved data. Please try again."`
  - [x] Keep the retry control accessible and obvious using standard Material behavior; final colors, typography tokens, spacing system, and shared state widgets remain Story 1.5.

- [x] Make retry deterministic and lifecycle-safe (AC: 4, 5, 6)
  - [x] Retry through Riverpod invalidation/refresh so the async bootstrap operation is discarded and evaluated again.
  - [x] Ensure retry reaches a fresh database attempt when database construction/opening itself failed; define the invalidation relationship deliberately rather than relying on a stale failed future.
  - [x] Preserve provider-owned database disposal. Do not manually close the database from the splash widget.
  - [x] Prevent duplicate retry submissions while initialization is already loading.
  - [x] Do not log raw database exceptions or local inventory information in production-visible output.

- [x] Add focused bootstrap and widget tests (AC: 1-6)
  - [x] Add provider-level coverage using an in-memory Drift database to prove bootstrap performs the readiness operation and completes without network/platform storage.
  - [x] Add a deterministic failing database/bootstrap fake and verify the result is a typed persistence failure rather than an uncaught raw exception.
  - [x] Verify the initial widget state shows the TindaTrack splash/loading UI.
  - [x] Verify successful initialization replaces the splash with the minimal Dashboard landing state.
  - [x] Verify failed initialization shows friendly recovery copy, a Retry action, and none of the injected raw technical error text.
  - [x] Verify Retry reruns initialization, shows loading during the new attempt, and can recover from first-attempt failure to Dashboard success.
  - [x] Verify provider overrides remain available so tests never open the production Android database file.
  - [x] Preserve and adapt existing provider lifecycle tests, including completed asynchronous database closure on container disposal.

- [x] Verify offline launch behavior and regression safety (AC: 1-6)
  - [x] Run `dart format --output=none --set-exit-if-changed .`.
  - [x] Run `flutter analyze`.
  - [x] Run `flutter test --reporter expanded`.
  - [x] Run `flutter build apk --debug`.
  - [ ] Launch the debug app on an Android emulator/device with network access disabled when the environment permits; confirm splash -> Dashboard succeeds without login, connectivity, or cloud prompts. (Not run: no Android target was attached.)
  - [x] Record exact commands, effective package versions, test counts, build result, and any verified UNC-workspace workaround in the Dev Agent Record.

### Review Findings

- [x] [Review][Patch] Serialize database closure before retry creates the replacement connection [tindatrack/lib/app/app.dart:49]
- [x] [Review][Patch] Prevent rapid duplicate Retry taps from launching repeated invalidation cycles [tindatrack/lib/app/app.dart:49]
- [x] [Review][Patch] Do not convert programming `Error` objects into misleading persistence failures [tindatrack/lib/app/bootstrap.dart:12]
- [x] [Review][Patch] Strengthen bootstrap/retry tests to prove readiness is awaited and failed database disposal completes before replacement [tindatrack/test/app/bootstrap_test.dart:11]
- [x] [Review][Patch] Correct the checked live offline-launch task because no Android target was attached [1-3-provide-offline-app-launch-and-splash-initialization.md:117]
- [x] [Review][Defer] Handle asynchronous database-close failures without uncaught zone errors [tindatrack/lib/app/providers.dart:33] — deferred, pre-existing

## Dev Notes

### Developer Context

Story 1.2 completed the architecture foundation and deliberately left the database provider lazy. Story 1.3 is the point where launch begins consuming that provider: the splash must wait for a genuine local database readiness operation, show safe recovery when it fails, and proceed offline when it succeeds.

The main implementation risk is crossing neighboring story boundaries:

- **Story 1.3 owns:** startup/bootstrap orchestration, splash loading state, local database readiness, safe failure/retry, and the minimal Dashboard success destination.
- **Story 1.4 owns:** the `go_router` route table, named routes, shell route/navigation model, exact four-item bottom navigation, and Products/History/Settings placeholders.
- **Story 1.5 owns:** final Material 3 theme tokens and reusable cross-app loading/empty/error components.
- **Epic 2 onward owns:** product schema/data and real feature screens.
- **Epic 4 owns:** real Dashboard summaries, low-stock preview, recent activity, and empty-state actions.

For this story, “routed to Dashboard” means the launch gate reaches the Dashboard destination after success. Do not create the final navigation architecture early. Structure the launch gate so Story 1.4 can place the success destination behind `go_router` without rewriting the initialization provider.

### Current Files To Update

#### `tindatrack/lib/main.dart`

- **Current state:** synchronously runs `ProviderScope(child: MainApp())`.
- **This story changes:** normally none; keep startup composition small. `main()` must not await database opening before `runApp`, because doing so would prevent the Flutter splash/retry UI from rendering.
- **Must preserve:** root `ProviderScope`, no service locator, no network startup, and no platform expansion.

#### `tindatrack/lib/app/app.dart`

- **Current state:** creates a plain `MaterialApp` whose `home` is the Story 1.1/1.2 smoke screen.
- **This story changes:** make the home content Riverpod-aware and switch among bootstrap loading, failure/retry, and Dashboard success states.
- **Must preserve:** `title: 'TindaTrack'`, `debugShowCheckedModeBanner: false`, a single root `MaterialApp`, and compatibility with Story 1.4's later router conversion.

#### `tindatrack/lib/app/providers.dart`

- **Current state:** provides lazy app-scoped `AppDatabase`, `IdGenerator`, and UTC `Clock`; database lifecycle is owned by Riverpod and closes asynchronously on disposal.
- **This story changes:** add only app-level bootstrap composition that truly belongs beside these providers, or keep bootstrap in `bootstrap.dart` and import the existing provider.
- **Must preserve:** lazy creation until read, override support, explicit disposal behavior, abstraction types for ID/time, and absence of widget-owned database lifecycle.

#### `tindatrack/lib/core/database/app_database.dart`

- **Current state:** injectable empty schema-v1 Drift database using production `driftDatabase(name: 'tindatrack')`.
- **This story changes:** optionally add one narrowly scoped readiness/open method if it makes bootstrap intent and testing clearer.
- **Must preserve:** schema version 1, no feature tables/DAOs, injectable `QueryExecutor`, production database name, generated-part setup, and no schema/migration change.

#### `tindatrack/test/widget_test.dart`

- **Current state:** pumps `MainApp` under `ProviderScope` and immediately verifies `TindaTrack` / `Offline inventory tracker`.
- **This story changes:** replace the old immediate smoke expectation with deterministic launch-state tests using provider overrides; do not let the widget test open a production database.
- **Must preserve:** useful verification of app name/local-only purpose and root Riverpod composition.

#### `tindatrack/test/app/providers_test.dart`

- **Current state:** proves deterministic service overrides, lazy database creation, and completed closure after provider-container disposal.
- **This story changes:** retain these tests and add/bootstrap tests separately or here if cohesive.
- **Must preserve:** the database resource-lifecycle regression check.

### Technical Requirements

- Keep Flutter `3.44.0` / Dart `3.12.x` compatibility and the dependency versions already resolved in `pubspec.lock`.
- Use Riverpod's async state instead of hand-rolled booleans plus `setState`; provider state must be overrideable in tests.
- Prefer the simplest stable shape: a `FutureProvider` is sufficient for immutable bootstrap work plus explicit invalidation retry. Do not add code generation or an `AsyncNotifier` unless the implementation genuinely needs mutable commands beyond retry.
- The readiness operation must really open/query Drift. Merely reading `databaseProvider` constructs an `AppDatabase` object but may not prove the underlying SQLite connection can open.
- Map any caught storage exception to `PersistenceFailure(debugMessage: ...)` or an equivalent typed result. The diagnostic value may support debugging/tests but must never be displayed or logged with inventory content.
- Do not add a connectivity package. Offline readiness is proven by the absence of remote dependencies and by local-only execution, not by asking whether the device is connected.
- Do not call `WidgetsFlutterBinding.ensureInitialized()` unless an actual startup API requires it; current bootstrap should run after `runApp` through Riverpod.
- Do not add an artificial splash timer. Transition as soon as required local work succeeds.
- Do not modify Android native launch-screen assets in this story unless a test/build defect requires it. The Flutter splash state is the scoped UX behavior.
- No schema version change, generated Drift change, or migration generation should be needed unless `app_database.dart` annotations/schema change unexpectedly.

### Architecture Compliance

- `lib/app`: bootstrap orchestration, launch gate, app-level providers/composition.
- `lib/core/database`: the database and an optional persistence-level readiness method only.
- `lib/core/errors`: reuse typed failures and friendly-message mapping; do not create a second error/result system.
- `lib/features/dashboard`: one minimal, read-only Dashboard destination may be introduced because Story 1.3 must land there. It must not own bootstrap or app-shell behavior.
- Widgets depend on Riverpod/bootstrap state, never directly on Drift queries.
- `core` remains feature-independent and must not import `app` or `features`.
- No global mutable bootstrap singleton and no database creation inside a widget.

### Library And Framework Requirements

Use the current project versions; no dependency addition is expected:

| Package | Current resolved version | Story 1.3 use |
| --- | --- | --- |
| `flutter_riverpod` | `3.3.2` | Async bootstrap state, provider overrides, invalidation/refresh retry |
| `drift` / `drift_dev` | `2.34.0` | Real local database readiness probe; no schema change |
| `drift_flutter` | `0.3.0` | Existing Android database opener |
| `go_router` | `17.3.0` | Installed only; route table and shell remain Story 1.4 |
| `mocktail` | `1.0.5` | Optional for a focused failure fake; prefer small fakes/overrides |

Do not add connectivity_plus, splash-generator packages, Firebase, HTTP clients, authentication SDKs, another state manager, another router, service locators, analytics, ads, or storage packages.

### File Structure Requirements

Expected new or updated files are approximately:

```text
tindatrack/
|-- lib/
|   |-- main.dart                              # likely unchanged
|   |-- app/
|   |   |-- app.dart                           # launch gate becomes root home
|   |   |-- bootstrap.dart                     # async local initialization
|   |   `-- providers.dart                     # preserve existing services
|   |-- core/
|   |   `-- database/
|   |       `-- app_database.dart              # optional readiness method
|   `-- features/
|       `-- dashboard/
|           `-- presentation/
|               `-- screens/
|                   `-- dashboard_screen.dart  # minimal success target only
`-- test/
    |-- app/
    |   |-- bootstrap_test.dart
    |   `-- providers_test.dart
    |-- core/
    |   `-- database/app_database_test.dart     # readiness coverage if method added
    `-- widget_test.dart
```

Exact file splitting may vary, but keep startup concerns in `app`, persistence mechanics in `core/database`, and the Dashboard destination in its feature. Do not create router/navigation/theme/shared-widget forests before their owning stories.

### Testing Requirements

- Tests mirror `lib/` paths and use deterministic provider overrides.
- Use `NativeDatabase.memory()` for successful database bootstrap tests.
- Create a narrow failing `QueryExecutor`, failing bootstrap provider override, or test database subclass; do not rely on corrupting real files or platform paths.
- Provider tests must prove the readiness operation is awaited, not merely that an `AppDatabase` instance exists.
- Widget tests must control pending/completed/failed states with completers or provider overrides; avoid fragile real-time delays.
- After a Retry tap, assert a second initialization attempt occurred.
- Assert visible text does not contain a supplied raw technical sentinel such as a SQLite exception message or filesystem path.
- Keep existing Story 1.2 tests passing, especially empty schema-v1 and asynchronous database disposal.
- Do not require internet, Android plugins, or a production database file for unit/widget tests.

### Previous Story Intelligence

- Story 1.2 established `ProviderScope`, a lazy/disposable `databaseProvider`, `IdGenerator`, UTC `Clock`, typed `Result`, `PersistenceFailure`, and `FailureMessageMapper`.
- The database provider is intentionally lazy. Story 1.3 must be the first app flow that watches/reads it eagerly for real startup readiness.
- `AppDatabase` has an injectable `QueryExecutor`, so bootstrap can be tested entirely in memory.
- The schema-v1 database intentionally has no feature tables. Do not mistake “initialize local services” for permission to add products, stock movements, settings, or migration code.
- Failure copy is neutral Filipino-friendly English, not raw technical text and not save-specific Tagalog.
- Riverpod provider lifecycle testing already verifies asynchronous database closure; preserve that behavior when retry/invalidation is introduced.
- The previous implementation passed code generation, Drift migration snapshot generation, strict formatting, analysis, 13 tests, and Android debug build.
- Windows Flutter tooling against the UNC workspace may stall. Use the previously verified disposable `C:\tmp` mirror for Flutter verification if needed, while keeping repository files as the source of truth.
- Code review requires truthful completion records: do not mark offline launch or commands complete unless they actually ran and passed.
- Deferred work contains one pre-existing transitive SQLite compatibility-package concern. Do not turn Story 1.3 into a Drift dependency upgrade.

### Git Intelligence Summary

- Current branch: `codex/complete-stories-1-1-and-1-2`, tracking the matching origin branch.
- Latest commit: `eb878cb Complete Flutter foundation stories`.
- That commit added the entire Android Flutter package and Story 1.1/1.2 foundation in one coherent baseline; Story 1.3 should extend its patterns rather than regenerate or restructure the project.
- Recent commits are planning/foundation commits. There is no existing router, splash, bootstrap controller, Dashboard feature, or feature table to reuse.
- The worktree was clean when Create Story began. Do not reset, clean, checkout, commit, push, or rewrite unrelated files during story implementation unless separately requested.

### Latest Technical Information

- As of 2026-06-20, the project's resolved `flutter_riverpod 3.3.2`, `drift 2.34.0`, and `go_router 17.3.0` match the current package releases. Do not upgrade them as part of this story.
- Riverpod providers cache async work and expose loading/error/data state to widgets. `FutureProvider` fits a one-time asynchronous bootstrap operation.
- Riverpod `ref.invalidate(provider)` discards the current provider state and causes reevaluation on the next read; `ref.refresh(provider)` is equivalent to invalidating and immediately reading the new state. Use one deliberately for Retry.
- Riverpod recommends `ref.watch` for UI synchronization and `ref.read` for user interactions such as button callbacks.
- Drift remains the local reactive SQLite layer. A harmless query must be awaited to prove that the underlying database can open.
- `go_router` supports redirects and shell routes, but those capabilities belong to Story 1.4. Keep Story 1.3's bootstrap provider independent so it can later drive router redirect/refresh behavior.

### Project Structure Notes

- `lib/app/bootstrap.dart` is explicitly present in the approved architecture target tree and is now justified by real behavior.
- Adding one minimal Dashboard screen is justified as the success destination, but adding Dashboard repositories/providers/widgets is not.
- The existing smoke copy may evolve into splash and Dashboard text, but preserve the TindaTrack identity and local/offline purpose.
- No `project-context.md` exists. The finalized Epics, Architecture, PRD, UX documents, readiness report, completed Story 1.2, current code, and Git history are the sources of truth.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story-13-Provide-Offline-App-Launch-And-Splash-Initialization]
- [Source: _bmad-output/planning-artifacts/epics.md#Story-14-Add-Main-Navigation-Shell]
- [Source: _bmad-output/planning-artifacts/epics.md#Story-15-Apply-MVP-Theme-And-Base-UI-States]
- [Source: _bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#User-Experience-Requirements]
- [Source: _bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#Non-Functional-Requirements]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Splash-Screen]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#State-Patterns]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Brand--Style]
- [Source: _bmad-output/planning-artifacts/architecture.md#Authentication--Security]
- [Source: _bmad-output/planning-artifacts/architecture.md#Frontend-Architecture]
- [Source: _bmad-output/planning-artifacts/architecture.md#Project-Structure--Boundaries]
- [Source: _bmad-output/planning-artifacts/implementation-readiness-report-2026-06-01.md#UX-To-Architecture-Alignment]
- [Source: _bmad-output/implementation-artifacts/1-2-establish-app-architecture-and-local-core-services.md#Dev-Notes]
- [Riverpod providers](https://riverpod.dev/docs/concepts2/providers)
- [Riverpod refs and invalidation](https://riverpod.dev/docs/concepts2/refs)
- [flutter_riverpod 3.3.2](https://pub.dev/packages/flutter_riverpod)
- [drift 2.34.0](https://pub.dev/packages/drift)
- [go_router 17.3.0](https://pub.dev/packages/go_router)

## Story Completion Status

- Story file created from the finalized Epic 1 requirements.
- Epic, PRD, UX, architecture, implementation-readiness, previous-story, deferred-work, current-code, Git, and current official technical guidance analyzed.
- Scope is bounded to offline local initialization, splash, safe retry, and minimal Dashboard handoff; router shell, final theme/base states, and real feature behavior remain deferred.
- Status set to `ready-for-dev`.
- Completion note: Ultimate context engine analysis completed - comprehensive developer guide created.

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- RED: Focused tests failed as expected because `bootstrapProvider`, `AppDatabase.ensureReady()`, and the launch-state UI did not exist.
- GREEN: Added the local bootstrap provider, real `SELECT 1` readiness probe, splash/Dashboard/failure states, and retry invalidation. The first focused run exposed Riverpod's default refresh behavior retaining the previous error; setting `skipLoadingOnRefresh: false` made retry loading explicit.
- Verification used the established disposable `C:\tmp\Inventory-story13-red` mirror because Windows Flutter tooling cannot use the repository's UNC path as its working directory.
- `dart format --output=none --set-exit-if-changed .`: passed, 21 files checked, 0 changes.
- `flutter analyze`: passed with no issues.
- `flutter test --reporter expanded`: passed, 20 tests.
- `flutter build apk --debug`: initial invocation exceeded the five-minute command window but completed and produced the APK; an immediate incremental rerun passed explicitly in 21.4 seconds at `build/app/outputs/flutter-apk/app-debug.apk`.
- `adb devices`: no emulator/device was attached, so the conditional live airplane-mode launch was not available in this environment.
- Effective versions remained Flutter 3.44.0 / Dart 3.12.x, Riverpod 3.3.2, Drift/Drift Dev 2.34.0, drift_flutter 0.3.0, and go_router 17.3.0. No dependency or schema version changed.
- Code-review verification after all patches: strict formatting passed with 21 files unchanged, `flutter analyze` passed with no issues, 23 tests passed, and `flutter build apk --debug` produced the debug APK.

### Completion Notes List

- Added a Riverpod `FutureProvider<Result<void>>` bootstrap boundary that lazily opens and probes the local Drift database without any network, login, cloud, permission, or account dependency.
- Added lightweight TindaTrack splash, safe initialization failure/retry, and a deliberately minimal Dashboard landing screen while preserving Story 1.4/1.5 boundaries.
- Retry invalidates both database and bootstrap providers, shows loading during refresh, creates a fresh database attempt after open failure, and preserves provider-owned asynchronous disposal.
- Added provider, database, and widget coverage for readiness, typed persistence failure mapping, splash, success, safe error copy, retry recovery, and fresh-database recreation.
- All 20 tests, strict formatting, Flutter analysis, and Android debug APK build passed. Live device launch was unavailable because no Android target was attached.
- Resolved all five code-review patches: serialized close-before-reopen with shared close completion, guarded rapid Retry taps, preserved programming errors, strengthened async/lifecycle tests, and corrected the unavailable live-device verification record.
- Final review suite contains 23 passing tests. One pre-existing asynchronous close-error handling concern remains explicitly deferred.

### File List

- `_bmad-output/implementation-artifacts/1-3-provide-offline-app-launch-and-splash-initialization.md`
- `_bmad-output/implementation-artifacts/deferred-work.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `tindatrack/lib/app/app.dart`
- `tindatrack/lib/app/bootstrap.dart`
- `tindatrack/lib/app/providers.dart`
- `tindatrack/lib/core/database/app_database.dart`
- `tindatrack/lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- `tindatrack/test/app/bootstrap_test.dart`
- `tindatrack/test/app/providers_test.dart`
- `tindatrack/test/core/database/app_database_test.dart`
- `tindatrack/test/widget_test.dart`

## Change Log

- 2026-06-20: Implemented offline local-service bootstrap, splash loading, safe retry, fresh database recreation, and minimal Dashboard handoff; added focused tests and passed all available quality gates. Status moved to review.
- 2026-06-21: Completed adversarial code review, resolved all five actionable findings, deferred one pre-existing lifecycle concern, reran all quality gates successfully, and marked Story 1.3 done.
