---
title: 'Full Restore UI / Apply Flow'
type: 'feature'
created: '2026-08-21'
status: 'done'
baseline_commit: '372ae2f'
context:
  - '{project-root}/_bmad-output/implementation-artifacts/spec-full-backup-restore-v1.md'
---

<frozen-after-approval reason="human-owned intent - do not modify unless human renegotiates">

## Intent

**Problem:** TindaTrack now exports restore-ready Products and Stock History CSVs and can validate them together, but the app still has no user-facing full restore flow and no database apply path for restoring movement history.

**Approach:** Add a guided local restore flow in App Info that picks Products CSV and Stock History CSV, previews counts and blocking errors, then restores only into an empty local database in one transaction.

## Boundaries & Constraints

**Always:** Keep restore local and user-initiated. Validate both selected CSVs before any write. Restore product IDs, archived status, product timestamps, movement IDs, movement timestamps, movement type, quantity trail, reason, note, and snapshots exactly from the preview. Apply all products and movements in one database transaction. Disable restore while another import/export/restore action is in progress. Show plain, non-technical errors and never expose raw exceptions in UI.

**Ask First:** Any replace-all restore, merge restore into non-empty data, selective restore, cloud backup/sync, account/login, automatic scheduled backup, or destructive clearing of current rows.

**Never:** Do not overwrite or delete existing data. Do not restore into a database that already has products or stock movements. Do not silently skip invalid rows. Do not reuse Products-only import semantics that generate fresh IDs. Do not create extra stock movements as side effects of restored products.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Valid full restore | Empty database, valid restorable Products CSV, valid matching Stock History CSV | Preview shows product, active, archived, and movement counts; Restore button is enabled; confirm applies rows and shows success snackbar | N/A |
| User cancels selection | User cancels either file picker step | Flow exits quietly without dialog or snackbar | No write occurs |
| Parser rejects files | Missing Product ID, bad Stock History header, duplicate IDs, bad timestamps, missing product references, or invalid quantity trails | Preview dialog shows blocking errors and disables Restore | No write occurs |
| Existing data present | Database has any product or stock movement before restore | Preview or apply blocks restore with an empty-database requirement | No write occurs |
| Apply fails mid-restore | Persistence throws after transaction starts | Transaction rolls back; UI remains on dialog with a friendly failure message | No partial restore remains |

</frozen-after-approval>

## Code Map

- `tindatrack/lib/features/settings/domain/entities/full_restore_preview.dart` -- Existing typed preview rows, counts, and blocking errors from the previous slice.
- `tindatrack/lib/features/settings/domain/services/full_restore_parser.dart` -- Existing parser for Products + Stock History CSV validation.
- `tindatrack/lib/features/settings/presentation/providers/csv_import_providers.dart` -- Existing Products-only import controller and Android CSV picker channel pattern to mirror or extend.
- `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart` -- App Info UI, export/import action buttons, and preview dialog pattern.
- `tindatrack/android/app/src/main/kotlin/com/rkuhonta/tindatrack/MainActivity.kt` -- Existing single CSV document picker bridge.
- `tindatrack/lib/core/database/app_database.dart` -- Drift database entry point that can host full restore transaction helpers.
- `tindatrack/lib/core/database/daos/products_dao.dart` -- Product persistence APIs, including atomic product import and emptiness checks to add.
- `tindatrack/lib/core/database/daos/stock_movements_dao.dart` -- Stock movement persistence APIs and movement history queries.
- `tindatrack/test/features/settings/...` and `tindatrack/test/core/database/...` -- Existing provider, screen, parser, and DAO test patterns.

## Tasks & Acceptance

**Execution:**
- [x] `tindatrack/lib/core/database/app_database.dart` -- Add a restore transaction API or helper that inserts restored products and movements all-or-nothing after verifying the target database is empty.
- [x] `tindatrack/lib/core/database/daos/products_dao.dart` and `tindatrack/lib/core/database/daos/stock_movements_dao.dart` -- Add minimal count/insert helpers needed by the restore transaction without weakening existing import behavior.
- [x] `tindatrack/lib/features/settings/presentation/providers/full_restore_providers.dart` -- Add controller/providers for picking two CSVs, previewing with `FullRestoreParser`, checking database emptiness, and applying valid previews.
- [x] `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart` -- Add Full Restore action and dialog showing counts/errors, empty-database requirement, progress state, and restore success/failure feedback.
- [x] `tindatrack/android/app/src/main/kotlin/com/rkuhonta/tindatrack/MainActivity.kt` -- Reuse or extend the document picker bridge so the restore controller can read Products and Stock History CSV files separately.
- [x] `tindatrack/test/features/settings/presentation/providers/full_restore_providers_test.dart` -- Cover cancel, blocking parser errors, existing-data block, successful restore summary, and apply failure.
- [x] `tindatrack/test/features/settings/presentation/screens/settings_screen_test.dart` -- Cover Full Restore button presence, blocking preview, enabled restore for clean preview, and friendly result UI.
- [x] `tindatrack/test/core/database/...` -- Cover full restore transaction preserves IDs/timestamps/reasons/snapshots and rolls back on failure.

