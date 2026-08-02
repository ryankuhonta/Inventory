---
baseline_commit: 3e7e3dce7400122c33c604844cb9982d98e2d2a1
---

# Story 2.8: Prepare Product Row Action Pattern

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a store helper,
I want product rows to expose clear and accessible actions,
so that I can edit products quickly and have a consistent place for future stock actions.

## Acceptance Criteria

1. **Given** an active product row is displayed
   **When** the user views available actions
   **Then** Edit is available from the row or an accessible row action pattern
   **And** the action is easy to tap on small Android screens.

2. **Given** the user taps Edit
   **When** the action is selected
   **Then** the app opens the Edit Product flow for that product
   **And** the selected product identity is preserved.

3. **Given** Stock In and Stock Out flows are not implemented until Epic 3
   **When** Product Catalog work is completed
   **Then** the product row may reserve layout or component structure for future stock actions
   **And** Stock In and Stock Out actions are not active, fake, disabled placeholders, or routed from Epic 2.

4. **Given** archived products are hidden from the default active product list
   **When** product row actions are displayed
   **Then** archived products do not expose Edit or future stock actions from the active list.

## Tasks / Subtasks

- [x] Task 1: Establish one reusable active-row action boundary (AC: #1, #3, #4)
  - [x] Add `ProductRowActions` under `features/products/presentation/widgets`; keep it presentation-only and independent of Riverpod, Drift, repositories, and routing.
  - [x] Give the component only the real Edit callback and the product identity/name needed for stable keys and accessible copy.
  - [x] Render a visible Edit icon/action with an explicit tooltip or semantic label such as `Edit <product name>` and a minimum 48x48 logical-pixel hit target.
  - [x] Keep the real Edit affordance mounted but disabled when its callback is temporarily null during guarded navigation, so rows do not reflow.
  - [x] Do not predeclare Stock In/Out callbacks, render disabled icons, add menu entries, add routes, or show "coming soon" controls. Epic 3 will extend the component when those flows exist.
  - [x] Do not place Archive in the row action component; Story 2.7 intentionally keeps Archive on Edit Product behind confirmation.

- [x] Task 2: Integrate Edit without regressing the existing row flow (AC: #1, #2)
  - [x] Update `ProductListItem` to show the row action while preserving product name, category/unit metadata, quantity, stock badge, stable row key, truncation, and current whole-row Edit tap.
  - [x] Keep the informational row semantics and the interactive Edit action as separate accessible nodes. The current `Semantics(excludeSemantics: true)` wrapper must not suppress the new action.
  - [x] Route both the whole-row tap and explicit Edit action through the same `onEdit` callback; one gesture must invoke it exactly once.
  - [x] Keep `_ProductListState._openingProductId` as the single-flight navigation guard so rapid row/action taps cannot stack Edit routes.
  - [x] Continue using `context.pushNamed(ProductRoute.editProduct.name, pathParameters: {'productId': product.id})`; add no route and pass no product object through navigation.
  - [x] Preserve the active product search/filter controller and list scroll/session state when Edit opens and returns.

- [x] Task 3: Protect responsive layout, accessibility, and active-only scope (AC: #1, #3, #4)
  - [x] Keep long product names, long units, two-line quantities, and stock badges readable without horizontal overflow when the action occupies trailing space.
  - [x] Verify the action remains visible, reachable, labeled, and at least 48dp at 360x640 with 2x text.
  - [x] Keep logical focus/semantics order: product information first, then the Edit action; do not produce duplicate or merged action announcements.
  - [x] Preserve lazy list rendering and avoid per-row controllers, providers, global keys, or state objects.
  - [x] Keep archived rows excluded through the existing active-only repository/provider query; do not add archived-list UI, optimistic filtering, or action-level archive checks.

- [x] Task 4: Add focused regression and navigation coverage (AC: #1, #2, #3, #4)
  - [x] Widget-test `ProductRowActions`: visible Edit affordance, stable product-keyed action, explicit accessible label/tooltip, 48dp target, enabled/disabled callback behavior, and exactly one callback invocation.
  - [x] Update `ProductListItem` tests for distinct row-information and Edit-action semantics, retained row tap, long text/2x scaling, stock badge preservation, and absence of Stock In/Out/Archive actions.
  - [x] Update Product List screen tests to satisfy Android and labeled tap-target guidelines with the action present and to prove 3,000-row lazy rendering remains intact.
  - [x] Extend navigation/identity coverage so the explicit action preserves the selected product ID through the shared callback seam, while existing real router/archive coverage proves the product-list route stack remains stable.
  - [x] Preserve the Story 2.7 archive flow: after archive removes a row reactively, no row action for that product remains.
  - [x] Run formatter, analyzer, focused widget/navigation tests, the complete Flutter suite, and WSL `git diff --check`.

### Review Findings

- [x] [Review][Patch] ProductRowActions suppresses the IconButton semantics without adding an activatable semantic tap action [tindatrack/lib/features/products/presentation/widgets/product_row_actions.dart:30]
- [x] [Review][Patch] Explicit Edit action is not covered through the real Edit Product route and product ID path parameters [tindatrack/test/features/products/presentation/screens/product_edit_navigation_flow_test.dart:13]
- [x] [Review][Defer] Edit navigation guard can stay stuck if `pushNamed` throws [tindatrack/lib/features/products/presentation/screens/product_list_screen.dart:279] - deferred, pre-existing

## Dev Notes

### Non-Negotiable Row Action Contract

| Concern | Required behavior |
| --- | --- |
| Current action | Edit only |
| Future seam | A dedicated row-action widget that Epic 3 can extend |
| Stock In/Out | No visible, disabled, fake, or routed controls in Story 2.8 |
| Archive | Remains inside Edit Product; never added to the row |
| Identity | Stable product ID passed through the existing named Edit route |
| Navigation | Whole-row tap and explicit action share one guarded callback |
| Tap target | At least 48x48 logical pixels |
| Semantics | Product information and Edit action remain separately discoverable |
| Active-only scope | Actions exist only for rows emitted by `activeProductsProvider` |
| Performance | Stateless/lightweight row actions; lazy list behavior preserved |

Use a direct Edit affordance rather than an overflow menu containing one real action plus speculative stock actions. A dedicated `ProductRowActions` widget establishes the future extension point without lying to users about unavailable functionality.

### Current Files To Extend

- `tindatrack/lib/features/products/presentation/widgets/product_list_item.dart`
  - Current: renders name, category/unit, quantity, and stock status; the whole `ListTile` invokes `onEdit`.
  - Current accessibility detail: one outer `Semantics` node uses `excludeSemantics: true`, combines row copy, and exposes the row tap.
  - Change: compose the visible Edit action without allowing that outer node to erase the action's semantics.
  - Preserve: current text truncation, two-line quantity safety, status precedence, stable row key, and row tap.
- `tindatrack/lib/features/products/presentation/screens/product_list_screen.dart`
  - Current: `_ProductListState` passes one guarded callback per row and sets `_openingProductId` synchronously before awaiting `pushNamed`.
  - Change: wire the explicit action to that same callback; do not create a second navigation path or guard.
  - Preserve: search/filter state, lazy `ListView.separated`, padding, empty/error/loading states, and Add Product behavior.
- `tindatrack/lib/app/router/app_routes.dart` and `app_router.dart`
  - Current: `ProductRoute.editProduct` already owns `/products/:productId/edit`.
  - Change: none expected.
  - Preserve: named-route identity and the existing Products branch navigator.

Expected new file:

```text
tindatrack/lib/features/products/presentation/widgets/product_row_actions.dart
```

Expected test changes:

```text
tindatrack/test/features/products/presentation/widgets/product_row_actions_test.dart
tindatrack/test/features/products/presentation/widgets/product_list_item_test.dart
tindatrack/test/features/products/presentation/screens/product_list_screen_test.dart
tindatrack/test/features/products/presentation/screens/product_edit_navigation_flow_test.dart
```

Do not modify the database, DAO, repository, domain entity, use case, provider, Edit Product form, app route inventory, or schema for this story unless a failing test proves a genuine integration defect.

### Semantics And Interaction Guardrails

- `Semantics(excludeSemantics: true)` replaces all descendant semantics. Therefore, an `IconButton` nested under the current outer row semantics would be visually present but unavailable to screen readers.
- Refactor the semantic boundary so row information and Edit are separate nodes. Do not solve this by removing all explicit row semantics and accepting fragmented name/category/quantity/status announcements.
- The Edit action needs a textual tooltip/semantic label; an edit icon alone is insufficient.
- Preserve one logical activation per gesture. If a trailing action sits inside a tappable row, verify its tap does not also trigger the row callback.
- Prefer a product-keyed action such as `ValueKey('product-edit-action-${product.id}')` for deterministic list and navigation tests.
- Flutter `IconButton` defaults to `kMinInteractiveDimension` (48dp) when unconstrained, but explicitly test the effective hit region under the app theme and text scaling.
- Keep the action visually compact while retaining its 48dp hit target. Do not shrink the target using custom constraints or dense visual density.

### Navigation And Race Guardrails

- Reuse `_openEditProduct`; do not call `pushNamed` from `ProductRowActions` or `ProductListItem`.
- `_openingProductId` is screen-local, set before the first await, and disables callbacks while a route is opening. Keep that single-flight behavior for row taps, action taps, and mixed rapid taps.
- When this guard nulls `onEdit`, leave the real Edit control in place as disabled; only speculative Stock In/Out placeholders are forbidden.
- Keep the stable route call:

```dart
context.pushNamed(
  ProductRoute.editProduct.name,
  pathParameters: <String, String>{'productId': productId},
);
```

- Do not reset or invalidate `productListControllerProvider` or `activeProductsProvider` when navigating.
- Do not add Stock In/Out routes early. Architecture mentions future stock routes, but the story acceptance criteria explicitly defer active stock actions until Epic 3.

### Previous Story Intelligence

- Story 2.6 established the Edit route, ID-keyed load/controller state, whole-row Edit entry point, and `_openingProductId` guard. Preserve its rapid-tap protection and query-preserving navigation tests.
- Story 2.7 added Archive only to Edit Product, kept archived products out of the watched active list, and proved reactive row removal without provider invalidation.
- Story 2.7 review fixes require terminally unavailable products to reject repeated mutations, long-text accessibility to remain safe, and screen-reader announcements to avoid duplication.
- The current verified baseline after Story 2.7 is 226 passing tests, clean Dart analysis, and clean WSL `git diff --check`.
- Do not move Archive to the row, expose archived rows, or add future stock behavior while creating the action seam.

### Git And Workspace Constraints

- Current branch: `codex/complete-stories-1-1-and-1-2`.
- Current committed HEAD: `4299867cc1451d23822a3cc2d01a44c81fd57fbd` (`Complete product editing and review fixes`).
- The WSL working tree currently contains intentional, uncommitted Story 2.7 implementation/review changes and existing handoff artifacts. Story 2.8 implementation must not overwrite, reset, clean, stage, or silently absorb them.
- Before beginning `dev-story` for 2.8, establish an intentional Story 2.7 commit/baseline in a separately authorized Git workflow; otherwise Story 2.8 review diffs will be mixed with Story 2.7.
- WSL `\\wsl.localhost\Ubuntu\home\rkuhonta\Inventory` remains authoritative. The established Windows verification mirror is `C:\tmp\inventory-story21`.
- Story creation does not authorize staging, committing, pushing, dependency upgrades, or Story 2.8 implementation.

### Library And Framework Requirements

- Repository-locked versions are authoritative: Flutter 3.44.0, Dart 3.12.0, `go_router ^17.3.0`, `flutter_riverpod ^3.3.2`, and `very_good_analysis ^10.2.0`.
- Add no package. This is a Material widget composition and existing go_router integration change.
- `go_router 17.3.0` supports the existing named-route and `pathParameters` pattern; reuse it rather than passing a domain object as route state.
- Current Flutter documentation states that tappable `ListTile` trailing widgets must be at least 48x48 and that trailing width must be constrained deliberately.

Official references:

- [Flutter IconButton constraints](https://api.flutter.dev/flutter/material/IconButton/constraints.html)
- [Flutter ListTile accessibility guidance](https://api.flutter.dev/flutter/material/ListTile-class.html)
- [Flutter Semantics.excludeSemantics](https://api.flutter.dev/flutter/widgets/Semantics/excludeSemantics.html)
- [go_router 17.3.0 named routes](https://pub.dev/documentation/go_router/latest/topics/Named%20routes-topic.html)

### Scope Boundaries

Do not implement Stock In, Stock Out, stock movement/history persistence, stock routes, disabled stock placeholders, Archive row actions, Restore, hard delete, product detail, archived-product browsing, schema/migrations, dashboard changes, scanner functionality, cloud/login/API, ads, POS, suppliers, accounting, reports, localization, or dependency upgrades.

### Testing Baseline And Quality Gate

- Baseline after Story 2.7: 226 passing Flutter tests, clean Dart analysis, clean WSL `git diff --check`.
- Mirror every new/changed `lib/features/products/presentation/...` widget path under `test/features/products/presentation/...`.
- Use exact callback counts, product-keyed finders, route URI/path-parameter assertions, and semantics finders. Avoid proving identity only through visible product copy.
- Test row tap and explicit Edit action independently, then test mixed rapid activation against the one-route guard.
- At 360x640 and 2x text, assert no overflow, action visibility, effective 48dp size, and Android/labeled tap-target guidelines.
- Preserve the 3,000-product lazy-build regression; the action widget must not cause eager row construction.
- Run focused tests first, then the complete suite. Do not claim completion from focused tests alone.

### Project Structure Notes

- Row actions remain feature-local under `features/products/presentation/widgets`; they are not shared `core` UI because no second feature consumes the pattern yet.
- Presentation continues to depend on domain entities, but the action widget must not depend on data/core-database layers.
- No `project-context.md` exists.
- Architecture's future Stock In/Out route examples do not override the explicit Epic 2 deferral in Story 2.8.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.8: Prepare Product Row Action Pattern]
- [Source: _bmad-output/planning-artifacts/epics.md#Epic 2: Product Catalog Management]
- [Source: _bmad-output/planning-artifacts/epics.md#Additional Requirements]
- [Source: _bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#Functional Requirements]
- [Source: _bmad-output/planning-artifacts/architecture.md#Frontend Architecture]
- [Source: _bmad-output/planning-artifacts/architecture.md#Non-Negotiable Consistency Rules]
- [Source: _bmad-output/planning-artifacts/architecture.md#Query And List Patterns]
- [Source: _bmad-output/planning-artifacts/architecture.md#Architectural Boundaries]
- [Source: _bmad-output/planning-artifacts/architecture.md#UX Flow Boundaries]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Product Row]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Product List]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Interaction Primitives]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Accessibility Floor]
- [Source: _bmad-output/implementation-artifacts/2-7-archive-product-without-deleting-history.md]
- [Source: tindatrack/lib/features/products/presentation/widgets/product_list_item.dart]
- [Source: tindatrack/lib/features/products/presentation/screens/product_list_screen.dart]
- [Source: tindatrack/lib/app/router/app_routes.dart]
- [Source: tindatrack/lib/app/router/app_router.dart]

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Implementation Plan

- Follow red-green-refactor per task, beginning with focused widget and navigation regressions.
- Keep `ProductRowActions` presentation-only and compose it beside, not inside, the row-information semantics boundary.
- Reuse the existing guarded `onEdit` callback and named product-ID route without introducing state or routing dependencies.

### Debug Log References

- Task 1 RED: focused test failed because `product_row_actions.dart` did not exist.
- Task 1 GREEN: 3 focused action tests and the complete 229-test Flutter suite passed in the Windows verification mirror.
- Task 2 RED: Product List Item tests failed because no explicit action or separate action semantics existed.
- Task 2 GREEN: 7 row tests, 9 Product List screen tests, and the complete 229-test Flutter suite passed.
- Task 3 RED: responsive/action assertions initially failed with the absent pre-Task-2 row action.
- Task 3 GREEN: 16 focused responsive/list tests and the complete 229-test Flutter suite passed.
- Task 4 RED: full-router explicit-action probes exposed Flutter test harness hangs around action-driven route pumping; coverage was split to focused action identity plus existing real router/archive flow.
- Task 4 GREEN: focused Story 2.8 tests, clean Dart analysis, complete 229-test Flutter suite, and WSL `git diff --check` passed.

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.
- Task 1: Added the stateless Edit-only row-action boundary with stable product key, explicit accessible copy, a 48dp target, and mounted disabled behavior.
- Task 2: Composed Edit beside the row-information semantics boundary; row and action share the existing guarded callback and named ID route.
- Task 3: Protected long text, stock badges, separate information/action semantics, 48dp reachability at 360x640 and 2x text, and 3,000-row lazy rendering.
- Task 4: Added focused regression coverage for action identity/callback behavior, preserved archive row removal coverage, ran formatter/analyzer/focused tests/full Flutter suite, and cleaned WSL diff whitespace.

### File List

- `_bmad-output/implementation-artifacts/2-8-prepare-product-row-action-pattern.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `tindatrack/lib/features/products/presentation/widgets/product_row_actions.dart`
- `tindatrack/test/features/products/presentation/widgets/product_row_actions_test.dart`
- `tindatrack/lib/features/products/presentation/widgets/product_list_item.dart`
- `tindatrack/lib/features/products/presentation/screens/product_list_screen.dart`
- `tindatrack/test/features/products/presentation/widgets/product_list_item_test.dart`
- `tindatrack/test/features/products/presentation/screens/product_list_screen_test.dart`
- `tindatrack/test/features/products/presentation/screens/product_edit_navigation_flow_test.dart`
- `tindatrack/test/features/products/presentation/screens/product_archive_navigation_flow_test.dart`

### Change Log

- 2026-07-06: Created comprehensive Story 2.8 context and marked it ready for development.
- 2026-07-07: Implemented Edit-only product row action pattern and moved Story 2.8 to review after formatter, analyzer, focused tests, full Flutter suite, and WSL diff check passed.
