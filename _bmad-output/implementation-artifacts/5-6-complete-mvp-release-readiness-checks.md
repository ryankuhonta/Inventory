# Story 5.6: Complete MVP Release Readiness Checks

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a developer preparing the MVP,
I want release-readiness checks to pass,
so that the app is stable enough for testing or first distribution.

## Acceptance Criteria

1. Given implementation is ready for MVP verification, when quality checks run, then Flutter analysis, unit tests, repository transaction tests, widget tests, and Drift migration tests pass, and failures are addressed before release handoff.
2. Given offline behavior is verified, when the app is used without internet, then core product, stock movement, dashboard, history, and settings flows remain usable, and no workflow requires login or cloud services.
3. Given release readiness is reviewed, when the app is prepared for testing or distribution, then no debug-only UI, test keys, raw exception messages, or fake future features are visible, and app version display is correct.
4. Given MVP scope exclusions are checked, when the codebase and routes are reviewed, then POS, supplier management, accounting/profit reports, cloud sync, barcode scanner UI, staff roles, multi-branch management, and remote API client layers remain absent, and deferred features are not partially implemented without scope approval.

## Tasks / Subtasks

- [ ] Task 1: Run and preserve release quality gates (AC: 1)
  - [ ] Run `dart analyze` from a Windows temp copy if UNC Flutter tooling blocks direct execution.
  - [ ] Run the full Flutter test suite, including repository transaction tests, widget tests, and Drift migration tests.
  - [ ] Run `flutter build apk --debug` as an Android build sanity check.
  - [ ] Run `git diff --check` from the repository workspace.
  - [ ] Address any failing analyzer, test, build, or whitespace issue before marking this task complete.

- [ ] Task 2: Add release-readiness regression checks for MVP scope and user-visible safety (AC: 2, 3, 4)
  - [ ] Add deterministic tests that inspect the production route graph and confirm only Dashboard, Products, Add Product, Edit Product, Stock In, Stock Out, History, and Settings routes are present.
  - [ ] Add or extend guardrail coverage to assert forbidden scope terms and future-feature routes remain absent from user-visible MVP surfaces.
  - [ ] Verify Settings app version copy still reads from bundled `pubspec.yaml` and is not hardcoded separately.
  - [ ] Ensure the tests do not require network, login, cloud services, analytics, ads, remote config, barcode scanner packages, POS, supplier, accounting, staff roles, or multi-branch code.

- [ ] Task 3: Review Android release/build configuration without expanding scope (AC: 1, 3)
  - [ ] Inspect `tindatrack/android/app/build.gradle.kts`, `AndroidManifest.xml`, and `pubspec.yaml` for release-readiness blockers.
  - [ ] Remove template-only TODO comments if they would be embarrassing or misleading in a release-readiness handoff, but do not invent production signing or distribution credentials.
  - [ ] Preserve current Android-first package identity unless an explicit requirement says to rename it.
  - [ ] Confirm no extra Android permissions, internet dependency, ad SDK, analytics SDK, scanner dependency, or cloud SDK is introduced.

- [ ] Task 4: Document release-readiness outcome for handoff (AC: 1-4)
  - [ ] Create or update a concise implementation artifact documenting quality gate results, Android build result, MVP scope checks, known limitations, and release-channel assumptions.
  - [ ] Explicitly call out that release signing / Play Store distribution remains a separate release-management decision if not configured.
  - [ ] Record any unresolved release-readiness risks as action items rather than silently passing them.
  - [ ] Keep documentation in `_bmad-output/implementation-artifacts` unless the codebase already has a more specific release checklist location.

- [ ] Task 5: Verify Story 5.6 completion (AC: 1-4)
  - [ ] Run Dart format for touched `lib` and `test` files.
  - [ ] Re-run focused tests added or changed for release readiness.
  - [ ] Re-run `dart analyze`.
  - [ ] Re-run the full Flutter test suite.
  - [ ] Re-run Android debug build validation.
  - [ ] Re-run `git diff --check`.

## Dev Notes

### Source Requirements

