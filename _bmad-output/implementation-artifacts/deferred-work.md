# Deferred Work

## Deferred from: code review of 1-2-establish-app-architecture-and-local-core-services (2026-06-20)

- Review the transitive end-of-life SQLite compatibility packages currently resolved through the pre-existing Drift/drift_flutter dependency set when the persistence stack is next upgraded. Story 1.2 intentionally preserves the versions established by Story 1.1.

## Deferred from: code review of 1-3-provide-offline-app-launch-and-splash-initialization (2026-06-21)

- Handle errors from the asynchronous database `close()` registered in `createManagedDatabase` so disposal failures do not surface as uncaught zone errors. This lifecycle helper predates Story 1.3 and should be addressed as a focused shared-infrastructure change.

## Deferred from: code review of 1-4-add-main-navigation-shell (2026-06-22)

- Harden the pre-existing Story 1.3 retry lifecycle so a database close that hangs, throws an `Exception`, or completes with a Dart `Error` cannot leave Retry permanently disabled.
- Allow the shared `closeManagedDatabase` helper to recover after a rejected close future instead of permanently caching and replaying the same failure.

## Deferred from: code review of 1-5-apply-mvp-theme-and-base-ui-states (2026-06-28)

- Retry can throw while reading a failed database provider (	indatrack/lib/app/app.dart:78).
- A database close that never completes can strand Retry (	indatrack/lib/app/app.dart:79).
- A rejected cached close future blocks later retries (	indatrack/lib/app/providers.dart:40).
- Provider disposal can surface an unhandled asynchronous close error (	indatrack/lib/app/providers.dart:34).

## Closed from: code review of 2-3-view-active-product-list-with-empty-state.md - 2026-08-03

- Duplicate Add Product routes from rapid repeated taps are now guarded in `ProductListScreen` and covered for both the FAB and empty-state action paths.

## Closed from: code review of 2-8-prepare-product-row-action-pattern.md - 2026-08-05

- Edit Product row navigation now uses an in-flight route guard that clears in `finally`, so rapid repeated Edit taps cannot stack duplicate edit routes and navigation failures do not leave later Edit attempts blocked.

## Closed from private APK feedback split - 2026-08-03

The private APK feedback items deferred on 2026-07-27 have since been closed and should no longer be treated as active deferred work.

- Add Product now includes the optional barcode field with duplicate-barcode handling.
- App version now displays as `Version 0.1.0 (Build 1)` instead of raw `0.1.0+1`.
- Android launcher icon assets now use the custom TindaTrack launcher icon.
- The visible Settings tab and screen heading now use `App Info` while keeping internal `/settings` route names stable.
- Stock In and Stock Out notes now support local-only same-context autocomplete suggestions.
