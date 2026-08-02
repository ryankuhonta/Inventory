---
baseline_commit: 75baba942252c7426105b6ce1f83cdd2957da855
---

# Story 1.2: Establish App Architecture And Local Core Services

Status: done

<!-- Note: Validation is optional. Run validate-create-story for an independent readiness check before dev-story. -->

## Story

As a developer maintaining the app,
I want the local architecture foundation in place,
so that product and stock features can be built consistently and safely.

## Acceptance Criteria

1. **Given** the Flutter project exists  
   **When** the application structure is created  
   **Then** the source tree includes meaningful code or documentation anchors under `lib/app`, `lib/core`, and `lib/features`  
   **And** future feature code is organized feature-first while shared, feature-independent infrastructure stays in `core`.

2. **Given** the app architecture foundation is implemented  
   **When** future features need state, persistence, IDs, time, or failures  
   **Then** Riverpod root wiring, a lazy/disposable Drift database provider, a ULID generation abstraction, an injectable UTC clock abstraction, and typed result/failure-to-message patterns are available  
   **And** widgets do not access Drift, DAOs, or database tables directly.

3. **Given** the local database scaffold is added  
   **When** schema version 1 is defined  
   **Then** the Drift database has an injectable executor for tests, a production Android database opener, and configuration ready for generated schema/migration tooling  
   **And** no product, stock movement, settings, barcode, or other feature table/DAO is created prematurely.

4. **Given** future Drift tables and columns will be added  
   **When** database identifiers are defined  
   **Then** explicit SQLite names follow `snake_case` for tables, columns, indexes, and stored enum values  
   **And** Dart types and fields may remain `UpperCamelCase` and `lowerCamelCase`.

5. **Given** the existing starter app is refactored into the architecture foundation  
   **When** the app is run or tested  
   **Then** the current local-only `TindaTrack` / `Offline inventory tracker` smoke screen still renders  
   **And** no splash flow, database initialization gate, route table, bottom navigation shell, final theme, reusable UI-state component, or MVP feature flow is introduced.

6. **Given** the architecture services are complete  
   **When** quality checks run  
   **Then** code generation, formatting, Flutter analysis, focused unit/database/provider tests, the widget smoke test, and an Android debug build pass  
   **And** tests prove UTC clock behavior, ULID string generation, typed failure mapping, Riverpod overrides/lifecycle, and the empty schema-v1 database scaffold.

## Tasks / Subtasks

- [x] Preserve the Story 1.1 baseline and confirm scope (AC: 1, 5)
  - [x] Work only inside the existing `tindatrack/` package plus this story's BMAD records.
  - [x] Keep Android as the only generated platform and preserve `com.rkuhonta.tindatrack`.
  - [x] Preserve the visible smoke-screen copy and offline runtime behavior.
  - [x] Do not overwrite, revert, stage, or otherwise absorb unrelated local changes.

- [x] Create the app composition boundary and Riverpod root wiring (AC: 1, 2, 5)
  - [x] Move the root application widget from `lib/main.dart` into `lib/app/app.dart`; keep `main.dart` limited to startup composition.
  - [x] Wrap the root app in `ProviderScope`.
  - [x] Add app-level providers in `lib/app/providers.dart` only for cross-cutting services owned by this story: database, ID generator, and clock.
  - [x] Make the database provider lazy and register database closure through Riverpod disposal.
  - [x] Keep `MaterialApp` and the current smoke screen behavior; do not wire go_router yet.

- [x] Establish feature-first and shared-infrastructure boundaries (AC: 1, 2)
  - [x] Create meaningful anchors for `lib/app`, `lib/core`, and `lib/features`; do not add a forest of empty directories.
  - [x] Document that future feature modules own their `presentation`, `domain`, and `data` layers under `lib/features/{feature}`.
  - [x] Keep `core` feature-independent; feature-specific entities, failures, validators, repositories, and providers must stay with their feature when introduced.
  - [x] Enforce dependency direction: presentation/controller -> domain/use case -> repository contract -> data implementation/DAO -> core database.

