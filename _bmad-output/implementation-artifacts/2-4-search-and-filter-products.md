---
baseline_commit: c2515545179a0b198ba64a57149baf739e351c49
---

# Story 2.4: Search And Filter Products

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a store helper,
I want to find products quickly by search or stock status,
so that I can act on the right item during busy selling hours.

## Acceptance Criteria

1. **Debounced local search**
   - **Given** the Products screen is open
   - **When** the user types into the search field
   - **Then** the visible input updates immediately
   - **And** the applied catalog query updates only after 300 milliseconds without another text change
   - **And** only the latest pending text is applied
   - **And** if a stock filter changes during a pending debounce, the filter applies immediately with the previously applied text, then the pending latest text applies to that current filter without reverting it
   - **And** clearing the field cancels any pending debounce and restores the selected stock-filter result immediately
   - **And** search remains fully offline.

2. **Defined name and optional-category matching**
   - **Given** a nonblank search term is applied
   - **When** the local query runs
   - **Then** leading and trailing whitespace is ignored
   - **And** active products match by ASCII case-insensitive substring against product name or a non-null category
   - **And** non-ASCII case behavior follows the locked SQLite `LIKE` implementation; Unicode case-folding infrastructure is not introduced
   - **And** `%`, `_`, and the chosen SQL escape character are treated as literal user text rather than wildcard syntax
   - **And** a null category never crashes or excludes a product whose name matches
   - **And** category remains optional in product creation.

3. **Mutually exclusive stock filters**
   - **Given** the Products screen is displayed
   - **When** the user selects `All`, `Low Stock`, or `Out of Stock`
   - **Then** the selection applies immediately without the text debounce
   - **And** the selected control is visually and semantically clear
   - **And** `All` includes every active product
   - **And** `Low Stock` includes products where `quantity > 0` and `quantity <= lowStockThreshold`
   - **And** `Out of Stock` includes products where `quantity == 0`
   - **And** zero-stock products do not also appear in `Low Stock`
   - **And** no persisted or manually maintained status flag is introduced.

4. **Reactive SQLite query boundary**
   - **Given** search text and a stock filter are applied
   - **When** the catalog is queried or its rows change
   - **Then** search and stock criteria combine with logical `AND`
   - **And** archived products remain excluded in every branch
   - **And** matching products remain ordered by name ascending in SQLite
   - **And** inserts or later valid quantity/archive updates re-evaluate the current criteria through the watched query
   - **And** widgets do not access Drift, `ProductsDao`, or the database directly
   - **And** stream failures remain safe `AsyncValue` errors with no raw Drift, SQLite, exception, or stack-trace text rendered.

5. **Search/filter controls and distinct empty states**
   - **Given** Products is displayed
   - **When** loading, content, empty, no-match, or error state is rendered
   - **Then** the labeled search control, `All`/`Low Stock`/`Out of Stock` controls, and existing Add Product FAB remain available
   - **And** default empty search plus `All` with no active products preserves the actionable `No products yet` state
   - **And** any non-default search or filter with zero matches shows `No matching products`
   - **And** the no-match state offers a clear way to reset search and filter
   - **And** no-match is not rendered as a technical error
   - **And** retry recreates only the current product query stream, not the app database.

6. **Low-end performance and accessibility floor**
   - **Given** up to 3,000 active products
   - **When** the user searches, changes filters, or scrolls results
   - **Then** rapid typing does not execute one database query per keystroke
   - **And** results remain builder-backed and rows are created on demand
   - **And** no eager widget list, network search, pagination layer, or second repository is introduced
   - **And** the screen remains usable at `360x640` with 2x system text
   - **And** search, clear/reset, and filter controls have accessible labels and applicable 48dp tap targets
   - **And** filter selection is not conveyed by color alone.

## Tasks / Subtasks

