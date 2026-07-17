---
baseline_commit: 33083d4
---

# Story 4.5: Show Recent Activity Preview

Status: ready-for-dev

## Story

As a store owner or helper,
I want to see recent stock movements on the dashboard,
so that I can quickly verify what changed recently.

## Acceptance Criteria

1. Given stock movements exist, when the Dashboard loads, then it shows a recent activity preview with the latest movements and each item includes movement type, product name snapshot, changed quantity, and time.
2. Given a movement has an optional note, when it appears in the Dashboard preview, then the preview may show the note only if it fits the compact layout and the full note remains available in History.
3. Given no stock movements exist, when the Dashboard loads, then the recent activity area shows friendly empty copy and guides the user that stock movements will appear after Stock In or Stock Out.
4. Given the recent activity preview is interactive, when the user taps the preview or view-all action, then the app navigates to History and no movement data is modified.

## Tasks / Subtasks

- [ ] Task 1: Add a Dashboard recent activity read model (AC: 1-3)
  - [ ] Add a compact dashboard domain entity for recent activity rows, likely under `tindatrack/lib/features/dashboard/domain/entities/`.
  - [ ] Include movement id, movement type, product name snapshot, quantity, unit snapshot, optional note, and UTC created timestamp.
  - [ ] Keep this read-only; do not introduce product quantity changes, stock movement inserts, schema changes, or generated Drift changes for this story.
  - [ ] Use the same movement type semantics as `StockMovementType` so labels remain `Stock In` and `Stock Out`.

- [ ] Task 2: Extend the Dashboard repository/provider path (AC: 1-3)
  - [ ] Add a `dashboardRecentActivityPreviewLimit` constant, recommended value `3`, next to the existing dashboard preview limit constants.
  - [ ] Add `DashboardRepository.watchRecentActivityPreview({int limit = dashboardRecentActivityPreviewLimit})`.
  - [ ] Implement the Drift repository query against `stock_movements`, sorted newest first by `created_at DESC, id DESC`, limited to the compact preview size.
  - [ ] Clamp custom limits like the low-stock preview does so negative limits produce no rows and oversized limits stay capped.
  - [ ] Map persisted stock movement rows into the dashboard preview entity without exposing Drift rows to widgets.
  - [ ] Add `dashboardRecentActivityPreviewProvider` in `dashboard_providers.dart`.

- [ ] Task 3: Render recent activity on Dashboard (AC: 1-3)
  - [ ] Add a `Recent Activity` section below the existing `Needs Restocking` section.
  - [ ] Render compact rows with movement type, product name snapshot, signed changed quantity, and local display time.
  - [ ] Show optional note only as short, bounded preview text; do not let notes dominate or overflow the compact dashboard layout.
  - [ ] Add friendly empty copy such as `No stock movement yet.` plus guidance that Stock In and Stock Out records will appear there.
  - [ ] Add lightweight loading and friendly error states that do not hide summary cards or low-stock preview.
  - [ ] Keep Dashboard empty-first-product behavior unchanged: when total products, low stock, and stock changes today are all zero, the first-product empty state remains the only body content.

- [ ] Task 4: Add navigation to History (AC: 4)
  - [ ] Add a compact `View History` action or make the section header/action tappable with a clear 48dp tap target.
  - [ ] Navigate with `context.go(AppRoute.history.path)`.
  - [ ] Do not modify movement data, mark items read, add filters, or add a new route/query parameter contract.
  - [ ] Preserve bottom navigation behavior and existing History route semantics.

- [ ] Task 5: Add focused tests (AC: 1-4)
  - [ ] Add repository tests for recent activity preview ordering, limit clamping, field mapping, optional note mapping, and stream re-emission.
  - [ ] Add Dashboard widget tests for populated rows, empty copy, loading state, error copy, optional note bounded rendering, and first-product empty-state regression.
  - [ ] Add a navigation widget/router test proving `View History` opens the History branch/path and performs no stock mutation.
  - [ ] Include a small-screen/high-text-scale test or extend the existing Dashboard screen test so recent activity rows do not overflow.
  - [ ] Use provider overrides for widget tests where practical; use in-memory Drift repository tests for query behavior.

