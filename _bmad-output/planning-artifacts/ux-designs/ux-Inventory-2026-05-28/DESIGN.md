---
title: "DESIGN: Inventory Tracker Android App"
status: final
created: 2026-05-28
updated: 2026-05-28
platform: android
sources:
  - ../../prds/prd-Inventory-2026-05-28/prd.md
tokens:
  colors:
    background: "#F8FAF7"
    surface: "#FFFFFF"
    surfaceMuted: "#EEF3EE"
    textPrimary: "#172018"
    textSecondary: "#5E6B60"
    primary: "#2E7D4F"
    primaryPressed: "#24643F"
    success: "#2E7D4F"
    warning: "#B7791F"
    warningSurface: "#FFF7E0"
    danger: "#B42318"
    dangerSurface: "#FDECEC"
    border: "#DDE5DD"
  typography:
    family: "System default / Roboto"
    display: "28sp, weight 700"
    title: "20sp, weight 700"
    section: "16sp, weight 700"
    body: "14sp, weight 400"
    label: "12sp, weight 600"
  rounded:
    small: 6
    medium: 8
    large: 12
  spacing:
    xs: 4
    sm: 8
    md: 16
    lg: 24
    xl: 32
  components:
    cardRadius: 8
    buttonRadius: 8
    inputRadius: 8
    minimumTapTarget: 48
---

# DESIGN: Inventory Tracker Android App

## Brand & Style

The app should feel like a reliable store notebook upgraded into a clean mobile tool. It should be calm, practical, and direct. The visual language should help owners act quickly without feeling like they are using a complex POS or accounting platform.

Style principles:

- Practical over decorative.
- Readable over compact.
- Clear status over visual flourish.
- Friendly but not playful.
- Lightweight enough for low-end Android phones.

## Colors

Use a light, fresh, utilitarian palette:

- `background`: soft off-white for full-screen app surfaces.
- `surface`: white for cards, sheets, and form areas.
- `primary`: grounded green for main actions and positive inventory movement.
- `warning`: amber for low-stock warnings.
- `danger`: red only for destructive actions, invalid stock out, and critical errors.
- `border`: quiet dividers and form outlines.

Color usage:

- Stock In uses `success`/`primary`.
- Stock Out uses neutral text unless blocked or risky.
- Low Stock uses `warning` and `warningSurface`.
- Out of Stock uses `danger` and `dangerSurface`.

Do not use large decorative gradients or heavy brand color backgrounds.

## Typography

Use Android system typography or Roboto. Text must stay readable on small phones.

- Dashboard headline: `display`.
- Screen title: `title`.
- Section labels and card headers: `section`.
- Product row names: `body` with medium or semibold weight.
- Metadata such as category, unit, and timestamp: `label` or small body.

Avoid viewport-scaled text. Avoid negative letter spacing.

## Layout & Spacing

Screens use a single-column mobile layout.

- Outer screen padding: 16dp.
- Between related controls: 8dp.
- Between sections: 16dp to 24dp.
- Summary cards: compact grid or horizontal scroll when space is limited.
- Product rows: full-width list items with stable height and clearly separated actions.

Bottom navigation should remain fixed on the main four sections: Dashboard, Products, History, Settings.

## Elevation & Depth

Keep elevation minimal:

- Cards use borders or very soft elevation.
- Form screens rely on spacing and sections, not stacked cards.
- Avoid nested cards.
- Avoid decorative floating panels.

## Shapes

Use modest radii:

- Cards: 8dp.
- Buttons: 8dp.
- Inputs: 8dp.
- Chips/status badges: 999dp only for small status pills.

## Components

### Primary Button

- Filled green.
- Used for Save, Add Product, Record Stock In, and Record Stock Out.
- Disabled state must be visibly inactive.

### Secondary Button

- Outlined or text button.
- Used for Cancel, Edit, and non-primary settings actions.

### Product Row

Shows:

- Product name.
- Category or unit.
- Current quantity.
- Status badge when low stock or out of stock.
- Quick action icons or concise action buttons.

### Summary Card

Shows one metric and one label:

- Total Products.
- Low Stock.
- Stock Changes Today.

### Status Badge

Use badges only for meaningful inventory states:

- Low Stock.
- Out of Stock.
- Archived if archive management is later exposed.

### Form Field

Use outlined fields with clear labels and helper/error text.

## Do's And Don'ts

Do:

- Use plain action labels.
- Keep stock movement forms short.
- Make validation messages specific.
- Keep low-stock warnings visible but not noisy.
- Use familiar Material icons.

Don't:

- Put ads in stock movement or product form flows.
- Hide core actions behind complex menus.
- Use dark, glossy, or finance-heavy styling.
- Show raw technical errors.
- Require login before local inventory use.
