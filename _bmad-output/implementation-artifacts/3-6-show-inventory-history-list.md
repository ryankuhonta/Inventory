---
baseline_commit: 4fad416907209de8dbe9756997134e0c5e2bfbbf
---

# Story 3.6: Show Inventory History List

Status: done

## Story

As a store owner,
I want to review stock movement history,
So that I can audit why product quantities changed.

## Acceptance Criteria

1. Given stock movement records exist, when the user opens History, then movements are shown newest first, and the screen is read-only.
2. Given a movement row is displayed, when the user reviews it, then it shows Stock In or Stock Out label, product name snapshot, changed quantity, previous quantity, new quantity, date/time, and note when present, and it remains understandable after product rename or archive.
3. Given a Stock Out movement has a reason value, when the movement appears in History, then the reason may be available to the row or detail model, and the MVP UI is not required to expose a reason filter or selector.
4. Given no stock movements exist, when the user opens History, then the screen shows a friendly empty state such as `Stock changes will appear here`, and it does not show a technical error.

## Tasks / Subtasks

- [x] Task 1: Add movement-history presentation provider (AC: 1, 4)
  - [x] Add a Riverpod provider under `tindatrack/lib/features/history/presentation/providers/` or the existing stock presentation provider boundary if the codebase pattern points there.
  - [x] Read from `stockRepositoryProvider.watchMovementHistory()`; do not query Drift/DAO directly from widgets.
  - [x] Preserve repository-provided newest-first ordering; do not sort in UI unless needed only as a defensive test aid.
  - [x] Surface loading, data, empty, and safe error states for the screen.

- [x] Task 2: Replace the History placeholder with a real read-only list (AC: 1, 2, 4)
  - [x] Update `tindatrack/lib/features/history/presentation/screens/movement_history_screen.dart`.
  - [x] Keep the root scaffold key `history-screen` for existing router tests.
  - [x] Use `AppLoadingView`, `AppErrorView`, and `AppEmptyState` patterns where appropriate.
  - [x] Render a lazy list for movement rows rather than a static column, so future larger histories remain responsive.
  - [x] Do not add edit/delete/retry mutation controls to rows; History is read-only in this story.

- [x] Task 3: Render complete movement row information (AC: 2, 3)
  - [x] Show `Stock In` for `StockMovementType.stockIn` and `Stock Out` for `StockMovementType.stockOut`.
  - [x] Show `productNameSnapshot`, not the current product name from `ProductRepository`.
  - [x] Show changed quantity with `unitSnapshot`, for example `+3 pcs` or `-2 pcs`.
  - [x] Show previous-to-new quantity, for example `5 -> 8 pcs`.
  - [x] Show a readable local date/time derived from `createdAt`; keep domain timestamps UTC and presentation-only formatting in the widget/helper.
  - [x] Show note text only when `movement.note` is non-null and non-empty.
  - [x] Keep `reason` available through the row/view model if useful, but do not add a reason filter, selector, or full detail screen in this story.

- [x] Task 4: Add focused widget/provider tests (AC: 1, 2, 3, 4)
  - [x] Create `tindatrack/test/features/history/presentation/screens/movement_history_screen_test.dart` or equivalent provider/screen split.
  - [x] Test movements render newest first using fake repository stream data.
  - [x] Test row copy includes type label, snapshot product name, signed changed quantity, previous/new quantities, date/time, and note when present.
  - [x] Test renamed/archived readability by using snapshot values without loading current product data.
  - [x] Test empty history shows `Stock changes will appear here` or equivalent friendly copy.
  - [x] Test repository/provider errors show friendly copy and do not leak raw Drift/SQL/debug text.
  - [x] Test the screen remains scrollable/lazy enough for many rows or small screens.

- [x] Task 5: Verify Story 3.6 completion (AC: 1, 2, 3, 4)
  - [x] Run focused history widget/provider tests.
  - [x] Run `dart format lib test`.
  - [x] Run Dart analyzer.
  - [x] Run the full Flutter test suite.
  - [x] Run WSL `git diff --check`.

### Review Findings

- [x] [Review][Patch] Fix invalid baseline commit in story frontmatter [_bmad-output/implementation-artifacts/3-6-show-inventory-history-list.md:2]

## Dev Notes

### Source Requirements

- Story 3.6 covers FR-017, FR-034, FR-035, FR-036, UX-DR22, and UX-DR23. [Source: `_bmad-output/planning-artifacts/epics.md#Story 3.6: Show Inventory History List`]
- History must show stock movements newest first and be read-only. [Source: `_bmad-output/planning-artifacts/epics.md#Story 3.6: Show Inventory History List`]
- Each movement row must include type, product snapshot, changed quantity, previous quantity, new quantity, date/time, and note when present. [Source: `_bmad-output/planning-artifacts/epics.md#Story 3.6: Show Inventory History List`; `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#History`]
- Movement history must remain readable after product rename or archive by using `product_name_snapshot` and `unit_snapshot`. [Source: `_bmad-output/planning-artifacts/architecture.md#Architecture Invariants`; `_bmad-output/planning-artifacts/architecture.md#Required Implementation Test Checklist`]
- Empty and error states must use friendly user copy and never expose raw Drift/SQL/exception text. [Source: `_bmad-output/planning-artifacts/epics.md#Story 3.6: Show Inventory History List`; `_bmad-output/planning-artifacts/architecture.md#UX Copy And Flow Notes`]

### Current System State