- [x] Add the Drift schema-v1 scaffold (AC: 2, 3, 4)
  - [x] Add `lib/core/database/app_database.dart` with `schemaVersion == 1` and no feature tables.
  - [x] Support an injected `QueryExecutor` so tests can use an in-memory database.
  - [x] Use the current `drift_flutter` production opener for the Android database file and a stable app-specific database name.
  - [x] Add the required `part` file and run build_runner; generated Drift output must be checked by analysis and tests.
  - [x] Add `build.yaml` and register `lib/core/database/app_database.dart` under `drift_dev.options.databases` so `dart run drift_dev make-migrations` can discover the database later.
  - [x] Run `dart run drift_dev make-migrations` once after schema v1 is generated and retain the initial empty-schema snapshot as the migration baseline; do not add upgrade steps because no prior schema exists.
  - [x] Do not create placeholder `products`, `stock_movements`, `app_settings`, barcode, sync, or authentication tables/DAOs.

- [x] Add the ULID abstraction (AC: 2, 6)
  - [x] Add `ulid` as a direct runtime dependency; do not rely on the unrelated transitive `uuid` package.
  - [x] Define an `IdGenerator` contract under `lib/core/id`.
  - [x] Implement the production ULID generator behind that contract and return canonical 26-character ULID strings.
  - [x] Generate IDs at future entity creation boundaries; do not introduce auto-increment domain IDs.

- [x] Add the injectable UTC clock (AC: 2, 6)
  - [x] Define a small clock contract under `lib/core/time`.
  - [x] Implement the system clock so its public value is always UTC.
  - [x] Keep direct `DateTime.now()` out of future domain/data code; production time access must remain behind the clock implementation.
  - [x] Provide test override/fake patterns without adding a second time library unless required.

- [x] Add typed result, failure, and message mapping foundations (AC: 2, 6)
  - [x] Define one canonical typed result shape for success/failure outcomes.
  - [x] Define only shared foundation failures needed now, such as persistence and unexpected failures.
  - [x] Add a pure failure-to-friendly-message mapper; never expose raw Drift, SQLite, stack trace, or exception text.
  - [x] Leave product-, barcode-, archive-, and stock-specific failure variants to the stories that introduce those rules.

- [x] Add focused architecture tests (AC: 2, 3, 4, 5, 6)
  - [x] Update the widget smoke test for the new app/ProviderScope composition while preserving both visible labels.
  - [x] Test the clock contract with a deterministic override/fake and verify production values are UTC.
  - [x] Test ULID output format, uniqueness across representative calls, and provider override support.
  - [x] Test each foundation failure maps to stable, Filipino-friendly English and does not leak technical exception text.
  - [x] Test the database with an in-memory executor, verify schema version 1, and verify no feature tables exist.
  - [x] Test app-level providers can be overridden and the database resource is closed on container disposal.

- [x] Verify the architecture foundation (AC: 5, 6)
  - [x] Run `dart run build_runner build --delete-conflicting-outputs`.
  - [x] Run `dart run drift_dev make-migrations` and confirm the schema-v1 baseline is current.
  - [x] Run `dart format --output=none --set-exit-if-changed .`.
  - [x] Run `flutter analyze`.
  - [x] Run `flutter test`.
  - [x] Run `flutter build apk --debug`.
  - [x] Record exact commands, effective dependency versions, and results in the Dev Agent Record.

### Review Findings

- [x] [Review][Patch] Make `AppFailure` extensible by feature-owned failure types [tindatrack/lib/core/errors/app_failure.dart:2]
- [x] [Review][Patch] Make asynchronous database disposal explicit and prove close completion in the provider lifecycle test [tindatrack/lib/app/providers.dart:31]
- [x] [Review][Patch] Use neutral Filipino-friendly English failure messages instead of Tagalog save-specific copy [tindatrack/lib/core/errors/failure_message_mapper.dart:11]
- [x] [Review][Patch] Prove the schema-v1 scaffold has no user-defined tables, not merely three named tables [tindatrack/test/core/database/app_database_test.dart:18]
- [x] [Review][Patch] Clarify dependency inversion between repository contracts and data implementations [tindatrack/lib/features/README.md:6]
- [x] [Review][Defer] Review transitive EOL SQLite compatibility packages when upgrading Drift infrastructure [tindatrack/pubspec.lock:648] — deferred, pre-existing

## Dev Notes

### Developer Context

Story 1.1 created a working Android-only Flutter package at `tindatrack/`, added the approved dependencies/tooling, and intentionally stopped at a minimal local Material screen. This story turns that starter into a testable architecture foundation without implementing any user feature.

The highest-risk mistake is scope blending. Architecture documents show the final target tree, but the finalized epic split is authoritative:

