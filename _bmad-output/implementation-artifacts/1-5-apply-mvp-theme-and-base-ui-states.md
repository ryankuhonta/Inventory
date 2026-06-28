---
baseline_commit: eb878cb81f8039bdd0fe175a53716baf37de2ece
---

# Story 1.5: Apply MVP Theme And Base UI States

Status: done

<!-- Note: Validation is optional. Run validate-create-story for an independent readiness check before dev-story. -->

## Story

As a store owner or helper,
I want the app to be readable and easy to tap,
so that I can use it comfortably on a small Android phone.

## Acceptance Criteria

1. **Given** the root app theme is configured  
   **When** the launch states, navigation shell, and four main placeholder screens render  
   **Then** the single `MaterialApp.router` uses a light Flutter Material 3 theme built from the approved color, typography, spacing, radius, and tap-target tokens  
   **And** the visual style is practical, readable, minimally elevated, and uncluttered.

2. **Given** the approved design tokens are inspected  
   **When** the theme and token files are reviewed  
   **Then** they expose the exact colors `#F8FAF7`, `#FFFFFF`, `#EEF3EE`, `#172018`, `#5E6B60`, `#2E7D4F`, `#24643F`, `#B7791F`, `#FFF7E0`, `#B42318`, `#FDECEC`, and `#DDE5DD` with their documented semantic roles  
   **And** typography uses system/Roboto-compatible `28/700`, `20/700`, `16/700`, `14/400`, and `12/600` styles, spacing uses `4/8/16/24/32`, and radii use `6/8/12`.

3. **Given** a screen needs loading, empty, or error feedback  
   **When** `AppLoadingView`, `AppEmptyState`, or `AppErrorView` is shown  
   **Then** it presents a lightweight, reusable, centered state using plain Filipino-friendly English  
   **And** empty/error states support a clear optional next-step action without owning navigation or business logic.

4. **Given** an initialization or data failure is displayed  
   **When** `AppErrorView` renders safe mapped copy  
   **Then** it communicates error meaning with visible text and an icon or equivalent non-color cue  
   **And** its API accepts no throwable, stack-trace, failure, or diagnostic-detail parameter; every failure call site maps its typed failure to safe display copy before constructing the view, with tests proving raw debug details are absent.

5. **Given** common navigation and action controls render on an Android phone  
   **When** accessibility checks run at normal and enlarged system text scales  
   **Then** applicable tap targets meet the 48dp Android floor, controls retain useful semantic labels, and the tested state layouts do not overflow on a small portrait viewport  
   **And** warnings or errors are never communicated by color alone.

6. **Given** Story 1.5 implementation is complete  
   **When** quality verification runs  
   **Then** focused theme/state/accessibility tests, all 30 existing bootstrap/navigation/lifecycle regressions, strict formatting, Flutter analysis, and an Android debug build pass  
   **And** no dependency, asset, route, permission, database schema, DAO, migration, generated database, or feature behavior is added.

## Tasks / Subtasks

- [x] Preserve the completed Story 1.4 baseline and bound Story 1.5 scope (AC: 1, 5, 6)
  - [x] Treat all current uncommitted Stories 1.3 and 1.4 implementation/review changes as existing user work; do not reset, rewrite, stage, or claim them as Story 1.5 work.
  - [x] Preserve `ProviderScope -> MaterialApp.router -> LaunchGate -> StatefulShellRoute/AppShell`, the four route roots, tab state, Android Back behavior, bootstrap retry, database lifecycle, app title, and disabled debug banner.
  - [x] Add no packages, custom font files, images, routes, permissions, persistence changes, network code, feature controllers, repositories, or business behavior.
  - [x] Do not implement dark mode, tablet optimization, final app branding/icons, product/dashboard/history/settings features, status badges, snackbars for future save flows, forms, or the final Story 5.5 accessibility audit.