- `MovementHistoryScreen` currently exists only as a placeholder at `tindatrack/lib/features/history/presentation/screens/movement_history_screen.dart` and already uses the root key `history-screen`.
- The History branch route already exists in `createAppRouter` through `_buildHistory`; no new route should be needed for the basic list.
- `StockRepository` already exposes `listMovementHistory({String? productId})` and `watchMovementHistory({String? productId})`, both documented as newest first.
- `DriftStockRepository.watchMovementHistory()` maps DAO rows to domain `StockMovement` entities.
- `StockMovementsDao._historyQuery()` orders by `createdAt DESC` and `id DESC`, with optional product filtering.
- Repository tests already cover list/watch newest-first ordering, product filtering, snapshot preservation after rename, and persistence failure mapping for invalid persisted rows. Story 3.6 should focus on presentation behavior, not duplicate deep repository transaction tests.
- There is no existing `movement_history_screen_test.dart`; this story should add the first History presentation tests.

### Architecture Compliance

- Use Flutter Material 3, Riverpod, go_router, Drift, and Clean Architecture; do not add new dependencies.
- Widgets must not access DAOs, Drift generated rows, or database classes directly.
- Keep History presentation code under `lib/features/history/presentation`; shared stock history data should continue to come through `features/stock` domain/repository APIs.
- Use `StockMovement` domain fields exactly: `type`, `quantity`, `previousQuantity`, `newQuantity`, `reason`, `note`, `productNameSnapshot`, `unitSnapshot`, and `createdAt`.
- Do not introduce product joins or current product lookups for row labels; snapshots are the history source of truth.
- Keep MVP exclusions out: no POS/cart, reports, accounting, supplier, login, cloud sync, barcode scanner, movement editing, movement deletion, export, or reason filtering.
- Use simple English with Filipino-friendly clarity. Good examples: `Stock In`, `Stock Out`, `Stock changes will appear here.`, `We couldn't load history. Please try again.`

### Files Expected To Change

- `tindatrack/lib/features/history/presentation/screens/movement_history_screen.dart`
- `tindatrack/lib/features/history/presentation/providers/movement_history_providers.dart` (new, if provider split is useful)
- `tindatrack/test/features/history/presentation/screens/movement_history_screen_test.dart` (new)
- `_bmad-output/implementation-artifacts/3-6-show-inventory-history-list.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

### Testing Requirements

- Follow existing widget test style from stock screens: fake repositories, `ProviderScope` overrides, `MaterialApp`, stable widget keys, and assertions that private/debug text is not visible.
- Add stable keys for important History elements, for example `history-screen`, `history-list`, `history-empty-state`, and per-row keys based on movement ID if practical.
- Use fake `StockRepository.watchMovementHistory()` streams for screen tests; implement unused mutation methods with `UnimplementedError` in the fake.
- Include at least one Stock In and one Stock Out row in tests.
- Include a Stock Out row with a non-default reason in test data so reason availability does not break rendering, while verifying no filter/selector is required.
- Include a movement whose `productNameSnapshot` differs from a hypothetical current product name to prove the widget uses snapshots only.
- Verify empty and error states use friendly copy and do not expose raw SQL/Drift/debug messages.

### Previous Story Intelligence

- Story 3.5 completed the Stock Out screen and marked product-row action activation as deferred to Story 3.7. Do not add Stock In/Stock Out row actions here.
- Story 3.5 added router support for Stock Out and focused tests around route mapping; History route already exists and should remain the third bottom-navigation branch.
- Story 3.4 and 3.5 established screen patterns for `AppLoadingView`, `AppErrorView`, `AppEmptyState`-style presentation, stable keys, safe user copy, and local verification from a Windows temp copy when Flutter cannot run from the UNC path.
- Story 3.3 completed atomic Stock Out repository behavior and movement snapshots; Story 3.6 should consume those snapshots rather than rebuilding stock mutation logic.
- Story 3.1 established `StockMovement` domain and DAO/repository history APIs. Reuse them instead of creating a History-specific data model unless a small presentation view model materially simplifies formatting.

### Latest Technical Notes

- Current package versions are already pinned in `tindatrack/pubspec.yaml`: `go_router ^17.3.0`, `flutter_riverpod ^3.3.2`, `drift ^2.34.0`, and Dart SDK `^3.12.0`.
- No dependency upgrade or web research is needed for this story; use existing Flutter/Riverpod/Drift APIs.
- For date/time display, prefer a small local formatting helper using the Dart standard library to avoid adding `intl` unless the project already has it. Keep output readable and deterministic in tests.

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- 2026-07-11: Created Story 3.6 context from Epic 3, UX, architecture, existing history placeholder, StockRepository history APIs, and Story 3.1-3.5 implementation learnings.
- 2026-07-11: Implemented movement history provider, read-only History list UI, and focused widget coverage.
- 2026-07-11: Focused History tests passed on local verification copy: 4/4.
- 2026-07-11: Dart analyzer passed on local verification copy with no issues.
- 2026-07-11: Full Flutter test suite passed on local verification copy: 298/298.

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.
- Added movement history provider backed by StockRepository.watchMovementHistory().
- Replaced History placeholder with read-only newest-first movement list, empty state, loading state, safe error state, and row formatting for type, snapshots, quantity delta, previous/new quantity, date/time, and notes.
- Added focused History screen tests for populated, empty, error, snapshot/read-only, and scrollable many-row behavior.
- Updated root widget tests to stub movement history data when exercising app-shell navigation.

### File List

- _bmad-output/implementation-artifacts/3-6-show-inventory-history-list.md
- _bmad-output/implementation-artifacts/sprint-status.yaml
- tindatrack/lib/features/history/presentation/providers/movement_history_providers.dart
- tindatrack/lib/features/history/presentation/screens/movement_history_screen.dart
- tindatrack/test/features/history/presentation/screens/movement_history_screen_test.dart
- tindatrack/test/widget_test.dart

### Change Log

- 2026-07-11: Created Story 3.6 artifact and marked it ready for dev.
- 2026-07-11: Implemented Inventory History list and moved story to review.