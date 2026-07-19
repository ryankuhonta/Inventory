# Story 4.6: Protect Dashboard Behavior With Tests

Status: ready-for-dev

## Story

As a developer maintaining dashboard logic,
I want dashboard summary and navigation tests,
so that the dashboard stays accurate as inventory features evolve.

## Acceptance Criteria

1. Given dashboard summary tests run, when active and archived products exist, then tests verify total product count excludes archived products and active products are counted correctly.
2. Given low-stock summary tests run, when products are below, equal to, and above their thresholds, then tests verify low-stock count includes quantity equal to threshold and out-of-stock products are treated as needing attention.
3. Given Stock Changes Today tests run, when movements exist around UTC/local day boundaries, then tests verify the dashboard uses the device or app local timezone day and UTC storage does not shift the user's visible "today" count.
4. Given dashboard widget tests run, when loading, empty, error, and populated states are rendered, then tests verify the correct user-facing state appears and raw technical errors are not shown.
5. Given dashboard navigation tests run, when the user taps the low-stock dashboard path, then tests verify Products opens with the Low Stock filter selected and the route works offline.

## Tasks / Subtasks

- [ ] Task 1: Audit existing Dashboard test coverage before adding new tests (AC: 1-5)
  - [ ] Review `tindatrack/test/features/dashboard/data/repositories/drift_dashboard_repository_test.dart` and list which ACs are already covered.
  - [ ] Review `tindatrack/test/features/dashboard/presentation/screens/dashboard_screen_test.dart`, `tindatrack/test/widget_test.dart`, and `tindatrack/test/app/launch_retry_regression_test.dart` for existing state, navigation, lifecycle, accessibility, and provider override coverage.
  - [ ] Avoid duplicating equivalent assertions unless duplication protects a different layer or regression path.

- [ ] Task 2: Complete repository and cross-feature data guardrails (AC: 1-3, 5)
  - [ ] Keep repository tests under `tindatrack/test/features/dashboard/data/repositories/drift_dashboard_repository_test.dart` unless a cross-feature test clearly belongs elsewhere.
  - [ ] Verify total active product count excludes archived products and counts multiple active rows correctly.
  - [ ] Verify low-stock count includes active products with quantity below threshold, equal to threshold, and zero quantity; excludes archived rows and above-threshold rows.
  - [ ] Add a cross-feature low-stock consistency test proving Dashboard summary count, Dashboard preview, and Products low-stock filter apply the same rule for zero, equal-threshold, below-threshold, above-threshold, and archived products.
  - [ ] Verify Stock Changes Today includes local-day start, excludes just-before-start and exact-end movements, and uses UTC query boundaries derived from a local day.
  - [ ] Strengthen local-day boundary coverage so it does not silently skip in UTC environments; prefer deterministic constructed DateTime/zone expectations or isolate any environment-dependent assertion with a separate always-running boundary test.
  - [ ] Preserve existing low-stock preview and recent activity preview tests for ordering, clamping, mapping, and stream re-emission; extend only if a missing acceptance gap remains.

- [ ] Task 3: Protect Dashboard provider composition and time refresh behavior (AC: 1-4)
  - [ ] Add focused provider tests under `tindatrack/test/features/dashboard/presentation/providers/dashboard_providers_test.dart` if no equivalent file exists.
  - [ ] Verify `dashboardRecentActivityPreviewProvider` delegates to `DashboardRepository.watchRecentActivityPreview` and emits repository data without touching Drift directly.
  - [ ] Use the existing `clockProvider` override pattern; do not call `DateTime.now()` directly in tests or production.
  - [ ] Verify `dashboardSummaryProvider` asks the repository for the current local day and invalidates at the next local midnight, or document why this is already covered and lower-risk than repository boundary tests.
  - [ ] Avoid real-time sleeps such as `Future.delayed(...)`; use fake clocks, provider invalidation, or fake async patterns where practical.
  - [ ] Ensure provider tests do not leave live timers or streams that keep Flutter tests hanging.

