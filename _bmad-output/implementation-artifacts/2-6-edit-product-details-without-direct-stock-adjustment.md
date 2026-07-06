---
baseline_commit: fe9c9396285ad06480b72ff7d3acd01057e951f4
---

# Story 2.6: Edit Product Details Without Direct Stock Adjustment

Status: done

## Story

As a store owner,
I want to edit product details without changing movement history,
so that product information stays accurate while stock changes remain auditable.

## Acceptance Criteria

1. **Given** an existing active product
   **When** the user opens Edit Product
   **Then** the form allows editing name, category, unit, selling price, low-stock threshold, and barcode if barcode input is present
   **And** the form does not allow direct post-creation quantity edits.

2. **Given** the user enters valid edited details
   **When** the user saves
   **Then** the product is updated locally
   **And** the user receives success feedback such as `Product updated.`

3. **Given** the user enters a duplicate non-null barcode already used by an active or archived product
   **When** the user saves
   **Then** saving is blocked
   **And** friendly copy explains that the barcode is already used by another product.

4. **Given** a product is renamed or its unit changes
   **When** future stock movement history is displayed
   **Then** the product catalog change does not delete or rewrite existing movement records
   **And** future movement snapshots can preserve readable history.

## Tasks / Subtasks

- [x] Task 1: Add edit-only domain contracts and reuse canonical validation (AC: #1, #2, #3, #4)
  - [x] Add `UpdateProductInput` under `features/products/domain/entities`; include only `name`, optional `category`, `unit`, `sellingPrice`, `lowStockThreshold`, and optional `barcode`.
  - [x] Keep `productId` as a separate use-case/repository argument so it cannot be edited accidentally.
  - [x] Do not put `quantity`, `isArchived`, `createdAt`, `updatedAt`, or generated IDs in `UpdateProductInput`.
  - [x] Extend `ProductValidator` through shared private detail rules or a common details contract; do not duplicate name/unit/price/threshold normalization between Add and Edit.
  - [x] Preserve duplicate product-name behavior: names are not unique.
  - [x] Add typed not-found and archived-product failures if needed; never use raw Drift/SQLite exceptions as presentation state.
  - [x] Add `GetProduct` and `UpdateProduct` use cases or equivalently explicit domain boundaries; widgets/controllers must not call repositories or DAOs directly.

- [x] Task 2: Implement a partial metadata update in DAO and repository (AC: #1, #2, #3, #4)
  - [x] Add an ID lookup that can distinguish an existing active product from missing/archived state.
  - [x] Add a DAO update constrained to the target product ID; update only editable detail columns plus `updated_at`.
  - [x] Never update `quantity`, `created_at`, `is_archived`, or `id`; never insert, delete, archive, or create a stock movement from Edit Product.
  - [x] Use `_clock.now().toUtc()` for `updatedAt`; do not call `DateTime.now()` directly and do not generate a new ULID.
  - [x] Normalize a blank/whitespace barcode to `null`.
  - [x] Allow the product to retain its own unchanged non-null barcode.
  - [x] Map a barcode collision with any other active or archived row to `DuplicateBarcodeFailure`.
  - [x] Map all other database exceptions to `PersistenceFailure` with private diagnostics only.
  - [x] Return the persisted updated `Product`, and let Drift table notifications refresh the active-products stream.
  - [x] Do not add a schema version, migration, generated schema snapshot, dependency, or new table.

- [x] Task 3: Compose product loading and edit submission with Riverpod (AC: #1, #2, #3)
  - [x] Add parameterized, auto-disposed product loading keyed by immutable product ID; use a stable `String` family parameter.
  - [x] Compose `GetProduct` and `UpdateProduct` providers from the existing `productRepositoryProvider`.
  - [x] Add an edit controller that owns loading/save/error state, prevents duplicate submissions, and ignores completion after disposal.
  - [x] Reuse `ProductFormState`, parsing helpers, validation messages, and form-level safe failure copy where practical instead of cloning Add Product logic.
  - [x] Keep field errors associated with the correct input and focus the first invalid editable field.
  - [x] Map duplicate barcode to `Barcode already used by another product.` and persistence failures to friendly retryable copy.

- [x] Task 4: Build the Edit Product route and accessible form (AC: #1, #2, #3)
  - [x] Add a named Products child route with canonical path `/products/:productId/edit`; read `productId` from `GoRouterState.pathParameters`.
  - [x] Load by product ID so direct navigation and process-safe routing do not depend on passing a mutable `Product` through `extra`.
  - [x] Prefill name, category, unit, selling price, low-stock threshold, and manual barcode when present.
  - [x] Do not render an editable quantity field. Show current quantity as read-only context with plain guidance that stock changes use Stock In/Out.
  - [x] Exclude cost price, archive controls, scanner UI, Stock In/Out controls, history mutation, login, cloud, and ads.
  - [x] Show lightweight loading, friendly unavailable/not-found state, and retry or back navigation without exposing diagnostics.
  - [x] During save, disable inputs/back navigation, prevent double submission, dismiss the keyboard, and show button-level `Saving...` progress.
  - [x] On success, show exact or equivalent friendly feedback `Product updated.` and return to Products so the watched list shows current data.
  - [x] Keep the form scrollable and safe at 360x640 with 2x text; preserve accessible labels, inline error semantics, and the 48dp save target.

- [x] Task 5: Provide a real edit entry point without pre-implementing Story 2.8 (AC: #1, #2)
  - [x] Make an active product row open its Edit Product route using the stable product ID.
  - [x] Extend the existing manually merged row semantics so the edit action is announced and operable; do not silently hide tap semantics behind `excludeSemantics`.
  - [x] Preserve row keys, name/category-or-unit/quantity/status copy, lazy 3,000-row rendering, 2x-text safety, and search/filter state.
  - [x] Keep the interaction minimal. Story 2.8 owns the final accessible row-action pattern and future action-slot structure.
  - [x] Do not expose active or fake Stock In/Out buttons or routes in this story.

- [x] Task 6: Prove update isolation, UX, and regressions (AC: #1, #2, #3, #4)
  - [x] Domain/use-case tests: normalization, invalid fields, no quantity field, repository short-circuit on invalid input, and typed failure passthrough.
  - [x] DAO/repository tests: editable fields update; `quantity`, `id`, `createdAt`, and archive state remain unchanged; `updatedAt` uses the injected UTC clock; no ID is generated.
  - [x] Barcode tests: blank becomes `null`, unchanged self-barcode succeeds, duplicate active barcode fails, and duplicate archived barcode fails.
  - [x] Missing/archived target tests: save is rejected with a typed failure and no row changes.
  - [x] Reactive test: the existing active-products watch emits the updated name/unit/threshold without manual cache invalidation.
  - [x] Router tests: named path generation encodes `productId`, builder receives the correct path parameter, and back returns to Products.
  - [x] Controller tests: prefilled target, success, field validation, duplicate barcode, persistence failure, unknown error, double-submit protection, and disposal safety.
  - [x] Widget tests: exact editable fields, no editable quantity/cost price, read-only current quantity guidance, prefilled values, save feedback, loading/error/not-found states, and 360x640 at 2x text.
  - [x] Product-list flow test: row edit navigation preserves current search/filter controller state and updated data reappears through Drift.
  - [x] Run formatter, analyzer, focused tests, the full Flutter suite, and `git diff --check`.

### Review Findings

- [x] [Review][Patch] Enforce metadata-only updates at the DAO boundary [tindatrack/lib/core/database/daos/products_dao.dart:53]
- [x] [Review][Patch] Prevent rapid taps from stacking duplicate edit routes [tindatrack/lib/features/products/presentation/screens/product_list_screen.dart:263]
- [x] [Review][Patch] Keep clock failures inside the repository Result boundary [tindatrack/lib/features/products/data/repositories/drift_products_repository.dart:102]
- [x] [Review][Patch] Correct the archived-product lookup contract documentation [tindatrack/lib/features/products/domain/repositories/products_repository.dart:12]
- [x] [Review][Patch] Prevent duplicate screen-reader announcements for read-only quantity [tindatrack/lib/features/products/presentation/screens/edit_product_screen.dart:226]
- [x] [Review][Patch] Make the product-list flow test exercise the row and reactive update path [tindatrack/test/features/products/presentation/screens/product_edit_navigation_flow_test.dart:49]
- [x] [Review][Patch] Add the required edit loading/error/validation and Back-navigation coverage [tindatrack/test/features/products/presentation/screens/edit_product_screen_test.dart:21]

## Dev Notes

### Non-Negotiable Update Contract

| Field | Edit behavior |
| --- | --- |
| `name` | Editable, trimmed, required |
| `category` | Editable, trimmed, blank becomes `null` |
| `unit` | Editable, trimmed, required |
| `sellingPrice` | Editable, finite and non-negative |
| `lowStockThreshold` | Editable, integer `0...999999` |
| `barcode` | Editable if shown, trimmed by repository, blank becomes `null`, unique across all rows |
| `quantity` | Read-only; never part of update input or companion |
| `id` | Immutable |
| `createdAt` | Immutable |
| `updatedAt` | Replaced with injected UTC clock value after successful update |
| `isArchived` | Immutable in this story |

Use a partial `ProductsCompanion` update. Do not use a full-row replace assembled from stale screen data: future Stock In/Out may update quantity while an edit form is open, and metadata save must never overwrite that current quantity.

### Current Files To Extend

- `tindatrack/lib/core/database/daos/products_dao.dart`
  - Current: insert plus watched active search/status query.
  - Change: add ID lookup and an ID-constrained partial details update.
  - Preserve: active-only list predicate, SQL ordering, literal LIKE escaping, NUL rejection, and disjoint stock filters.
- `tindatrack/lib/features/products/data/repositories/drift_products_repository.dart`
  - Current: create, barcode normalization/constraint mapping, query mapping, Drift-to-domain mapping.
  - Change: load/update methods using the existing injected clock and failure mapping.
  - Preserve: one canonical `_toDomain`, duplicate-barcode detection, and current watch behavior.
- `tindatrack/lib/features/products/domain/repositories/products_repository.dart`
  - Add explicit product lookup and metadata update contracts; keep watched query unchanged.
- `tindatrack/lib/features/products/domain/validation/product_validator.dart`
  - Reuse current visual-order rules and `maxProductQuantity`; edit validation excludes starting quantity.
- `tindatrack/lib/features/products/presentation/controllers/product_form_controller.dart`
  - Current Add controller owns parsing, safe messages, double-submit guard, and disposal safety.
  - Extract reusable details parsing/state/message pieces only when it reduces duplication; keep Add behavior and tests unchanged.
- `tindatrack/lib/features/products/presentation/providers/product_providers.dart`
  - Compose lookup/update use cases and a parameterized product detail provider from the existing repository.
- `tindatrack/lib/features/products/presentation/screens/add_product_screen.dart`
  - Preserve all current fields, defaults, validation focus, loading, success route, and accessibility. Extract shared form widgets only if Add remains behavior-identical.
- `tindatrack/lib/features/products/presentation/screens/product_list_screen.dart`
  - Add edit navigation while preserving search, filters, async branches, retry, FAB, app-session query state, and lazy list construction.
- `tindatrack/lib/features/products/presentation/widgets/product_list_item.dart`
  - Add an explicit edit callback/semantics without losing the single merged label, status badge, quantity, stable keys, or responsive layout.
- `tindatrack/lib/app/router/app_routes.dart` and `app_router.dart`
  - Add one Products child route and builder injection seam matching the existing Add Product pattern.

Expected new files, unless a smaller reuse-oriented structure is clearer:

```text
tindatrack/lib/features/products/domain/entities/update_product_input.dart
tindatrack/lib/features/products/domain/usecases/get_product.dart
tindatrack/lib/features/products/domain/usecases/update_product.dart
tindatrack/lib/features/products/presentation/controllers/edit_product_controller.dart
tindatrack/lib/features/products/presentation/screens/edit_product_screen.dart
tindatrack/test/features/products/domain/usecases/get_product_test.dart
tindatrack/test/features/products/domain/usecases/update_product_test.dart
tindatrack/test/features/products/presentation/controllers/edit_product_controller_test.dart
tindatrack/test/features/products/presentation/screens/edit_product_screen_test.dart
```

Do not create a second repository implementation, database, form validator, or product entity.

### Architecture And Regression Guardrails

- Dependency direction remains `presentation -> domain -> data -> core database`; widgets/controllers never import Drift, DAOs, or `AppDatabase`.
- `features/products` owns metadata edit. `features/stock` exclusively owns every post-creation quantity change.
- A metadata edit is one local row update, so no stock transaction or history insert is appropriate.
- Future history readability comes from immutable movement snapshots. This story must not add the stock-movement schema early or rewrite future/previous snapshots after rename.
- Drift remains the source of truth. A successful update should naturally re-emit watched product queries.
- No optimistic mutation of the active-products list; wait for persistence success.
- Do not invalidate/reset `productListControllerProvider`; search/filter state survives edit navigation.
- Preserve Story 2.5 status derivation from current quantity/threshold. Editing threshold may change the badge/filter membership through the watched query; no manual status flag or cache is added.
- Keep duplicate names allowed. Only normalized non-null barcode is globally unique, including archived rows.
- No schema or generated-file change is expected.

### UX And Accessibility Guardrails

- Screen title: `Edit Product`.
- Primary action may be `Save Changes`; success feedback is `Product updated.`.
- Keep plain English with Filipino-friendly phrasing and no raw technical language.
- Quantity must be visibly read-only or absent as an input; guidance should prevent users from assuming the value is editable here.
- Use existing Material 3 theme, spacing tokens, form patterns, safe message row, and loading label.
- Manual barcode text entry is allowed; barcode scanner UI, route, permission, and dependency remain excluded.
- Archive is Story 2.7. The final row action pattern and future stock action slots are Story 2.8.

### Previous Story Intelligence

- Story 2.5 finished with 169/169 tests, clean analysis, and clean diff validation.
- Preserve the domain-owned stock status and shared visible/semantic label mapping.
- Preserve the review fixes: NUL-containing search returns no rows, a fired debounce releases its timer reference, and status copy has one presentation mapping.
- The list uses app-session query state, stable row keys, SQL-backed search/status filters, lazy rendering, and merged row semantics.
- Current working tree contains the uncommitted Story 2.5 review fixes and sprint/story bookkeeping. Do not reset, clean, overwrite, stage, commit, or push them unless explicitly requested.

### Git And Workspace Constraints

- Branch: `codex/complete-stories-1-1-and-1-2`; current HEAD at story creation: `fe9c939`.
- WSL workspace is authoritative. Run Flutter/Dart commands from `C:\tmp\inventory-story21` after copying only Story 2.6-changed Flutter files as needed, then audit the WSL diff.
- Preserve the nine intentional untracked Story 2.1/2.2 review/handoff files and Story 2.4 handoff file.
- Do not reset or clean the worktree.

### Locked Library And API Notes

- Use the repository's locked versions: Dart `^3.12.0`, Drift/drift_dev `^2.34.0`, drift_flutter `^0.3.0`, flutter_riverpod `^3.3.2`, go_router `^17.3.0`, and very_good_analysis `^10.2.0`.
- Do not upgrade or add packages for this story.
- Drift partial updates use a companion so absent columns stay untouched; always add an ID `where` clause.
- GoRouter dynamic segments use `:productId`, `state.pathParameters['productId']`, and named navigation `pathParameters`.
- Riverpod families should use auto-disposal for per-product screen state and a stable immutable parameter.

Official references:

- [Drift writes and partial update companions](https://drift.simonbinder.eu/dart_api/writes/)
- [Drift reactive stream invalidation after updates](https://drift.simonbinder.eu/dart_api/streams/)
- [Riverpod families](https://riverpod.dev/docs/concepts2/family)
- [go_router route path parameters](https://pub.dev/documentation/go_router/latest/topics/Configuration-topic.html)

### Scope Boundaries

Do not implement archive/restore, Stock In/Out, stock movement/history tables, product detail screen, dashboard changes, final row action menu/sheet, scanner functionality, cloud/login/API, ads, POS, suppliers, accounting, reports, localization, dependencies, or schema changes.

### Testing Baseline And Quality Gate

- Baseline before Story 2.6 implementation: 169 passing Flutter tests, clean Dart analysis, and clean `git diff --check`.
- Add tests beside mirrored `lib/` paths and use in-memory Drift for DAO/repository behavior.
- Run focused tests during each task, then the complete suite.
- Completion requires clean formatting, analysis, full tests, and WSL `git diff --check`; do not claim completion from focused tests alone.

### Project Structure Notes

- Product metadata edit remains entirely under `features/products`; shared code moves to `core` only if another feature already consumes it.
- Current files use plural `ProductRepository` contract naming and `DriftProductsRepository`; follow current code rather than outdated early blueprint examples.
- Architecture/epics/current code override old project-plan snippets that mention UUID, `cost_price`, direct `DateTime.now()`, raw exceptions, or obsolete dependency versions.
- No `project-context.md` exists.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.6: Edit Product Details Without Direct Stock Adjustment]
- [Source: _bmad-output/planning-artifacts/epics.md#Additional Requirements]
- [Source: _bmad-output/planning-artifacts/architecture.md#Non-Negotiable Consistency Rules]
- [Source: _bmad-output/planning-artifacts/architecture.md#Communication Patterns]
- [Source: _bmad-output/planning-artifacts/architecture.md#Architectural Boundaries]
- [Source: _bmad-output/planning-artifacts/architecture.md#Product Handoff Notes]
- [Source: _bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#AC-002: Edit Product]
- [Source: _bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#Edge Cases]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Form Field]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Edit Product]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Forms]
- [Source: _bmad-output/implementation-artifacts/2-5-show-low-stock-and-out-of-stock-product-status.md]
- [Source: tindatrack/lib/features/products/presentation/controllers/product_form_controller.dart]
- [Source: tindatrack/lib/features/products/presentation/screens/add_product_screen.dart]
- [Source: tindatrack/lib/features/products/presentation/screens/product_list_screen.dart]
- [Source: tindatrack/lib/features/products/presentation/widgets/product_list_item.dart]
- [Source: tindatrack/lib/features/products/data/repositories/drift_products_repository.dart]
- [Source: tindatrack/lib/core/database/daos/products_dao.dart]
- [Source: tindatrack/lib/app/router/app_router.dart]

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Implementation Plan

- Add a quantity-free update contract and reuse the canonical product-detail validation path.
- Persist metadata through an active-ID-constrained partial Drift update with typed failures.
- Compose ID-keyed Riverpod loading/submission, an accessible edit route/form, and row navigation.
- Prove update isolation, barcode behavior, reactive refresh, routing, accessibility, and regressions.

### Debug Log References

- Corrected the imperative nested-route flow assertion to verify rendered Edit Product state rather than stale route-information state.
- Updated pre-existing product-row semantics assertions for the newly announced `Edit product` action.

### Completion Notes List

- Added edit-only domain/use-case contracts, typed unavailable failures, and shared detail parsing/validation without exposing quantity or persistence identity.
- Added active-product lookup and partial metadata persistence; quantity, ID, creation time, archive state, schema, dependencies, and movement history remain untouched.
- Added auto-disposed ID-keyed loading/save state, friendly failure copy, duplicate-submit/disposal protection, and reactive Drift refresh.
- Added `/products/:productId/edit`, prefilled accessible editing, read-only quantity guidance, success feedback, and stable-ID row entry while preserving list query state.
- Verified formatter, clean Dart analysis, 52 focused tests, 9 product-list screen regressions, and the complete 193-test Flutter suite.
- Resolved all 7 code-review patches; review-focused tests passed 41/41, Dart analysis stayed clean, and the full suite passed 198/198.

### File List

- `_bmad-output/implementation-artifacts/2-6-edit-product-details-without-direct-stock-adjustment.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `tindatrack/lib/app/router/app_router.dart`
- `tindatrack/lib/app/router/app_routes.dart`
- `tindatrack/lib/core/database/daos/products_dao.dart`
- `tindatrack/lib/features/products/data/repositories/drift_products_repository.dart`
- `tindatrack/lib/features/products/domain/entities/update_product_input.dart`
- `tindatrack/lib/features/products/domain/failures/product_failure.dart`
- `tindatrack/lib/features/products/domain/repositories/products_repository.dart`
- `tindatrack/lib/features/products/domain/usecases/get_product.dart`
- `tindatrack/lib/features/products/domain/usecases/update_product.dart`
- `tindatrack/lib/features/products/domain/validation/product_validator.dart`
- `tindatrack/lib/features/products/presentation/controllers/edit_product_controller.dart`
- `tindatrack/lib/features/products/presentation/controllers/product_form_controller.dart`
- `tindatrack/lib/features/products/presentation/providers/product_providers.dart`
- `tindatrack/lib/features/products/presentation/screens/edit_product_screen.dart`
- `tindatrack/lib/features/products/presentation/screens/product_list_screen.dart`
- `tindatrack/lib/features/products/presentation/widgets/product_list_item.dart`
- `tindatrack/test/app/router/app_router_test.dart`
- `tindatrack/test/features/products/data/repositories/drift_products_repository_update_test.dart`
- `tindatrack/test/features/products/domain/product_domain_test.dart`
- `tindatrack/test/features/products/domain/usecases/add_product_test.dart`
- `tindatrack/test/features/products/domain/usecases/update_product_test.dart`
- `tindatrack/test/features/products/presentation/controllers/edit_product_controller_test.dart`
- `tindatrack/test/features/products/presentation/controllers/product_form_controller_test.dart`
- `tindatrack/test/features/products/presentation/providers/product_providers_test.dart`
- `tindatrack/test/features/products/presentation/providers/product_query_provider_test.dart`
- `tindatrack/test/features/products/presentation/screens/add_product_screen_test.dart`
- `tindatrack/test/features/products/presentation/screens/edit_product_screen_test.dart`
- `tindatrack/test/features/products/presentation/screens/product_edit_navigation_flow_test.dart`
- `tindatrack/test/features/products/presentation/screens/product_list_screen_test.dart`
- `tindatrack/test/features/products/presentation/widgets/product_list_item_test.dart`

### Change Log

- 2026-07-02: Implemented and verified Story 2.6; moved status to `review`.
- 2026-07-06: Resolved all code-review findings and moved Story 2.6 to done.
