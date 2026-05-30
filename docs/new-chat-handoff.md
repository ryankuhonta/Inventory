# New Chat Handoff: Inventory Tracker BMAD Project

Copy/paste this into a new chat:

```markdown
Act as Codex using the BMAD Method for this project.

Workspace:
`\\wsl.localhost\Ubuntu\home\rkuhonta\Inventory`

Project:
Android-first Flutter Inventory Tracker app for Philippine sari-sari stores and small businesses.

Current BMAD status:
- BMAD installed.
- Analysis completed.
- PRD completed and finalized.
- UX completed and finalized.
- Architecture workflow is in progress.
- Architecture Step 1 completed: workspace initialized.
- Architecture Step 2 completed: project context analysis saved.
- Architecture Step 3 completed: starter template evaluation saved.
- We are currently at Architecture Step 4: Core Architectural Decisions.

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
- Architecture document:
  `_bmad-output/planning-artifacts/architecture.md`

Key product decisions:
- MVP is an offline-first Android inventory app.
- Target users are sari-sari store owners, helpers, and small sellers.
- MVP core loop:
  `Check stock -> Search/select product -> Stock in/out -> Confirm -> See updated quantity/history`
- MVP includes product CRUD, stock in/out, inventory history, low-stock alerts, dashboard, settings.
- MVP excludes POS, cloud sync, login requirement, supplier management, accounting, barcode scanning.
- Barcode scanning is planned for next release only.
- Add nullable `barcode` field now for future readiness, but no scanner UI in MVP.
- No fake login screen in MVP.
- No ads in Add Product, Edit Product, Stock In, Stock Out, or save/confirm flows.

Key architecture decisions already saved:
- Starter: `flutter create --empty --platforms android --org com.rkuhonta tindatrack`
- Stack: Flutter, Riverpod, Drift over SQLite, Clean Architecture.
- Structure: feature-first folders.
- IDs: use UUIDs or ULIDs for products and transactions.
- Product deletion should be avoided; archive internally.
- User-facing archive wording may be “Hide product” or “Stop selling.”
- Stock movement is the source of truth after product creation.
- Stock In/Out must be atomic database transactions.

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

Next task:
Continue BMAD Architecture Step 4: Core Architectural Decisions.

Read:
`.agents/skills/bmad-create-architecture/steps/step-04-decisions.md`

Then draft the Step 4 content for:
1. Data Architecture
2. Authentication & Security
3. API & Communication Patterns
4. Frontend Architecture
5. Infrastructure & Deployment

Follow BMAD strictly:
- Do not jump to coding yet.
- Present the Step 4 draft first.
- Then offer:
  **A** - Advanced Elicitation
  **P** - Party Mode
  **C** - Continue/save to architecture.md

Use Taglish/Filipino-friendly explanations when talking to me.
```
