# New Chat Handoff: Inventory Tracker BMAD Project

Copy/paste this into a new chat:

```markdown
Act as Codex using the BMAD Method for this project.

Workspace:
`\\wsl.localhost\Ubuntu\home\rkuhonta\Inventory`

Repository:
`https://github.com/ryankuhonta/Inventory.git`

Project:
Android-first Flutter Inventory Tracker app for Philippine sari-sari stores and small businesses.

Communication:
- Use Taglish/Filipino-friendly explanations.
- Follow BMAD workflows strictly.
- Present required drafts/checkpoints before saving when the selected BMAD skill requires them.
- Do not skip workflow gates or jump directly to implementation.

Current BMAD status:
- Analysis, PRD, UX, Architecture, Epics and Stories, Implementation Readiness, and Sprint Planning are complete.
- Implementation Readiness result: `READY`, with `0 critical issues` and `0 remaining major issues`.
- Epic 1 is `in-progress`.
- Story 1.1 is `done`.
- Story 1.2 is `done`.
- Story 1.3 is the next backlog story.

Next required BMAD step:
Run **Create Story** for Story 1.3 using the `bmad-create-story` skill.

Read:
`.agents/skills/bmad-create-story/SKILL.md`

Target story:
`1-3-provide-offline-app-launch-and-splash-initialization`

Do not run `bmad-dev-story` or start coding Story 1.3 until its story file has been created and the Create Story workflow is complete.

Important implementation artifacts:
- Sprint status:
  `_bmad-output/implementation-artifacts/sprint-status.yaml`
- Completed Story 1.1:
  `_bmad-output/implementation-artifacts/1-1-set-up-initial-project-from-flutter-empty-starter-template.md`
- Completed Story 1.2:
  `_bmad-output/implementation-artifacts/1-2-establish-app-architecture-and-local-core-services.md`
- Deferred review work:
  `_bmad-output/implementation-artifacts/deferred-work.md`
- Flutter application:
  `tindatrack/`

Story 1.1 result:
- Generated an Android-only Flutter project with:
  `flutter create --empty --platforms android --org com.rkuhonta tindatrack`
- Flutter package is under `tindatrack/`.
- Android namespace/application ID is `com.rkuhonta.tindatrack`.
- Flutter 3.44.0 and Dart 3.12.0 were used.
- Added Riverpod, Drift/SQLite, go_router, build_runner, mocktail, and Very Good Analysis.
- Preserved the minimal local-only screen:
  - `TindaTrack`
  - `Offline inventory tracker`
- Formatting, analysis, widget tests, Android debug APK build, code review, and live offline emulator launch passed.

Story 1.2 result:
- Added meaningful `lib/app`, `lib/core`, and `lib/features` architecture boundaries.
- Moved the root app widget to `lib/app/app.dart`.
- Wrapped app startup in Riverpod `ProviderScope`.
- Added lazy and disposable app-level providers for:
  - Drift database
  - ULID ID generator
  - injectable UTC clock
- Added an empty Drift schema-v1 scaffold with:
  - injectable `QueryExecutor`
  - production `drift_flutter` opener using `tindatrack.sqlite`
  - generated Drift code
  - `build.yaml` database registration
  - initial schema snapshot under `drift_schemas/`
- Added typed result and shared failure/message foundations.
- Feature-owned failures can extend the shared failure type.
- Failure messages use neutral Filipino-friendly English and never expose raw technical details.
- Added focused tests for providers, async database disposal, empty schema, failure mapping, result types, ULIDs, UTC clock, and the smoke screen.
- Code review resolved all five actionable findings.
- One pre-existing transitive SQLite compatibility-package concern was deferred until a future Drift infrastructure upgrade.
- Final verification passed:
  - Drift code generation
  - Drift migration snapshot generation
  - strict formatting
  - Flutter analysis
  - 13 tests
  - Android debug APK build
- Story 1.2 intentionally did not add splash/bootstrap flow, routing, bottom navigation, final theme, feature tables, DAOs, or MVP feature screens.

Current sprint status:
- `epic-1`: `in-progress`
- Story 1.1: `done`
- Story 1.2: `done`
- Story 1.3: `backlog`
- Story 1.4 and all later stories/epics remain `backlog`.

Important planning files:
- Main planning document:
  `docs/bmad-inventory-tracker-plan.md`
- PRD:
  `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/prd.md`
- PRD addendum:
  `_bmad-output/planning-artifacts/prds/prd-Inventory-2026-05-28/addendum.md`
- UX design:
  `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md`
- UX experience:
  `_bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md`
- Architecture:
  `_bmad-output/planning-artifacts/architecture.md`
- Epics and stories:
  `_bmad-output/planning-artifacts/epics.md`
- Implementation readiness report:
  `_bmad-output/planning-artifacts/implementation-readiness-report-2026-06-01.md`

Key product decisions:
- MVP is an offline-first Android inventory app.
- Target users are sari-sari store owners, helpers, and small sellers.
- Core loop:
  `Check stock -> Search/select product -> Stock in/out -> Confirm -> See updated quantity/history`
- MVP includes product CRUD, stock in/out, inventory history, low-stock alerts, dashboard, and settings.
- MVP excludes POS, cloud sync, login requirement, supplier management, accounting/profit reports, and barcode scanner UI.
- Add a nullable `barcode` field for future readiness, but no scanner UI, route, permission, service, or dependency in MVP.
- No fake login screen.
- No ads in Add Product, Edit Product, Stock In, Stock Out, or save/confirm flows.
- `cost_price` is deferred post-MVP.
- Restore Archived Product UI is deferred for MVP.
- PHP is the fixed MVP currency context.
- Dashboard "Stock Changes Today" uses the device/app local timezone day; stored timestamps remain UTC.

Key architecture decisions:
- Stack: Flutter, Riverpod, Drift over SQLite, Clean Architecture, and go_router.
- Use feature-first folders under `lib/features`.
- Shared infrastructure goes under `lib/core`.
- App shell, routing, and theme go under `lib/app`.
- Use ULID string IDs project-wide.
- Store timestamps in UTC and use an injectable clock.
- Do not call `DateTime.now()` directly in domain/data code.
- Database tables/columns use `snake_case`; Dart fields may use `camelCase`.
- Archive products instead of hard-deleting them.
- Stock movement is the source of truth for quantity changes after product creation.
- Stock In/Out must insert the movement and update product quantity in one Drift transaction.
- Stock movement history stores `product_name_snapshot` and `unit_snapshot`.
- Blank barcode normalizes to `null`; multiple null barcodes are allowed.
- Duplicate non-null barcodes are rejected across active and archived products.
- Quantities use integers with explicit practical bounds.

Stock Out reason enum:
- `sold` = nabenta
- `damaged` = sira
- `lost` = nawala
- `personal_use` = kinuha for personal use
- `correction` = correction/adjustment

MVP Stock Out handling:
- Data/domain supports the reason enum.
- Default reason is `sold`.
- Visible reason selector UI is deferred unless separately scoped.
- Optional note remains visible.

Start by inspecting the current files and Git status, then follow the Create Story workflow for Story 1.3.
```
