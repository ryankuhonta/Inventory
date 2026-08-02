---
baseline_commit: 961043939f2ad5a94a25c476512e36e509190399
---

# Story 3.4: Build Stock In Screen

Status: done

## Story

As a store helper,
I want a simple Stock In screen,
So that I can quickly record newly added inventory.

## Acceptance Criteria

1. Given the user opens Stock In for an active product, when the screen loads, then it shows the product name, current quantity, quantity input, optional note, and primary action, and the quantity input uses a numeric keyboard.
2. Given the user enters zero, negative, or invalid quantity, when the form is submitted, then the form shows inline validation, and no stock movement is recorded.
3. Given the user enters a valid Stock In quantity, when the form is submitted, then the save action shows button-level loading while processing, and duplicate submissions are prevented.
4. Given Stock In succeeds, when the operation completes, then the user sees friendly success feedback including the new stock count, and the previous screen or product data reflects the updated quantity.
5. Given Stock In fails, when the operation returns a typed failure, then the UI shows friendly recovery copy, and raw database or exception messages are not shown.

## Tasks / Subtasks

- [x] Task 1: Add Stock In route and screen shell (AC: 1)
  - [x] Extend `ProductRoute` with a Products-branch route such as `/products/:productId/stock-in`.
  - [x] Add the route to `createAppRouter` and pass `productId` into the Stock In screen builder.
  - [x] Create `tindatrack/lib/features/stock/presentation/screens/stock_in_screen.dart`.
  - [x] Load the selected product through the existing `productByIdProvider(productId)` / `GetProduct` path; do not query Drift from the widget.
  - [x] Show loading and unavailable-product states using existing `AppLoadingView` / `AppErrorView` style.

- [x] Task 2: Build the Stock In form UI (AC: 1, 2, 3)
  - [x] Display product name and current quantity with unit.
  - [x] Add a numeric quantity field with stable keys and accessible labels.
  - [x] Add an optional note field.
  - [x] Add a primary `Record Stock In` action with minimum 48dp tap target.
  - [x] Keep the form scrollable for small Android screens and large system font sizes.
  - [x] Disable fields/back navigation while saving and show button-level `Saving...` progress.

- [x] Task 3: Add Stock In presentation controller (AC: 2, 3, 4, 5)
  - [x] Create a focused auto-disposed Riverpod controller under `features/stock/presentation/controllers`.
  - [x] Parse raw form values into `RecordStockInInput`.
  - [x] Reject blank, non-integer, zero, and negative quantities before calling the repository.
  - [x] Guard duplicate submissions while `isSaving` is true.
  - [x] Call `ref.read(stockRepositoryProvider).recordStockIn(...)`.
  - [x] Map `StockMovementValidationFailure`, `StockProductNotFoundFailure`, `StockArchivedProductFailure`, and `PersistenceFailure` to friendly UI copy.
  - [x] Never display `debugMessage`, raw Drift errors, or exception text.

- [x] Task 4: Success behavior and state refresh (AC: 4)
  - [x] On success, show feedback like `Added 10 pcs to Rice. New stock: 18 pcs.`
  - [x] Return to the previous screen or Products branch in a way that keeps navigation predictable.
  - [x] Ensure product data refreshes after mutation; invalidate relevant product/list providers as needed.
  - [x] Do not add product-row Stock In buttons yet; Story 3.7 owns row action activation.

- [x] Task 5: Add focused tests (AC: 1, 2, 3, 4, 5)
  - [x] Router test proves the Stock In route maps under the Products branch and preserves `productId`.
  - [x] Widget test proves active product details, current quantity, numeric quantity input, note field, and primary action render.
  - [x] Widget/controller test proves invalid quantity shows inline validation and does not call `recordStockIn`.
  - [x] Test pending save disables duplicate submission and shows button-level loading.
  - [x] Test success calls `recordStockIn`, shows friendly new-stock feedback, and navigates/refreshes.
  - [x] Test typed repository failures show friendly copy without leaking debug/private diagnostics.
  - [x] Test small-screen or enlarged-text layout remains scrollable and the primary button remains usable.

- [x] Task 6: Verify Story 3.4 completion (AC: 1, 2, 3, 4, 5)
  - [x] Run focused stock/product/router tests.
  - [x] Run Dart format for `lib` and `test`.
  - [x] Run Dart analyzer.
  - [x] Run the full Flutter test suite.
  - [x] Run WSL `git diff --check`.

## Dev Notes

### Source Requirements

- Story 3.4 covers FR-024, FR-025, FR-026, FR-031, UX-DR18, UX-DR20, UX-DR25, UX-DR26, and UX-DR28. [Source: `_bmad-output/planning-artifacts/epics.md#Story 3.4: Build Stock In Screen`]
- Stock In screen must show product name, current quantity, quantity input, optional note, and primary action. [Source: `_bmad-output/planning-artifacts/epics.md#Story 3.4: Build Stock In Screen`; `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Stock In`]
- Quantity must be greater than zero and use a numeric keyboard. [Source: `_bmad-output/planning-artifacts/epics.md#Story 3.4: Build Stock In Screen`; `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Interaction Primitives`]
- Feedback must be friendly, use snackbars or inline banners, and avoid raw technical terms/errors. [Source: `_bmad-output/planning-artifacts/epics.md#UX Design Requirements`; `_bmad-output/planning-artifacts/architecture.md#API & Communication Patterns`]
- Forms must show button-level progress and prevent duplicate submissions while saving. [Source: `_bmad-output/planning-artifacts/epics.md#Story 3.4: Build Stock In Screen`; `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#State Patterns`]

### Current System State

