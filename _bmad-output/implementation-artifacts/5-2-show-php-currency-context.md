---
baseline_commit: 1e39a1393585e90759fa6afdf96b1f721ecd27db
---

# Story 5.2: Show PHP Currency Context

Status: review

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a store owner in the Philippines,
I want the app to use PHP as the default currency context,
so that product prices feel familiar and clear.

## Acceptance Criteria

1. Given the user opens Settings, when the currency section is displayed, then PHP is shown as the MVP currency context, and no editable multi-currency selector is introduced.
2. Given product prices are displayed elsewhere in the app, when price formatting is used, then formatting follows the centralized PHP currency context, and formatting behavior is consistent across product and settings surfaces.
3. Given future multi-currency support is considered, when MVP settings are reviewed, then the implementation remains simple enough to extend later, and it does not require UI rewrite for future currency options.

## Tasks / Subtasks

- [x] Task 1: Add a centralized PHP currency formatter/context (AC: 2, 3)
  - [x] Create `tindatrack/lib/core/formatters/currency_formatter.dart`; create the `core/formatters` folder if needed.
  - [x] Keep the formatter dependency-free; do not add `intl` or any package for Story 5.2.
  - [x] Expose a small API for the MVP PHP context, such as `CurrencyFormatter.php()` plus constants/fields for code `PHP` and symbol represented in Dart as `\u20B1`.
  - [x] Format non-negative prices consistently for display, with two decimal places and thousands separators.
  - [x] Keep parsing and validation ownership in existing product form/controller code; this story is about display formatting and currency context, not input validation rules.

- [x] Task 2: Update Settings currency copy to consume the centralized context (AC: 1-3)
  - [x] Update `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart`.
  - [x] Preserve `Key('settings-screen')` and `Key('settings-currency-section')`.
  - [x] Continue showing `PHP` as the MVP currency context.
  - [x] Do not add a dropdown, segmented control, editable selector, settings persistence, or `app_settings` Drift schema for currency.
  - [x] Keep the existing local-only Settings screen and four-tab app shell unchanged.

- [x] Task 3: Apply centralized PHP formatting to visible product price surfaces (AC: 2)
  - [x] Find current visible product price surfaces before editing; do not invent new screens.
  - [x] Update product UI labels/help text where useful so price context is clear, for example selling price fields can mention PHP.
  - [x] If a read-only product price is displayed in product rows or other product surfaces, format it through the centralized formatter.
  - [x] Do not change stored numeric values, Drift columns, repository contracts, product validation, or save behavior.
  - [x] Do not introduce cost price, accounting/profit, POS, reporting, supplier, scanner, cloud sync, account, or login behavior.

- [x] Task 4: Add focused formatter and UI tests (AC: 1-3)
  - [x] Add `tindatrack/test/core/formatters/currency_formatter_test.dart`.
  - [x] Test PHP code/symbol context and stable formatting, including zero, whole pesos, centavos, and thousands separators.
  - [x] Update Settings tests to prove the currency section uses the PHP context and still has no editable multi-currency selector.
  - [x] Update product presentation tests for any visible price-context copy or formatted price output changed by this story.
  - [x] Include a small-phone/high-text-scale regression if product or settings visible copy changes could affect layout.

- [x] Task 5: Verify Story 5.2 completion (AC: 1-3)
  - [x] Run Dart format for touched `lib` and `test` files.
  - [x] Run focused currency/settings/product tests.
  - [x] Run `dart analyze`.
  - [x] Run the full Flutter test suite if focused tests and analyzer pass.
  - [x] Run `git diff --check`.

## Dev Notes

### Source Requirements