- [x] Add the approved app theme and token files (AC: 1, 2, 5)
  - [x] Add `lib/app/theme/app_colors.dart` with all exact `DESIGN.md` colors and semantic names: background, surface, surface-muted, primary/secondary text, primary, primary-pressed, success, warning/warning-surface, danger/danger-surface, and border.
  - [x] Add an immutable `AppSpacing` `ThemeExtension` under `lib/core/ui/app_spacing.dart` with `xs=4`, `sm=8`, `md=16`, `lg=24`, and `xl=32`, plus correct `copyWith`/`lerp`; register it in the app theme so core widgets and feature roots can consume spacing without importing `app/theme` or duplicating literals.
  - [x] Add `lib/app/theme/app_typography.dart` using the platform system family (Roboto on Android) and map the approved display, title, section, body, and label sizes/weights into a `TextTheme`; do not add Google Fonts or disable system text scaling.
  - [x] Add `lib/core/ui/app_dimensions.dart` for the `6/8/12` radii, documented `8dp` card/button/input radius, `999dp` pill override for later status chips, and `48dp` minimum tap target without duplicating spacing or color constants.
  - [x] Add `lib/app/theme/app_theme.dart` exposing one light `ThemeData` with `useMaterial3: true`, approved typography, `MaterialTapTargetSize.padded`, off-white scaffold background, minimally elevated/bordered surfaces, 8dp button/input shapes, and component minimum sizes that preserve 48dp action targets.
  - [x] Use `ColorScheme.fromSeed` only for unspecified roles, then explicitly map `primary=#2E7D4F`, `surface=#FFFFFF`, `surfaceContainer=#EEF3EE`, `onSurface=#172018`, `onSurfaceVariant=#5E6B60`, `error=#B42318`, `errorContainer=#FDECEC`, and `outline=#DDE5DD`; configure the pressed `FilledButton` state as `#24643F`.
  - [x] Keep warning/success semantic tokens available through `AppColors`; do not force them into unrelated `ColorScheme` roles and do not treat token presence alone as proof of contrast compliance.
  - [x] Do not render normal-sized warning text as `#B7791F` on `#FFF7E0`; use primary text for readable warning copy and reserve warning color for an icon/border/accent paired with a visible label.

- [x] Integrate the theme into existing app presentation without changing behavior (AC: 1, 2, 5, 6)
  - [x] Set the theme only on the existing root `MaterialApp.router` in `lib/app/app.dart`; do not add a nested app, recreate the router, or move bootstrap into routing.
  - [x] Preserve the current launch-gate state machine and exact safe retry/database-close ordering while replacing only the private loading/error presentation with the shared state views.
  - [x] Keep the Story 1.4 `NavigationBar` destinations, order, visible labels, `currentIndex`, and `goBranch` behavior unchanged; let the root theme style it and modify `app_shell.dart` only if a measured accessibility requirement cannot be met through `ThemeData`.
  - [x] Apply the shared typography and spacing tokens to the skeletal Dashboard, Products, History, and Settings roots while preserving their keys, identities, neutral placeholder copy, and lack of feature actions/data.
  - [x] Do not invent navigation container, indicator, icon, animation, or elevation tokens that the UX documents leave unspecified; retain consistent Material 3 defaults.

- [x] Add reusable loading, empty, and error state views (AC: 3, 4, 5)
  - [x] Add stateless, presentation-only `AppLoadingView`, `AppEmptyState`, and `AppErrorView` widgets under `lib/core/widgets/`; they must not import Riverpod, go_router, Drift, feature code, repositories, or failure implementations.
  - [x] Keep the shared views embeddable content widgets rather than full `MaterialApp` instances or feature-owned navigation shells; callers remain responsible for the surrounding page/`Scaffold`.
  - [x] `AppLoadingView` may accept safe title/message text and must use a small progress indicator with a useful loading semantic/live-region label.
  - [x] `AppEmptyState` must require a clear title, allow optional explanatory text/icon, and expose an optional action label/callback pair for feature stories to wire later; action label and callback must be supplied together or neither, enforced by constructor assertions.
  - [x] `AppErrorView` must accept only already-safe visible message text plus an optional action label/callback pair; do not accept or stringify `Object`, `Exception`, `Error`, stack trace, or database failure details.
  - [x] Error presentation must include a visible icon and text in addition to danger color. Error action label and callback must be supplied together or neither; neither produces no button, incomplete pairs fail construction, and rendered actions retain at least a 48dp tap target.
  - [x] Reuse the existing `FailureMessageMapper` before passing initialization copy into `AppErrorView`; do not duplicate failure mapping inside the widget.
  - [x] Do not add speculative `button_loading`, `primary_button`, `confirm_dialog`, warning-banner, snackbar service, or feature-specific empty-state APIs in this story.