- [x] Task 1: Define the product-list query and stock-filter contract (AC: 1–4)
  - [x] Add an immutable domain query value under `features/products/domain/entities` with normalized search text and `ProductStockFilter.all`, `.lowStock`, and `.outOfStock`.
  - [x] Keep Low Stock and Out of Stock mutually exclusive: zero is Out of Stock; only positive quantity at or below threshold is Low Stock.
  - [x] Make equality/hash behavior stable so identical effective queries do not recreate streams unnecessarily.
  - [x] Add focused domain tests for trim/blank normalization, stable equality, and filter identity; keep quantity/threshold predicate proofs at the real SQLite query boundary.
  - [x] Do not add visible badges, badge copy, badge colors, or row actions; Story 2.5 owns status presentation.

- [x] Task 2: Parameterize the watched repository/DAO query (AC: 2–4, 6)
  - [x] Evolve `ProductRepository.watchActiveProducts` to accept the query while preserving one canonical repository and existing create behavior.
  - [x] Map the domain query to persistence-only DAO parameters/types; the core database layer must not import feature domain types.
  - [x] In `ProductsDao`, always apply `is_archived = false`, optional literal case-insensitive name/category matching, the selected stock predicate, and `name ASC`.
  - [x] Escape LIKE metacharacters explicitly with Drift's `like(..., escapeChar: ...)`; do not pass raw user text to `%term%` or claim `contains()` escapes wildcards.
  - [x] Keep category matching null-safe and search/filter composition grouped correctly as `(name OR category) AND stock AND active`.
  - [x] Preserve reactive `watch()` behavior and immutable domain mapping in `DriftProductsRepository`.
  - [x] Add real in-memory SQLite tests for active-only behavior, case-insensitive name/category matches, literal `%`/`_`/escape text, blank search, all stock boundaries, combined criteria, name order, and live re-emission.

- [x] Task 3: Add presentation-owned debounced query state (AC: 1, 3–5)
  - [x] Add a feature controller/notifier under `features/products/presentation/controllers`; use existing Riverpod 3 APIs without code generation or a new package.
  - [x] Debounce text changes by exactly 300 ms, replace the prior pending timer, apply only the latest term, and cancel safely on disposal.
  - [x] Apply stock-filter changes immediately with the currently applied search; a pending text callback must read the current filter when it fires and must never restore a captured stale filter.
  - [x] Keep query state alive for the app session so it survives indexed-stack tab switches and can accept a future dashboard-selected filter; cancel pending timers when the provider container is disposed, not merely when Products becomes offstage.
  - [x] Apply a blank/cleared query immediately and expose one reset operation that restores empty search plus `All`.
  - [x] Make `activeProductsProvider` watch the applied query and call the existing repository provider; do not construct another DAO/repository.
  - [x] Keep stream errors in `AsyncValue`; retry must invalidate only the query-aware product stream.
  - [x] Add deterministic controller/provider tests using controlled Flutter test time or explicit completers—never wall-clock sleeps.

- [x] Task 4: Add accessible search, filters, and no-match UX (AC: 1, 3, 5, 6)
  - [x] Convert `ProductListScreen` to a consumer stateful widget only if needed to own and dispose `TextEditingController`/`FocusNode`; initialize visible text from query state without cursor jumps.
  - [x] Add a single-line Material search `TextField` or equivalent with a persistent accessible label, search icon, and accessible clear action.
  - [x] Add exactly `All`, `Low Stock`, and `Out of Stock` filter controls using `FilterChip`, `ChoiceChip`, segmented controls, or an equivalent responsive Material pattern.
  - [x] Keep controls outside the result-state switch so loading, error, empty, and no-match transitions do not remove the user's query context.
  - [x] Preserve the existing Add Product FAB, `ProductRoute.addProduct`, true-empty Add action, loading/error safe copy, lazy list, stable row keys, and read-only row behavior.
  - [x] Render `No matching products` for non-default criteria with one reset action; do not show the first-product Add CTA as the no-match remedy.
  - [x] Lay out controls without horizontal overflow at `360x640` and 2x text; use wrapping or safe horizontal scrolling while retaining 48dp tap targets and selected semantics.

