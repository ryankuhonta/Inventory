---
stepsCompleted: [1, 2, 3, 4, 5, 6]
inputDocuments:
  - _bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md
  - _bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/addendum.md
  - _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md
  - _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md
  - docs/bmad-inventory-tracker-plan.md
workflowType: 'architecture'
project_name: 'Inventory'
user_name: 'Phg00311'
date: '2026-05-28'
status: 'initialized'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Step 1: Workflow Initialization

Architecture workspace initialized for Inventory.

### Documents Found

- PRD: 1 finalized PRD loaded.
- PRD addendum: 1 downstream technical note loaded.
- UX Design: 2 finalized UX spines loaded.
- Project documentation: 1 combined BMAD planning document loaded.
- Project context: none found.

### Files Loaded

- `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md`
- `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/addendum.md`
- `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md`
- `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md`
- `docs/bmad-inventory-tracker-plan.md`

### Initialization Result

The required PRD exists, and UX inputs are available. The architecture workflow is ready for project context analysis.

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**
The MVP has 40 detailed functional requirements, but architecturally these should be grouped into a small set of MVP capabilities rather than treated as 40 equal priorities:

- Dashboard action summary
- Product CRUD and archive
- Product search and filtering
- Stock In / Stock Out
- Inventory history
- Settings and future backup/export placeholder

The primary daily loop is:

Check stock -> Search/select product -> Stock in/out -> Confirm -> See updated quantity/history

This loop should drive architecture decisions more than feature count. The app must help users answer: "Ilan na lang ang paninda ko, and ano ang nadagdag/nabawas?"

**Non-Functional Requirements:**
The architecture is shaped strongly by offline-first behavior, local persistence, low-end Android performance, data reliability, readable UI, and future cloud-sync readiness. The app must not require login, internet, or barcode scanning for MVP inventory work.

**Scale & Complexity:**

- Primary domain: Android offline-first mobile app.
- Complexity level: medium.
- Estimated architectural components: app shell, routing, design system/theme, local database, product feature, stock movement feature, dashboard feature, history feature, settings feature, shared validation/error/loading components.

### Technical Constraints & Dependencies

- Flutter is the selected mobile stack.
- Riverpod is selected for state management.
- Drift over SQLite is selected for local persistence because the app needs relational integrity, migrations, transactions, and queryable history.
- Clean Architecture is preferred to keep UI, domain rules, and data access separated.
- UUIDs or ULIDs should be used for products and transactions from day one to support future sync.
- Barcode scanning is deferred to the next release, but product records should support a nullable barcode field now.
- Barcode must be nullable and unique when present.
- Stock In and Stock Out must use database transactions.
- Product deletion should be avoided; archive internally and use friendlier UI language such as "Hide product" or "Stop selling."
- Ads must not appear in Add Product, Edit Product, Stock In, Stock Out, or before any save/confirm action.
- Login and cloud sync are future-ready but should not appear as fake MVP flows.

### Architecture Invariants

- INV-001: Product quantity must never be negative.
- INV-002: Stock movement insert and product quantity update must commit in one database transaction.
- INV-003: Archived products must remain readable in movement history.
- INV-004: All stock movements must include `productId`, `type`, `quantity`, `previousQuantity`, `newQuantity`, `reason`, and `createdAt`.
- INV-005: Barcode is nullable and unique when present.
- INV-006: Stock movement is the source of truth for quantity changes after product creation.
- INV-007: User-facing errors must be translated from domain failures into plain language.

### Stock Movement Reasons

Stock Out must not be treated as one generic "bawas" action. The architecture should support a reason enum:

- `sold`
- `damaged`
- `lost`
- `personal_use`
- `correction`

This preserves audit value without adding full accounting complexity.

### Performance And Data Rules

- Product list should use lazy rendering.
- Search should be debounced.
- Product search should be indexed by name, future barcode, and possibly category.
- No blocking database calls should run on the UI thread.
- Dashboard summaries should avoid heavy recomputation on every rebuild.
- 3,000 products is the upper local performance target, while common users may have 50-500 products.

### Test And Migration Gates

- Unit tests required for stock in, stock out, validation, and low-stock calculation.
- Repository tests required for transaction rollback.
- Widget tests required for add/edit product and insufficient stock out.
- Every Drift schema change requires a migration test.

### Cross-Cutting Concerns Identified

- Offline-first data access.
- Atomic stock movement.
- Human-readable stock movement reasons.
- Local search and filtering performance.
- Low-end Android responsiveness.
- Validation and user-friendly error handling.
- Future cloud-sync compatibility.
- Barcode-ready data model without barcode scanning UX in MVP.
- Accessibility: readable typography, 48dp tap targets, non-color-only warnings.
- Monetization boundaries that protect core workflows.
- Data-loss risk due to local-only storage; backup/export must remain explicit in architecture planning.

## Starter Template Evaluation

### Primary Technology Domain

Android-first Flutter mobile application based on the PRD, UX specs, and offline-first architecture requirements.

### Starter Options Considered

**Option 1: Flutter official `flutter create --empty`**
Selected. Provides a minimal Flutter app foundation without forcing Bloc, Firebase, cloud services, or a heavy opinionated structure. This lets us build the accepted Clean Architecture, Riverpod, Drift, and feature-first folder structure intentionally.

