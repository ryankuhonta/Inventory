---
baseline_commit: 5175352a3c81a183ca71fa52d8a483f97434103d
---

# Story 3.3: Record Stock Out Atomically With Insufficient Stock Protection

Status: done

## Story

As a store helper,
I want to record removed or sold stock safely,
So that inventory decreases only when enough stock is available.

## Acceptance Criteria

1. Given an active product has enough available stock, when the user records Stock Out with a positive quantity, then the product quantity decreases by that quantity, and a `stock_out` movement is inserted with previous quantity, new quantity, product snapshots, optional note, reason, and UTC timestamp.
2. Given the user records Stock Out with zero or negative quantity, when the action is submitted, then the action is rejected, and no product quantity or movement history change is saved.
3. Given a product has less stock than the requested Stock Out quantity, when the user submits the action, then the action is rejected with an insufficient stock failure, and the product quantity remains unchanged.
4. Given the target product does not exist or is archived, when Stock Out is attempted, then the action is rejected with a typed failure, and no movement record is inserted.
5. Given a Stock Out operation is processed, when either the product quantity update or movement insert fails, then the entire transaction rolls back, and no partial inventory state is saved.

## Tasks / Subtasks

- [x] Task 1: Add Stock Out domain input and typed failure (AC: 1, 2, 3, 4)
  - [x] Create `RecordStockOutInput` with `productId`, positive `quantity`, optional `reason`, and optional `note`.
  - [x] Default omitted reason to `StockOutReason.defaultReason` at the repository boundary, matching existing `recordMovementRow` behavior.
  - [x] Add `StockInsufficientQuantityFailure` carrying enough structured data for UI copy, at minimum available and requested quantities.
  - [x] Reuse existing `StockMovementValidationFailure` for zero or negative quantity.

- [x] Task 2: Extend stock repository contract and implementation (AC: 1, 2, 3, 4, 5)
  - [x] Add `recordStockOut(RecordStockOutInput input)` to `StockRepository`.
  - [x] Implement `DriftStockRepository.recordStockOut` using the same transaction-scoped pattern as Story 3.2 `recordStockIn`.
  - [x] Validate positive quantity before product lookup, ID generation, or timestamp generation.
  - [x] Read the product row inside the transaction, including archived rows.
  - [x] Reject missing products with `StockProductNotFoundFailure` and archived products with `StockArchivedProductFailure`.
  - [x] Reject requested quantity greater than available quantity with `StockInsufficientQuantityFailure` before generating ID/time or mutating persistence.
  - [x] Compute `previousQuantity` from the product row and `newQuantity = previousQuantity - input.quantity`.
  - [x] Update the active product quantity and insert one `stock_out` movement in the same Drift transaction.
  - [x] Store product name/unit snapshots from the product row, normalized note, reason persisted value, injected ULID, and injected UTC timestamp.
  - [x] Map transaction/persistence failures to `PersistenceFailure` and leave no partial product/history state.

- [x] Task 3: Add focused repository tests (AC: 1, 2, 3, 4, 5)
  - [x] Test successful Stock Out decreases product quantity and writes exactly one `stock_out` movement.
  - [x] Test default and explicit Stock Out reasons persist and map back to domain values.
  - [x] Test injected ULID/UTC timestamp and product name/unit snapshots.
  - [x] Test zero and negative quantity return validation failure, do not mutate product/history, and do not generate ID/time.
  - [x] Test insufficient stock returns typed insufficient-stock failure, preserves product quantity, inserts no movement, and does not generate ID/time.
  - [x] Test missing product and archived product return typed failures and insert no movement.
  - [x] Test movement insert failure after product update rolls back product quantity.

- [x] Task 4: Verify Story 3.3 completion (AC: 1, 2, 3, 4, 5)
  - [x] Run focused stock repository tests.
  - [x] Run Dart format for `lib` and `test`.
  - [x] Run Dart analyzer.
  - [x] Run the full Flutter test suite.
  - [x] Run WSL `git diff --check`.

## Dev Notes

### Source Requirements