- Story 5.6 covers NFR-001, NFR-002, NFR-005, NFR-006, NFR-009, and NFR-010. [Source: `_bmad-output/planning-artifacts/epics.md#Story 5.6: Complete MVP Release Readiness Checks`]
- MVP must work offline, persist locally after restart, keep stock changes reliable and atomic, avoid production logging of sensitive inventory data, remain beginner-friendly and modular, and preserve future cloud-sync readiness without requiring cloud services now. [Source: `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#9. Non-Functional Requirements`]
- Success metrics include product/dashboard responsiveness on low-end Android devices, zero known bugs allowing negative stock, and movement history matching quantity changes during QA. [Source: `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#15. Success Metrics`]
- Release readiness criteria require accepted product CRUD, atomic stock in/out, low-stock behavior, designed MVP UX flows, confirmed local database/repository boundaries, and future sync readiness. [Source: `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#16. Release Readiness Criteria`]
- Architecture requires Flutter analyze/test/build checks before release, including unit tests, repository rollback tests, widget tests, Drift migration tests, and Android debug/release build validation. [Source: `_bmad-output/planning-artifacts/architecture.md#Deployment Architecture`]
- Release channel is explicitly release planning, not architecture readiness; first release path remains open between private APK and Play Store internal testing. [Source: `_bmad-output/planning-artifacts/architecture.md#MVP Addendum Review Notes`; `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#17. Open Questions`]

### Current System State

- Current primary app routes are defined in `tindatrack/lib/app/router/app_router.dart` and route identities in `app_routes.dart`: Dashboard, Products, History, Settings, and Products-owned Add Product, Edit Product, Stock In, and Stock Out.
- Existing feature folders are limited to Dashboard, Products, Stock, History, and Settings under `tindatrack/lib/features`; no login, cloud sync, POS, supplier, accounting, staff, multi-branch, remote API, ad, analytics, or scanner feature folders are present.
- Existing test coverage already includes `test/core/database/app_database_migration_test.dart`, repository tests under `test/features/*/data/repositories`, stock controller/screen tests, dashboard tests, settings tests, and `test/ux/mvp_visible_copy_guardrail_test.dart`.
- `pubspec.yaml` currently declares Flutter, Drift, Riverpod, go_router, and ULID dependencies; no network, auth, cloud, analytics, ad, scanner, POS, supplier, or accounting packages are present.
- `pubspec.yaml` version is `0.1.0+1` and is bundled as an asset for Settings app version display.
- Android build config exists under `tindatrack/android`; `android/app/build.gradle.kts` currently uses `applicationId = "com.rkuhonta.tindatrack"`, version values from Flutter, and debug signing for release build placeholders generated by the Flutter template.
- `AndroidManifest.xml` currently contains launcher metadata and Flutter text processing package-visibility query only; there is no internet permission or feature-specific permission currently required by MVP flows.

### Architecture Compliance

- Do not add new backend infrastructure, remote API clients, login/auth routes, cloud sync services, analytics, crash reporting, ads, scanner dependencies, POS/cart/checkout, supplier management, accounting/profit reports, staff roles, or multi-branch management. [Source: `_bmad-output/planning-artifacts/architecture.md#MVP Exclusions Enforced By Structure`]
- Keep feature code in existing feature-first folders and shared UI/components in `tindatrack/lib/core`; tests must mirror `lib/` under `tindatrack/test`. [Source: `_bmad-output/planning-artifacts/architecture.md#File Organization Patterns`; `_bmad-output/planning-artifacts/architecture.md#Test Organization`]
- Presentation code must keep using Riverpod providers/controllers and typed domain failures rather than reaching into Drift directly. [Source: `_bmad-output/planning-artifacts/architecture.md#API & Communication Patterns`]
- No Drift schema change is expected for this story. If one becomes necessary, it requires version bump, migration, migration test, and data preservation checks. [Source: `_bmad-output/planning-artifacts/architecture.md#Required Implementation Test Checklist`]
- Android release-readiness checks may inspect platform files but should not add signing credentials, keystore files, Play Store setup, or distribution automation unless the user explicitly scopes that release-management work.

### UX And Scope Guardrails

