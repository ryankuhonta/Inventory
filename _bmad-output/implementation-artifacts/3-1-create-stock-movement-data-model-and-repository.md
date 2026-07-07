---
baseline_commit: 43cfbb44073af9117b8df42ccb0781a478c3237a
---

# Story 3.1: Create Stock Movement Data Model And Repository

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a store owner,
I want every stock change saved as a local movement record,
so that I can trust the app's inventory history.

## Acceptance Criteria

1. Given the product catalog foundation exists, when stock movement persistence is implemented, then the `stock_movements` table is created with `id`, `product_id`, `type`, `quantity`, `previous_quantity`, `new_quantity`, `reason`, `note`, `product_name_snapshot`, `unit_snapshot`, and `created_at`, and database columns use `snake_case`.
2. Given a stock movement is created, when it is saved locally, then it receives a ULID string ID and UTC timestamp from injectable services, and it stores the product name and unit snapshots from the time of movement.
3. Given movement type values are stored, when a movement is inserted, then type is constrained to `stock_in` or `stock_out`, and invalid movement types are rejected before persistence.
4. Given Stock Out reason support is added in the domain/data layer, when a Stock Out movement is recorded, then the reason value supports `sold`, `damaged`, `lost`, `personal_use`, and `correction`, and the default reason is `sold` when no selector is exposed in MVP.
5. Given movement history is queried, when the repository returns movement records, then records are sorted newest first, and widgets do not access Drift rows directly.

## Tasks / Subtasks

- [x] Task 1: Add Drift schema v3 for stock movements (AC: 1, 3, 4)
  - [x] Add `tindatrack/lib/core/database/tables/stock_movements_table.dart`.
  - [x] Define columns exactly as `id`, `product_id`, `type`, `quantity`, `previous_quantity`, `new_quantity`, `reason`, `note`, `product_name_snapshot`, `unit_snapshot`, `created_at`.
  - [x] Use `snake_case` SQL names through Drift's generated naming; Dart getters may stay `camelCase`.
  - [x] Add check constraints for positive `quantity`, non-negative `previous_quantity`, non-negative `new_quantity`, valid `type` values, and valid `reason` values.
  - [x] Use `product_id` as a reference to `products.id`; do not cascade-delete movement history.
  - [x] Add an index for product-scoped history queries, and add a created-time ordering index if needed by the DAO query.
  - [x] Register `StockMovements` and the new DAO in `AppDatabase`, bump `schemaVersion` from 2 to 3, and add a `from2To3` migration step.

- [x] Task 2: Generate and preserve Drift migration artifacts (AC: 1)
  - [x] Run Drift/build_runner generation from `tindatrack`.
  - [x] Add `drift_schemas/app_database/drift_schema_v3.json`.
  - [x] Update generated migration support and generated test schema files.
  - [x] Extend `test/core/database/app_database_migration_test.dart` to validate fresh schema v3 and v2-to-v3 migration.
  - [x] Add schema constraint tests for exact `stock_movements` columns, nullability, defaults, indexes, and enum/check constraints.

- [x] Task 3: Add stock movement domain contracts (AC: 2, 3, 4, 5)
  - [x] Create `tindatrack/lib/features/stock/domain/entities/stock_movement.dart`.
  - [x] Create input/value objects for recording movement metadata without touching product quantity yet, for example `create_stock_movement_input.dart`.
  - [x] Model `StockMovementType` with `stockIn`/`stockOut` mapped to persisted `stock_in`/`stock_out`.
  - [x] Model `StockOutReason` with `sold`, `damaged`, `lost`, `personalUse`, and `correction`; persistence must use `personal_use`.
  - [x] Default Stock Out reason to `sold` at the domain/application boundary when the caller omits a reason.
  - [x] Add typed stock failures under `features/stock/domain/failures`, reusing `AppFailure` and `Result<T>` rather than introducing exceptions or a second result type.
  - [x] Create `StockRepository` with methods needed by this story only: persist one movement record and watch/list movement history newest first.

