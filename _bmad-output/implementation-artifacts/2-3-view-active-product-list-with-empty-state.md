---
baseline_commit: f758d77cead3d1f8f921d46bd0aa9bf48a07cf72
---

# Story 2.3: View Active Product List With Empty State

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a store owner,
I want to see my active products in one list,
so that I can check current stock quickly.

## Acceptance Criteria

1. **Reactive active-product source**
   - **Given** the Products screen is open
   - **When** the local product catalog emits data
   - **Then** the screen reads through a feature-owned Riverpod provider over `ProductRepository.watchActiveProducts`
   - **And** widgets do not access Drift, `ProductsDao`, or the database directly
   - **And** active products remain ordered by name through the existing SQLite query.

2. **Lazy populated list**
   - **Given** active products exist
   - **When** the user opens Products
   - **Then** a lazy-rendered list shows active, non-archived products
   - **And** each row shows product name, category when present or unit as fallback, and current quantity with its unit
   - **And** every row has a stable product-ID key and accessible product/quantity meaning
   - **And** no edit, archive, Stock In, Stock Out, search, filter, or scanner behavior is introduced by this story.

3. **Actionable empty state**
   - **Given** no active products exist
   - **When** the user opens Products
   - **Then** the screen shows friendly copy explaining that no products exist yet
   - **And** it provides a clear `Add Product` action
   - **And** the existing Add Product floating action button remains available
   - **And** either add action opens the existing `/products/add` flow.

4. **Loading, error, and live-update behavior**
   - **Given** the product stream has not emitted yet
   - **When** Products is displayed
   - **Then** a lightweight, accessible loading state is shown.
   - **Given** the stream fails
   - **When** Products renders the failure
   - **Then** friendly recovery copy and a retry action are shown
   - **And** raw Drift, SQLite, exception, or stack-trace text is never rendered.
   - **Given** a product is created while Products remains in the navigation stack
   - **When** the repository stream emits the updated catalog
   - **Then** the screen updates without a manual refresh or a second database read path.

5. **3,000-product and accessibility floor**
   - **Given** the local catalog contains up to 3,000 active products
   - **When** the list renders
   - **Then** rows are created on demand with `ListView.builder`, `ListView.separated`, or an equivalent lazy sliver
   - **And** the implementation does not eagerly construct all row widgets
   - **And** the screen remains usable at `360x640`, with enlarged system text, readable labels, and applicable 48dp tap targets.

## Tasks / Subtasks

- [x] Task 1: Expose the existing active-product stream through Riverpod (AC: 1, 4)
  - [x] Add a feature-owned `StreamProvider<List<Product>>` in `product_providers.dart` that watches `productRepositoryProvider.watchActiveProducts()`.
  - [x] Preserve the repository and DAO as the only mapping/query boundaries; do not add a second repository, DAO query, cache, controller, or list use case without a concrete need.
  - [x] Keep stream errors inside `AsyncValue`; presentation must map them to stable safe copy rather than interpolating the error.
  - [x] Add provider tests proving subscription, emitted updates, error state, and disposal without reaching into Drift from presentation.

- [x] Task 2: Replace the Products placeholder with complete async states (AC: 1, 3, 4)
  - [x] Convert `ProductListScreen` to a Riverpod consumer and render explicit loading, empty, error, and content states.
  - [x] Reuse `AppLoadingView`, `AppEmptyState`, and `AppErrorView`; keep feature-specific safe copy in the Products presentation layer.
  - [x] Keep the existing FAB and route it through `ProductRoute.addProduct`.
  - [x] Give the empty state its own Add Product action using the same route helper/callback as the FAB.
  - [x] Retry by invalidating/refreshing the active-products provider; do not reopen or replace the app database.

- [x] Task 3: Add the lazy, accessible product row presentation (AC: 2, 5)
  - [x] Render content with a builder-backed list and a non-null `itemCount`.
  - [x] Add a small presentation-only row widget under `features/products/presentation/widgets` if that keeps the screen readable.
  - [x] Show name, category-or-unit metadata, and quantity with unit; use the product ID for a stable key.
  - [x] Keep rows read-only in this story. Do not wire edit/archive/stock actions before their owning stories.
  - [x] Do not introduce Low Stock or Out of Stock badges here; Story 2.5 owns the canonical status rule and visual priority.