- [x] Task 5: Prove the complete search/filter flow (AC: 1–6)
  - [x] Prove no query is applied before 300 ms, the latest rapid input wins, clear/reset is immediate, disposal cancels pending work, and filter selection is immediate.
  - [x] Prove the debounce/filter race: type, select a filter before 300 ms, observe old-search/new-filter immediately, then latest-search/same-filter after 300 ms.
  - [x] Prove name and optional-category matching, mixed-case ASCII behavior, whitespace normalization, literal wildcard characters, null category, duplicate names, and offline operation.
  - [x] Prove `All`, threshold-1, threshold, threshold+1, zero, and threshold-zero cases; zero must appear only under Out of Stock.
  - [x] Prove search and stock filter intersect, archived rows never appear, results remain name ordered, and watched results react to database changes.
  - [x] Prove true catalog empty versus no matching products, safe error/retry, controls/FAB persistence, clear/reset action, and selected filter semantics.
  - [x] Preserve and extend the 3,000-product lazy-construction proof; do not add brittle wall-clock performance assertions.
  - [x] Run applicable Android tap-target and labeled-target guidelines at `360x640` with 2x text.
  - [x] Update repository fakes and provider overrides mechanically where the query-aware method signature requires it; do not weaken existing Story 2.1–2.3 assertions.

- [x] Task 6: Verify Story 2.4 without disturbing completed Stories 2.1–2.3 (AC: 1–6)
  - [x] Run Dart formatting, Flutter analysis, focused domain/DAO/repository/controller/provider/widget/router tests, and the complete Flutter suite.
  - [x] Keep the current `127` tests green and record the new final total honestly.
  - [x] Preserve every existing uncommitted Story 2.1–2.3 change; do not reset, clean, stage, or commit.
  - [x] Do not run schema generation or create a migration unless implementation proves a real schema change is necessary; the intended solution uses existing columns and index.
  - [x] Build/launch only if a concrete integration risk appears.

### Review Findings

- [x] [Review][Patch] Limit product search input to 1,000 characters [tindatrack/lib/features/products/presentation/screens/product_list_screen.dart:70]
- [x] [Review][Patch] Synchronize visible search text when the applied query changes after remount [tindatrack/lib/features/products/presentation/screens/product_list_screen.dart:31]
- [x] [Review][Patch] Normalize ASCII case for stable equality of semantically equivalent search queries [tindatrack/lib/features/products/domain/entities/product_list_query.dart:49]
- [x] [Review][Patch] Remove nondeterministic duplicate-name tie-order assertion [tindatrack/test/core/database/daos/products_dao_duplicate_name_search_test.dart:35]
- [x] [Review][Patch] Add watched-query proofs for quantity and archive transitions [tindatrack/test/core/database/daos/products_dao_search_filter_test.dart:141]

## Dev Notes

### Developer Context

Story 2.3 established the complete reactive list path:

```text
ProductListScreen
  -> activeProductsProvider
  -> productRepositoryProvider
  -> ProductRepository.watchActiveProducts
  -> DriftProductsRepository.watchActiveProducts
  -> ProductsDao.watchActiveProducts
  -> SQLite watched query
```

Story 2.4 extends that path with one query value and one presentation controller. Do not create an in-widget filtered copy, second repository, cache, one-shot refresh path, remote search, or eager result widget list.

Recommended target flow:

```text
Search TextField / stock filter controls
  -> ProductListController (raw events, 300 ms text debounce)
  -> applied ProductListQuery
  -> activeProductsProvider
  -> ProductRepository.watchActiveProducts(query)
  -> DriftProductsRepository maps query to persistence parameters
  -> ProductsDao watched SQLite query
  -> AsyncValue<List<Product>>
```

The controller owns workflow timing only. Query semantics belong to immutable domain values; SQL expressions belong to the DAO; row mapping remains in the repository; widgets render state.

