---
baseline_commit: 5175352a3c81a183ca71fa52d8a483f97434103d
---

# Story 3.2: Record Stock In Atomically

Status: done

## Story

As a store owner,
I want to record added inventory,
So that new purchases increase available stock and leave a history trail.

## Acceptance Criteria

1. Given an active product exists, when the user records Stock In with a positive quantity, then the product quantity increases by that quantity, and a `stock_in` movement is inserted with previous quantity, new quantity, product snapshots, optional note, and UTC timestamp.
2. Given the user records Stock In with zero or negative quantity, when the action is submitted, then the action is rejected, and no product quantity or movement history change is saved.
3. Given the target product does not exist or is archived, when Stock In is attempted, then the action is rejected with a typed failure, and the UI can map the failure to friendly copy.
4. Given a Stock In operation is processed, when either the product quantity update or movement insert fails, then the entire transaction rolls back, and no partial inventory state is saved.

## Tasks / Subtasks

- [x] Task 1: Add Stock In domain input and typed failures (AC: 1, 2, 3)
  - [x] Create a minimal `RecordStockInInput` with `productId`, positive `quantity`, and optional `note`.
  - [x] Extend stock failures with typed missing-product, archived-product, and validation failures reusable by UI copy.
  - [x] Preserve existing movement-row validation behavior from Story 3.1.

- [x] Task 2: Add product persistence support for atomic quantity updates (AC: 1, 4)
  - [x] Add a DAO method that updates `products.quantity` and `updated_at` for one active product by ID.
  - [x] Keep direct quantity mutation scoped to stock repository transaction flows; product edit must still not alter stock.
  - [x] Preserve non-negative product quantity constraints.

- [x] Task 3: Implement atomic `recordStockIn` repository flow (AC: 1, 2, 3, 4)
  - [x] Read the product row by ID, including archived rows.
  - [x] Reject missing or archived products with typed failures before mutation.
  - [x] Validate positive stock-in quantity before generating IDs or timestamps.
  - [x] Compute `previousQuantity` and `newQuantity`.
  - [x] In one Drift transaction, update `products.quantity` and insert a `stock_movements` row with `stock_in`.
  - [x] Store product name/unit snapshots from the product row at movement time.
  - [x] Use injected ULID and UTC clock values; never call `DateTime.now()` directly.

- [x] Task 4: Update providers and focused tests (AC: 1, 2, 3, 4)
  - [x] Compose `DriftStockRepository` with `ProductsDao` as well as `StockMovementsDao`.
  - [x] Test success updates product quantity and writes movement history.
  - [x] Test injected ULID/UTC timestamp and product name/unit snapshots.
  - [x] Test invalid quantity, missing product, and archived product do not mutate.
  - [x] Test rollback when movement insert fails after product update.
  - [x] Run focused stock tests, analyzer, full Flutter test suite, and WSL `git diff --check`.

### Review Findings

- [x] [Review][Patch] Stock In reads and computes product quantity outside the transaction [tindatrack/lib/features/stock/data/repositories/drift_stock_repository.dart:97]
- [x] [Review][Patch] Story baseline commit does not resolve in the authoritative WSL repository [_bmad-output/implementation-artifacts/3-2-record-stock-in-atomically.md:2]

## Dev Notes

### Source Requirements

- Epic 3 objective: users can record Stock In and Stock Out safely while preserving reliable movement history for audit. [Source: `_bmad-output/planning-artifacts/epics.md#Epic 3: Stock Movement And Inventory History`]
- Story 3.2 covers FR-024, FR-025, FR-026, FR-031, FR-032, FR-033, NFR-005, and UX-DR20. [Source: `_bmad-output/planning-artifacts/epics.md#Story 3.2: Record Stock In Atomically`]
- Architecture invariants require product quantity update and stock movement insert to commit in one transaction, product quantity never to become negative, movement history to remain readable after archive/rename, and user-facing errors to come from typed failures. [Source: `_bmad-output/planning-artifacts/architecture.md#Architecture Invariants`]
- Archived products cannot receive Stock In/Out unless restored first. [Source: `_bmad-output/planning-artifacts/architecture.md#Boundary sweep decisions`]
- Stock In uses movement type `stock_in` and optional note; MVP does not require a separate Stock In reason enum. [Source: `_bmad-output/planning-artifacts/architecture.md#Boundary sweep decisions`]

### Current System State

