---
baseline_commit: 1970740
---

# Story 4.2: Build Dashboard Screen With Summary Cards

Status: review

## Story

As a store owner,
I want to see total products, low stock, and stock changes today,
so that I can understand inventory status at a glance.

## Acceptance Criteria

1. Given the user opens the Dashboard, when inventory data is available, then the screen shows the header "Inventory Today" and summary cards for Total Products, Low Stock, and Stock Changes Today.
2. Given dashboard data is loading, when the screen is displayed, then it shows a lightweight loading state and the UI remains responsive.
3. Given dashboard data fails to load, when the screen is displayed, then it shows friendly recovery copy and raw database or exception messages are not shown.
4. Given no products exist, when the user opens the Dashboard, then the screen shows an empty state that guides the user to add the first product and the empty state does not imply cloud setup or login is required.

## Tasks / Subtasks

- [x] Task 1: Replace the Dashboard placeholder with a provider-backed screen (AC: 1-4)
  - [x] Convert `DashboardScreen` to a Consumer-based widget or use a local `Consumer` while preserving `Key('dashboard-screen')`.
  - [x] Watch `dashboardSummaryProvider`; do not query Drift, DAOs, products, or stock movements directly from widgets.
  - [x] Keep the dashboard read-only in this story; no product mutation, stock mutation, navigation wiring, low-stock preview, or recent-activity preview.

- [x] Task 2: Render populated dashboard summary cards (AC: 1)
  - [x] Show the exact header text `Inventory Today`.
  - [x] Render three summary cards with labels `Total Products`, `Low Stock`, and `Stock Changes Today`.
  - [x] Bind card values to `DashboardSummary.totalActiveProducts`, `lowStockProducts`, and `stockChangesToday`.
  - [x] Use a compact single-column mobile layout, stable card dimensions, `AppSpacing`, `AppDimensions.componentRadius`, and Material theme colors.
  - [x] Use warning treatment for the Low Stock card only when the value is greater than zero; do not rely on color alone.

- [x] Task 3: Handle dashboard loading and error states (AC: 2, 3)
  - [x] Use `AppLoadingView` or an equally lightweight shared pattern with `Key('dashboard-loading-state')`.
  - [x] Use `AppErrorView` with friendly copy, `Key('dashboard-error-state')`, and a Retry action that invalidates `dashboardSummaryProvider`.
  - [x] Do not display raw exception text, Drift messages, stack traces, or technical database wording.

- [x] Task 4: Handle first-product empty state (AC: 4)
  - [x] When `totalActiveProducts == 0`, show `AppEmptyState` with `Key('dashboard-empty-state')`.
  - [x] Include clear copy and action text `Add your first product`.
  - [x] Do not imply login, cloud setup, backup, sync, scanner, POS, supplier, or accounting setup.
  - [x] Do not implement the action's navigation in this story unless the existing routing helper makes it trivial and fully tested; Story 4.4 owns dashboard navigation paths.

- [x] Task 5: Add focused widget tests for Story 4.2 (AC: 1-4)
  - [x] Add tests under `tindatrack/test/features/dashboard/presentation/screens/dashboard_screen_test.dart`.
  - [x] Test the populated state renders the header, all three card labels, and expected values.
  - [x] Test loading state renders without overflowing on a small Android-sized surface.
  - [x] Test error state shows friendly recovery copy and no raw exception content.
  - [x] Test zero-product state shows `Add your first product`.
  - [x] Override `dashboardSummaryProvider` or its repository provider in tests; keep tests deterministic and independent of wall-clock time.

- [x] Task 6: Verify Story 4.2 completion (AC: 1-4)
  - [x] Run Dart format for touched `lib` and `test` files.
  - [x] Run focused dashboard screen tests.
  - [x] Run `dart analyze`.
  - [x] Run the full Flutter test suite if focused tests and analyzer pass.
  - [x] Run `git diff --check`.

## Dev Notes

### Source Requirements

