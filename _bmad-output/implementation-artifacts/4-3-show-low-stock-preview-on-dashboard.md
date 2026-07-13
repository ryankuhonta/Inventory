---
baseline_commit: 595de64
---

# Story 4.3: Show Low-Stock Preview On Dashboard

Status: done

## Story

As a store owner,
I want to preview low-stock products on the dashboard,
so that I know what may need restocking without opening the full list.

## Acceptance Criteria

1. Given low-stock or out-of-stock products exist, when the Dashboard loads, then it shows a preview of a small number of products needing attention and each preview item shows product name, quantity, unit, and status.
2. Given out-of-stock products are present in the preview, when low-stock products are also present, then Out of Stock is clearly labeled and it is not hidden behind a generic Low Stock label.
3. Given no products are low stock, when the Dashboard loads, then the low-stock preview area shows calm empty copy and it does not create unnecessary warning noise.

## Tasks / Subtasks

- [x] Task 1: Add a read-only dashboard low-stock preview model and repository stream (AC: 1-3)
  - [x] Add a dashboard domain entity for preview rows with product id, product name, quantity, unit, and `ProductStockStatus`.
  - [x] Extend `DashboardRepository` with a read-only stream for low-stock preview rows.
  - [x] Implement the Drift query in `DriftDashboardRepository`; include active products only, include quantity `0`, include positive quantities at or below threshold, and exclude archived products.
  - [x] Sort the preview so out-of-stock rows appear before low-stock rows, then by name for stable scanning.
  - [x] Limit the preview to a small fixed number, preferably 3, so the Dashboard remains compact.
  - [x] Do not add schema changes, generated Drift changes, product mutations, stock mutations, or navigation in this story.

- [x] Task 2: Add a Riverpod provider for the low-stock preview (AC: 1-3)
  - [x] Add `dashboardLowStockPreviewProvider` near the existing dashboard providers.
  - [x] Keep widgets consuming dashboard providers only; do not query Drift, DAOs, or products directly from widgets.
  - [x] Preserve the existing `dashboardSummaryProvider` local-midnight behavior; this story should not change the stock-changes-today timing logic.

- [x] Task 3: Render the low-stock preview section on the Dashboard (AC: 1-3)
  - [x] Keep the existing summary cards and first-product empty state behavior from Story 4.2.
  - [x] Add a section under the summary cards with visible title `Needs Restocking`.
  - [x] Render preview rows with product name, quantity plus unit, and a status label/badge.
  - [x] Reuse `ProductStockStatus` and the existing `StockBadge` presentation where practical so Out of Stock continues to override Low Stock.
  - [x] Use calm empty copy when the preview list is empty, for example `No products need restocking right now.`
  - [x] Do not add a tappable view-all action or product-list navigation; Story 4.4 owns dashboard-to-products navigation.

- [x] Task 4: Handle loading and error behavior without disrupting the summary cards (AC: 1-3)
  - [x] The preview may show a lightweight inline loading state while the summary cards remain visible.
  - [x] The preview error state must use friendly copy and must not show raw exception, SQL, Drift, stack trace, or database wording.
  - [x] The preview retry action, if present, should invalidate only the preview provider unless a broader dashboard retry is already visible.

- [x] Task 5: Add focused tests for Story 4.3 (AC: 1-3)
  - [x] Add repository tests proving preview rows include out-of-stock and low-stock active products, exclude archived products, exclude in-stock products, limit the result, and sort Out of Stock first.
  - [x] Add provider tests proving the preview provider uses the app database-backed dashboard repository.
  - [x] Add widget tests proving Dashboard renders the preview title, product names, quantities with units, and distinct Out of Stock versus Low Stock labels.
  - [x] Add widget tests proving the calm preview empty copy appears when no products need restocking.
  - [x] Add widget tests proving preview errors do not expose raw diagnostics.

- [x] Task 6: Verify Story 4.3 completion (AC: 1-3)
  - [x] Run Dart format for touched `lib` and `test` files.
  - [x] Run focused dashboard repository/provider/screen tests.
  - [x] Run `dart analyze`.
  - [x] Run the full Flutter test suite if focused tests and analyzer pass.
  - [x] Run `git diff --check`.

## Dev Notes

### Source Requirements

- Story 4.3 covers FR-002, FR-005, FR-021, FR-022, UX-DR9, and UX-DR13. [Source: `_bmad-output/planning-artifacts/epics.md#Story 4.3: Show Low-Stock Preview On Dashboard`]
- Dashboard must show `Inventory Today`, summary cards, low-stock preview, and recent activity preview; this story owns only the low-stock preview and not navigation or recent activity. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Dashboard`]
- Low-stock and out-of-stock states must be visible without opening product details, with Out of Stock visually overriding Low Stock. [Source: `_bmad-output/planning-artifacts/epics.md#UX Design Requirements`]
- Dashboard summaries and preview data should use focused queries and avoid heavy recomputation on rebuild. [Source: `_bmad-output/planning-artifacts/architecture.md#Performance And Data Rules`]
- User-facing errors must be friendly and must not expose raw database or exception details. [Source: `_bmad-output/planning-artifacts/architecture.md#API & Communication Patterns`]

