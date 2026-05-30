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

Current BMAD status:
- BMAD installed and committed.
- Analysis completed.
- PRD completed and finalized.
- UX completed and finalized.
- Architecture workflow completed and saved.
- Architecture frontmatter now has:
  `stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]`
  `status: 'complete'`
  `completedAt: '2026-05-30'`
- Latest pushed commits:
  - `8eafa1f Add BMAD planning and architecture docs`
  - `0c46118 Complete BMAD architecture workflow`

Important files:
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
- Completed architecture document:
  `_bmad-output/planning-artifacts/architecture.md`

Key product decisions:
- MVP is an offline-first Android inventory app.
- Target users are sari-sari store owners, helpers, and small sellers.
- MVP core loop:
  `Check stock -> Search/select product -> Stock in/out -> Confirm -> See updated quantity/history`
- MVP includes product CRUD, stock in/out, inventory history, low-stock alerts, dashboard, settings.
- MVP excludes POS, cloud sync, login requirement, supplier management, accounting/profit reports, barcode scanning UI.
- Barcode scanning is post-MVP only.
- Add nullable `barcode` field now for future readiness, but no scanner UI, route, permission, service, or dependency in MVP.
- No fake login screen in MVP.
- No ads in Add Product, Edit Product, Stock In, Stock Out, or save/confirm flows.
- `cost_price` is deferred post-MVP. MVP tracks stock quantity and movement history, not margin/profit/accounting.

Key architecture decisions:
- Starter command:
  `flutter create --empty --platforms android --org com.rkuhonta tindatrack`
- Stack:
  Flutter, Riverpod, Drift over SQLite, Clean Architecture, go_router.
- Structure:
  feature-first folders under `lib/features`, with shared infrastructure under `lib/core` and app shell under `lib/app`.
- IDs:
  use ULID string IDs project-wide.
- Time:
  store timestamps in UTC and use an injectable clock; no direct `DateTime.now()` in domain/data code.
- Database naming:
  database tables/columns use `snake_case`; Dart model/entity fields may use `camelCase`.
- Product deletion:
  archive products, do not hard-delete.
- Stock movement:
  source of truth for quantity changes after product creation.
- Stock In/Out:
  must insert stock movement and update product quantity in one Drift transaction.
- Stock movement history:
  include `product_name_snapshot` and `unit_snapshot` in `stock_movements` unless explicitly rejected before schema implementation.
- Barcode:
  blank barcode input normalizes to `null`; multiple null barcodes allowed; duplicate non-null barcode rejected; uniqueness applies across active and archived products.
- Quantity:
  use integer stock quantities with explicit practical bounds.

Architecture invariants:
- `INV-001`: Product quantity must never be negative.
- `INV-002`: Stock movement insert and product quantity update must commit in one database transaction.
- `INV-003`: Archived products must remain readable in movement history.
- `INV-004`: All stock movements must include `productId`, `type`, `quantity`, `previousQuantity`, `newQuantity`, `reason`, and `createdAt`.
- `INV-005`: Barcode is nullable and unique when present.
- `INV-006`: Stock movement is the source of truth for quantity changes after product creation.
- `INV-007`: User-facing errors must be translated from domain failures into plain language.

Stock Out reason enum:
- `sold`
- `damaged`
- `lost`
- `personal_use`
- `correction`

Recommended next BMAD step:
Start **Create Epics and Stories** using the `bmad-create-epics-and-stories` skill.

Read:
`.agents/skills/bmad-create-epics-and-stories/SKILL.md`

Then proceed with its workflow, starting with:
`.agents/skills/bmad-create-epics-and-stories/steps/step-01-validate-prerequisites.md`

Expected goal:
- Convert the finalized PRD, UX, and completed architecture into implementation epics and user stories.
- Do not jump to coding yet.
- Follow BMAD strictly.
- Present drafts before saving.
- Use Taglish/Filipino-friendly explanations when talking to me.
```
