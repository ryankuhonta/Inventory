---
title: 'Full Backup / Restore v1'
type: 'feature'
created: '2026-08-15'
status: 'done'
baseline_commit: '8c5e191'
context:
  - '{project-root}/_bmad-output/implementation-artifacts/spec-csv-export-v1.md'
  - '{project-root}/_bmad-output/implementation-artifacts/spec-csv-import-restore.md'
---

## Intent

**Problem:** TindaTrack can export Products and Stock History CSVs, and can import Products CSVs, but the export format is not yet lossless enough for full backup/restore because stock history rows do not carry stable product IDs, movement IDs, or stock-out reasons.

**Approach:** Make the CSV export contract restorable first, while preserving compatibility with existing Products CSV imports. Then add a guided full restore flow that can import Products and Stock History together without silently corrupting existing data.

## Boundaries & Constraints

**Always:** Keep backup/restore local and user-initiated. Preserve active/archived product status. Preserve stock movement type, quantity trail, reason, note, snapshots, and created timestamp when full restore is implemented. Validate before writing and apply all-or-none.

**Ask First:** Any destructive replace-all restore, merge into existing data, cloud integration, account/login, or restore behavior that overwrites current rows.

**Never:** Do not silently skip invalid rows. Do not create stock movements as side effects of Products-only import. Do not claim current CSV export is a complete backup until stock history restore exists.

## Phase 1: Restorable CSV Contract

- Products export includes a stable `Product ID` column.
- Stock History export includes `Movement ID`, `Product ID`, and `Reason` columns.
- Products import accepts both the prior Products CSV schema and the new schema with `Product ID`, but still inserts fresh product IDs in Products-only import mode.

## Phase 2: Full Restore Flow

- Pick both Products CSV and Stock History CSV.
- Preview counts and blocking errors before writing.
- Require an empty target database or explicit user-approved replace-all semantics before writing history.
- Insert restored products and movements in one database transaction.

## Acceptance Criteria

- New exports include product and movement IDs required for future restore.
- Existing Products CSV files exported before this change still import successfully.
- Products-only import continues to generate fresh IDs and never imports stock history.
- Full restore implementation, when added, refuses inconsistent history rows whose `Product ID` does not exist in the selected Products CSV.


## Tasks & Acceptance

**Execution:**
- [x] `tindatrack/lib/features/settings/domain/services/csv_export_builder.dart` -- Add stable IDs and stock-out reason columns to exported CSVs so future full restore has a lossless contract.
- [x] `tindatrack/lib/features/settings/domain/services/csv_import_parser.dart` -- Keep Products-only import compatible with both legacy exports and new exports containing `Product ID`.
- [x] `tindatrack/lib/features/settings/domain/entities/full_restore_preview.dart` -- Add typed preview rows, counts, and blocking errors for full restore.
- [x] `tindatrack/lib/features/settings/domain/services/full_restore_parser.dart` -- Parse Products and Stock History CSVs together and validate cross-file product references before any future write.
- [x] `tindatrack/test/features/settings/domain/services/...` -- Cover restorable export format, legacy Products import compatibility, valid full restore preview, missing product references, non-restorable Products files, and duplicate IDs.

**Acceptance Criteria:**
- Given a new TindaTrack export, when a full restore preview parses the Products and Stock History CSVs together, then it reports product, active, archived, and movement counts with no blocking errors.
- Given a Stock History CSV row references a Product ID missing from the selected Products CSV, when preview parses the files, then restore is blocked with a row-level error.
- Given an older Products CSV without Product ID is used for full restore, when preview parses it, then restore is blocked as not restorable while Products-only import remains compatible.
- Given duplicate Product IDs or Movement IDs appear in the selected CSVs, when preview parses them, then restore is blocked with duplicate-ID errors.

## Verification

**Commands:**
- `flutter test test/features/settings` -- passed, 35 tests.
- `dart analyze` -- passed, no issues.

## Completion Notes

- Added Full Restore Preview domain models and parser; no UI or database writes yet.
- Full restore preview now enforces restorable CSV headers and cross-file Stock History -> Products ID integrity.
- Existing Products-only import remains backward-compatible with legacy Products CSV exports.


## Review Fixes

- Block empty Stock History CSV files while allowing valid header-only exports with zero movement rows.
- Reject overflow-normalized UTC timestamps by requiring exact export timestamp round-trips.
- Validate Stock In/Stock Out quantity trails before any future restore write.
- Validate reason semantics: Stock In requires blank reason, Stock Out requires a supported non-blank reason.
- Added an export-builder-to-full-restore-parser round-trip test so header/order drift is caught.

## Suggested Review Order

**Export Contract**

- Export now carries IDs and reason data needed for restore.
  [`csv_export_builder.dart:28`](../../tindatrack/lib/features/settings/domain/services/csv_export_builder.dart#L28)

- Products-only import stays compatible with legacy and ID-bearing exports.
  [`csv_import_parser.dart:19`](../../tindatrack/lib/features/settings/domain/services/csv_import_parser.dart#L19)

**Full Restore Preview**

- Parser coordinates products and history, then joins by Product ID.
  [`full_restore_parser.dart:36`](../../tindatrack/lib/features/settings/domain/services/full_restore_parser.dart#L36)

- Stock History must be a valid selected export, not an empty file.
  [`full_restore_parser.dart:270`](../../tindatrack/lib/features/settings/domain/services/full_restore_parser.dart#L270)

- Movement rows validate references, reason semantics, and quantity trails.
  [`full_restore_parser.dart:331`](../../tindatrack/lib/features/settings/domain/services/full_restore_parser.dart#L331)

- Timestamp parsing rejects overflow-normalized calendar values.
  [`full_restore_parser.dart:583`](../../tindatrack/lib/features/settings/domain/services/full_restore_parser.dart#L583)

- Preview types keep future persistence writes typed and reviewable.
  [`full_restore_preview.dart:4`](../../tindatrack/lib/features/settings/domain/entities/full_restore_preview.dart#L4)

**Tests**

- Export-builder round trip catches header/order drift.
  [`full_restore_parser_test.dart:33`](../../tindatrack/test/features/settings/domain/services/full_restore_parser_test.dart#L33)

- Safety tests cover missing references, empty files, dates, math, and duplicates.
  [`full_restore_parser_test.dart:82`](../../tindatrack/test/features/settings/domain/services/full_restore_parser_test.dart#L82)