- [x] Add focused theme, base-state, and accessibility tests (AC: 1-6)
  - [x] Add mirrored tests under `test/app/theme/` that assert Material 3 is enabled, every exact token value is retained, the approved `TextTheme` roles have the required sizes/weights, scaffold/surface/error/outline mappings are correct, and button/input shapes and action minimum sizes use the documented values.
  - [x] Add tests under `test/core/widgets/` for loading title/message/progress semantics, empty state with and without an action, error icon/text/action, callback invocation, and omission/disable behavior for incomplete optional actions.
  - [x] Prove `AppErrorView` has no raw throwable input and visible initialization errors still come only from `FailureMessageMapper`; preserve the existing raw SQLite-detail suppression assertion.
  - [x] Update `test/widget_test.dart` to verify the root app supplies the approved theme to splash, failure, Dashboard, and navigation descendants without weakening any of the 30 Story 1.3/1.4 regressions.
  - [x] Use Flutter accessibility guideline checks or precise hit-test size assertions to verify navigation/retry/state actions meet Android's 48dp floor and retain labels; do not infer accessibility from icon size or color.
  - [x] Test all three shared state views, including action variants, at exactly `360x640` logical pixels with `TextScaler.linear(2.0)` and fail on any framework overflow exception.
  - [x] Run `textContrastGuideline` (or an equally explicit ratio assertion) for every foreground/background pairing actually rendered by Story 1.5, including primary actions, normal surface text, and error presentation.
  - [x] Verify supplying neither action label nor callback renders no button, while either incomplete label/callback pair fails construction.
  - [x] Verify the error state includes non-color cues and that all four main placeholder screens remain reachable with their canonical keys and route behavior unchanged.

- [x] Run regression and Android verification (AC: 1-6)
  - [x] Run `dart format --output=none --set-exit-if-changed .`.
  - [x] Run `flutter analyze`.
  - [x] Run `flutter test --reporter expanded`.
  - [x] Run `flutter build apk --debug`.
  - [x] If an Android target is available, manually verify the themed native launch -> TindaTrack loading state -> Dashboard shell, all four tabs, retry presentation, and readability on the configured phone viewport; otherwise record the live check as not run.
  - [x] Record exact commands, effective versions, final test count, build result, device result, and UNC mirror use in the Dev Agent Record.

### Review Findings

- [x] [Review][Patch] Disabled buttons retain the active primary fill [tindatrack/lib/app/theme/app_theme.dart:63]
- [x] [Review][Patch] Navigation labels bypass the approved 12/600 typography [tindatrack/lib/app/theme/app_theme.dart:36]
- [x] [Review][Patch] Enlarged-text branch test places MediaQuery outside MaterialApp [tindatrack/test/widget_test.dart:376]
- [x] [Review][Patch] Navigation accessibility verification measures layout rather than semantic tap targets and labels [tindatrack/test/widget_test.dart:365]
- [x] [Review][Patch] Contrast coverage omits navigation and placeholder screens [tindatrack/test/widget_test.dart:350]
- [x] [Review][Patch] Error-view radius is coupled to a spacing token instead of the radius token [tindatrack/lib/core/widgets/app_error_view.dart:41]
- [x] [Review][Patch] Root rebuilds recreate the immutable theme graph [tindatrack/lib/app/theme/app_theme.dart:10]
- [x] [Review][Patch] Story-owned Dart source and test files are executable [tindatrack/lib/app/theme/app_theme.dart:1]
- [x] [Review][Patch] Filled-button typography duplicates the approved label token as a literal [tindatrack/lib/app/theme/app_theme.dart:60]
- [x] [Review][Defer] Retry can throw while reading a failed database provider [tindatrack/lib/app/app.dart:78] — deferred, pre-existing
- [x] [Review][Defer] A database close that never completes can strand Retry [tindatrack/lib/app/app.dart:79] — deferred, pre-existing
- [x] [Review][Defer] A rejected cached close future blocks later retries [tindatrack/lib/app/providers.dart:40] — deferred, pre-existing
- [x] [Review][Defer] Provider disposal can surface an unhandled asynchronous close error [tindatrack/lib/app/providers.dart:34] — deferred, pre-existing