**Acceptance Criteria:**
- Given an empty database and matching restorable exports, when the user selects Products CSV and Stock History CSV from App Info and confirms restore, then all products and stock movements are restored with original stable IDs and history fields.
- Given the local database already contains any product or stock movement, when the user previews or confirms full restore, then restore is blocked with an empty-database message and no rows are written.
- Given either selected CSV has parser errors, when the preview dialog opens, then the Restore action is disabled and the first blocking errors are shown with file/row context.
- Given persistence fails during apply, when the restore transaction exits, then no partial products or movements remain and the dialog shows a friendly retry message.

## Design Notes

The v1 flow intentionally restores only into an empty database. That avoids irreversible replace-all or merge semantics while still making exported backups useful for a fresh install/device. The App Info copy should distinguish Products-only import from Full Restore so users understand that Full Restore includes stock history and requires an empty app database.

## Verification

**Commands:**
- `flutter test test/features/settings test/core/database` -- passed, 80 tests.
- `dart analyze` -- passed, no issues.
- `flutter build apk --debug` -- passed.

**Manual checks (if no CLI):**
- On an empty test app, export CSVs, then Full Restore them and confirm products/history appear.
- On a non-empty test app, attempt Full Restore and confirm it is blocked before writing.


## Review Fixes

- Rechecked the empty-database guard at confirm time so restore blocks with the required message if data appears after preview.
- Avoided dialog-context snackbar lookup after closing the Full Restore dialog.
- Switched restore emptiness checks to bounded queries instead of loading entire tables.
- Added defensive movement-to-product validation before transaction inserts begin.

## Suggested Review Order

**Restore Boundary**

- Start here: empty-only, all-or-nothing restore preserves backup identities.
  [`app_database.dart:45`](../../tindatrack/lib/core/database/app_database.dart#L45)

- Confirm-time guard prevents restoring after data appears post-preview.
  [`full_restore_providers.dart:179`](../../tindatrack/lib/features/settings/presentation/providers/full_restore_providers.dart#L179)

- Preview-time guard blocks non-empty databases without loading full tables.
  [`full_restore_providers.dart:216`](../../tindatrack/lib/features/settings/presentation/providers/full_restore_providers.dart#L216)

**User Flow**

- App Info exposes Full Restore alongside existing CSV actions.
  [`settings_screen.dart:131`](../../tindatrack/lib/features/settings/presentation/screens/settings_screen.dart#L131)

- Restore preview shows counts, empty-database requirement, and blocking errors.
  [`settings_screen.dart:272`](../../tindatrack/lib/features/settings/presentation/screens/settings_screen.dart#L272)

- Restore completion uses captured UI handles and specific empty-database feedback.
  [`settings_screen.dart:358`](../../tindatrack/lib/features/settings/presentation/screens/settings_screen.dart#L358)

- Android picker bridge reuses CSV document selection for both restore files.
  [`MainActivity.kt:47`](../../tindatrack/android/app/src/main/kotlin/com/rkuhonta/tindatrack/MainActivity.kt#L47)

**Tests**

- Database tests prove field preservation, guard behavior, and rollback.
  [`app_database_full_restore_test.dart:15`](../../tindatrack/test/core/database/app_database_full_restore_test.dart#L15)

- Controller tests cover cancel, parser errors, empty checks, and apply failure.
  [`full_restore_providers_test.dart:10`](../../tindatrack/test/features/settings/presentation/providers/full_restore_providers_test.dart#L10)

- Widget tests cover the Full Restore button and preview/apply UX.
  [`settings_screen_test.dart:202`](../../tindatrack/test/features/settings/presentation/screens/settings_screen_test.dart#L202)