---
baseline_commit: f758d77cead3d1f8f921d46bd0aa9bf48a07cf72
---

# Story 2.1: Create Product Catalog Data Model And Repository

Status: done

## Story

As a store owner,
I want my products saved locally,
so that my inventory list remains available after closing and reopening the app.

## Acceptance Criteria

1. **Products schema without deferred accounting scope**
   - **Given** the local database foundation exists
   - **When** product catalog persistence is implemented
   - **Then** the `products` table contains `id`, `name`, `category`, `unit`, `selling_price`, `quantity`, `low_stock_threshold`, `barcode`, `is_archived`, `created_at`, and `updated_at`
   - **And** `cost_price` is not added to the MVP schema.

2. **Generated identity, UTC timestamps, and durable persistence**
   - **Given** a product is created through the repository
   - **When** the product is saved locally
   - **Then** it receives a ULID string ID from the injected `IdGenerator`
   - **And** `createdAt` and `updatedAt` use the same UTC instant from the injected `Clock`
   - **And** the saved product remains available after the database is closed and reopened.

3. **Nullable barcode normalization**
   - **Given** a barcode value is persisted
   - **When** the input is blank or whitespace-only
   - **Then** the repository stores `null`
   - **And** multiple products may have null barcodes
   - **And** nonblank barcodes are trimmed without adding case-folding or scanner behavior.

4. **Barcode uniqueness and typed failure**
   - **Given** a non-null normalized barcode already belongs to any active or archived product
   - **When** another product is saved with that barcode
   - **Then** the database rejects the duplicate as the final concurrency-safe guard
   - **And** the repository returns `DuplicateBarcodeFailure`
   - **And** no raw Drift, SQLite, or constraint error escapes the repository.

5. **Active product query returns domain entities**
   - **Given** products exist locally
   - **When** the active product query runs
   - **Then** it returns only non-archived products, sorted by name ascending
   - **And** consumers receive domain `Product` entities, never generated Drift rows.

6. **Fresh schema v2 and migration from v1 are equivalent**
   - **Given** either a fresh database or the existing empty schema-v1 database
   - **When** the database opens at schema version 2
   - **Then** the resulting products schema, indexes, defaults, and constraints are equivalent
   - **And** v1 is upgraded without destructive reset behavior
   - **And** fresh-v2 and v1-to-v2 migration tests pass.

7. **Database lifecycle and retry behavior is deterministic**
   - **Given** the database is disposed or launch initialization is retried
   - **When** provider reads or close operations throw synchronously, complete with an `Exception` or Dart `Error`, reject a cached close future, or exceed a bounded timeout
   - **Then** no disposal error becomes an unhandled zone error
   - **And** concurrent callers share one in-flight close attempt
   - **And** a rejected close attempt is not cached permanently
   - **And** Retry is re-enabled rather than remaining disabled
   - **And** tests cover each path without wall-clock sleeps.

## Tasks / Subtasks

- [x] Task 1: Harden shared database lifecycle and launch Retry (AC: 7)
  - [x] Make provider disposal observe and safely contain asynchronous close failures.
  - [x] Preserve one shared in-flight close for concurrent callers, but evict a rejected attempt so a later call can retry.
  - [x] Recover from synchronous provider reads, `Exception`, `Error`, rejected close futures, and a bounded close timeout.
  - [x] Keep Retry state deterministic across success, failure, timeout, widget disposal, and provider invalidation.
  - [x] Test with controlled completers/injected timeout behavior; do not sleep.

- [x] Task 2: Define the Drift products table and schema-v2 migration (AC: 1, 3, 4, 6)
  - [x] Add `Products` at `lib/core/database/tables/products_table.dart`.
  - [x] Use text ULID primary key; required name/unit; nullable category/barcode; REAL selling price; integer quantity/threshold; boolean archive state; UTC `DateTime` fields.
  - [x] Add database checks for non-negative selling price, quantity, and threshold; default `is_archived` to false.
  - [x] Make normalized barcode nullable and unique across active and archived rows. SQLite UNIQUE permits multiple nulls.
  - [x] Add architecture-required query indexes; do not duplicate the barcode index created by UNIQUE.
  - [x] Register the table/DAO, bump schema version 1 to 2, create all entities on fresh install, and create v2 entities on upgrade.
  - [x] Preserve the existing schema-v1 export; generate and retain schema-v2 migration support.
  - [x] Regenerate `app_database.g.dart`; never hand-edit generated code.

