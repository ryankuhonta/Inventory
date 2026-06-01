---
stepsCompleted: [1, 2, 3, 4]
inputDocuments:
  - _bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md
  - _bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/addendum.md
  - _bmad-output/planning-artifacts/architecture.md
  - _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md
  - _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md
  - docs/bmad-inventory-tracker-plan.md
---

# Inventory - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for Inventory, decomposing the requirements from the PRD, UX Design if it exists, and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

FR-001: The app shall show total active products.

FR-002: The app shall show the number of low-stock products.

FR-003: The app shall show recent inventory activity.

FR-004: The app shall provide navigation to Products, History, and Settings.

FR-005: The app shall provide a clear path to view low-stock products.

FR-006: The app shall allow the user to create a product.

FR-007: Product creation shall require a product name.

FR-008: Product creation shall support optional category.

FR-009: Product creation shall support unit, defaulting to "pcs".

FR-010: Product creation shall support quantity.

FR-011: Product creation shall support low-stock threshold.

FR-012: Product creation shall support selling price.

FR-013: Product creation may support cost price, but architecture resolves cost_price as deferred post-MVP and not part of the MVP schema.

FR-014: The app shall allow users to edit existing product details.

FR-015: The app shall allow users to archive products.

FR-016: Archived products shall not appear in the default active product list.

FR-017: Archived products shall retain their inventory history.

FR-018: The app shall list active products.

FR-019: The app shall support product search by name.

FR-020: The app should support search or filtering by category.

FR-021: The app shall visually identify low-stock products.

FR-022: The app shall visually identify out-of-stock products.

FR-023: The app shall provide quick access from a product row to edit, stock in, and stock out.

FR-024: The app shall allow stock in for an existing product.

FR-025: Stock in shall require a positive quantity.

FR-026: Stock in shall increase the product quantity.

FR-027: The app shall allow stock out for an existing product.

FR-028: Stock out shall require a positive quantity.

FR-029: Stock out shall decrease the product quantity.

FR-030: Stock out shall be blocked if quantity exceeds available stock.

FR-031: Stock movement shall support an optional note.

FR-032: Successful stock movement shall create an inventory history entry.

FR-033: Product quantity update and history entry creation shall succeed or fail together.

FR-034: The app shall show inventory transactions sorted newest first.

FR-035: Each transaction shall show movement type, product, quantity, previous quantity, new quantity, and date/time.

FR-036: The app shall show a friendly empty state when there is no history.

FR-037: The app shall show app settings.

FR-038: The app shall show PHP as the default currency context.

FR-039: The app shall show backup/export as a future-ready placeholder.

FR-040: The app shall show app version information.

### NonFunctional Requirements

NFR-001: The app must work offline for all MVP features.

NFR-002: The app must persist data locally after app restart.

NFR-003: Core screens should remain responsive on low-end Android devices.

NFR-004: The product list should handle at least 3,000 local products.

NFR-005: Stock changes must be stored reliably and atomically.

NFR-006: The app must not log sensitive inventory data in production.

NFR-007: The app should use readable typography and accessible contrast.

NFR-008: Common tap targets should be at least 48dp.

NFR-009: The codebase should remain beginner-friendly and modular.

NFR-010: MVP architecture should support future cloud sync without rewriting the UI.

### Additional Requirements

- Initialize the app from the official Flutter empty starter: `flutter create --empty --platforms android --org com.rkuhonta tindatrack`.
- Use Flutter, Riverpod, Drift over SQLite, Clean Architecture, and go_router.
- Use feature-first folders under `lib/features`, shared code under `lib/core`, and app shell/routing/theme under `lib/app`.
- Use ULID string IDs project-wide at creation boundaries.
- Store timestamps in UTC through an injectable clock, not direct `DateTime.now()` calls.
- Use `snake_case` for database tables and columns; Dart fields may use `camelCase`.
- Use Drift/SQLite as the local source of truth with migrations and migration tests.
- Keep MVP local-only with no required login, no backend API, no cloud sync, and no fake authentication flow.
- Archive products instead of hard-deleting them.
- Hide archived products from the default active product list while preserving their history.
- Prevent archived products from receiving Stock In/Out unless restored first.
- Treat stock movement as the source of truth for quantity changes after product creation.
- Allow initial quantity during product creation; after creation, all quantity changes must route through stock movement use cases.
- Insert stock movement and update product quantity in one Drift transaction.
- Require stock mutation rollback tests proving failed stock changes insert no movement and alter no product quantity.
- Include `product_name_snapshot` and `unit_snapshot` in `stock_movements` so history remains readable after product rename or archive.
- Stock movement records must include product id, type, quantity, previous quantity, new quantity, optional note, product snapshots, and created timestamp.
- Use integer stock quantities and practical configured maximums for quantities and thresholds.
- Reject negative quantities and thresholds.
- Allow zero stock and show it as out of stock.
- Block Stock Out when requested quantity exceeds available stock.
- Normalize blank barcode input to `null`.
- Allow multiple null barcodes.
- Reject duplicate non-null barcodes across active and archived products.
- Keep barcode scanner UI, scanner route, permissions, and dependencies out of MVP.
- Defer `cost_price` post-MVP; do not add a nullable placeholder in the MVP schema.
- Use typed domain failures and map them to friendly user-facing messages.
- Do not expose raw SQL, Drift, or exception messages in UI.
- Use repository contracts and use cases; widgets must not access Drift directly.
- Dashboard and history must be read-only over inventory data.
- Product search should be debounced and backed by appropriate local indexes.
- Dashboard summaries should use focused aggregate queries and avoid heavy recomputation.
- App version display should read from `pubspec.yaml`, not hardcoded copy.
- Required tests include stock in/out logic, validation, low-stock calculation, repository transaction rollback, add/edit product widgets, insufficient stock out widget behavior, barcode normalization/uniqueness, archive behavior, history readability, UTC clock use, ULID generation, typed failure mapping, and migration tests.
- Keep MVP exclusions out of implementation: POS/cart/checkout, supplier management, accounting/profit reports, login/signup/account, cloud sync, barcode scanner, staff roles, multi-branch management, push notifications, and remote API client layers.