- Story 4.2 covers FR-001, FR-002, FR-003, UX-DR9, UX-DR10, UX-DR25, and UX-DR26. [Source: `_bmad-output/planning-artifacts/epics.md#Story 4.2: Build Dashboard Screen With Summary Cards`]
- Dashboard must show `Inventory Today`, summary cards for Total Products, Low Stock, and Stock Changes Today, plus later low-stock and recent-activity previews. This story owns only the header and summary cards. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Dashboard`]
- Loading states should be lightweight; error states must use plain recovery text and include retry for data loading failures. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#State Patterns`]
- Empty dashboard state should guide the user to `Add your first product`. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Dashboard`]
- Dashboard summaries should avoid heavy recomputation on rebuild and use aggregate queries. [Source: `_bmad-output/planning-artifacts/architecture.md#Performance And Data Rules`]

### Current System State

- `tindatrack/lib/features/dashboard/presentation/screens/dashboard_screen.dart` is still a placeholder that renders `Dashboard` and `Offline inventory tracker`.
- Story 4.1 added the summary read boundary:
  - `DashboardSummary`
  - `DashboardRepository`
  - `DriftDashboardRepository`
  - `dashboardRepositoryProvider`
  - `dashboardSummaryProvider`
- `dashboardSummaryProvider` already handles local-day summary streams and refreshes after local midnight. Reuse it directly; do not reimplement dashboard SQL or time-window logic in the screen.
- Existing shared state widgets are available:
  - `tindatrack/lib/core/widgets/app_loading_view.dart`
  - `tindatrack/lib/core/widgets/app_error_view.dart`
  - `tindatrack/lib/core/widgets/app_empty_state.dart`
- Existing UI constants are available:
  - `tindatrack/lib/core/ui/app_spacing.dart`
  - `tindatrack/lib/core/ui/app_dimensions.dart`

### Architecture Compliance

- Keep widgets presentation-only. Widgets consume `dashboardSummaryProvider`; they must not access Drift, DAOs, or raw database rows.
- Keep Dashboard read-only. No stock movement, product mutation, settings mutation, schema change, generated Drift change, or migration belongs in Story 4.2.
- Keep MVP exclusions out: no login, cloud sync, backup/export, scanner, POS, supplier, accounting, reporting, remote API client, or fake future-feature UI.
- Use existing packages only: Flutter Material, Riverpod, Drift-backed providers already in the project. No new dependencies are needed.
- Use simple English with Filipino-friendly phrasing; do not show technical terms like raw database errors, exceptions, "entity", or "mutation" in UI.

### UX And Layout Guardrails

- Use a single-column Android mobile layout with 16dp outer padding and 8/16/24dp spacing from `AppSpacing`. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Layout & Spacing`]
- Summary cards should be compact and stable. A responsive `Wrap`, constrained grid, or vertical list is acceptable if it avoids overflow on small phones and enlarged text.
- Use modest 8dp card radius via `AppDimensions.componentRadius`; avoid nested cards, decorative gradients, heavy shadows, and floating panels. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Elevation & Depth`]
- Card content should show one metric and one label. Use visible labels, not color-only meaning. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Summary Card`]
- Preserve the app shell and bottom navigation; `DashboardScreen` owns only the dashboard branch content.

### Suggested Implementation Shape

- Update:
  - `tindatrack/lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- Add:
  - `tindatrack/test/features/dashboard/presentation/screens/dashboard_screen_test.dart`
- Optional private widgets inside `dashboard_screen.dart` are acceptable:
  - `_DashboardContent`
  - `_SummaryCard`
  - `_DashboardEmptyState`
- Suggested keys for robust tests:
  - `Key('dashboard-screen')`
  - `Key('dashboard-loading-state')`
  - `Key('dashboard-error-state')`
  - `Key('dashboard-empty-state')`
  - `Key('dashboard-summary-total-products')`
  - `Key('dashboard-summary-low-stock')`
  - `Key('dashboard-summary-stock-changes-today')`

### Testing Requirements