- [x] Task 4: Prove the complete list flow (AC: 1–5)
  - [x] Add widget tests for loading, populated, empty, safe error/retry, Add Product navigation, and reactive stream updates.
  - [x] Prove row fallback behavior for present category versus unit, quantity/unit display, stable keys, and accessible labels.
  - [x] Prove a 3,000-item input does not place the final off-screen row in the widget tree initially, then verify scrolling can reveal later rows.
  - [x] Preserve the existing real-SQLite DAO/repository tests proving archived exclusion and name ordering; add only a focused integration seam if presentation composition is otherwise unproven.
  - [x] Update router tests to inject a lightweight Products builder where the test is about routing rather than provider state.
  - [x] Test at `360x640` with enlarged text and run applicable Android tap-target and labeled-target guidelines.

- [x] Task 5: Verify Story 2.3 without disturbing completed Stories 2.1–2.2 (AC: 1–5)
  - [x] Run Dart formatting, Flutter analysis, focused provider/widget/router tests, and the complete Flutter test suite.
  - [x] Keep the current `113` tests green and record the new final total honestly.
  - [x] Preserve every existing uncommitted Story 2.1 and Story 2.2 change; do not reset, clean, stage, or commit.
  - [x] Build/launch only if a concrete integration risk appears; no schema generation, migration, or dependency change is expected.

### Review Findings

- [x] [Review][Patch] Preserve category-or-unit metadata in merged row semantics [tindatrack/lib/features/products/presentation/widgets/product_list_item.dart:17]
- [x] [Review][Patch] Make quantity layout robust for long units and enlarged text [tindatrack/lib/features/products/presentation/widgets/product_list_item.dart:32]
- [x] [Review][Defer] Guard against duplicate Add Product routes from rapid repeated taps [tindatrack/lib/features/products/presentation/screens/product_list_screen.dart:64] — deferred, pre-existing

## Dev Notes

### Developer Context

Stories 2.1 and 2.2 already provide the entire data and creation path required by this story:

```text
ProductListScreen
  -> activeProductsProvider (new StreamProvider)
  -> productRepositoryProvider (existing)
  -> ProductRepository.watchActiveProducts (existing)
  -> DriftProductsRepository.watchActiveProducts (existing)
  -> ProductsDao.watchActiveProducts (existing)
  -> SQLite reactive query (existing)
```

The DAO already filters `is_archived = false` and orders by `name ASC` in SQLite. The repository already maps Drift rows to immutable domain `Product` values. Story 2.3 is a presentation/composition slice: do not move filtering, ordering, or mapping into widgets and do not introduce an in-memory sort/filter copy.

The worktree intentionally contains completed, uncommitted Stories 2.1 and 2.2. Treat them as prerequisite baseline context. Current committed HEAD remains `f758d77`; a broad git diff includes prerequisite work and must not be attributed wholesale to Story 2.3.

### State And Failure Contract

- Add one `StreamProvider<List<Product>>` beside the existing product feature providers.
- Watch `productRepositoryProvider`; do not construct `DriftProductsRepository` again inside the list provider.
- The UI consumes `AsyncValue<List<Product>>` and handles:
  - loading -> `AppLoadingView`
  - data empty -> `AppEmptyState`
  - data populated -> lazy list
  - error -> `AppErrorView` with stable safe copy and retry
- Never render `error.toString()`, stack traces, SQL, Drift, or database diagnostics.
- Drift's watched query is the refresh mechanism after Add Product succeeds. Do not manually append the newly created product to UI state or trigger an extra one-shot query.
- A provider retry should recreate the stream subscription through Riverpod. It must not invalidate `databaseProvider` or run database lifecycle recovery intended for app bootstrap.

### Product Row Contract

For this story a row contains only:

- product name;
- category after persistence normalization when non-null, otherwise unit;
- current integer quantity and unit;
- stable `ValueKey` derived from `product.id`;
- accessible semantics that identify the product and visible quantity.