### UX Design Requirements

UX-DR1: Implement a Flutter Material 3 visual system using the DESIGN.md tokens for colors, typography, spacing, radii, and minimum tap target size.

UX-DR2: Use a light, practical, readable visual style with off-white background, white surfaces, green primary actions, amber low-stock warning, and red destructive or critical states.

UX-DR3: Avoid large decorative gradients, heavy shadows, nested cards, glossy/finance-heavy styling, and unnecessary visual clutter.

UX-DR4: Use Android system typography or Roboto with readable small-screen sizing; avoid viewport-scaled text and negative letter spacing.

UX-DR5: Use a single-column Android mobile layout with 16dp outer padding and spacing that keeps actions easy to scan.

UX-DR6: Keep bottom navigation fixed to Dashboard, Products, History, and Settings with visible labels.

UX-DR7: Splash screen must initialize local app services, route to Dashboard on success, and show a simple retry state on initialization failure.

UX-DR8: MVP must not force login; any future login screen must support Continue Offline and must not block local inventory tracking.

UX-DR9: Dashboard must show "Inventory Today," summary cards for Total Products, Low Stock, and Stock Changes Today, plus low-stock and recent activity previews.

UX-DR10: Dashboard empty state must guide the user to "Add your first product."

UX-DR11: Product List must include a local search field, All/Low Stock/Out of Stock filters, active product rows, and an Add Product floating action button.

UX-DR12: Product rows must show product name, category or unit, current quantity, meaningful status badges, and quick actions for Stock In, Stock Out, and Edit.

UX-DR13: Low-stock and out-of-stock states must be visible without opening product details, with Out of Stock visually overriding Low Stock.

UX-DR14: Product empty state must lead to Add Product; no-results search state must show "No matching products."

UX-DR15: Add Product must provide fields for product name, optional category, unit defaulting to "pcs", selling price, starting quantity, and low-stock threshold, with cost price excluded from MVP per architecture.

UX-DR16: Edit Product must allow details to be updated without losing history; post-creation quantity changes should be handled through Stock In/Out, not direct edit.

UX-DR17: Archive action must be secondary, require confirmation, and reassure users that history remains available.

UX-DR18: Stock In screen must show product name, current quantity, quantity input, optional note, and primary action "Record Stock In" or equivalent friendly copy.

UX-DR19: Stock Out screen must show product name, current quantity, quantity input, optional note, and primary action "Record Stock Out" or equivalent friendly copy.

UX-DR20: Stock In and Stock Out must validate that quantity is greater than zero.

UX-DR21: Stock Out blocked state must show "Not enough stock available" near the quantity field and must not update quantity.

UX-DR22: Inventory History must show newest transactions first with movement type, product name, changed quantity, previous quantity, new quantity, date/time, and note when present.

UX-DR23: Inventory History empty state must explain that stock changes will appear there.

UX-DR24: Settings must show local settings, PHP currency context, backup/export placeholder marked honestly as future/coming soon, app version, and future privacy/data note as appropriate.

UX-DR25: Feedback must use snackbars or inline banners for saved, product updated, stock recorded, not enough stock, and generic recovery states.

UX-DR26: Loading states must be lightweight; forms should disable save and show button-level progress while saving.

UX-DR27: Accessibility floor requires 48dp tap targets, readable text at system font scaling, accessible input labels, field-associated error messages, and warnings that do not rely on color alone.

UX-DR28: Use numeric keyboard types for quantity and price fields, dismiss keyboard on save, and keep forms scrollable for small screens.

UX-DR29: Keep ads out of Add Product, Edit Product, Stock In, Stock Out, and any save/confirm flow.

UX-DR30: Use simple English with Filipino-friendly phrasing, avoiding technical terms like "inventory mutation," "entity," and raw constraint or database messages.

### FR Coverage Map

FR-001: Epic 4 - Dashboard total active products.

FR-002: Epic 4 - Dashboard low-stock count.

FR-003: Epic 4 - Recent inventory activity.

FR-004: Epic 1 - Main navigation to Products, History, and Settings.

FR-005: Epic 4 - Clear path to low-stock products.

FR-006: Epic 2 - Create product.

FR-007: Epic 2 - Product name required.

FR-008: Epic 2 - Optional category.

FR-009: Epic 2 - Unit defaulting to "pcs".

FR-010: Epic 2 - Starting quantity.

FR-011: Epic 2 - Low-stock threshold.

FR-012: Epic 2 - Selling price.

FR-013: Epic 2 - Cost price explicitly deferred post-MVP.

FR-014: Epic 2 - Edit product details.

FR-015: Epic 2 - Archive product.

FR-016: Epic 2 - Hide archived products from active list.

FR-017: Epic 2 and Epic 3 - Preserve archived product history.

FR-018: Epic 2 - Active product list.

FR-019: Epic 2 - Search by name.

FR-020: Epic 2 - Search or filter by category.

FR-021: Epic 2 and Epic 4 - Low-stock visual state.

FR-022: Epic 2 and Epic 4 - Out-of-stock visual state.

FR-023: Epic 2 and Epic 3 - Product row edit/action pattern and Stock In/Out row action activation.

FR-024: Epic 3 - Stock In.

FR-025: Epic 3 - Positive Stock In quantity.

FR-026: Epic 3 - Stock In increases quantity.

FR-027: Epic 3 - Stock Out.

FR-028: Epic 3 - Positive Stock Out quantity.

FR-029: Epic 3 - Stock Out decreases quantity.

FR-030: Epic 3 - Block Stock Out beyond available stock.

FR-031: Epic 3 - Optional movement note.

FR-032: Epic 3 - History entry on movement.

FR-033: Epic 3 - Atomic quantity update plus history insert.

FR-034: Epic 3 - Newest-first history.

FR-035: Epic 3 - Movement details display.

FR-036: Epic 3 - Empty history state.

FR-037: Epic 5 - App settings.

FR-038: Epic 5 - PHP currency context.

FR-039: Epic 5 - Backup/export placeholder.

FR-040: Epic 5 - App version information.

## Epic List

