---
baseline_commit: f758d77cead3d1f8f921d46bd0aa9bf48a07cf72
---

# Story 2.2: Add Product With Validation

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a store owner,
I want to add a product with basic stock details,
so that I can start tracking inventory.

## Acceptance Criteria

1. **Approved Add Product fields and defaults**
   - **Given** the user opens Add Product
   - **When** the form is displayed
   - **Then** it includes product name, optional category, unit defaulting to `pcs`, selling price, starting quantity, and low-stock threshold
   - **And** starting quantity and low-stock threshold default to `0`
   - **And** selling price may be left blank and is submitted as `0`
   - **And** `cost_price`, barcode/scanner controls, stock-movement fields, and post-MVP fields are not shown.

2. **Required text validation and first-invalid-field focus**
   - **Given** product name is empty or whitespace-only
   - **When** the user saves
   - **Then** saving is blocked before the repository is called
   - **And** product name shows friendly inline copy such as `Enter a product name.`
   - **And** the first invalid field is focused and made visible.
   - **Given** unit is empty or whitespace-only
   - **When** the user saves
   - **Then** saving is blocked with field-associated inline feedback.

3. **Numeric validation**
   - **Given** selling price, starting quantity, or low-stock threshold contains invalid text
   - **When** the user saves
   - **Then** saving is blocked with inline feedback on the first invalid field.
   - **Given** any numeric value is negative, non-finite, or a quantity/threshold exceeds the configured practical maximum of `999999`
   - **When** the user saves
   - **Then** saving is blocked
   - **And** the repository is not called.
   - **And** starting quantity and low-stock threshold accept integers only, while selling price accepts a finite non-negative decimal.

4. **Normalized local save**
   - **Given** the user enters valid product details
   - **When** the user saves
   - **Then** name and unit are trimmed, blank category becomes `null`, and the feature calls the existing `ProductRepository.createProduct` boundary through an Add Product use case
   - **And** the product is saved through the Story 2.1 Drift repository without direct widget-to-DAO/database access
   - **And** duplicate product names remain allowed.

5. **Success, progress, and duplicate-submit behavior**
   - **Given** a valid save is in progress
   - **When** the repository operation has not completed
   - **Then** the keyboard is dismissed, the primary action shows button-level progress, and save controls cannot start another submission.
   - **Given** the save succeeds
   - **When** the operation completes
   - **Then** the user sees `Product saved.` or equivalent approved copy
   - **And** the Add Product screen returns to Products.

6. **Safe failure behavior**
   - **Given** the repository returns a typed failure
   - **When** the save completes
   - **Then** the form remains available with the user's entered values
   - **And** the save action is re-enabled
   - **And** the user sees friendly recovery copy without raw Drift, SQLite, stack-trace, or exception text.

7. **Accessible small-screen form and preserved barcode behavior**
   - **Given** Add Product is used on a small Android screen or with enlarged system text
   - **When** the form is displayed and validated
   - **Then** it remains scrollable without overflow, fields have accessible labels, errors are associated with fields, and applicable controls retain the 48dp tap-target floor
   - **And** quantity and price fields request suitable numeric keyboards.
   - **And** Story 2.2 does not add barcode input or scanner scope; the existing repository blank-to-`null` barcode normalization remains unchanged and covered by Story 2.1 tests.

## Tasks / Subtasks

- [x] Task 1: Add the product-validation and creation application boundary (AC: 2–4, 6)
  - [x] Add a feature-owned validator and/or validation failure carrying enough field identity for inline presentation; keep validation independent of Flutter widgets and Drift.
  - [x] Add an `AddProduct` use case under `features/products/domain/usecases` that trims name/unit, converts blank category to `null`, validates semantic bounds, and calls the existing `ProductRepository.createProduct`.
  - [x] Reuse `CreateProductInput`, `Product`, `Result<T>`, `PersistenceFailure`, and `DuplicateBarcodeFailure`; do not create another result, repository, database, clock, or ID abstraction.
  - [x] Keep duplicate names valid, zero values valid, price finite/non-negative, and quantity/threshold within `0..999999`.
  - [x] Unit-test required/whitespace text, invalid/negative/non-finite numbers, upper bounds, normalization, repository non-invocation on failure, success delegation, and typed failure passthrough.

