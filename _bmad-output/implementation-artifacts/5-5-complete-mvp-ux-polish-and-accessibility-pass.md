---
baseline_commit: d493eea470c16a9f8f649c60cf94d22253c89830
---

# Story 5.5: Complete MVP UX Polish And Accessibility Pass

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a store owner or helper,
I want the app to feel clear, readable, and forgiving,
so that I can use it confidently during daily store work.

## Acceptance Criteria

1. Given all MVP screens are available, when Dashboard, Products, Add Product, Edit Product, Stock In, Stock Out, History, and Settings are reviewed, then copy is plain, helpful, and Filipino-friendly English, and technical words like raw database errors, "entity," or "inventory mutation" are not shown to users.
2. Given common UI states are reviewed, when loading, empty, error, validation, and success states appear, then each state gives clear feedback or a next step, and messages are consistent with the approved UX tone.
3. Given accessibility is reviewed, when common controls and warning states are inspected, then tap targets follow the 48dp floor where applicable, and warnings do not rely on color alone.
4. Given core operational flows are reviewed, when Add Product, Edit Product, Stock In, and Stock Out are used, then no ads, login prompts, cloud prompts, or monetization interruptions appear, and actions remain focused on local inventory work.

## Tasks / Subtasks

- [x] Task 1: Audit and polish user-facing copy across MVP screens (AC: 1, 2, 4)
  - [x] Review Dashboard, Products, Add Product, Edit Product, Stock In, Stock Out, History, and Settings visible copy.
  - [x] Remove or prevent user-visible technical wording such as raw SQL/Drift/database diagnostics, exception text, "entity," "inventory mutation," "remote API," or other developer terms.
  - [x] Keep copy plain, helpful, and action-oriented; prefer approved terms such as `Add Product`, `Record Stock In`, `Record Stock Out`, `Low Stock`, `Out of Stock`, `Not enough stock available`, and `Saved`.
  - [x] Preserve established Settings copy from Stories 5.1-5.4, including PHP currency context, honest Backup / Export copy, local-device/no-account/no-internet wording, and `pubspec.yaml` app version display.
  - [x] Do not add ads, login, cloud sync prompts, monetization, analytics, remote config, network behavior, or future-feature routes.

- [x] Task 2: Polish common UI states and next-step behavior (AC: 2, 4)
  - [x] Reuse shared state widgets in `tindatrack/lib/core/widgets/app_empty_state.dart`, `app_error_view.dart`, and `app_loading_view.dart` where appropriate.
  - [x] Ensure loading, empty, error, validation, and success states use friendly recovery or next-step copy and never expose raw diagnostics.
  - [x] Verify Dashboard empty state behavior: if an "Add your first product" action is visible, it must navigate to Add Product or be made non-actionable with honest copy.
  - [x] Preserve retry provider invalidation behavior on Dashboard, Products, History, and product/stock unavailable states.
  - [x] Preserve save/confirm flow behavior: forms dismiss keyboard on save, prevent duplicate submits while saving, and show button-level progress.

- [x] Task 3: Improve accessibility and screen-reader clarity where gaps are found (AC: 3)
  - [x] Keep Material 3, `AppSpacing`, `AppDimensions`, 8dp component radii, and `AppDimensions.minimumTapTarget` patterns.
  - [x] Confirm common tappable controls meet the 48dp floor, especially product row actions, dashboard actions, bottom navigation, Settings sections if made tappable, and form submit buttons.
  - [x] Confirm low-stock/out-of-stock warnings are label-based, not color-only; preserve `StockBadge` visible labels and semantics.
  - [x] Add or refine semantics where rows are fragmented for assistive tech, especially History movement rows.
  - [x] Keep screens usable at small phone dimensions and high system text scaling; prefer scrollable layouts and wrapping over fixed-width text assumptions.

- [x] Task 4: Preserve operational flow boundaries and existing behavior (AC: 1-4)
  - [x] Preserve the four-tab app shell: Dashboard, Products, History, Settings.
  - [x] Preserve Products search/filter behavior, search length limiting, filter-chip state, and product row navigation guards.
  - [x] Preserve Add/Edit Product validation, focus-first-invalid behavior, scroll-to-invalid behavior, numeric keyboard types, and no direct post-creation quantity editing.
  - [x] Preserve Stock In/Out digits-only quantity input, 9-character quantity limit, product refresh invalidations, friendly success messages, and no stock movement without a valid active product.
  - [x] Preserve History as read-only and newest-first.
  - [x] Preserve all stable keys used by existing widget tests unless there is a strong reason and tests are updated intentionally.