- [ ] Task 6: Verify Story 4.5 completion (AC: 1-4)
  - [ ] Run Dart format for touched `lib` and `test` files.
  - [ ] Run focused dashboard/repository/router tests touched by this story.
  - [ ] Run `dart analyze`.
  - [ ] Run the full Flutter test suite if focused tests and analyzer pass.
  - [ ] Run `git diff --check`.

## Dev Notes

### Source Requirements

- Story 4.5 covers FR-003, FR-034, FR-035, UX-DR9, and UX-DR22. [Source: `_bmad-output/planning-artifacts/epics.md#Story 4.5: Show Recent Activity Preview`]
- FR-003 requires the app to show recent inventory activity. [Source: `_bmad-output/planning-artifacts/epics.md#Functional Requirements`]
- FR-034 requires inventory transactions sorted newest first. [Source: `_bmad-output/planning-artifacts/epics.md#Functional Requirements`]
- FR-035 requires movement type, product, quantity, previous quantity, new quantity, and date/time in transaction displays; Dashboard preview may stay compact but must include the story-required subset. [Source: `_bmad-output/planning-artifacts/epics.md#Functional Requirements`]
- UX-DR9 requires Dashboard to include low-stock and recent activity previews. [Source: `_bmad-output/planning-artifacts/epics.md#UX Design Requirements`]
- UX-DR22 requires Inventory History rows to show newest transactions first with movement type, product name, changed quantity, previous quantity, new quantity, date/time, and note when present. [Source: `_bmad-output/planning-artifacts/epics.md#UX Design Requirements`]
- Dashboard navigation includes a path to History. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Information Architecture`]

### Current System State

- `DashboardScreen` already renders summary cards and a `Needs Restocking` section through `dashboardLowStockPreviewProvider`.
- `DashboardRepository` currently exposes `watchSummary` and `watchLowStockPreview`; Story 4.5 should extend this same read-only boundary.
- `DriftDashboardRepository` already uses focused `customSelect(...).watch()` queries and maps rows into dashboard-specific domain entities.
- `dashboardSummaryProvider` already refreshes stock-changes-today at the next local midnight. The recent activity preview itself can simply watch movement rows.
- `StockMovementsDao.watchMovements` and `StockRepository.watchMovementHistory` already sort movement history newest first. Dashboard may either add a focused limited query in `DriftDashboardRepository` or reuse a repository path only if it can stay compact and avoid scanning/rendering the full history.
- `MovementHistoryScreen` already formats labels as `Stock In` / `Stock Out`, signed quantities, local date/time, and note cards. Keep Dashboard copy consistent but more compact.
- `AppRoute.history.path` is `/history`; bottom navigation uses the four canonical routes from `AppRoute`.

### Architecture Compliance

- Dashboard is read-only and must not mutate stock. [Source: `_bmad-output/planning-artifacts/architecture.md#Service Boundaries`]
- History is read-only and owns movement browsing; Dashboard may preview recent movement data but must not become the full history feature. [Source: `_bmad-output/planning-artifacts/architecture.md#Feature Responsibility Map`]
- Widgets must not import DAOs or `AppDatabase`; screens/widgets call providers/controllers. [Source: `_bmad-output/planning-artifacts/architecture.md#Component Boundaries`]
- Internal flow remains presentation -> provider/repository contract -> repository implementation -> Drift DAO/query. [Source: `_bmad-output/planning-artifacts/architecture.md#Integration Points`]
- Stock In/Out is the only path that writes stock movements and product quantity changes. [Source: `_bmad-output/planning-artifacts/architecture.md#Data Boundaries`]
- Use existing packages only: Flutter Material, Riverpod, go_router, Drift. No new dependency is needed.
- MVP exclusions remain out: no login, cloud sync, barcode scanner, POS/cart, supplier, accounting/profit reports, analytics, or remote API layer.

### UX And Layout Guardrails