- [ ] Task 4: Complete Dashboard widget state and retry guardrails (AC: 4)
  - [ ] Keep widget tests under `tindatrack/test/features/dashboard/presentation/screens/dashboard_screen_test.dart` unless app-shell behavior belongs in `tindatrack/test/widget_test.dart`.
  - [ ] Verify summary loading, summary error, all-zero first-product empty state, populated summary cards, low-stock preview states, and recent activity preview states remain user-friendly.
  - [ ] Verify raw diagnostics such as `PRIVATE_SQL_FAILURE`, Drift messages, or SQL snippets are not visible in dashboard summary, low-stock preview, or recent activity errors.
  - [ ] Add retry interaction tests for Dashboard summary, low-stock preview, and recent activity preview errors: tap Retry, verify the provider/repository is re-read, and verify friendly copy recovers.
  - [ ] Add a visible timestamp assertion for recent activity rows so `_formatActivityDateTime(item.createdAt.toLocal())` remains locked by user-visible behavior, not just row presence.
  - [ ] Preserve the Story 4.5 regression where older recent activity still appears even when summary counts are all zero.

- [ ] Task 5: Complete Dashboard navigation and offline shell guardrails (AC: 5)
  - [ ] Verify `View Low Stock` uses `context.go(AppRoute.products.path)` and the existing `ProductStockFilter.lowStock` controller path.
  - [ ] Verify Products opens with the Low Stock filter visibly selected after Dashboard navigation.
  - [ ] Add an app-shell regression using the real `createAppRouter`/bottom navigation path, not only the lightweight fake router, so Dashboard -> Products low-stock navigation works in the real shell.
  - [ ] In the app-shell regression, assert the Products branch is selected and the user can reset the Products filter from Low Stock back to All.
  - [ ] Verify the navigation test runs entirely with local provider overrides or an in-memory database; it must not require network, login, cloud sync, or a remote API.
  - [ ] Keep History navigation tests from Story 4.5 intact; do not add new routes or query parameters for Story 4.6.

- [ ] Task 6: Add responsive/accessibility guardrails only where gaps remain (AC: 4-5)
  - [ ] Preserve small-phone/high-text-scale tests for Dashboard summary, low-stock preview, and recent activity rows.
  - [ ] Add one populated small-phone/high-text-scale test covering summary cards plus both preview sections together with large counts and long product names.
  - [ ] Add targeted accessibility assertions for stable user behavior: low-stock row semantics, recent activity row button semantics, loading semantics labels, and `View Low Stock` / `View History` tap targets where not already covered.
  - [ ] Do not assert brittle exact pixel positions or private widget structure beyond stable keys and user-visible behavior.

- [ ] Task 7: Verify Story 4.6 completion (AC: 1-5)
  - [ ] Run Dart format for touched test files.
  - [ ] Run focused Dashboard repository/provider/widget tests.
  - [ ] Run `dart analyze`.
  - [ ] Run the full Flutter test suite if focused tests and analyzer pass.
  - [ ] Run `git diff --check`.

## Dev Notes

### Source Requirements

- Story 4.6 covers FR-001, FR-002, FR-003, FR-005, FR-021, FR-022, NFR-003, and NFR-004. [Source: `_bmad-output/planning-artifacts/epics.md#Story 4.6: Protect Dashboard Behavior With Tests`]
- FR-001 requires Dashboard total active products. [Source: `_bmad-output/planning-artifacts/epics.md#Functional Requirements`]
- FR-002 requires Dashboard low-stock count. [Source: `_bmad-output/planning-artifacts/epics.md#Functional Requirements`]
- FR-003 requires recent inventory activity. [Source: `_bmad-output/planning-artifacts/epics.md#Functional Requirements`]
- FR-005 requires a clear path to low-stock products. [Source: `_bmad-output/planning-artifacts/epics.md#Functional Requirements`]
- FR-021 and FR-022 require low-stock and out-of-stock visual identification. [Source: `_bmad-output/planning-artifacts/epics.md#Functional Requirements`]
- NFR-003 and NFR-004 require responsiveness on low-end Android devices and product-list scale awareness. Dashboard tests should protect focused aggregate queries and avoid full-list recomputation patterns. [Source: `_bmad-output/planning-artifacts/epics.md#NonFunctional Requirements`]

### Current Dashboard System State

