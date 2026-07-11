---
baseline_commit: 4fad416907209de8dbe9756997134e0c5e2bfbbf
---

# Story 3.7: Activate Product Row Stock Movement Actions

Status: done

## Story

As a store helper,
I want Stock In and Stock Out actions available from each active product row,
So that I can record inventory movement without extra searching.

## Acceptance Criteria

1. Given an active product row is displayed after Stock In and Stock Out screens exist, when the user views available row actions, then Stock In and Stock Out actions are available from the row or accessible row action pattern, and the actions are easy to tap on small Android screens.
2. Given the user taps Stock In from a product row, when the action is selected, then the app opens the Stock In flow for that product, and the selected product identity is preserved.
3. Given the user taps Stock Out from a product row, when the action is selected, then the app opens the Stock Out flow for that product, and the selected product identity is preserved.
4. Given archived products are hidden from the default active product list, when row stock movement actions are displayed, then archived products do not expose Stock In or Stock Out actions from the active list.

## Tasks / Subtasks

- [x] Task 1: Extend product row action presentation (AC: 1, 4)
  - [x] Update `tindatrack/lib/features/products/presentation/widgets/product_row_actions.dart` to expose Stock In, Stock Out, and Edit actions for one active product row.
  - [x] Keep `ProductRowActions` presentation-only: it receives callbacks and product identity/name, and it must not call repositories, DAOs, stock controllers, or go_router directly.
  - [x] Use familiar Material icons and tooltips/semantics such as `Stock In <productName>`, `Stock Out <productName>`, and `Edit <productName>`.
  - [x] Add stable product-keyed keys, for example `product-stock-in-action-<id>`, `product-stock-out-action-<id>`, and preserve `product-edit-action-<id>`.
  - [x] Keep each action at least 48dp and usable on a 360px-wide Android screen with enlarged text.
  - [x] Choose a compact accessible row action pattern that does not overflow. Direct icon buttons are acceptable if they fit; a menu/action sheet is acceptable if tests prove Stock In and Stock Out are available and tappable.

- [x] Task 2: Thread callbacks through product list rows (AC: 1, 2, 3, 4)
  - [x] Update `ProductListItem` to accept `onStockIn` and `onStockOut` callbacks alongside `onEdit`.
  - [x] Pass the callbacks into `ProductRowActions` without changing product row display data, stock badges, row semantics for product information, or Edit behavior.
  - [x] Keep product rows scoped to active products supplied by `activeProductsProvider`; do not introduce archived product queries or archive restore behavior in this story.

- [x] Task 3: Navigate from active product rows to existing stock flows (AC: 2, 3)
  - [x] Update `_ProductList` in `product_list_screen.dart` to open `ProductRoute.stockIn.name` and `ProductRoute.stockOut.name` with `pathParameters: {'productId': product.id}`.
  - [x] Reuse the existing duplicate-navigation guard pattern around `_openingProductId`; while one row action is navigating, disable row actions so repeated taps do not stack routes.
  - [x] Unfocus search/keyboard before navigation, matching the existing Edit navigation behavior.
  - [x] Do not create new Stock In/Stock Out screens, routes, controllers, repository calls, dialogs, confirmation flows, or history writes here. Story 3.4 and 3.5 already own the real stock flows.

- [x] Task 4: Add focused widget and navigation tests (AC: 1, 2, 3, 4)
  - [x] Update `product_row_actions_test.dart` to assert all three actions render with stable keys, accessible labels/tooltips, 48dp tap targets, disabled callback behavior, and no Archive action.
  - [x] Update `product_list_item_test.dart` to prove product information semantics remain distinct from the row actions and all callbacks fire independently.
  - [x] Update `product_list_screen_test.dart` or add a focused navigation test to prove tapping row Stock In opens `/products/<id>/stock-in` and tapping row Stock Out opens `/products/<id>/stock-out` with the selected product ID preserved.
  - [x] Test the out-of-stock row still exposes Stock Out from the active list; validation/blocking belongs inside the Stock Out flow, not this row action surface.
  - [x] Test active-list scoping by using the fake active-products stream: archived products should not appear, so they should not expose row stock actions.
  - [x] Keep existing Add Product, Edit, search/filter, 3,000-product lazy list, small-screen, and accessibility tests passing.