## Dev Notes

### Developer Context

Stories 1.1-1.4 established the Android project, feature/core boundaries, local bootstrap/retry lifecycle, stable app-scoped router, and four stateful navigation branches. Story 1.5 closes Epic 1 by supplying the approved visual/accessibility foundation and reusable loading/empty/error presentation for later feature stories.

The required composition remains:

```text
ProviderScope
`-- MaterialApp.router(theme: AppTheme.light)
    `-- builder: LaunchGate(routerChild)
        |-- loading -> Scaffold + AppLoadingView
        |-- failure -> Scaffold + AppErrorView(safe mapped copy, Retry)
        `-- success -> StatefulShellRoute router child
            `-- AppShell + themed NavigationBar
                |-- Dashboard placeholder
                |-- Products placeholder
                |-- History placeholder
                `-- Settings placeholder
```

Theme and state primitives must remain presentation-only. They must not read the database, bootstrap provider, router, or feature state.

### Story Boundaries

- **Story 1.5 owns:** exact visual tokens, root light Material 3 theme, base dimensions, shared loading/empty/error views, initial small-screen/accessibility tests, and token styling of current placeholders.
- **Stories 2.3/2.4 own Products states:** real product list, no-products action, and no-search-results behavior.
- **Stories 2.5 and later own inventory statuses:** Low Stock/Out of Stock badges and domain-specific warning behavior.
- **Stories 3.4/3.5 own stock feedback:** form loading, validation, commit success, and blocked Stock Out states.
- **Story 3.6 owns History empty state.**
- **Story 4.2 owns Dashboard loading/content/empty/error behavior.**
- **Story 5.1 owns Settings content and error behavior.**
- **Story 5.5 owns final whole-app UX/accessibility consistency and polish.**

The shared widgets added here are foundations for those stories, not permission to implement their feature behavior early.

### Exact Approved Tokens

| Category | Token | Value |
| --- | --- | --- |
| Color | background | `#F8FAF7` |
| Color | surface | `#FFFFFF` |
| Color | surfaceMuted | `#EEF3EE` |
| Color | textPrimary | `#172018` |
| Color | textSecondary | `#5E6B60` |
| Color | primary / success | `#2E7D4F` |
| Color | primaryPressed | `#24643F` |
| Color | warning | `#B7791F` |
| Color | warningSurface | `#FFF7E0` |
| Color | danger | `#B42318` |
| Color | dangerSurface | `#FDECEC` |
| Color | border | `#DDE5DD` |
| Typography | display | `28sp`, weight `700` |
| Typography | title | `20sp`, weight `700` |
| Typography | section | `16sp`, weight `700` |
| Typography | body | `14sp`, weight `400` |
| Typography | label | `12sp`, weight `600` |
| Spacing | xs / sm / md / lg / xl | `4 / 8 / 16 / 24 / 32dp` via core `AppSpacing` theme extension |
| Radius | small / medium / large | `6 / 8 / 12dp` |
| Component | card / button / input radius | `8dp` |
| Component | status-pill override | `999dp` |
| Accessibility | minimum applicable tap target | `48dp` |

Use the platform system font; Android supplies Roboto. Do not add a font dependency or asset. The UX mentions medium/semibold product-row names but defines no separate weight token; do not invent that token in Story 1.5.

### Current Files To Update

#### `tindatrack/lib/app/app.dart`