**Option 2: Flutter official standard app template**
Rejected. Good for basic bootstrapping, but includes sample counter app code that we would immediately remove. `--empty` is cleaner.

**Option 3: Very Good CLI Flutter starter**
Rejected for this project. It is strong and production-minded, with flavors, linting, CI, testing posture, and scalable structure. However, its default app template is Bloc-oriented, while this project has selected Riverpod. We can borrow its discipline later without adopting its architecture.

**Option 4: Custom starter**
Rejected. A custom starter would only make sense if we already had a maintained internal Flutter template. Creating one now adds setup and maintenance work before product value.

### Selected Starter: Flutter Official Empty App

**Rationale for Selection:**
Use the official Flutter empty starter so the project begins cleanly and matches our architecture decisions instead of adapting around an unrelated starter. The product risk is not lack of template polish; the product risk is delaying the first trustworthy inventory loop.

The starter should support this path:

```text
Flutter empty starter
-> Add chosen dependencies
-> Create feature-first folder structure
-> Add linting and tests
-> Add Drift/Riverpod patterns
-> Build first vertical slice
```

The first vertical slice should be:

```text
Product model + local DB + repository + provider + product list/add product UI
```

**Initialization Command:**

```bash
flutter create --empty --platforms android --org com.rkuhonta tindatrack
```

**Architectural Decisions Provided by Starter:**

**Language & Runtime:**
Dart + Flutter Android app.

**Styling Solution:**
Flutter Material foundation. App-specific Material 3 theme will be built from `DESIGN.md`.

**Build Tooling:**
Flutter SDK build pipeline for Android.

**Testing Framework:**
Flutter test support will be extended with unit, repository, widget, and migration tests.

**Code Organization:**
Starter provides the base app shell only. We will add feature-first Clean Architecture folders manually:

- `lib/app`
- `lib/core`
- `lib/features/products`
- `lib/features/stock`
- `lib/features/dashboard`
- `lib/features/history`
- `lib/features/settings`

**Development Experience:**
Immediately after project creation, add:

- Riverpod
- Drift
- go_router
- very_good_analysis or strict Flutter lint rules
- build_runner
- mocktail
- SQLite native libs
- test harness

**Starter Guardrails:**

- No direct DB access from widgets.
- Drift DAOs stay in data layer.
- Riverpod providers stay near feature presentation/application boundaries.
- Stock movement only through a transaction use case/service.
- Shared domain errors translate into friendly UI messages.
- First implementation story must add dependencies, linting, folder structure, database scaffold, and test harness before feature screens expand.

**Note:**
Project initialization using this command should be the first implementation story.

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**
- Use Drift over SQLite as the authoritative local database, with schema migrations and repository tests.
- Model stock movement as the source of truth after product creation.
- Enforce non-negative inventory and atomic stock movement transactions in the data/domain boundary.
- Keep MVP local-only with no required login, no cloud dependency, and no fake authentication flow.
- Use Riverpod for application state and go_router for explicit app navigation.

**Important Decisions (Shape Architecture):**
- Use feature-first Clean Architecture folders with presentation, domain, and data layers per feature.
- Archive products instead of deleting them, while preserving movement history.
- Add nullable unique barcode field now, but expose no scanner UI in MVP.
- Use friendly domain failure translation for all user-facing errors.
- Keep infrastructure Android-first, simple, and local build/release oriented.

**Deferred Decisions (Post-MVP):**
- Cloud sync, login, staff roles, multi-device usage, supplier management, POS, barcode scanning UI, and server APIs are deferred.
- Database encryption is deferred unless a future requirement introduces sensitive credentials, cloud tokens, or paid account data.
- Remote monitoring/crash reporting is deferred or optional because MVP must work without internet and should not depend on cloud services.

### Data Architecture

**Decision:** Drift over SQLite remains the local persistence layer.

**Verified Version Context:** Drift latest verified version is `2.33.0`; Flutter latest stable verified version is `3.44.0` with Dart `3.12.0`.

**Rationale:** For this app, inventory data is relational: products, stock movements, dashboard summaries, history filters, future barcode lookup, and future sync metadata. Drift gives type-safe queries, migrations, transactions, joins, reactive streams, and testable DAOs. Sakto siya sa sari-sari store use case kasi kailangan reliable kahit offline at kahit biglang ma-close ang app.

**Data Modeling Approach:**
- `products` table:
  - `id`
  - `name`
  - `category`
  - `unit`
  - `price`
  - `quantity`
  - `lowStockThreshold`
  - `barcode` nullable
  - `isArchived`
  - `createdAt`
  - `updatedAt`
- `stock_movements` table:
  - `id`
  - `productId`
  - `type`
  - `quantity`
  - `previousQuantity`
  - `newQuantity`
  - `reason`
  - `note`
  - `createdAt`
- `settings` table or local key-value storage for simple app preferences.

**Validation Strategy:**
- Domain layer validates business rules before persistence.
- Database constraints protect invariants as a second guard.
- Product quantity, stock movement quantity, and thresholds must never be negative.
- Stock Out must reject quantities greater than current product stock.
- Barcode is nullable but unique when present.
- User-facing errors must be translated from domain failures into plain Taglish-friendly messages.