- [x] Task 2: Compose feature-owned Riverpod dependencies and save state (AC: 2–6)
  - [x] Add product feature providers that compose `ProductsDao`, `DriftProductsRepository`, and `AddProduct` from the existing app-level database, ID-generator, and clock providers.
  - [x] Add an auto-disposed product-form controller/notifier that owns submission state, prevents concurrent saves, and exposes only presentation-safe state.
  - [x] Keep form parsing/field errors deterministic and testable; widgets render state and dispatch actions rather than containing persistence or business rules.
  - [x] Ensure every failed or rejected save returns from loading to an enabled form without losing entered values.
  - [x] Guard asynchronous completion with the Riverpod lifecycle (`ref.mounted` or equivalent) and safely contain unexpected `Exception`/Dart `Error` outcomes without exposing diagnostics.

- [x] Task 3: Add the route and accessible Add Product form (AC: 1–7)
  - [x] Add a secondary named route at `/products/add` under the Products branch; keep `AppRoute.values` limited to the four primary navigation roots.
  - [x] Extend `createAppRouter` with an injectable Add Product builder so router/widget tests remain isolated.
  - [x] Add only a minimal forward-compatible Add Product action to the current Products placeholder; Story 2.3 still owns the reactive product list, empty/list states, and final FAB/list composition.
  - [x] Build a Material 3, single-column, scrollable Add Product screen using the existing theme, spacing, dimensions, and input decoration.
  - [x] Render exactly the approved Story 2.2 fields; initialize unit to `pcs`, quantity/threshold to `0`, and omit cost price, barcode/scanner, archive, edit, and stock-movement controls.
  - [x] Use field-associated inline validation, explicit focus nodes, numeric keyboard types, keyboard dismissal on submit, and first-invalid-field focus/visibility.
  - [x] Disable duplicate submissions and show a compact progress indicator in the primary action while preserving its label semantics.
  - [x] On success, show `Product saved.` through the root `ScaffoldMessenger` and pop to Products; on failure, remain on the form and show feature-safe recovery copy.

- [x] Task 4: Prove the complete Add Product flow (AC: 1–7)
  - [x] Add router tests for the named `/products/add` child route, Products branch selection, back navigation, and preservation of exactly four primary roots.
  - [x] Add widget tests for exact fields/defaults/exclusions, successful input mapping and feedback, whitespace name, missing unit, invalid/negative/too-large numeric input, first-invalid focus, and zero values.
  - [x] Prove the save button prevents duplicate calls while pending and re-enables after a typed failure without clearing entered values.
  - [x] Prove no raw diagnostic text appears for persistence or unexpected failures.
  - [x] Test the form at `360x640` with `2x` text scaling, Android tap-target/labeled-target guidance, scrolling, and no overflow.
  - [x] Add one integration-level test through the real in-memory Drift repository proving a valid Add Product use-case input is persisted with the normalized values; do not duplicate Story 2.1's exhaustive repository suite.

- [x] Task 5: Verify Story 2.2 without disturbing completed Story 2.1 (AC: 1–7)
  - [x] Run Dart formatting, Flutter analysis, focused domain/controller/router/widget tests, and the complete Flutter test suite.
  - [x] Build/launch only if required by an encountered integration risk; no schema generation or migration work is expected.
  - [x] Preserve all pre-existing Story 2.1 worktree changes and keep Story 2.2's File List limited to files actually added or modified for this story.

### Review Findings