### Epic 1: Offline App Shell And Local Foundation

Users can open the Android app without internet, land in a usable offline-first shell, and navigate between the main MVP sections.

**FRs covered:** FR-004

**Implementation Notes:** Initialize the Flutter empty starter, add core dependencies, configure app theme, routing, bottom navigation, Riverpod wiring, Drift database foundation, ULID generation, injectable UTC clock, typed failures, and local initialization. No login, backend, cloud sync, or scanner UI should be introduced.

### Epic 2: Product Catalog Management

Users can create, view, search, edit, archive, and understand product stock status in their local product catalog.

**FRs covered:** FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, FR-013, FR-014, FR-015, FR-016, FR-017, FR-018, FR-019, FR-020, FR-021, FR-022, FR-023

**Implementation Notes:** Build product domain/data/presentation flows, active product list, Add/Edit Product forms, product validation, search/filter behavior, status badges, archive-not-delete behavior, barcode normalization and uniqueness rules, and row actions. `cost_price` remains deferred post-MVP.

### Epic 3: Stock Movement And Inventory History

Users can record Stock In and Stock Out safely while preserving a reliable movement history for audit.

**FRs covered:** FR-023, FR-024, FR-025, FR-026, FR-027, FR-028, FR-029, FR-030, FR-031, FR-032, FR-033, FR-034, FR-035, FR-036, FR-017

**Implementation Notes:** Implement stock movement use cases, validation, insufficient-stock blocking, atomic Drift transaction for quantity update plus movement insert, movement snapshots, optional notes, newest-first history, friendly empty states, and history readability after product rename/archive.

### Epic 4: Dashboard And Low-Stock Awareness

Users can quickly see inventory health, recent activity, and what needs restocking.

**FRs covered:** FR-001, FR-002, FR-003, FR-005, FR-021, FR-022

**Implementation Notes:** Build dashboard summaries, low-stock count, stock changes today, recent activity preview, low-stock preview, empty dashboard guidance, and navigation to low-stock filtered products using efficient aggregate queries.

### Epic 5: Settings And Release Readiness

Users can view basic app settings and future backup/export expectations while the MVP receives polish and release-quality safeguards.

**FRs covered:** FR-037, FR-038, FR-039, FR-040

**Implementation Notes:** Build Settings with PHP currency context, honest backup/export placeholder, app version sourced from `pubspec.yaml`, future privacy/data note as appropriate, final UX polish, accessibility checks, and required release-readiness tests.

## Epic 1: Offline App Shell And Local Foundation

Users can open the Android app without internet, land in a usable offline-first shell, and navigate between the main MVP sections.

### Story 1.1: Set Up Initial Project From Flutter Empty Starter Template

**Requirements:** FR-004, NFR-001, NFR-003, NFR-009, NFR-010

As a store owner,
I want the app to install and open on Android,
So that I can start using an offline inventory tracker without setup complexity.

**Acceptance Criteria:**

**Given** the repository is ready for implementation
**When** the Flutter project is initialized
**Then** the project uses the official empty Android starter command `flutter create --empty --platforms android --org com.rkuhonta tindatrack`
**And** the app package foundation is Android-first and does not introduce iOS, web, backend, login, cloud sync, barcode scanner, POS, supplier, or accounting scope.

**Given** the project dependencies are added
**When** the app is prepared for development
**Then** Riverpod, Drift, go_router, test tooling, linting, and required local SQLite support are available
**And** the app remains lightweight for low-end Android devices.

**Given** the initialized app is built or run
**When** the developer starts the app on an Android target
**Then** the app opens to a basic working Flutter screen without requiring internet access
**And** analysis and the default test baseline pass.

### Story 1.2: Establish App Architecture And Local Core Services

**Requirements:** FR-004, NFR-001, NFR-002, NFR-009, NFR-010

As a developer maintaining the app,
I want the local architecture foundation in place,
So that product and stock features can be built consistently and safely.

**Acceptance Criteria:**

**Given** the Flutter project exists
**When** the application structure is created
**Then** the source tree includes `lib/app`, `lib/core`, and `lib/features`
**And** feature code is organized feature-first while shared infrastructure stays in `core`.

**Given** the app architecture foundation is implemented
**When** future features need state, persistence, routing, IDs, time, or failures
**Then** Riverpod app wiring, Drift database scaffolding, ULID generation abstraction, injectable UTC clock abstraction, and typed failure/message patterns are available
**And** widgets do not access Drift directly.

**Given** the local database scaffold is added
**When** the first schema version is defined
**Then** database naming rules use `snake_case` for tables and columns
**And** the scaffold is ready for future Drift migrations and migration tests without creating unused product or stock tables prematurely.

### Story 1.3: Provide Offline App Launch And Splash Initialization

**Requirements:** FR-004, NFR-001, NFR-002, UX-DR7, UX-DR8

As a store owner,
I want the app to open without internet and initialize local services,
So that I can use inventory features even when connection is unavailable.

**Acceptance Criteria:**

**Given** the user launches the app with no internet connection
**When** the splash screen initializes local app services
**Then** the app does not request login, network access, or cloud setup
**And** local initialization is enough to proceed.

**Given** local initialization succeeds
**When** the splash flow completes
**Then** the user is routed to the Dashboard area
**And** the app is ready for offline MVP navigation.

**Given** local initialization fails
**When** the splash flow cannot open required local services
**Then** the app shows a simple retry state with plain recovery text
**And** raw database or exception messages are not exposed.

### Story 1.4: Add Main Navigation Shell

**Requirements:** FR-004, UX-DR6

As a store owner,
I want simple navigation between Dashboard, Products, History, and Settings,
So that I can move around the inventory app without confusion.

**Acceptance Criteria:**

**Given** the app shell is loaded
**When** the user views the main app
**Then** bottom navigation shows exactly four MVP sections: Dashboard, Products, History, and Settings
**And** labels remain visible.

**Given** the user taps a bottom navigation item
**When** Dashboard, Products, History, or Settings is selected
**Then** go_router navigates to the matching placeholder screen
**And** the selected section is visually clear.