- Preserve single-column Android layout with 16dp outer padding and practical 8/16/24dp spacing. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Layout & Spacing`]
- Common tap targets should be at least 48dp. [Source: `_bmad-output/planning-artifacts/epics.md#NonFunctional Requirements`]
- Keep Dashboard calm and operational: no nested cards, decorative gradients, heavy shadows, large hero blocks, or image-heavy assets. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Elevation & Depth`]
- Use plain, Filipino-friendly English and avoid raw technical terms in visible copy. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Voice And Tone`]
- Recent activity rows should remain readable at system font scaling and should not rely on color alone. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Accessibility Floor`]

### Suggested Implementation Shape

- Likely add:
  - `tindatrack/lib/features/dashboard/domain/entities/dashboard_recent_activity_item.dart`
- Likely update:
  - `tindatrack/lib/features/dashboard/domain/repositories/dashboard_repository.dart`
  - `tindatrack/lib/features/dashboard/data/repositories/drift_dashboard_repository.dart`
  - `tindatrack/lib/features/dashboard/presentation/providers/dashboard_providers.dart`
  - `tindatrack/lib/features/dashboard/presentation/screens/dashboard_screen.dart`
  - `tindatrack/test/features/dashboard/data/repositories/drift_dashboard_repository_test.dart`
  - `tindatrack/test/features/dashboard/presentation/screens/dashboard_screen_test.dart`
- Suggested keys:
  - `Key('dashboard-recent-activity-section')`
  - `Key('dashboard-view-history-action')`
  - `Key('dashboard-recent-activity-item-${movement.id}')`
  - `Key('dashboard-recent-activity-empty')`
  - `Key('dashboard-recent-activity-loading')`
  - `Key('dashboard-recent-activity-error')`
- Suggested labels:
  - Section title: `Recent Activity`
  - Action: `View History`
  - Empty title/copy: `No stock movement yet.` / `Stock In and Stock Out records will appear here.`

### Testing Requirements

- Repository tests should use in-memory `AppDatabase(NativeDatabase.memory())`, `ProductsDao`, and `StockMovementsDao`, matching existing dashboard repository tests.
- Widget tests should use provider overrides through `_DashboardRepository` or equivalent fakes and should not require real wall-clock time.
- Navigation test can mirror Story 4.4's router test but target `AppRoute.history.path` and a fake History route.
- Verify error copy does not leak exception text such as `PRIVATE_SQL_FAILURE`.
- Verify compact notes do not overflow on a 360x640 viewport with enlarged text.
- Run Flutter commands from a Windows temp copy if UNC workspace tooling fails; CMD does not support UNC current directories.

### Previous Story Intelligence

- Story 4.4 completed at `4132f0d` and review fix at `33083d4`.
- Story 4.4 added Dashboard-to-Products navigation through `go_router`, using `context.go(AppRoute.products.path)` after setting existing Products filter state.
- Story 4.4 review fixed low-stock consistency: Products Low Stock now includes zero-quantity products just like Dashboard restocking counts, while Out of Stock remains visually distinct.
- Story 4.4 tests established a lightweight Dashboard router pattern with provider overrides.
- Do not regress Story 4.3/4.4 behavior: summary cards remain visible, low-stock preview loading/error/empty states remain inline, `View Low Stock` still navigates to Products, and first-product empty state hides Dashboard preview sections.

### Git Intelligence

- `33083d4 Fix Story 4.4 low-stock filter consistency`
- `4132f0d Complete Story 4.4 dashboard low-stock navigation`
- `0097c74 Record Story 4.3 review findings`
- `286d0c8 Fix Story 4.3 dashboard review findings`
- `a5539bb Complete Story 4.3 dashboard low stock preview`

Recent Dashboard work keeps feature code under `lib/features/dashboard`, mirrors tests under `test/features/dashboard`, uses Riverpod provider overrides for deterministic widget tests, and verifies Flutter from a Windows temp copy when UNC workspace tooling blocks direct Flutter commands.

### Project Structure Notes

- Keep Dashboard and History connected through app-level navigation and read-only data, not through mutation or cross-feature UI ownership.
- Avoid adding a new recent-activity route; use existing `AppRoute.history`.
- Avoid schema or generated Drift changes unless a test proves current `stock_movements` columns cannot satisfy the story. The current table already has movement type, quantity, product snapshot, unit snapshot, note, and created timestamp.
- If sharing formatting with History becomes useful, prefer a small pure helper only if it genuinely reduces duplication without creating feature ownership confusion.

## Dev Agent Record

### Agent Model Used

Codex GPT-5

### Debug Log References

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.

### File List
