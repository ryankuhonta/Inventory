---
title: "PRD: Inventory Tracker Android App"
status: final
created: 2026-05-28
updated: 2026-05-28
source: "../../../../docs/bmad-inventory-tracker-plan.md"
---

# PRD: Inventory Tracker Android App

## 1. Overview

Inventory Tracker is an offline-first Android application for sari-sari stores, small retailers, market stalls, and home-based sellers in the Philippines. The app helps owners and helpers track products, record stock movement, and identify low-stock items without relying on internet connectivity.

The MVP focuses on one operational promise: a store owner should quickly know what products exist, how many are left, and what changed recently.

## 2. Problem Statement

Many small Philippine retailers still track inventory through notebooks, memory, or informal messages. This creates recurring problems:

- Stock runs out before the owner notices.
- Inventory counts are hard to verify during busy selling hours.
- Multiple family members or helpers may update stock informally.
- Manual records can be lost, forgotten, or duplicated.
- Internet access may be unstable or unavailable, making online-first tools unreliable.

The product must make basic inventory discipline easy enough for daily store use.

## 3. Goals

- Help users maintain an accurate local product inventory.
- Make stock in and stock out fast to record.
- Surface low-stock and out-of-stock products clearly.
- Preserve a history of stock movement for simple auditability.
- Work fully offline on low-end Android devices.
- Establish a clean foundation for future cloud backup, monetization, and analytics.

## 4. Non-Goals For MVP

- Full point-of-sale checkout.
- Customer accounts or loyalty programs.
- Supplier management.
- Barcode or QR scanning.
- Cloud sync.
- Multi-user roles.
- Accounting, profit reports, taxes, and ledger management.
- Receipt printing.

## 5. Target Users

### Primary Persona: Aling Maria, Sari-Sari Store Owner

Aling Maria runs a neighborhood sari-sari store from home. She uses a low-end Android phone and wants a simple way to know what to restock. She does not want a complicated accounting or POS system.

Primary needs:

- See low-stock products quickly.
- Add common store items without confusion.
- Use the app even without internet.
- Trust that records remain after closing and reopening the app.

### Secondary Persona: Jun, Store Helper

Jun helps record stock changes while customers are being served. He needs quick search and simple stock movement actions without editing product details accidentally.

Primary needs:

- Find products quickly.
- Record stock out with minimal typing.
- Avoid mistakes like negative stock.
- See clear success or error feedback.

### Tertiary Persona: Bea, Home-Based Seller

Bea sells small products through Facebook and Messenger. Her main risk is overselling because she does not always remember current stock.

Primary needs:

- Keep product counts updated.
- Review movement history.
- Eventually back up data.

## 6. MVP Scope

### In Scope

- Dashboard summary.
- Product list.
- Add product.
- Edit product.
- Archive product.
- Search products.
- Stock in.
- Stock out.
- Inventory history.
- Low-stock alerts.
- Settings screen with future-ready backup/export placeholder.
- Local offline data persistence.

### Out Of Scope

- Login requirement.
- Online account management.
- Real cloud backup.
- Sales reports.
- Multi-branch management.
- Staff permissions.
- Push notifications.

## 7. User Experience Requirements

- The app must open into a useful dashboard after splash initialization.
- Navigation must be simple enough for non-technical users.
- Product and stock actions must use plain labels.
- Error states must explain what the user can do next.
- Empty states must be friendly and actionable.
- The app must avoid heavy animation and unnecessary visual clutter.
- Tap targets should be appropriate for one-handed Android usage.

## 8. Functional Requirements

### Dashboard

- FR-001: The app shall show total active products.
- FR-002: The app shall show the number of low-stock products.
- FR-003: The app shall show recent inventory activity.
- FR-004: The app shall provide navigation to Products, History, and Settings.
- FR-005: The app shall provide a clear path to view low-stock products.

### Product Management

- FR-006: The app shall allow the user to create a product.
- FR-007: Product creation shall require a product name.
- FR-008: Product creation shall support optional category.
- FR-009: Product creation shall support unit, defaulting to "pcs".
- FR-010: Product creation shall support quantity.
- FR-011: Product creation shall support low-stock threshold.
- FR-012: Product creation shall support selling price.
- FR-013: Product creation may support cost price.
- FR-014: The app shall allow users to edit existing product details.
- FR-015: The app shall allow users to archive products.
- FR-016: Archived products shall not appear in the default active product list.
- FR-017: Archived products shall retain their inventory history.

### Product List And Search

- FR-018: The app shall list active products.
- FR-019: The app shall support product search by name.
- FR-020: The app should support search or filtering by category.
- FR-021: The app shall visually identify low-stock products.
- FR-022: The app shall visually identify out-of-stock products.
- FR-023: The app shall provide quick access from a product row to edit, stock in, and stock out.

### Stock Movement

- FR-024: The app shall allow stock in for an existing product.
- FR-025: Stock in shall require a positive quantity.
- FR-026: Stock in shall increase the product quantity.
- FR-027: The app shall allow stock out for an existing product.
- FR-028: Stock out shall require a positive quantity.
- FR-029: Stock out shall decrease the product quantity.
- FR-030: Stock out shall be blocked if quantity exceeds available stock.
- FR-031: Stock movement shall support an optional note.
- FR-032: Successful stock movement shall create an inventory history entry.
- FR-033: Product quantity update and history entry creation shall succeed or fail together.

### Inventory History

- FR-034: The app shall show inventory transactions sorted newest first.
- FR-035: Each transaction shall show movement type, product, quantity, previous quantity, new quantity, and date/time.
- FR-036: The app shall show a friendly empty state when there is no history.

