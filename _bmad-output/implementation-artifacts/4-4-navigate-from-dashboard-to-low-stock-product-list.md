---
baseline_commit: 0097c74
---

# Story 4.4: Navigate From Dashboard To Low-Stock Product List

Status: review

## Story

As a store owner,
I want to tap the low-stock dashboard area,
so that I can review all products that need restocking.

## Acceptance Criteria

1. Given the Dashboard shows a Low Stock summary or preview, when the user taps the low-stock area, then the app navigates to Products and the Low Stock filter is applied.
2. Given Products opens from the Dashboard low-stock path, when the screen is displayed, then the selected Low Stock filter is visually clear and the user can return to All products.
3. Given Dashboard and Products both use low-stock behavior, when product quantity or threshold data changes, then both areas rely on the same low-stock rule and duplicate inconsistent low-stock logic is avoided.

## Tasks / Subtasks

- [x] Task 1: Add a Dashboard low-stock navigation affordance (AC: 1)
  - [x] Make the low-stock summary/preview area clearly tappable only when Dashboard content is visible.
  - [x] Prefer a compact `View Low Stock` text/action in the `Needs Restocking` section or a clear tap target on the low-stock summary area; keep 48dp tap target guidance.
  - [x] Use existing Dashboard layout, spacing, colors, and keys where possible.
  - [x] Do not navigate from the first-product empty state, summary loading state, or summary error state.

- [x] Task 2: Reuse the Products query controller when navigating (AC: 1-3)
  - [x] On Dashboard action, set `productListControllerProvider` to `ProductStockFilter.lowStock` through its existing notifier API.
  - [x] Navigate to the Products branch root using the existing `AppRoute.products` route / go_router branch.
  - [x] Do not add a new route, query parameter contract, product repository method, dashboard repository method, Drift query, schema change, or generated Drift change for this story.
  - [x] Preserve existing Products search text behavior unless the chosen implementation explicitly resets search for clarity; document and test the chosen behavior.

- [x] Task 3: Ensure Products reflects the incoming low-stock filter (AC: 2-3)
  - [x] The `Low Stock` chip must be selected after Dashboard navigation.
  - [x] The user must still be able to tap `All` to return to all active products.
  - [x] Existing product-list empty/no-match states must remain friendly and must not expose technical copy.
  - [x] Existing Product row actions for Edit, Stock In, and Stock Out must remain unchanged.

- [x] Task 4: Preserve shared low-stock rules (AC: 3)
  - [x] Use the existing `ProductStockFilter.lowStock` and product-list repository path for the full list.
  - [x] Keep Dashboard preview read-only and compact; Story 4.4 only adds navigation from Dashboard to Products.
  - [x] Do not duplicate low-stock classification in Dashboard widgets; if a helper is needed, it must delegate to existing product-list/controller concepts.
  - [x] Confirm `Out of Stock` remains distinct in the preview and product rows; this story applies the existing Low Stock filter path as specified by AC, and must not relabel Out of Stock as Low Stock.

- [x] Task 5: Add focused tests (AC: 1-3)
  - [x] Add Dashboard widget/router test proving tapping the low-stock dashboard action navigates to Products and selects the Low Stock filter.
  - [x] Add or update Product list/controller tests proving the Low Stock filter is visually selected after the controller receives the Dashboard navigation state.
  - [x] Add test coverage proving tapping `All` after Dashboard navigation resets the stock filter to all active products.
  - [x] Add regression coverage proving Dashboard first-product empty state does not show the low-stock navigation action.
  - [x] Keep tests deterministic with provider overrides; do not require real wall-clock time.

- [x] Task 6: Verify Story 4.4 completion (AC: 1-3)
  - [x] Run Dart format for touched `lib` and `test` files.
  - [x] Run focused dashboard/product/router tests touched by this story.
  - [x] Run `dart analyze`.
  - [x] Run the full Flutter test suite if focused tests and analyzer pass.
  - [x] Run `git diff --check`.

## Dev Notes

### Source Requirements