**Given** MVP navigation is implemented
**When** the route table is reviewed
**Then** it contains no login, barcode scanner, cloud sync, POS, supplier, or accounting routes
**And** future features are not exposed as fake flows.

### Story 1.5: Apply MVP Theme And Base UI States

**Requirements:** NFR-007, NFR-008, UX-DR1, UX-DR2, UX-DR3, UX-DR4, UX-DR5, UX-DR25, UX-DR27, UX-DR30

As a store owner or helper,
I want the app to be readable and easy to tap,
So that I can use it comfortably on a small Android phone.

**Acceptance Criteria:**

**Given** the app theme is configured
**When** the main app screens render
**Then** they use a Flutter Material 3 theme based on the approved design tokens for colors, typography, spacing, shape, and tap target guidance
**And** the visual style is light, practical, and uncluttered.

**Given** a screen needs loading, empty, or error feedback
**When** the corresponding base state component is shown
**Then** the message is plain, Filipino-friendly English and includes a clear next step where useful
**And** raw technical errors are not shown to users.

**Given** common interactive elements are displayed
**When** the user taps primary navigation or action controls
**Then** tap targets follow the 48dp accessibility floor where applicable
**And** warnings or errors are not communicated by color alone.

## Epic 2: Product Catalog Management

Users can create, view, search, edit, archive, and understand product stock status in their local product catalog.

### Story 2.1: Create Product Catalog Data Model And Repository

**Requirements:** FR-006, FR-013, FR-016, FR-018, NFR-001, NFR-002, NFR-004, NFR-010

As a store owner,
I want my products saved locally,
So that my inventory list remains available after closing and reopening the app.

**Acceptance Criteria:**

**Given** the local database foundation exists
**When** product catalog persistence is implemented
**Then** the `products` table is created with `id`, `name`, `category`, `unit`, `selling_price`, `quantity`, `low_stock_threshold`, `barcode`, `is_archived`, `created_at`, and `updated_at`
**And** `cost_price` is not added to the MVP schema.

**Given** a product is created through the repository
**When** the product is saved locally
**Then** it receives a ULID string ID and UTC timestamps from injectable services
**And** the product remains available after app restart.

**Given** barcode values are persisted
**When** the barcode is blank or whitespace
**Then** it is normalized to `null`
**And** multiple products may have null barcode values.

**Given** a non-null barcode already exists on any active or archived product
**When** another product is saved with the same barcode
**Then** the repository rejects the duplicate barcode
**And** returns a typed failure that can be mapped to friendly UI copy.

**Given** products exist in local storage
**When** the active product query runs
**Then** it returns non-archived products only
**And** it does not expose raw Drift rows directly to widgets.

### Story 2.2: Add Product With Validation

**Requirements:** FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, FR-013, UX-DR15, UX-DR25, UX-DR28

As a store owner,
I want to add a product with basic stock details,
So that I can start tracking inventory.

**Acceptance Criteria:**

**Given** the user opens Add Product
**When** the form is displayed
**Then** it includes product name, optional category, unit defaulting to "pcs", selling price, starting quantity, and low-stock threshold
**And** cost price is not shown in the MVP form.

**Given** the user leaves product name empty
**When** the user saves the product
**Then** saving is blocked
**And** a friendly validation message explains that product name is required.

**Given** the user enters a negative quantity, threshold, or selling price
**When** the user saves the product
**Then** saving is blocked
**And** the first invalid field receives clear inline feedback.

**Given** the user enters valid product details
**When** the user saves the product
**Then** the product is saved locally
**And** the user receives success feedback such as "Product saved."

**Given** the user enters a blank barcode value if barcode input is present
**When** the product is saved
**Then** the barcode is stored as `null`
**And** no validation error is shown for the blank barcode.

### Story 2.3: View Active Product List With Empty State

**Requirements:** FR-016, FR-018, UX-DR11, UX-DR12, UX-DR14

As a store owner,
I want to see my active products in one list,
So that I can check current stock quickly.

**Acceptance Criteria:**

**Given** active products exist
**When** the user opens Products
**Then** the screen shows a lazy-rendered list of active, non-archived products
**And** each row shows product name, category or unit, current quantity, and relevant status information.

**Given** no active products exist
**When** the user opens Products
**Then** the screen shows a friendly empty state
**And** the empty state provides a clear action to add the first product.

**Given** the Products screen is displayed
**When** the user looks for the add action
**Then** an Add Product floating action button is available
**And** tapping it opens the Add Product flow.

**Given** the local catalog contains many products
**When** the Products screen renders
**Then** list rendering remains responsive for the 3,000-product target
**And** the UI avoids loading all row widgets at once.

### Story 2.4: Search And Filter Products

**Requirements:** FR-019, FR-020, FR-021, FR-022, NFR-003, NFR-004, UX-DR11, UX-DR14

As a store helper,
I want to find products quickly by search or stock status,
So that I can act on the right item during busy selling hours.

**Acceptance Criteria:**

**Given** the user is on Products
**When** the user types into search
**Then** the product list filters locally by product name
**And** the search input is debounced to protect low-end device responsiveness.

**Given** products have categories
**When** the user searches or filters by category where supported
**Then** matching products can be found without requiring internet access
**And** category support does not make product creation mandatory for category.

**Given** the Products screen is displayed
**When** the user selects All, Low Stock, or Out of Stock
**Then** the selected filter is visually clear
**And** the list displays only products matching the selected filter.

**Given** no products match the current search or filter
**When** the filtered list is empty
**Then** the screen shows "No matching products" or equivalent plain copy
**And** it does not show a technical error.

### Story 2.5: Show Low-Stock And Out-of-Stock Product Status

**Requirements:** FR-021, FR-022, UX-DR12, UX-DR13, UX-DR27

As a store owner,
I want products to clearly show low-stock and out-of-stock states,
So that I know what needs attention.

**Acceptance Criteria:**

**Given** a product quantity is equal to or below its low-stock threshold
**When** the product appears in the product list
**Then** it is marked as Low Stock
**And** the status uses text or label copy, not color alone.

**Given** a product quantity is zero
**When** the product appears in the product list
**Then** it is marked as Out of Stock
**And** Out of Stock visually overrides Low Stock.