Use a simple `ListTile`/row or equivalent Material 3 presentation with existing theme and spacing. Avoid nested cards, fixed pixel heights that break at text scaling, trailing overflow, and interactive affordances that do nothing. If the row is not actionable yet, do not add an `onTap`.

The original epic says "relevant status information." For Story 2.3, the visible current quantity is the relevant stock information. Low-stock/out-of-stock calculation, badge copy, colors, and Out-of-Stock priority belong exclusively to Story 2.5.

### Empty, Loading, And Error Copy

Recommended safe copy:

- Loading semantics: `Loading products`
- Empty title: `No products yet`
- Empty message: `Add your first product to start tracking stock.`
- Empty/FAB action: `Add Product`
- Error title: `Products unavailable`
- Error message: `We couldn't load your products. Please try again.`
- Retry action: `Retry`

Both the empty action and FAB may coexist because the story explicitly requires an actionable empty state and a persistent add affordance. Keep their navigation callback identical.

### Performance Guardrails

- Use a builder-backed list with `itemCount`; never create `products.map(...).toList()` as widget children.
- Do not use `SingleChildScrollView` around the populated list.
- Do not set `shrinkWrap: true` inside an unconstrained outer scroll view.
- Keep row construction presentation-only and side-effect free.
- A 3,000-product widget test should prove lazy construction structurally; it is not a benchmark and should not use wall-clock timing assertions.
- Preserve SQLite filtering and ordering. Do not load archived products and hide them in Dart.

### Routing And Regression Guardrails

- `AppRoute.values` remains exactly the four primary roots.
- `ProductRoute.addProduct` remains the existing `/products/add` secondary route.
- Story 2.2 now returns to Products with `goNamed(AppRoute.products.name)`, so the watched stream should show the saved row automatically.
- `createAppRouter` already supports `productsBuilder` injection. Router-only tests should inject a placeholder Products screen rather than accidentally requiring Riverpod/database composition.
- Do not change Add Product form, save behavior, pending-navigation guards, validation, repository persistence, schema, or generated Drift artifacts.

### Current Files To Update

- `tindatrack/lib/features/products/presentation/providers/product_providers.dart`
  - Current: composes DAO, repository, and Add Product use case.
  - Change: expose the active product stream as `AsyncValue` through one feature provider.
  - Preserve: existing composition and app-level database/ID/clock dependencies.
- `tindatrack/lib/features/products/presentation/screens/product_list_screen.dart`
  - Current: static placeholder plus Add Product FAB.
  - Change: render loading, empty, error, and lazy content states.
  - Preserve: Products screen key, Add Product route, simple Material 3 layout, and branch behavior.
- `tindatrack/test/app/router/app_router_test.dart`
  - Current: some route cases instantiate the default Products builder.
  - Change: inject a lightweight Products builder where provider behavior is irrelevant.
  - Preserve: four-root, branch-state, Add Product mapping, and back-navigation assertions.

### Expected New Files

Use the smallest structure that mirrors `lib/`:

```text
tindatrack/lib/features/products/presentation/widgets/product_list_item.dart
tindatrack/test/features/products/presentation/providers/product_providers_test.dart
tindatrack/test/features/products/presentation/screens/product_list_screen_test.dart
tindatrack/test/features/products/presentation/widgets/product_list_item_test.dart  # only if row behavior merits a separate file
```

Do not add dependencies, generated Riverpod code, a product-list controller, a second repository, or database artifacts.

### Previous Story Intelligence

- Story 2.2 is `done` after code review; Flutter analysis is clean and the complete suite passes `113/113`.
- Its code review locked all form fields during pending saves, blocked back navigation until save completion, returned visibly to Products after switching branches, validated small-screen error semantics, and proved duplicate names through real SQLite.
- Reuse `productRepositoryProvider` and `ProductRoute.addProduct`; do not rebuild either boundary.
- Add Product already normalizes text and the repository stream emits persisted domain values, so the list must not normalize again.
- Flutter commands cannot run reliably from the UNC workspace. The established safe verification flow copies only changed files into disposable `C:\tmp\inventory-story21`, runs Flutter there, and copies formatter output back while the WSL workspace remains authoritative.

