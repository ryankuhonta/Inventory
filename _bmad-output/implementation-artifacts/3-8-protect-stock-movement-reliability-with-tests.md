---
baseline_commit: 6784394
---

# Story 3.8: Protect Stock Movement Reliability With Tests

Status: done

## Story

As a developer maintaining inventory logic,
I want stock movement tests around the transaction boundary,
So that the app never saves mismatched quantity and history.

## Acceptance Criteria

1. Given Stock In logic is tested, when a valid Stock In is executed, then tests verify quantity increases and a movement record is inserted, and previous and new quantities are correct.
2. Given Stock Out logic is tested, when a valid Stock Out is executed, then tests verify quantity decreases and a movement record is inserted, and previous and new quantities are correct.
3. Given insufficient Stock Out is tested, when requested quantity exceeds available stock, then tests verify product quantity remains unchanged, and no movement record is inserted.
4. Given transaction rollback is tested, when either product quantity update or movement insert fails, then tests verify no partial save remains, and product quantity and movement history stay consistent.
5. Given archived product behavior is tested, when Stock In or Stock Out is attempted for an archived product, then tests verify the operation is rejected, and no movement or quantity change is saved.
6. Given movement snapshot behavior is tested, when a product is renamed or archived after a movement, then tests verify history remains readable through `product_name_snapshot` and `unit_snapshot`.
7. Given infrastructure behavior is tested, when stock movements are created, then tests verify ULID generation and injectable UTC clock usage, and stock out reason defaults to `sold` when no reason is provided.

## Tasks / Subtasks

- [x] Task 1: Audit existing stock reliability coverage before adding tests (AC: 1-7)
  - [x] Review `tindatrack/test/features/stock/data/repositories/drift_stock_repository_test.dart` against every AC and identify exact missing assertions.
  - [x] Reuse existing repository test helpers, fake ID generator, fixed UTC clock, in-memory database setup, and DAO access patterns.
  - [x] Do not duplicate an existing passing test just to satisfy story wording; strengthen or rename existing tests when that makes the AC clearer.

- [x] Task 2: Harden Stock In transaction and metadata tests (AC: 1, 4, 5, 6, 7)
  - [x] Ensure valid Stock In asserts product quantity, one inserted movement, `previousQuantity`, `newQuantity`, `productNameSnapshot`, `unitSnapshot`, generated ID, injected UTC `createdAt`, note normalization, and `reason == null`.
  - [x] Ensure zero/negative quantity, missing product, and archived product failures leave product quantity and movement history unchanged and do not consume movement IDs.
  - [x] Ensure a forced movement insert failure rolls back the product quantity update.
  - [x] Ensure snapshots remain readable after later product rename and archive.

- [x] Task 3: Harden Stock Out transaction and metadata tests (AC: 2, 3, 4, 5, 6, 7)
  - [x] Ensure valid Stock Out asserts product quantity, one inserted movement, `previousQuantity`, `newQuantity`, `productNameSnapshot`, `unitSnapshot`, generated ID, injected UTC `createdAt`, note normalization, and default `StockOutReason.sold` when reason is omitted.
  - [x] Ensure excessive quantity returns `StockInsufficientQuantityFailure`, leaves product quantity unchanged, inserts no movement, and does not consume movement IDs.
  - [x] Ensure zero/negative quantity, missing product, and archived product failures leave product quantity and movement history unchanged and do not consume movement IDs.
  - [x] Ensure a forced movement insert failure rolls back the product quantity update.
  - [x] Preserve explicit Stock Out reason behavior for supported reasons; do not add a UI reason selector.

- [x] Task 4: Add lower-level schema or DAO guard tests only for uncovered reliability gaps (AC: 4, 6, 7)
  - [x] Inspect `tindatrack/test/core/database/stock_movements_schema_constraints_test.dart` and `tindatrack/test/core/database/app_database_migration_test.dart` before adding any new database tests.
  - [x] Add tests only if constraints, migrations, timestamp storage, movement type/reason storage, or snapshot persistence are not already covered.
  - [x] Do not introduce a Drift schema change unless tests reveal a real implementation defect. If a schema changes, update generated Drift files and migration tests in the same story.

- [x] Task 5: Protect presentation/controller behavior only where it proves reliability boundaries (AC: 3, 5)
  - [x] Verify existing controller and screen tests already cover invalid/excessive quantity, duplicate-submit guards, friendly typed failure copy, and no raw diagnostics.
  - [x] Add or strengthen presentation tests only if they prove no repository call is made for client-side invalid input or that repository failures surface safely.
  - [x] Keep transaction correctness assertions in repository/database tests, not widget tests.