**Given** products are filtered by Low Stock or Out of Stock
**When** the user changes product quantities through valid flows later
**Then** the status calculation is based on current local product data
**And** no manual status flag is required.

### Story 2.6: Edit Product Details Without Direct Stock Adjustment

**Requirements:** FR-014, FR-017, UX-DR16

As a store owner,
I want to edit product details without changing movement history,
So that product information stays accurate while stock changes remain auditable.

**Acceptance Criteria:**

**Given** an existing active product
**When** the user opens Edit Product
**Then** the form allows editing name, category, unit, selling price, low-stock threshold, and barcode if barcode input is present
**And** the form does not allow direct post-creation quantity edits.

**Given** the user enters valid edited details
**When** the user saves
**Then** the product is updated locally
**And** the user receives success feedback such as "Product updated."

**Given** the user enters a duplicate non-null barcode already used by an active or archived product
**When** the user saves
**Then** saving is blocked
**And** friendly copy explains that the barcode is already used by another product.

**Given** a product is renamed or its unit changes
**When** future stock movement history is displayed
**Then** the product catalog change does not delete or rewrite existing movement records
**And** future movement snapshots can preserve readable history.

### Story 2.7: Archive Product Without Deleting History

**Requirements:** FR-015, FR-016, FR-017, UX-DR17

As a store owner,
I want to archive products I no longer sell,
So that my active list stays clean while history remains available.

**Acceptance Criteria:**

**Given** an active product exists
**When** the user chooses Archive
**Then** the app asks for confirmation
**And** the copy explains that the product will be hidden from the active list but history remains available.

**Given** the user confirms archive
**When** the archive action succeeds
**Then** the product is marked archived locally
**And** the product is not physically deleted from the database.

**Given** a product is archived
**When** the user opens the default product list
**Then** the archived product is hidden
**And** historical references to that product remain available for history flows.

**Given** the MVP scope is reviewed
**When** archive behavior is implemented
**Then** Restore Archived Product UI is deferred
**And** archived products cannot receive Stock In or Stock Out unless a future restore flow is explicitly added.

### Story 2.8: Prepare Product Row Action Pattern

**Requirements:** FR-014, FR-023, UX-DR12, NFR-008

As a store helper,
I want product rows to expose clear and accessible actions,
So that I can edit products quickly and have a consistent place for future stock actions.

**Acceptance Criteria:**

**Given** an active product row is displayed
**When** the user views available actions
**Then** Edit is available from the row or an accessible row action pattern
**And** the action is easy to tap on small Android screens.

**Given** the user taps Edit
**When** the action is selected
**Then** the app opens the Edit Product flow for that product
**And** the selected product identity is preserved.

**Given** Stock In and Stock Out flows are not implemented until Epic 3
**When** Product Catalog work is completed
**Then** the product row may reserve layout or component structure for future stock actions
**And** Stock In and Stock Out actions are not active, fake, or routed from Epic 2.

**Given** archived products are hidden from the default active product list
**When** product row actions are displayed
**Then** archived products do not expose Edit or future stock actions from the active list.

## Epic 3: Stock Movement And Inventory History

Users can record Stock In and Stock Out safely while preserving a reliable movement history for audit.

### Story 3.1: Create Stock Movement Data Model And Repository

**Requirements:** FR-031, FR-032, FR-034, FR-035, NFR-002, NFR-005

As a store owner,
I want every stock change saved as a local movement record,
So that I can trust the app's inventory history.

**Acceptance Criteria:**

**Given** the product catalog foundation exists
**When** stock movement persistence is implemented
**Then** the `stock_movements` table is created with `id`, `product_id`, `type`, `quantity`, `previous_quantity`, `new_quantity`, `reason`, `note`, `product_name_snapshot`, `unit_snapshot`, and `created_at`
**And** database columns use `snake_case`.

**Given** a stock movement is created
**When** it is saved locally
**Then** it receives a ULID string ID and UTC timestamp from injectable services
**And** it stores the product name and unit snapshots from the time of movement.

**Given** movement type values are stored
**When** a movement is inserted
**Then** type is constrained to `stock_in` or `stock_out`
**And** invalid movement types are rejected before persistence.

**Given** Stock Out reason support is added in the domain/data layer
**When** a Stock Out movement is recorded
**Then** the reason value supports `sold`, `damaged`, `lost`, `personal_use`, and `correction`
**And** the default reason is `sold` when no selector is exposed in MVP.

**Given** movement history is queried
**When** the repository returns movement records
**Then** records are sorted newest first
**And** widgets do not access Drift rows directly.

### Story 3.2: Record Stock In Atomically

**Requirements:** FR-024, FR-025, FR-026, FR-031, FR-032, FR-033, NFR-005, UX-DR20

As a store owner,
I want to record added inventory,
So that new purchases increase available stock and leave a history trail.

**Acceptance Criteria:**

**Given** an active product exists
**When** the user records Stock In with a positive quantity
**Then** the product quantity increases by that quantity
**And** a `stock_in` movement is inserted with previous quantity, new quantity, product snapshots, optional note, and UTC timestamp.

**Given** the user records Stock In with zero or negative quantity
**When** the action is submitted
**Then** the action is rejected
**And** no product quantity or movement history change is saved.

**Given** the target product does not exist or is archived
**When** Stock In is attempted
**Then** the action is rejected with a typed failure
**And** the UI can map the failure to friendly copy.

**Given** a Stock In operation is processed
**When** either the product quantity update or movement insert fails
**Then** the entire transaction rolls back
**And** no partial inventory state is saved.

### Story 3.3: Record Stock Out Atomically With Insufficient Stock Protection

**Requirements:** FR-027, FR-028, FR-029, FR-030, FR-031, FR-032, FR-033, NFR-005, UX-DR20, UX-DR21

As a store helper,
I want to record removed or sold stock safely,
So that inventory decreases only when enough stock is available.

**Acceptance Criteria:**

**Given** an active product has enough available stock
**When** the user records Stock Out with a positive quantity
**Then** the product quantity decreases by that quantity
**And** a `stock_out` movement is inserted with previous quantity, new quantity, product snapshots, optional note, reason, and UTC timestamp.