- Preserve the four-tab app shell: Dashboard, Products, History, Settings. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Bottom Navigation`]
- Preserve offline-first behavior in every primary flow; no MVP user should be forced to sign in or connect to the internet. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Login Account And Cloud Sync`; `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Implementation Notes`]
- Keep screens readable and usable on small Android screens, with scrollable forms and lightweight UI for low-end devices. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Brand And Style`; `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Responsive And Platform Notes`]
- Do not add debug-only UI, test labels, raw exception messages, fake future-feature buttons, fake sync/export flows, or monetization prompts as part of release readiness.

### Suggested Implementation Shape

- Start with guardrail tests before editing platform/config files:
  - Route graph test: verify production `createAppRouter()` exposes exactly the MVP route names/paths and no excluded route labels or paths.
  - Scope/dependency test: parse `pubspec.yaml` and/or file tree to fail if excluded packages or feature folders appear.
  - Manifest/build config test: assert no unexpected Android permissions and document the current signing/distribution state.
- Prefer a release-readiness artifact such as `_bmad-output/implementation-artifacts/5-6-mvp-release-readiness-checklist.md` for gate results and risks.
- Keep code changes minimal. This story should mostly add verification coverage, clean template release comments if appropriate, and document results.
- If full `flutter build apk --release` fails due signing/environment setup, do not fake success; record it as a release-management action item and keep debug build validation as the implementation-level build sanity check.

### Testing Requirements

- Verification should include:
  - `dart analyze`
  - `flutter test`
  - focused release-readiness tests added by this story
  - `flutter build apk --debug`
  - `git diff --check`
- Continue running Flutter verification from a Windows temp copy under `C:\tmp` if UNC paths block Flutter tooling.
- If a release guardrail test scans files, keep it deterministic and scoped to local files; do not require network, emulator, external services, or credentials.
- Existing required test categories already present in the tree should remain passing: migration tests, repository transaction tests, widget/screen tests, stock in/out controller tests, app routing tests, and UX visible-copy guardrail tests.

### Previous Story Intelligence

- Story 5.1 established Settings without providers or persistence and intentionally avoided auth, cloud, scanner, POS, supplier, accounting, reporting, and dependency changes.
- Story 5.2 centralized PHP currency display through `CurrencyFormatter.php()`.
- Story 5.3 added honest Backup / Export placeholder copy and preserved local-device/no-account/no-internet expectations.
- Story 5.4 added app version display from bundled `pubspec.yaml`; preserve `versionFromPubspec`, `pubspec.yaml` asset registration, and parser behavior.
- Story 5.5 fixed Dashboard first-product CTA navigation, added consolidated History movement row semantics, and replaced source-literal copy checks with widget-level visible-copy guardrails over MVP screens.
- Story 5.5 final verification after review patches: focused tests passed from `C:\tmp\tindatrack-story-5-5-review-fix`, `dart analyze` passed with no issues, and `git diff --check` was clean.

### Git Intelligence

- `0b6a1a2 Complete Story 5.5 code review`
- `e068fb7 Create Story 5.5 UX polish context`
- `d493eea Complete Story 5.4 code review`
- `92fa01f Implement Story 5.4 app version display`
- `3491f0e Create Story 5.4 app version context`

Recent work favors focused story-scoped tests, implementation artifacts under `_bmad-output/implementation-artifacts`, stable keys/routes, visible-copy guardrails, and status-only review completion commits.

### Anti-Scope And Regression Guardrails

- Do not implement release signing credentials, Play Store upload automation, crash reporting, telemetry, analytics, ads, cloud sync, backup/export, barcode scanning, POS/cart/checkout, supplier management, accounting/profit reporting, staff roles, multi-branch support, or remote API client layers in this story.
- Do not introduce Android permissions unless a currently implemented MVP feature requires them; offline local inventory work should not need internet permission.
- Do not change Drift schema, migrations, product quantity rules, stock movement transaction boundaries, or route identities unless a failing release-readiness check proves a real blocker.
- Do not remove existing Settings PHP, Backup / Export, Local Data, or App Version copy.
- Do not mark release readiness complete if any analyzer/test/build gate fails; record unresolved risks explicitly.

### Project Structure Notes

- Expected likely files to touch:
  - `_bmad-output/implementation-artifacts/5-6-complete-mvp-release-readiness-checks.md`
  - `_bmad-output/implementation-artifacts/sprint-status.yaml`
  - `_bmad-output/implementation-artifacts/5-6-mvp-release-readiness-checklist.md` or equivalent release-readiness artifact
  - `tindatrack/test/app/router/app_router_test.dart` or a new release-readiness guardrail test under `tindatrack/test/ux` or `tindatrack/test/app`
  - possibly `tindatrack/android/app/build.gradle.kts` only for template-comment cleanup, not signing setup
- This is a release-readiness verification story, not a feature expansion story.

## Dev Agent Record

### Agent Model Used

Codex GPT-5

### Debug Log References

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.

### File List

- `_bmad-output/implementation-artifacts/5-6-complete-mvp-release-readiness-checks.md`

### Change Log

- 2026-07-25: Created Story 5.6 release readiness context; marked ready for dev.