- [x] Task 5: Add focused UX/accessibility regression coverage (AC: 1-4)
  - [x] Add or update tests that scan visible text across MVP screens for forbidden technical/MVP-exclusion terms.
  - [x] Add or update tests for small phone/high text scale coverage on any screen that changes.
  - [x] Add or update tests for 48dp tap targets and semantics using existing patterns from `app_state_views_test.dart`, `product_row_actions_test.dart`, and screen tests.
  - [x] Add or update tests for warnings not relying on color alone, reusing `stock_badge_test.dart` patterns when relevant.
  - [x] Add or update tests for Dashboard first-product empty action behavior if changed.

- [x] Task 6: Verify Story 5.5 completion (AC: 1-4)
  - [x] Run Dart format for touched `lib` and `test` files.
  - [x] Run focused tests for touched screens/widgets.
  - [x] Run `dart analyze`.
  - [x] Run the full Flutter test suite if focused tests and analyzer pass.
  - [x] Run `git diff --check`.


### Review Findings

- [x] [Review][Patch] Guardrail omits required forbidden terms [tindatrack/test/ux/mvp_visible_copy_guardrail_test.dart:127]
- [x] [Review][Patch] Copy guardrail scans source literals instead of visible screen text [tindatrack/test/ux/mvp_visible_copy_guardrail_test.dart:93]

## Dev Notes

### Source Requirements

- Story 5.5 covers NFR-006, NFR-007, NFR-008, UX-DR25, UX-DR26, UX-DR27, UX-DR28, UX-DR29, and UX-DR30. [Source: `_bmad-output/planning-artifacts/epics.md#Story 5.5: Complete MVP UX Polish And Accessibility Pass`]
- The MVP must be offline-first, readable on low-end Android devices, and beginner-friendly. [Source: `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#9. Non-Functional Requirements`]
- User experience requirements require plain labels, friendly actionable empty/error states, light visual treatment, one-handed Android tap targets, and no unnecessary clutter. [Source: `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#7. User Experience Requirements`]
- Monetization constraints prohibit ads inside Add Product, Edit Product, Stock In, or Stock Out flows. [Source: `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#13. Monetization Requirements And Ideas`; `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/addendum.md#Monetization Notes`]
- Approved voice uses plain, helpful, action-oriented English and avoids "Inventory mutation", "Entity", raw constraint failures, and similar technical terms. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Voice And Tone`]
- State patterns require lightweight loading, actionable empty states, plain recovery text, retry for initialization/data loading failures, and no raw database/exception messages. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#State Patterns`; `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Feedback`]
- Accessibility floor requires 48dp minimum tap targets, readable text at system font scaling, input labels, field-associated error messages, non-color-only warnings, and no motion-only feedback. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Accessibility Floor`]

### Current System State

- Existing MVP screens are implemented under:
  - `tindatrack/lib/features/dashboard/presentation/screens/dashboard_screen.dart`
  - `tindatrack/lib/features/products/presentation/screens/product_list_screen.dart`
  - `tindatrack/lib/features/products/presentation/screens/add_product_screen.dart`
  - `tindatrack/lib/features/products/presentation/screens/edit_product_screen.dart`
  - `tindatrack/lib/features/stock/presentation/screens/stock_in_screen.dart`
  - `tindatrack/lib/features/stock/presentation/screens/stock_out_screen.dart`
  - `tindatrack/lib/features/history/presentation/screens/movement_history_screen.dart`
  - `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart`
- Shared empty, error, and loading presentations already live in `tindatrack/lib/core/widgets` and are scrollable with friendly copy inputs.
- `StockBadge` already exposes visible `Low Stock` and `Out of Stock` labels and semantics, so warnings are not purely color-based today.
- Add/Edit Product and Stock In/Out screens already use scrollable forms, inline field errors, numeric keyboard types where required, button-level saving labels, and duplicate-submit prevention.
- Product list already preserves search state, filter chips, a length-limited search field, and an `_openingProductId` guard while opening row routes.
- History is read-only and newest-first, but movement rows currently present text as separate fragments; merged row semantics may improve screen-reader readability.
- Dashboard empty state currently needs careful review: if an Add Product call to action appears, ensure it actually opens Add Product or change the copy/action model.

### Architecture Compliance

- Keep feature code in the existing feature folders; shared cross-feature widgets stay in `tindatrack/lib/core/widgets`; shared UI constants stay in `tindatrack/lib/core/ui`; theme/app shell stay in `tindatrack/lib/app`. [Source: `_bmad-output/planning-artifacts/architecture.md#File Organization Patterns`]
- Widgets must not access Drift directly; presentation should continue using Riverpod providers/controllers and typed failure-to-friendly-copy boundaries. [Source: `_bmad-output/planning-artifacts/architecture.md#API & Communication Patterns`; `_bmad-output/planning-artifacts/architecture.md#Implementation Handoff`]
- Dashboard and History remain read-only; stock mutations remain owned by `features/stock`. [Source: `_bmad-output/planning-artifacts/architecture.md#Feature Responsibility Map`]
- MVP structure must not introduce login/signup/account folders, cloud sync folders, POS/cart/checkout, barcode scanner UI/dependencies, remote API client layers, supplier management, or accounting/profit reports. [Source: `_bmad-output/planning-artifacts/architecture.md#MVP Exclusions Enforced By Structure`]
- No Drift schema changes, migrations, Android permissions, network clients, analytics SDKs, ad SDKs, or new release-channel services should be needed for this story.