- **Story 1.2:** app/core/features boundaries, Riverpod root and service providers, empty Drift schema scaffold, ULID abstraction, UTC clock, typed result/failure/message pattern.
- **Story 1.3:** open/initialize required local services through splash, success routing, failure/retry behavior.
- **Story 1.4:** go_router route table, four-section navigation shell, and placeholder screens.
- **Story 1.5:** final Material 3 tokens/theme and reusable loading/empty/error UI.
- **Story 2.1:** first feature schema (`products`) and product repository.
- **Story 3.1:** `stock_movements` schema and repository.

Do not interpret the architecture's broad "first implementation priority" or complete future directory tree as permission to pull later-story work into Story 1.2.

### Current Files To Update

#### `tindatrack/lib/main.dart`

- **Current state:** owns `main()`, `MainApp`, `MaterialApp`, and the complete smoke screen.
- **This story changes:** reduce it to startup composition and move `MainApp` into `lib/app/app.dart`; add `ProviderScope` at the Flutter root.
- **Must preserve:** app title, debug banner behavior, visible `TindaTrack` and `Offline inventory tracker` text, local-only startup, and lack of login/network/cloud requirements.

#### `tindatrack/test/widget_test.dart`

- **Current state:** imports `main.dart`, pumps `MainApp`, and checks both smoke-screen labels.
- **This story changes:** import the new app location and pump it under the same Riverpod composition required in production.
- **Must preserve:** deterministic verification of both labels and no dependence on a real database file, network, emulator, or platform plugin.

#### `tindatrack/pubspec.yaml` and `pubspec.lock`

- **Current state:** direct dependencies are Drift `2.34.0`, drift_flutter `0.3.0`, Riverpod `3.3.2`, and go_router `17.3.0`; build_runner, drift_dev, mocktail, and Very Good Analysis are already present.
- **This story changes:** add only the direct ULID dependency required by the approved ID decision. `path_provider` is already transitive through drift_flutter; add it directly only if Story 1.2 source imports it.
- **Must preserve:** matching `drift`/`drift_dev` versions, strict linting, Android-only/lightweight dependency posture, and absence of deferred SDKs.

#### `tindatrack/analysis_options.yaml`

- **Current state:** includes `very_good_analysis` with no broad exclusions.
- **This story changes:** normally none; add only narrow, explained lint exceptions if generated-code integration truly requires one.
- **Must preserve:** strict analysis and no blanket rule disabling.

### Technical Requirements

- Use Flutter `3.44.0` / Dart `3.12.x` compatibility established by Story 1.1.
- Use Riverpod as composition and dependency injection. Providers must expose contracts where substitutability matters.
- Do not instantiate a database inside a widget.
- A provider may construct the database lazily, but Story 1.3 owns eager startup initialization, splash waiting, and retry.
- Close `AppDatabase` through provider/container disposal so tests and hot restarts do not leak SQLite resources.
- Keep the database constructor injectable with a `QueryExecutor`.
- Schema version 1 is intentionally empty of feature tables. The scaffold may still generate a valid Drift database class.
- Register the database path in `build.yaml` and capture the initial schema-v1 snapshot now. Do not add upgrade logic or a migration test for the initial schema because there is no prior version; Story 2.1 must bump the schema version and add the first migration test when it introduces `products`.
- Treat `snake_case` as a database identifier rule. Dart getters/classes remain idiomatic Dart unless an explicit `.named('snake_case')` is required.
- Use ULID strings project-wide. The generator abstraction must prevent direct package calls from spreading into feature code.
- The clock abstraction returns UTC. Only its production implementation may call the system clock.
- Keep a single typed result/failure approach; do not mix thrown data exceptions, nullable error strings, and multiple result libraries.
- Friendly messages are presentation-facing values. They must not be persisted and must not become database enum values.
- No sensitive inventory logging is needed or allowed in this foundation.

### Architecture Compliance

- `lib/app`: app composition and app-level providers. Router, navigation shell, bootstrap flow, and final theme remain later-story concerns.
- `lib/core/database`: Drift wiring and persistence infrastructure only. No business rules or user-facing decisions.
- `lib/core/errors`: shared result/failure/message primitives only.
- `lib/core/id`: ID contract and ULID implementation.
- `lib/core/time`: clock contract and production implementation.
- `lib/features`: feature-first boundary. Create feature folders when the corresponding story adds meaningful code.
- Widgets may depend on Riverpod controllers/providers, never Drift or DAOs.
- Future features may depend on `core`; `core` must never import a feature.
- Avoid global service locators and mutable singletons.

