---
baseline_commit: b250a8f
---

# Story 4.1: Create Dashboard Summary Queries

Status: done

## Story

As a store owner,
I want dashboard numbers to reflect my local inventory,
So that I can quickly understand store status.

## Acceptance Criteria

1. Given active and archived products exist, when the dashboard total products query runs, then it counts active products only, and archived products are excluded.
2. Given products have quantities and low-stock thresholds, when the low-stock count query runs, then it counts products where quantity is equal to or below the low-stock threshold, and out-of-stock products are included because they need attention.
3. Given stock movement records have UTC timestamps, when the Stock Changes Today query runs, then it computes today using the device or app local timezone day, and converts the local day start/end boundaries to UTC for the Drift query.
4. Given dashboard summaries are displayed, when the app rebuilds dashboard widgets, then summary values come from focused aggregate queries, and widgets do not recompute summaries by scanning full product or movement lists.

## Tasks / Subtasks

- [x] Task 1: Design the dashboard summary read model boundary (AC: 1-4)
  - [x] Add dashboard domain/data types under `tindatrack/lib/features/dashboard` rather than placing dashboard logic in product, stock, history, or widgets.
  - [x] Define a compact summary entity/model with total active products, low-stock products, and stock changes today.
  - [x] Keep the boundary read-only; do not add stock mutation, product mutation, or navigation behavior in this story.

- [x] Task 2: Implement focused Drift aggregate queries (AC: 1, 2, 4)
  - [x] Count active products with `products.is_archived == false` only.
  - [x] Count low-stock active products with the same rule used by Products low-stock filtering, but include out-of-stock products for dashboard attention: active rows where `quantity <= low_stock_threshold`.
  - [x] Use SQL aggregate/count queries; do not watch or scan full product lists in dashboard widgets.
  - [x] Prefer a dedicated dashboard DAO/repository/read service if that keeps persistence-only queries out of presentation.

- [x] Task 3: Implement Stock Changes Today query with local-day boundaries (AC: 3, 4)
  - [x] Accept or derive a local `DateTime` for "today" through an injectable clock or query input; do not call `DateTime.now()` directly inside widgets.
  - [x] Compute the local day start and exclusive next-day boundary, then convert both boundaries to UTC for persisted `stock_movements.created_at` comparisons.
  - [x] Count stock movement rows whose UTC `created_at` is `>= startUtc` and `< endUtc`.
  - [x] Preserve UTC storage and existing history ordering/index assumptions.

- [x] Task 4: Compose Riverpod providers for dashboard summaries (AC: 4)
  - [x] Add dashboard providers under `tindatrack/lib/features/dashboard/presentation/providers`.
  - [x] Reuse existing app/database/clock providers instead of creating separate database or time singletons.
  - [x] Expose summary state as a provider suitable for Story 4.2 UI consumption.
  - [x] Keep `DashboardScreen` placeholder UI changes minimal unless needed to wire provider tests; Story 4.2 owns summary cards.

- [x] Task 5: Add focused tests for dashboard summary behavior (AC: 1-4)
  - [x] Add repository/DAO/provider tests under `tindatrack/test/features/dashboard` mirroring the new `lib/features/dashboard` structure.
  - [x] Test active vs archived total count.
  - [x] Test low-stock count includes quantity below threshold, equal to threshold, and zero stock, while excluding archived rows and above-threshold rows.
  - [x] Test stock changes today across local timezone day boundaries using UTC persisted timestamps.
  - [x] Test provider composition uses the app database/clock and returns the expected summary without widget-side list scanning.

- [x] Task 6: Verify Story 4.1 completion (AC: 1-4)
  - [x] Run Dart format for touched `lib` and `test` files.
  - [x] Run focused dashboard tests.
  - [x] Run `dart analyze`.
  - [x] Run the full Flutter test suite if focused tests and analyzer pass.
  - [x] Run `git diff --check`.

### Review Findings

