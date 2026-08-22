---
title: 'Full Restore Verification Summary'
type: 'feature'
created: '2026-08-22T14:58:00+08:00'
status: 'done'
baseline_commit: 'f495812b425584c798a2385039394f9ca9343a59'
context: []
---

<frozen-after-approval reason="human-owned intent - do not modify unless human renegotiates">

## Intent

**Problem:** After a successful Full Restore, the App Info screen only shows a brief snackbar that does not clearly reassure the user which records landed. This is weak feedback for a destructive-adjacent recovery workflow where users need confidence that products, archived products, and movements were restored.

**Approach:** Replace the terse success snackbar with a compact verification summary after restore succeeds. Use the existing `FullRestoreSummary` counts returned by the controller; do not change parsing, validation, database writes, or the empty-database guard.

## Boundaries & Constraints

**Always:** Keep Full Restore blocked unless preview is valid and the target database is empty. Preserve the current preview dialog behavior and existing restore transaction path. The post-success copy must include total products, active products, archived products, and stock movements, using readable singular/plural wording.

**Ask First:** Any change that adds a new persisted restore log, changes exported CSV format, changes restore validation rules, or turns the summary into a separate history screen.

**Never:** Do not weaken the empty database requirement. Do not add cloud/account language. Do not expose raw exception/debug text in user-visible restore feedback.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Successful full restore with active-only products | Summary has 1 product, 1 active, 0 archived, 1 movement | User sees success feedback that says 1 product restored, 1 active, 0 archived, and 1 stock movement restored | N/A |
| Successful full restore with archived products | Summary has multiple products including archived rows | User sees archived count in the success feedback | N/A |
| Failed full restore | Controller returns failure | Existing dialog error handling remains; no success summary appears | Existing friendly error message is shown |

</frozen-after-approval>

## Code Map

- `tindatrack/lib/features/settings/presentation/providers/full_restore_providers.dart` -- already returns `FullRestoreSummary` from successful restore; should remain the source of counts.
- `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart` -- owns the Full Restore preview dialog and success snackbar copy.
- `tindatrack/test/features/settings/presentation/providers/full_restore_providers_test.dart` -- verifies summary counts from controller.
- `tindatrack/test/features/settings/presentation/screens/settings_screen_test.dart` -- verifies App Info restore UI behavior and copy.

## Tasks & Acceptance

**Execution:**
- [x] `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart` -- add a small formatter/helper for Full Restore success summary copy and use it in the success snackbar -- ensures copy is readable and tested without changing restore mechanics.
- [x] `tindatrack/test/features/settings/presentation/screens/settings_screen_test.dart` -- update the clean restore widget test to expect product, active, archived, and movement counts -- covers the happy path.
- [x] `tindatrack/test/features/settings/presentation/screens/settings_screen_test.dart` -- add or adjust a restore test with archived products in the selected CSV -- covers the archived-count summary edge case.
- [x] `tindatrack/test/features/settings/presentation/screens/settings_screen_test.dart` -- keep failure/cancel tests passing -- guards against accidental success summary on non-success paths.

**Acceptance Criteria:**
- Given a clean Full Restore preview and successful apply, when the user taps Restore, then the success feedback includes restored product count, active count, archived count, and stock movement count.
- Given a restore set containing archived products, when restore succeeds, then the success feedback includes the archived product count.
- Given restore fails after confirmation, when the dialog shows an error, then no success summary is shown.

## Spec Change Log

## Verification

**Commands:**
- `C:\src\flutter\bin\flutter.bat test test/features/settings/presentation/screens/settings_screen_test.dart test/features/settings/presentation/providers/full_restore_providers_test.dart` -- expected: all targeted settings tests pass.
- `C:\src\flutter\bin\cache\dart-sdk\bin\dart.exe analyze` -- expected: no analyzer issues.

## Suggested Review Order

**Success Feedback**

- Entry point swaps the old terse message for summary copy.
  [`settings_screen.dart:370`](../../tindatrack/lib/features/settings/presentation/screens/settings_screen.dart#L370)

- Formatter keeps total, active, archived, and movement counts together.
  [`settings_screen.dart:406`](../../tindatrack/lib/features/settings/presentation/screens/settings_screen.dart#L406)

**Failure Handling**

- Existing failure path remains dialog-local and avoids success feedback.
  [`settings_screen.dart:374`](../../tindatrack/lib/features/settings/presentation/screens/settings_screen.dart#L374)

**Tests**

- Active-only restore verifies singular wording and zero archived count.
  [`settings_screen_test.dart:273`](../../tindatrack/test/features/settings/presentation/screens/settings_screen_test.dart#L273)

- Archived restore verifies archived count appears in success feedback.
  [`settings_screen_test.dart:282`](../../tindatrack/test/features/settings/presentation/screens/settings_screen_test.dart#L282)

- Failed restore verifies friendly error without success summary.
  [`settings_screen_test.dart:314`](../../tindatrack/test/features/settings/presentation/screens/settings_screen_test.dart#L314)