### Library And Framework Requirements

Use the versions already resolved by Story 1.1 unless dependency resolution requires a compatible patch update:

| Package | Current resolved version | Story 1.2 use |
| --- | --- | --- |
| `flutter_riverpod` | `3.3.2` | Root `ProviderScope`, service providers, overrides, disposal |
| `drift` / `drift_dev` | `2.34.0` | Empty schema-v1 database class and generated code |
| `drift_flutter` | `0.3.0` | Android/native database opener |
| `build_runner` | `2.15.0` | Drift code generation |
| `go_router` | `17.3.0` | Installed only; routing is Story 1.4 |
| `ulid` | `2.0.1` verified | Direct dependency behind `IdGenerator` |
| `mocktail` | `1.0.5` | Use only where a simple fake/override is insufficient |

Do not add Freezed, fpdart/dartz, get_it, injectable, another state manager, another router, a second ORM, Firebase, HTTP clients, scanner packages, analytics, ads, or secure storage.

### File Structure Requirements

Expected new or updated files are approximately:

```text
tindatrack/
|-- build.yaml
|-- lib/
|   |-- main.dart
|   |-- app/
|   |   |-- app.dart
|   |   `-- providers.dart
|   |-- core/
|   |   |-- database/
|   |   |   |-- app_database.dart
|   |   |   `-- app_database.g.dart
|   |   |-- errors/
|   |   |   |-- app_failure.dart
|   |   |   |-- failure_message_mapper.dart
|   |   |   `-- result.dart
|   |   |-- id/
|   |   |   |-- id_generator.dart
|   |   |   `-- ulid_generator.dart
|   |   `-- time/
|   |       `-- clock.dart
|   `-- features/
|       `-- README.md
|-- pubspec.lock
|-- pubspec.yaml
`-- test/
    |-- app/
    |   `-- providers_test.dart
    |-- core/
    |   |-- database/app_database_test.dart
    |   |-- errors/failure_message_mapper_test.dart
    |   |-- id/ulid_generator_test.dart
    |   `-- time/clock_test.dart
    `-- widget_test.dart
```

This list is guidance, not permission to create unused final-architecture files. In particular, do not add `bootstrap.dart`, router/navigation/theme files, shared widgets, feature screens, feature `data/domain/presentation` trees, DAOs, converters, or table files before their owning story needs them.

### Testing Requirements

- Tests mirror the `lib/` path.
- Use `ProviderContainer.test()` for pure Riverpod provider tests where practical.
- Override service providers with deterministic fakes; do not read global mutable state.
- An in-memory Drift executor must keep database tests isolated from Android storage/plugins.
- Verify disposal explicitly. A test database must not remain open after its Riverpod container is disposed.
- ULID tests should assert canonical shape and non-reuse, not lexical ordering based on calls made within the same millisecond.
- Clock tests must assert `isUtc == true`; do not compare against a fragile exact real-time value.
- Failure-message tests must assert stable friendly copy and absence of supplied raw exception/database text.
- Empty schema tests must allow Drift/SQLite internal metadata but reject feature-owned tables such as `products`, `stock_movements`, or `app_settings`.
- Keep the widget test independent from production database opening; the provider is lazy and the smoke screen must not read it.
- There is no schema migration to test yet because version 1 is the initial empty scaffold. Keep its generated schema snapshot as the baseline; Story 2.1 must add the v1-to-v2 migration and migration test when it introduces the first feature table.

### Previous Story Intelligence

- Story 1.1 deliberately did not wire Riverpod, routing, database classes, ULIDs, clocks, failures, or the final shell. Story 1.2 now owns the first five foundations but routing remains Story 1.4.
- The package was generated and verified with Flutter `3.44.0`, Dart `3.12.0`, and Android SDK 36.
- The current dependency set successfully passed formatting, strict analysis, widget tests, and Android debug build.
- Windows Flutter tooling against the UNC workspace previously stalled for tests/builds. Story 1.1 used a disposable `C:\tmp` mirror for verification while keeping source edits in the repository. Reuse that verified workaround if the UNC issue recurs; never treat the mirror as source of truth.
- The initial WSL call into the Windows Flutter script hit CRLF/tooling issues. Prefer the working Windows Flutter invocation pattern already recorded in Story 1.1.
- Live offline Android launch has already proven the starter screen works with airplane mode enabled, Wi-Fi disabled, and mobile data disabled.
- Code review emphasized truthful completion records. Do not mark checks complete unless their command actually passed.