### Settings

- FR-037: The app shall show app settings.
- FR-038: The app shall show PHP as the default currency context.
- FR-039: The app shall show backup/export as a future-ready placeholder.
- FR-040: The app shall show app version information.

## 9. Non-Functional Requirements

- NFR-001: The app must work offline for all MVP features.
- NFR-002: The app must persist data locally after app restart.
- NFR-003: Core screens should remain responsive on low-end Android devices.
- NFR-004: The product list should handle at least 3,000 local products.
- NFR-005: Stock changes must be stored reliably and atomically.
- NFR-006: The app must not log sensitive inventory data in production.
- NFR-007: The app should use readable typography and accessible contrast.
- NFR-008: Common tap targets should be at least 48dp.
- NFR-009: The codebase should remain beginner-friendly and modular.
- NFR-010: MVP architecture should support future cloud sync without rewriting the UI.

## 10. User Stories

- US-001: As a store owner, I want to add products so that I can start tracking my inventory.
- US-002: As a store owner, I want to see all products so that I can check current stock.
- US-003: As a store owner, I want to see low-stock products so that I know what to restock.
- US-004: As a store helper, I want to record stock out quickly so that sold items are reflected in inventory.
- US-005: As a store owner, I want to record stock in so that new purchases increase available stock.
- US-006: As a store owner, I want to review inventory history so that I can audit stock changes.
- US-007: As a future premium user, I want backup/export so that I reduce the risk of data loss.

## 11. Acceptance Criteria

### AC-001: Add Product

Given the user opens Add Product, when all required fields are valid and the user saves, then the product is saved locally and appears in the product list.

Given the product name is empty, when the user saves, then the app blocks saving and shows a validation message.

Given quantity or low-stock threshold is negative, when the user saves, then the app blocks saving and shows a validation message.

### AC-002: Edit Product

Given an existing product, when the user changes valid product details and saves, then the product list reflects the updated details.

### AC-003: Archive Product

Given an existing product, when the user archives it, then it no longer appears in the active product list and its historical transactions remain available.

### AC-004: Stock In

Given a product has quantity 5, when the user records stock in quantity 10, then the product quantity becomes 15 and a stock-in transaction is created.

### AC-005: Stock Out

Given a product has quantity 5, when the user records stock out quantity 3, then the product quantity becomes 2 and a stock-out transaction is created.

Given a product has quantity 5, when the user attempts stock out quantity 6, then the app blocks the action and product quantity remains 5.

### AC-006: Low Stock

Given a product quantity is equal to or below its low-stock threshold, when the product appears in dashboard or product list, then it is shown as low stock.

### AC-007: Offline Persistence

Given the device has no internet, when the user adds products or records stock movement, then the app saves the changes locally.

Given the app is closed and reopened, when the user returns to product list and history, then previously saved data remains.

## 12. Edge Cases

- EC-001: Duplicate product names are allowed in MVP but should not crash or overwrite existing products.
- EC-002: Zero-stock products are valid and should display as out of stock.
- EC-003: Negative quantities are never valid.
- EC-004: Very large quantities should be constrained to a practical integer range.
- EC-005: Empty search results should show a clear no-result state.
- EC-006: Empty product list should guide users to add their first product.
- EC-007: Empty history should explain that stock movement will appear after stock in or stock out.
- EC-008: Product archive should not delete inventory transactions.
- EC-009: App interruption during stock movement should not create partial quantity/history updates.

## 13. Monetization Requirements And Ideas

MVP should remain useful without payment.

Future monetization options:

- Ad-supported free tier.
- Paid ad-free upgrade.
- One-time Pro unlock for backup/export, barcode scanning, and advanced reports.
- Subscription for cloud sync and multi-device access.

Monetization constraints:

- Ads must not appear inside Add Product, Edit Product, Stock In, or Stock Out flows.
- Paid features must not break local offline inventory tracking.

## 14. Risks And Limitations

- R-001: Users may expect POS features, so product positioning must clearly say inventory tracker.
- R-002: Local-only storage risks data loss if the device is damaged or reset.
- R-003: Manual input can still be forgotten during busy selling hours.
- R-004: Low-end Android performance may suffer if list rendering and database queries are inefficient.
- R-005: Ads may reduce trust if placed in operational workflows.

## 15. Success Metrics

- User can add first product in under one minute.
- User can record stock in or stock out in under three taps after selecting a product.
- Product list and dashboard load quickly on low-end Android devices.
- Zero known bugs allowing negative stock.
- Stock movement history matches product quantity changes during QA.

Counter-metrics:

- Users abandon product creation due to too many required fields.
- Users misunderstand the app as a full POS system.
- Ads interrupt operational flows.

## 16. Release Readiness Criteria

The MVP is ready for implementation handoff when:

- Product CRUD requirements are accepted.
- Stock in/out atomicity is accepted as a hard requirement.
- Low-stock behavior is accepted.
- UX flow is designed for Dashboard, Products, Add/Edit Product, Stock In, Stock Out, History, and Settings.
- Architecture confirms local database, repository boundaries, and future sync readiness.
- Epics and stories are created from this PRD.

## 17. Open Questions

- What final app name should be used: TindaTrack, SariStock, Bantay Inventory, Tindahan Tracker, or another name?
- Should MVP copy be English-only, Taglish, or Filipino-first?
- Should cost price be included in MVP or deferred to reporting/profit features?
- Should archive be visible to users in MVP, or only implemented internally?
- What is the preferred first release path: private APK testing or Play Store internal testing?