- [x] Task 6: Verify Story 3.8 completion (AC: 1-7)
  - [x] Run focused stock repository/database/controller/screen tests touched by this story.
  - [x] Run Dart format for touched `test` and `lib` files.
  - [x] Run Dart analyzer.
  - [x] Run the full Flutter test suite.
  - [x] Run `git diff --check`.

### Review Findings

- [x] [Review][Patch] Remove UTF-8 BOM from BMAD artifacts [_bmad-output/implementation-artifacts/3-8-protect-stock-movement-reliability-with-tests.md:1, _bmad-output/implementation-artifacts/sprint-status.yaml:1]
- [x] [Review][Patch] Assert missing-product operations do not create the requested missing row [tindatrack/test/features/stock/data/repositories/drift_stock_repository_test.dart:120]
- [x] [Review][Patch] Add rollback coverage for product quantity update failure [tindatrack/test/features/stock/data/repositories/drift_stock_repository_test.dart:154]
## Dev Notes

### Source Requirements

- Story 3.8 covers FR-024, FR-025, FR-026, FR-027, FR-028, FR-029, FR-030, FR-032, FR-033, and NFR-005. [Source: `_bmad-output/planning-artifacts/epics.md#Story 3.8: Protect Stock Movement Reliability With Tests`]
- Epic 3 requires safe Stock In/Stock Out, insufficient-stock blocking, atomic quantity update plus movement insert, movement snapshots, and newest-first readable history. [Source: `_bmad-output/planning-artifacts/epics.md#Epic 3: Stock Movement And Inventory History`]
- Architecture invariants require product quantity to never be negative, stock movement insert and product quantity update to commit in one database transaction, archived products to remain readable in movement history, and stock movement to be the source of truth for post-creation quantity changes. [Source: `_bmad-output/planning-artifacts/architecture.md#Architecture Invariants`]
- Test gates require unit tests for stock in/out validation, repository tests for transaction rollback, widget tests for insufficient Stock Out, and migration tests for every Drift schema change. [Source: `_bmad-output/planning-artifacts/architecture.md#Test And Migration Gates`]
- Required implementation tests include Stock In/Out movement creation, failed stock mutation inserting no movement and changing no quantity, archived products blocking Stock In/Out unless restored, snapshot readability after rename/archive, injected UTC clock, ULID generation, and typed failure mapping. [Source: `_bmad-output/planning-artifacts/architecture.md#Required Implementation Test Checklist`]

### Current System State

- `DriftStockRepository` owns the repository transaction boundary for Stock In and Stock Out. It depends on `ProductsDao`, `StockMovementsDao`, `IdGenerator`, and `Clock`.
- `recordStockIn` and `recordStockOut` should validate input and product state before generating a movement ID. Invalid, missing, archived, and insufficient-stock attempts should not consume IDs.
- `recordStockIn` should create `StockMovementType.stockIn` movements with `reason == null`.
- `recordStockOut` should create `StockMovementType.stockOut` movements and default omitted reason to `StockOutReason.sold`.
- Existing repository tests already cover much of this story. Treat Story 3.8 as a reliability coverage audit plus targeted hardening, not a production rewrite.
- Existing controller/screen tests cover form validation, duplicate-submit guards, typed failure copy, and small-screen behavior for Stock In and Stock Out. Strengthen them only if a reliability boundary is missing.

### Architecture Compliance

- Keep Clean Architecture boundaries: widgets and controllers must not inspect Drift rows, DAOs, raw SQL exceptions, clocks, or ID generators.
- Keep all post-creation quantity changes routed through `features/stock` repository/use-case boundaries. Do not reintroduce direct product quantity edits from product presentation.
- Use the existing in-memory Drift test approach for transaction assertions.
- Use injected fake ID generator and fixed UTC clock in tests. Do not use `DateTime.now()` or random IDs in deterministic tests.
- Do not add dependencies, new stock screens, new routes, scanner/POS/accounting/supplier/cloud/export/reporting features, movement edit/delete behavior, or a Stock Out reason selector.

### Files Expected To Change

