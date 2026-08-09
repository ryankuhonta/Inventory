---
title: 'CSV Export v1'
type: 'feature'
created: '2026-08-09'
status: 'done'
context:
  - '{project-root}/_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md'
  - '{project-root}/_bmad-output/planning-artifacts/architecture.md'
---

<frozen-after-approval reason="human-owned intent - do not modify unless human renegotiates">

## Intent

**Problem:** App Info currently shows Backup / Export as a placeholder, but the user wants a first real export feature that stays local-only and produces readable files.

**Approach:** Implement CSV Export v1 from App Info, generating Products and Stock History CSV files and opening the Android share sheet so the user can save or share them.

## Boundaries & Constraints

**Always:** Include active and archived products. Products CSV must expose product status as `Active` or `Archived`. Stock history must use movement snapshots so history remains readable after product rename/archive. Keep the feature offline-first and user-initiated.

**Ask First:** Any restore/import behavior, cloud backup, account/login, Google Drive-specific integration, or extra report beyond the two CSV files.

**Never:** Do not implement database restore, automatic backup, cloud sync, login, POS/accounting behavior, or export claims that imply data is already protected.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Export data | Products and movements exist | Share sheet receives `products.csv` and `stock-history.csv` files with stable headers and escaped values | N/A |
| Archived product | Product has `isArchived = true` | Products CSV status cell is `Archived` | N/A |
| CSV-sensitive text | Value contains comma, quote, or newline | Value is RFC-style CSV escaped with quotes doubled | N/A |
| Persistence/export failure | Repository read, temp write, or share call fails | App Info shows friendly snackbar and keeps app usable | Raw exception is not shown |

</frozen-after-approval>

## Code Map

- `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart` -- App Info surface currently showing Backup / Export placeholder.
- `tindatrack/lib/features/products/domain/repositories/products_repository.dart` -- Product boundary needs an all-products export query.
- `tindatrack/lib/features/stock/domain/repositories/stock_repository.dart` -- Existing movement history listing can supply stock history export rows.
- `tindatrack/lib/core/database/daos/products_dao.dart` -- Needs all-products query including archived rows.

## Tasks & Acceptance

**Execution:**
- [ ] `tindatrack/pubspec.yaml` -- add share/temp-file dependencies for CSV sharing.
- [ ] `tindatrack/lib/core/database/daos/products_dao.dart` -- add all-products list method including archived rows.
- [ ] `tindatrack/lib/features/products/...` -- expose all-products export data through repository/provider boundaries.
- [ ] `tindatrack/lib/features/settings/...` -- build CSVs, write temp files, call share sheet, and replace placeholder with Export Data action.
- [ ] `tindatrack/test/...` -- cover CSV escaping, archived status, controller success/failure, and Settings visible copy.

**Acceptance Criteria:**
- Given App Info is open, when the user taps Export Data, then Products and Stock History CSV files are generated and shared.
- Given an archived product exists, when Products CSV is generated, then its Status column says `Archived`.
- Given export fails, when the user taps Export Data, then a friendly snackbar appears and raw technical details are hidden.

## Verification

**Commands:**
- `dart format lib test` -- expected: formatted successfully.
- `flutter test test/features/settings test/features/products/data/repositories test/core/database/daos/products_dao_test.dart` -- expected: all pass.
- `dart analyze` -- expected: no issues.
## Completion Notes

- Added CSV Export v1 in App Info with Products and Stock History CSV sharing plus visible Save to Downloads/TindaTrack.
- Products export includes active and archived rows with a Status column.
- Verification passed: focused settings/DAO tests, flutter analyze, and debug APK build.
- APK: _bmad-output/implementation-artifacts/apk/current/tindatrack-0.1.0+1-debug-csv-export-downloads-20260809.apk.