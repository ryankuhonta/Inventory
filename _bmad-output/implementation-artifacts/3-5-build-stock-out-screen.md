---
baseline_commit: b76e67a2e19d69afb97c230bc21aa10aa71023c1
---

# Story 3.5: Build Stock Out Screen

Status: ready-for-dev

## Story

As a store helper,
I want a simple Stock Out screen,
So that I can quickly record sold, lost, or removed stock.

## Acceptance Criteria

1. Given the user opens Stock Out for an active product, when the screen loads, then it shows the product name, current quantity, quantity input, optional note, and primary action, and the quantity input uses a numeric keyboard.
2. Given the visible MVP form is implemented, when the user records Stock Out, then the Stock Out reason defaults to `sold`, and a visible reason selector is deferred unless separately scoped.
3. Given the user enters zero, negative, invalid, or excessive quantity, when the form is submitted, then the form shows inline validation near the quantity field, and excessive quantity shows "Not enough stock available" or equivalent friendly copy.
4. Given the user enters a valid Stock Out quantity, when the form is submitted, then the save action shows button-level loading while processing, and duplicate submissions are prevented.
5. Given Stock Out succeeds, when the operation completes, then the user sees friendly success feedback including the new stock count, and the previous screen or product data reflects the updated quantity.
6. Given Stock Out fails, when the operation returns a typed failure, then the UI shows friendly recovery copy, and raw database or exception messages are not shown.

## Tasks / Subtasks

- [ ] Task 1: Add Stock Out route and screen shell (AC: 1)
  - [ ] Extend `ProductRoute` with `/products/:productId/stock-out` and segment `:productId/stock-out`.
  - [ ] Add `stockOutBuilder` to `createAppRouter`, defaulting to a private `_buildStockOut` helper.
  - [ ] Register Stock Out as a Products-branch child route and pass `productId` from `GoRouterState.pathParameters`.
  - [ ] Create `tindatrack/lib/features/stock/presentation/screens/stock_out_screen.dart`.
  - [ ] Load the selected product through `productByIdProvider(productId)` / `GetProduct`; do not query Drift from the widget.
  - [ ] Show loading and unavailable-product states using the existing `AppLoadingView` / `AppErrorView` pattern.

- [ ] Task 2: Build the Stock Out form UI (AC: 1, 2, 3, 4)
  - [ ] Display product name and `Current quantity: <qty> <unit>`.
  - [ ] Add numeric quantity field with stable key `stock-out-quantity-field` and accessible label.
  - [ ] Add optional note field with stable key `stock-out-note-field`.
  - [ ] Add primary action `Record Stock Out` with stable key `record-stock-out-button` and minimum 48dp tap target.
  - [ ] Do not add a visible Stock Out reason selector in this story; reason must default to `sold` through domain/repository behavior.
  - [ ] Keep the form scrollable for small Android screens and large system font sizes.
  - [ ] Disable fields/back navigation while saving and show button-level `Saving...` progress.

- [ ] Task 3: Add Stock Out presentation controller (AC: 2, 3, 4, 6)
  - [ ] Create `tindatrack/lib/features/stock/presentation/controllers/stock_out_controller.dart`.
  - [ ] Use an auto-disposed Riverpod Notifier family keyed by product ID, mirroring `StockInController` conventions.
  - [ ] Parse raw form values into `RecordStockOutInput`.
  - [ ] Reject blank, non-integer, zero, negative, and over-maximum quantities before calling the repository.
  - [ ] For visible excessive quantity where current product quantity is known, show inline quantity copy `Not enough stock available.` before calling the repository.
  - [ ] Guard duplicate submissions while `isSaving` is true.
  - [ ] Call `ref.read(stockRepositoryProvider).recordStockOut(...)`; do not reimplement stock mutation logic in the controller.
  - [ ] Leave `reason` unset or pass `StockOutReason.defaultReason`; both must persist as `sold`.
  - [ ] Map `StockMovementValidationFailure`, `StockInsufficientQuantityFailure`, `StockProductNotFoundFailure`, `StockArchivedProductFailure`, and `PersistenceFailure` to friendly UI copy.
  - [ ] Never display `debugMessage`, raw Drift errors, SQL text, or exception text.