- [x] Task 3: Add product domain types and repository contract (AC: 2–5)
  - [x] Add a Drift-independent immutable `Product` entity with exactly the Story 2.1 fields.
  - [x] Add a create input/draft that does not generate IDs/timestamps or expose Drift companions.
  - [x] Add feature-owned `DuplicateBarcodeFailure` extending `AppFailure`.
  - [x] Define `ProductRepository` in `features/products/domain/repositories/products_repository.dart` with minimal create and watch-active operations.
  - [x] Reuse the existing `Result<T>` contract; do not add another result abstraction.

- [x] Task 4: Implement DAO and Drift repository (AC: 2–5)
  - [x] Keep `ProductsDao` persistence-only: insert and SQL-filtered active query.
  - [x] Inject DAO/database, `IdGenerator`, and `Clock` into `DriftProductsRepository`.
  - [x] Normalize barcode once: trim and convert empty to `null`.
  - [x] Generate one ULID and capture one UTC instant before insertion so both timestamps match.
  - [x] Map generated rows to domain entities in the data layer.
  - [x] Map barcode constraint violations to `DuplicateBarcodeFailure`; map other database errors to the existing persistence failure.
  - [x] Return a reactive SQL query filtered by archive state and ordered by name; do not filter/sort a full table in Dart.

- [x] Task 5: Add schema, repository, persistence, and lifecycle tests (AC: 1–7)
  - [x] Verify exact SQL columns, names, primary key, nullability, defaults, checks, indexes, and absence of `cost_price`.
  - [x] Verify fresh v2 and v1-to-v2 schemas using Drift migration tooling.
  - [x] Verify product persistence through close/reopen with an isolated file-backed database.
  - [x] Verify deterministic injected ULID and UTC timestamp.
  - [x] Verify blank barcode normalization, multiple nulls, trimmed duplicates, and archived-row uniqueness.
  - [x] Verify active-only name-sorted reactive domain results.
  - [x] Verify negative price, quantity, and threshold cannot bypass database safeguards.
  - [x] Verify repository errors never leak raw Drift/SQLite exceptions.
  - [x] Cover every lifecycle/retry path from Task 1.

- [x] Task 6: Generate and verify the complete application (AC: 1–7)
  - [x] Run Drift/build_runner and migration generation; confirm generated files are current.
  - [x] Run format, Flutter analysis, and the complete test suite.
  - [x] Build the Android debug APK from a disposable `C:\tmp` mirror if UNC Flutter remains unreliable; WSL stays authoritative.
  - [x] Run the agreed emulator/device launch walkthrough when available; do not add Story 2.2 UI.

### Review Findings

- [x] [Review][Patch] Prevent overlapping database close attempts after timeout [tindatrack/lib/app/providers.dart:81]
- [x] [Review][Patch] Test non-barcode failure translation through a real SQLite repository boundary [tindatrack/test/features/products/data/repositories/drift_products_repository_test.dart:127]
- [x] [Review][Patch] Complete AC7 lifecycle and Retry regression coverage for synchronous close failure, production timeout, and successful invalidation/state recovery [tindatrack/test/app/database_lifecycle_regression_test.dart:60]
## Dev Notes

### Developer Context

This is the first story with real product data. `AppDatabase` is intentionally schema version 1 with no feature tables, and `drift_schemas/app_database/drift_schema_v1.json` records that empty baseline. Story 2.1 establishes the migration pattern inherited by later epics.