- [x] [Review][Patch] Local day end is not DST-safe [tindatrack/lib/features/dashboard/data/repositories/drift_dashboard_repository.dart:15]
- [x] [Review][Patch] Dashboard summary can stay on yesterday after local midnight [tindatrack/lib/features/dashboard/presentation/providers/dashboard_providers.dart:13]
- [x] [Review][Patch] Timezone-boundary test mirrors implementation instead of proving non-UTC local-day behavior [tindatrack/test/features/dashboard/data/repositories/drift_dashboard_repository_test.dart:81]
- [x] [Review][Patch] Story Change Log contains a literal backtick-n artifact [_bmad-output/implementation-artifacts/4-1-create-dashboard-summary-queries.md:150]
- [x] [Review][Patch] Dev Agent Record is empty despite story being in review [_bmad-output/implementation-artifacts/4-1-create-dashboard-summary-queries.md:135]

## Dev Notes

### Source Requirements

- Story 4.1 covers FR-001, FR-002, FR-003, FR-021, FR-022, NFR-003, and NFR-004. [Source: `_bmad-output/planning-artifacts/epics.md#Story 4.1: Create Dashboard Summary Queries`]
- Epic 4 requires dashboard summaries, low-stock count, stock changes today, recent activity, low-stock preview, empty dashboard guidance, and navigation to low-stock filtered products using efficient aggregate queries. [Source: `_bmad-output/planning-artifacts/epics.md#Epic 4: Dashboard And Low-Stock Awareness`]
- Dashboard summaries must use focused aggregate queries and avoid heavy recomputation on every rebuild. [Source: `_bmad-output/planning-artifacts/architecture.md#Performance And Data Rules`]
- Dashboard and history are read-only over inventory data. [Source: `_bmad-output/planning-artifacts/architecture.md#Additional Requirements`]
- UX expects Dashboard to show `Inventory Today`, summary cards for Total Products, Low Stock, and Stock Changes Today, plus previews in later stories. Story 4.1 should prepare the data boundary; Story 4.2 owns the visible summary cards. [Source: `_bmad-output/planning-artifacts/epics.md#Story 4.2: Build Dashboard Screen With Summary Cards`]

### Current System State

- `tindatrack/lib/features/dashboard/presentation/screens/dashboard_screen.dart` is still a placeholder with static text only.
- `ProductsDao.watchActiveProducts` already implements active product filtering and separates low-stock from out-of-stock for the Products screen. Dashboard low-stock count must intentionally include out-of-stock products because both need attention.
- `ProductsDao` and `StockMovementsDao` are persistence-only DAOs attached to `AppDatabase`; keep that pattern if adding dashboard-specific queries.
- `StockMovements` rows store UTC `createdAt` and already have `stock_movements_created_at_idx`, which supports today-count range queries.
- Existing providers compose DAOs from `databaseProvider`; reuse this pattern for dashboard providers.

### Architecture Compliance

- Keep Clean Architecture boundaries: widgets should consume dashboard providers/read models, not Drift rows or raw DAOs.
- Keep dashboard read-only. Do not mutate product quantity, stock movements, products, routes, or settings in Story 4.1.
- Use existing packages only: Flutter, Riverpod, Drift, go_router, test tooling already pinned in `tindatrack/pubspec.yaml`.
- Do not add new dependencies, generated schema changes, migrations, routes, scanner/POS/accounting/supplier/cloud/export/reporting scope, or dashboard UI cards beyond what the query/provider boundary needs.
- Database columns remain `snake_case`; Dart entities remain `camelCase`.

### Suggested Implementation Shape

- Possible new files:
  - `tindatrack/lib/features/dashboard/domain/entities/dashboard_summary.dart`
  - `tindatrack/lib/features/dashboard/domain/repositories/dashboard_repository.dart`
  - `tindatrack/lib/features/dashboard/data/repositories/drift_dashboard_repository.dart`
  - `tindatrack/lib/features/dashboard/presentation/providers/dashboard_providers.dart`
  - matching tests under `tindatrack/test/features/dashboard/...`
- If a dedicated DAO is added under `tindatrack/lib/core/database/daos`, update `AppDatabase` only if Drift generation requires DAO registration. Do not change schema version for read-only DAOs.
- A repository method such as `watchSummary({required DateTime localNow})` or `summaryFor(DateTime localNow)` is acceptable; prefer deterministic inputs for tests.
- For `Stock Changes Today`, use local day boundaries:
  - `localStart = DateTime(localNow.year, localNow.month, localNow.day)`
  - `localEnd = localStart.add(const Duration(days: 1))`
  - `startUtc = localStart.toUtc()`
  - `endUtc = localEnd.toUtc()`
  - query `createdAt >= startUtc && createdAt < endUtc`

### Files Expected To Change