**Migration Approach:**
- Every Drift schema change requires a migration.
- Every migration requires a migration test.
- Future sync fields may be added later without changing current UX, for example `syncStatus`, `remoteId`, or `lastSyncedAt`.

**Caching Strategy:**
- No separate cache for MVP.
- Drift reactive queries serve as the local source and UI update trigger.
- Dashboard summaries should use focused aggregate queries, not full table scans on every rebuild.
- Search should be debounced and backed by indexes on `name`, `category`, and future `barcode`.

**Affects:** Products, Stock In/Out, Dashboard, History, Settings, future backup/sync.

### Authentication & Security

**Decision:** MVP has no required authentication and no fake login screen.

**Rationale:** The core promise is mabilis, offline, and usable agad. Login would add friction and imply cloud features that are not part of MVP. For sari-sari users, "bukas app, tingin stock, record galaw" is more important than account setup.

**Authentication Method:**
- None for MVP.
- App opens directly to the main inventory experience.
- Future authentication can be added for cloud backup/sync, but must not block local-only usage.

**Authorization Pattern:**
- No roles or permissions in MVP.
- Future staff roles can be introduced when multi-user/cloud sync exists.

**Security Middleware:**
- Not applicable because there is no backend API in MVP.

**Local Data Protection:**
- Do not log product lists, stock history, prices, or user-entered notes.
- Do not expose raw database errors directly to users.
- Use plain-language error mapping at the presentation boundary.
- `flutter_secure_storage` latest verified version is `10.3.1`; reserve it for future secrets such as cloud tokens, not normal inventory records.

**Encryption Decision:**
- Do not encrypt the whole local database in MVP unless a later requirement explicitly needs it.
- Rationale: full database encryption adds operational and recovery complexity. MVP data is local business inventory, not account credentials.
- Revisit encryption when cloud login, paid accounts, or sensitive personal data are introduced.

**API Security Strategy:**
- Deferred because MVP has no remote API.

**Affects:** App launch, settings, future backup, future sync, error handling, logging policy.

### API & Communication Patterns

**Decision:** MVP has no remote API. Internal communication uses repository contracts and use cases.

**Rationale:** Offline-first means local database operations are the app's main communication path. The important "API" ngayon is not HTTP; it is the boundary between UI, domain use cases, repositories, and Drift DAOs.

**Internal API Pattern:**
- Presentation calls Riverpod providers/controllers.
- Providers call use cases or application services.
- Use cases call repository interfaces.
- Repository implementations call Drift DAOs.
- Widgets must not access Drift directly.

**Error Handling Standard:**
- Data/database exceptions map to domain failures.
- Domain failures map to user-facing messages.
- Examples:
  - `InsufficientStockFailure` -> "Kulang ang stock para sa bawas na ito."
  - `DuplicateBarcodeFailure` -> "May produkto na gamit ang barcode na ito."
  - `ArchivedProductFailure` -> "Naka-hide ang produktong ito. Ibalik muna bago galawin ang stock."

**Communication Between Services:**
- No background service or sync worker in MVP.
- No event bus.
- Use explicit use cases for stock movement and product changes.
- Dashboard and history read from Drift streams/queries.

**API Documentation Approach:**
- No OpenAPI needed for MVP.
- Document repository contracts, domain failures, and invariants in code comments/tests and architecture docs.
- Future backend sync API should be documented separately when introduced.

**Rate Limiting Strategy:**
- Not applicable for MVP local-only use.
- Local UI should debounce product search to avoid excessive queries during typing.

**Affects:** Products, stock movement, history, dashboard, future sync design.

### Frontend Architecture

**Decision:** Flutter Material 3 app using Riverpod, go_router, and feature-first Clean Architecture.

**Verified Version Context:** Riverpod latest verified version is `3.2.1`; go_router latest verified version is `17.2.3`.

**Rationale:** Riverpod keeps state explicit, testable, and feature-local. go_router gives predictable navigation without inventing custom route plumbing. Flutter Material 3 matches the mobile-first UX spec and keeps Android implementation straightforward.

**State Management Approach:**
- Use Riverpod providers per feature.
- Async UI state should use `AsyncValue` or feature-specific state objects.
- Keep business rules out of widgets.
- Controllers/providers coordinate user actions, but domain rules stay in use cases/services.

**Component Architecture:**
- Feature-first folders:
  - `features/products`
  - `features/stock`
  - `features/dashboard`
  - `features/history`
  - `features/settings`
- Shared UI components live in `core/widgets`.
- App shell, routing, and theme live in `app`.

**Routing Strategy:**
- Use go_router for named routes.
- Main routes:
  - Dashboard
  - Product List
  - Add Product
  - Edit Product
  - Product Detail
  - Stock In
  - Stock Out
  - History
  - Settings
- No login route in MVP.
- No barcode scanner route in MVP.

**Performance Optimization:**
- Lazy product list rendering.
- Debounced search.
- Indexed local search fields.
- Avoid heavy dashboard recomputation on every rebuild.
- Database work must not block the UI thread.
- Keep animations lightweight for low-end Android devices.

