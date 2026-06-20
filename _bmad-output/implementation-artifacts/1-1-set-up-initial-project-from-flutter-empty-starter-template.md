---
baseline_commit: 75baba942252c7426105b6ce1f83cdd2957da855
---

# Story 1.1: Set Up Initial Project From Flutter Empty Starter Template

Status: done

<!-- Note: Validation is optional. Run bmad-create-story with the validate action for an independent readiness check before dev-story. -->

## Story

As a store owner,
I want the app to install and open on Android,
so that I can start using an offline inventory tracker without setup complexity.

## Acceptance Criteria

1. **Given** the repository is ready for implementation  
   **When** the Flutter project is initialized  
   **Then** the project uses the official empty Android starter command:

   ```bash
   flutter create --empty --platforms android --org com.rkuhonta tindatrack
   ```

   **And** the generated Flutter package is located at the repository root under `tindatrack/`.

2. **Given** the starter project has been generated  
   **When** its platform folders and Android configuration are reviewed  
   **Then** Android is the only generated platform  
   **And** the Android namespace and application ID use `com.rkuhonta.tindatrack`.

3. **Given** the project dependencies are added  
   **When** the app is prepared for later implementation stories  
   **Then** Riverpod, Drift, go_router, Android SQLite support, code generation, test tooling, and strict linting are available  
   **And** dependency choices remain lightweight enough for low-end Android devices.

4. **Given** the initialized application is run without internet access  
   **When** Flutter starts the Android app  
   **Then** a basic working Flutter screen is displayed  
   **And** no login, network connection, cloud setup, or remote service is required.

5. **Given** the initial project setup is complete  
   **When** quality checks are run  
   **Then** formatting, Flutter analysis, the default widget test baseline, and an Android debug build pass  
   **And** the repository contains no partially implemented MVP feature flow.

6. **Given** the existing repository contains BMAD planning and documentation artifacts  
   **When** the Flutter package is generated  
   **Then** existing `.agents`, `_bmad`, `_bmad-output`, and `docs` content is preserved  
   **And** unrelated local changes are not overwritten or reverted.

## Tasks / Subtasks

- [x] Verify the implementation environment (AC: 1, 5)
  - [x] Confirm the Flutter SDK is available and record the effective Flutter and Dart versions in the Dev Agent Record.
  - [x] Prefer the architecture baseline of Flutter `3.44.0` and Dart `3.12.0`; if the installed stable SDK differs, verify compatibility before changing the documented baseline.
  - [x] Run `flutter doctor` and record any Android toolchain issue that prevents build verification.

- [x] Generate the Android-only Flutter package (AC: 1, 2, 6)
  - [x] Run the exact approved starter command from the repository root.
  - [x] Do not use the standard counter template or generate additional platform folders.
  - [x] Confirm the package path is `tindatrack/`.
  - [x] Confirm Android namespace/application ID is `com.rkuhonta.tindatrack`.
  - [x] Preserve all existing planning, BMAD, documentation, and unrelated user-authored files.

- [x] Add the approved dependency and tooling foundation (AC: 3)
  - [x] Add `flutter_riverpod`, `drift`, `drift_flutter`, and `go_router` as runtime dependencies.
  - [x] Add `drift_dev`, `build_runner`, `mocktail`, and `very_good_analysis` as development dependencies.
  - [x] Keep `flutter_test` from the Flutter SDK.
  - [x] Run dependency resolution and include the generated lockfile in the Story 1.1 change set.
  - [x] Do not add Firebase, authentication, HTTP/API clients, scanner libraries, analytics, ads, secure storage, or other deferred infrastructure.

- [x] Configure the minimum runnable application (AC: 4)
  - [x] Keep `lib/main.dart` small and understandable.
  - [x] Render a basic local-only Material screen suitable for a smoke test.
  - [x] Confirm the screen has no runtime dependency on internet access.
  - [x] Do not wire Riverpod, routing, splash initialization, bottom navigation, the final theme, database classes, or feature screens in this story.

- [x] Configure analysis and baseline testing (AC: 3, 5)
  - [x] Configure `analysis_options.yaml` to include `very_good_analysis`.
  - [x] Apply only narrowly justified lint exceptions; do not broadly disable strict analysis.
  - [x] Add or update the generated widget test to verify that the basic initial screen renders.
  - [x] Ensure generated/tool directories such as `.dart_tool/` remain ignored.