- [x] [Review][Patch] Keep displayed form values consistent with the submission snapshot while saving [tindatrack/lib/features/products/presentation/screens/add_product_screen.dart:68]
- [x] [Review][Patch] Make pending-save navigation complete visibly and prevent silent writes after leaving the form [tindatrack/lib/features/products/presentation/screens/add_product_screen.dart:57]
- [x] [Review][Patch] Exercise validated error semantics at the required small-screen and enlarged-text viewport [tindatrack/test/features/products/presentation/screens/add_product_screen_test.dart:207]
- [x] [Review][Patch] Prove duplicate product names through the real SQLite persistence seam [tindatrack/test/features/products/presentation/providers/product_providers_integration_test.dart:15]

## Dev Notes

### Developer Context

Story 2.1 already established the complete product persistence boundary: exact schema v2, `ProductsDao`, Drift-independent `Product` and `CreateProductInput`, `ProductRepository.createProduct`, `DriftProductsRepository`, injected ULID/clock behavior, barcode normalization, typed failures, and active-product streaming. Story 2.2 is the presentation/application slice over that boundary. It must not redesign or bypass it.

The approved flow is:

```text
AddProductScreen
  -> product form controller (Riverpod)
  -> AddProduct use case + validation
  -> ProductRepository contract
  -> DriftProductsRepository
  -> ProductsDao / AppDatabase
```

The worktree intentionally contains completed, uncommitted Story 2.1 changes. Treat those files as prerequisite context, preserve them exactly unless Story 2.2 genuinely requires a scoped modification, and do not reset, clean, stage, commit, or attribute all baseline diff files to Story 2.2.

### Validation Contract

Use one canonical set of semantic rules behind the controller/use case:

| Field | Input rule | Normalized value |
|---|---|---|
| Product name | required after trim | trimmed `String` |
| Category | optional | trimmed text or `null` when blank |
| Unit | required after trim; initial UI value `pcs` | trimmed `String` |
| Selling price | blank means zero; otherwise finite decimal `>= 0` | `double` |
| Starting quantity | required integer `0..999999`; initial UI value `0` | `int` |
| Low-stock threshold | required integer `0..999999`; initial UI value `0` | `int` |
| Barcode | no Story 2.2 field | `null` through existing input/repository behavior |

Do not rely only on `TextFormField` validators. The use-case/application boundary must reject invalid typed input so tests and future non-widget callers cannot bypass invariants. Database checks remain the final persistence safeguard.

Focus/validation order is the visual form order: name, category (no required error), unit, selling price, starting quantity, low-stock threshold. Focus and scroll to the first invalid field after submit. Validation copy should be plain English with Filipino-friendly phrasing.

### Failure And Feedback Contract

- Validation failures stay inline and must not call the repository.
- `PersistenceFailure` maps to copy such as `We couldn't save this product. Please try again.`
- `DuplicateBarcodeFailure` remains safely handled even though Story 2.2 exposes no barcode field; do not leak diagnostics.
- Unexpected failures use stable generic recovery copy; raw `debugMessage`, SQL, Drift, and stack traces never render.
- A pending save cannot be triggered again.
- Success is emitted once, shows `Product saved.`, and returns to Products.
- Do not optimistically claim success before repository completion.

### Routing And UX Boundaries

`AppRoute` currently represents exactly four branch roots and drives `NavigationBar` indexing and tests. Do not add `addProduct` to that enum. Define a separate product-secondary route identity/constant and nest the relative `add` route under `/products`.

The Products branch is currently a placeholder. Add the smallest durable entry action needed to open Add Product, without implementing Story 2.3's reactive list, empty catalog behavior, row layout, search, filters, or stock badges early.

Use the existing Material 3 theme and:

- `AppSpacing` for `8/16/24` spacing
- `AppDimensions.minimumTapTarget` for the 48dp floor
- existing `InputDecorationTheme` and button themes
- `SafeArea` plus `SingleChildScrollView`/equivalent for small screens
- `TextInputType.number` for integer fields and `TextInputType.numberWithOptions(decimal: true)` for selling price
- `FocusNode` ownership/disposal and `Form` validation without leaking controllers or nodes.