### Current System State

- `tindatrack/lib/features/dashboard/presentation/screens/dashboard_screen.dart` already consumes `dashboardSummaryProvider`, renders `Inventory Today`, summary cards, loading, error/retry, and first-product empty state.
- `DashboardRepository` currently exposes only `watchSummary({required DateTime localNow})`.
- `DriftDashboardRepository` currently uses a focused custom aggregate query over `products` and `stock_movements`.
- `dashboardSummaryProvider` uses the app `Clock`, converts to local time, and invalidates itself after local midnight. Keep that behavior intact.
- Product stock status already exists in `tindatrack/lib/features/products/domain/entities/product_stock_status.dart`:
  - `inStock`
  - `lowStock`
  - `outOfStock`
  - `Product.stockStatus` classifies quantity `0` as out-of-stock before low-stock.
- `StockBadge` already exists in `tindatrack/lib/features/products/presentation/widgets/stock_badge.dart` and provides user-facing labels `Low Stock` and `Out of Stock`.
- Product list filtering already uses persistence predicates in `ProductsDao`, but Dashboard should use its own read-only dashboard repository method rather than making Dashboard widgets depend on product repository or DAO details.

### Architecture Compliance

- Keep Dashboard read-only. No product creation/edit/archive, stock in/out, stock movement insert, settings change, route change, schema change, or generated Drift update belongs in Story 4.3.
- Keep widgets presentation-only. Widgets consume dashboard providers and reusable domain/presentation types; they must not access Drift, DAOs, or raw database rows.
- Reuse `ProductStockStatus` and `StockBadge` to avoid duplicate low-stock/out-of-stock rules.
- Keep MVP exclusions out: no login, cloud sync, backup/export, scanner, POS, supplier, accounting, reporting, remote API client, or fake future-feature UI.
- Use existing packages only: Flutter Material, Riverpod, Drift-backed providers already in the project. No new dependencies are needed.
- Use simple English with Filipino-friendly phrasing; avoid technical UI words like database, exception, entity, mutation, query, or Drift.

### UX And Layout Guardrails

- Preserve the single-column Android mobile layout with 16dp outer padding and spacing from `AppSpacing`. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Layout & Spacing`]
- Keep the preview compact. It should not push the summary cards into a dense or cluttered layout.
- Use modest 8dp card/list item radius via `AppDimensions.componentRadius`; avoid nested cards, decorative gradients, heavy shadows, and floating panels. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Elevation & Depth`]
- Warnings must not rely on color alone. Preview rows need visible text labels for `Low Stock` and `Out of Stock`.
- Empty preview copy should be calm, not alarming, when no products need restocking.
- Preserve the app shell and bottom navigation; `DashboardScreen` owns only dashboard branch content.

### Suggested Implementation Shape

- Add:
  - `tindatrack/lib/features/dashboard/domain/entities/dashboard_low_stock_preview_item.dart`
- Update:
  - `tindatrack/lib/features/dashboard/domain/repositories/dashboard_repository.dart`
  - `tindatrack/lib/features/dashboard/data/repositories/drift_dashboard_repository.dart`
  - `tindatrack/lib/features/dashboard/presentation/providers/dashboard_providers.dart`
  - `tindatrack/lib/features/dashboard/presentation/screens/dashboard_screen.dart`
  - `tindatrack/test/features/dashboard/data/repositories/drift_dashboard_repository_test.dart`
  - `tindatrack/test/features/dashboard/presentation/providers/dashboard_providers_test.dart`
  - `tindatrack/test/features/dashboard/presentation/screens/dashboard_screen_test.dart`
- Suggested constants/keys:
  - `dashboardLowStockPreviewLimit = 3`
  - `Key('dashboard-low-stock-preview-section')`
  - `Key('dashboard-low-stock-preview-empty')`
  - `Key('dashboard-low-stock-preview-loading')`
  - `Key('dashboard-low-stock-preview-error')`
  - `Key('dashboard-low-stock-preview-item-$productId')`

### Testing Requirements

- Repository tests should use in-memory Drift like the existing dashboard repository tests.
- Test preview query with at least:
  - one out-of-stock active product
  - multiple low-stock active products
  - one in-stock active product
  - one archived low/out-of-stock product
- Assert preview rows are capped to 3 and ordered with out-of-stock before low-stock.
- Widget tests should override both `dashboardSummaryProvider` and `dashboardLowStockPreviewProvider`, or override `dashboardRepositoryProvider` with a deterministic fake that implements both repository methods.
- Keep tests deterministic and independent of wall-clock time.
- Run focused dashboard tests from a Windows temp copy if direct Flutter commands fail from the UNC workspace.