- [ ] Task 4: Success behavior and state refresh (AC: 5)
  - [ ] On success, show feedback like `Removed 3 pcs from Rice. New stock: 2 pcs.`
  - [ ] Return to the previous screen or Products branch in a predictable way, matching Stock In behavior.
  - [ ] Invalidate `productByIdProvider(product.id)` and `activeProductsProvider` after successful mutation.
  - [ ] Do not add product-row Stock Out buttons yet; Story 3.7 owns row action activation after both screens exist.

- [ ] Task 5: Add focused tests (AC: 1, 2, 3, 4, 5, 6)
  - [ ] Router test proves the Stock Out route maps under the Products branch and preserves `productId`.
  - [ ] Widget test proves active product details, current quantity, numeric quantity input, note field, and primary action render.
  - [ ] Controller/widget test proves invalid quantity shows inline validation and does not call `recordStockOut`.
  - [ ] Test excessive quantity shows `Not enough stock available.` and does not call `recordStockOut` when the current product quantity is available in presentation.
  - [ ] Test repository `StockInsufficientQuantityFailure` also maps to friendly inline quantity copy without leaking diagnostics.
  - [ ] Test pending save disables duplicate submission and shows button-level loading.
  - [ ] Test success calls `recordStockOut`, leaves/defaults reason to `sold`, shows friendly new-stock feedback, and navigates/refreshes.
  - [ ] Test typed repository failures show friendly copy without leaking debug/private diagnostics.
  - [ ] Test small-screen or enlarged-text layout remains scrollable and the primary button remains usable.

- [ ] Task 6: Verify Story 3.5 completion (AC: 1, 2, 3, 4, 5, 6)
  - [ ] Run focused stock/product/router tests.
  - [ ] Run Dart format for `lib` and `test`.
  - [ ] Run Dart analyzer.
  - [ ] Run the full Flutter test suite.
  - [ ] Run WSL `git diff --check`.

## Dev Notes

### Source Requirements

- Story 3.5 covers FR-027, FR-028, FR-029, FR-030, FR-031, UX-DR19, UX-DR20, UX-DR21, UX-DR25, UX-DR26, and UX-DR28. [Source: `_bmad-output/planning-artifacts/epics.md#Story 3.5: Build Stock Out Screen`]
- Stock Out screen must show product name, current quantity, quantity input, optional note, and primary action. [Source: `_bmad-output/planning-artifacts/epics.md#Story 3.5: Build Stock Out Screen`; `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Stock Out`]
- Quantity must be greater than zero, use numeric keyboard, and block excessive stock out with friendly inline copy near the quantity field. [Source: `_bmad-output/planning-artifacts/epics.md#Story 3.5: Build Stock Out Screen`; `_bmad-output/planning-artifacts/epics.md#UX Design Requirements`; `_bmad-output/planning-artifacts/architecture.md#Validation Strategy`]
- MVP Stock Out reason defaults to `sold`; a visible reason selector is deferred. [Source: `_bmad-output/planning-artifacts/epics.md#Story 3.5: Build Stock Out Screen`; `_bmad-output/planning-artifacts/architecture.md#Stock Movement Reasons`]
- Feedback must be friendly, use snackbars or inline banners, and avoid raw technical terms/errors. [Source: `_bmad-output/planning-artifacts/epics.md#UX Design Requirements`; `_bmad-output/planning-artifacts/architecture.md#API & Communication Patterns`]

### Current System State

- `RecordStockOutInput` already exists with `productId`, positive `quantity`, optional `reason`, and optional `note`.
- `StockOutReason.defaultReason` is `StockOutReason.sold`; `DriftStockRepository.recordStockOut` already uses `input.reason ?? StockOutReason.defaultReason`.
- `StockRepository.recordStockOut` is implemented and tested at the repository layer. It validates positive quantity before product lookup/ID/time generation, rejects missing/archived products with typed failures, rejects excessive quantity with `StockInsufficientQuantityFailure`, updates product quantity and inserts a `stock_out` movement in one Drift transaction, normalizes note, snapshots product name/unit, and maps persistence errors to `PersistenceFailure`.
- `stockRepositoryProvider` already composes `ProductsDao`, `StockMovementsDao`, `IdGenerator`, and `Clock`; no new repository dependency should be needed.
- Product lookup already exists via `getProductProvider` and `productByIdProvider(productId)`.
- `StockInScreen` and `StockInController` are the closest implementation templates. Mirror their loading, unavailable state, form disabling, button-level loading, `PopScope`, snackbar, provider invalidation, and test harness patterns.
- `ProductRowActions` intentionally exposes Edit only. Do not add Stock In or Stock Out row buttons in this story; Story 3.7 owns row action activation.