**Bundle Optimization:**
- Android-only MVP build target.
- Avoid large packages unless needed for core workflow.
- Do not include barcode scanner, cloud auth SDKs, POS printer SDKs, or analytics SDKs in MVP unless their feature is actually implemented.

**Affects:** All screens, navigation, testability, low-end Android performance.

### Infrastructure & Deployment

**Decision:** Android-first local Flutter project with simple release pipeline and no backend infrastructure for MVP.

**Rationale:** The MVP's value is trustworthy local inventory tracking. Backend infrastructure now would create cost and complexity before cloud features exist. Mas practical muna: stable Android app, reliable local DB, tested stock flow.

**Hosting Strategy:**
- No app backend hosting in MVP.
- No cloud database in MVP.
- Future sync/backup can introduce backend architecture later.

**CI/CD Pipeline Approach:**
- Use Flutter analyze/test/build checks before release.
- Required quality gates:
  - Dart/Flutter analysis
  - Unit tests for stock in/out, validation, and low-stock logic
  - Repository transaction rollback tests
  - Widget tests for add/edit product and insufficient stock out
  - Drift migration tests
  - Android debug/release build validation

**Environment Configuration:**
- MVP needs minimal environment configuration.
- Use Dart defines only when future features require build-time values.
- No secrets should be committed.
- No API keys required for MVP.

**Monitoring And Logging:**
- Local debug logging only during development.
- No sensitive inventory data in logs.
- Crash reporting is optional/deferred; if added later, it must not block offline use and must respect user privacy.

**Scaling Strategy:**
- Local scale target: 50 to 3,000 products.
- SQLite indexes support search and history queries.
- Future sync scale should be designed later around UUID/ULID IDs and movement history.

**Affects:** Project setup, test gates, Android release, future cloud sync.

### Decision Impact Analysis

**Implementation Sequence:**
1. Create Flutter empty Android project with selected org/app name.
2. Add linting, Riverpod, Drift, go_router, test dependencies, and app folder structure.
3. Define Drift schema for products, stock movements, and settings.
4. Add migrations and migration test harness.
5. Implement domain entities, failures, validators, and repository contracts.
6. Implement product repository and stock movement transaction use case.
7. Build first vertical slice: product list, add product, local persistence.
8. Add stock in/out flows with atomic transaction tests.
9. Add dashboard summaries and history views.
10. Add settings and backup/export placeholder.

**Cross-Component Dependencies:**
- Stock In/Out depends on product schema, movement schema, domain failures, and transaction support.
- Dashboard depends on product and movement queries.
- History depends on archived products remaining readable.
- Search depends on product indexes and debounced UI input.
- Future barcode scanning depends on the nullable unique `barcode` field already existing.
- Future cloud sync depends on stable UUID/ULID identifiers and source-of-truth movement history.

## Implementation Patterns & Consistency Rules

### Pattern Categories Defined

**Critical Conflict Points Identified:**
- Database naming and enum storage
- Stock movement transaction boundaries
- Archive behavior
- ID and timestamp generation
- Repository failure return style
- Riverpod provider/controller ownership
- Feature folder and test placement
- Loading, empty, success, and error UI behavior
- Future barcode/sync placeholders without premature MVP UI

### Non-Negotiable Consistency Rules

All implementation agents MUST follow these rules:

1. Stock quantity changes after product creation MUST go through a stock movement use case/service.
2. Stock In/Out MUST insert a `stock_movements` row and update `products.quantity` inside the same Drift transaction.
3. UI, controllers, and generic product update methods MUST NOT update product quantity directly.
4. Product quantity MUST never become negative.
5. Products MUST be archived, not hard-deleted.
6. Archived products MUST remain readable in movement history.
7. Archived products MUST be hidden from active product lists/search by default.
8. Archived products MUST NOT receive new stock movements unless restored first.
9. Barcode MUST remain nullable and unique when present, including archived products.
10. Repositories MUST return typed failures, not raw Drift/SQLite exceptions.
11. UI MUST map failures into plain, action-oriented user messages.
12. Drift schema changes MUST include a version bump, migration, migration test, and data preservation check.

### Naming Patterns

**Database Naming Conventions:**
Use `snake_case` for database tables, columns, indexes, and stored enum values.

Examples:
- Tables: `products`, `stock_movements`, `app_settings`
- Columns: `product_id`, `low_stock_threshold`, `previous_quantity`, `new_quantity`, `archived_at`, `created_at`
- Indexes: `idx_products_name`, `idx_products_category`, `idx_products_barcode`, `idx_stock_movements_product_id`
- Foreign keys: `{referenced_table_singular}_id`, for example `product_id`

Drift table classes use PascalCase:
- `Products`
- `StockMovements`
- `AppSettings`

**Code Naming Conventions:**
Use Dart standard naming:
- Classes: `ProductRepository`, `RecordStockOutUseCase`, `StockMovementRepository`
- Files: `snake_case.dart`
- Variables/functions: `camelCase`
- Providers: `lowerCamelCaseProvider`

Examples:
- `product_repository.dart`
- `product_repository_impl.dart`
- `record_stock_in.dart`
- `record_stock_out.dart`
- `product_list_screen.dart`
- `product_detail_screen.dart`