- Dashboard production code is already implemented through:
  - `tindatrack/lib/features/dashboard/domain/entities/dashboard_summary.dart`
  - `tindatrack/lib/features/dashboard/domain/entities/dashboard_low_stock_preview_item.dart`
  - `tindatrack/lib/features/dashboard/domain/entities/dashboard_recent_activity_item.dart`
  - `tindatrack/lib/features/dashboard/domain/repositories/dashboard_repository.dart`
  - `tindatrack/lib/features/dashboard/data/repositories/drift_dashboard_repository.dart`
  - `tindatrack/lib/features/dashboard/presentation/providers/dashboard_providers.dart`
  - `tindatrack/lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- `DriftDashboardRepository.watchSummary(localNow:)` uses focused SQL aggregate subqueries over `products` and `stock_movements`; widgets must not recompute summary values by scanning full lists.
- `watchLowStockPreview` reads active `products`, prioritizes out-of-stock rows, then low-stock rows, and caps the preview size.
- `watchRecentActivityPreview` reads `stock_movements`, orders by `created_at DESC, id DESC`, caps preview size, and maps Drift rows into a dashboard-specific domain entity.
- `dashboardSummaryProvider` uses `clockProvider.now().toLocal()`, schedules `ref.invalidateSelf` at next local midnight, and delegates summary calculation to the repository.
- `DashboardScreen` reads summary plus recent activity at the top level so the first-product empty state is shown only when summary is all zero and the loaded recent activity preview is empty.

### Architecture Compliance

- Dashboard and History are read-only over inventory data. Tests must not add stock mutation behavior to Dashboard. [Source: `_bmad-output/planning-artifacts/architecture.md#Service Boundaries`]
- Widgets call providers/controllers; widgets must not import DAOs or `AppDatabase`. Repository tests may use in-memory Drift and DAOs. [Source: `_bmad-output/planning-artifacts/architecture.md#Component Boundaries`]
- Internal flow remains screen -> Riverpod provider/controller -> repository contract -> repository implementation -> Drift DAO/query. [Source: `_bmad-output/planning-artifacts/architecture.md#Integration Points`]
- Dashboard summaries should avoid heavy recomputation and use focused aggregate queries. [Source: `_bmad-output/planning-artifacts/architecture.md#Performance And Data Rules`]
- Keep MVP exclusions absent: no login, cloud sync, barcode scanner, POS/cart, supplier, accounting/profit reports, analytics, or remote API layer. [Source: `_bmad-output/planning-artifacts/architecture.md#MVP Exclusions Enforced By Structure`]

### UX And Accessibility Guardrails