- Story 4.4 covers FR-005, FR-021, FR-022, UX-DR9, and UX-DR11. [Source: `_bmad-output/planning-artifacts/epics.md#Story 4.4: Navigate From Dashboard To Low-Stock Product List`]
- FR-005 requires a clear path to view low-stock products. [Source: `_bmad-output/planning-artifacts/epics.md#Functional Requirements`]
- Dashboard primary actions include `View Products` and `View Low Stock`; Dashboard navigation includes `Low Stock filtered Products`. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Information Architecture`]
- Product List already owns filter chips for `All`, `Low Stock`, and `Out of Stock`. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Product List`]

### Current System State

- `DashboardScreen` currently renders summary cards and the `Needs Restocking` preview, but the preview is read-only from Story 4.3.
- `dashboardLowStockPreviewProvider` reads compact preview rows through `DashboardRepository.watchLowStockPreview`; keep that read-only and compact.
- `ProductListScreen` already renders filter chips and reads `productListControllerProvider` plus `activeProductsProvider`.
- `ProductListController.stockFilterChanged(ProductStockFilter.lowStock)` already applies the Low Stock filter immediately.
- `activeProductsProvider` already passes `ProductListQuery` to `ProductRepository.watchActiveProducts`, so Products owns the full-list filtering path.
- `ProductsDao.watchActiveProducts` implements Low Stock as positive quantity at or below threshold and Out of Stock as zero quantity. Do not rewrite that in Dashboard.
- `AppRoute.products.path` is `/products`; bottom navigation uses a four-branch `StatefulShellRoute.indexedStack`.

### Architecture Compliance

- Keep Dashboard read-only: no product creation/edit/archive, stock in/out, stock movement insert, settings write, schema change, or generated Drift update belongs here. [Source: `_bmad-output/planning-artifacts/architecture.md#Service Boundaries`]
- Widgets must not import DAOs or `AppDatabase`; screens/widgets call providers/controllers. [Source: `_bmad-output/planning-artifacts/architecture.md#Component Boundaries`]
- Features should not depend on each other directly as data layers. For this UI coordination story, use app/router and existing providers; do not make products data depend on dashboard data or vice versa. [Source: `_bmad-output/planning-artifacts/architecture.md#Rules`]
- Use existing packages only: Flutter Material, Riverpod, go_router. No new dependencies are needed.
- MVP exclusions remain out: no login, cloud sync, barcode scanner, POS/cart, supplier, accounting, remote API client, or fake future-feature UI.

### UX And Layout Guardrails

- Preserve single-column Android layout with 16dp outer padding and practical spacing. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Layout & Spacing`]
- Common tap targets should be at least 48dp. [Source: `_bmad-output/planning-artifacts/epics.md#NonFunctional Requirements`]
- Keep the action calm and utilitarian; avoid nested cards, decorative gradients, heavy shadows, and clutter. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Elevation & Depth`]
- Warnings must not rely on color alone; visible labels for Low Stock and Out of Stock must remain. [Source: `_bmad-output/planning-artifacts/epics.md#UX Design Requirements`]

### Suggested Implementation Shape

- Likely update:
  - `tindatrack/lib/features/dashboard/presentation/screens/dashboard_screen.dart`
  - `tindatrack/test/features/dashboard/presentation/screens/dashboard_screen_test.dart`
  - `tindatrack/test/features/products/presentation/screens/product_list_search_filter_screen_test.dart` or an app/router integration test
  - Possibly `tindatrack/test/widget_test.dart` if root app navigation coverage is the cleanest path
- Likely imports for Dashboard action:
  - `go_router` for navigation
  - `AppRoute` for the Products path/name
  - `ProductStockFilter` and `productListControllerProvider` to set the existing Products query
- Suggested keys:
  - `Key('dashboard-view-low-stock-action')`
  - Keep existing `dashboard-low-stock-preview-section` and `dashboard-summary-low-stock` keys.

### Testing Requirements

