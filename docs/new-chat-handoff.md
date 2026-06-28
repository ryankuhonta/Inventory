# New Chat Handoff: Inventory Tracker BMAD Project

Copy/paste everything inside the block into a new chat:

```markdown
Act as Codex using the BMAD Method for this project.

Workspace:
`\\wsl.localhost\Ubuntu\home\rkuhonta\Inventory`

Communication:
- Use concise Taglish/Filipino-friendly explanations.
- Follow the selected BMAD skill exactly, including its checkpoints and status updates.
- Continue autonomously unless the workflow requires a user decision or a genuine blocker.

Start by inspecting Git status, then run **Dev Story** for Story 1.5 exactly as directed below.

## Current BMAD state

- Planning, UX, architecture, epics, implementation readiness, and sprint planning are complete.
- Epic 1 is `in-progress`.
- Story 1.1: `done`
- Story 1.2: `done`
- Story 1.3: `done`
- Story 1.4: `done`
- Story 1.5: `ready-for-dev`
- Story 1.5 is already created and independently validated. Do not run Create Story again.

Next required BMAD step:

Run `bmad-dev-story` for:

`_bmad-output/implementation-artifacts/1-5-apply-mvp-theme-and-base-ui-states.md`

Read and follow:

`.agents/skills/bmad-dev-story/SKILL.md`

Do not start Story 2.1, an Epic 1 retrospective, or another workflow until Story 1.5 implementation and review are complete.

## Git and worktree safety

- Current branch: `codex/complete-stories-1-1-and-1-2`
- Current HEAD: `eb878cb81f8039bdd0fe175a53716baf37de2ece`
- Stories 1.3 and 1.4, review fixes, story records, deferred-work entries, and sprint updates remain uncommitted.
- The dirty working tree is the authoritative implementation baseline.
- Preserve every existing modification and untracked file.
- Do not reset, clean, checkout, overwrite, stage, commit, or claim existing Story 1.3/1.4 work as Story 1.5 work unless the user explicitly authorizes it.
- A diff against HEAD includes multiple completed stories; use the Story 1.5 File List and Dev Agent Record to separate new work.

## Story 1.5 objective

Apply the approved light Material 3 theme and reusable base loading, empty, and error views so the app remains readable and easy to tap on small Android phones.

Story 1.5 owns:

- Exact approved colors, typography, spacing, radii, and 48dp tap-target guidance.
- One root light Material 3 theme on the existing `MaterialApp.router`.
- `AppLoadingView`, `AppEmptyState`, and `AppErrorView`.
- Theme styling of the current launch states, navigation shell, and four skeletal branch roots.
- Focused token, accessibility, contrast, small-screen, and large-text tests.

Story 1.5 does not own:

- Product, stock, history, dashboard, or settings feature behavior.
- Feature-specific empty states or future save/snackbar flows.
- Dark mode, tablet layouts, custom fonts, final branding, routes, permissions, assets, database changes, or new packages.
- Final whole-app polish, which belongs to Story 5.5.

## Approved token highlights

- Colors:
  - background `#F8FAF7`
  - surface `#FFFFFF`
  - surface-muted `#EEF3EE`
  - primary text `#172018`
  - secondary text `#5E6B60`
  - primary/success `#2E7D4F`
  - pressed primary `#24643F`
  - warning `#B7791F`
  - warning surface `#FFF7E0`
  - danger `#B42318`
  - danger surface `#FDECEC`
  - border `#DDE5DD`
- Typography: `28/700`, `20/700`, `16/700`, `14/400`, `12/600`
- Spacing: `4/8/16/24/32`
- Radii: `6/8/12`; card/button/input radius `8`
- Minimum applicable tap target: `48dp`
- Use the Android system font/Roboto; add no font package or asset.
- Do not use warning amber as normal-sized text on its pale warning surface; use primary text plus a warning icon/border/accent and visible label.

## Required architecture

Preserve:

```text
ProviderScope
`-- MaterialApp.router(theme: AppTheme.light)
    `-- builder: LaunchGate(routerChild)
        |-- loading -> Scaffold + AppLoadingView
        |-- failure -> Scaffold + AppErrorView(safe mapped copy, Retry)
        `-- success -> StatefulShellRoute router child
            `-- AppShell + themed NavigationBar
```

Expected ownership:

- `lib/app/theme`: `AppColors`, `AppTypography`, and `AppTheme`
- `lib/core/ui`: `AppSpacing` ThemeExtension and `AppDimensions`
- `lib/core/widgets`: reusable loading/empty/error views
- `lib/app/app.dart`: root theme and existing bootstrap composition
- Feature root screens consume the theme but do not define it

Important dependency direction:

- `core` must not import `app` or `features`.
- Register `AppSpacing` in `ThemeData.extensions`.
- Core widgets and feature roots read spacing through the core extension.
- Shared state widgets accept display text and callbacks only; they must not own Riverpod, routing, failure mapping, retries, database access, or feature logic.
- `AppErrorView` must not accept throwable, stack-trace, failure, or diagnostic-detail parameters. Existing call sites map failures through `FailureMessageMapper` first.

## Existing behavior that must remain intact

Story 1.3:

- Offline bootstrap performs a real Drift readiness query.
- Loading and safe retry states hide shell/navigation content.
- Retry guards duplicate taps, closes the old database before invalidation, and creates a fresh database.
- Raw technical details remain hidden.

Story 1.4:

- Stable Riverpod-owned `GoRouter`.
- `StatefulShellRoute.indexedStack`.
- Exact roots: `/dashboard`, `/products`, `/history`, `/settings`.
- Exact tabs: Dashboard, Products, History, Settings.
- Labels always visible.
- Tab state and branch state are router-owned.
- Default Android Back behavior remains unchanged.
- Navigation does not rerun bootstrap or recreate/close the database/router.

Current regression baseline:

- 30 tests passed after Story 1.4 code review.
- Flutter analysis and strict formatting passed.
- Android debug APK build passed.
- Live API 36 emulator verification passed for launch, splash, Dashboard shell, and all four tabs.

## Required Story 1.5 testing

- Follow RED-GREEN-REFACTOR.
- Preserve all 30 existing tests.
- Test exact tokens, Material 3, mapped `ColorScheme` roles, typography, shapes, and 48dp action sizes.
- Test all three shared views, optional action callbacks, semantics, and non-color error cues.
- Require action label and callback together or neither; incomplete pairs must fail construction.
- Test all shared state views at exactly `360x640` logical pixels with `TextScaler.linear(2.0)` and fail on overflow.
- Run explicit contrast guideline checks for all foreground/background pairings Story 1.5 renders.
- Keep the existing raw SQLite-detail suppression test.
- Keep production plugins/database out of focused widget tests through current overrides/in-memory Drift.

## Verification environment

Windows Flutter cannot run from the UNC workspace. Keep repository files authoritative and use a disposable mirror under `C:\tmp` for Flutter commands.

Required gates:

```text
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --reporter expanded
flutter build apk --debug
```

If an Android target is available, verify themed launch -> TindaTrack loading -> Dashboard shell, all four tabs, retry presentation, and readability. Otherwise record the device check as not run.

Effective versions:

- Flutter `3.44.0`
- Dart `3.12.0`
- Riverpod `3.3.2`
- go_router `17.3.0`
- Drift `2.34.0`
- drift_flutter `0.3.0`

Do not change dependencies or lockfile.

## Important files

- Story 1.5:
  `_bmad-output/implementation-artifacts/1-5-apply-mvp-theme-and-base-ui-states.md`
- Sprint status:
  `_bmad-output/implementation-artifacts/sprint-status.yaml`
- Previous Story 1.4:
  `_bmad-output/implementation-artifacts/1-4-add-main-navigation-shell.md`
- Deferred work:
  `_bmad-output/implementation-artifacts/deferred-work.md`
- App root:
  `tindatrack/lib/app/app.dart`
- Navigation shell:
  `tindatrack/lib/app/navigation/app_shell.dart`
- Current widget regressions:
  `tindatrack/test/widget_test.dart`
- Exact UX tokens:
  `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md`
- UX state/accessibility guidance:
  `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md`
- Architecture:
  `_bmad-output/planning-artifacts/architecture.md`

## Deferred work outside Story 1.5

- Retry can be stranded by a database close that hangs, throws, or completes with an `Error`.
- `closeManagedDatabase` caches rejected close futures.
- Asynchronous disposal errors need focused lifecycle handling.
- Transitive end-of-life SQLite compatibility packages need review during a later persistence-stack upgrade.

Start now:

1. Inspect `git status`.
2. Load the full Story 1.5 file and sprint status.
3. Run the `bmad-dev-story` workflow exactly.
4. Implement continuously through tests and Android build unless a genuine HALT condition occurs.
5. Move Story 1.5 to `review` only after every required gate passes.
```