- [x] Task 4: Add Drift DAO and repository implementation (AC: 2, 3, 4, 5)
  - [x] Create `tindatrack/lib/core/database/daos/stock_movements_dao.dart`.
  - [x] DAO stays persistence-only: insert movement rows, reject invalid persisted enum strings by table/domain validation, and query newest-first movement history.
  - [x] Create `tindatrack/lib/features/stock/data/repositories/drift_stock_repository.dart`.
  - [x] Repository composes `StockMovementsDao`, `IdGenerator`, and `Clock`, mirroring `DriftProductsRepository`.
  - [x] Repository maps Drift rows to domain entities and translates persistence errors into typed failures.
  - [x] Store `product_name_snapshot` and `unit_snapshot` from the input at creation time; do not look up or mutate product quantity in this story.

- [x] Task 5: Compose Riverpod providers for future Epic 3 stories (AC: 5)
  - [x] Create `tindatrack/lib/features/stock/presentation/providers/stock_providers.dart`.
  - [x] Provide `stockMovementsDaoProvider` from `databaseProvider`.
  - [x] Provide `stockRepositoryProvider` from DAO, `idGeneratorProvider`, and `clockProvider`.
  - [x] Do not add Stock In/Out routes, screens, row actions, or UI copy in Story 3.1.

- [x] Task 6: Add focused tests and quality gates (AC: 1, 2, 3, 4, 5)
  - [x] DAO tests prove insert and newest-first ordering without exposing Drift rows to widgets.
  - [x] Repository tests prove injected ULID and UTC clock usage.
  - [x] Repository tests prove product/unit snapshots are copied into the movement entity.
  - [x] Domain tests prove movement type and reason mappings, including default `sold`.
  - [x] Persistence tests prove invalid type/reason and invalid quantities are rejected.
  - [x] Provider tests prove production provider composition uses the app database, ID generator, and clock.
  - [x] Run formatter, Dart analyzer, focused tests, full Flutter test suite, and WSL `git diff --check`.

### Review Findings

- [x] [Review][Patch] v2-to-v3 migration test does not prove existing product rows are preserved [`tindatrack/test/core/database/app_database_migration_test.dart:26`]
- [x] [Review][Patch] Foreign key enforcement is not tested for orphan stock movement inserts [`tindatrack/test/core/database/stock_movements_schema_constraints_test.dart:102`]
- [x] [Review][Patch] listMovementHistory does not catch Object-level mapping failures from persisted enum parsing [`tindatrack/lib/features/stock/data/repositories/drift_stock_repository.dart:41`]
- [x] [Review][Patch] Repository validation tests do not cover negative previous/new quantity branches [`tindatrack/test/features/stock/data/repositories/drift_stock_repository_test.dart:108`]
- [x] [Review][Patch] Repository history tests do not prove productId filtering excludes other products for list/watch [`tindatrack/test/features/stock/data/repositories/drift_stock_repository_test.dart:89`]

## Dev Notes

### Source Requirements

- Epic 3 objective: users can record Stock In and Stock Out safely while preserving a reliable movement history for audit. [Source: `_bmad-output/planning-artifacts/epics.md#Epic 3: Stock Movement And Inventory History`]
- Story 3.1 covers FR-031, FR-032, FR-034, FR-035, NFR-002, and NFR-005. [Source: `_bmad-output/planning-artifacts/epics.md#Story 3.1: Create Stock Movement Data Model And Repository`]
- PRD requirements: movement supports optional note, successful movement creates inventory history, history sorts newest first, each transaction shows movement type/product/quantity/previous/new/date-time, local data persists after restart, and stock changes must be reliable and atomic. [Source: `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#Functional Requirements`]
- Architecture invariant: stock movement insert and product quantity update must eventually commit in one database transaction, but this story is the persistence foundation and must not implement quantity mutation yet. [Source: `_bmad-output/planning-artifacts/architecture.md#Architecture Invariants`]
- Architecture requires all stock movements to include `productId`, `type`, `quantity`, `previousQuantity`, `newQuantity`, `reason`, and `createdAt`; Story 3.1 additionally requires `product_name_snapshot` and `unit_snapshot`. [Source: `_bmad-output/planning-artifacts/architecture.md#Architecture Invariants`; `_bmad-output/planning-artifacts/epics.md#Story 3.1: Create Stock Movement Data Model And Repository`]
- Stock Out reasons are `sold`, `damaged`, `lost`, `personal_use`, and `correction`; `sold` is the MVP default when no selector is exposed. [Source: `_bmad-output/planning-artifacts/architecture.md#Stock Movement Reasons`; `_bmad-output/planning-artifacts/epics.md#Story 3.1: Create Stock Movement Data Model And Repository`]

