---
title: 'Barcode Camera Scan'
type: 'feature'
created: '2026-08-08'
status: 'done'
baseline_commit: '741dfe4db47a9336bc312c7b8cd7c20b6312ebae'
context:
  - '{project-root}/_bmad-output/specs/spec-barcode-camera-scan/SPEC.md'
---

<frozen-after-approval reason="human-owned intent - do not modify unless human renegotiates">

## Intent

**Problem:** Products already support an optional barcode value, but users must type the barcode manually. This is slow and error-prone when adding or editing products from physical stock.

**Approach:** Add an optional camera-scan action beside the existing barcode inputs on Add Product and Edit Product. A successful scan writes the detected barcode into the same text controller used by manual entry, so save/update behavior continues through the current validation, normalization, and duplicate-barcode paths.

## Boundaries & Constraints

**Always:** Preserve manual barcode typing, clearing, and replacement. Target Android APK behavior first. Use camera access only after the user starts scanning. Keep scanner output on the existing form fields/controllers. Return to the product form without losing unsaved values on cancel, permission denial, or scanner failure. Show a short snackbar when scanning fails or camera permission is unavailable. Support common retail barcode formats, including EAN, UPC, and Code 128.

**Ask First:** Adding product lookup by barcode, changing barcode uniqueness/storage rules, supporting batch scanning, or expanding beyond barcode field population. Adding iOS-only configuration beyond what the selected Flutter package requires should be confirmed separately.

**Never:** Do not introduce a separate barcode persistence path. Do not make scanning mandatory. Do not erase an existing barcode when the scanner closes without a result. Do not change product quantity or stock movement behavior.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Add scan success | Add Product has any unsaved form values and scanner returns `4801234567890` | `barcode-field` contains `4801234567890`; other fields keep their values; Save Product submits the barcode through the existing form flow | N/A |
| Edit scan success | Edit Product has an existing or manually changed barcode and scanner returns `012345678905` | `edit-barcode-field` is replaced with `012345678905`; unsaved-change detection treats the scanned value like typed input | N/A |
| Cancel scan | User opens scanner then backs out before a barcode is detected | User returns to the same form; barcode and other unsaved fields remain unchanged | No error message required |
| Permission or scanner failure | Camera permission is denied or scanner cannot start/read | User returns to the same form; current barcode remains unchanged; manual entry remains available | Show a short snackbar explaining that barcode scanning is unavailable |
| Duplicate scanned barcode | Scanner writes a barcode already used by another product, then user saves | Existing duplicate-barcode validation/message is shown through the current controller/repository path | No scanner-specific duplicate handling |

</frozen-after-approval>

## Code Map

- `tindatrack/pubspec.yaml` -- Add the maintained scanner dependency used by the camera scanner screen.
- `tindatrack/android/app/src/main/AndroidManifest.xml` -- Declare Android camera permission for scanner access.
- `tindatrack/lib/app/router/app_routes.dart` -- Add a Products child route identity for barcode scanning.
- `tindatrack/lib/app/router/app_router.dart` -- Register the scanner screen route and allow route-builder injection in tests.
- `tindatrack/lib/features/products/presentation/screens/add_product_screen.dart` -- Replace the barcode field call with scan-enabled barcode input handling.
- `tindatrack/lib/features/products/presentation/screens/edit_product_screen.dart` -- Replace the edit barcode field call with scan-enabled barcode input handling.
- `tindatrack/lib/features/products/presentation/screens/barcode_scanner_screen.dart` -- New camera scanner screen that returns a barcode string through the Navigator.
- `tindatrack/lib/features/products/presentation/widgets/barcode_input_field.dart` -- New reusable barcode text field with a scan icon action and accessible label.
- `tindatrack/test/features/products/presentation/screens/add_product_screen_test.dart` -- Cover scan result population, cancel preservation, and scan failure snackbar on Add Product.
- `tindatrack/test/features/products/presentation/screens/edit_product_screen_test.dart` -- Cover scan result population and unsaved-change behavior on Edit Product.

## Tasks & Acceptance

**Execution:**
- [x] `tindatrack/pubspec.yaml` -- Add `mobile_scanner` and refresh lockfile -- Required to access device camera barcode scanning.
- [x] `tindatrack/android/app/src/main/AndroidManifest.xml` -- Add camera permission -- Required for Android runtime camera access.
- [x] `tindatrack/lib/features/products/presentation/screens/barcode_scanner_screen.dart` -- Implement a single-result scanner screen that pops the first non-empty barcode value -- Provides the camera flow.
- [x] `tindatrack/lib/app/router/app_routes.dart` and `tindatrack/lib/app/router/app_router.dart` -- Add scanner route under Products -- Keeps navigation consistent with existing product child flows.
- [x] `tindatrack/lib/features/products/presentation/widgets/barcode_input_field.dart` -- Add reusable scan-enabled barcode field -- Avoids duplicated Add/Edit field decoration logic.
- [x] `tindatrack/lib/features/products/presentation/screens/add_product_screen.dart` and `tindatrack/lib/features/products/presentation/screens/edit_product_screen.dart` -- Wire scan action to update existing barcode controllers and show snackbar on failure -- Satisfies the user-visible feature while preserving form behavior.
- [x] Product screen tests -- Add focused widget tests with injected scanner route results/failures -- Covers the I/O matrix without depending on real camera hardware.