**Given** the user records Stock Out with zero or negative quantity
**When** the action is submitted
**Then** the action is rejected
**And** no product quantity or movement history change is saved.

**Given** a product has less stock than the requested Stock Out quantity
**When** the user submits the action
**Then** the action is rejected with an insufficient stock failure
**And** the product quantity remains unchanged.

**Given** the target product does not exist or is archived
**When** Stock Out is attempted
**Then** the action is rejected with a typed failure
**And** no movement record is inserted.

**Given** a Stock Out operation is processed
**When** either the product quantity update or movement insert fails
**Then** the entire transaction rolls back
**And** no partial inventory state is saved.

### Story 3.4: Build Stock In Screen

**Requirements:** FR-024, FR-025, FR-026, FR-031, UX-DR18, UX-DR20, UX-DR25, UX-DR26, UX-DR28

As a store owner,
I want a simple Stock In screen,
So that I can quickly record new inventory.

**Acceptance Criteria:**

**Given** the user opens Stock In for an active product
**When** the screen loads
**Then** it shows the product name, current quantity, quantity input, optional note, and primary action
**And** the quantity input uses a numeric keyboard.

**Given** the user enters zero, negative, or invalid quantity
**When** the user submits Stock In
**Then** the form shows inline validation
**And** no stock movement is recorded.

**Given** the user enters a valid Stock In quantity
**When** the user submits the form
**Then** the save action shows button-level loading while processing
**And** duplicate submissions are prevented.

**Given** Stock In succeeds
**When** the operation completes
**Then** the user sees friendly success feedback including the new stock count
**And** the previous screen or product data reflects the updated quantity.

**Given** Stock In fails
**When** the operation returns a typed failure
**Then** the UI shows friendly recovery copy
**And** raw database or exception messages are not shown.

### Story 3.5: Build Stock Out Screen

**Requirements:** FR-027, FR-028, FR-029, FR-030, FR-031, UX-DR19, UX-DR20, UX-DR21, UX-DR25, UX-DR26, UX-DR28

As a store helper,
I want a simple Stock Out screen,
So that I can quickly record sold, lost, or removed stock.

**Acceptance Criteria:**

**Given** the user opens Stock Out for an active product
**When** the screen loads
**Then** it shows the product name, current quantity, quantity input, optional note, and primary action
**And** the quantity input uses a numeric keyboard.

**Given** the visible MVP form is implemented
**When** the user records Stock Out
**Then** the Stock Out reason defaults to `sold`
**And** a visible reason selector is deferred unless separately scoped.

**Given** the user enters zero, negative, invalid, or excessive quantity
**When** the user submits Stock Out
**Then** the form shows inline validation near the quantity field
**And** excessive quantity shows "Not enough stock available" or equivalent friendly copy.

**Given** the user enters a valid Stock Out quantity
**When** the user submits the form
**Then** the save action shows button-level loading while processing
**And** duplicate submissions are prevented.

**Given** Stock Out succeeds
**When** the operation completes
**Then** the user sees friendly success feedback including the new stock count
**And** the previous screen or product data reflects the updated quantity.

**Given** Stock Out fails
**When** the operation returns a typed failure
**Then** the UI shows friendly recovery copy
**And** raw database or exception messages are not shown.

### Story 3.6: Show Inventory History List

**Requirements:** FR-017, FR-034, FR-035, FR-036, UX-DR22, UX-DR23

As a store owner,
I want to review stock movement history,
So that I can audit why product quantities changed.

**Acceptance Criteria:**

**Given** stock movement records exist
**When** the user opens History
**Then** movements are shown newest first
**And** the screen is read-only.

**Given** a movement row is displayed
**When** the user reviews it
**Then** it shows Stock In or Stock Out label, product name snapshot, changed quantity, previous quantity, new quantity, date/time, and note when present
**And** it remains understandable after product rename or archive.

**Given** a Stock Out movement has a reason value
**When** the movement appears in History
**Then** the reason may be available to the row or detail model
**And** the MVP UI is not required to expose a reason filter or selector.

**Given** no stock movements exist
**When** the user opens History
**Then** the screen shows a friendly empty state such as "Stock changes will appear here"
**And** it does not show a technical error.

### Story 3.7: Activate Product Row Stock Movement Actions

**Requirements:** FR-023, FR-024, FR-027, UX-DR12, NFR-008

As a store helper,
I want Stock In and Stock Out actions available from each active product row,
So that I can record inventory movement without extra searching.

**Acceptance Criteria:**

**Given** an active product row is displayed after Stock In and Stock Out screens exist
**When** the user views available row actions
**Then** Stock In and Stock Out actions are available from the row or accessible row action pattern
**And** the actions are easy to tap on small Android screens.

**Given** the user taps Stock In from a product row
**When** the action is selected
**Then** the app opens the Stock In flow for that product
**And** the selected product identity is preserved.

**Given** the user taps Stock Out from a product row
**When** the action is selected
**Then** the app opens the Stock Out flow for that product
**And** the selected product identity is preserved.

**Given** archived products are hidden from the default active product list
**When** row stock movement actions are displayed
**Then** archived products do not expose Stock In or Stock Out actions from the active list.

**Given** Stock In or Stock Out navigation fails
**When** the user selects a row stock action
**Then** no stock mutation is performed
**And** the user receives friendly recovery feedback.

### Story 3.8: Protect Stock Movement Reliability With Tests

**Requirements:** FR-024, FR-025, FR-026, FR-027, FR-028, FR-029, FR-030, FR-032, FR-033, NFR-005

As a developer maintaining inventory logic,
I want stock movement tests around the transaction boundary,
So that the app never saves mismatched quantity and history.

**Acceptance Criteria:**

**Given** Stock In logic is tested
**When** a valid Stock In is executed
**Then** tests verify quantity increases and a movement record is inserted
**And** previous and new quantities are correct.

**Given** Stock Out logic is tested
**When** a valid Stock Out is executed
**Then** tests verify quantity decreases and a movement record is inserted
**And** previous and new quantities are correct.

