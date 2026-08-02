---
baseline_commit: 4299867cc1451d23822a3cc2d01a44c81fd57fbd
---

# Story 2.7: Archive Product Without Deleting History

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a store owner,
I want to archive products I no longer sell,
so that my active list stays clean while history remains available.

## Acceptance Criteria

1. **Given** an active product exists
   **When** the user chooses Archive
   **Then** the app asks for confirmation
   **And** the copy explains that the product will be hidden from the active list but history remains available.

2. **Given** the user confirms archive
   **When** the archive action succeeds
   **Then** the product is marked archived locally
   **And** the product is not physically deleted from the database.

3. **Given** a product is archived
   **When** the user opens the default product list
   **Then** the archived product is hidden
   **And** historical references to that product remain available for history flows.

4. **Given** the MVP scope is reviewed
   **When** archive behavior is implemented
   **Then** Restore Archived Product UI is deferred
   **And** archived products cannot receive Stock In or Stock Out unless a future restore flow is explicitly added.

## Tasks / Subtasks

- [x] Task 1: Add an archive-only domain boundary (AC: #2, #4)
  - [x] Extend `ProductRepository` with `Future<Result<void>> archiveProduct(String id)`.
  - [x] Add an `ArchiveProduct` use case that delegates by stable product ID and exposes no delete, restore, quantity, or metadata mutation.
  - [x] Reuse `ProductNotFoundFailure`, `ArchivedProductFailure`, `PersistenceFailure`, and the existing `Result<T>` contract; do not add exceptions or UI strings to the domain layer.
  - [x] Keep `GetProduct` active-only for presentation/application consumers so archived products remain unavailable to Edit and future Stock In/Out flows unless a dedicated restore/read-history boundary is introduced.

- [x] Task 2: Persist a guarded soft archive without a schema change (AC: #2, #3, #4)
  - [x] Add a DAO operation that updates exactly one row matching both `id` and `isArchived == false`.
  - [x] Use a partial `ProductsCompanion` to set only `isArchived: true` and `updatedAt`; do not replace the full row.
  - [x] In `DriftProductsRepository.archiveProduct`, obtain the timestamp from the injected clock, convert it to UTC, call the DAO, and translate all persistence/clock failures to typed results.
  - [x] If no active row is updated, distinguish missing from already archived through the existing ID lookup and return `ProductNotFoundFailure` or `ArchivedProductFailure`.
  - [x] Do not call Drift `delete`, remove the row, mutate quantity/details/identity/creation time, generate an ID, insert a movement, or alter barcode uniqueness.
  - [x] Preserve the current active-only watch predicate. The Drift table update must naturally re-run the watched query and remove the archived row without manual cache/list mutation.

- [x] Task 3: Compose archive dependencies and single-flight screen state (AC: #1, #2)
  - [x] Add `archiveProductProvider` to the canonical product providers using the existing repository instance.
  - [x] Add product-ID-keyed, auto-disposed archive submission state, either as a focused controller or a clearly isolated extension of the existing Edit controller.
  - [x] Prevent duplicate archive submissions and prevent Save Changes and Archive from running concurrently.
  - [x] Keep the Edit screen mounted and recoverable when archive fails; map missing/already-archived targets to a safe unavailable message and persistence/unknown failures to friendly retry guidance.
  - [x] Check mounted/disposed state after awaits so navigation, snackbars, and state updates never occur after disposal.

- [x] Task 4: Add a secondary confirmed Archive action to Edit Product (AC: #1, #2, #3)
  - [x] Place Archive on the existing Edit Product screen; do not add it directly to product rows because Story 2.8 owns the final row-action pattern.
  - [x] Render Archive as a visually secondary destructive action using the theme error color, with an explicit label/icon and at least a 48dp tap target.
  - [x] Show a Material confirmation dialog titled `Archive product?` (or equivalent) with Cancel and Archive actions.
  - [x] Include the product name where it remains readable at large text, and use exact or equivalent reassurance: `This product will be hidden from your active list. Its inventory history will still be available.`
  - [x] Cancel, back, or barrier dismissal must make no persistence call and leave the form unchanged.
  - [x] After confirmation, disable form inputs, Save Changes, Archive, and back navigation; show button-level `Archiving...` progress without obscuring the dialog/action semantics.
  - [x] On success, show exact or equivalent feedback `Product archived.` and return to Products. The watched active list must remove the row while preserving the current search/filter controller state.
  - [x] Keep the screen scrollable and safe at 360x640 with 2x text; preserve accessible labels, focus order, dialog announcements, and existing Edit Product behavior.

- [x] Task 5: Prove non-deletion, isolation, reactive removal, and regressions (AC: #1, #2, #3, #4)
  - [x] Use-case tests: delegates the stable ID and passes through success, not-found, archived, and persistence results.
  - [x] DAO/repository tests: active row becomes archived; exactly `isArchived` and UTC `updatedAt` change; `id`, name, category, unit, selling price, quantity, threshold, barcode, and `createdAt` remain unchanged.
  - [x] Prove the row still exists through the DAO lookup that includes archived rows; never infer non-deletion only from a domain method that intentionally rejects archived products.
  - [x] Test missing target, already-archived target, DAO failure, and injected-clock failure; each returns the correct typed failure and makes no unintended changes.
  - [x] Reactive repository test: an existing `watchActiveProducts` subscription emits the product before archive and emits without it after archive, with no provider invalidation.
  - [x] Controller tests: success, cancellation/no-submit boundary, duplicate-submit protection, friendly typed/unknown failures, retry readiness, and disposal safety.
  - [x] Widget tests: secondary Archive action, confirmation and reassurance copy, Cancel/back/barrier behavior, destructive semantics, progress/disabled state, success feedback/navigation, and failure recovery.
  - [x] Integration-style product-list flow test: open the real active row, archive from Edit Product, return to the unchanged query state, and observe the row disappear through Drift.
  - [x] Preserve all existing Add/Edit/list/search/filter/status/accessibility tests and the 198-test baseline.
  - [x] Run formatter, analyzer, focused tests, the full Flutter suite, and WSL `git diff --check`.

### Review Findings

- [x] [Review][Patch] Translate non-Exception clock and DAO failures at the repository boundary.
- [x] [Review][Patch] Preserve existing validation feedback when archive fails.
- [x] [Review][Patch] Keep terminally unavailable products from accepting repeated mutations.
- [x] [Review][Patch] Keep archive confirmation actions reachable for long names at large text.
- [x] [Review][Patch] Prevent duplicate screen-reader announcements during archive progress.
- [x] [Review][Patch] Prove system-back cancellation, unchanged form values, and dialog accessibility.
- [x] [Review][Patch] Bound reactive-stream waits so regressions fail instead of hanging.
- [x] [Review][Patch] Exercise production archive-provider wiring.

## Dev Notes

### Non-Negotiable Archive Contract

| Concern | Required behavior |
| --- | --- |
| Persistence | Soft update; set `isArchived = true` |
| Timestamp | Set `updatedAt` from the injected clock as UTC |
| Row identity | Preserve `id`; generate no new ID |
| Product details | Preserve name, category, unit, selling price, threshold, and barcode |
| Stock | Preserve quantity; create no stock movement |
| Creation metadata | Preserve `createdAt` |
| Deletion | Never call delete or physically remove the product row |
| Active list | Existing `isArchived == false` query removes the row reactively |
| History | Preserve the row for future references; future movement snapshots remain immutable |
| Repeated archive | Return a typed archived/unavailable failure; do not report a false success |
| Restore | Out of scope; add no archived-products list or restore action |

The schema already has `Products.isArchived` with a default of `false`. This story requires no schema version bump, generated schema change, migration, or `archivedAt` addition. Current code and the established schema are authoritative over architecture examples that mention an optional `archived_at` field.

### Current Files To Extend

- `tindatrack/lib/core/database/daos/products_dao.dart`
  - Current: insert, lookup including archived rows, active-only metadata update, and watched active queries.
  - Change: add one active-ID-constrained partial archive update.
  - Preserve: active search/status predicates, ordering, LIKE escaping/NUL protection, and metadata update isolation.
- `tindatrack/lib/features/products/data/repositories/drift_products_repository.dart`
  - Current: create/get/update/watch, canonical row mapping, injected ID/clock, barcode normalization, and typed persistence mapping.
  - Change: add archive orchestration and failure mapping; reuse `_toDomain` only where a domain row is actually needed.
  - Preserve: `getProduct` rejects archived rows and watched queries remain the source of truth.
- `tindatrack/lib/features/products/domain/repositories/products_repository.dart`
  - Add the explicit archive contract; do not expose a generic delete or unrestricted update.
- `tindatrack/lib/features/products/presentation/providers/product_providers.dart`
  - Compose `ArchiveProduct` from the canonical repository.
- `tindatrack/lib/features/products/presentation/controllers/edit_product_controller.dart` or a new focused sibling controller
  - Coordinate single-flight archive state with the existing save lifecycle without weakening current validation/error behavior.
- `tindatrack/lib/features/products/presentation/screens/edit_product_screen.dart`
  - Add secondary action, confirmation, progress, success/failure feedback, and navigation.
  - Preserve all current fields, read-only quantity guidance, validation focus, save behavior, unavailable states, and small-screen accessibility.

Expected new files:

```text
tindatrack/lib/features/products/domain/usecases/archive_product.dart
tindatrack/test/features/products/domain/usecases/archive_product_test.dart
```

If archive state is isolated from edit-save state, also use mirrored paths such as:

```text
tindatrack/lib/features/products/presentation/controllers/archive_product_controller.dart
tindatrack/test/features/products/presentation/controllers/archive_product_controller_test.dart
```

Do not create a second repository implementation, DAO, database, product entity, active-list provider, route, or screen.

### End-To-End And Race Guardrails

- Dependency direction remains `presentation -> domain -> data -> core database`; widgets/controllers never import Drift, DAOs, or `AppDatabase`.
- Use one ID-constrained SQL update. Never load a full product into the UI and write it back: that could overwrite stock/details changed elsewhere.
- Set the controller busy state synchronously before the first await. One screen must not allow Save and Archive mutations to overlap.
- The repository owns the authoritative active-row guard. UI disabling is not a persistence guarantee.
- A DAO archive result of zero rows is not success. Resolve it to missing versus archived with the existing inclusive lookup.
- Drift write APIs reschedule watched queries on affected tables. Do not optimistically remove the product, mutate `activeProductsProvider`, invalidate `productListControllerProvider`, or reset search/filter state.
- A product can be archived at any quantity, including low or zero stock. Archive is catalog lifecycle, not a stock mutation.
- Barcode remains reserved because the row remains stored and the database uniqueness constraint spans active and archived products.
- Stock movement/history tables are not implemented yet. Do not introduce them early. Story 3 uses immutable `product_name_snapshot` and `unit_snapshot` so future history stays readable after rename/archive.
- Future Stock In/Out use cases must reject archived products at their repository/domain boundary. This story preserves that invariant through the existing active-only `getProduct` contract; it does not add fake stock actions or tests against nonexistent stock code.

### UX And Accessibility Guardrails

- Use `Archive`, never `Delete`.
- Archive is secondary/destructive; Save Changes remains the primary filled action.
- Confirmation copy must explain both consequences before persistence: hidden from the active list, history retained.
- Both confirmation actions need clear accessible names. Do not rely on red color alone.
- Keep dialog copy concise and allow wrapping/scaling; avoid fixed heights.
- Dismissal before confirmation is safe and reversible. Once persistence starts, prevent duplicate actions and back navigation until it finishes.
- Use simple English with Filipino-friendly phrasing and never surface raw Drift/SQLite/exception text.
- No ads, scanner UI, login/cloud prompts, Stock In/Out controls, or final row action menu belong in this flow.

### Previous Story Intelligence

- Story 2.6 established active-product ID lookup, active-only partial metadata updates, typed missing/archived failures, injected UTC timestamps, auto-disposed ID-keyed screen state, and the Edit Product route/screen.
- Reuse the edit entry point. Story 2.8 deliberately owns the final product-row action pattern.
- Preserve all seven Story 2.6 review fixes:
  - DAO writes enforce mutation boundaries.
  - rapid row taps cannot stack duplicate Edit routes.
  - clock failures stay inside the repository `Result` boundary.
  - lookup documentation accurately describes archived-product rejection.
  - read-only quantity has one screen-reader announcement.
  - list flow tests exercise the real row/reactive path.
  - edit loading/error/validation/back behavior remains covered.
- The committed Story 2.6 baseline is 198/198 passing tests with clean Dart analysis and `git diff --check`.

### Git And Workspace Constraints

- Branch: `codex/complete-stories-1-1-and-1-2`.
- Story creation baseline and pushed HEAD: `4299867` (`Complete product editing and review fixes`), matching `origin/codex/complete-stories-1-1-and-1-2`.
- WSL workspace `\\wsl.localhost\Ubuntu\home\rkuhonta\Inventory` is authoritative.
- Run Flutter/Dart commands from `C:\tmp\inventory-story21`, copying only Story 2.7-changed Flutter files when verification is needed, then audit the WSL diff.
- Preserve all ten intentional untracked Story 2.1/2.2 review/handoff files and Story 2.4/2.6 handoffs. Do not reset, clean, modify, stage, commit, or push them.

### Locked Library And API Notes

- Use repository-locked versions: Dart `^3.12.0`, Drift/drift_dev `^2.34.0`, drift_flutter `^0.3.0`, flutter_riverpod `^3.3.2`, go_router `^17.3.0`, and very_good_analysis `^10.2.0`.
- Do not add or upgrade packages.
- Drift partial updates use companions so absent fields stay untouched; every update must have an explicit `where` clause.
- Drift watched queries automatically re-run after writes through Drift APIs; no manual invalidation is required.
- Riverpod 3 families use constructor parameters on `Notifier` and should be auto-disposed for per-product state, matching Story 2.6.
- Flutter `showDialog<bool>` with `AlertDialog` provides the confirmation result. Keep Cancel/dismissal distinct from explicit confirmation, and make the dialog content responsive.

Official references:

- [Drift writes and partial update companions](https://drift.simonbinder.eu/dart_api/writes/)
- [Drift reactive stream invalidation](https://drift.simonbinder.eu/dart_api/streams/)
- [Riverpod families](https://riverpod.dev/docs/concepts2/family)
- [Riverpod automatic disposal](https://riverpod.dev/docs/concepts2/auto_dispose)
- [Flutter showDialog](https://api.flutter.dev/flutter/material/showDialog.html)
- [Flutter AlertDialog](https://api.flutter.dev/flutter/material/AlertDialog-class.html)

### Scope Boundaries

Do not implement hard delete, restore, an archived-products screen/filter, a product detail screen, Story 2.8 row actions, Stock In/Out, stock movement/history tables, dashboard changes, schema/migration changes, scanner functionality, cloud/login/API, ads, POS, suppliers, accounting, reports, localization, or dependency upgrades.

### Testing Baseline And Quality Gate

- Baseline at story creation: 198 passing Flutter tests, clean Dart analysis, clean `git diff --check`.
- Mirror every changed `lib/` path under `test/`; use the existing in-memory Drift database and injected clock helpers.
- Prefer exact state assertions over implementation-detail mocks for DAO/repository/reactive behavior.
- A passing UI test alone cannot prove history preservation. The persistence test must reload the archived row through an inclusive DAO lookup and compare preserved fields.
- Run focused tests during implementation, then the complete suite. Do not claim completion from focused tests alone.

### Project Structure Notes

- Archive remains in `features/products`; shared code moves to `core` only if another feature already consumes it.
- Current code uses `ProductRepository` and `DriftProductsRepository`; follow current names rather than outdated blueprint snippets.
- No `project-context.md` exists.
- No UX conflict remains: the UX artifact places Archive as a confirmed secondary action on Edit Product, while the architecture permits friendly labels. Use `Archive` for consistency with current epics and copy guidance.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.7: Archive Product Without Deleting History]
- [Source: _bmad-output/planning-artifacts/epics.md#Additional Requirements]
- [Source: _bmad-output/planning-artifacts/architecture.md#Non-Negotiable Consistency Rules]
- [Source: _bmad-output/planning-artifacts/architecture.md#Product CRUD And Archive]
- [Source: _bmad-output/planning-artifacts/architecture.md#UX Copy And Flow Notes]
- [Source: _bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#AC-003: Archive Product]
- [Source: _bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#Edge Cases]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Secondary Button]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Edit Product]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Interaction Primitives]
- [Source: _bmad-output/implementation-artifacts/2-6-edit-product-details-without-direct-stock-adjustment.md]
- [Source: tindatrack/lib/core/database/tables/products_table.dart]
- [Source: tindatrack/lib/core/database/daos/products_dao.dart]
- [Source: tindatrack/lib/features/products/data/repositories/drift_products_repository.dart]
- [Source: tindatrack/lib/features/products/domain/repositories/products_repository.dart]
- [Source: tindatrack/lib/features/products/presentation/controllers/edit_product_controller.dart]
- [Source: tindatrack/lib/features/products/presentation/providers/product_providers.dart]
- [Source: tindatrack/lib/features/products/presentation/screens/edit_product_screen.dart]
- [Source: tindatrack/lib/features/products/presentation/screens/product_list_screen.dart]

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Implementation Plan

- Add a typed archive use case and guarded active-row Drift update that preserves every non-archive field.
- Reuse the Edit Product controller so save and archive share one single-flight busy state and safe failure mapping.
- Add confirmed accessible archive UX plus repository, controller, widget, and real-Drift navigation coverage.

### Debug Log References

- Replaced unbounded settling in the real Drift widget flow with deterministic pumps and explicitly flushed Drift's zero-duration stream cleanup timer.
- Kept the WSL source authoritative while running Flutter tooling from `C:	mpinventory-story21`.

### Completion Notes List

- Added soft archive across domain, repository, DAO, provider, controller, and Edit Product UI without a schema change or physical deletion.
- Archive updates only `isArchived` and injected UTC `updatedAt`; retained-row tests prove identity, product details, stock, barcode, and creation time remain unchanged.
- Added confirmation/reassurance copy, destructive secondary styling, 48dp target, cancellation safety, mutual Save/Archive exclusion, progress state, and friendly feedback.
- Verified formatter, clean Dart analysis, focused archive tests, real Drift navigation/query preservation, and the complete 221-test suite.
- Addressed all eight code-review patches across repository error translation, terminal controller state, validation preservation, responsive dialog behavior, progress semantics, and regression coverage.
- Re-verified with 32 focused tests, clean Dart analysis, the complete 226-test suite, and clean WSL `git diff --check`.

- Ultimate context engine analysis completed - comprehensive developer guide created.

### File List

- `_bmad-output/implementation-artifacts/2-7-archive-product-without-deleting-history.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `tindatrack/lib/core/database/daos/products_dao.dart`
- `tindatrack/lib/features/products/data/repositories/drift_products_repository.dart`
- `tindatrack/lib/features/products/domain/repositories/products_repository.dart`
- `tindatrack/lib/features/products/domain/usecases/archive_product.dart`
- `tindatrack/lib/features/products/presentation/controllers/edit_product_controller.dart`
- `tindatrack/lib/features/products/presentation/controllers/product_form_controller.dart`
- `tindatrack/lib/features/products/presentation/providers/product_providers.dart`
- `tindatrack/lib/features/products/presentation/screens/edit_product_screen.dart`
- `tindatrack/test/features/products/data/repositories/drift_products_repository_archive_test.dart`
- `tindatrack/test/features/products/domain/product_domain_test.dart`
- `tindatrack/test/features/products/domain/usecases/add_product_test.dart`
- `tindatrack/test/features/products/domain/usecases/archive_product_test.dart`
- `tindatrack/test/features/products/domain/usecases/update_product_test.dart`
- `tindatrack/test/features/products/presentation/controllers/archive_product_controller_test.dart`
- `tindatrack/test/features/products/presentation/controllers/edit_product_controller_test.dart`
- `tindatrack/test/features/products/presentation/controllers/product_form_controller_test.dart`
- `tindatrack/test/features/products/presentation/providers/product_providers_test.dart`
- `tindatrack/test/features/products/presentation/providers/product_query_provider_test.dart`
- `tindatrack/test/features/products/presentation/screens/add_product_screen_test.dart`
- `tindatrack/test/features/products/presentation/screens/archive_product_screen_test.dart`
- `tindatrack/test/features/products/presentation/screens/edit_product_screen_test.dart`
- `tindatrack/test/features/products/presentation/screens/product_archive_navigation_flow_test.dart`
- `tindatrack/test/features/products/presentation/screens/product_edit_navigation_flow_test.dart`


### Change Log

- 2026-07-06: Implemented and verified soft product archive; moved Story 2.7 to review.
- 2026-07-06: Applied all eight code-review patches and moved Story 2.7 to done.