Use `stock_movements` for inventory history records. Avoid generic `transactions` naming because it conflicts with database transaction language.

**Provider Naming Conventions:**
Examples:
- `productRepositoryProvider`
- `watchProductsProvider`
- `productDetailProvider`
- `productFormControllerProvider`
- `recordStockInControllerProvider`
- `recordStockOutControllerProvider`

Avoid mixing `service`, `manager`, `notifier`, and `controller` unless the role is explicitly different.

### Structure Patterns

**Project Organization:**
Use feature-first Clean Architecture:

```text
lib/
  app/
  core/
  features/
    dashboard/
    products/
    stock/
    history/
    settings/
```

Feature folders MUST follow:

```text
feature_name/
  data/
    datasources/
    models/
    repositories/
  domain/
    entities/
    failures/
    repositories/
    usecases/
  presentation/
    controllers/
    providers/
    screens/
    widgets/
```

Shared code belongs in `core` only when used by two or more features.

**Database Structure:**
```text
lib/core/database/
  app_database.dart
  tables/
    products_table.dart
    stock_movements_table.dart
    app_settings_table.dart
  daos/
    products_dao.dart
    stock_movements_dao.dart
```

Allowed dependency direction:

```text
presentation -> domain -> data -> core database
```

Disallowed:

```text
screen -> dao
screen -> database
provider -> database table directly
```

**Test Organization:**
Tests MUST mirror `lib/` under `test/`.

```text
test/
  core/
    database/
      app_database_migration_test.dart
  features/
    products/
      domain/
      data/
      presentation/
    stock/
      domain/
      data/
      presentation/
```

Repository tests MUST use an in-memory Drift database.

Required tests:
- `stock_in_creates_movement_and_increments_quantity`
- `stock_out_creates_movement_and_decrements_quantity`
- `stock_out_fails_when_insufficient_quantity`
- transaction rollback when movement insert or product update fails
- archived product visibility rules
- nullable barcode behavior and unique barcode enforcement
- enum mapper stability
- every Drift migration

### Format Patterns

**ID Format:**
Use ULID string IDs project-wide.

Rationale: ULIDs are client-generated, future-sync friendly, and naturally sortable for local records.

Rules:
- Do not use auto-increment integer IDs for products or stock movements.
- Generate IDs before insertion.
- Use the same ID format across products, stock movements, and future sync metadata.

**Timestamp Format:**
Store timestamps in UTC. Convert to local time only at presentation boundaries.

Rules:
- Domain/data code MUST NOT call `DateTime.now()` directly.
- Use an injectable `Clock` or `DateTimeProvider`.
- Do not base business logic on formatted display dates.
- Suggested timestamp fields: `created_at`, `updated_at`, `archived_at`, `occurred_at`.

**Enum Storage:**
Store enum values as stable lowercase strings.

Examples:
- Stock movement type: `stock_in`, `stock_out`
- Stock out reasons: `sold`, `damaged`, `lost`, `personal_use`, `correction`

Rules:
- DB enum strings are stable and append-only.
- Do not rename stored enum values casually.
- Add mapper tests when enum mappings are introduced or changed.
- Do not store user-facing labels in the database.

### Communication Patterns

**State Management Patterns:**
Use Riverpod consistently.

Rules:
- Read-only list/detail data uses providers exposing `AsyncValue`.
- User actions use controller classes.
- Controllers own screen workflow state, including saving/loading/error state.
- Repositories are stateless data access.
- Drift database provider is an app-level singleton.
- Widgets must not contain business rules.

**Repository Pattern:**
Domain repositories define contracts. Data repositories implement contracts and call Drift DAOs.

Repositories MUST return typed failures or typed result objects. They MUST NOT leak raw database exceptions to presentation.

Example:

```dart
abstract class ProductRepository {
  Future<Result<Product, AppFailure>> addProduct(AddProductInput input);
  Stream<List<Product>> watchActiveProducts(ProductFilter filter);
  Future<Result<Product?, AppFailure>> getProductById(String id);
  Future<Result<void, AppFailure>> archiveProduct(String id);
}
```

Stock quantity changes MUST go through stock movement use cases/services, not generic product update methods.

### Process Patterns

**Error Handling Patterns:**
Use this flow:

```text
Database exception -> data failure -> domain failure -> UI message
```

Example failures:
- `InsufficientStockFailure`
- `DuplicateBarcodeFailure`
- `ProductNotFoundFailure`
- `ArchivedProductFailure`
- `InvalidQuantityFailure`
- `DatabaseWriteFailure`

UI message pattern:
```text
What happened + why + what to do next
```

Examples:
- "Only 3 left. You can't remove 5."
- "Kulang ang stock para sa bawas na ito. Check quantity and try again."
- "May produkto na gamit ang barcode na ito."
- "Hindi ma-save ngayon. Subukan ulit."

Do not expose:
- raw SQL errors
- stack traces
- Drift exception text
- technical enum names

**Loading State Patterns:**
Use consistent states:
- loading
- content
- empty
- error

Shared widgets:
- `AppLoadingView`
- `AppEmptyState`
- `AppErrorView`

Rules:
- Page-opening loads MAY use full-screen loading.
- Local save/confirm actions SHOULD use button-level loading.
- Save/confirm buttons MUST prevent double tap while saving.
- Stock In/Out MUST NOT update UI optimistically before the database transaction succeeds.

