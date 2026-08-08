---
id: SPEC-barcode-camera-scan
companions: []
sources: []
---

> **Canonical contract.** This SPEC is the complete, preservation-validated contract for what to build, test, and validate.

# Barcode Camera Scan

## Why

Product barcode storage already exists, but typing barcodes by hand is slow and error-prone for store inventory work. Users adding or editing a product need a faster input path that can read a physical barcode through the device camera while preserving the existing manual field.

## Capabilities

- id: CAP-1
  intent: Users can launch camera barcode scanning from the existing Add Product barcode input.
  success: From Add Product, tapping the scan control opens a scanner; a successful scan writes the scanned barcode into `barcode-field` and the product can be saved through the existing form flow.
- id: CAP-2
  intent: Users can launch camera barcode scanning from the existing Edit Product barcode input.
  success: From Edit Product, tapping the scan control opens a scanner; a successful scan writes the scanned barcode into `edit-barcode-field` and the product can be saved through the existing update flow.
- id: CAP-3
  intent: Users can still type, clear, or replace barcodes manually when scanning is unavailable or unwanted.
  success: The barcode field remains editable; scanner cancel, permission denial, or scanner failure does not erase the current field value or block manual entry.
- id: CAP-4
  intent: The app preserves existing barcode validation and duplicate-barcode behavior after scanner input.
  success: A scanned barcode is submitted through the same product form/repository path as a typed barcode, including normalization and duplicate handling.

## Constraints

- Scanning must be optional and must not remove manual barcode entry.
- The feature targets the app's mobile Flutter experience and must request/use camera access only when the user starts scanning.
- Scanner results must populate the existing barcode controllers rather than introducing a separate product data path.
- Cancelled scans and scanner errors must return users to the product form without losing unsaved form values.

## Non-goals

- Product lookup by barcode is out of scope.
- Batch scanning multiple products is out of scope.
- Generating or printing barcodes is out of scope.
- Changing the barcode database schema is out of scope.

## Success signal

On a mobile device, a user can add or edit a product, tap a scan control beside the barcode field, scan a physical barcode, see that value in the barcode field, and save without typing the barcode. If scanning is cancelled or unavailable, the form remains intact and manual entry still works.

## Assumptions

- Android camera scanning is the first required platform because the current release path is APK-focused.
- A maintained Flutter barcode scanning package can be added if it works with the current Flutter SDK and Android build.
- The scan control should live near the barcode input on both Add Product and Edit Product screens.

## Open Questions

- Should the first implementation support iOS permissions/configuration too, or Android only for this release?
- Should the scanner accept all common barcode formats or restrict to retail formats such as EAN/UPC/Code 128?
- Should the app show a short message when camera permission is denied, or is returning to the field enough?