- Story 5.2 covers FR-038: the app shall show PHP as the default currency context. [Source: `_bmad-output/planning-artifacts/epics.md#Story 5.2: Show PHP Currency Context`; `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#8. Functional Requirements`]
- Epic 5 goal is Settings and release readiness: users can view basic app settings and future backup/export expectations while the MVP receives polish and safeguards. [Source: `_bmad-output/planning-artifacts/epics.md#Epic 5: Settings And Release Readiness`]
- PRD MVP scope includes Settings and local offline persistence; out of scope includes login, online account management, real cloud backup, sales reports, multi-branch management, staff permissions, and push notifications. [Source: `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#6. MVP Scope`]
- Product creation supports selling price; cost price and profit/accounting remain deferred. [Source: `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md#8. Functional Requirements`; `_bmad-output/planning-artifacts/architecture.md#Functional Requirements Coverage`]
- Settings UX content explicitly lists `Currency: PHP`. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Settings`]

### Current System State

- `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart` already renders a local-only Settings screen with a Currency section showing `PHP`.
- There is no `tindatrack/lib/core/formatters` directory yet, although architecture reserves `core/formatters/currency_formatter.dart`.
- Product forms currently label selling price as `Selling price (optional)` and store numeric input as `double`; edit prefill currently uses `product.sellingPrice.toString()`.
- Product list rows currently show product name, category/unit metadata, quantity, status, and row actions; they do not display selling price.
- There is no `intl` dependency in `tindatrack/pubspec.yaml`; Story 5.2 should not add one.
- There is no `app_settings` Drift table in the current codebase. Do not introduce one for a fixed MVP PHP context unless later stories explicitly require persistence.

### Architecture Compliance

- Use Flutter Material 3 and current project dependencies only. [Source: `_bmad-output/planning-artifacts/architecture.md#Project Structure Patterns`]
- Put shared formatter logic under `tindatrack/lib/core/formatters`; feature screens should consume it rather than duplicating currency literals and formatting behavior. [Source: `_bmad-output/planning-artifacts/architecture.md#Project Structure Patterns`]
- Keep Settings under `tindatrack/lib/features/settings`; keep Products under `tindatrack/lib/features/products`; shared UI/constants remain under `tindatrack/lib/core`. [Source: `_bmad-output/planning-artifacts/architecture.md#Feature Responsibility Map`]
- Settings owns local preferences, app info, and honest placeholders only; it must not own product business rules or add login/cloud/POS/accounting scope. [Source: `_bmad-output/planning-artifacts/architecture.md#Feature Responsibility Map`]
- MVP has no external integrations, no login provider, no cloud sync, no barcode scanner, no remote API client, and no ads in save/confirm flows. [Source: `_bmad-output/planning-artifacts/architecture.md#MVP Exclusions Enforced By Structure`; `_bmad-output/planning-artifacts/architecture.md#Integration Points`]
- Do not add Drift schema changes for this story. A fixed PHP currency context can be represented in code without persistence.

### UX And Layout Guardrails

- Keep Settings single-column, calm, practical, and readable for low-end Android phones. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Layout & Spacing`; `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Brand & Style`]
- Primary navigation remains Dashboard, Products, History, Settings; do not add routes or tabs for currency. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Navigation`]
- Use numeric keyboard behavior for price fields and keep forms scrollable for small screens. [Source: `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Interaction Primitives`]
- Keep copy plain and Filipino-friendly. Avoid jargon like currency provider, locale engine, account setup, cloud sync, sales report, margin, or accounting.

### Suggested Implementation Shape

- Add:
  - `tindatrack/lib/core/formatters/currency_formatter.dart`
  - `tindatrack/test/core/formatters/currency_formatter_test.dart`
- Update as needed:
  - `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart`
  - `tindatrack/test/features/settings/presentation/screens/settings_screen_test.dart`
  - `tindatrack/lib/features/products/presentation/screens/add_product_screen.dart`
  - `tindatrack/test/features/products/presentation/screens/add_product_screen_test.dart`
  - `tindatrack/lib/features/products/presentation/screens/edit_product_screen.dart`
  - `tindatrack/test/features/products/presentation/screens/edit_product_screen_test.dart`
  - `tindatrack/lib/features/products/presentation/widgets/product_list_item.dart` and its tests only if the implementation chooses to display read-only selling price in product rows.
- Prefer a small immutable class or abstract-final utility that is easy to extend later, for example:
  - `currencyCode == 'PHP'`
  - `currencySymbol == '\\u20B1'`
  - `format(num amount) => '\\u20B11,234.50'`
- Keep formatter behavior deterministic and independent of device locale unless a later story explicitly scopes localization.

### Testing Requirements

- Formatter tests should be pure Dart tests and cover exact strings for representative values:
  - `0` -> `\u20B10.00`
  - `1` -> `\u20B11.00`
  - `12.5` -> `\u20B112.50`
  - `1234.56` -> `\u20B11,234.56`
  - a larger thousands example
- Settings widget tests should still assert all four MVP sections render and should assert no editable selector exists in the Currency section.
- Product tests should assert any changed price labels/copy and any formatted price text or semantics. Keep existing save/validation tests passing.
- If product rows gain selling price display, update row semantics intentionally and test high-text-scale behavior so row actions remain 48dp and accessible.
- Run Flutter commands from a Windows temp copy under `C:\tmp` if the UNC workspace blocks Flutter tooling.

### Previous Story Intelligence

