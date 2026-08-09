---
title: 'CSV Import / Restore for Products'
type: 'feature'
created: '2026-08-10'
status: 'done'
baseline_commit: 'da716abcce12831354ed4a29edd8e5ce77e6ffca'
context: []
---

<frozen-after-approval reason="human-owned intent - do not modify unless human renegotiates">

## Intent

**Problem:** TindaTrack can export Products and Stock History CSV files, but there is no matching way to restore product catalog data from a Products CSV after moving devices, testing builds, or recovering local data.

**Approach:** Add a products-only CSV import flow from App Info that lets the user pick a CSV file, previews validation results, and only applies valid rows after explicit confirmation. The import uses the existing Products CSV schema, preserves each row's Active/Archived status, and rejects duplicate non-empty barcodes with a friendly report before writing.

## Boundaries & Constraints

**Always:** Import only the Products CSV columns exported today: `Product Name`, `Category`, `Unit`, `Selling Price`, `Current Quantity`, `Low Stock Threshold`, `Barcode`, `Status`, `Created At`, `Updated At`. Show a preview summary before import and require a second user action to apply. Treat blank category and barcode as null. Preserve `Status` as active or archived. Insert imported products as new product rows with fresh app IDs; keep imported stock quantity as the product's current quantity. Validate required fields and numeric values using the same practical product rules as Add Product. Reject the import if any row has errors, if duplicate non-empty barcodes appear inside the CSV, or if any non-empty CSV barcode already exists in active or archived products.

**Ask First:** If implementation reveals that Android file picking requires a new third-party package instead of a small platform-channel extension, pause before adding the dependency. If importing historical `Created At` / `Updated At` would require schema or repository behavior that risks existing update semantics, ask before preserving those timestamps.

**Never:** Do not import Stock History CSV rows in this scope. Do not merge into existing products, update products, restore existing archived product rows by matching name/barcode, delete current data, or create stock movement history rows. Do not silently skip invalid rows while importing the rest.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Export round trip preview | User selects a Products CSV created by current export, with active and archived rows | Preview shows row count, active count, archived count, and zero blocking errors | N/A |
| Confirm valid import | Preview has no errors and user taps import | New products are inserted with fresh IDs, current quantities from CSV, null blanks normalized, and archived rows remain hidden from active product list | If persistence fails, show failure and keep user on preview |
| Missing/wrong file | User selects Stock History CSV or a file missing required product headers | Preview/app shows clear invalid-file message and no database write | No rows are imported |
| Bad row values | Required text is blank, price is not numeric, quantity/threshold is negative or too large, or status is not Active/Archived | Preview lists row-specific blocking errors | Import button is disabled |
| Duplicate barcode | Barcode repeats in the CSV or already exists in active/archived database rows | Preview lists duplicate barcode errors | Import button is disabled |
| User cancels picker | Android picker returns no file | App returns to App Info without failure noise | No database write |

</frozen-after-approval>

## Code Map

- `tindatrack/lib/features/settings/domain/services/csv_export_builder.dart` -- Defines the canonical Products CSV headers and escaping behavior that import should accept.
- `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart` -- App Info screen currently owns Backup / Export actions; add the import entry point and preview/apply UI flow here or in a small settings screen/dialog owned by it.
- `tindatrack/lib/features/settings/presentation/providers/csv_export_providers.dart` -- Existing Settings controller/provider pattern for CSV operations and Android method-channel handoffs; add import providers/controllers nearby.
- `tindatrack/lib/features/products/domain/validation/product_validator.dart` -- Canonical product validation rules for name, unit, price, quantity, and low-stock threshold.
- `tindatrack/lib/features/products/data/repositories/drift_products_repository.dart` -- Product persistence boundary; extend with a bulk import method or an import-specific repository service that maps SQLite failures to typed results.
- `tindatrack/lib/core/database/daos/products_dao.dart` -- Existing insert/list helpers and all-products export query; add import-support helpers if repository needs an atomic transaction or barcode lookup.
- `tindatrack/android/app/src/main/kotlin/com/rkuhonta/tindatrack/MainActivity.kt` -- Existing Android CSV export channel; likely extension point for selecting and reading a CSV file without introducing a new Flutter dependency.
- `tindatrack/test/features/settings/...` and `tindatrack/test/features/products/...` -- Existing focused test style for CSV services, providers, screens, repositories, and DAO behavior.

## Tasks & Acceptance

