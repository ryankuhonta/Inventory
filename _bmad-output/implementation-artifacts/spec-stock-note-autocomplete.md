---
title: 'Stock note autocomplete suggestions'
type: 'feature'
created: '2026-08-01'
status: 'done'
baseline_commit: '79867f931085094df91af42ef8403a1a16f29f5b'
context:
  - '{project-root}/_bmad-output/implementation-artifacts/private-apk-test-notes-2026-07-26.md'
---

<frozen-after-approval reason="human-owned intent - do not modify unless human renegotiates">

## Intent

**Problem:** Stock In and Stock Out notes require repeatedly typing the same values, even when the same note was already used before.

**Approach:** Add local autocomplete suggestions to the Stock In and Stock Out note fields using prior persisted movement notes from the same note context.

## Boundaries & Constraints

**Always:** Keep suggestions local to the app database. Trim stored notes for suggestion display. Separate Stock In note suggestions from Stock Out note suggestions. Keep the existing submit, validation, disabled, and navigation behavior intact.

**Ask First:** Expanding autocomplete to product names, categories, units, or barcodes; adding cloud sync; adding a new persistent table; changing visible labels beyond the autocomplete surface.

**Never:** Mix unrelated field values, suggest blank notes, suggest Stock Out notes inside Stock In, suggest Stock In notes inside Stock Out, or block saving if suggestions fail to load.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Stock In match | Prior Stock In note `delivery`, user types `de` in Stock In note | `delivery` is offered and can be tapped to fill the note field | If suggestions fail, the note field remains usable without suggestions |
| Stock Out match | Prior Stock Out note `consumed`, user types `co` in Stock Out note | `consumed` is offered and can be tapped to fill the note field | If suggestions fail, the note field remains usable without suggestions |
| Context isolation | Prior Stock In note `delivery` and prior Stock Out note `sold` | Stock In only suggests `delivery`; Stock Out only suggests `sold` | N/A |
| Empty and duplicate history | Blank notes and repeated note values exist | Blank notes are ignored and duplicate suggestion text appears once | N/A |

</frozen-after-approval>

## Code Map

- `tindatrack/lib/core/database/daos/stock_movements_dao.dart` -- Drift DAO for querying movement rows.
- `tindatrack/lib/features/stock/domain/repositories/stock_repository.dart` -- Stock repository contract used by presentation code.
- `tindatrack/lib/features/stock/data/repositories/drift_stock_repository.dart` -- Drift-backed stock repository implementation and note normalization.
- `tindatrack/lib/features/stock/presentation/providers/stock_providers.dart` -- Riverpod providers for stock data dependencies.
- `tindatrack/lib/features/stock/presentation/screens/stock_in_screen.dart` -- Stock In form note field.
- `tindatrack/lib/features/stock/presentation/screens/stock_out_screen.dart` -- Stock Out form note field.
- `tindatrack/test/features/stock/data/repositories/drift_stock_repository_test.dart` -- Repository tests for note suggestion query behavior.
- `tindatrack/test/features/stock/presentation/screens/stock_in_screen_test.dart` -- Stock In widget tests.
- `tindatrack/test/features/stock/presentation/screens/stock_out_screen_test.dart` -- Stock Out widget tests.

## Tasks & Acceptance

**Execution:**
- [x] `tindatrack/lib/core/database/daos/stock_movements_dao.dart` -- add a distinct recent note query filtered by movement type.
- [x] `tindatrack/lib/features/stock/domain/repositories/stock_repository.dart` and `tindatrack/lib/features/stock/data/repositories/drift_stock_repository.dart` -- expose and implement same-field note suggestion loading.
- [x] `tindatrack/lib/features/stock/presentation/providers/stock_providers.dart` -- add a provider for note suggestions by stock movement type.
- [x] `tindatrack/lib/features/stock/presentation/screens/stock_in_screen.dart` and `tindatrack/lib/features/stock/presentation/screens/stock_out_screen.dart` -- replace the plain note fields with autocomplete-backed fields that preserve existing keys and controllers.
- [x] `tindatrack/test/features/stock/data/repositories/drift_stock_repository_test.dart`, `tindatrack/test/features/stock/presentation/screens/stock_in_screen_test.dart`, and `tindatrack/test/features/stock/presentation/screens/stock_out_screen_test.dart` -- cover suggestion filtering, dedupe, tap-to-fill, and no cross-context leakage.

**Acceptance Criteria:**
- Given prior Stock In notes exist, when the user types a matching prefix in Stock In note, then same-context note suggestions appear and selecting one fills the field.
- Given prior Stock Out notes exist, when the user types a matching prefix in Stock Out note, then same-context note suggestions appear and selecting one fills the field.
- Given a note exists only in the opposite movement type, when the user types in the current note field, then that opposite-context note is not suggested.
- Given suggestion loading fails or returns no values, when the note field is used, then the form remains editable and submittable.

## Spec Change Log

## Verification

**Commands:**
- `C:\src\flutter\bin\cache\dart-sdk\bin\dart.exe analyze` -- expected: no issues.
- `C:\src\flutter\bin\flutter.bat test` -- expected: all tests pass.
- `C:\src\flutter\bin\flutter.bat build apk --debug` -- expected: debug APK builds successfully.

## Suggested Review Order

**Entry Point**

- Stock In binds same-context suggestions into the existing note form.
  [`stock_in_screen.dart:118`](../../tindatrack/lib/features/stock/presentation/screens/stock_in_screen.dart#L118)

- Stock Out uses the same pattern with Stock Out-only history.
  [`stock_out_screen.dart:118`](../../tindatrack/lib/features/stock/presentation/screens/stock_out_screen.dart#L118)

**Suggestion Source**

- DAO trims, dedupes, clamps limit, and keeps latest note text deterministic.
  [`stock_movements_dao.dart:43`](../../tindatrack/lib/core/database/daos/stock_movements_dao.dart#L43)

- Provider maps persistence failures to empty suggestions so forms remain usable.
  [`stock_providers.dart:25`](../../tindatrack/lib/features/stock/presentation/providers/stock_providers.dart#L25)

**Autocomplete UI**

- Shared widget preserves controller/focus behavior while adding tap-to-fill suggestions.
  [`stock_note_autocomplete_field.dart:36`](../../tindatrack/lib/features/stock/presentation/widgets/stock_note_autocomplete_field.dart#L36)

- Keyboard submit accepts active options before falling back to form submit.
  [`stock_note_autocomplete_field.dart:58`](../../tindatrack/lib/features/stock/presentation/widgets/stock_note_autocomplete_field.dart#L58)

**Tests**

- Repository coverage verifies context isolation, dedupe, latest text, and limit clamping.
  [`drift_stock_repository_test.dart:471`](../../tindatrack/test/features/stock/data/repositories/drift_stock_repository_test.dart#L471)

- Stock In widget coverage verifies tap-to-fill and movement type selection.
  [`stock_in_screen_test.dart:51`](../../tindatrack/test/features/stock/presentation/screens/stock_in_screen_test.dart#L51)

- Stock Out widget coverage verifies tap-to-fill and movement type selection.
  [`stock_out_screen_test.dart:52`](../../tindatrack/test/features/stock/presentation/screens/stock_out_screen_test.dart#L52)