- Story 5.1 created a synchronous Settings screen and intentionally avoided providers, persistence, network calls, auth, cloud, scanner, POS, supplier, accounting, reporting, and dependency changes.
- Story 5.1 preserved stable keys:
  - `Key('settings-screen')`
  - `Key('settings-currency-section')`
  - `Key('settings-backup-export-section')`
  - `Key('settings-app-version-section')`
  - `Key('settings-local-data-section')`
- Story 5.1 tests are in `tindatrack/test/features/settings/presentation/screens/settings_screen_test.dart` and include section rendering, MVP exclusion copy, small-phone/high-text-scale layout, and app-shell Settings route access.
- Story 5.1 review found no issues from Blind Hunter or Edge Case Hunter; Acceptance Auditor timed out, and local AC pass found no gaps. Status was marked `done`.

### Git Intelligence

- `35d06a8 Mark settings story done after review`
- `3bf25f6 Build settings screen`
- `1f9a956 Complete Epic 4 dashboard hardening`
- `4683c97 Create Story 4.6 dashboard test protection`
- `b830427 Fix Story 4.5 review findings`
- `684d8b5 Complete Story 4.5 dashboard recent activity`

Recent work favors feature-local widget tests, stable user-visible keys, explicit MVP exclusion assertions, and full-suite verification from a Windows temp copy when Flutter cannot run from the UNC workspace.

### Anti-Scope And Regression Guardrails

- Do not add user-selectable currencies in Story 5.2.
- Do not add persistence, settings repository/provider, Drift schema, migration, or app_settings table for the fixed MVP PHP context.
- Do not add `intl`, package metadata, storage, auth, cloud, backup/export, barcode scanning, POS, supplier, reporting, profit, margin, or accounting dependencies/features.
- Do not change product save payloads or validation semantics: blank selling price still maps to `0`, invalid/negative values still show existing friendly errors.
- Do not convert stored prices to strings. Database/domain values remain numeric; formatting is presentation-only.

### Project Structure Notes

- This story should centralize PHP display context, not implement general localization or multi-currency settings.
- Story 5.3 owns fuller backup/export placeholder behavior.
- Story 5.4 owns reading the installed app version from package metadata or `pubspec.yaml`.
- Story 5.5 owns broader MVP polish/accessibility across all screens.
- Story 5.6 owns release-readiness verification.

## Dev Agent Record

### Agent Model Used

Codex GPT-5

### Debug Log References

- 2026-07-20: Red focused test run from `C:\tmp\Inventory-tindatrack-story-5-2-red` failed on missing `CurrencyFormatter` and missing PHP product/settings UI expectations.
- 2026-07-20: Focused currency/settings/product tests passed from `C:\tmp\Inventory-tindatrack-story-5-2-verify2`.
- 2026-07-20: `dart analyze` passed from `C:\tmp\Inventory-tindatrack-story-5-2-verify2` with no issues.
- 2026-07-20: Full Flutter test suite passed from `C:\tmp\Inventory-tindatrack-story-5-2-verify2`.
- 2026-07-20: `git diff --check` passed from the workspace.

### Completion Notes List

- Ultimate context engine analysis completed - comprehensive developer guide created.
- Added a dependency-free centralized PHP currency formatter under `core/formatters` with exact formatting tests.
- Updated Settings currency copy to consume the centralized PHP context while preserving the local-only, non-editable Settings UI.
- Updated product price surfaces by labeling selling price fields with PHP context and displaying formatted read-only selling prices in product rows and semantics.
- Preserved product validation, persistence, Drift schema, repository contracts, save behavior, routes, and MVP exclusions.

### File List

- `_bmad-output/implementation-artifacts/5-2-show-php-currency-context.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `tindatrack/lib/core/formatters/currency_formatter.dart`
- `tindatrack/lib/features/products/presentation/screens/add_product_screen.dart`
- `tindatrack/lib/features/products/presentation/screens/edit_product_screen.dart`
- `tindatrack/lib/features/products/presentation/widgets/product_list_item.dart`
- `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart`
- `tindatrack/test/core/formatters/currency_formatter_test.dart`
- `tindatrack/test/features/products/presentation/screens/add_product_screen_test.dart`
- `tindatrack/test/features/products/presentation/screens/edit_product_screen_test.dart`
- `tindatrack/test/features/products/presentation/screens/product_list_screen_test.dart`
- `tindatrack/test/features/products/presentation/widgets/product_list_item_test.dart`
- `tindatrack/test/features/settings/presentation/screens/settings_screen_test.dart`

### Change Log

- 2026-07-20: Implemented Story 5.2 PHP currency context and focused tests; marked story ready for review.