### UX And Layout Guardrails

- Keep the app calm, practical, direct, readable, and lightweight for low-end Android phones. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Brand & Style`]
- Use the existing light Material 3 visual system with off-white background, white surfaces, grounded green primary actions, amber low-stock warnings, and red destructive/critical states. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Colors`]
- Use Android system typography/Roboto, no viewport-scaled text, no negative letter spacing, and readable small-screen sizing. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Typography`]
- Screens use single-column mobile layouts, 16dp outer padding, 8dp related-control spacing, 16-24dp section spacing, modest 8dp radii, and minimal elevation. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Layout & Spacing`; `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Shapes`]
- Do not add decorative gradients, heavy shadows, nested cards, dark/glossy styling, finance-heavy styling, or image-heavy operational screens. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Do's And Don'ts`; `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Responsive And Platform Notes`]
- Bottom navigation remains fixed to Dashboard, Products, History, and Settings with visible labels. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Bottom Navigation`]

### Suggested Implementation Shape

- Start with test-backed audit before broad UI edits. Prefer narrow fixes to observable UX/accessibility gaps over cosmetic churn.
- Likely high-value updates:
  - Make Dashboard first-product empty CTA navigate to Add Product if it currently looks actionable.
  - Add merged or clearer semantics to History movement rows.
  - Add a cross-screen forbidden-copy regression test for raw technical terms and MVP exclusions.
  - Add focused tap-target or semantics tests only where existing coverage is thin.
  - Add high-text-scale/small-phone coverage only for screens changed in this story.
- Prefer reusing existing widgets and helpers rather than creating a new design system layer.
- Avoid changing shared theme tokens unless a failing accessibility test proves the shared token is the root issue.
- Preserve all existing stable keys and route names unless a test-backed accessibility fix requires a deliberate update.

### Testing Requirements

- Reuse existing test patterns:
  - `tindatrack/test/core/widgets/app_state_views_test.dart` for `tester.ensureSemantics()`, text contrast, Android tap-target guidelines, and 360x640 high-text-scale overflow checks.
  - `tindatrack/test/features/products/presentation/widgets/product_row_actions_test.dart` for icon-button semantics labels and 48dp action sizes.
  - `tindatrack/test/features/products/presentation/widgets/stock_badge_test.dart` for visible warning labels plus semantics.
  - Existing screen tests for Dashboard, Products, Add/Edit Product, Stock In/Out, History, and Settings for small phone/high text scale and raw diagnostic guards.
- If adding app-wide visible-copy scans, keep them deterministic: pump screens with provider overrides or local test fixtures, gather visible `Text`, and assert forbidden terms are absent.
- Include forbidden terms relevant to this story: `entity`, `inventory mutation`, `database`, `sql`, `drift`, `exception`, `stack trace`, `remote api`, `login`, `cloud sync`, `ad`, `premium`, `subscribe`, `pos`, `barcode scanner`, `accounting`.
- Continue running Flutter verification from a Windows temp copy under `C:\tmp` if UNC paths block Flutter tooling.

### Previous Story Intelligence