- `tindatrack/lib/features/dashboard/**`
- `tindatrack/test/features/dashboard/**`
- Potentially `tindatrack/lib/core/database/daos/**` if aggregate queries are implemented as a persistence-only DAO.
- Potentially `tindatrack/lib/core/database/app_database.dart` and generated Drift files if a new DAO part/registration is required. Do not change schema version for read-only query code.
- `_bmad-output/implementation-artifacts/4-1-create-dashboard-summary-queries.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

### Testing Requirements

- Use `AppDatabase(NativeDatabase.memory())` for repository/DAO tests, matching existing database tests.
- Seed products with active, archived, zero-stock, below-threshold, equal-threshold, and above-threshold cases.
- Seed stock movements with UTC timestamps just inside and just outside the target local day.
- Include a timezone-boundary test that proves local-day conversion, not naive UTC calendar-day counting.
- Provider tests should use `ProviderContainer.test` and override `databaseProvider` and clock/time inputs as needed.
- Tests should not depend on wall-clock time or random IDs.

### Previous Story Intelligence

- Story 3.8 completed stock movement reliability coverage and fixed review findings. Product and movement persistence are now well-covered and can be trusted as dashboard sources.
- Story 3.8 verification passed focused repository tests, analyzer, full Flutter test suite, and `git diff --check` from a Windows temp copy because direct Flutter commands fail on the UNC workspace.
- Story 3.6 established read-only movement history over `StockRepository.watchMovementHistory`; dashboard recent activity previews in later stories should reuse that read-only posture.
- Story 3.7 kept row stock actions as navigation only and did not move stock mutation logic into product widgets. Maintain the same boundary discipline for dashboard.

### Latest Technical Notes

- No web research or dependency upgrade is needed for Story 4.1. Current pinned Flutter/Riverpod/Drift APIs already support aggregate queries, providers, and in-memory database tests.
- For Flutter verification from this UNC workspace, use the established temp-copy pattern under `C:\tmp` if direct Flutter/Dart commands fail.

### Project Structure Notes

- This story should create the data/query foundation for Epic 4. Avoid implementing Story 4.2 UI cards, Story 4.3 low-stock preview, Story 4.4 navigation, or Story 4.5 recent activity preview unless a tiny provider seam is needed for 4.1 tests.
- Keep dashboard summary naming specific; avoid generic analytics/reporting abstractions that imply post-MVP reporting scope.

## Dev Agent Record

### Agent Model Used

- Codex GPT-5

### Debug Log References

- Focused dashboard tests: `flutter test test/features/dashboard` passed from `C:\tmp\tindatrack-story-4-1-review-fixes` with 7 tests.
- Analyzer: `dart analyze` passed from `C:\tmp\tindatrack-story-4-1-review-fixes`.
- Full suite: `flutter test` passed from `C:\tmp\tindatrack-story-4-1-review-fixes` with 309 tests.
- Whitespace check: `git diff --check` passed.

### Completion Notes List

- Added a read-only dashboard summary boundary with focused aggregate counts over products and stock movements.
- Added Riverpod providers for Story 4.2 dashboard card consumption.
- Added repository and provider tests for active-product, low-stock, stock-change, table-watch, local-day, and provider composition behavior.
- Review fixes: made local day end DST-safe, refreshed dashboard summary after local midnight, strengthened local-day tests, and cleaned story metadata.

### File List

- `_bmad-output/implementation-artifacts/4-1-create-dashboard-summary-queries.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `tindatrack/lib/features/dashboard/data/repositories/drift_dashboard_repository.dart`
- `tindatrack/lib/features/dashboard/domain/entities/dashboard_summary.dart`
- `tindatrack/lib/features/dashboard/domain/repositories/dashboard_repository.dart`
- `tindatrack/lib/features/dashboard/presentation/providers/dashboard_providers.dart`
- `tindatrack/test/features/dashboard/data/repositories/drift_dashboard_repository_test.dart`
- `tindatrack/test/features/dashboard/presentation/providers/dashboard_providers_test.dart`

### Change Log

- 2026-07-11: Created Story 4.1 artifact and marked it ready for dev.
- 2026-07-11: Implemented dashboard summary queries/providers and marked Story 4.1 ready for review.
- 2026-07-12: Applied Story 4.1 code review fixes for local-day boundaries, midnight refresh, test coverage, and story metadata.