**Execution:**
- [x] `tindatrack/lib/features/settings/domain/services/csv_import_parser.dart` -- Add a small RFC4180-compatible parser/validator for the exported Products CSV schema -- keeps preview deterministic and unit-testable.
- [x] `tindatrack/lib/features/settings/domain/entities/csv_import_preview.dart` -- Add preview/result models with counts, row errors, pending rows, and success summary -- avoids stringly typed controller state.
- [x] `tindatrack/lib/features/settings/presentation/providers/csv_import_providers.dart` -- Add controller methods to pick, preview, and apply import; depend on product validation, product persistence, clock/id generation, and platform handoff abstractions.
- [x] `tindatrack/lib/features/products/domain/repositories/products_repository.dart`, `tindatrack/lib/features/products/data/repositories/drift_products_repository.dart`, `tindatrack/lib/core/database/daos/products_dao.dart` -- Add atomic products import support that prechecks barcodes across active and archived rows and inserts all rows or none.
- [x] `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart` -- Add Import Products CSV action, preview dialog/screen, disabled import state for errors, confirmation/apply state, success and failure snackbars -- gives the user a reversible-feeling workflow before writes happen.
- [x] `tindatrack/android/app/src/main/kotlin/com/rkuhonta/tindatrack/MainActivity.kt` -- Add Android document picker/read support if a platform channel can do it cleanly -- enables real CSV file selection on device.
- [x] `tindatrack/test/...` -- Cover parser edge cases, duplicate barcode validation, controller no-write-on-error behavior, successful active/archived insert behavior, and basic settings UI states.

**Acceptance Criteria:**
- Given a valid exported Products CSV with one Active and one Archived row, when the user previews and confirms import, then two new product rows are created and only the active row appears in the active product list.
- Given a Products CSV with any row-level validation error, when preview completes, then the import action is unavailable and no product rows are inserted.
- Given a Products CSV with a non-empty barcode that duplicates another CSV row or any existing active/archived product, when preview completes, then the duplicate is reported and no product rows are inserted.
- Given the user cancels file selection, when returning to App Info, then there is no error snackbar and no product rows are inserted.

## Design Notes

Use the exported Products CSV header as the contract. This keeps restore understandable for testers: the file TindaTrack produces is the file TindaTrack accepts. `Created At` and `Updated At` should be parsed for validation if practical, but imported rows may use current app timestamps if preserving historical timestamps would complicate repository guarantees.

## Verification

**Commands:**
- `C:\src\flutter\bin\flutter.bat test test/features/settings test/features/products test/core/database/daos/products_dao_test.dart` -- expected: all targeted tests pass.
- `C:\src\flutter\bin\cache\dart-sdk\bin\dart.exe analyze` -- expected: no analyzer issues.
- `C:\src\flutter\bin\flutter.bat build apk --debug` -- expected: Android debug APK builds successfully.




## Suggested Review Order

**Entry Point**

- App Info adds the user-facing import action beside export.
  [`settings_screen.dart:104`](../../tindatrack/lib/features/settings/presentation/screens/settings_screen.dart#L104)

- Preview/apply flow keeps import explicit and guarded.
  [`settings_screen.dart:213`](../../tindatrack/lib/features/settings/presentation/screens/settings_screen.dart#L213)

**Import Coordination**

- Controller composes picker, parser, barcode checks, and import writes.
  [`csv_import_providers.dart:64`](../../tindatrack/lib/features/settings/presentation/providers/csv_import_providers.dart#L64)

- Existing barcode checks are chunked before preview approval.
  [`csv_import_providers.dart:175`](../../tindatrack/lib/features/settings/presentation/providers/csv_import_providers.dart#L175)

- Atomic import rows use fresh IDs and current timestamps.
  [`csv_import_providers.dart:202`](../../tindatrack/lib/features/settings/presentation/providers/csv_import_providers.dart#L202)

**CSV Validation**

- Products CSV schema, row validation, and duplicate barcode checks live here.
  [`csv_import_parser.dart:28`](../../tindatrack/lib/features/settings/domain/services/csv_import_parser.dart#L28)

- Malformed quoted CSV fields become blocking preview errors.
  [`csv_import_parser.dart:233`](../../tindatrack/lib/features/settings/domain/services/csv_import_parser.dart#L233)

- Preview models keep counts, row errors, and import summaries typed.
  [`csv_import_preview.dart:1`](../../tindatrack/lib/features/settings/domain/entities/csv_import_preview.dart#L1)

**Persistence And Android**

- DAO batch import is transactional and all-or-none.
  [`products_dao.dart:47`](../../tindatrack/lib/core/database/daos/products_dao.dart#L47)

- Android picker reads selected CSV text with lifecycle and size guards.
  [`MainActivity.kt:87`](../../tindatrack/android/app/src/main/kotlin/com/rkuhonta/tindatrack/MainActivity.kt#L87)

**Tests**

- Parser tests cover valid rows, wrong headers, duplicates, and malformed quotes.
  [`csv_import_parser_test.dart:73`](../../tindatrack/test/features/settings/domain/services/csv_import_parser_test.dart#L73)

- Controller tests cover cancel, duplicate existing barcodes, and no-write errors.
  [`csv_import_providers_test.dart:25`](../../tindatrack/test/features/settings/presentation/providers/csv_import_providers_test.dart#L25)

- Screen tests cover blocking preview, clean import, and quiet cancel.
  [`settings_screen_test.dart:167`](../../tindatrack/test/features/settings/presentation/screens/settings_screen_test.dart#L167)

- DAO tests cover barcode lookup and transactional rollback.
  [`products_dao_test.dart:72`](../../tindatrack/test/core/database/daos/products_dao_test.dart#L72)