**Success Feedback Patterns:**
Stock In/Out should show confirmation after commit.

Examples:
- "Stock added: Coke 1.5L is now 12."
- "Stock removed: Lucky Me Beef is now 3."

**Empty State Patterns:**
Empty states MUST say what is empty and what the user can do next.

Examples:
- "No products yet. Add your first item to start tracking stock."
- "No stock movement yet. Stock changes will appear here."
- "No archived products."

**Archive Copy Rules:**
Use "Archive" or "Archived," not "Delete," for product removal from active inventory.

Suggested explanation:
"Archived products no longer appear in active inventory, but stay visible in history."

### Query And List Patterns

Default query behavior:
- Active product list excludes archived products.
- Active products sort by name ascending.
- Movement history sorts newest first.
- Search is case-insensitive.
- Archived products appear only when explicitly requested.
- Dashboard summary queries should use aggregate queries, not full-list recomputation.

### Do / Don't Table

| Do | Don't |
| --- | --- |
| Use stock movement use cases for quantity changes | Update product quantity directly from UI/controllers |
| Insert movement and update quantity in one transaction | Save stock history and product quantity separately |
| Archive products with `archived_at` | Hard-delete products |
| Store enum values as stable lowercase strings | Store user-facing enum labels in DB |
| Store timestamps in UTC | Mix local display dates into domain logic |
| Use injectable time source | Call `DateTime.now()` in domain/data code |
| Return typed failures from repositories | Show raw Drift/SQLite exceptions |
| Mirror tests under `test/features/...` | Put feature tests in unrelated folders |
| Keep barcode nullable and unique | Add scanner UI or scanner dependencies in MVP |

### Enforcement Guidelines

All AI agents MUST:
- Follow the dependency direction `presentation -> domain -> data -> core database`.
- Add/update tests when touching stock rules, transactions, migrations, archive behavior, barcode uniqueness, or enum mappings.
- Keep widgets free of direct database access.
- Keep user-facing messages plain and action-oriented.
- Update this architecture document before introducing a new pattern that conflicts with these rules.

Pattern enforcement uses:
- Flutter analyzer
- Unit tests
- Repository tests
- Widget tests
- Migration tests
- Code review against this architecture document

### Agent Review Checklist

Before finishing implementation work, agents must check:

- Does this preserve non-negative stock?
- Is product quantity changed only through stock movements?
- Are required stock writes transactional?
- Are archived products still readable in history?
- Are archived products excluded from active lists by default?
- Are barcode rules preserved?
- Are timestamps stored in UTC and generated through an injectable time source?
- Are failures typed before reaching UI?
- Are user-facing errors plain and helpful?
- Do tests mirror the `lib/` structure?
- Are naming conventions consistent across DB, Dart, routes, and tests?

## Project Structure & Boundaries

### Complete Project Directory Structure