- Story 3.3 covers FR-027, FR-028, FR-029, FR-030, FR-031, FR-032, FR-033, NFR-005, UX-DR20, and UX-DR21. [Source: `_bmad-output/planning-artifacts/epics.md#Story 3.3: Record Stock Out Atomically With Insufficient Stock Protection`]
- Stock Out with enough stock must decrease product quantity and insert a `stock_out` movement with previous/new quantities, product snapshots, optional note, reason, and UTC timestamp. [Source: `_bmad-output/planning-artifacts/epics.md#Story 3.3: Record Stock Out Atomically With Insufficient Stock Protection`]
- Stock Out quantity must be positive; zero or negative requests are rejected without product or history mutation. [Source: `_bmad-output/planning-artifacts/epics.md#Story 3.3: Record Stock Out Atomically With Insufficient Stock Protection`]
- Requested Stock Out quantity greater than available stock must be rejected with an insufficient-stock failure and leave quantity unchanged. [Source: `_bmad-output/planning-artifacts/epics.md#Story 3.3: Record Stock Out Atomically With Insufficient Stock Protection`]
- Missing or archived targets must be rejected with typed failures and no movement insert. [Source: `_bmad-output/planning-artifacts/epics.md#Story 3.3: Record Stock Out Atomically With Insufficient Stock Protection`]
- Product quantity update and movement insert must succeed or fail together in one transaction. [Source: `_bmad-output/planning-artifacts/epics.md#Story 3.3: Record Stock Out Atomically With Insufficient Stock Protection`; `_bmad-output/planning-artifacts/architecture.md#Architecture Invariants`]

### Architecture Compliance

- Use Flutter/Riverpod/Drift/Clean Architecture. This story is repository/domain logic only; do not add UI, routes, scanner, POS, supplier, accounting, dashboard, cloud sync, or Stock Out screen work.
- All post-creation product quantity changes must route through `features/stock`; product edit flows must still not mutate stock quantity. [Source: `_bmad-output/planning-artifacts/architecture.md#Product Handoff Notes`]
- Keep Drift DAOs persistence-only. Transaction orchestration belongs in `DriftStockRepository`, not inside DAO methods.
- Use existing `ProductsDao.updateActiveProductQuantity` for active product quantity updates. It already filters `isArchived == false` and returns the persisted row or `null`.
- Use `StockMovementType.stockOut.persistedValue` and `StockOutReason` persisted values already defined in `stock_movement.dart`; do not add a new reason enum.
- Preserve `recordMovementRow` as an audit-row-only method for Story 3.1 behavior and existing tests.
- Domain inputs/entities must not import Drift generated classes.
- Reuse `IdGenerator`, `Clock`, `Result<T>`, `AppFailure`, and `PersistenceFailure`.
- Use `clock.now().toUtc()` and ULID generation only after validation, product existence/archive checks, and sufficient-stock checks pass.
- Product quantity must never become negative; zero stock is valid and should block further Stock Out. [Source: `_bmad-output/planning-artifacts/architecture.md#Boundary sweep decisions`]

### Current System State

- Story 3.1 added the `stock_movements` table, `StockMovementsDao`, `CreateStockMovementInput`, `StockMovement`, stock type/reason enums, and movement history list/watch behavior.
- Story 3.2 added `RecordStockInInput`, `StockProductNotFoundFailure`, `StockArchivedProductFailure`, `ProductsDao.updateActiveProductQuantity`, and `StockRepository.recordStockIn`.
- `DriftStockRepository.recordStockIn` now validates positive quantity before storage access, then performs product read, quantity computation, active product update, and movement insert inside one Drift transaction.
- `StockOutReason.defaultReason` is `sold`; `recordMovementRow` already defaults omitted Stock Out reason to `sold`.
- `stockRepositoryProvider` already composes `ProductsDao`, `StockMovementsDao`, `IdGenerator`, and `Clock`; no provider shape change should be needed unless the constructor changes.
- WSL workspace is authoritative. Flutter/Dart verification should use a local Windows copy because direct Flutter runs on the UNC path have hung or failed in prior sessions.

### Files Expected To Change