- Use provider overrides rather than real database setup where practical.
- A Dashboard-only widget test can assert the action is present and invokes a fake router path if wrapped with a test router.
- An integration-style widget test with `MainApp`/`createAppRouter` should prove the Products branch is selected and `Low Stock` chip is selected after tapping the Dashboard action.
- A ProductList test should prove `Low Stock` selected state can return to `All` by tapping the `All` chip.
- Include an empty-dashboard regression proving no low-stock navigation action appears when no products exist.
- Run from a Windows temp copy if Flutter commands fail from the UNC workspace; CMD does not support UNC current directories.

### Previous Story Intelligence

- Story 4.3 completed and pushed at `a5539bb`, with review fixes at `286d0c8` and review artifact sync at `0097c74`.
- Story 4.3 added `DashboardLowStockPreviewItem`, `DashboardRepository.watchLowStockPreview`, `dashboardLowStockPreviewProvider`, and the `Needs Restocking` section.
- Review fixes clamped preview limits, added deterministic ordering, avoided preview subscription before content visibility, hardened preview row layout for narrow/high-text screens, and strengthened tests.
- Do not regress Story 4.3 behavior: preview loading/error/empty states remain inline, summary cards remain visible, and first-product empty state hides the preview section.
- Story 4.4 should be the first story to make the low-stock Dashboard area interactive; do not add recent activity navigation because Story 4.5 owns recent activity.

### Git Intelligence

- `0097c74 Record Story 4.3 review findings`
- `286d0c8 Fix Story 4.3 dashboard review findings`
- `a5539bb Complete Story 4.3 dashboard low stock preview`
- `595de64 Finalize Story 4.2 review status`
- `aad3c4a Complete Story 4.2 dashboard summary screen`

Recent Dashboard work keeps feature code under `lib/features/dashboard`, mirrors tests under `test/features/dashboard`, uses Riverpod provider overrides for deterministic widget tests, and verifies Flutter from a Windows temp copy when UNC workspace tooling blocks direct Flutter commands.

### Project Structure Notes

- This story should not create a separate `low-stock` route unless the existing router/controller approach cannot satisfy AC. The product list already has the filter state; prefer reusing it.
- Avoid product feature data-layer changes unless tests prove current product filter behavior cannot support Dashboard navigation.
- Keep Dashboard and Products connected through app-level navigation/state coordination, not through repository coupling.

## Dev Agent Record

### Agent Model Used

Codex GPT-5

### Debug Log References

- Focused Story 4.4 tests initially exposed a narrow-screen text-scale overflow in the new Dashboard action header; the header/action layout was changed from horizontal to vertical.
- Verification ran from `C:\tmp\tindatrack-story-4-4-verify-20260713` because Flutter commands cannot use the UNC workspace as a CMD current directory.
- `flutter test test/features/dashboard/presentation/screens/dashboard_screen_test.dart test/features/products/presentation/screens/product_list_search_filter_screen_test.dart` passed with 18 tests.
- `dart analyze` passed with no issues.
- Full `flutter test` passed with 326 tests.
- `git diff --check` passed.

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.
- Added a Dashboard `View Low Stock` action in the `Needs Restocking` section.
- Dashboard action applies the existing Products `ProductStockFilter.lowStock` through `productListControllerProvider` before navigating to `/products`.
- Preserved the existing Products query/filter pipeline; no new routes, repositories, Drift queries, schema changes, or generated files were added.
- Product List can still switch from Low Stock back to All.
- First-product Dashboard empty state continues to hide the low-stock navigation action.

### File List

- `_bmad-output/implementation-artifacts/4-4-navigate-from-dashboard-to-low-stock-product-list.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `tindatrack/lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- `tindatrack/test/features/dashboard/presentation/screens/dashboard_screen_test.dart`
- `tindatrack/test/features/products/presentation/screens/product_list_search_filter_screen_test.dart`

### Change Log

- 2026-07-13: Created Story 4.4 implementation guide and marked it ready for development.
- 2026-07-13: Implemented Dashboard-to-Low-Stock Products navigation and marked Story 4.4 ready for review.
