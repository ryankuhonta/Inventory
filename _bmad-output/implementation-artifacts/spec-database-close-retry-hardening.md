# Spec: Database Close Retry Hardening

Date: 2026-08-06

## Goal

Ensure database close errors and hangs cannot strand app launch Retry, poison later retry attempts, or escape as uncaught asynchronous disposal errors.

## Implementation

- `tindatrack/lib/app/app.dart`
  - `_LaunchGateState._retry` guards concurrent Retry taps with `_isRetrying`.
  - Database provider reads and close calls are wrapped in `try`/`on Object`.
  - Close/read failures re-enable Retry when the widget is still mounted.
  - Successful close invalidates `databaseProvider` and `bootstrapProvider` to create fresh launch state.

- `tindatrack/lib/app/providers.dart`
  - `createManagedDatabase` registers disposal through `_closeOnDispose`.
  - `_closeOnDispose` observes both synchronous and asynchronous close failures.
  - `closeManagedDatabase` shares an in-flight close attempt for the same database.
  - Rejected close attempts are evicted, allowing later calls to retry.
  - Timed-out waits release the caller without starting overlapping close attempts.

## Regression Coverage

- `tindatrack/test/app/database_lifecycle_regression_test.dart`
  - concurrent callers share one close attempt
  - rejected `Exception` and Dart `Error` closes are evicted
  - synchronous close failure is evicted
  - close timeout avoids overlapping closes
  - provider disposal contains synchronous and asynchronous close failures

- `tindatrack/test/app/launch_retry_regression_test.dart`
  - Retry recovers when reading `databaseProvider` throws
  - Retry recovers from Dart `Error` close failures
  - Retry recovers from controlled close timeouts
  - successful Retry recreates app launch state
  - pending Retry close is safe when the widget is disposed

## Verification

Ran from `C:\tmp\Inventory-db-lifecycle-verify\tindatrack` to avoid Windows Flutter UNC current-directory limitations:

```powershell
C:\src\flutter\bin\flutter.bat test test/app/database_lifecycle_regression_test.dart test/app/launch_retry_regression_test.dart test/app/providers_test.dart test/widget_test.dart
```

Result: `26/26` tests passed.

Also ran:

```powershell
wsl.exe -d Ubuntu --cd /home/rkuhonta/Inventory git diff --check
```

Result: passed.