- [x] Verify the project baseline (AC: 4, 5)
  - [x] Allow network access for initial package resolution and Android toolchain downloads when required; offline behavior applies to the built app at runtime.
  - [x] Run `dart format --output=none --set-exit-if-changed .` from the Flutter package root.
  - [x] Run `flutter analyze`.
  - [x] Run `flutter test`.
  - [x] Run `flutter build apk --debug`.
  - [x] If an Android emulator or device is available, launch the app and confirm it opens without internet.
  - [x] Record commands and results in the Dev Agent Record.

### Review Findings

- [x] [Review][Patch] Verify live Android launch with networking disabled before completion — Verified on the `TindaTrack_API_36` Android 16 emulator with airplane mode enabled, Wi-Fi disabled, and mobile data disabled; the app process remained alive and rendered both expected labels.
- [x] [Review][Patch] Correct the lockfile task wording so it does not claim a pre-review commit [_bmad-output/implementation-artifacts/1-1-set-up-initial-project-from-flutter-empty-starter-template.md:72]
- [x] [Review][Patch] Synchronize Story Completion Status with the current review workflow state [_bmad-output/implementation-artifacts/1-1-set-up-initial-project-from-flutter-empty-starter-template.md:254]

## Dev Notes

### Developer Context

This is the first implementation story in a greenfield repository. The repository currently contains BMAD and project documentation but no Flutter package, `pubspec.yaml`, Android project, or Dart source.

The purpose of this story is to establish a reproducible Android Flutter baseline. It is not the architecture-scaffolding or feature-development story. The developer must leave a small application that resolves dependencies, renders locally, passes its baseline checks, and is ready for Story 1.2.

The approved user-facing product is an offline-first Android inventory tracker for Philippine sari-sari stores and small businesses. The starter must not require internet, login, cloud configuration, or backend services.

### Scope Boundary And Story Sequencing

The finalized epic breakdown is authoritative when it assigns work across stories:

- **Story 1.1:** Flutter package generation, approved dependencies/tooling, minimal runnable screen, linting, baseline test/build.
- **Story 1.2:** `lib/app`, `lib/core`, `lib/features`, Clean Architecture boundaries, Drift database scaffold, Riverpod app wiring, ULID abstraction, injectable UTC clock, and typed failures.
- **Story 1.3:** Offline splash/local-service initialization and retry behavior.
- **Story 1.4:** go_router route table, four-section shell, and bottom navigation.
- **Story 1.5:** Approved Material 3 theme and reusable loading/empty/error states.

Architecture text that broadly describes the "first implementation story" must be interpreted through this finalized story decomposition. Do not pull Story 1.2-1.5 work into Story 1.1.

### Technical Requirements

- Use the exact approved command:

  ```bash
  flutter create --empty --platforms android --org com.rkuhonta tindatrack
  ```

- Keep the Flutter package nested at `<repository-root>/tindatrack/`. Do not generate into `.` because that risks mixing Flutter-generated files with BMAD project artifacts.
- The generated project name is `tindatrack`; Android identity is `com.rkuhonta.tindatrack`.
- Generate Android only. The absence of iOS, web, Windows, macOS, and Linux platform folders is intentional.
- The basic screen may use Flutter's default Material foundation. Final visual tokens and application navigation belong to later stories.
- Install Riverpod but do not add `ProviderScope` or other Riverpod app wiring; Story 1.2 owns that integration.
- Drift dependencies are installed now, but no Drift table, database class, DAO, migration, generated `.g.dart` file, or database-opening behavior is created.
- Do not run `build_runner` merely to manufacture output when no generator input exists yet.
- Do not use direct `DateTime.now()`, UUID/ULID generation, persistence, repositories, or domain failures in this story because those concerns are not needed by the basic starter screen.

### Library And Framework Requirements

Use stable package versions compatible with the installed Flutter/Dart SDK. The following versions were verified on June 15, 2026 and are compatibility targets, not instructions to force an unsatisfiable dependency set:

| Package | Verified stable version | Placement |
| --- | --- | --- |
| `flutter_riverpod` | `3.3.2` | dependency |
| `drift` | `2.34.0` | dependency |
| `drift_flutter` | `0.3.0` | dependency |
| `go_router` | `17.3.0` | dependency |
| `drift_dev` | `2.34.0` | dev dependency |
| `build_runner` | `2.15.0` | dev dependency |
| `mocktail` | `1.0.5` | dev dependency |
| `very_good_analysis` | `10.2.0` | dev dependency |

Dependency guidance:

- Use `flutter pub add` or compatible SDK tooling to resolve constraints supported by the installed Flutter/Dart SDK. Record any resolved version that differs from the verified target.
- Keep `drift` and `drift_dev` on matching versions.
- `drift_flutter` supplies Flutter/native database-opening support and its transitive SQLite platform libraries; do not add redundant SQLite packages unless the current official setup or build result requires them.
- Do not add `path_provider` in this story unless Story 1.1 code imports it directly. Story 1.2 may add it with the database-opening implementation.
- `go_router` is installed for Story 1.4 but should not be wired into the basic Story 1.1 screen.
- `mocktail` is available for later tests; the Story 1.1 smoke test does not need mocks.
- `very_good_analysis` should be included from `analysis_options.yaml`; any exception must be explicit and minimal.

### Architecture Compliance

Keep the starter Android-first, local-only at runtime, beginner-friendly, and limited to the approved Flutter stack. Do not introduce backend/API layers, authentication, Firebase/cloud sync, scanner capabilities, POS, supplier/accounting modules, staff or branch management, ads, or competing state-management/routing frameworks.

### File Structure Requirements

Expected new or modified files include:

```text
tindatrack/
|-- .gitignore
|-- README.md
|-- analysis_options.yaml
|-- android/
|-- lib/
|   `-- main.dart
|-- pubspec.lock
|-- pubspec.yaml
`-- test/
    `-- widget_test.dart