- Story 3.1 added `stock_movements`, `StockMovementsDao`, `CreateStockMovementInput`, `StockMovement`, `StockRepository`, `DriftStockRepository`, and `stockRepositoryProvider`.
- `DriftStockRepository.recordMovementRow` inserts movement audit rows only and deliberately does not mutate products. Story 3.2 must add a true stock-in mutation API while preserving that row-only method for existing tests and future internal use.
- `ProductsDao.getProductById` reads active and archived rows. `ProductsDao` currently updates details and archives products but has no quantity-update method.
- `AppDatabase` already registers `Products`, `StockMovements`, `ProductsDao`, and `StockMovementsDao`, with schema version 3 and foreign keys enabled.

### Architecture Compliance

- Use Flutter/Riverpod/Drift/Clean Architecture. No UI, route, scanner, POS, cloud, supplier, accounting, or dashboard work belongs in this story.
- Keep Drift DAOs persistence-only. Transaction orchestration belongs in the repository/data boundary.
- Domain entities and inputs must not depend on Drift generated classes.
- Reuse `IdGenerator`, `Clock`, `Result<T>`, `AppFailure`, and `PersistenceFailure`.
- Use `clock.now().toUtc()` and ULID generation only after domain validation has passed.

### Previous Story Intelligence

- Story 3.1 established movement type persistence values `stock_in` and `stock_out`, Stock Out reason defaults, product name/unit snapshots, and repository failure mapping.
- Story 3.1 tests use `NativeDatabase.memory()`, fake ID generators, and fixed clocks; follow that style.
- Prior review findings emphasized rollback/constraint coverage, product history filtering, and mapping persisted enum failures to typed persistence failures. Story 3.2 should keep these guards in place.

### Testing Requirements

- Add focused tests primarily in `tindatrack/test/features/stock/data/repositories/drift_stock_repository_test.dart`.
- Required proofs:
  - Stock In success updates product quantity and inserts exactly one `stock_in` movement.
  - Movement has injected ID and UTC timestamp.
  - Movement snapshots product name and unit from the product row.
  - Zero or negative quantity returns typed validation failure and does not update product or movement history.
  - Missing product returns typed missing-product failure and does not write movement history.
  - Archived product returns typed archived-product failure and does not mutate.
  - If movement insert fails after product update, the transaction rolls back product quantity.

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- 2026-07-08: Created Story 3.2 context and began implementation from backlog.
- 2026-07-08: Focused stock repository test passed on local verification copy: 15/15.
- 2026-07-08: Dart analyzer passed on local verification copy with no issues.
- 2026-07-08: Full Flutter test suite passed on local verification copy: 257/257.
- 2026-07-08: WSL git diff --check passed.
- 2026-07-08: Code review patches passed focused stock repository test: 15/15.
- 2026-07-08: Code review patches passed Dart analyzer with no issues.
- 2026-07-08: Code review patches passed full Flutter test suite: 257/257.
- 2026-07-08: Code review patches passed WSL git diff --check.

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.
- Added `RecordStockInInput` and stock-specific typed failures for missing and archived products.
- Added active product quantity update support in `ProductsDao` for stock transaction flows.
- Extended `DriftStockRepository` with `recordStockIn`, which reads the product row, rejects invalid targets/quantities, computes previous/new quantities, updates the product, and inserts the `stock_in` movement in one Drift transaction.
- Movement rows use injected ULID/UTC timestamp values, preserve product name/unit snapshots, normalize optional notes, and roll back product quantity if movement insertion fails.
- Code review moved Stock In product read, quantity computation, active update, and movement insert into one transaction-scoped flow.
- Added focused repository coverage for success, deterministic ID/time, snapshots, invalid quantity, missing/archived product no-op behavior, and transaction rollback.

### File List

- _bmad-output/implementation-artifacts/3-2-record-stock-in-atomically.md
- _bmad-output/implementation-artifacts/sprint-status.yaml
- tindatrack/lib/core/database/daos/products_dao.dart
- tindatrack/lib/features/stock/data/repositories/drift_stock_repository.dart
- tindatrack/lib/features/stock/domain/entities/record_stock_in_input.dart
- tindatrack/lib/features/stock/domain/failures/stock_failure.dart
- tindatrack/lib/features/stock/domain/repositories/stock_repository.dart
- tindatrack/lib/features/stock/presentation/providers/stock_providers.dart
- tindatrack/test/features/stock/data/repositories/drift_stock_repository_test.dart

### Change Log

- 2026-07-08: Created Story 3.2 artifact and marked it in progress.
- 2026-07-08: Implemented atomic Stock In repository flow and moved story to review.
- 2026-07-08: Applied code review fixes and moved story to done.