- Dashboard content should include `Inventory Today`, summary cards, low-stock preview, and recent activity preview. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Dashboard`]
- First-product Dashboard empty state should guide the user to `Add your first product`. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Dashboard`]
- Keep the Dashboard calm, practical, and direct; avoid decorative gradients, heavy shadows, nested cards, and raw technical copy. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Brand & Style`]
- Minimum tap target is 48dp, text must remain readable at system font scaling, and warnings must not rely on color alone. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Accessibility Floor`]
- Visible copy should be plain and action-oriented, avoiding technical words such as `inventory mutation`, `entity`, and raw constraint errors. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Voice And Tone`]

### Existing Test Inventory

- `tindatrack/test/features/dashboard/data/repositories/drift_dashboard_repository_test.dart` already contains Dashboard repository tests for active/archived counts, low-stock counts, local-day stock changes, low-stock preview ordering/clamping/re-emission, recent activity ordering/clamping/mapping/re-emission, and summary re-emission.
- `tindatrack/test/features/dashboard/presentation/screens/dashboard_screen_test.dart` already contains widget tests for summary cards, neutral/warning low-stock card behavior, no-active-products-with-stock-changes behavior, older recent activity with all-zero summary, low-stock preview rows/states, recent activity rows/states, History navigation, row tap navigation, Low Stock navigation, small-screen/high-text-scale behavior, friendly error copy, and first-product empty state.
- Remaining high-value gaps identified during story creation: full app-shell Dashboard -> Products low-stock navigation, cross-feature low-stock consistency, recent activity provider composition, visible recent activity timestamp formatting, non-skipping local-day boundary coverage, retry recovery interactions, Dashboard-specific accessibility/tap-target assertions, and one populated whole-page small-screen/high-text-scale regression.
- `tindatrack/test/widget_test.dart` already contains app-level launch, bootstrap, navigation shell, theme, accessibility guideline, and high-text-scale branch-root coverage. Dashboard stream providers are overridden in app-level tests to avoid real Drift lifecycle timers.
- `tindatrack/test/app/launch_retry_regression_test.dart` already protects bootstrap retry behavior and overrides Dashboard summary, low-stock preview, and recent activity providers deterministically.

### Previous Story Intelligence

- Story 4.5 completed at `684d8b5` and review fix at `b830427`.
- Story 4.5 review found a real regression: older recent activity could be hidden by the all-zero first-product empty state. The fix made `DashboardScreen` consider loaded recent activity before choosing the first-product empty state.
- Story 4.5 review also strengthened navigation tests so `View History` and row taps navigate to History without modifying movement preview data.
- Focused Dashboard screen tests passed 20/20 from `C:\tmp\tindatrack-story-4-5-review-fix\tindatrack`; `dart analyze` passed; `git diff --check` was clean.
- Story 4.4 completed at `4132f0d` and review fix at `33083d4`; it established the Dashboard-to-Products navigation pattern through `context.go(AppRoute.products.path)` after setting `ProductStockFilter.lowStock`.
- Story 4.4 review fixed low-stock consistency so zero-quantity products remain part of low-stock/restocking behavior while Out of Stock stays visually distinct.

### Git Intelligence

- `b830427 Fix Story 4.5 review findings`
- `684d8b5 Complete Story 4.5 dashboard recent activity`
- `21e15db Create Story 4.5 recent activity preview`
- `33083d4 Fix Story 4.4 low-stock filter consistency`
- `4132f0d Complete Story 4.4 dashboard low-stock navigation`
- `0097c74 Record Story 4.3 review findings`
- `286d0c8 Fix Story 4.3 dashboard review findings`
- `a5539bb Complete Story 4.3 dashboard low stock preview`

Recent Dashboard work keeps feature code under `tindatrack/lib/features/dashboard`, mirrors tests under `tindatrack/test/features/dashboard`, uses provider overrides for deterministic widget tests, and verifies Flutter from a Windows temp copy when UNC workspace tooling blocks direct Flutter commands.

### Library And Framework Requirements

- Use existing dependencies only: Flutter Material, flutter_test, Riverpod, go_router, Drift, and the current test helper style. No new package is needed.
- Current local package context is Dart SDK `^3.12.0`, Drift `^2.34.0`, flutter_riverpod `^3.3.2`, go_router `^17.3.0`, mocktail `^1.0.5`, and very_good_analysis `^10.2.0`. [Source: `tindatrack/pubspec.yaml`]
- Do not use web research or dependency upgrades for Story 4.6 unless an existing test failure proves a package-specific issue.

### Project Structure Notes

- Primary expected updates are tests, not production code:
  - `tindatrack/test/features/dashboard/data/repositories/drift_dashboard_repository_test.dart`
  - `tindatrack/test/features/dashboard/presentation/screens/dashboard_screen_test.dart`
  - Possible focused provider test file under `tindatrack/test/features/dashboard/presentation/providers/` if needed.
  - Possible app-level regression additions in `tindatrack/test/widget_test.dart` only for shell/offline navigation behavior.
- Avoid schema or generated Drift changes. Story 4.6 is a protection story, not a database feature story.
- Avoid adding routes, query parameters, filters, or UI states unless a test exposes an existing behavior gap that must be fixed.
- Do not duplicate Story 4.1-4.5 happy-path tests unless the duplicate protects a different layer such as provider composition, app-shell routing, or cross-feature consistency.
- Keep fake repositories and provider overrides deterministic. Avoid live streams/timers that make `pumpAndSettle` hang.
- If a production fix is necessary, keep it narrow and add a regression test that fails without the fix.

## Dev Agent Record

### Agent Model Used

Codex GPT-5

### Debug Log References

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.

### File List

### Change Log

- 2026-07-19: Created Story 4.6 developer context from Epic 4, architecture, UX specs, current Dashboard code/tests, and Story 4.5 review learnings.