Epic 1 already provides `AppDatabase` with an injectable executor, Riverpod database/ULID/clock providers, `AppFailure`, `PersistenceFailure`, `Result<T>`, offline bootstrap, and launch Retry. Extend these seams. Do not introduce another database, ID/time abstraction, result type, or direct widget-to-Drift access.

### Data Contract

| SQL column | Drift/Dart type | Rule |
|---|---|---|
| `id` | text / `String` | ULID primary key; no auto-increment |
| `name` | text / `String` | required |
| `category` | nullable text / `String?` | optional |
| `unit` | text / `String` | required; UI default belongs to Story 2.2 |
| `selling_price` | real / `double` | non-negative; no `cost_price` |
| `quantity` | integer / `int` | non-negative; initial quantity only |
| `low_stock_threshold` | integer / `int` | non-negative |
| `barcode` | nullable unique text / `String?` | trimmed; blank becomes null |
| `is_archived` | boolean / `bool` | defaults false; no hard delete |
| `created_at` | dateTime / `DateTime` | injected UTC |
| `updated_at` | dateTime / `DateTime` | same injected UTC on create |

Do not add `archived_at`, sync fields, stock movements, `cost_price`, scanner dependencies, or product UI. After creation, quantity must not be changed through generic product updates; Epic 3 owns stock mutation.

### Architecture and Repository Guardrails

```text
future presentation/controller
  -> domain repository contract
  <- data repository implementation
  -> ProductsDao
  -> AppDatabase / SQLite
```

- Domain code must not import Drift.
- Use this minimal domain contract; do not add edit/archive/filter methods early:

```dart
abstract interface class ProductRepository {
  Future<Result<Product>> createProduct(CreateProductInput input);
  Stream<List<Product>> watchActiveProducts();
}
```

- DAO code remains unaware of ULIDs, clocks, domain failures, and UI copy.
- Repository code owns row mapping, normalization, generated values, and exception translation.
- Core must not depend on the products feature. `DuplicateBarcodeFailure` remains feature-owned; Story 2.2 may map it to friendly copy.
- The UNIQUE constraint is authoritative for races; preflight lookup cannot replace constraint handling.
- Fresh creation uses current entities; v1-to-v2 upgrade creates only new v2 entities.
- Never delete/recreate the database or clear user data during migration.

### Lifecycle/Retry Guardrails From The Epic 1 Retrospective

These are required Story 2.1 work:

1. Provider disposal observes close failures so they do not become unhandled asynchronous errors.
2. Rejected cached close futures are evicted for later retry.
3. Hanging close does not strand Retry disabled.
4. Retry recovers if reading the failed database provider throws.
5. Tests include `Exception` and Dart `Error` outcomes.

Preserve lazy database creation, one in-flight close shared by concurrent callers, mounted checks, and invalidation after successful retry.

### Current Files To Update

- `tindatrack/lib/core/database/app_database.dart`: register products/DAO, schema v2, migration; preserve injectable executor, production path, and `ensureReady`.
- `tindatrack/lib/core/database/app_database.g.dart`: regenerate only.
- `tindatrack/lib/app/providers.dart`: safe disposal and retryable close cache; preserve lazy providers and concurrent sharing.
- `tindatrack/lib/app/app.dart`: bounded total Retry failure handling; preserve launch states and mounted checks.
- Existing related tests under `test/app` and `test/core/database`: extend, do not replace.

### Expected New Files

```text
lib/core/database/tables/products_table.dart
lib/core/database/daos/products_dao.dart
lib/features/products/domain/entities/product.dart
lib/features/products/domain/entities/create_product_input.dart
lib/features/products/domain/failures/product_failure.dart
lib/features/products/domain/repositories/products_repository.dart
lib/features/products/data/repositories/drift_products_repository.dart
test/core/database/app_database_migration_test.dart
test/core/database/daos/products_dao_test.dart
test/features/products/data/repositories/drift_products_repository_test.dart
```

Keep helper splitting minimal. Generated migration helpers/schema snapshots stay in locations configured by `build.yaml`. Tests mirror `lib/` where practical.