### Current System State

- `AppDatabase` currently registers only `Products` and `ProductsDao`, and `schemaVersion` is `2`. This story must update it to include `StockMovements`, `StockMovementsDao`, and schema version `3`. [Source: `tindatrack/lib/core/database/app_database.dart`]
- Existing migration path uses generated `migrations.stepByStep` with `from1To2`. Add `from2To3`; do not replace the existing v1-to-v2 migration. [Source: `tindatrack/lib/core/database/app_database.dart`; `tindatrack/lib/core/database/generated_migrations.dart`]
- Existing Drift schema snapshots are `drift_schema_v1.json` and `drift_schema_v2.json`; Story 3.1 must add `drift_schema_v3.json`. [Source: `tindatrack/drift_schemas/app_database/`]
- Existing migration tests validate fresh schema v2 and real empty v1-to-v2 migration. Extend these tests for v3 instead of creating a parallel migration approach. [Source: `tindatrack/test/core/database/app_database_migration_test.dart`]
- Products are soft-archived, not deleted. Movement rows must remain readable after product archive or rename through snapshots. [Source: `tindatrack/lib/core/database/tables/products_table.dart`; `_bmad-output/implementation-artifacts/epic-2-retro-2026-07-07.md#Critical Path Items`]

### Architecture Compliance

- Use Flutter/Riverpod/Drift/Clean Architecture; no backend, cloud sync, scanner, POS, supplier, accounting, or remote API work belongs in this story. [Source: `_bmad-output/planning-artifacts/architecture.md#Core Architectural Decisions`]
- Keep `lib/core/database` responsible for Drift tables, DAOs, generated database wiring, migrations, and persistence-level query support. [Source: `_bmad-output/planning-artifacts/architecture.md#Component Boundary Rules`]
- Put stock domain/data/provider files under `lib/features/stock`; do not put stock movement behavior into `features/products`. [Source: `_bmad-output/planning-artifacts/architecture.md#Feature Boundary Table`]
- DAOs are persistence-only. Business validation, enum defaults, and failure mapping belong in domain/application/repository layers. [Source: `_bmad-output/planning-artifacts/architecture.md#Component Boundary Rules`]
- Domain entities must not depend on Drift generated classes. Repository implementations own Drift row to domain mapping. [Source: `_bmad-output/planning-artifacts/architecture.md#Data Flow`]
- Reuse the project-wide `IdGenerator`, `Clock`, `Result<T>`, `AppFailure`, and `PersistenceFailure`. Do not create another result abstraction, time abstraction, ID abstraction, or raw exception contract. [Source: `tindatrack/lib/app/providers.dart`; `tindatrack/lib/core/errors/result.dart`; `tindatrack/lib/core/errors/app_failure.dart`]

### Existing Patterns To Reuse

- `DriftProductsRepository` is the template for repository composition: DAO + `IdGenerator` + `Clock`, generated ULID, `clock.now().toUtc()`, try/catch around Drift calls, and row-to-domain mapping. [Source: `tindatrack/lib/features/products/data/repositories/drift_products_repository.dart`]
- Product providers show the expected Riverpod shape: DAO provider from `databaseProvider`, repository provider from DAO/ID/clock, and feature-level providers near presentation. [Source: `tindatrack/lib/features/products/presentation/providers/product_providers.dart`]
- Product DAO query parameters are persistence-only types inside the DAO file; use the same spirit for stock movement query inputs if needed. [Source: `tindatrack/lib/core/database/daos/products_dao.dart`]
- Product repository tests use `NativeDatabase.memory()`, local fake ID generators, and fixed clocks; use the same pattern unless a shared helper is introduced deliberately. [Source: `tindatrack/test/features/products/data/repositories/drift_products_repository_test.dart`]

### Story 3.1 Boundary