- [x] Task 5: Verify Story 3.7 completion (AC: 1, 2, 3, 4)
  - [x] Run focused product row/product list/router tests.
  - [x] Run Dart format for `lib` and `test`.
  - [x] Run Dart analyzer.
  - [x] Run the full Flutter test suite.
  - [x] Run WSL `git diff --check`.


  ### Review Findings

  - [x] [Review][Patch] Reset row navigation guard when route push fails [tindatrack/lib/features/products/presentation/screens/product_list_screen.dart]
  - [x] [Review][Patch] Prove Stock In and Stock Out remain tappable on small enlarged-text screens [tindatrack/test/features/products/presentation/screens/product_list_screen_test.dart]
  - [x] [Review][Patch] Make archived-product absence test non-vacuous with a mixed source list [tindatrack/test/features/products/presentation/screens/product_list_screen_test.dart]
  - [x] [Review][Patch] Remove literal backtick-n artifacts from row action doc comments [tindatrack/lib/features/products/presentation/widgets/product_row_actions.dart]
## Dev Notes

### Source Requirements

- Story 3.7 covers FR-023, FR-024, FR-027, UX-DR12, and NFR-008. [Source: `_bmad-output/planning-artifacts/epics.md#Story 3.7: Activate Product Row Stock Movement Actions`]
- Product rows must provide quick access to Edit, Stock In, and Stock Out. [Source: `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#Product List And Search`; `_bmad-output/planning-artifacts/epics.md#UX Design Requirements`]
- Stock In/Stock Out navigation starts from Products and opens the existing secondary flows. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Information Architecture`; `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Product List`]
- Common tap targets must be at least 48dp and text must remain readable at system font scaling. [Source: `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#Non-Functional Requirements`; `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Accessibility Floor`]
- Archived products are hidden from the default active product list and cannot receive Stock In/Out unless restored first. [Source: `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#Product Management`; `_bmad-output/planning-artifacts/architecture.md#Required Implementation Test Checklist`]

### Current System State

- `ProductRoute.stockIn` and `ProductRoute.stockOut` already exist with paths `/products/:productId/stock-in` and `/products/:productId/stock-out`.
- `createAppRouter` already registers Stock In and Stock Out as Products-branch child routes and passes `productId` from `GoRouterState.pathParameters`.
- `StockInScreen` and `StockOutScreen` already load the selected product through `productByIdProvider(productId)` and perform the real record flow. Row actions should only navigate to these screens.
- `ProductListScreen` currently opens Add Product and Edit Product only. `_ProductListState` has `_openingProductId` and `_openEditProduct(...)` to guard duplicate navigation and reset after `pushNamed` completes.
- `ProductListItem` currently displays product name, category/unit, quantity, stock badge, and one `ProductRowActions` child.
- `ProductRowActions` currently exposes only Edit with key `product-edit-action-<productId>`, tooltip/semantics `Edit <productName>`, and a 48dp `IconButton`.
- `activeProductsProvider` is the active-list boundary. Archived products should remain absent through that provider; do not query archived products in presentation.

### Architecture Compliance

- Use Flutter Material 3, Riverpod, go_router, and existing Clean Architecture boundaries; do not add dependencies.
- Keep stock mutation logic inside `features/stock` and the existing Stock In/Stock Out screens/controllers. Product row actions must not call `StockRepository.recordStockIn` or `recordStockOut` directly.
- Widgets must not access Drift, DAOs, database rows, ID generators, clocks, or persistence failures directly.
- Keep `features/products/presentation` responsible for product list row UI and navigation callbacks only.
- Preserve list laziness and performance for up to 3,000 local products. Do not replace `ListView.separated` with a static column.
- Keep MVP exclusions out: no scanner, POS/cart, supplier, accounting, login, cloud sync, movement editing/deletion, reason selector, export, reports, or new History behavior.
- Use simple English with Filipino-friendly clarity. Recommended labels: `Stock In`, `Stock Out`, `Edit`, `Stock In Rice`, `Stock Out Rice`.

### Files Expected To Change

