---
title: "EXPERIENCE: Inventory Tracker Android App"
status: final
created: 2026-05-28
updated: 2026-05-28
platform: android
visual_identity: DESIGN.md
sources:
  - ../../prds/prd-Inventory-2026-05-28/prd.md
---

# EXPERIENCE: Inventory Tracker Android App

## Foundation

Form factor: Android mobile app.

UI system: Flutter Material 3, customized with tokens from `DESIGN.md`.

Audience: non-technical sari-sari store owners, helpers, and home-based sellers who need fast offline inventory tracking.

Core UX promise: the app should answer "what do I have, what is low, and what changed?" without requiring internet or advanced setup.

## Information Architecture

Primary navigation:

1. Dashboard
2. Products
3. History
4. Settings

Secondary screens:

- Splash
- Future Login
- Add Product
- Edit Product
- Stock In
- Stock Out

Navigation model:

```text
Splash
  -> Dashboard

Dashboard
  -> Products
  -> Low Stock filtered Products
  -> History
  -> Settings

Products
  -> Add Product
  -> Edit Product
  -> Stock In
  -> Stock Out

History
  -> Product detail reference, future

Settings
  -> Future Login
  -> Backup/export placeholder
```

## Voice And Tone

Voice should be plain, helpful, and action-oriented.

Use:

- "Add Product"
- "Record Stock In"
- "Record Stock Out"
- "Low Stock"
- "Out of Stock"
- "Not enough stock available"
- "Saved"

Avoid:

- "Inventory mutation"
- "Entity"
- "Transaction failed due to constraint"
- "SKU required" unless SKU is later added

## Screen Specifications

### Splash Screen

Purpose: initialize local app services and route to Dashboard.

Content:

- App name or logo.
- Small loading indicator.

Behavior:

- If local database opens successfully, navigate to Dashboard.
- If initialization fails, show a simple retry state.

### Future Login Screen

MVP status: future-ready, not required by default.

Purpose: support future cloud backup and sync without blocking offline use.

Primary actions:

- Continue Offline.
- Sign In for Backup, future.

Rule:

- The user must never be forced to sign in for MVP local inventory tracking.

### Dashboard

Purpose: give a quick operational snapshot.

Content:

- Header: "Inventory Today".
- Summary cards:
  - Total Products.
  - Low Stock.
  - Stock Changes Today.
- Low-stock preview.
- Recent activity preview.

Primary actions:

- Add Product.
- View Products.
- View Low Stock.

Empty state:

- If no products exist, show a clear first action: "Add your first product".

### Product List

Purpose: browse, search, and act on products.

Content:

- Search field.
- Filter chips:
  - All.
  - Low Stock.
  - Out of Stock.
- Product rows.
- Add Product floating action button.

Product row behavior:

- Tap row opens Edit Product or product action sheet depending on implementation preference.
- Quick actions should allow Stock In, Stock Out, and Edit.
- Low-stock and out-of-stock states are visible without opening details.

Empty states:

- No products: prompt to add the first product.
- No search results: show "No matching products".

### Add Product

Purpose: create a tracked product.

Fields:

- Product name, required.
- Category, optional.
- Unit, default "pcs".
- Selling price, optional but available.
- Cost price, optional.
- Starting quantity, required and non-negative.
- Low-stock threshold, required and non-negative.

Behavior:

- Save button remains enabled but validates on submit, or disables only when invalidity is obvious.
- On success, return to Product List and show "Product saved".
- On validation failure, focus the first invalid field.

### Edit Product

Purpose: update product details without losing history.

Fields:

- Same as Add Product.

Behavior:

- Quantity can be edited only if the product model allows manual adjustment; preferred MVP behavior is to change stock through Stock In/Out.
- Archive is secondary and requires confirmation.
- On save, show "Product updated".

### Stock In

Purpose: record added inventory.

Content:

- Product name.
- Current quantity.
- Quantity input.
- Optional note.
- Primary action: "Record Stock In".

Validation:

- Quantity must be greater than zero.

Success:

- Show new quantity.
- Return to previous screen or stay with confirmation depending on flow.

### Stock Out

Purpose: record removed/sold/lost inventory.

Content:

- Product name.
- Current quantity.
- Quantity input.
- Optional note.
- Primary action: "Record Stock Out".

Validation:

- Quantity must be greater than zero.
- Quantity cannot exceed current stock.

Blocked state:

- Show "Not enough stock available" near quantity field.
- Do not update product quantity.

### Inventory History

Purpose: audit stock movement.

Content:

- Newest transactions first.
- Optional date grouping.
- Each row:
  - Stock In or Stock Out label.
  - Product name.
  - Quantity changed.
  - Previous quantity to new quantity.
  - Date/time.
  - Note when present.

Empty state:

- "Stock changes will appear here."

### Settings

Purpose: keep configuration and future growth visible without cluttering core workflows.

Content:

- Business name placeholder, future.
- Currency: PHP.
- Backup/export placeholder.
- App version.
- Privacy and data note, future.

Behavior:

- Backup/export item can show "Coming soon".

## Component Patterns

### Bottom Navigation

Items:

- Dashboard.
- Products.
- History.
- Settings.

Rules:

- Keep labels visible.
- Do not add more than four primary tabs in MVP.

### Search

- Search runs locally.
- Query should match product name.
- Category matching is allowed but not required.
- Keep input responsive for thousands of products.

### Filters

Use segmented chips for:

- All.
- Low Stock.
- Out of Stock.

Selected filter should be visually clear.

### Forms

- Use vertical forms.
- Show labels above or inside fields consistently.
- Show inline validation.
- Keep save action fixed near bottom on long forms where practical.

### Feedback

Use snackbars or inline banners for:

- Saved.
- Product updated.
- Stock recorded.
- Not enough stock.
- Something went wrong.

Do not expose raw database or exception messages.

## State Patterns

### Loading

- Dashboard: lightweight skeleton or spinner.
- Product list: list skeleton preferred.
- Forms: disable save button and show small progress indicator.

### Empty

- Empty states include an action when possible.
- Product empty state should lead to Add Product.
- History empty state should explain that stock movements will appear there.

### Error

- Use plain recovery text.
- Include retry for initialization or data loading failures.
- Keep destructive retry flows out of stock movement.

### Low Stock

- Low stock appears when quantity is equal to or below threshold.
- Out of stock overrides low stock visually.

## Interaction Primitives

- Tap primary cards to navigate to filtered lists.
- Use direct row actions for frequent inventory tasks.
- Confirmation is required for archive, but not for normal stock in/out after validation.
- Use keyboard type numeric for quantity and price fields.
- Dismiss keyboard on save.
- Keep forms scrollable for small screens.

## Accessibility Floor

- Minimum tap target: 48dp.
- Text should remain readable at system font scaling.
- Warnings should not rely on color alone; include labels.
- Inputs must have accessible labels.
- Error messages must be associated with relevant fields.
- Do not use motion as the only feedback.

## Key Flows

### UJ-001: Aling Maria Adds Her First Product

1. Maria opens the app and lands on Dashboard.
2. The empty state prompts her to add a product.
3. She enters product name, unit, starting quantity, and low-stock threshold.
4. She saves the product.
5. The app returns to Products and shows the new item.

Climax: Maria sees that her notebook item now exists in a searchable product list.

### UJ-002: Jun Records A Sale As Stock Out

1. Jun opens Products.
2. He searches for the sold item.
3. He taps Stock Out on the product row.
4. He enters the sold quantity.
5. The app validates available stock.
6. He records stock out.
7. The product quantity updates and history records the movement.

Climax: Jun updates stock without editing product details or calculating the new quantity manually.

### UJ-003: Maria Checks What To Restock

1. Maria opens Dashboard.
2. She sees a Low Stock summary.
3. She taps the low-stock summary.
4. Products opens with Low Stock filter applied.
5. She reviews the list before buying supplies.

Climax: Maria gets a restock list without scanning every item.

### UJ-004: Bea Audits Inventory Changes

1. Bea opens History.
2. She reviews the newest stock movements.
3. She checks previous and new quantities for a product.
4. She uses notes to understand why stock changed.

Climax: Bea can explain why the current quantity changed.

## Responsive And Platform Notes

- Portrait phone layout is primary.
- Landscape should remain usable but does not need optimized tablet layouts in MVP.
- Support small Android screens by keeping forms scrollable.
- Avoid large hero sections.
- Avoid image-heavy assets in operational screens.

## Implementation Handoff Notes

- Use `DESIGN.md` tokens in Flutter theme setup.
- Treat `EXPERIENCE.md` screen specs as source for routes and widgets.
- Keep ads out of product form and stock movement screens.
- Preserve offline-first behavior in every primary flow.