- Story 5.1 established the Settings screen and stable settings keys while intentionally avoiding providers, persistence, auth, cloud, scanner, POS, supplier, accounting, reporting, and dependency changes.
- Story 5.2 centralized PHP currency display through `CurrencyFormatter.php()` and updated product price surfaces; do not regress PHP copy or formatting.
- Story 5.3 strengthened Backup / Export copy and tests; preserve the no-account/no-internet and local-device wording.
- Story 5.4 added app version display from bundled `pubspec.yaml`; preserve `versionFromPubspec`, the `pubspec.yaml` asset, loading/success behavior, and focused parser test.
- Story 5.4 review fixed version parsing to require the top-level scalar, ignore inline comments, and return `Unavailable` when absent.
- Recent verification pattern: focused widget tests, `dart analyze`, full Flutter suite, and `git diff --check`; Flutter commands should run from a Windows temp copy if UNC paths block tooling.

### Git Intelligence

- `d493eea Complete Story 5.4 code review`
- `92fa01f Implement Story 5.4 app version display`
- `3491f0e Create Story 5.4 app version context`
- `2f3c602 Complete Story 5.3 code review`
- `f69878d Implement Story 5.3 backup export placeholder`

Recent work favors tightly scoped story files, feature-local widget tests, stable user-visible keys, explicit MVP exclusion assertions, and status-only review completion commits.

### Anti-Scope And Regression Guardrails

- Do not add ads, login/account prompts, cloud prompts, analytics, telemetry, remote config, remote API clients, network behavior, Android permissions, Drift schema changes, migrations, or new platform dependencies.
- Do not implement backup/export, barcode scanning, POS/cart/checkout, supplier management, accounting/profit reporting, staff roles, or release-channel services.
- Do not move stock mutation responsibility out of `features/stock`.
- Do not make History or Dashboard mutate inventory data.
- Do not change Product quantity directly in Edit Product.
- Do not remove existing friendly copy or stable keys without updating tests intentionally.
- Do not mark this story complete based on visual inspection only; add focused regression tests for each changed behavior.

### Project Structure Notes

- Story 5.5 is a cross-screen polish/accessibility pass, not a redesign.
- The expected output is a small set of high-confidence UX/accessibility fixes plus regression coverage.
- Story 5.6 owns broader release readiness checks; do not duplicate release packaging/build scope here beyond normal story verification.

## Dev Agent Record

### Agent Model Used

Codex GPT-5

### Debug Log References

- 2026-07-25: Red focused tests failed from `C:\tmp\tindatrack-story-5-5` for Dashboard first-product CTA navigation and History row semantics before production fixes.
- 2026-07-25: Focused Story 5.5 tests passed from `C:\tmp\tindatrack-story-5-5`:
  - `flutter test test/features/dashboard/presentation/screens/dashboard_screen_test.dart test/features/history/presentation/screens/movement_history_screen_test.dart test/ux/mvp_visible_copy_guardrail_test.dart`
- 2026-07-25: `dart analyze` passed from `C:\tmp\tindatrack-story-5-5` with no issues.
- 2026-07-25: Full Flutter test suite passed from `C:\tmp\tindatrack-story-5-5` with 358 tests passing.
- 2026-07-25: git diff --check passed from the workspace.
- 2026-07-25: Code review patches applied; focused tests passed from `C:\tmp\tindatrack-story-5-5-review-fix` and `dart analyze` passed with no issues.

### Completion Notes List

- Audited MVP screen copy and added a widget-level visible-copy guardrail over MVP screens to block technical and out-of-scope terms, including login and ad copy.
- Fixed the Dashboard first-product empty-state action so the visible CTA opens Add Product instead of acting as a no-op.
- Added a consolidated History movement row semantics label so assistive tech hears one clear movement summary, including product, signed quantity, quantity change, date, and note.
- Preserved the four-tab shell, Products search/filter behavior, stock flow boundaries, Settings copy, warnings with visible labels, and existing stable keys.

### File List

- `_bmad-output/implementation-artifacts/5-5-complete-mvp-ux-polish-and-accessibility-pass.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `tindatrack/lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- `tindatrack/lib/features/history/presentation/screens/movement_history_screen.dart`
- `tindatrack/test/features/dashboard/presentation/screens/dashboard_screen_test.dart`
- `tindatrack/test/features/history/presentation/screens/movement_history_screen_test.dart`
- `tindatrack/test/ux/mvp_visible_copy_guardrail_test.dart`

### Change Log

- 2026-07-25: Implemented Story 5.5 MVP UX polish and accessibility pass; marked ready for review.