```text
tindatrack/
├── README.md
├── pubspec.yaml
├── analysis_options.yaml
├── build.yaml
├── .gitignore
├── android/
├── assets/
│   ├── icons/
│   └── images/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   ├── bootstrap.dart
│   │   ├── providers.dart
│   │   ├── router/
│   │   │   ├── app_router.dart
│   │   │   └── app_routes.dart
│   │   ├── navigation/
│   │   │   └── app_shell.dart
│   │   └── theme/
│   │       ├── app_theme.dart
│   │       ├── app_colors.dart
│   │       ├── app_spacing.dart
│   │       └── app_typography.dart
│   ├── core/
│   │   ├── database/
│   │   │   ├── app_database.dart
│   │   │   ├── converters/
│   │   │   │   └── date_time_converter.dart
│   │   │   ├── daos/
│   │   │   │   ├── products_dao.dart
│   │   │   │   ├── stock_movements_dao.dart
│   │   │   │   └── settings_dao.dart
│   │   │   └── tables/
│   │   │       ├── products_table.dart
│   │   │       ├── stock_movements_table.dart
│   │   │       └── app_settings_table.dart
│   │   ├── errors/
│   │   │   ├── app_failure.dart
│   │   │   ├── repository_failure.dart
│   │   │   └── failure_message_mapper.dart
│   │   ├── formatters/
│   │   │   ├── currency_formatter.dart
│   │   │   └── date_formatter.dart
│   │   ├── id/
│   │   │   ├── id_generator.dart
│   │   │   └── ulid_generator.dart
│   │   ├── time/
│   │   │   └── clock.dart
│   │   ├── ui/
│   │   │   ├── app_dimensions.dart
│   │   │   └── app_breakpoints.dart
│   │   ├── validation/
│   │   │   └── validators.dart
│   │   └── widgets/
│   │       ├── app_empty_state.dart
│   │       ├── app_error_view.dart
│   │       ├── app_loading_view.dart
│   │       ├── button_loading.dart
│   │       ├── confirm_dialog.dart
│   │       └── primary_button.dart
│   └── features/
│       ├── dashboard/
│       │   ├── data/
│       │   │   └── repositories/
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   ├── repositories/
│       │   │   └── usecases/
│       │   └── presentation/
│       │       ├── providers/
│       │       ├── screens/
│       │       │   └── dashboard_screen.dart
│       │       └── widgets/
│       ├── products/
│       │   ├── data/
│       │   │   ├── models/
│       │   │   └── repositories/
│       │   │       └── drift_products_repository.dart
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   ├── repositories/
│       │   │   │   └── products_repository.dart
│       │   │   └── usecases/
│       │   │       ├── add_product.dart
│       │   │       ├── update_product.dart
│       │   │       ├── archive_product.dart
│       │   │       └── watch_active_products.dart
│       │   └── presentation/
│       │       ├── controllers/
│       │       ├── providers/
│       │       ├── screens/
│       │       │   ├── product_list_screen.dart
│       │       │   ├── product_form_screen.dart
│       │       │   └── product_detail_screen.dart
│       │       └── widgets/
│       │           ├── archive_status_chip.dart
│       │           ├── low_stock_indicator.dart
│       │           ├── product_card.dart
│       │           └── stock_badge.dart
│       ├── stock/
│       │   ├── data/
│       │   │   ├── models/
│       │   │   └── repositories/
│       │   │       └── drift_stock_repository.dart
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   ├── repositories/
│       │   │   │   └── stock_repository.dart
│       │   │   └── usecases/
│       │   │       ├── adjust_stock.dart
│       │   │       ├── record_stock_in.dart
│       │   │       └── record_stock_out.dart
│       │   └── presentation/
│       │       ├── controllers/
│       │       ├── providers/
│       │       ├── screens/
│       │       │   └── stock_adjust_screen.dart
│       │       └── widgets/
│       ├── history/
│       │   ├── data/
│       │   │   └── repositories/
│       │   │       └── drift_history_repository.dart
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   ├── repositories/
│       │   │   │   └── history_repository.dart
│       │   │   └── usecases/
│       │   │       └── watch_stock_movements.dart
│       │   └── presentation/
│       │       ├── providers/
│       │       ├── screens/
│       │       │   └── movement_history_screen.dart
│       │       └── widgets/
│       └── settings/
│           ├── data/
│           │   └── repositories/
│           ├── domain/
│           │   ├── entities/
│           │   ├── repositories/
│           │   └── usecases/
│           └── presentation/
│               ├── providers/
│               ├── screens/
│               │   └── settings_screen.dart
│               └── widgets/
└── test/
    ├── core/
    │   ├── database/
    │   │   └── app_database_migration_test.dart
    │   ├── id/
    │   └── time/
    ├── features/
    │   ├── dashboard/
    │   ├── products/
    │   ├── stock/
    │   ├── history/
    │   └── settings/
    └── helpers/
        ├── fake_clock.dart
        ├── fake_id_generator.dart
        └── test_database.dart
```

### Architectural Boundaries

**Source Of Truth Boundary:**
`lib/core/database` owns Drift database wiring, tables, DAOs, converters, migrations, and persistence-level transaction support.

DAOs are persistence-only. They may run SQL/Drift queries, but they must not contain business rules or user-facing decisions.

Repositories translate DAO results into domain entities and typed failures.

**Dependency Direction:**
```text
presentation -> domain -> data -> core database
```

Rules:
- Features may depend on `core`.
- `core` must not depend on features.
- Features should not depend on each other directly.
- Widgets must not import DAOs or `AppDatabase`.
- Controllers must not run Drift queries directly.

**API Boundaries:**
MVP has no backend or remote API. The main internal API boundary is between domain repository contracts and data repository implementations.

**Component Boundaries:**
- Screens/widgets call Riverpod providers/controllers.
- Controllers call use cases.
- Use cases call repository contracts.
- Repository implementations call Drift DAOs.
- Domain entities do not depend on Drift generated classes.

**Service Boundaries:**
- Product creation/edit/archive lives in `features/products`.
- Quantity changes live in `features/stock`.
- Dashboard is read-only and must not mutate stock.
- History is read-only and must not mutate stock.
- Settings stores local preferences only.

**Data Boundaries:**
- `products` table stores product details, current quantity, archive status, and nullable barcode.
- `stock_movements` table stores inventory movement records and is the source of truth for stock changes after product creation.
- `app_settings` stores local MVP preferences only.
- Stock movement transactions are owned by the stock repository/use case path. Hindi puwedeng hiwalay ang movement insert and quantity update.

### Feature Responsibility Map

| Feature | Owns | Must Not Own |
| --- | --- | --- |
| `dashboard` | Read-only summaries, low-stock signals, recent activity display | Product mutation, stock mutation, settings logic |
| `products` | Product CRUD, archive/unarchive, barcode uniqueness handling, active product list/search | Direct stock quantity adjustment after creation |
| `stock` | Stock In, Stock Out, stock adjustment transactions, movement creation, stock confirmation feedback | Product form editing, history browsing ownership |
| `history` | Read-only stock movement browsing/filtering, archived product display in movement context | Stock mutation, product mutation |
| `settings` | Local preferences, app info, backup/export placeholder if real | Login, cloud sync, barcode scanner, POS, business rules |

### Requirements To Structure Mapping

**Dashboard**
- FR-001, FR-010
- Lives in `lib/features/dashboard`
- Reads product counts, low-stock count, and recent movements from repositories/providers.
- Must use aggregate queries where practical.

