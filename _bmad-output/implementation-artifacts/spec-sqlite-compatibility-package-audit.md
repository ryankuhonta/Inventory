# Spec: SQLite Compatibility Package Audit

Date: 2026-08-06

## Goal

Review the transitive end-of-life SQLite compatibility packages resolved through the Drift persistence stack and determine whether they require immediate action.

## Local Dependency Snapshot

Direct persistence dependencies from `tindatrack/pubspec.yaml`:

- `drift: ^2.34.0`
- `drift_flutter: ^0.3.0`
- `drift_dev: ^2.34.0`

Relevant locked packages from `tindatrack/pubspec.lock`:

- `drift 2.34.0`
- `drift_flutter 0.3.0`
- `drift_dev 2.34.0`
- `sqlite3 3.3.3`
- `sqlite3_flutter_libs 0.6.0+eol`
- `sqlcipher_flutter_libs 0.7.0+eol`
- `sqlparser 0.44.5`

`flutter pub deps --style=compact` confirms:

- `drift_flutter 0.3.0` depends on `drift`, `sqlite3`, `sqlite3_flutter_libs`, and `sqlcipher_flutter_libs`.
- `drift` and `drift_dev` depend on `sqlite3`.
- App code does not directly depend on `sqlite3_flutter_libs` or `sqlcipher_flutter_libs`.

## Current Package Metadata

Checked against pub.dev on 2026-08-06:

- `sqlite3_flutter_libs 0.6.0+eol` is documented as obsolete after upgrading to `package:sqlite3` 3.x. Starting with `0.6.0`, it no longer does anything and exists so libraries can depend on it without bringing old Flutter SQLite build scripts into the app.
- `sqlcipher_flutter_libs 0.7.0+eol` is similarly documented as unused with `package:sqlite3` 3.x.
- `sqlite3` 3.0.0 changed native loading to build hooks and says projects should drop dependencies on `sqlite3_flutter_libs` and `sqlcipher_flutter_libs` when upgrading directly.
- `drift_flutter` currently still lists both compatibility packages as dependencies, so their presence here is transitive and expected.

Sources:

- https://pub.dev/packages/sqlite3_flutter_libs
- https://pub.dev/documentation/sqlite3_flutter_libs/latest/sqlite3_flutter_libs/
- https://pub.dev/packages/sqlcipher_flutter_libs/versions
- https://pub.dev/documentation/sqlcipher_flutter_libs/latest/sqlcipher_flutter_libs/
- https://pub.dev/packages/sqlite3/changelog
- https://pub.dev/packages/drift_flutter/versions

## `pub outdated` Snapshot

Read-only command:

```powershell
C:\src\flutter\bin\flutter.bat pub outdated
```

Persistence-related output:

- `drift`: current `2.34.0`, upgradable/resolvable/latest `2.34.3`
- `drift_flutter`: current `0.3.0`, upgradable/resolvable/latest `0.3.1`
- `drift_dev`: current `2.34.0`, latest `2.34.5`, but not currently resolvable beyond `2.34.0`
- `sqlite3`: current `3.3.3`, upgradable/resolvable/latest `3.5.1`
- `sqlparser`: current `0.44.5`, latest `0.45.0`, not currently resolvable beyond `0.44.5`

## Assessment

No immediate action is required from the `+eol` package names alone.

The important distinction is that the lockfile is not holding old active Flutter native-library packages such as `sqlite3_flutter_libs 0.5.x` or `sqlcipher_flutter_libs 0.6.x`. It is holding the post-migration `+eol` placeholders documented as inert compatibility packages for ecosystems already on `sqlite3` 3.x.

The remaining upgrade opportunity is routine dependency freshness, not an urgent EOL remediation. If we choose an upgrade pass later, upgrade and test the persistence stack together:

- `drift`
- `drift_flutter`
- `drift_dev`
- `sqlite3`
- generated Drift code

Recommended verification for a future upgrade pass:

- `dart run build_runner build --delete-conflicting-outputs`
- `dart format lib test`
- focused database/repository tests
- full Flutter test suite
- Android debug or release build smoke check

## Result

Audit complete. The deferred SQLite compatibility package review can be closed without changing dependencies.