- **Current state:** one `MaterialApp.router` reads the stable Riverpod router and uses a private launch gate. Private splash and initialization-failure widgets render loading and safe retry presentation.
- **This story changes:** add `AppTheme.light`; compose private launch-state wrappers from `AppLoadingView` and `AppErrorView`.
- **Must preserve:** title, debug-banner setting, router identity, launch-gate `AsyncValue` handling, programming-error behavior, safe mapper usage, duplicate-retry guard, serialized close-before-invalidate ordering, and router child on success.
- **Must avoid:** moving retry/database logic into shared widgets, invalidating the router, nesting apps, or exposing raw errors.

#### `tindatrack/lib/app/navigation/app_shell.dart`

- **Current state:** owns the persistent `Scaffold`, router shell body, and exact four-destination `NavigationBar`.
- **This story changes:** normally none; root component themes should provide appearance and tap-target behavior.
- **Must preserve:** destination order/labels/icons, always-visible labels, `currentIndex`, and `goBranch(index, initialLocation: index == currentIndex)`.
- **Must avoid:** local tab state, custom Back interception, future routes, badges, FABs, drawers, or speculative polish.

#### Four branch placeholder screens

- **Current state:** each is a skeletal keyed `Scaffold` with a centered identity and neutral placeholder copy.
- **This story changes:** apply approved title/body styles, secondary text color, and token spacing/padding so current main screens visibly consume the theme.
- **Must preserve:** keys, screen names, placeholder meaning, route ownership, and no data/actions.

#### `tindatrack/test/widget_test.dart`

- **Current state:** 30 passing tests across the repository after Story 1.4 review; widget tests protect splash, safe failure, retry, database rotation, navigation, provider identity, and Android Back behavior.
- **This story changes:** add theme/state/accessibility assertions and adapt widget-type expectations if private launch presentation delegates to shared views.
- **Must preserve:** every bootstrap, raw-detail suppression, retry, router, database, and Back assertion; tests continue using provider overrides and in-memory Drift.

### Technical Requirements

- Use the repository-resolved Flutter `3.44.0`, Dart `3.12.0`, Riverpod `3.3.2`, go_router `17.3.0`, Drift `2.34.0`, and drift_flutter `0.3.0`; do not change dependency constraints or lockfile.
- Use `ThemeData(useMaterial3: true, ...)` or an equivalent Material 3 construction. Prefer `ColorScheme.fromSeed(...).copyWith(...)` so unspecified roles retain coherent accessible Material defaults.
- Set `materialTapTargetSize: MaterialTapTargetSize.padded`; component themes may additionally set a 48dp minimum action height.
- Use `ThemeData` component themes rather than repeating button/input/navigation styling in feature widgets.
- Keep `AppColors` and `AppTypography` under `lib/app/theme`; keep the cross-feature `AppSpacing` theme extension, dimensions, and shared state widgets under `lib/core`.
- Register `AppSpacing` in `ThemeData.extensions`; core widgets and feature roots read it through `Theme.of(context).extension<AppSpacing>()` and must not import `app/theme`.
- Shared state widgets accept display data/callbacks only. They do not accept domain failures or own mapping, routing, provider reads, retries, or persistence.
- Respect system text scaling. Do not clamp `MediaQuery.textScaler`, use viewport-derived font sizes, or set negative letter spacing.
- Keep UI stateless/lightweight with no decorative animation, image, gradient, or expensive custom painting.
- Never log or render raw database/exception details.

### Architecture Compliance

- `lib/app/theme`: application theme and exact design tokens.
- `lib/core/ui`: cross-feature spacing extension and dimensions such as radii and tap-target constants.
- `lib/core/widgets`: reusable presentation-only loading, empty, and error views.
- `lib/app/app.dart`: root theme and bootstrap composition.
- `lib/features/*/presentation/screens`: feature-owned roots consuming, but not defining, the theme.
- `core` must not import `app` or `features`; therefore shared widgets must consume `Theme.of(context)` rather than importing `AppColors` or other `app/theme` files.
- `app` may import `core`; features may import `core`, but cross-feature theme ownership remains in `app`.
- No database/schema/code generation action is required.

### Library And Framework Requirements