### Settled Query Semantics

- Search is trimmed, ASCII case-insensitive through SQLite `LIKE`, and substring-based; non-ASCII case folding is unchanged SQLite behavior.
- The same term matches product `name` or non-null `category`; no separate category-management UI is added.
- Blank search means no text predicate.
- Search and stock filter combine with `AND`; name/category fields combine with `OR`.
- `All`: any active product.
- `Low Stock`: `quantity > 0 && quantity <= lowStockThreshold`.
- `Out of Stock`: `quantity == 0`.
- Out of Stock overrides Low Stock, so the filters are disjoint.
- Criteria never mutate products and no status column/flag is stored.
- Name ascending remains the database order.

For literal search, escape `\`, `%`, and `_` in that order, surround the escaped term with `%`, and call Drift `like(pattern, escapeChar: r'\')` (or an equivalently tested literal implementation). Drift 2.34's convenience `contains()` expands to `%substring%` but does not escape user wildcard characters.

### Empty, Loading, And Error State Contract

- Default query (`search == ''`, filter `All`) plus an empty result keeps Story 2.3's `No products yet` state and Add Product action.
- Any non-default query/filter plus an empty result shows:
  - title: `No matching products`
  - message: plain guidance such as `Try another search or reset the filters.`
  - action: `Reset`
- Controls remain visible in all result states so the user can understand and recover from current criteria.
- Stream error remains:
  - title: `Products unavailable`
  - message: `We couldn't load your products. Please try again.`
  - action: `Retry`
- Never interpolate an exception, SQL, Drift, stack trace, or query text into user-facing error copy.
- Retry invalidates the current `activeProductsProvider`; it must not invalidate `databaseProvider`.
- The existing read contract intentionally surfaces watched-stream failures to Riverpod for `AsyncError` containment. Do not redesign the repository into a new result-stream type in this story; the presentation must keep raw diagnostics out of rendered copy.

### Controller Lifecycle And Race Contract

- Product query state deliberately persists for the app session because the Products branch is retained by `StatefulShellRoute.indexedStack`.
- Switching tabs must not reset search/filter state or dispose/recreate the watched query.
- `TextEditingController` and `FocusNode` remain widget-owned and are disposed with the screen; debounce `Timer` remains controller-owned.
- Provider/container disposal cancels the timer. Tests should dispose the provider container to prove no late state write.
- A filter tap during pending text uses the old applied text plus the new filter immediately.
- When the timer fires, it applies only the newest normalized text to the controller's current filter. It must not use a whole query object captured before the filter tap.
- Clear and Reset cancel the pending timer before applying their immediate state.

### SQL, Index, And Schema Guardrails

The existing table already has every required field and `products_active_name_idx` on `(isArchived, name)`. Keep it. A case-insensitive infix search (`%term%`) cannot honestly claim full B-tree lookup, but the existing index still supports active-list narrowing/name order, the local ceiling is 3,000 products, and the 300 ms debounce prevents per-keystroke query churn.

The intended Story 2.4 solution therefore has:

- no table column change;
- no database version bump;
- no generated Drift artifact change;
- no migration/schema snapshot update;
- no FTS table or normalized shadow column;
- no category index added merely for `%term%` contains search;
- no dependency change.

If profiling proves this design cannot meet the 3,000-product target, HALT before expanding scope. A NOCASE/prefix/FTS/index redesign is a real persistence decision requiring migration tests and explicit approval.

DAO reactive-update tests may insert or update rows through the in-memory test database/DAO seam to trigger re-emission. Do not add production edit, quantity-adjustment, or archive APIs to satisfy Story 2.4 tests; those behaviors belong to later stories.

### Current Files To Update

- `tindatrack/lib/core/database/daos/products_dao.dart`
  - Current: parameterless active-only, name-ascending watched query.
  - Change: accept persistence query parameters and compose literal search/stock predicates.
  - Preserve: `isArchived = false`, `name ASC`, reactive `watch()`, and no domain imports.
- `tindatrack/lib/features/products/domain/repositories/products_repository.dart`
  - Current: `createProduct` plus parameterless `watchActiveProducts`.
  - Change: accept the immutable list query.
  - Preserve: product creation contract and domain-only API.
- `tindatrack/lib/features/products/data/repositories/drift_products_repository.dart`
  - Current: delegates to DAO and maps Drift rows to immutable `Product`.
  - Change: map domain query fields to persistence query parameters.
  - Preserve: mapping, typed create failures, injected ID/clock, barcode behavior.
- `tindatrack/lib/features/products/presentation/providers/product_providers.dart`
  - Current: canonical DAO/repository/Add providers and `activeProductsProvider`.
  - Change: compose query state into the existing stream provider.
  - Preserve: one canonical repository and safe `AsyncValue`.
- `tindatrack/lib/features/products/presentation/screens/product_list_screen.dart`
  - Current: consumer async states, FAB, true empty state, lazy content list.
  - Change: search/filter controls and no-match branch.
  - Preserve: keys where existing tests depend on them, routing, safe copy, lazy list, retry.

### Expected New Files

```text
tindatrack/lib/features/products/domain/entities/product_list_query.dart
tindatrack/lib/features/products/presentation/controllers/product_list_controller.dart
tindatrack/test/features/products/domain/entities/product_list_query_test.dart
tindatrack/test/features/products/presentation/controllers/product_list_controller_test.dart
```

Update mirrored tests for DAO, repository, providers, integration, and screen. Signature changes may also require mechanical updates to repository fakes in:

```text
tindatrack/test/features/products/domain/product_domain_test.dart
tindatrack/test/features/products/domain/usecases/add_product_test.dart
tindatrack/test/features/products/presentation/controllers/product_form_controller_test.dart
tindatrack/test/features/products/presentation/screens/add_product_screen_test.dart
```

Do not update `product_list_item.dart` unless a failing Story 2.4 test proves it necessary. Story 2.3 already fixed merged category semantics and long-unit/2x-text layout.

### Previous Story Intelligence

- Story 2.3 is `done`; the complete suite passes `127/127` and Flutter analysis is clean.
- Its review fixed category metadata in merged semantics and moved quantity out of unconstrained `ListTile.trailing`.
- Preserve the real SQLite stream boundary, safe async states, dual Add actions, 3,000-item lazy list, stable product-ID keys, and test router builder injection.
- Add Product returns visibly to Products; the watched query must update current search/filter results without a manual append or second read path.
- Persisted product text is already normalized. Query normalization must not mutate product rows.
- A rapid repeated Add-route guard is deferred as pre-existing work; do not absorb it into Story 2.4.
- Flutter commands remain unreliable from the UNC workspace. Copy only Story 2.4-changed files to the disposable `C:\tmp\inventory-story21` mirror, run Flutter there, and copy formatter output back while the WSL workspace remains authoritative.

### Git Intelligence

- Current committed HEAD remains `f758d77` (`Complete Epic 1 foundation and retrospective`).
- Stories 2.1–2.3 are complete but intentionally uncommitted, so a broad diff against HEAD contains prerequisite work and must not be attributed wholesale to Story 2.4.
- Preserve the dirty worktree. Do not reset, clean, stage, commit, or rewrite unrelated files.
- Recent commits establish the Flutter foundation, BMAD sprint plan, and architecture; current product code and tests are the more relevant implementation pattern for this story.

### Performance And Accessibility Guardrails

- Keep the list builder-backed with a non-null `itemCount`.
- Do not wrap the result list in `SingleChildScrollView`, use eager `products.map(...).toList()` children, or add `shrinkWrap: true` inside an outer scroll view.
- Debounce assertions must count applied queries/state transitions; do not use wall-clock latency thresholds.
- Search must expose a durable label such as `Search products`; placeholder-only labeling is insufficient.
- Clear/reset controls need a tooltip/semantic label.
- Selected filters need the Material selected/checkmark semantics and a visible non-color cue.
- Controls must wrap or scroll safely at 360 logical pixels and 2x text.
- Preserve read-only rows; status badges and their non-color labels arrive in Story 2.5.

### Library And Latest Technical Information

Locked project versions are authoritative:

- Dart `^3.12.0`
- Drift / drift_dev `2.34.0`
- drift_flutter `0.3.0`
- flutter_riverpod / riverpod `3.3.2`
- go_router `17.3.0`
- very_good_analysis `10.2.0`

No package upgrade is required. Use:

- Flutter `TextField` with an owned/disposed `TextEditingController` when programmatic initialization/reset is required.
- Material `FilterChip`/`ChoiceChip` or an equivalent control whose `selected` state is visible and semantic.
- Riverpod notifier/provider lifecycle plus `ref.onDispose` for debounce cleanup.
- Drift watched queries so database changes re-run current criteria automatically.
- Drift expression comparisons for quantity predicates and escaped `like` for literal search.

Primary references:

- [Flutter `TextField`](https://api.flutter.dev/flutter/material/TextField-class.html)
- [Flutter `FilterChip`](https://api.flutter.dev/flutter/material/FilterChip-class.html)
- [Riverpod debounce/cancel guidance](https://riverpod.dev/docs/how_to/cancel)
- [Drift stream queries](https://drift.simonbinder.eu/dart_api/streams/)
- [Drift expressions](https://drift.simonbinder.eu/dart_api/expressions/)

### Scope Boundaries

Do not implement:

- Story 2.5 status badges, colors, row warning priority, or status copy;
- Story 2.6 edit navigation/product update;
- Story 2.7 archive controls or archived-product management;
- Story 2.8 row action menus;
- Stock In/Out routes or actions;
- Dashboard-to-low-stock deep-link wiring (Epic 4), though filter state should be settable later;
- category CRUD, category chips/dropdowns, or mandatory category;
- barcode search/scanner UI, permissions, route, or dependency;
- pagination, FTS, remote API/search, cloud sync, login, ads, analytics, POS, supplier, accounting, or reporting behavior;
- schema, migration, generated-code, or dependency changes without an explicit halt and scope decision.

### Testing Requirements

- Domain query:
  - default identity and stable equality;
  - trim/blank normalization;
  - disjoint stock boundaries.
- DAO/repository:
  - active-only and name order for every query;
  - mixed-case ASCII name and category contains match, with no unpromised Unicode case-folding assertion;
  - null category;
  - literal `%`, `_`, and `\`;
  - combined search/filter;
  - zero/threshold boundaries;
  - live watched update;
  - reactive update triggered through test-only database/DAO seams without adding later-story production APIs;
  - unchanged domain mapping.
- Controller/provider:
  - no applied query before 300 ms;
  - latest rapid text wins;
  - clear and filter change are immediate;
  - filter changes during a pending debounce cannot be reverted by a stale timer callback;
  - query state survives indexed-stack tab changes and timer cleanup occurs on provider-container disposal;
  - reset returns default;
  - disposal cancels pending timer;
  - query is forwarded once per effective change;
  - stream error remains `AsyncError`;
  - retry recreates current stream.
- Widget:
  - controls visible across loading/content/empty/no-match/error;
  - true empty versus `No matching products`;
  - reset recovery;
  - selected filter visible and semantic;
  - FAB and Add navigation preserved;
  - reactive current-query update;
  - safe error copy;
  - 3,000-result lazy construction;
  - 360x640, 2x text, applicable Android tap/labeled-target checks.
- Regression:
  - preserve DAO archived/name-order tests;
  - update fakes without weakening Add Product tests;
  - run formatter, analyzer, focused tests, and full suite.

### Project Structure Notes

- Dependency direction remains `presentation -> domain -> data -> core database`.
- Feature query/controller types live under `features/products`; persistence-only query types may live beside `ProductsDao`.
- Widgets import domain/presentation types only, never Drift or DAO types.
- Tests mirror `lib/`.
- No `project-context.md` exists; this story, planning artifacts, completed Story 2.3, current code, and locked dependencies are authoritative.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.4: Search And Filter Products]
- [Source: _bmad-output/planning-artifacts/epics.md#Additional Requirements]
- [Source: _bmad-output/planning-artifacts/epics.md#UX Design Requirements]
- [Source: _bmad-output/planning-artifacts/architecture.md#Communication Patterns]
- [Source: _bmad-output/planning-artifacts/architecture.md#Query And List Patterns]
- [Source: _bmad-output/planning-artifacts/architecture.md#Frontend Architecture]
- [Source: _bmad-output/planning-artifacts/architecture.md#UX Flow Boundaries]
- [Source: _bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#Product List And Search]
- [Source: _bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#Edge Cases]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Product List]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Search]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Filters]
- [Source: _bmad-output/implementation-artifacts/2-3-view-active-product-list-with-empty-state.md]
- [Source: tindatrack/lib/core/database/daos/products_dao.dart]
- [Source: tindatrack/lib/features/products/domain/repositories/products_repository.dart]
- [Source: tindatrack/lib/features/products/data/repositories/drift_products_repository.dart]
- [Source: tindatrack/lib/features/products/presentation/providers/product_providers.dart]
- [Source: tindatrack/lib/features/products/presentation/screens/product_list_screen.dart]

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

### Implementation Plan

- Task 1: Introduce a normalized immutable domain query and enum, prove effective equality and filter identity with focused tests, then run the complete regression suite.
- Task 2: Parameterize the SQLite watched query behind persistence-only parameters, map the domain query in the canonical repository, prove literal matching and stock composition in memory, and mechanically update repository fakes.
- Task 3: Add app-session Riverpod query state with an exact 300 ms text debounce, immediate filter/clear/reset operations, race-safe current-filter reads, query-aware stream composition, and deterministic lifecycle/error/retry tests.
- Task 4: Make the Products screen own its visible text/focus lifecycle, keep accessible search and exactly three selected chips outside result states, and distinguish recoverable no-match from true empty without disturbing the lazy list or Add flow.
- Task 5: Run the cross-layer Story 2.4 proof matrix, add explicit duplicate-name and clear/filter/session-restoration coverage, and preserve all prior routing, Add Product, lazy-list, safe-error, and accessibility assertions.
- Task 6: Recheck formatting for every touched Dart file, run clean static analysis and the complete Flutter suite in the mirror, then audit the authoritative WSL diff for scope, whitespace, schema, generated-file, dependency, and git-operation safety.

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.
- Task 1 complete: added normalized `ProductListQuery`, stable value equality/hash behavior, default-query identity, and the three mutually exclusive stock-filter identities. Focused tests passed 4/4; full Flutter regression suite passed 131/131.
- Task 2 complete: added escaped literal SQLite search over name/nullable category, mutually exclusive stock predicates, active-only AND composition, name ordering, watched re-emission, domain-to-persistence mapping, and query-aware repository signatures. Focused tests passed 7/7; full suite passed 138/138; analysis clean.
- Task 3 complete: added the app-session `ProductListController`, exact latest-only debounce, race-safe immediate filters, immediate clear/reset, disposal cancellation, query-aware repository stream recreation, safe stream errors, and current-query retry. Focused tests passed 6/6; full suite passed 144/144; analysis clean.
- Task 4 complete: added the labeled search field and accessible clear action, exactly three responsive selected `ChoiceChip` filters, persistent controls across async states, distinct no-match/reset UX, and widget-owned controller/focus disposal while preserving FAB, routing, safe copy, stable keys, read-only rows, and lazy construction. Focused screen tests passed 12/12; full suite passed 149/149; analysis clean.
- Task 5 complete: the 37-test focused Story 2.4 matrix proves normalization, literal SQLite matching, nullable category, duplicate names, disjoint stock boundaries, query intersection/order/reactivity, debounce races, clear/reset/disposal/session behavior, safe retry, distinct empty states, selected controls, lazy 3,000-row construction, routing preservation, and 360×640/2× accessibility. Full suite passed 151/151; analysis clean.
- Task 6 complete: formatting check reported 0/20 changes, Flutter analysis reported no issues, and the complete suite passed 151/151. `git diff --check` is clean; no schema/generated/dependency/build changes were needed; the eight intentional handoff/review files remain untouched and untracked; no reset, clean, stage, commit, or push was performed.
- Code review complete: resolved all five findings with a 1,000-character search cap, remount-safe visible-query synchronization, ASCII-only effective query normalization, order-independent duplicate-name assertions, and quantity/archive watched-update proofs. Final suite passed 154/154; analysis and diff checks clean.

### File List

- `_bmad-output/implementation-artifacts/2-4-search-and-filter-products.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `tindatrack/lib/core/database/daos/products_dao.dart`
- `tindatrack/lib/features/products/data/repositories/drift_products_repository.dart`
- `tindatrack/lib/features/products/domain/entities/product_list_query.dart`
- `tindatrack/lib/features/products/domain/repositories/products_repository.dart`
- `tindatrack/lib/features/products/presentation/controllers/product_list_controller.dart`
- `tindatrack/lib/features/products/presentation/providers/product_providers.dart`
- `tindatrack/lib/features/products/presentation/screens/product_list_screen.dart`
- `tindatrack/test/core/database/daos/products_dao_duplicate_name_search_test.dart`
- `tindatrack/test/core/database/daos/products_dao_search_filter_test.dart`
- `tindatrack/test/features/products/data/repositories/drift_products_repository_query_test.dart`
- `tindatrack/test/features/products/domain/entities/product_list_query_test.dart`
- `tindatrack/test/features/products/domain/product_domain_test.dart`
- `tindatrack/test/features/products/domain/usecases/add_product_test.dart`
- `tindatrack/test/features/products/presentation/controllers/product_form_controller_test.dart`
- `tindatrack/test/features/products/presentation/controllers/product_list_controller_test.dart`
- `tindatrack/test/features/products/presentation/providers/product_providers_test.dart`
- `tindatrack/test/features/products/presentation/providers/product_query_provider_test.dart`
- `tindatrack/test/features/products/presentation/screens/add_product_screen_test.dart`
- `tindatrack/test/features/products/presentation/screens/product_list_search_filter_screen_test.dart`
- `tindatrack/test/features/products/presentation/screens/product_search_filter_flow_test.dart`

## Change Log

- 2026-06-30: Created Story 2.4 with implementation-ready search semantics, mutually exclusive stock filters, debounced Riverpod state, SQL query boundaries, accessible no-match UX, and regression guardrails.
- 2026-07-01: Completed Task 1 domain query contract and focused normalization/equality/filter tests; full suite 131/131 green.
- 2026-07-01: Completed Task 2 query-aware repository/DAO boundary with literal escaped search, stock filters, reactive SQLite proofs, 138/138 tests green, and clean analysis.
- 2026-07-01: Completed Task 3 debounced app-session query controller and query-aware provider flow; 144/144 tests green and analysis clean.
- 2026-07-01: Completed Task 4 accessible search/filter/no-match UI while preserving list and Add behavior; 149/149 tests green and analysis clean.
- 2026-07-01: Completed Task 5 cross-layer Story 2.4 proof matrix; 37/37 focused tests and 151/151 full tests green, analysis clean.
- 2026-07-01: Completed Task 6 final verification with stable formatting, clean analysis/diff, and 151/151 tests; no schema or git mutation beyond working-tree edits.
- 2026-07-01: Resolved all five parallel code-review findings; final suite 154/154 green, analysis and diff checks clean, story moved to done.