**Given** insufficient Stock Out is tested
**When** requested quantity exceeds available stock
**Then** tests verify product quantity remains unchanged
**And** no movement record is inserted.

**Given** transaction rollback is tested
**When** either product quantity update or movement insert fails
**Then** tests verify no partial save remains
**And** product quantity and movement history stay consistent.

**Given** archived product behavior is tested
**When** Stock In or Stock Out is attempted for an archived product
**Then** tests verify the operation is rejected
**And** no movement or quantity change is saved.

**Given** movement snapshot behavior is tested
**When** a product is renamed or archived after a movement
**Then** tests verify history remains readable through `product_name_snapshot` and `unit_snapshot`.

**Given** infrastructure behavior is tested
**When** stock movements are created
**Then** tests verify ULID generation and injectable UTC clock usage
**And** stock out reason defaults to `sold` when no reason is provided.

## Epic 4: Dashboard And Low-Stock Awareness

Users can quickly see inventory health, recent activity, and what needs restocking.

### Story 4.1: Create Dashboard Summary Queries

**Requirements:** FR-001, FR-002, FR-003, FR-021, FR-022, NFR-003, NFR-004

As a store owner,
I want dashboard numbers to reflect my local inventory,
So that I can quickly understand store status.

**Acceptance Criteria:**

**Given** active and archived products exist
**When** the dashboard total products query runs
**Then** it counts active products only
**And** archived products are excluded.

**Given** products have quantities and low-stock thresholds
**When** the low-stock count query runs
**Then** it counts products where quantity is equal to or below the low-stock threshold
**And** out-of-stock products are included because they need attention.

**Given** stock movement records have UTC timestamps
**When** the Stock Changes Today query runs
**Then** it computes today using the device or app local timezone day
**And** converts the local day start/end boundaries to UTC for the Drift query.

**Given** dashboard summaries are displayed
**When** the app rebuilds dashboard widgets
**Then** summary values come from focused aggregate queries
**And** widgets do not recompute summaries by scanning full product or movement lists.

### Story 4.2: Build Dashboard Screen With Summary Cards

**Requirements:** FR-001, FR-002, FR-003, UX-DR9, UX-DR10, UX-DR25, UX-DR26

As a store owner,
I want to see total products, low stock, and stock changes today,
So that I can understand inventory status at a glance.

**Acceptance Criteria:**

**Given** the user opens the Dashboard
**When** inventory data is available
**Then** the screen shows the header "Inventory Today"
**And** summary cards for Total Products, Low Stock, and Stock Changes Today.

**Given** dashboard data is loading
**When** the screen is displayed
**Then** it shows a lightweight loading state
**And** the UI remains responsive.

**Given** dashboard data fails to load
**When** the screen is displayed
**Then** it shows friendly recovery copy
**And** raw database or exception messages are not shown.

**Given** no products exist
**When** the user opens the Dashboard
**Then** the screen shows an empty state that guides the user to add the first product
**And** the empty state does not imply cloud setup or login is required.

### Story 4.3: Show Low-Stock Preview On Dashboard

**Requirements:** FR-002, FR-005, FR-021, FR-022, UX-DR9, UX-DR13

As a store owner,
I want to preview low-stock products on the dashboard,
So that I know what may need restocking without opening the full list.

**Acceptance Criteria:**

**Given** low-stock or out-of-stock products exist
**When** the Dashboard loads
**Then** it shows a preview of a small number of products needing attention
**And** each preview item shows product name, quantity, unit, and status.

**Given** out-of-stock products are present in the preview
**When** low-stock products are also present
**Then** Out of Stock is clearly labeled
**And** it is not hidden behind a generic Low Stock label.

**Given** no products are low stock
**When** the Dashboard loads
**Then** the low-stock preview area shows calm empty copy
**And** it does not create unnecessary warning noise.

### Story 4.4: Navigate From Dashboard To Low-Stock Product List

**Requirements:** FR-005, FR-021, FR-022, UX-DR9, UX-DR11

As a store owner,
I want to tap the low-stock dashboard area,
So that I can review all products that need restocking.

**Acceptance Criteria:**

**Given** the Dashboard shows a Low Stock summary or preview
**When** the user taps the low-stock area
**Then** the app navigates to Products
**And** the Low Stock filter is applied.

**Given** Products opens from the Dashboard low-stock path
**When** the screen is displayed
**Then** the selected Low Stock filter is visually clear
**And** the user can return to All products.

**Given** Dashboard and Products both use low-stock behavior
**When** product quantity or threshold data changes
**Then** both areas rely on the same low-stock rule
**And** duplicate inconsistent low-stock logic is avoided.

### Story 4.5: Show Recent Activity Preview

**Requirements:** FR-003, FR-034, FR-035, UX-DR9, UX-DR22

As a store owner or helper,
I want to see recent stock movements on the dashboard,
So that I can quickly verify what changed recently.

**Acceptance Criteria:**

**Given** stock movements exist
**When** the Dashboard loads
**Then** it shows a recent activity preview with the latest movements
**And** each item includes movement type, product name snapshot, changed quantity, and time.

**Given** a movement has an optional note
**When** it appears in the Dashboard preview
**Then** the preview may show the note only if it fits the compact layout
**And** the full note remains available in History.

**Given** no stock movements exist
**When** the Dashboard loads
**Then** the recent activity area shows friendly empty copy
**And** it guides the user that stock movements will appear after Stock In or Stock Out.

**Given** the recent activity preview is interactive
**When** the user taps the preview or view-all action
**Then** the app navigates to History
**And** no movement data is modified.

### Story 4.6: Protect Dashboard Behavior With Tests

**Requirements:** FR-001, FR-002, FR-003, FR-005, FR-021, FR-022, NFR-003, NFR-004

As a developer maintaining dashboard logic,
I want dashboard summary and navigation tests,
So that the dashboard stays accurate as inventory features evolve.

**Acceptance Criteria:**

**Given** dashboard summary tests run
**When** active and archived products exist
**Then** tests verify total product count excludes archived products
**And** active products are counted correctly.