- `tindatrack/lib/features/products/presentation/widgets/product_row_actions.dart`
- `tindatrack/lib/features/products/presentation/widgets/product_list_item.dart`
- `tindatrack/lib/features/products/presentation/screens/product_list_screen.dart`
- `tindatrack/test/features/products/presentation/widgets/product_row_actions_test.dart`
- `tindatrack/test/features/products/presentation/widgets/product_list_item_test.dart`
- `tindatrack/test/features/products/presentation/screens/product_list_screen_test.dart` or a new focused product row navigation test
- `_bmad-output/implementation-artifacts/3-7-activate-product-row-stock-movement-actions.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

### Testing Requirements

- Follow existing product widget test style: `MaterialApp`, `AppTheme.light`, stable keys, and semantics assertions.
- Follow existing product list screen test style: fake `activeProductsProvider` streams, `ProviderScope` overrides, and `MaterialApp.router`/`GoRouter` route harnesses.
- Include route builders for Stock In and Stock Out that display the received `productId`, so tests prove identity preservation rather than only screen presence.
- Preserve existing assertions that Product List is lazy for 3,000 rows and fits a 360x640 viewport with text scale 2.
- Do not duplicate Stock In/Out form validation tests; those belong to Story 3.4/3.5 test files. This story tests action availability and navigation only.
- For Flutter verification from this UNC workspace, use the established Windows temp-copy pattern if direct Flutter/Dart commands hang or fail.

### Previous Story Intelligence

- Story 3.4 completed Stock In route, screen, controller, provider invalidation, friendly feedback, and focused route/controller/screen tests.
- Story 3.5 completed Stock Out route, screen, controller, duplicate-submit guard, friendly insufficient-stock handling, provider invalidation, and focused route/controller/screen tests. It explicitly deferred product-row Stock Out buttons to Story 3.7.
- Story 3.6 completed the read-only History list and did not add product-row actions or History filters. History remains read-only; no Story 3.7 work should touch movement history UI.
- Recent git commits show the same progression: `b76e67a Complete stock in screen`, `4fad416 Prepare stock out screen story`; Story 3.5/3.6 implementation files are currently uncommitted in this working tree.
- Prior verification ran from a local Windows copy under `C:\tmp` because Flutter tooling cannot reliably run from the UNC WSL path.

### Latest Technical Notes

- Current package versions are already pinned in `tindatrack/pubspec.yaml`: `go_router ^17.3.0`, `flutter_riverpod ^3.3.2`, `drift ^2.34.0`, and Dart SDK `^3.12.0`.
- No dependency upgrade or web research is needed for this story. Use existing Flutter `IconButton`, `Semantics`, `Tooltip`, `MenuAnchor`/`PopupMenuButton` if already acceptable without new packages, and existing go_router APIs.

### Project Structure Notes

- This story should stay in presentation files under `features/products`. It should not add domain entities, repository methods, Drift migrations, stock use cases, or new app routes.
- If a compact action-menu implementation is chosen, keep the menu widget within `ProductRowActions` or a sibling presentation widget under `features/products/presentation/widgets`.
- If direct icon buttons are chosen, verify they do not crowd long product names or overflow at text scale 2.

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- 2026-07-11: Created Story 3.7 context from Epic 3, PRD, UX, architecture, existing Product List action seam, and Story 3.4-3.6 implementation learnings.

### Completion Notes List

- Implemented direct 48dp row actions for Stock In, Stock Out, and Edit with product-keyed stable keys, tooltips, and semantics labels.
- Threaded Stock In/Stock Out callbacks through active product list rows and routed them to the existing ProductRoute.stockIn/ProductRoute.stockOut flows with selected productId preserved.
- Reused the product-list duplicate navigation guard and keyboard unfocus behavior for all row actions.
- Added focused widget and navigation coverage for action availability, callback independence, out-of-stock Stock Out availability, archived-product absence from active list, route identity preservation, small-screen accessibility, and existing list behavior.
- Verification passed: focused product row/list/screen tests, dart format, dart analyze, full Flutter test suite, and WSL git diff --check.
- Code review resolved 4 patch findings: route reset safety, small-screen tappability proof, non-vacuous archived-product coverage, and doc-comment cleanup.

### File List

- _bmad-output/implementation-artifacts/3-7-activate-product-row-stock-movement-actions.md
- _bmad-output/implementation-artifacts/sprint-status.yaml
- tindatrack/lib/features/products/presentation/screens/product_list_screen.dart
- tindatrack/lib/features/products/presentation/widgets/product_list_item.dart
- tindatrack/lib/features/products/presentation/widgets/product_row_actions.dart
- tindatrack/test/features/products/presentation/screens/product_list_screen_test.dart
- tindatrack/test/features/products/presentation/widgets/product_list_item_test.dart
- tindatrack/test/features/products/presentation/widgets/product_row_actions_test.dart

### Change Log

- 2026-07-11: Created Story 3.7 artifact and marked it ready for dev.
- 2026-07-11: Implemented product row Stock In/Stock Out/Edit actions and marked story ready for review.
- 2026-07-11: Code review found 4 patch items; all were resolved.