- `RecordStockInInput` already exists with `productId`, positive `quantity`, and optional `note`.
- `StockRepository.recordStockIn` is implemented and tested. It validates positive quantity before product lookup/ID/time generation, rejects missing/archived products with typed failures, updates product quantity and inserts a `stock_in` movement in one Drift transaction, normalizes note, snapshots product name/unit, and maps persistence errors to `PersistenceFailure`.
- `stockRepositoryProvider` already composes `ProductsDao`, `StockMovementsDao`, `IdGenerator`, and `Clock`; no new repository dependency should be needed.
- Product lookup already exists via `getProductProvider` and `productByIdProvider(productId)`.
- `EditProductScreen` already demonstrates the target patterns for product loading, unavailable state, form disabling, button-level loading, `PopScope`, snackbars, and returning to Products.
- `ProductRowActions` intentionally exposes Edit only. Do not add Stock In row buttons in this story; Story 3.7 owns row action activation after both Stock In and Stock Out screens exist.

### Architecture Compliance

- Use Flutter Material 3, Riverpod, go_router, Drift, and Clean Architecture; do not add new dependencies.
- Widgets must not access DAOs or Drift generated classes directly.
- Route and presentation code should live under `lib/app/router` and `lib/features/stock/presentation`.
- Keep stock mutations routed through `features/stock` and `StockRepository.recordStockIn`.
- Keep MVP exclusions out: no scanner, POS, supplier, accounting, login, cloud sync, ads, or Stock Out reason selector work.
- Use simple English with Filipino-friendly phrasing. Good examples: `Record Stock In`, `Enter a quantity greater than 0.`, `We couldn't record stock in. Please try again.`

### Files Expected To Change

- `tindatrack/lib/app/router/app_routes.dart`
- `tindatrack/lib/app/router/app_router.dart`
- `tindatrack/lib/features/stock/presentation/screens/stock_in_screen.dart` (new)
- `tindatrack/lib/features/stock/presentation/controllers/stock_in_controller.dart` (new)
- `tindatrack/test/app/router/app_router_test.dart`
- `tindatrack/test/features/stock/presentation/screens/stock_in_screen_test.dart` (new)
- `tindatrack/test/features/stock/presentation/controllers/stock_in_controller_test.dart` (new, if controller behavior is not fully covered by widget tests)
- `_bmad-output/implementation-artifacts/3-4-build-stock-in-screen.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

### Testing Requirements

- Follow existing widget test style from `edit_product_screen_test.dart`: fake repositories/use cases, `ProviderScope` overrides, `MaterialApp.router`, stable widget keys, and assertions that private debug text is not visible.
- Follow router test style from `app_router_test.dart`: named route path, path parameter preservation, Products branch selected index, and back navigation behavior.
- Tests should cover both presentation validation and repository failure mapping. Repository transaction behavior is already covered by Story 3.2; do not duplicate deep Drift rollback tests here.
- Include a layout/accessibility guard for scrollability on small screens or enlarged text.

### Previous Story Intelligence

- Story 3.2 and Story 3.3 completed the repository layer. Do not reimplement stock mutation logic in controllers or widgets.
- Previous stock stories intentionally avoid ID/time generation and persistence calls on invalid input; Story 3.4 should preserve that externally by validating before calling `recordStockIn`.
- Story 3.3 review completed cleanly, but external reviewer subagents failed from usage limits; no code findings were applied.
- Prior verification used a Windows local copy because Flutter/Dart can hang or fail on the WSL UNC path. Use the same verification pattern when running Flutter commands if needed.

### Latest Technical Notes

- The current project already pins recent package versions in `tindatrack/pubspec.yaml`: `go_router ^17.3.0`, `flutter_riverpod ^3.3.2`, `drift ^2.34.0`, and Dart SDK `^3.12.0`.
- Official package pages currently list `go_router 17.3.0`, `flutter_riverpod 3.3.2`, and `drift 2.34.1`; this story does not require upgrading dependencies. [Source: `https://pub.dev/packages/go_router`; `https://pub.dev/packages/flutter_riverpod`; `https://pub.dev/packages/drift`]

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- 2026-07-09: Created Story 3.4 context from Epic 3, UX, architecture, existing route/product form patterns, and Story 3.2/3.3 repository implementation.
- 2026-07-09: Implemented Stock In route, screen, controller, and focused tests.
- 2026-07-09: Focused route/controller/screen tests passed on local verification copy: 22/22.
- 2026-07-09: Dart analyzer passed on local verification copy with no issues.
- 2026-07-09: Full Flutter test suite passed on local verification copy: 277/277.

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.
- Added Products-branch Stock In route with stable productId path parameter.
- Added Stock In screen with product loading, current quantity display, numeric quantity input, optional note, button-level saving state, and friendly success/failure feedback.
- Added Stock In controller that validates quantity before repository calls, guards duplicate submissions, calls recordStockIn, and maps typed failures to UI-safe copy.
- Added focused router, controller, and widget coverage for Stock In behavior, validation, loading, success, failures, and small-screen layout.

### File List

- _bmad-output/implementation-artifacts/3-4-build-stock-in-screen.md
- _bmad-output/implementation-artifacts/sprint-status.yaml
- tindatrack/lib/app/router/app_routes.dart
- tindatrack/lib/app/router/app_router.dart
- tindatrack/lib/features/stock/presentation/controllers/stock_in_controller.dart
- tindatrack/lib/features/stock/presentation/screens/stock_in_screen.dart
- tindatrack/test/app/router/app_router_test.dart
- tindatrack/test/features/stock/presentation/controllers/stock_in_controller_test.dart
- tindatrack/test/features/stock/presentation/screens/stock_in_screen_test.dart

### Change Log

- 2026-07-09: Created Story 3.4 artifact and marked it ready for dev.
- 2026-07-09: Implemented Stock In screen and moved story to review.