**Acceptance Criteria:**
- Given Add Product has unsaved field values, when scanner navigation returns a barcode, then only the barcode field is updated and the existing save flow receives that value.
- Given Edit Product has an existing barcode, when scanner navigation returns a barcode, then the edit barcode field is replaced and unsaved-change handling recognizes the replacement.
- Given scanner navigation returns null, when the user comes back to the form, then the previous barcode value remains unchanged and no error snackbar is shown.
- Given scanner navigation throws, when the user returns to the form, then a scanner-unavailable snackbar is shown and manual barcode entry still works.
- Given a scanned barcode duplicates another product, when the form is saved, then the existing duplicate-barcode validation path handles the error.

## Spec Change Log

- Review patch: ignored transient `MobileScanner` detection errors instead of closing the scanner; startup/permission failures still return scanner-unavailable. Avoids prematurely ejecting users on recoverable camera frames. KEEP: scanner screen returns `false` only for screen-level scanner unavailability.
- Review patch: added Add/Edit in-flight scan guards and rapid-tap tests. Avoids duplicate scanner route stacks and racing scan results. KEEP: manual field editing remains enabled independently of scan-button state.
- Review patch: declared Android camera hardware optional and expanded Add/Edit acceptance tests for cancel, failure, missing route, duplicate scanned barcode, and rapid taps. Avoids excluding no-camera devices and locks the expected fallback behavior.

## Design Notes

Use `mobile_scanner` because its current pub.dev package supports Android with CameraX/ML Kit, common barcode formats, and a permissive BSD-3-Clause license. Keep package usage inside the scanner screen so form widget tests can inject fake scanner route results without initializing camera hardware.

## Verification

**Commands:**
- `dart format lib test` from `tindatrack/` -- expected: modified Dart files are formatted.
- `flutter test test/features/products/presentation/screens/add_product_screen_test.dart test/features/products/presentation/screens/edit_product_screen_test.dart` from `tindatrack/` -- expected: focused product form tests pass.
- `flutter build apk --debug` from `tindatrack/` -- expected: Android plugin/manifest integration builds successfully.

**Manual checks (if CLI is blocked by WSL/Windows tooling):**
- On an Android device/emulator, open Add Product and Edit Product, tap the scan icon beside Barcode, grant camera permission, scan a retail barcode, confirm the field fills, then save.


## Suggested Review Order

**Form Entry Points**

- Add Product wires scan into the existing barcode controller.
  [`add_product_screen.dart:148`](../../tindatrack/lib/features/products/presentation/screens/add_product_screen.dart#L148)

- Edit Product mirrors the same scan-enabled barcode input.
  [`edit_product_screen.dart:234`](../../tindatrack/lib/features/products/presentation/screens/edit_product_screen.dart#L234)

- In-flight guards prevent stacked scanner routes and reset safely.
  [`add_product_screen.dart:200`](../../tindatrack/lib/features/products/presentation/screens/add_product_screen.dart#L200)

**Scanner Route**

- Product child route centralizes scanner navigation identity.
  [`app_routes.dart:40`](../../tindatrack/lib/app/router/app_routes.dart#L40)

- Router registers the scanner under the Products branch.
  [`app_router.dart:92`](../../tindatrack/lib/app/router/app_router.dart#L92)

- Scanner returns one supported retail barcode or scanner-unavailable.
  [`barcode_scanner_screen.dart:30`](../../tindatrack/lib/features/products/presentation/screens/barcode_scanner_screen.dart#L30)

**Shared UI**

- Reusable barcode field keeps manual entry separate from scan enablement.
  [`barcode_input_field.dart:56`](../../tindatrack/lib/features/products/presentation/widgets/barcode_input_field.dart#L56)

**Android Integration**

- Camera permission is declared without requiring camera hardware.
  [`AndroidManifest.xml:2`](../../tindatrack/android/app/src/main/AndroidManifest.xml#L2)

**Regression Coverage**

- Add Product covers scan success, cancel, failure, rapid taps, and duplicates.
  [`add_product_screen_test.dart:333`](../../tindatrack/test/features/products/presentation/screens/add_product_screen_test.dart#L333)

- Edit Product covers scanned unsaved changes, cancel, failure, and rapid taps.
  [`edit_product_screen_test.dart:240`](../../tindatrack/test/features/products/presentation/screens/edit_product_screen_test.dart#L240)