### Current Files To Update

- `tindatrack/lib/app/router/app_routes.dart`
  - Current state: defines only the four primary `AppRoute` identities.
  - Change: add a separate secondary product route identity without changing root enum order/count.
  - Preserve: root names/paths and NavigationBar assumptions.
- `tindatrack/lib/app/router/app_router.dart`
  - Current state: builds four `StatefulShellRoute` branches through one root-only helper with injectable root builders.
  - Change: add the Products child route and injectable Add Product builder.
  - Preserve: branch state, direct-root routing, router disposal, no login/scanner routes.
- `tindatrack/lib/features/products/presentation/screens/product_list_screen.dart`
  - Current state: Products placeholder only.
  - Change: add the minimal route entry action.
  - Preserve: defer list/search/filter/row/status implementation to Stories 2.3–2.5.
- Existing Story 2.1 domain/data files
  - Current state: complete and verified product persistence boundary.
  - Change: only extend feature-owned failures/contracts if the validation/use-case design strictly requires it.
  - Preserve: schema, DAO SQL, repository error translation, ID/clock injection, and barcode behavior.

### Expected New Files

Use the smallest structure consistent with the existing architecture; expected locations are:

```text
tindatrack/lib/features/products/domain/usecases/add_product.dart
tindatrack/lib/features/products/domain/validation/product_validator.dart
tindatrack/lib/features/products/presentation/controllers/product_form_controller.dart
tindatrack/lib/features/products/presentation/providers/product_providers.dart
tindatrack/lib/features/products/presentation/screens/add_product_screen.dart
tindatrack/lib/features/products/presentation/widgets/product_form.dart        # only if splitting materially improves clarity
tindatrack/test/features/products/domain/usecases/add_product_test.dart
tindatrack/test/features/products/domain/validation/product_validator_test.dart
tindatrack/test/features/products/presentation/controllers/product_form_controller_test.dart
tindatrack/test/features/products/presentation/screens/add_product_screen_test.dart
```

Tests must mirror `lib/`. Do not add new dependencies, generated Riverpod code, a second repository implementation, or a second form/state abstraction unless a concrete need appears.

### Previous Story Intelligence

- Story 2.1 is `done` after code review and the full suite now passes `78/78`.
- Its review fixed timeout overlap by keeping a timed-out underlying database close shared, added real-SQLite non-barcode failure translation coverage, and completed synchronous-close/production-timeout/successful-Retry tests. Preserve those lifecycle changes.
- `DriftProductsRepository.createProduct` already generates one ULID and one UTC instant, trims/normalizes barcode, maps only the barcode UNIQUE violation to `DuplicateBarcodeFailure`, and maps other persistence exceptions safely.
- Product domain code is Drift-independent; core remains independent of products.
- Flutter commands cannot run reliably from the UNC working directory. The established verification pattern copies only changed files into disposable `C:\tmp\inventory-story21` while WSL remains authoritative.

### Git Intelligence

- Current committed HEAD is `f758d77` (`Complete Epic 1 foundation and retrospective`).
- Story 2.1 is intentionally uncommitted and is not visible as a later commit; use its story File List and current worktree as the prerequisite boundary.
- `f758d77` established the four-branch router, Material 3 theme/tokens, placeholder screens, app lifecycle, and widget/accessibility test style.
- `eb878cb` established Drift, app-level providers, typed `Result<T>`/failures, injectable ULID/clock, strict linting, and mirrored tests.
- Preserve builder injection patterns in `createAppRouter`, provider overrides in tests, controlled completers for async behavior, and strict full-suite verification.

### Library And Latest Technical Information

Verified 2026-06-29:

- Flutter documentation reflects Flutter `3.44.0`; use a `Form`/`GlobalKey<FormState>` and field validators for UI validation/focus behavior.
- `flutter_riverpod 3.3.2` is the current project and current stable package version. Use stable `Notifier`/`AsyncNotifier` APIs; experimental mutation/persist APIs are unnecessary.
- `go_router 17.3.0` is the current project and current stable package version. It supports sub-routes and multiple navigators/ShellRoute; extend the existing manual route tree rather than adding a generator.
- No dependency upgrade is required.

Technical references:

- [Flutter forms cookbook](https://docs.flutter.dev/cookbook/forms)
- [flutter_riverpod 3.3.2](https://pub.dev/packages/flutter_riverpod)
- [go_router 17.3.0](https://pub.dev/packages/go_router)

### Scope Boundaries

Do not implement:

- Story 2.3 product list/empty state/reactive stream
- Story 2.4 search/category/status filters
- Story 2.5 low/out-of-stock badges
- Story 2.6 edit flow
- Story 2.7 archive flow
- Story 2.8 row action menu
- barcode input/scanner route, permission, or dependency
- cost price, accounting/profit fields, stock movements, direct post-create stock adjustment
- schema version changes, Drift migrations, generated database edits
- login, cloud sync, backend/API, ads, POS, supplier, or reporting scope.

### Testing Requirements

- RED-GREEN-REFACTOR per task; prove new tests fail before implementation.
- Pure validator/use-case tests must cover every boundary and exact repository-call behavior.
- Controller tests use fake repository/use case outcomes and controlled completers; no wall-clock sleeps.
- Widget tests must assert semantics and behavior, not only widget presence.
- Use a real in-memory `AppDatabase` only for the single end-to-end persistence seam; use overrides/fakes for presentation cases.
- Preserve all existing `78` tests and run the complete suite plus `flutter analyze`.
- No schema change means no build_runner, schema snapshot, or migration test update is expected.

### Project Structure Notes

- Dependency direction remains `presentation -> domain -> data -> core database`.
- Feature providers are the composition boundary and may construct the DAO/repository from app-level dependencies; widgets may not import DAO/database/data implementation types.
- Shared `core` code must remain feature-independent. Product-specific validation/failure copy stays under `features/products`.
- Keep files beginner-readable and avoid unnecessary code generation or framework abstractions.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.2: Add Product With Validation]
- [Source: _bmad-output/planning-artifacts/epics.md#Additional Requirements]
- [Source: _bmad-output/planning-artifacts/architecture.md#Non-Negotiable Consistency Rules]
- [Source: _bmad-output/planning-artifacts/architecture.md#State Management Patterns]
- [Source: _bmad-output/planning-artifacts/architecture.md#Process Patterns]
- [Source: _bmad-output/planning-artifacts/architecture.md#UX Flow Boundaries]
- [Source: _bmad-output/planning-artifacts/architecture.md#Required Implementation Test Checklist]
- [Source: _bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#AC-001: Add Product]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Add Product]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Forms]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Form Field]
- [Source: _bmad-output/implementation-artifacts/2-1-create-product-catalog-data-model-and-repository.md]
- [Source: tindatrack/lib/features/products/domain/repositories/products_repository.dart]
- [Source: tindatrack/lib/features/products/data/repositories/drift_products_repository.dart]
- [Source: tindatrack/lib/app/router/app_router.dart]
- [Source: tindatrack/lib/app/router/app_routes.dart]

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- Task 1 RED: validator/use-case tests failed because the feature validation and Add Product application boundary did not exist.
- Task 1 GREEN: 14 focused tests and the 92-test full suite passed after adding normalized field validation and repository delegation.
- Task 2 RED: controller tests failed because feature providers, raw form parsing, and submission state did not exist.
- Task 2 GREEN: 7 controller tests and the 99-test full suite passed for validation, safe failures, duplicate-submit prevention, and disposal.
- Task 3 RED: router/form tests failed because the secondary route and Add Product screen did not exist.
- Task 3 GREEN: 9 focused route/form tests and the 105-test full suite passed for exact fields, validation focus, saving state, feedback, and navigation.
- Task 4 coverage: 21 focused tests passed after adding back navigation, numeric edge cases, unexpected-error redaction, small-screen accessibility, and real SQLite provider composition.
- Task 4 GREEN: the complete 110-test suite passed with all Story 2.2 proof gates active.
- Task 5 GREEN: 70 source/test files were format-clean, Flutter analysis reported no issues, 35 focused tests passed, and the complete suite passed 110/110 tests. No build or launch was required because no schema, dependency, or platform integration changed.
- Code review patches GREEN: 38 focused Story 2.2 tests passed, Flutter analysis reported no issues, and the complete suite passed 113/113 tests.

### Implementation Plan

- Follow task order with red-green-refactor; keep persistence and presentation verification separate.
- Use field-specific domain validation, a thin Add Product use case, feature-owned Riverpod composition, and a controller state model that never exposes raw failures.

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.
- Task 1 complete: added framework-independent normalization/validation and a repository-backed Add Product use case with full boundary tests.
- Task 2 complete: composed feature dependencies and added disposal-safe, presentation-safe Riverpod form submission state.
- Task 3 complete: added the Products child route, minimal add entry action, and accessible Add Product form with safe save feedback.
- Task 4 complete: proved routing, controller, widget, accessibility, error-redaction, and real persistence behavior.
- Task 5 complete: format, analysis, focused, and full regression gates passed; Story 2.1 changes were preserved and nothing was staged or committed.
- Code review complete: locked fields during saves, protected pending navigation, returned visibly to Products after branch switches, proved validated small-screen semantics, and allowed duplicate names through real SQLite.

### File List

- `_bmad-output/implementation-artifacts/2-2-add-product-with-validation.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `_bmad-output/implementation-artifacts/2-2-review-prompt-blind-hunter.md`
- `_bmad-output/implementation-artifacts/2-2-review-prompt-edge-case-hunter.md`
- `_bmad-output/implementation-artifacts/2-2-review-prompt-acceptance-auditor.md`
- `tindatrack/lib/features/products/domain/failures/product_failure.dart`
- `tindatrack/lib/features/products/domain/usecases/add_product.dart`
- `tindatrack/lib/features/products/domain/validation/product_validator.dart`
- `tindatrack/lib/features/products/presentation/controllers/product_form_controller.dart`
- `tindatrack/lib/features/products/presentation/providers/product_providers.dart`
- `tindatrack/lib/app/router/app_router.dart`
- `tindatrack/lib/app/router/app_routes.dart`
- `tindatrack/lib/features/products/presentation/screens/add_product_screen.dart`
- `tindatrack/lib/features/products/presentation/screens/product_list_screen.dart`
- `tindatrack/test/features/products/domain/usecases/add_product_test.dart`
- `tindatrack/test/features/products/domain/validation/product_validator_test.dart`
- `tindatrack/test/features/products/presentation/controllers/product_form_controller_test.dart`
- `tindatrack/test/app/router/app_router_test.dart`
- `tindatrack/test/features/products/presentation/screens/add_product_screen_test.dart`
- `tindatrack/test/features/products/presentation/providers/product_providers_integration_test.dart`

## Change Log

- 2026-06-29: Created Story 2.2 with implementation-ready Add Product validation, routing, state, UX, and test guardrails.
- 2026-06-29: Completed Task 1 validation and Add Product use-case boundary with passing focused and full regression suites.
- 2026-06-29: Completed Task 2 Riverpod composition and deterministic, safe Add Product submission state.
- 2026-06-29: Completed Task 3 Products routing and Add Product form with passing focused and regression tests.
- 2026-06-29: Completed Task 4 comprehensive routing, form, accessibility, failure, and real persistence coverage.
- 2026-06-29: Completed Story 2.2 quality gates and moved the implementation to review.
- 2026-06-30: Applied all four code-review patches and completed Story 2.2 with 113 passing tests.