### Previous Story Intelligence

- Story 4.2 is complete and pushed at `595de64`. It replaced the Dashboard placeholder with a provider-backed screen and added the summary cards.
- Story 4.2 review fixed three useful dashboard edge cases:
  - low-stock card is neutral when count is `0`
  - summary cards show when stock changes exist even with `0` active products
  - summary card text guards overflow
- Do not regress the first-product empty state. If total active products, low-stock products, and stock changes today are all zero, Dashboard still shows the first-product guidance instead of summary cards plus preview empty copy.
- Story 4.1 added local-day summary handling and midnight refresh. This story should not weaken or duplicate that timing logic.
- Existing Product screen code demonstrates the expected stock status rule and badge presentation. Reuse those patterns.

### Git Intelligence

- `595de64 Finalize Story 4.2 review status`
- `aad3c4a Complete Story 4.2 dashboard summary screen`
- `1970740 Fix Story 4.1 dashboard review findings`
- `fc77aa6 Complete Story 4.1 dashboard summary queries`
- `b250a8f Complete Story 3.8 stock movement reliability tests`

Recent work keeps feature code under `lib/features/{feature}`, mirrors tests under `test/features/{feature}`, uses Riverpod provider overrides for deterministic widget tests, and verifies Flutter from a Windows temp copy when UNC workspace tooling blocks direct Flutter commands.

### Project Structure Notes

- This story should not implement Story 4.4 navigation to the filtered Products list, Story 4.5 recent activity preview, or Story 4.6 broad dashboard regression suite.
- If an action-looking affordance is tempting for the preview header, keep it non-interactive in this story. Story 4.4 owns the clear path from Dashboard to Products.
- If the repository method returns product IDs, they are for stable keys and future navigation only; do not wire navigation in Story 4.3.

## Dev Agent Record

### Agent Model Used

Codex GPT-5

### Debug Log References

- `flutter test test/features/dashboard` initially passed after implementation with 18 focused dashboard tests from `C:\tmp\tindatrack-story-4-3-verify`.
- `dart analyze` initially reported two test style issues in `drift_dashboard_repository_test.dart`; both were fixed.
- Full `flutter test` initially exposed missing dashboard preview overrides in app/widget test harnesses through hanging `pumpAndSettle` paths; harnesses were updated with deterministic empty preview streams.
- Final focused dashboard tests passed from `C:\tmp\tindatrack-story-4-3-full-20260713021104` with 18 tests.
- Final `dart analyze` passed with no issues from `C:\tmp\tindatrack-story-4-3-verify`.
- Final full `flutter test` passed from `C:\tmp\tindatrack-story-4-3-full-20260713021104` with 320 tests.
- Review fix verification passed from `C:\tmp\tindatrack-story-4-3-review-fix-20260713`:
  - `flutter test test/features/dashboard` passed with 22 tests.
  - `dart analyze` passed with no issues.
  - Full `flutter test` passed with 324 tests.
  - `git diff --check` passed.

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.
- Added a read-only Dashboard low-stock preview entity, repository method, Drift query, and Riverpod provider.
- Rendered a compact `Needs Restocking` Dashboard section below the summary cards, including preview rows, inline loading, friendly error/retry, and calm empty copy.
- Reused `ProductStockStatus` and `StockBadge` so Out of Stock remains distinct from Low Stock and warnings do not rely on color alone.
- Kept Dashboard read-only and left dashboard-to-products navigation for Story 4.4.
- Updated app/widget test harnesses to provide deterministic empty low-stock preview streams when Dashboard summary data is stubbed.

### File List

- `_bmad-output/implementation-artifacts/4-3-show-low-stock-preview-on-dashboard.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `tindatrack/lib/features/dashboard/domain/entities/dashboard_low_stock_preview_item.dart`
- `tindatrack/lib/features/dashboard/domain/repositories/dashboard_repository.dart`
- `tindatrack/lib/features/dashboard/data/repositories/drift_dashboard_repository.dart`
- `tindatrack/lib/features/dashboard/presentation/providers/dashboard_providers.dart`
- `tindatrack/lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- `tindatrack/test/app/launch_retry_regression_test.dart`
- `tindatrack/test/features/dashboard/data/repositories/drift_dashboard_repository_test.dart`
- `tindatrack/test/features/dashboard/presentation/providers/dashboard_providers_test.dart`
- `tindatrack/test/features/dashboard/presentation/screens/dashboard_screen_test.dart`
- `tindatrack/test/widget_test.dart`

### Change Log

- 2026-07-13: Created Story 4.3 implementation guide and marked it ready for development.
- 2026-07-13: Implemented Dashboard low-stock preview and marked Story 4.3 ready for review.
- 2026-07-13: Completed Story 4.3 review fixes and marked story done.