| Package/API | Resolved version | Story 1.5 use |
| --- | --- | --- |
| Flutter Material | Flutter `3.44.0` | Material 3 `ThemeData`, `ColorScheme`, component themes, `NavigationBar`, state views |
| Flutter test accessibility guidelines | Flutter `3.44.0` | Android tap-target, semantic-label, and optional contrast checks |
| flutter_riverpod | `3.3.2` | Existing root/bootstrap/router lifecycle only; no new theme provider |
| go_router | `17.3.0` | Existing shell only; no route changes |
| drift / drift_flutter | `2.34.0` / `0.3.0` | Existing bootstrap only; no persistence changes |

Do not add Google Fonts, another design system, state manager, router, animation library, localization package, connectivity package, or feature SDK.

### File Structure Requirements

Expected new or updated files are approximately:

```text
tindatrack/
|-- lib/
|   |-- app/
|   |   |-- app.dart
|   |   `-- theme/
|   |       |-- app_colors.dart
|   |       |-- app_theme.dart
|   |       `-- app_typography.dart
|   |-- core/
|   |   |-- ui/
|   |   |   |-- app_dimensions.dart
|   |   |   `-- app_spacing.dart
|   |   `-- widgets/
|   |       |-- app_empty_state.dart
|   |       |-- app_error_view.dart
|   |       `-- app_loading_view.dart
|   `-- features/
|       |-- dashboard/presentation/screens/dashboard_screen.dart
|       |-- products/presentation/screens/product_list_screen.dart
|       |-- history/presentation/screens/movement_history_screen.dart
|       `-- settings/presentation/screens/settings_screen.dart
`-- test/
    |-- app/theme/app_theme_test.dart
    |-- core/widgets/app_state_views_test.dart
    `-- widget_test.dart