### Git Intelligence Summary

- Baseline planning commit: `75baba9 Complete BMAD sprint planning`.
- The current branch is `main`.
- Story 1.1 implementation and records are local and uncommitted. Treat them as the working baseline, not disposable output.
- Current user work includes modifications to `sprint-status.yaml` and `docs/new-chat-handoff.md`, plus untracked Story 1.1 and `tindatrack/` content.
- Do not reset, clean, checkout, commit, push, or rewrite unrelated files.

### Latest Technical Information

- Riverpod's current documentation requires `ProviderScope` at a Flutter app root; it owns the provider container used for state, overrides, and disposal. Pure provider tests should use `ProviderContainer.test()`.
- Drift `2.34.0` setup uses `drift`, matching `drift_dev`, build_runner, and a platform opener. A database class needs a constructor, `schemaVersion`, and generated part file.
- Current Drift migration guidance recommends registering database paths in `build.yaml` for generated schema/migration tooling and adding migration tests when schemas change.
- The verified `ulid` package version is `2.0.1`; it produces canonical 26-character lexicographically sortable identifiers.
- Dart `DateTime.toUtc()` returns the same instant represented in UTC. The production clock should normalize system time before exposing it to domain/data callers.

### Project Structure Notes

- The architecture's complete directory tree is a target state across all epics, not the deliverable for this story.
- `lib/features/README.md` is acceptable as a tracked boundary note until Story 2.1 creates the first meaningful feature module. Do not use `.gitkeep` files to imply implemented architecture.
- An empty schema-v1 database is intentional because Epics explicitly delay `products` to Story 2.1 and `stock_movements` to Story 3.1.
- go_router remains installed from Story 1.1, but no route table is required or allowed here.
- No project-context file was found; the approved planning artifacts and completed Story 1.1 are the sources of truth.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story-12-Establish-App-Architecture-And-Local-Core-Services]
- [Source: _bmad-output/planning-artifacts/epics.md#Story-13-Provide-Offline-App-Launch-And-Splash-Initialization]
- [Source: _bmad-output/planning-artifacts/epics.md#Story-14-Add-Main-Navigation-Shell]
- [Source: _bmad-output/planning-artifacts/epics.md#Story-15-Apply-MVP-Theme-And-Base-UI-States]
- [Source: _bmad-output/planning-artifacts/architecture.md#Implementation-Patterns--Consistency-Rules]
- [Source: _bmad-output/planning-artifacts/architecture.md#Project-Structure--Boundaries]
- [Source: _bmad-output/planning-artifacts/architecture.md#Format-Patterns]
- [Source: _bmad-output/planning-artifacts/architecture.md#Architectural-Boundaries]
- [Source: _bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#Non-Functional-Requirements]
- [Source: _bmad-output/planning-artifacts/implementation-readiness-report-2026-06-01.md#Epic-Quality-Review]
- [Source: _bmad-output/implementation-artifacts/1-1-set-up-initial-project-from-flutter-empty-starter-template.md#Dev-Notes]
- [Riverpod ProviderContainers/ProviderScopes](https://riverpod.dev/docs/concepts2/containers)
- [Drift setup](https://drift.simonbinder.eu/setup/)
- [Drift migrations](https://drift.simonbinder.eu/migrations/)
- [ulid package](https://pub.dev/packages/ulid)
- [Dart DateTime.toUtc](https://api.dart.dev/dart-core/DateTime/toUtc.html)

## Story Completion Status

- Story file created from the finalized Epic 1 requirements.
- Epic, PRD, UX, architecture, implementation-readiness, previous-story, current-code, Git, and latest official technical guidance analyzed.
- Scope is bounded to architecture and local-core scaffolding; later splash, navigation, theme, and feature work remain deferred.
- Status set to `ready-for-dev`.
- Completion note: Ultimate context engine analysis completed - comprehensive developer guide created.

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- RED: Initial tests were added before implementation. The first repository-path run failed because Windows `cmd.exe` cannot use a UNC working directory; verification moved to the established disposable `C:\tmp\Inventory-story12` mirror.
- RED/GREEN: First complete test run exposed two genuine mismatches: lowercase ULID output and an asynchronous database-close assertion. The generator now normalizes canonical uppercase ULIDs, and lifecycle coverage observes the managed database's `close()` call directly.
- `flutter pub get`: passed; added direct `ulid 2.0.1`. Effective core versions remained Riverpod `3.3.2`, Drift/Drift Dev `2.34.0`, drift_flutter `0.3.0`, build_runner `2.15.0`, go_router `17.3.0`, mocktail `1.0.5`, and Very Good Analysis `10.2.0`.
- `dart run build_runner build --delete-conflicting-outputs`: passed and generated the empty database class; build_runner `2.15.0` warned that the legacy flag is ignored.
- Final `dart run build_runner build`: passed; Drift output regenerated with managers disabled for the intentionally empty schema.
- `dart run drift_dev make-migrations`: passed; retained `drift_schemas/app_database/drift_schema_v1.json`.
- `dart format --output=none --set-exit-if-changed .`: passed with 18 files checked and 0 changes.
- `flutter analyze`: passed with no issues.
- `flutter test --reporter expanded`: passed, 12 tests.
- `flutter build apk --debug`: passed; generated `build/app/outputs/flutter-apk/app-debug.apk` in the disposable verification mirror.
- Verified repository implementation files byte-match the tested mirror. Android remains the only generated platform and namespace/application ID remain `com.rkuhonta.tindatrack`.
- Code-review verification: `dart run build_runner build`, `dart run drift_dev make-migrations`, strict formatting, `flutter analyze`, 13 focused/regression tests, and `flutter build apk --debug` all passed after applying the five review patches.

### Completion Notes List

- Refactored startup into a Riverpod `ProviderScope` composition boundary while preserving the existing local-only smoke screen.
- Added lazy, overrideable app-level database, ID generator, and UTC clock providers with managed database disposal.
- Added an injectable empty Drift schema-v1 database, production `tindatrack.sqlite` opener, generated code, and initial migration schema snapshot.
- Added direct ULID generation, UTC clock, typed result/failure primitives, and safe Filipino-friendly failure messages.
- Documented feature-first ownership and dependency direction without introducing later-story routes, splash, shell, theme, tables, DAOs, or feature flows.
- Added focused provider, database, result/failure, ULID, clock, and widget tests; all automated quality and Android debug build gates passed.
- Resolved all five actionable code-review findings: feature-extensible failures, explicit asynchronous database close handling with completion-based verification, neutral friendly-English messages, complete empty-schema checking, and corrected repository dependency inversion.
- Deferred only the pre-existing transitive SQLite compatibility-package review until the Drift infrastructure is intentionally upgraded.

### File List

- `_bmad-output/implementation-artifacts/1-2-establish-app-architecture-and-local-core-services.md`
- `_bmad-output/implementation-artifacts/deferred-work.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `tindatrack/build.yaml`
- `tindatrack/drift_schemas/app_database/drift_schema_v1.json`
- `tindatrack/lib/app/app.dart`
- `tindatrack/lib/app/providers.dart`
- `tindatrack/lib/core/database/app_database.dart`
- `tindatrack/lib/core/database/app_database.g.dart`
- `tindatrack/lib/core/errors/app_failure.dart`
- `tindatrack/lib/core/errors/failure_message_mapper.dart`
- `tindatrack/lib/core/errors/result.dart`
- `tindatrack/lib/core/id/id_generator.dart`
- `tindatrack/lib/core/id/ulid_generator.dart`
- `tindatrack/lib/core/time/clock.dart`
- `tindatrack/lib/features/README.md`
- `tindatrack/lib/main.dart`
- `tindatrack/pubspec.lock`
- `tindatrack/pubspec.yaml`
- `tindatrack/test/app/providers_test.dart`
- `tindatrack/test/core/database/app_database_test.dart`
- `tindatrack/test/core/errors/failure_message_mapper_test.dart`
- `tindatrack/test/core/errors/result_test.dart`
- `tindatrack/test/core/id/ulid_generator_test.dart`
- `tindatrack/test/core/time/clock_test.dart`
- `tindatrack/test/widget_test.dart`

## Change Log

- 2026-06-20: Implemented Story 1.2 architecture and local core-service foundation, added focused tests and Drift migration baseline, and passed formatting, analysis, tests, and Android debug build. Status moved to review.
- 2026-06-20: Completed adversarial code review, resolved all five actionable findings, deferred one pre-existing dependency-stack concern, reran all quality gates successfully, and marked Story 1.2 done.
