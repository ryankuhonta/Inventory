# Story 5.6 MVP Release Readiness Checklist

Date: 2026-07-25
Story: 5.6 Complete MVP Release Readiness Checks
Status: Passed for code-review handoff
Verification workspace: `C:\tmp\tindatrack-story-5-6`

## Quality Gates

| Gate | Result | Notes |
| --- | --- | --- |
| Dart format | Passed | Formatted touched Dart tests. |
| Focused release-readiness tests | Passed | `flutter test test/app/router/app_router_test.dart test/ux/release_readiness_guardrail_test.dart` passed. |
| Static analysis | Passed | `dart analyze` reported no issues. |
| Full Flutter test suite | Passed | `flutter test` passed with 363 tests. |
| Android debug build | Passed | `flutter build apk --debug` produced `build/app/outputs/flutter-apk/app-debug.apk`. |
| Workspace whitespace | Passed | `git diff --check` passed. |

## MVP Scope Checks

- Production route identities remain limited to Dashboard, Products, History, Settings, Add Product, Edit Product, Stock In, and Stock Out.
- `lib/features` remains limited to `dashboard`, `history`, `products`, `settings`, and `stock`.
- `pubspec.yaml` contains no forbidden auth, cloud, analytics, ads, scanner, POS, supplier, accounting, or remote API dependencies.
- Android manifest has no Internet, camera, notification, or other extra app permissions.
- Android build config still uses `com.rkuhonta.tindatrack`, Flutter-provided version values, and local debug signing for smoke builds.

## Offline And Release Notes

- Core MVP flows remain local-only through existing repository, Drift, and widget coverage.
- Settings app version continues to read from bundled `pubspec.yaml`.
- No login, cloud sync, remote API, analytics, ad SDK, barcode scanner UI, POS, supplier, accounting, staff role, or multi-branch implementation was added.
- Release signing and Play Store/internal testing distribution are not configured by this story. They remain release-management decisions for the chosen first distribution channel.

## Action Items Before External Distribution

- Choose first release path: private APK testing or Play Store internal testing.
- Configure production signing outside this MVP implementation story before distributing beyond local/debug smoke testing.