```

The exact Android files are generated by the installed Flutter SDK. Avoid hand-editing generated Gradle files unless required to correct the approved namespace/application ID or restore a passing Android build.

Do not create empty architecture folders solely to resemble the future directory tree. Story 1.2 should create folders alongside meaningful scaffold code so empty directories are not lost by Git.

### Testing Requirements

Minimum automated verification:

- A widget smoke test pumps the minimal root application without Riverpod wiring.
- The test verifies stable visible text or another deterministic element from the initial screen.
- `flutter analyze` reports no issues.
- `flutter test` passes.
- `flutter build apk --debug` completes.

Manual verification, when an Android target is available:

- App installs/launches.
- Basic screen renders.
- Airplane mode or disabled network does not block startup.
- No login, permissions, or cloud configuration prompt appears.

The built app must start and render without network access. Initial dependency download, Gradle resolution, and Android toolchain setup may use the network and are not part of the offline-runtime acceptance criterion.

Do not claim device-launch verification if no emulator/device was available. Record that limitation while still completing analysis, tests, and debug build.

### Existing Files And Preservation

No existing Flutter source files are being updated because the Flutter project does not yet exist. Existing repository content must be treated as project records and preserved. In particular:

- `.agents/`
- `_bmad/`
- `_bmad-output/`
- `docs/`

The worktree may contain an unrelated local modification to `docs/new-chat-handoff.md`. Do not overwrite, stage, revert, or reformat that file as part of Story 1.1.

### Latest Technical Information

- Flutter's current documentation reflects Flutter `3.44.0` as of May 5, 2026.
- Current Drift setup requires both runtime packages and build-time tooling; code generation is run with `dart run build_runner build` only after generator inputs exist.
- Current Drift Flutter setup supports `drift_flutter` for native database opening, but actual database creation is deferred to Story 1.2.
- Riverpod 3 uses `ProviderScope` as its Flutter root container; Story 1.2 will add that wiring.
- go_router 17 remains the approved declarative router, but route implementation is deferred to Story 1.4.

### Project Structure Notes

- The architecture's complete future tree is a target architecture, not a requirement to create every file in this starter story.
- The nested `tindatrack/` package is intentional because the repository root already owns BMAD planning artifacts.
- Tests created in this story remain under `tindatrack/test/`; later tests should mirror `tindatrack/lib/`.
- No project-context file currently exists; this story and the approved planning artifacts are the implementation sources of truth.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story-11-Set-Up-Initial-Project-From-Flutter-Empty-Starter-Template]
- [Source: _bmad-output/planning-artifacts/epics.md#Story-12-Establish-App-Architecture-And-Local-Core-Services]
- [Source: _bmad-output/planning-artifacts/architecture.md#Starter-Template-Evaluation]
- [Source: _bmad-output/planning-artifacts/architecture.md#Project-Structure--Boundaries]
- [Source: _bmad-output/planning-artifacts/architecture.md#Implementation-Readiness-Validation]
- [Source: _bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#Non-Goals-For-MVP]
- [Source: _bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#Non-Functional-Requirements]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Foundation]
- [Flutter CLI documentation](https://docs.flutter.dev/reference/flutter-cli)
- [Riverpod package](https://pub.dev/packages/flutter_riverpod)
- [Drift setup guide](https://drift.simonbinder.eu/setup/)
- [go_router package](https://pub.dev/packages/go_router)
- [Very Good Analysis package](https://pub.dev/packages/very_good_analysis)

## Story Completion Status

- Story file created from the finalized Epic 1 requirements.
- Architecture, PRD, UX, current repository state, and current package information analyzed.
- Implementation scope is bounded to starter setup and baseline quality checks.
- Status advanced from `ready-for-dev` through `review` to `done` after implementation, adversarial code review, and live offline Android verification.
- Completion note: Ultimate context engine analysis completed - comprehensive developer guide created.

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- `flutter --version`: Flutter 3.44.0, Dart 3.12.0, DevTools 2.57.0.
- `flutter doctor -v`: Android SDK 36.0.0 and licenses available; no Android emulator/device connected. The Visual Studio warning applies only to excluded Windows desktop development.
- Initial WSL execution of the Windows Flutter shell script failed because of CRLF line endings; project generation used Windows Flutter through `cmd pushd` while preserving the exact Flutter create arguments.
- Flutter test execution against the UNC path stalled in Windows tooling. Tests and builds were run against a disposable `C:\tmp` mirror of the same source; all source edits remained in the repository workspace.
- Red phase: widget test failed because `TindaTrack` was absent from the generated `Hello World!` screen.
- Green/refactor phase: widget test passed after implementing the minimal screen; strict analysis initially found one missing public API doc and passed after documenting the constructor.
- Code-review verification: installed Android Emulator and the API 36 Google APIs x86_64 image, created `TindaTrack_API_36`, disabled Wi-Fi and mobile data, enabled airplane mode, installed the debug APK, and launched `com.rkuhonta.tindatrack`.
- Offline launch evidence: Android reported `airplane_mode=1`, `wifi=0`, `mDataConnectionState=0`; app PID `4080` remained active, UI Automator exposed `TindaTrack` and `Offline inventory tracker`, and recent logcat contained no fatal app exception.

### Completion Notes List

- Generated the Android-only Flutter empty package at `tindatrack/` with namespace/application ID `com.rkuhonta.tindatrack`.
- Added the approved dependency foundation at the verified compatible versions: Riverpod 3.3.2, Drift/Drift Dev 2.34.0, drift_flutter 0.3.0, go_router 17.3.0, build_runner 2.15.0, mocktail 1.0.5, and Very Good Analysis 10.2.0.
- Removed the starter `flutter_lints` dependency and enabled `very_good_analysis` without broad lint exclusions.
- Added a minimal local-only Material screen and a deterministic widget smoke test without Riverpod, routing, database, or feature wiring.
- Verified formatting, strict analysis, widget tests, Android identity, Android-only platform generation, ignored tool output, and a successful debug APK build.
- Automated test and debug build gates passed. Code review then installed and used an Android 16 emulator to complete the live offline-launch check; AC4 is verified.

### File List

- `tindatrack/.gitignore`
- `tindatrack/.metadata`
- `tindatrack/README.md`
- `tindatrack/analysis_options.yaml`
- `tindatrack/android/.gitignore`
- `tindatrack/android/app/build.gradle.kts`
- `tindatrack/android/app/src/debug/AndroidManifest.xml`
- `tindatrack/android/app/src/main/AndroidManifest.xml`
- `tindatrack/android/app/src/main/kotlin/com/rkuhonta/tindatrack/MainActivity.kt`
- `tindatrack/android/app/src/main/res/drawable-v21/launch_background.xml`
- `tindatrack/android/app/src/main/res/drawable/launch_background.xml`
- `tindatrack/android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- `tindatrack/android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- `tindatrack/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- `tindatrack/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- `tindatrack/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
- `tindatrack/android/app/src/main/res/values-night/styles.xml`
- `tindatrack/android/app/src/main/res/values/styles.xml`
- `tindatrack/android/app/src/profile/AndroidManifest.xml`
- `tindatrack/android/build.gradle.kts`
- `tindatrack/android/gradle.properties`
- `tindatrack/android/gradle/wrapper/gradle-wrapper.properties`
- `tindatrack/android/settings.gradle.kts`
- `tindatrack/lib/main.dart`
- `tindatrack/pubspec.lock`
- `tindatrack/pubspec.yaml`
- `tindatrack/test/widget_test.dart`

## Change Log

- 2026-06-15: Initialized the Android-only Flutter application, added approved dependencies and strict linting, implemented the minimal offline starter screen, added the smoke test, and passed the Story 1.1 automated quality/build gates.
- 2026-06-15: Addressed all code-review findings, including live Android launch with networking disabled; Story 1.1 approved as done.