### Testing Requirements

- Use `NativeDatabase.memory()` for isolated behavior and a temporary file-backed database for restart persistence.
- Use checked-in schema snapshots for migration validation.
- Inject fake IDs and clock values; never assert random IDs or real time.
- Use controlled futures/completers for lifecycle paths; avoid flaky sleeps.
- Keep the existing 44-test baseline passing.
- Verify SQL filtering/order rather than equivalent in-memory behavior.

### Library and Latest Technical Information

No dependency upgrade is needed:

- Dart SDK constraint `^3.12.0`
- Drift `2.34.0`
- drift_flutter `0.3.0`
- SQLite resolved to `3.3.3`
- Riverpod `3.3.2`
- ULID `2.0.1`

Verified 2026-06-28: Drift `2.34.0` and drift_flutter `0.3.0` are current stable; drift_flutter 0.3.0 uses sqlite3 3.x. Current Drift guidance favors generated schema snapshots and migration tests. SQLite treats nulls as distinct under UNIQUE, supporting multiple null barcodes while rejecting duplicate non-null values. Avoid an unrelated package-upgrade sweep.

### Scope Boundaries

Do not implement Add/Edit Product UI (2.2), list UI (2.3), search/filter UI (2.4), stock status UI (2.5), edit/archive flows (2.6–2.7), row actions (2.8), stock movement/history (Epic 3), or scanner/cloud/login/POS/supplier/accounting functionality.

### Git Intelligence

- `f758d77` completed Epic 1 bootstrap, routing, theme, base states, and retrospective.
- `eb878cb` established Drift exports, database injection, failures/results, ULID, clock, and mirrored tests.

Extend these patterns. The worktree was clean and synchronized at story creation.

### Latest Technical References