### Git Intelligence

- Current committed HEAD: `f758d77` (`Complete Epic 1 foundation and retrospective`).
- Recent commits establish the Flutter foundation, BMAD sprint plan, and architecture; Stories 2.1–2.2 remain intentionally uncommitted.
- Preserve builder injection, provider overrides, controlled streams/completers, stable widget keys, strict linting, and mirrored test paths already used by the current codebase.

### Library And Latest Technical Information

Verified 2026-06-30 against the locked project:

- `flutter_riverpod 3.3.2`: use `StreamProvider` so stream values are exposed as `AsyncValue`, cache the latest emission, and are easy to override in tests.
- `drift 2.34.0`: `watch()` returns an auto-updating `Stream<List<T>>`; the existing DAO already owns the watched query.
- `go_router 17.3.0`: no route change is required.
- Flutter/Dart project constraint is Dart `^3.12.0`. Use `ListView.builder` or `ListView.separated` with `itemCount` for on-demand row construction.
- No dependency upgrade is required.

Primary references:

- [Flutter `ListView.builder`](https://api.flutter.dev/flutter/widgets/ListView/ListView.builder.html)
- [Riverpod `StreamProvider`](https://riverpod.dev/docs/providers/stream_provider)
- [Drift stream queries](https://drift.simonbinder.eu/dart_api/streams/)

### Scope Boundaries

Do not implement:

- Story 2.4 search, debounce, category/status filters, or no-results search state;
- Story 2.5 Low Stock/Out of Stock calculations, badges, colors, or warning priority;
- Story 2.6 edit navigation or product updates;
- Story 2.7 archive controls or archived-product management;
- Story 2.8 row action menus;
- Stock In/Out routes or actions;
- barcode display/input/scanner behavior;
- pagination, remote APIs, cloud sync, login, ads, or analytics;
- schema, migration, DAO query, generated-code, or dependency changes.

### Testing Requirements

- Provider tests:
  - repository stream subscription and multiple emissions;
  - AsyncError containment without UI diagnostic leakage;
  - override/disposal behavior without wall-clock sleeps.
- Widget tests:
  - loading, empty, populated, and safe error states;
  - empty action and FAB both navigate to Add Product;
  - category-versus-unit fallback and quantity/unit display;
  - reactive update after a new stream emission;
  - 3,000 inputs remain lazily built;
  - small screen, enlarged text, semantics, and no overflow.
- Persistence boundary:
  - preserve the DAO test proving SQL-level archived exclusion and name ordering;
  - avoid duplicating Story 2.1's exhaustive repository tests unless a real composition gap is found.
- Regression:
  - run focused Story 2.3 tests, router tests, Flutter analysis, and the full suite;
  - no schema change means no build_runner or migration update.

### Project Structure Notes

- Dependency direction remains `presentation -> domain -> data -> core database`.
- Feature providers are the composition boundary; widgets import domain values and presentation providers/widgets only.
- Shared `core` widgets remain product-agnostic.
- Tests mirror `lib/`.
- No project-context.md exists; this story, planning artifacts, previous story, and current code are authoritative.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.3: View Active Product List With Empty State]
- [Source: _bmad-output/planning-artifacts/epics.md#Additional Requirements]
- [Source: _bmad-output/planning-artifacts/architecture.md#State Management Patterns]
- [Source: _bmad-output/planning-artifacts/architecture.md#Query And List Patterns]
- [Source: _bmad-output/planning-artifacts/architecture.md#UX Flow Boundaries]
- [Source: _bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#AC-001: Add Product]
- [Source: _bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#Edge Cases]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Product List]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Product Row]
- [Source: _bmad-output/implementation-artifacts/2-2-add-product-with-validation.md]
- [Source: tindatrack/lib/features/products/presentation/providers/product_providers.dart]
- [Source: tindatrack/lib/features/products/presentation/screens/product_list_screen.dart]
- [Source: tindatrack/lib/features/products/domain/repositories/products_repository.dart]
- [Source: tindatrack/lib/features/products/data/repositories/drift_products_repository.dart]
- [Source: tindatrack/lib/core/database/daos/products_dao.dart]

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- Task 1 RED: provider tests failed to compile because `activeProductsProvider` did not exist.
- Task 1 GREEN: 3 focused provider tests and the 116-test full suite passed after adding the canonical repository stream provider.
- Task 2 RED: async-state widget tests failed against the static Products placeholder.
- Task 2 GREEN: 3 focused screen tests and the 119-test full suite passed for loading, empty, safe error/retry, and both Add Product actions.
- Task 3 RED: row and populated-list tests failed because the read-only row widget and lazy list did not exist.
- Task 3 GREEN: 6 focused row/screen tests and the 122-test full suite passed with builder-backed rows, stable keys, metadata fallback, and combined semantics.
- Task 4 RED: the first full-suite pass exposed router/shell harnesses that instantiated the new consumer screen without provider composition.
- Task 4 GREEN: 33 focused provider, SQLite, screen, row, router, shell, and app tests passed; the complete suite passed 126/126.
- Task 5 GREEN: Dart formatting was clean, Flutter analysis reported no issues, 33 focused tests passed, and the complete suite passed 126/126.
- Review patches RED: focused row tests reproduced missing category semantics and Flutter's `ListTile` trailing-width assertion at 360x640 with 2x text.
- Review patches GREEN: 34 focused tests, clean Flutter analysis, and the complete 127-test suite passed after the accessibility and responsive-layout fixes.

### Implementation Plan

- Follow task order with red-green-refactor; keep Riverpod composition, async screen states, row presentation, and proof gates independently testable.

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.
- Task 1 complete: exposed the existing repository stream through one feature-owned `StreamProvider` with update, error, and disposal coverage.
- Task 2 complete: replaced the placeholder with reusable loading, actionable empty, safe error/retry, and content states while preserving the Add Product route.
- Task 3 complete: added a read-only accessible product row and a `ListView.separated` catalog that builds stable-ID rows on demand.
- Task 4 complete: proved live repository/UI updates, safe async states, dual Add actions, 3,000-item lazy construction, small-screen accessibility, and isolated routing harnesses.
- Task 5 complete: verified formatting, static analysis, focused Story 2.3 coverage, and the full 126-test regression suite without staging, committing, schema generation, migration, dependency, or launch changes.
- Code review complete: merged semantics now retain visible category metadata, quantity content uses a width-safe stacked layout, and a long-unit/2x-text regression test protects both fixes.

### File List

- `_bmad-output/implementation-artifacts/2-3-view-active-product-list-with-empty-state.md`
- `_bmad-output/implementation-artifacts/deferred-work.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `tindatrack/lib/features/products/presentation/providers/product_providers.dart`
- `tindatrack/test/features/products/presentation/providers/product_providers_test.dart`
- `tindatrack/lib/features/products/presentation/screens/product_list_screen.dart`
- `tindatrack/test/features/products/presentation/screens/product_list_screen_test.dart`
- `tindatrack/lib/features/products/presentation/widgets/product_list_item.dart`
- `tindatrack/test/features/products/presentation/widgets/product_list_item_test.dart`
- `tindatrack/test/features/products/presentation/providers/product_providers_integration_test.dart`
- `tindatrack/test/app/navigation/app_shell_test.dart`
- `tindatrack/test/app/router/app_router_test.dart`
- `tindatrack/test/widget_test.dart`

## Change Log

- 2026-06-30: Created Story 2.3 with implementation-ready reactive list, lazy rendering, async-state, accessibility, and scope guardrails.
- 2026-06-30: Completed Task 1 active-product StreamProvider composition and lifecycle coverage.
- 2026-06-30: Completed Task 2 Products async states, retry, and Add Product navigation.
- 2026-06-30: Completed Task 3 lazy read-only product rows with accessible quantity semantics.
- 2026-06-30: Completed Task 4 reactive, lazy-list, accessibility, SQLite composition, and routing proof gates.
- 2026-06-30: Completed Task 5 verification and moved Story 2.3 to review with 33 focused and 126 full-suite tests passing.
- 2026-06-30: Resolved 2 code-review findings for row semantics and responsive quantity layout; 34 focused and 127 full-suite tests pass.