```

This structure is guidance, not permission to create the full future architecture tree. Add only files with concrete Story 1.5 behavior.

### Testing Requirements

- Test public observable behavior and exact token values; avoid snapshots/goldens that are brittle across rendering environments.
- Theme tests should assert `useMaterial3`, `ColorScheme`, scaffold background, text sizes/weights, spacing/radius constants, component shapes, and minimum sizes.
- Shared-view tests should cover content, optional actions, callback behavior, semantics, and non-color error cues.
- Use `tester.ensureSemantics()` and Flutter accessibility matchers where appropriate; dispose the semantics handle.
- Test at least one 48dp action target and the four navigation destinations. Do not equate a 24dp icon with its larger interactive target.
- Exercise every shared state view at exactly `360x640` logical pixels with `TextScaler.linear(2.0)`; production must not clamp user scaling.
- Treat action label/callback as an invariant pair in both empty and error views; test both valid variants and constructor assertion failures for incomplete pairs.
- Run explicit contrast guideline checks for all foreground/background combinations Story 1.5 actually renders. Warning tokens are not permission to use amber as normal-sized text on its pale warning surface.
- Check framework exceptions after small-screen/large-text pumps so overflow errors fail the test deterministically.
- Preserve the complete 30-test Story 1.4 baseline; final count must increase.
- Windows Flutter tooling cannot run from the UNC workspace. Use a disposable `C:\tmp` mirror for format/analyze/test/build while keeping repository files authoritative.
- Run a full Android debug build after tests. A live device check is conditional on target availability and must be recorded honestly.

### Previous Story Intelligence

- Story 1.4 created one stable Riverpod-owned `GoRouter`, `StatefulShellRoute.indexedStack`, exact four branch roots, and a router child wrapped by bootstrap through `MaterialApp.router.builder`.
- Router and database creation counts remain stable across tab changes and Android Back; Story 1.5 styling must not introduce provider reads or rebuild lifecycle objects.
- Launch failure text already comes from `FailureMessageMapper`; reuse it before `AppErrorView`.
- Navigation labels and branch keys are covered by tests. Do not change them while styling.
- Story 1.4 review added Android Back, complete failed-bootstrap shell isolation, and real provider-owned router-identity tests. Preserve all 30 passing tests.
- Live API 36 verification previously confirmed native launch, TindaTrack splash, Dashboard shell, and all four tabs.
- Existing deferred work remains out of scope: retry can be stranded by a hanging/failing close, rejected close futures remain cached, asynchronous disposal errors need handling, and transitive EOL SQLite compatibility packages need later review.

### Git Intelligence Summary

- Current branch: `codex/complete-stories-1-1-and-1-2`; HEAD: `eb878cb Complete Flutter foundation stories`.
- Stories 1.3 and 1.4, their review fixes, story records, deferred-work entries, and sprint updates remain uncommitted.
- A diff against HEAD includes multiple completed stories. Preserve the dirty worktree and separate Story 1.5 files/notes explicitly; do not reset, clean, checkout, stage, or overwrite existing work.
- Recent committed implementation uses strict `very_good_analysis`, Riverpod overrides, in-memory Drift, mirrored Windows test/build execution, and Android debug verification.
- The resolved dependency versions in the working tree are authoritative over older planning-document snapshots.

### Latest Technical Information

- Flutter `3.44.0` official guidance supports Material 3 component themes through `ThemeData`, generated coherent schemes through `ColorScheme.fromSeed`, and component-specific overrides. Use the repository SDK rather than upgrading.
- Flutter's mobile default `MaterialTapTargetSize.padded` expands affected controls to a 48x48 target; set it explicitly and still verify actual controls because not every widget is governed identically.
- Flutter's accessibility guideline API can test Android tap targets, semantic labels, and text contrast. Use deterministic focused checks and treat contrast tests as verification, not as a substitute for exact approved tokens.
- System text scaling is automatic; layouts must provide room at enlarged scale rather than disabling or clamping it in production.

Official references:

- [Flutter ThemeData API](https://api.flutter.dev/flutter/material/ThemeData/ThemeData.html)
- [Flutter MaterialTapTargetSize API](https://api.flutter.dev/flutter/material/MaterialTapTargetSize.html)
- [Flutter accessibility design guidance](https://docs.flutter.dev/ui/accessibility/ui-design-and-styling)
- [Flutter accessibility testing guidance](https://docs.flutter.dev/ui/accessibility/accessibility-testing)

### Project Structure Notes

- Architecture places theme/design tokens in `lib/app/theme`, shared dimensions in `lib/core/ui`, and reusable state widgets in `lib/core/widgets`.
- `core` cannot depend on `app`; shared widgets should derive colors and typography from `Theme.of(context)`.
- Exact visual tokens come from `DESIGN.md`; screen/state behavior comes from `EXPERIENCE.md`.
- UX leaves navigation indicator colors/shapes, icon colors, animation, and elevation unspecified. Use Material 3 defaults instead of creating extra tokens.
- No `project-context.md` exists; finalized planning artifacts, completed Story 1.4, current source, Git state, and current official Flutter docs are authoritative.

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story-15-Apply-MVP-Theme-And-Base-UI-States]
- [Source: _bmad-output/planning-artifacts/epics.md#UX-Design-Requirements]
- [Source: _bmad-output/planning-artifacts/architecture.md#Frontend-Architecture]
- [Source: _bmad-output/planning-artifacts/architecture.md#Loading-State-Patterns]
- [Source: _bmad-output/planning-artifacts/architecture.md#Project-Structure--Boundaries]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Colors]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Typography]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Layout--Spacing]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Shapes]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#State-Patterns]
- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Accessibility-Floor]
- [Source: _bmad-output/planning-artifacts/implementation-readiness-report-2026-06-01.md#UX-To-Architecture-Alignment]
- [Source: _bmad-output/implementation-artifacts/1-4-add-main-navigation-shell.md#Previous-Story-Intelligence]

## Story Completion Status

- Story file created from finalized Epic 1 requirements and exact approved UX tokens.
- PRD, addendum, epics, architecture, UX design/experience, implementation-readiness, previous-story, current-code, Git, parallel artifact analysis, and official Flutter guidance analyzed.
- Scope is bounded to the light Material 3 theme, shared state views, current placeholder styling, and accessibility verification; all feature behavior and final polish remain deferred to their owning stories.
- Status set to `ready-for-dev`.
- Completion note: Ultimate context engine analysis completed - comprehensive developer guide created.

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Implementation Plan

- Protect the 30-test Story 1.4 baseline before changing presentation.
- Add exact theme tokens and focused failing tests, then implement the minimum light Material 3 theme.
- Add reusable presentation-only state views and integrate them at the existing launch gate.
- Style only the four skeletal route roots, preserving router, navigation, retry, and database behavior.
- Run focused accessibility checks, full regression, strict analysis/formatting, and Android debug build from the required Windows mirror.

### Debug Log References

- 2026-06-27 baseline: `flutter test --reporter expanded` passed 30/30 before Story 1.5 changes.
- RED: focused theme/state tests failed because the token, theme, and shared-widget files did not exist; root integration test then failed because the old private launch presentation was still active.
- GREEN: focused token/state tests passed; root integration and small-phone/large-text tests passed; full suite passed 44/44.
- Final commands in `C:\tmp\inventory-story15-work`: `dart format --output=none --set-exit-if-changed .` (39 files, 0 changed), `flutter analyze` (no issues), `flutter test --reporter expanded` (44 passed), and `flutter build apk --debug` (success).
- Effective tooling: Flutter 3.44.0 stable, Dart 3.12.0, DevTools 2.57.0. APK: `build\app\outputs\flutter-apk\app-debug.apk` in the mirror.
- Device result: live Android check not run; `flutter devices` found only Windows, Chrome, and Edge. The APK build emitted a non-blocking Android SDK XML version warning.
- UNC note: Windows Flutter tooling used the disposable `C:\tmp\inventory-story15-work` mirror; the WSL/UNC workspace remained authoritative and only Story 1.5-owned files were copied back.

### Completion Notes List

- Preserved the authoritative uncommitted Story 1.3/1.4 baseline and all router, branch-state, Android Back, retry, database-close, and provider-lifecycle behavior.
- Added the exact approved colors, typography, spacing extension, radii/dimensions, light Material 3 root theme, 48dp action sizing, and pressed-primary styling without dependencies or assets.
- Added reusable loading, empty, and safe error views with paired optional actions, loading semantics, non-color error cues, and large-text/small-screen resilience.
- Applied shared theme typography and spacing to the existing launch states and four canonical skeletal branch roots without adding feature behavior.
- Added exact-token, component-theme, action-invariant, contrast, semantics, tap-target, raw-detail suppression, root-theme, navigation reachability, and 360x640 at 2x text tests. Final suite: 44/44 passed.

- Resolved all 9 Story 1.5 code-review patch findings: disabled-state styling, token reuse, navigation typography/accessibility/contrast coverage, effective 2x text scaling, radius semantics, stable theme identity, and source permissions.
- Post-review verification: format clean, Flutter analysis clean, 44/44 tests passed, and Android debug APK built successfully.
### File List

- `_bmad-output/implementation-artifacts/1-5-apply-mvp-theme-and-base-ui-states.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `tindatrack/lib/app/app.dart`
- `tindatrack/lib/app/theme/app_colors.dart`
- `tindatrack/lib/app/theme/app_theme.dart`
- `tindatrack/lib/app/theme/app_typography.dart`
- `tindatrack/lib/core/ui/app_dimensions.dart`
- `tindatrack/lib/core/ui/app_spacing.dart`
- `tindatrack/lib/core/widgets/app_empty_state.dart`
- `tindatrack/lib/core/widgets/app_error_view.dart`
- `tindatrack/lib/core/widgets/app_loading_view.dart`
- `tindatrack/lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- `tindatrack/lib/features/history/presentation/screens/movement_history_screen.dart`
- `tindatrack/lib/features/products/presentation/screens/product_list_screen.dart`
- `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart`
- `tindatrack/test/app/theme/app_theme_test.dart`
- `tindatrack/test/core/widgets/app_state_views_test.dart`
- `tindatrack/test/widget_test.dart`

## Change Log

- 2026-06-27: Implemented Story 1.5 light Material 3 theme, shared base states, themed placeholders, and focused accessibility/regression coverage; moved story to review.
- 2026-06-28: Addressed all 9 code-review patch findings and completed post-review verification; story marked done.