**Given** low-stock summary tests run
**When** products are below, equal to, and above their thresholds
**Then** tests verify low-stock count includes quantity equal to threshold
**And** out-of-stock products are treated as needing attention.

**Given** Stock Changes Today tests run
**When** movements exist around UTC/local day boundaries
**Then** tests verify the dashboard uses the device or app local timezone day
**And** UTC storage does not shift the user's visible "today" count.

**Given** dashboard widget tests run
**When** loading, empty, error, and populated states are rendered
**Then** tests verify the correct user-facing state appears
**And** raw technical errors are not shown.

**Given** dashboard navigation tests run
**When** the user taps the low-stock dashboard path
**Then** tests verify Products opens with the Low Stock filter selected
**And** the route works offline.

## Epic 5: Settings And Release Readiness

Users can view basic app settings and future backup/export expectations while the MVP receives polish and release-quality safeguards.

### Story 5.1: Build Settings Screen

**Requirements:** FR-037, FR-038, FR-039, FR-040, UX-DR24

As a store owner,
I want to see basic app settings,
So that I understand the app's local setup and future options.

**Acceptance Criteria:**

**Given** the user opens Settings
**When** the screen loads
**Then** it shows basic settings sections for currency, backup/export, app version, and local data/privacy note where appropriate
**And** the screen works without internet.

**Given** MVP scope is enforced
**When** Settings is implemented
**Then** it does not require login
**And** it does not expose fake cloud sync, account management, supplier, POS, barcode scanner, or accounting settings.

**Given** Settings data is unavailable or fails to load
**When** the screen displays an error state
**Then** the app shows friendly recovery copy
**And** raw technical errors are not shown.

### Story 5.2: Show PHP Currency Context

**Requirements:** FR-038

As a store owner in the Philippines,
I want the app to use PHP as the default currency context,
So that product prices feel familiar and clear.

**Acceptance Criteria:**

**Given** the user opens Settings
**When** the currency section is displayed
**Then** PHP is shown as the MVP currency context
**And** no editable multi-currency selector is introduced.

**Given** product prices are displayed elsewhere in the app
**When** price formatting is used
**Then** formatting follows the centralized PHP currency context
**And** formatting behavior is consistent across product and settings surfaces.

**Given** future multi-currency support is considered
**When** MVP settings are reviewed
**Then** the implementation remains simple enough to extend later
**And** it does not require UI rewrite for future currency options.

### Story 5.3: Add Honest Backup/Export Placeholder

**Requirements:** FR-039, UX-DR8, UX-DR24

As a store owner,
I want to know backup/export is planned but not active yet,
So that I am not misled about data protection.

**Acceptance Criteria:**

**Given** the user opens Settings
**When** the Backup/Export item is displayed
**Then** it is clearly labeled as "Coming soon" or equivalent plain copy
**And** it does not imply that backup is currently active.

**Given** the user taps or views the Backup/Export placeholder
**When** explanatory copy is shown
**Then** it explains that MVP data is stored locally on the device
**And** it does not require login or network access.

**Given** MVP scope is enforced
**When** backup/export placeholder is implemented
**Then** no fake export file, cloud sync service, login route, or remote API client is added
**And** future backup/export remains a separately scoped feature.

### Story 5.4: Show App Version From Pubspec

**Requirements:** FR-040

As a store owner or tester,
I want to see the app version,
So that support and testing can identify which build is installed.

**Acceptance Criteria:**

**Given** the user opens Settings
**When** the app version row is displayed
**Then** it shows the installed app version from package metadata or `pubspec.yaml`
**And** the visible version is not hardcoded separately in UI copy.

**Given** the app runs in debug or release mode
**When** Settings displays app version
**Then** the version display works consistently
**And** it can support build identification during testing.

### Story 5.5: Complete MVP UX Polish And Accessibility Pass

**Requirements:** NFR-006, NFR-007, NFR-008, UX-DR25, UX-DR26, UX-DR27, UX-DR28, UX-DR29, UX-DR30

As a store owner or helper,
I want the app to feel clear, readable, and forgiving,
So that I can use it confidently during daily store work.

**Acceptance Criteria:**

**Given** all MVP screens are available
**When** Dashboard, Products, Add Product, Edit Product, Stock In, Stock Out, History, and Settings are reviewed
**Then** copy is plain, helpful, and Filipino-friendly English
**And** technical words like raw database errors, "entity," or "inventory mutation" are not shown to users.

**Given** common UI states are reviewed
**When** loading, empty, error, validation, and success states appear
**Then** each state gives clear feedback or a next step
**And** messages are consistent with the approved UX tone.

**Given** accessibility is reviewed
**When** common controls and warning states are inspected
**Then** tap targets follow the 48dp floor where applicable
**And** warnings do not rely on color alone.

**Given** core operational flows are reviewed
**When** Add Product, Edit Product, Stock In, and Stock Out are used
**Then** no ads, login prompts, cloud prompts, or monetization interruptions appear
**And** actions remain focused on local inventory work.

### Story 5.6: Complete MVP Release Readiness Checks

**Requirements:** NFR-001, NFR-002, NFR-005, NFR-006, NFR-009, NFR-010

As a developer preparing the MVP,
I want release-readiness checks to pass,
So that the app is stable enough for testing or first distribution.

**Acceptance Criteria:**

**Given** implementation is ready for MVP verification
**When** quality checks run
**Then** Flutter analysis, unit tests, repository transaction tests, widget tests, and Drift migration tests pass
**And** failures are addressed before release handoff.

**Given** offline behavior is verified
**When** the app is used without internet
**Then** core product, stock movement, dashboard, history, and settings flows remain usable
**And** no workflow requires login or cloud services.

**Given** release readiness is reviewed
**When** the app is prepared for testing or distribution
**Then** no debug-only UI, test keys, raw exception messages, or fake future features are visible
**And** app version display is correct.

**Given** MVP scope exclusions are checked
**When** the codebase and routes are reviewed
**Then** POS, supplier management, accounting/profit reports, cloud sync, barcode scanner UI, staff roles, multi-branch management, and remote API client layers remain absent
**And** deferred features are not partially implemented without scope approval.