- [Drift migrations](https://drift.simonbinder.eu/migrations/)
- [Drift migration tests](https://drift.simonbinder.eu/migrations/tests/)
- [Drift tables and constraints](https://drift.simonbinder.eu/dart_api/tables/)
- [Drift stream queries](https://drift.simonbinder.eu/dart_api/streams/)
- [SQLite UNIQUE constraints](https://www.sqlite.org/lang_createtable.html#unique_constraints)
- [Drift package](https://pub.dev/packages/drift)
- [drift_flutter package](https://pub.dev/packages/drift_flutter)

### Project Structure Notes

- Older source material mentions UUID and `cost_price`; finalized epics and architecture override these with ULID and no `cost_price`.
- UX says selling price is optional at form level; Story 2.2 owns form defaults/validation. Story 2.1 stores a non-negative REAL value.
- SQL names are `snake_case`; Dart names are `camelCase`.
- `ProductRepository` is the class name; the canonical architecture file path is `products_repository.dart`.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.1: Create Product Catalog Data Model And Repository]
- [Source: _bmad-output/planning-artifacts/architecture.md#Data Architecture]
- [Source: _bmad-output/planning-artifacts/architecture.md#Non-Negotiable Consistency Rules]
- [Source: _bmad-output/planning-artifacts/architecture.md#Required Implementation Test Checklist]
- [Source: _bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#Product Management]
- [Source: _bmad-output/implementation-artifacts/epic-1-retro-2026-06-28.md#Action Items]
- [Source: _bmad-output/implementation-artifacts/deferred-work.md]
- [Source: tindatrack/lib/core/database/app_database.dart]
- [Source: tindatrack/lib/app/providers.dart]
- [Source: tindatrack/lib/app/app.dart]
- [Source: tindatrack/build.yaml]
- [Source: tindatrack/drift_schemas/app_database/drift_schema_v1.json]

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- Task 1 RED: lifecycle and Retry regression tests failed against the original permanent close cache and unbounded retry flow.
- Task 1 GREEN: 53-test full suite passed after retryable close caching, bounded waits, safe disposal observation, and deterministic Retry recovery.
- Task 2 RED: fresh schema tests observed schema v1 and no products table.
- Task 2 GREEN: generated schema v2, v1-to-v2 step migration, exact table constraints/index, and snapshot validation passed in the 57-test suite.
- Task 3 RED: domain contract tests failed because product types and repository interfaces did not exist.
- Task 3 GREEN: Drift-independent immutable types, feature-owned duplicate failure, and minimal canonical repository contract passed in the 61-test suite.
- Task 4 RED: DAO/repository tests failed on missing insert, active watch, normalization, mapping, and typed failures.
- Task 4 GREEN: SQL-filtered DAO and Drift repository passed deterministic ID/UTC, normalization, uniqueness, mapping, and failure tests in the 68-test suite.
- Task 5 RED: expanded schema metadata revealed the expected primary-key autoindex alongside barcode uniqueness; the assertion was refined to detect duplicate barcode indexes specifically.
- Task 5 GREEN: full 75-test suite passed, including migration, persistence restart, reactive watch, DB safeguards, typed errors, and lifecycle regressions.
- Task 6 GREEN: Drift and migration generation current; format and analysis clean; 75/75 tests passed; Android debug APK built; API 36 launch verified with MainActivity focused.

### Implementation Plan

- Follow story task order with red-green-refactor and full regression gates after each task.

### Completion Notes List

- Implemented schema v2 with the exact products table, generated migration steps, and preserved schema-v1 baseline.
- Added Drift-independent product domain types, feature-owned duplicate-barcode failure, SQL DAO, and Drift repository.
- Added deterministic ULID/UTC creation, barcode normalization, active-only reactive ordering, and typed persistence failure mapping.
- Hardened database disposal and Retry for shared closes, rejection eviction, timeout, synchronous reads, `Exception`, and Dart `Error`.
- Verified Drift generation and migrations, formatting, clean Flutter analysis, 75/75 tests, Android debug APK, and API 36 emulator launch.

### File List

- `_bmad-output/implementation-artifacts/2-1-create-product-catalog-data-model-and-repository.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `tindatrack/analysis_options.yaml`
- `tindatrack/drift_schemas/app_database/drift_schema_v2.json`
- `tindatrack/lib/app/app.dart`
- `tindatrack/lib/app/providers.dart`
- `tindatrack/lib/core/database/app_database.dart`
- `tindatrack/lib/core/database/app_database.g.dart`
- `tindatrack/lib/core/database/daos/products_dao.dart`
- `tindatrack/lib/core/database/daos/products_dao.g.dart`
- `tindatrack/lib/core/database/generated_migrations.dart`
- `tindatrack/lib/core/database/tables/products_table.dart`
- `tindatrack/lib/features/products/data/repositories/drift_products_repository.dart`
- `tindatrack/lib/features/products/domain/entities/create_product_input.dart`
- `tindatrack/lib/features/products/domain/entities/product.dart`
- `tindatrack/lib/features/products/domain/failures/product_failure.dart`
- `tindatrack/lib/features/products/domain/repositories/products_repository.dart`
- `tindatrack/test/app/database_lifecycle_regression_test.dart`
- `tindatrack/test/app/launch_retry_regression_test.dart`
- `tindatrack/test/core/database/app_database_migration_test.dart`
- `tindatrack/test/core/database/app_database_schema_test.dart`
- `tindatrack/test/core/database/app_database_test.dart`
- `tindatrack/test/core/database/daos/products_dao_test.dart`
- `tindatrack/test/core/database/products_schema_constraints_test.dart`
- `tindatrack/test/features/products/data/repositories/drift_products_repository_test.dart`
- `tindatrack/test/features/products/data/repositories/product_persistence_regression_test.dart`
- `tindatrack/test/features/products/domain/product_domain_test.dart`
- `tindatrack/test/generated_migrations/schema.dart`
- `tindatrack/test/generated_migrations/schema_v1.dart`
- `tindatrack/test/generated_migrations/schema_v2.dart`

## Change Log

- 2026-06-28: Implemented Story 2.1 product catalog persistence foundation and lifecycle hardening; ready for review.