### Architecture Compliance

- Use Flutter Material 3, Riverpod, go_router, Drift, and Clean Architecture; do not add new dependencies.
- Widgets must not access DAOs or Drift generated classes directly.
- Route and presentation code should live under `lib/app/router` and `lib/features/stock/presentation`.
- Keep stock mutations routed through `features/stock` and `StockRepository.recordStockOut`.
- Keep MVP exclusions out: no scanner, POS, supplier, accounting, login, cloud sync, ads, or visible Stock Out reason selector.
- Use simple English with Filipino-friendly phrasing. Good examples: `Record Stock Out`, `Enter a quantity greater than 0.`, `Not enough stock available.`, `We couldn't record stock out. Please try again.`

### Files Expected To Change

- `tindatrack/lib/app/router/app_routes.dart`
- `tindatrack/lib/app/router/app_router.dart`
- `tindatrack/lib/features/stock/presentation/screens/stock_out_screen.dart` (new)
- `tindatrack/lib/features/stock/presentation/controllers/stock_out_controller.dart` (new)
- `tindatrack/test/app/router/app_router_test.dart`
- `tindatrack/test/features/stock/presentation/screens/stock_out_screen_test.dart` (new)
- `tindatrack/test/features/stock/presentation/controllers/stock_out_controller_test.dart` (new, if controller behavior is not fully covered by widget tests)
- `_bmad-output/implementation-artifacts/3-5-build-stock-out-screen.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

### Testing Requirements

- Follow existing widget test style from `stock_in_screen_test.dart`: fake repositories/use cases, `ProviderScope` overrides, `MaterialApp.router`, stable widget keys, and assertions that private debug text is not visible.
- Follow router test style from `app_router_test.dart`: named route path, path parameter preservation, Products branch selected index, and back navigation behavior.
- Tests should cover both presentation validation and repository failure mapping. Repository transaction behavior is already covered by Story 3.3; do not duplicate deep Drift rollback tests here.
- Include the insufficient-stock UI case explicitly. The user should see friendly copy near the quantity field and no stock movement should be recorded when the excessive quantity can be rejected before repository call.
- Include a layout/accessibility guard for scrollability on small screens or enlarged text.

### Previous Story Intelligence

- Story 3.4 added the Stock In route, controller, screen, and tests; Stock Out should follow the same architecture and naming conventions with stock-out-specific keys/copy.
- Story 3.3 completed the Stock Out repository layer. Do not reimplement transaction or quantity mutation logic in controllers or widgets.
- Previous stock stories intentionally avoid ID/time generation and persistence calls on invalid input; Story 3.5 should preserve that externally by validating before calling `recordStockOut` where possible.
- Story 3.4 verification passed: focused route/controller/screen tests 22/22, Dart analyzer with no issues, and full Flutter test suite 277/277.
- Prior verification used a Windows local copy because Flutter/Dart can hang or fail on the WSL UNC path. Use the same verification pattern when running Flutter commands if needed.

### Latest Technical Notes

- The current project already pins recent package versions in `tindatrack/pubspec.yaml`: `go_router ^17.3.0`, `flutter_riverpod ^3.3.2`, `drift ^2.34.0`, and Dart SDK `^3.12.0`.
- This story does not require dependency upgrades. Keep implementation inside existing Flutter/Riverpod/go_router/Drift patterns.

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- 2026-07-09: Created Story 3.5 context from Epic 3, UX, architecture, existing Stock In presentation patterns, and Story 3.3/3.4 stock movement implementation.

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.

### File List

- _bmad-output/implementation-artifacts/3-5-build-stock-out-screen.md
- _bmad-output/implementation-artifacts/sprint-status.yaml

### Change Log

- 2026-07-09: Created Story 3.5 artifact and marked it ready for dev.