- `tindatrack/lib/features/stock/domain/entities/record_stock_out_input.dart` (new)
- `tindatrack/lib/features/stock/domain/failures/stock_failure.dart`
- `tindatrack/lib/features/stock/domain/repositories/stock_repository.dart`
- `tindatrack/lib/features/stock/data/repositories/drift_stock_repository.dart`
- `tindatrack/test/features/stock/data/repositories/drift_stock_repository_test.dart`
- `_bmad-output/implementation-artifacts/3-3-record-stock-out-atomically-with-insufficient-stock-protection.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

### Testing Requirements

- Add focused tests primarily in `tindatrack/test/features/stock/data/repositories/drift_stock_repository_test.dart`, following the Story 3.1/3.2 style: `NativeDatabase.memory()`, fake ID generators, fixed clocks, and real DAOs.
- Required proofs:
  - Success decreases product quantity and inserts exactly one `stock_out` movement.
  - Movement has injected ID and UTC timestamp.
  - Movement snapshots product name and unit from the product row.
  - Reason defaults to `StockOutReason.defaultReason` when omitted and preserves explicit reasons when provided.
  - Zero or negative quantity returns typed validation failure and does not update product or movement history.
  - Insufficient stock returns typed insufficient-stock failure and does not update product or movement history.
  - Missing product returns typed missing-product failure and does not write movement history.
  - Archived product returns typed archived-product failure and does not mutate.
  - If movement insert fails after product update, the transaction rolls back product quantity.
- Full verification should include focused stock repository tests, format, analyzer, full Flutter suite, and WSL `git diff --check`.

### Previous Story Intelligence

- Story 3.2 code review found that reading/computing quantity outside the transaction risked stale movement rows and lost updates. Story 3.3 must use the transaction-scoped pattern from the corrected `recordStockIn` from the start.
- Story 3.2 intentionally validates positive quantity before product lookup, ID generation, or clock use; use the same ordering for Stock Out.
- Story 3.2 returns missing/archived typed failures before generating IDs/time; insufficient stock should follow that same no-side-effects rule.
- Story 3.2 rollback test uses a `_FailingInsertStockMovementsDao`; reuse that style for Stock Out rollback.
- Prior review dismissed wrapping `watchMovementHistory` errors as out-of-scope and architecture-consistent; do not reopen that in Story 3.3.

### Tooling Notes

- Direct Windows Flutter/Dart commands can hang or fail on the WSL UNC path. Use a local verification copy under `C:\tmp` for Flutter/Dart commands, then copy formatted touched files back to WSL.
- Do not commit or push unless explicitly requested.
- Current workspace already contains uncommitted Story 3.2 changes; preserve them and build Story 3.3 on top without reverting.

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- 2026-07-08: Created Story 3.3 context from Epic 3, architecture, and Story 3.2 implementation/review learnings.
- 2026-07-08: Began Story 3.3 implementation from ready-for-dev.
- 2026-07-08: Red phase confirmed focused Stock Out tests failed before repository implementation.
- 2026-07-08: Focused stock repository tests passed on local verification copy: 22/22.
- 2026-07-08: Dart formatter completed on local verification copy.
- 2026-07-08: Dart analyzer passed on local verification copy with no issues.
- 2026-07-08: Full Flutter test suite passed on local verification copy: 264/264.
- 2026-07-08: WSL git diff --check passed.

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.
- Added `RecordStockOutInput` with product ID, quantity, optional reason, and optional note.
- Added typed `StockInsufficientQuantityFailure` with available/requested quantity details for UI mapping.
- Extended `StockRepository` and `DriftStockRepository` with transaction-scoped `recordStockOut`.
- Stock Out validates positive quantity, missing/archived product, and sufficient stock before ID/time generation or persistence mutation.
- Successful Stock Out updates product quantity and writes a `stock_out` movement with previous/new quantities, snapshots, normalized note, reason, injected ULID, and UTC timestamp.
- Added focused repository coverage for success, explicit/default reasons, deterministic ID/time, snapshots, invalid quantity, insufficient stock, missing/archived targets, and rollback.

### File List

- _bmad-output/implementation-artifacts/3-3-record-stock-out-atomically-with-insufficient-stock-protection.md
- _bmad-output/implementation-artifacts/sprint-status.yaml
- tindatrack/lib/features/stock/data/repositories/drift_stock_repository.dart
- tindatrack/lib/features/stock/domain/entities/record_stock_out_input.dart
- tindatrack/lib/features/stock/domain/failures/stock_failure.dart
- tindatrack/lib/features/stock/domain/repositories/stock_repository.dart
- tindatrack/test/features/stock/data/repositories/drift_stock_repository_test.dart

### Change Log

- 2026-07-08: Created Story 3.3 artifact and marked it ready for dev.
- 2026-07-08: Implemented atomic Stock Out repository flow and moved story to review.