- This story creates stock movement persistence and repository foundations only.
- Do not implement Stock In or Stock Out product quantity changes yet; that belongs to Stories 3.2 and 3.3.
- Do not add Stock In/Out screens, navigation routes, row actions, form controllers, or history UI yet; those belong to Stories 3.4 through 3.7.
- Do not directly update `products.quantity` from this story's repository method. Story 3.2/3.3 will add the transaction boundary that combines product quantity update with movement insert.
- If a method is needed to create a movement record in this story, keep its name and documentation clear that it records a movement row only and is not the final stock mutation API.

### Data Model Guidance

- Suggested domain entity fields:
  - `id`
  - `productId`
  - `type`
  - `quantity`
  - `previousQuantity`
  - `newQuantity`
  - `reason`
  - `note`
  - `productNameSnapshot`
  - `unitSnapshot`
  - `createdAt`
- Persisted type values must be exactly `stock_in` and `stock_out`.
- Persisted reason values must be exactly `sold`, `damaged`, `lost`, `personal_use`, and `correction`.
- `note` is nullable. Keep blank-note normalization in the domain/application layer if this story accepts user-provided text.
- Store timestamps as UTC through `Clock`; never call `DateTime.now()` directly.
- Use ULID strings through `IdGenerator`; do not use auto-increment integer IDs.

### Testing Requirements

- Add/extend tests at these likely paths:
  - `tindatrack/test/core/database/app_database_migration_test.dart`
  - `tindatrack/test/core/database/stock_movements_schema_constraints_test.dart`
  - `tindatrack/test/core/database/daos/stock_movements_dao_test.dart`
  - `tindatrack/test/features/stock/domain/entities/stock_movement_test.dart`
  - `tindatrack/test/features/stock/data/repositories/drift_stock_repository_test.dart`
  - `tindatrack/test/features/stock/presentation/providers/stock_providers_test.dart`
- Required proofs:
  - Fresh schema v3 validates.
  - Schema v2 migrates to v3 and preserves existing product rows.
  - `stock_movements` columns are exact and no `cost_price`, sync, cloud, or scanner fields are introduced.
  - Invalid persisted `type`, invalid persisted `reason`, non-positive `quantity`, and negative previous/new quantities cannot persist.
  - Inserted movement uses exactly one injected ULID and one injected UTC timestamp.
  - Product name/unit snapshots survive later product metadata changes.
  - Movement history query sorts newest first.
  - Repository returns domain entities and typed failures, never Drift rows or raw exceptions.

### Build and Verification Notes

- Run generation from `tindatrack` after changing Drift tables/database annotations. Existing toolchain uses `build_runner`, `drift_dev`, and `build.yaml`.
- Expected verification:
  - Dart format for touched `lib` and `test` files
  - Dart analyzer clean
  - Focused stock movement/migration tests pass
  - Full Flutter test suite passes
  - WSL `git diff --check` clean
- If Windows Flutter tooling is needed, keep Windows mirrors verification-only; the WSL workspace remains authoritative. [Source: `_bmad-output/implementation-artifacts/epic-2-retro-2026-07-07.md#Previous Retrospective Follow-Through`]

### Project Structure Notes

- Expected new files:
  - `tindatrack/lib/core/database/tables/stock_movements_table.dart`
  - `tindatrack/lib/core/database/daos/stock_movements_dao.dart`
  - `tindatrack/lib/features/stock/domain/entities/stock_movement.dart`
  - `tindatrack/lib/features/stock/domain/repositories/stock_repository.dart`
  - `tindatrack/lib/features/stock/domain/failures/stock_failure.dart`
  - `tindatrack/lib/features/stock/data/repositories/drift_stock_repository.dart`
  - `tindatrack/lib/features/stock/presentation/providers/stock_providers.dart`
- Expected updated files:
  - `tindatrack/lib/core/database/app_database.dart`
  - generated Drift outputs including `app_database.g.dart`, DAO `.g.dart`, `generated_migrations.dart`, and generated test schema files
  - `tindatrack/test/core/database/app_database_migration_test.dart`