**Product CRUD And Archive**
- FR-002, FR-003, FR-004, FR-005
- Lives in `lib/features/products`
- Uses `products` table through repository contracts.
- Archive sets archive state/`archived_at`; no hard delete.
- Archived products are hidden from active product lists but visible in movement history as read-only references.

**Stock In / Stock Out**
- FR-006, FR-007, FR-008
- Lives in `lib/features/stock`
- Uses stock movement use cases.
- Owns transaction rule: insert movement + update quantity atomically.
- Owns stock success/failure feedback in presentation.

**Inventory History**
- FR-009
- Lives in `lib/features/history`
- Reads `stock_movements`, newest first.
- Must display archived products when referenced by movement history.

**Settings And Backup Placeholder**
- FR-012
- Lives in `lib/features/settings`
- MVP may show local settings and backup/export placeholder only if implemented honestly.
- No cloud login or sync implementation.

**Cross-Cutting Concerns**
- Database: `lib/core/database`
- Failures/messages: `lib/core/errors`
- Validation: `lib/core/validation`
- ULID generation: `lib/core/id`
- Injectable time: `lib/core/time`
- Shared UI states/components: `lib/core/widgets`
- Shared UI constants: `lib/core/ui`
- Theme/design tokens: `lib/app/theme`
- App composition/providers: `lib/app`

### MVP Exclusions Enforced By Structure

The MVP structure must not include:
- login/signup/account feature folders
- cloud sync feature folders
- POS/cart/checkout feature folders
- barcode scanner screen, route, service, or dependency
- remote API client layer
- supplier management feature
- accounting/profit reports feature

Future-ready fields may exist, such as nullable `barcode`, but future feature folders must not be added until the feature enters scope.

### Integration Points

**Internal Communication:**
```text
Screen
-> Riverpod controller/provider
-> Use case
-> Repository contract
-> Repository implementation
-> Drift DAO
-> SQLite
```

**External Integrations:**
MVP has no external integrations. No login provider, no cloud sync, no barcode scanner, no ads in save/confirm flows.

**Data Flow:**
- Product creation writes `products`.
- Stock In/Out writes `stock_movements` and updates `products.quantity` in one transaction.
- Dashboard reads aggregate inventory data.
- History reads stock movements.
- Product list reads active, non-archived products.
- Settings reads/writes local preferences only.

### UX Flow Boundaries

**Main Navigation:**
`lib/app/navigation/app_shell.dart` owns app-level navigation shell. Dashboard is a feature screen, not the owner of the whole app shell.

**Product Screens:**
- `product_list_screen.dart`: active product list/search
- `product_form_screen.dart`: add/edit product
- `product_detail_screen.dart`: product details and entry point to stock actions/archive

**Stock Screens:**
- `stock_adjust_screen.dart`: Stock In/Out form and confirmation state
- Stock presentation owns snackbars/messages like "Stock added" or "Only 3 left. You can't remove 5."

**History Screens:**
- `movement_history_screen.dart`: read-only movement log, newest first

**Settings Screens:**
- `settings_screen.dart`: local preferences and honest backup/export placeholder only

### File Organization Patterns

**Configuration Files:**
- `pubspec.yaml`: dependencies and assets
- `analysis_options.yaml`: linting rules
- `build.yaml`: Drift/build_runner configuration if needed
- `android/`: Android platform configuration only

**Source Organization:**
Feature code lives in `lib/features/{feature}`. Shared cross-feature code lives in `lib/core`. App shell, app-level providers, router, navigation shell, and theme live in `lib/app`.

**Test Organization:**
Tests mirror `lib/`.

Examples:
- `lib/features/products/domain/usecases/add_product.dart`
- `test/features/products/domain/usecases/add_product_test.dart`
- `lib/core/database/app_database.dart`
- `test/core/database/app_database_migration_test.dart`

Repository tests use an in-memory Drift database through `test/helpers/test_database.dart`.

Shared test helpers:
- `test/helpers/fake_clock.dart`
- `test/helpers/fake_id_generator.dart`
- `test/helpers/test_database.dart`

**Asset Organization:**
Static images/icons live under `assets/`. No scanner assets, login assets, or cloud-sync branding in MVP unless the feature exists.

### Development Workflow Integration

**Development Server Structure:**
Flutter mobile app development uses Flutter tooling, not a web dev server. Primary run target is Android emulator/device.

**Build Process Structure:**
Flutter builds Android artifacts from `lib/main.dart`, `pubspec.yaml`, generated Drift files, and `android/`.

**Deployment Structure:**
MVP deployment target is Android. No backend deployment is required.

### Structure Review Checklist

Before implementation work is accepted:
- Does the feature live in the correct `features/{feature}` folder?
- Does it preserve `presentation -> domain -> data -> core database`?
- Does `core` remain feature-independent?
- Are DAOs persistence-only?
- Are repositories translating data into domain entities and typed failures?
- Are stock changes routed through `features/stock`?
- Are history and dashboard read-only?
- Are MVP exclusions still absent from the tree?
- Do tests mirror the `lib/` path?
- Are test helpers used for clock, ID generation, and in-memory database setup?