- Widget tests should wrap `DashboardScreen` in `ProviderScope` and `MaterialApp` using the app theme if existing helpers are available.
- Prefer overriding `dashboardSummaryProvider` with deterministic `AsyncValue`/stream behavior for screen states.
- Test populated state with non-zero values, for example total products `12`, low stock `3`, stock changes today `5`.
- Test empty state with `DashboardSummary(totalActiveProducts: 0, lowStockProducts: 0, stockChangesToday: 0)`.
- Test error state with a fake exception and assert the raw exception string is not visible.
- Test loading/small-screen behavior with a compact surface similar to existing widget tests; verify no overflow exceptions.
- Run focused dashboard tests from a Windows temp copy if direct Flutter commands fail from the UNC workspace.

### Previous Story Intelligence

- Story 4.1 is complete and pushed at `1970740`. It added the provider this story must consume.
- Story 4.1 review fixed two time-boundary risks: DST-safe local day end and provider invalidation after local midnight. Do not weaken or duplicate that logic.
- Story 4.1 verification passed focused dashboard tests, analyzer, full Flutter test suite, and `git diff --check` from `C:\tmp\tindatrack-story-4-1-review-fixes`.
- Existing Product and History screens demonstrate the expected pattern for `AsyncValue` state handling with shared loading/error/empty widgets.

### Git Intelligence

- `1970740 Fix Story 4.1 dashboard review findings`
- `fc77aa6 Complete Story 4.1 dashboard summary queries`
- `b250a8f Complete Story 3.8 stock movement reliability tests`
- `6784394 Complete product row stock actions`
- `5d963d1 Complete stock out and history flows`

Recent work consistently keeps feature code under `lib/features/{feature}`, tests mirrored under `test/features/{feature}`, uses Riverpod provider overrides for deterministic tests, and verifies Flutter from a Windows temp copy when the UNC workspace blocks direct Flutter tooling.

### Project Structure Notes

- This story should not implement Story 4.3 low-stock preview, Story 4.4 navigation to filtered Products, Story 4.5 recent activity preview, or Story 4.6 broad dashboard regression suite.
- If an `Add your first product` action is rendered, keep it simple and local to the empty state. Do not introduce new router contracts unless fully covered and consistent with existing `ProductRoute.addProduct`.

## Dev Agent Record

### Agent Model Used

Codex GPT-5

### Debug Log References

- `flutter test test/features/dashboard/presentation/screens/dashboard_screen_test.dart` initially failed against the placeholder Dashboard screen, confirming the Story 4.2 screen tests were red before implementation.
- `flutter test test/features/dashboard test/widget_test.dart` passed from `C:\tmp\tindatrack-story-4-2-verify1` with 21 tests.
- `flutter test test/app` passed from `C:\tmp\tindatrack-story-4-2-verify1` with 39 tests after updating router/navigation test harnesses for the provider-backed Dashboard.
- `dart analyze` passed from `C:\tmp\tindatrack-story-4-2-verify1` with no issues.
- `flutter test` passed from `C:\tmp\tindatrack-story-4-2-verify1` with 313 tests.

### Completion Notes List

- Replaced the placeholder Dashboard branch with a Riverpod-backed summary screen consuming `dashboardSummaryProvider` only.
- Added summary cards for Total Products, Low Stock, and Stock Changes Today, including a non-color-only warning treatment when low-stock count is non-zero.
- Added friendly loading, error/retry, and first-product empty states without exposing raw exception or database details.
- Added focused Dashboard screen widget coverage and updated app/root test harnesses to provide deterministic Dashboard summary data now that Dashboard is no longer static.\n- Addressed review findings by showing cards when any visible summary count is non-zero, making zero-low-stock treatment neutral, using approved warning color tokens, and guarding card text overflow.

### File List

- `_bmad-output/implementation-artifacts/4-2-build-dashboard-screen-with-summary-cards.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `tindatrack/lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- `tindatrack/test/app/launch_retry_regression_test.dart`
- `tindatrack/test/app/navigation/app_shell_test.dart`
- `tindatrack/test/app/router/app_router_test.dart`
- `tindatrack/test/features/dashboard/presentation/screens/dashboard_screen_test.dart`
- `tindatrack/test/widget_test.dart`

### Change Log

- 2026-07-12: Implemented Dashboard summary cards and marked Story 4.2 ready for review.\n- 2026-07-12: Applied Story 4.2 review fixes for neutral low-stock state and zero-product activity summaries.