- Detected variance: architecture mentions `test/helpers/test_database.dart`, but the current repo does not have `tindatrack/test/helpers`. Follow current in-memory `NativeDatabase.memory()` patterns unless a helper becomes necessary.

### Git Intelligence Summary

- Recent commits show the current branch completed Epic 2 and the retrospective: `43cfbb4 Complete Epic 2 retrospective`, `3e7e3dc Complete product archiving and prepare row actions`, `4299867 Complete product editing and review fixes`, `fe9c939 Implement product search filters and stock status`, and `c251554 Complete product catalog stories 2.1-2.3 and prepare 2.4`.
- The local worktree contains historical untracked handoff/review prompt files. Preserve them; do not clean, stage, or delete them unless explicitly instructed.
- No commit or push should be performed by the dev agent unless the user explicitly asks.

### Latest Technical Information

- No external web research was needed for this story. Project architecture and `pubspec.yaml` provide the active version context: Dart SDK `^3.12.0`, Drift `^2.34.0`, `drift_dev` `^2.34.0`, Riverpod `^3.3.2`, and go_router `^17.3.0`. [Source: `tindatrack/pubspec.yaml`; `_bmad-output/planning-artifacts/architecture.md#Data Architecture`]

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- 2026-07-08 BMAD code review closeout verification passed: focused Story 3.1 tests 24/24, Dart analyzer clean, full Flutter test suite 251/251, and WSL git diff --check clean.
- dart run build_runner build and Drift schema commands run from Windows-local temp copy because Windows Flutter/Dart hung on the WSL UNC path.
- lutter analyze passed from 	indatrack via cmd /c pushd.
- Focused Story 3.1 tests passed from C:\tmp\inventory_codegen_3_1: 21/21.
- Full Flutter test suite passed from C:\tmp\inventory_codegen_3_1: 248/248.
- WSL git diff --check passed.

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.
- Added Drift stock_movements schema v3 with quantity/type/reason checks, product reference, history indexes, generated migration support, and v3 schema snapshots.
- Added stock movement DAO, domain entity/enums/input/failures/repository contract, Drift repository, and Riverpod providers.
- Repository records movement rows with injected ULID/UTC clock values, copies product/unit snapshots, defaults omitted Stock Out reason to sold, and does not mutate product quantities or add UI.
- Added migration, schema constraint, DAO, domain, repository, provider, and regression test coverage; analyzer and full suite pass.

### File List

- tindatrack/drift_schemas/app_database/drift_schema_v3.json
- tindatrack/lib/core/database/app_database.dart
- tindatrack/lib/core/database/app_database.g.dart
- tindatrack/lib/core/database/daos/stock_movements_dao.dart
- tindatrack/lib/core/database/daos/stock_movements_dao.g.dart
- tindatrack/lib/core/database/generated_migrations.dart
- tindatrack/lib/core/database/tables/stock_movements_table.dart
- tindatrack/lib/features/stock/data/repositories/drift_stock_repository.dart
- tindatrack/lib/features/stock/domain/entities/create_stock_movement_input.dart
- tindatrack/lib/features/stock/domain/entities/stock_movement.dart
- tindatrack/lib/features/stock/domain/failures/stock_failure.dart
- tindatrack/lib/features/stock/domain/repositories/stock_repository.dart
- tindatrack/lib/features/stock/presentation/providers/stock_providers.dart
- tindatrack/test/core/database/app_database_migration_test.dart
- tindatrack/test/core/database/app_database_schema_test.dart
- tindatrack/test/core/database/app_database_test.dart
- tindatrack/test/core/database/daos/stock_movements_dao_test.dart
- tindatrack/test/core/database/stock_movements_schema_constraints_test.dart
- tindatrack/test/features/stock/data/repositories/drift_stock_repository_test.dart
- tindatrack/test/features/stock/domain/entities/stock_movement_test.dart
- tindatrack/test/features/stock/presentation/providers/stock_providers_test.dart
- tindatrack/test/generated_migrations/schema.dart
- tindatrack/test/generated_migrations/schema_v3.dart

### Change Log

- 2026-07-08: Completed BMAD code review patches and marked Story 3.1 done after verification.
- 2026-07-07: Implemented Story 3.1 stock movement persistence foundation and moved story to review.
