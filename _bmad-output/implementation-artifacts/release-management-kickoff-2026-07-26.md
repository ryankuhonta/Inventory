# Release Management Kickoff

**Date:** 2026-07-26
**Workstream:** Release management
**Starting point:** MVP implementation and retrospectives closed
**Current app version:** `0.1.0+1`
**Current Android package:** `com.rkuhonta.tindatrack`
**Current signing state:** release build type still uses debug signing

## Decision

Start with a private signed APK testing pass before Play Store internal testing.

This is the right first move because the MVP still needs production signing setup, first real-device install validation, and tester handoff notes. A private APK pass is the fastest way to prove the signed release candidate installs, opens, preserves the local-only scope, and exercises the core store-helper workflows before Play Console setup and review-facing metadata become part of the work.

After that private pass is stable, move to Play Store internal testing. Internal testing is the better second step because it distributes through Google Play, supports up to 100 testers, gives testers Play-managed updates, and exercises the Play Console release path without opening the app publicly.

## Source Notes

- Google Play Console Help says internal testing is for quick distribution to up to 100 trusted testers and is recommended before closed or open testing.
- Google Play Console Help says developers with personal accounts created after 2023-11-13 must run closed testing with at least 12 opted-in testers for 14 continuous days before production access.
- Android Developers documentation allows website/server APK distribution, but users must opt in to installing unknown apps before installing outside Google Play.

References:

- https://support.google.com/googleplay/android-developer/answer/9845334
- https://support.google.com/googleplay/android-developer/answer/14151465
- https://developer.android.com/distribute/marketing-tools/alternative-distribution

## Comparison

| Path | Best for | Strengths | Costs and risks |
|---|---|---|---|
| Private signed APK testing | First real-device shakeout with a very small trusted group | Fastest path, no store listing dependency, easy to control, validates signing and install behavior early | Testers must install from outside Play, device settings may block unknown apps, no Play-managed updates, not representative of Play delivery |
| Play Store internal testing | Store-distributed QA with trusted testers | Secure Play delivery, update handling, opt-in links, up to 100 testers, useful rehearsal for Play Console release flow | Requires Play Console app setup and artifact upload, package name becomes fixed after upload, needs store/testing metadata, may surface policy/setup work earlier |

## Recommended Sequence

1. Configure production-style signing without committing secrets.
2. Build a signed release APK for private testing.
3. Run release gates on the signed candidate.
4. Share the APK only with a tiny trusted group.
5. Collect install, device, and workflow feedback.
6. Fix only release-blocking issues.
7. Prepare Play Console app setup and internal testing notes.
8. Upload an Android App Bundle for Play Store internal testing.

## Private APK Test Scope

Target testers:

- 2 to 5 trusted people or devices.
- At least one lower-end Android device if available.
- At least one device using the real store-helper workflow context.

Required tester flows:

- Install and open the signed APK.
- Confirm Dashboard, Products, History, and Settings routes load.
- Add a product with valid PHP price context.
- Edit an existing product.
- Archive a product if appropriate for the test dataset.
- Record Stock In.
- Record Stock Out, including insufficient-stock protection.
- Review History for readable movement rows.
- Confirm Settings communicates local-only scope and future backup/export honestly.

Known exclusions to preserve in tester notes:

- No account login.
- No cloud sync.
- No backup/export yet.
- No barcode scanner.
- No POS checkout.
- No supplier, accounting, staff role, or multi-branch features.

## Play Store Internal Testing Entry Criteria

Before moving to Play internal testing:

- Signed private APK testing has no release-blocking install or core-flow failures.
- Release signing configuration is documented and secret files remain outside Git.
- Version/build identity is clear across Settings, artifact filename, commit SHA, and tester notes.
- Store package name `com.rkuhonta.tindatrack` is confirmed as final enough to upload, because Play fixes the package name after the first artifact upload.
- Tester feedback channel is ready.
- App name, short description, basic store listing copy, and privacy/data-safety posture are ready enough for internal testing.

## Immediate Next Tasks

1. Decide keystore location and secret-handling convention.
2. Add Git-ignored signing property support if not already present.
3. Build a signed release APK from `tindatrack/`.
4. Re-run analyzer, release-readiness tests, full Flutter suite, and signed APK build validation.
5. Create private APK tester handoff notes.

## Guardrails

- Do not distribute debug-signed artifacts as release candidates.
- Do not commit keystore files, passwords, aliases, or local signing property files.
- Do not add cloud, account, analytics, ads, crash reporting, scanner, POS, supplier, accounting, or network dependencies during release management unless explicitly scoped.
- Keep MVP routes limited to Dashboard, Products, Add Product, Edit Product, Stock In, Stock Out, History, and Settings.
- Re-run Story 5.6 release-readiness guardrails after signing changes.