- `tindatrack/test/features/stock/data/repositories/drift_stock_repository_test.dart`
- Potentially `tindatrack/test/core/database/stock_movements_schema_constraints_test.dart`
- Potentially `tindatrack/test/core/database/app_database_migration_test.dart`
- Potentially `tindatrack/test/features/stock/presentation/controllers/stock_in_controller_test.dart`
- Potentially `tindatrack/test/features/stock/presentation/controllers/stock_out_controller_test.dart`
- Potentially `tindatrack/test/features/stock/presentation/screens/stock_in_screen_test.dart`
- Potentially `tindatrack/test/features/stock/presentation/screens/stock_out_screen_test.dart`
- Only if a real defect is exposed: matching production file under `tindatrack/lib/features/stock` or `tindatrack/lib/core/database`
- `_bmad-output/implementation-artifacts/3-8-protect-stock-movement-reliability-with-tests.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

### Testing Requirements

- Focus first on `drift_stock_repository_test.dart`; it is the correct layer for atomicity, rollback, snapshots, generated IDs, UTC timestamps, archived product rejection, and default reasons.
- Repository assertions should check both sides of every failure: the product row remains unchanged and `StockMovementsDao(database).listMovements()` remains empty.
- Rollback tests should force movement insert failure after quantity update would otherwise occur, then assert quantity is unchanged and history is empty.
- Snapshot tests should prove history uses `productNameSnapshot` and `unitSnapshot` after product rename and archive, not a live join to current product metadata.
- Presentation/controller tests may use fakes and should stay focused on form validation, repository-call prevention for invalid inputs, duplicate submission, and friendly failure copy.
- For Flutter verification from this UNC workspace, use the established Windows temp-copy pattern under `C:\tmp` if direct Flutter/Dart commands hang or fail.

### Previous Story Intelligence

- Story 3.1 created `stock_movements`, movement entities, validation, default Stock Out reason support, UTC timestamps, ULID generation, snapshot fields, and history ordering.
- Story 3.2 implemented atomic Stock In behavior and repository tests for success, invalid quantity, missing/archived products, and movement insert rollback.
- Story 3.3 implemented atomic Stock Out behavior, insufficient-stock protection, default `sold` reason, and rollback tests.
- Story 3.4 and Story 3.5 implemented Stock In/Out screens/controllers with duplicate-submit guards, provider invalidation, friendly feedback, and focused presentation tests.
- Story 3.6 implemented read-only History and reinforced snapshot readability after rename/archive.
- Story 3.7 added product-row navigation to Stock In/Out only; it deliberately did not move stock mutation logic into product-row widgets.

### Latest Technical Notes

- Current package versions are already pinned in `tindatrack/pubspec.yaml`; no dependency upgrade or web research is needed for this test-hardening story.
- Use existing Flutter test, Drift in-memory database, Riverpod test containers, and project fakes/helpers. Avoid new mocking libraries or test harnesses unless a current helper cannot express the required assertion.

### Project Structure Notes

- This story should be test-heavy. Production edits are acceptable only when a new or strengthened test exposes an actual reliability defect.
- If production code changes, keep changes in the smallest owning layer and update tests first or in the same patch.
- Database columns remain `snake_case`; Dart entities remain `camelCase`.

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- 2026-07-11: Created Story 3.8 context from Epic 3, architecture invariants/test gates, existing stock repository/controller/screen tests, Story 3.7 handoff, and previous Story 3.1-3.7 learnings.

### Completion Notes List

- Audited existing stock reliability coverage against all Story 3.8 acceptance criteria.
- Hardened repository tests so missing-product Stock In and Stock Out attempts also prove an existing product quantity remains unchanged while history stays empty and IDs are not consumed.
- Hardened snapshot coverage so movement history remains readable after product rename and archive.
- No production code or schema changes were needed; existing repository, database, controller, and screen guardrails passed focused and full regression verification.
- Resolved code review findings by removing BOMs, strengthening missing-product absence assertions, and adding product-update failure rollback coverage.

### File List

- _bmad-output/implementation-artifacts/3-8-protect-stock-movement-reliability-with-tests.md
- _bmad-output/implementation-artifacts/sprint-status.yaml
- tindatrack/test/features/stock/data/repositories/drift_stock_repository_test.dart

### Change Log

- 2026-07-11: Created Story 3.8 artifact and marked it ready for dev.
- 2026-07-11: Implemented Story 3.8 test hardening and marked it ready for review.
- 2026-07-11: Resolved code review findings and marked Story 3.8 done.
