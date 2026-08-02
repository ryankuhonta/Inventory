---
baseline_commit: c2515545179a0b198ba64a57149baf739e351c49
---

# Story 2.5: Show Low-Stock And Out-of-Stock Product Status

Status: done

## Story

As a store owner,
I want products to clearly show low-stock and out-of-stock states,
so that I know what needs attention.

## Acceptance Criteria

1. **Given** a product quantity is equal to or below its low-stock threshold
   **When** the product appears in the product list
   **Then** it is marked as Low Stock
   **And** the status uses text or label copy, not color alone.

2. **Given** a product quantity is zero
   **When** the product appears in the product list
   **Then** it is marked as Out of Stock
   **And** Out of Stock visually overrides Low Stock.

3. **Given** products are filtered by Low Stock or Out of Stock
   **When** the user changes product quantities through valid flows later
   **Then** the status calculation is based on current local product data
   **And** no manual status flag is required.

## Tasks / Subtasks

- [x] Task 1: Add one domain-owned derived stock-status contract (AC: #1, #2, #3)
  - [x] Define mutually exclusive `inStock`, `lowStock`, and `outOfStock` states under `features/products/domain`.
  - [x] Derive status only from current `Product.quantity` and `Product.lowStockThreshold`; never persist or cache it.
  - [x] Apply precedence exactly: zero -> Out of Stock; positive quantity at/below threshold -> Low Stock; otherwise -> in stock.
  - [x] Test zero, equality, below threshold, above threshold, and zero-threshold boundaries.
- [x] Task 2: Build a reusable product stock badge (AC: #1, #2)
  - [x] Render exact `Low Stock` or `Out of Stock` copy and no warning for normal stock.
  - [x] Reuse warning/danger foreground and surface tokens and `statusPillRadius`.
  - [x] Keep it lightweight, Material 3, readable at system text scaling, and available to assistive technology.
- [x] Task 3: Integrate status into `ProductListItem` (AC: #1, #2, #3)
  - [x] Consume the domain status and display at most one badge.
  - [x] Add status to the existing combined row semantics label.
  - [x] Preserve name, metadata, quantity, stable row keys, read-only behavior, and 360px/2x-text safety.
  - [x] Preserve all Story 2.3/2.4 list, search, filter, async-state, retry, and Add behavior.
- [x] Task 4: Prove status, accessibility, and reactivity (AC: #1, #2, #3)
  - [x] Extend domain and widget tests for the full truth table, colors, exact copy, semantics, and layout.
  - [x] Prove mixed rows classify independently and zero-stock rows remain visible.
  - [x] Prove current data above-threshold -> threshold -> zero renders none -> Low Stock -> Out of Stock without restart or manual status.
  - [x] Preserve disjoint Story 2.4 filters: Low Stock is `quantity > 0 && quantity <= threshold`; Out of Stock is `quantity == 0`.
  - [x] Run formatter, analyzer, focused tests, and the full Flutter suite in the mirror; audit the WSL diff.

### Review Findings

- [x] [Review][Patch] Reject NUL-containing search text before SQLite `LIKE` can broaden the match unexpectedly [tindatrack/lib/core/database/daos/products_dao.dart:49]
- [x] [Review][Patch] Clear the fired debounce timer reference when its callback begins [tindatrack/lib/features/products/presentation/controllers/product_list_controller.dart:29]
- [x] [Review][Patch] Share one stock-status label mapping between visible badge copy and merged row semantics [tindatrack/lib/features/products/presentation/widgets/product_list_item.dart:19]

## Dev Notes

### Status Contract

| Current quantity | Derived status | Row label |
| --- | --- | --- |
| `0` | `outOfStock` | `Out of Stock` |
| `> 0` and `<= threshold` | `lowStock` | `Low Stock` |
| `> threshold` | `inStock` | none |

Zero satisfies the broad numeric low-stock rule but has explicit Out of Stock precedence. Never render both labels. Keep this display contract aligned with Story 2.4's already-disjoint DAO predicates; do not change filter semantics.

### Current Files To Update

- `tindatrack/lib/features/products/domain/entities/product.dart`
  - Current: immutable, Drift-independent entity with `quantity` and `lowStockThreshold`.
  - Change: expose derived status here or through one adjacent domain extension/value.
  - Preserve: constructor and persisted fields; no stored status.
- `tindatrack/lib/features/products/presentation/widgets/product_list_item.dart`
  - Current: read-only `ListTile` shows name, category-or-unit, quantity, and manually composed merged semantics.
  - Change: render one badge and append its label to parent semantics.
  - Preserve: null-category behavior, `onTap == null`, overflow safety, and `Semantics(container: true, excludeSemantics: true)`.
- `tindatrack/test/features/products/domain/product_domain_test.dart`
  - Add the status boundary matrix, or use a dedicated mirrored test if status is a new file.
- `tindatrack/test/features/products/presentation/widgets/product_list_item_test.dart`
  - Extend existing key/content/semantics/read-only/2x-text tests.
- `tindatrack/lib/features/products/presentation/screens/product_list_screen.dart`
  - Expected production change: none. Preserve search, three chips, async branches, FAB, lazy list, and stable row keys.
- `tindatrack/lib/app/theme/app_colors.dart` and `tindatrack/lib/core/ui/app_dimensions.dart`
  - Change: none. Reuse `warning`, `warningSurface`, `danger`, `dangerSurface`, and `statusPillRadius`.

Possible new files, only if they prevent duplication:

```text
tindatrack/lib/features/products/domain/entities/product_stock_status.dart
tindatrack/lib/features/products/presentation/widgets/stock_badge.dart
tindatrack/test/features/products/domain/entities/product_stock_status_test.dart
tindatrack/test/features/products/presentation/widgets/stock_badge_test.dart
```

Do not create both a calculator and widget-side threshold conditions. One domain truth is required.

### Architecture And Regression Guardrails

- Preserve dependency direction `presentation -> domain -> data -> core database`; widgets never access Drift/DAOs.
- Drift watched queries remain the local source and reactivity trigger. Derivation is O(1) per rendered row.
- No status column, schema version, migration, generated file, repository/provider cache, or dependency change.
- No quantity mutation. Later `features/stock` use cases own all post-creation stock changes.
- Archived products stay excluded; active products stay name-ordered; lazy rendering must still support 3,000 products.
- Story 2.4 is done with 154/154 tests, clean analysis, and clean `git diff --check`.
- Preserve its 1,000-character search cap, remount synchronization, normalized query equality, duplicate-name behavior, watched quantity/archive re-emission, and app-session query state.
- Story 2.3 fixed merged row semantics and long-unit/2x-text layout; extend those fixes.

### UX And Accessibility Guardrails

- Exact copy is `Low Stock` and `Out of Stock`.
- Low Stock uses `AppColors.warning` on `warningSurface`; Out of Stock uses `danger` on `dangerSurface`.
- Use a compact status pill, not a card, dialog, banner, or action.
- Normal rows get no noisy `In Stock` badge.
- Status remains visible without opening details and never replaces quantity.
- Because the row excludes child semantics, explicitly include status in the parent label.
- Prefer wrapping/natural height over clipping, fixed widths, horizontal scrolling, or smaller text.
- The badge is informational, not interactive; do not add fake tap behavior for the 48dp action-target rule.

### Library And Latest Technical Information

Locked versions are authoritative: Dart `^3.12.0`, Drift/drift_dev `2.34.0`, drift_flutter `0.3.0`, flutter_riverpod/riverpod `3.3.2`, go_router `17.3.0`, very_good_analysis `10.2.0`. No upgrade or package is needed.

Flutter `Semantics.excludeSemantics` supports replacing child semantics with the deliberate row label. `Wrap` creates another run when content does not fit, appropriate for narrow screens and enlarged text.

- [Flutter Semantics](https://api.flutter.dev/flutter/widgets/Semantics-class.html)
- [Flutter Semantics.excludeSemantics](https://api.flutter.dev/flutter/widgets/Semantics/excludeSemantics.html)
- [Flutter Wrap](https://api.flutter.dev/flutter/widgets/Wrap-class.html)

### Git And Workspace Constraints

- Branch: `codex/complete-stories-1-1-and-1-2`; HEAD: `c2515545179a0b198ba64a57149baf739e351c49`.
- Story 2.4 is intentionally unstaged/uncommitted. Preserve the full dirty tree and intentional untracked files.
- WSL is authoritative; use `C:\tmp\inventory-story21` for Flutter commands and copy only Story 2.5-changed files.
- Do not reset, clean, stage, commit, push, or modify/remove temporary Story 2.1/2.2 prompts/handoffs or the Story 2.4 handoff.

### Scope Boundaries

Do not implement persisted status, schema/generated/repository writes, Stock In/Out, history, dashboard summaries/navigation, edit/archive/row actions, `In Stock` badges, dual warnings, notifications, scanning, login/cloud/API, ads, POS, suppliers, accounting, reports, localization, or dependencies.

### Testing Requirements

- Domain: zero with zero/positive thresholds; equality above zero; positive below threshold; above threshold; positive quantity with zero threshold.
- Badge/row: exact copy/tokens, one warning only, none for normal, quantity/metadata retained, status exactly once in merged semantics, 360x640 at 2x text.
- List/reactivity: mixed independent states, zero-stock visibility, current-data re-emission, unchanged filter membership.
- Regression: loading/content/empty/no-match/error, controls, retry, Add routing, lazy 3,000 rows, safe copy, format, analysis, focused tests, full suite.

### Project Structure Notes

- Product-specific status logic stays under features/products, not core; tests mirror lib/.
- Presentation imports domain status and shared UI tokens only; it never imports Drift or DAO types.
- No project-context.md exists. This story, planning artifacts, Story 2.4, current code, and locked dependencies are authoritative.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.5: Show Low-Stock And Out-of-Stock Product Status]
- [Source: _bmad-output/planning-artifacts/epics.md#Additional Requirements]
- [Source: _bmad-output/planning-artifacts/epics.md#UX Design Requirements]
- [Source: _bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#AC-006: Low Stock]
- [Source: _bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#Edge Cases]
- [Source: _bmad-output/planning-artifacts/architecture.md#Test And Migration Gates]
- [Source: _bmad-output/planning-artifacts/architecture.md#Communication Patterns]
- [Source: _bmad-output/planning-artifacts/architecture.md#Query And List Patterns]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Status Badge]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Product List]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Low Stock]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Accessibility Floor]
- [Source: _bmad-output/implementation-artifacts/2-4-search-and-filter-products.md]
- [Source: tindatrack/lib/features/products/domain/entities/product.dart]
- [Source: tindatrack/lib/features/products/domain/entities/product_list_query.dart]
- [Source: tindatrack/lib/features/products/presentation/screens/product_list_screen.dart]
- [Source: tindatrack/lib/features/products/presentation/widgets/product_list_item.dart]
- [Source: tindatrack/lib/app/theme/app_colors.dart]
- [Source: tindatrack/lib/core/ui/app_dimensions.dart]

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

### Implementation Plan

- Task 1: establish a zero-first immutable domain status and boundary tests.
- Task 2: add a token-driven informational badge with focused widget tests.
- Task 3: integrate one derived badge into ProductListItem and merged semantics.
- Task 4: prove mixed-list and reactive status transitions, then run full quality gates.

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.
- Task 1 complete: added the derived three-state status contract; 6 focused tests and the 160-test full suite pass.
- Task 2 complete: added the token-driven informational badge; 3 focused tests and the 163-test full suite pass.
- Task 3 complete: integrated one derived badge into each row and merged semantics; 6 focused tests and the 166-test full suite pass.
- Task 4 complete: mixed-list and reactive status proofs pass; 24 focused tests, 168/168 full suite, clean analysis, and clean diff validation.
- Code review complete: fixed all 3 actionable findings; 21 focused tests and the 169/169 full suite pass with clean analysis and diff validation.

### File List

- `_bmad-output/implementation-artifacts/2-5-show-low-stock-and-out-of-stock-product-status.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `tindatrack/lib/core/database/daos/products_dao.dart`
- `tindatrack/lib/features/products/presentation/controllers/product_list_controller.dart`
- `tindatrack/test/core/database/daos/products_dao_search_filter_test.dart`
- `tindatrack/lib/features/products/domain/entities/product_stock_status.dart`
- `tindatrack/lib/features/products/presentation/widgets/product_list_item.dart`
- `tindatrack/lib/features/products/presentation/widgets/stock_badge.dart`
- `tindatrack/test/features/products/domain/entities/product_stock_status_test.dart`
- `tindatrack/test/features/products/presentation/screens/product_list_screen_test.dart`
- `tindatrack/test/features/products/presentation/widgets/product_list_item_test.dart`
- `tindatrack/test/features/products/presentation/widgets/stock_badge_test.dart`

## Change Log

- 2026-07-01: Implemented derived low/out-of-stock status, accessible token-driven badges, reactive product-row rendering, and full regression coverage; moved story to review.
- 2026-07-02: Completed adversarial code review, fixed all actionable findings, and moved Story 2.5 to done.
