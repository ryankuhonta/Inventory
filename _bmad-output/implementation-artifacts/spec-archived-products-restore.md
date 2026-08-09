---
title: 'Archived Products Restore'
type: 'feature'
created: '2026-08-10'
status: 'done'
baseline_commit: 'dcd6637691673f15cb2f7abbeb7118cbde6a97d2'
context: []
---

<frozen-after-approval reason="human-owned intent - do not modify unless human renegotiates">

## Intent

**Problem:** Archived products are preserved in the database and export, but the app has no user-facing place to review them or bring one back into the active catalog. This leaves archive as a one-way action in practice.

**Approach:** Add an Archived Products screen reachable from Products, list archived products with read-only product details, and allow restoring an archived product with confirmation and friendly feedback. Restored products should reappear in the active Products list with their existing quantity, barcode, history, and metadata intact.

## Boundaries & Constraints

**Always:** Keep archive as soft-delete only; restore must flip `isArchived` back to false and update `updatedAt` in UTC. Preserve stock quantity and inventory history. Use existing Drift repository/use-case/provider patterns, typed `Result` failures, Material 3 UI, 48dp tap targets, and friendly user-facing messages. Archived products must not expose Stock In, Stock Out, or Edit actions while they remain archived.

**Ask First:** Ask before adding import/restore-from-CSV behavior, hard delete, bulk restore, editing archived products, or changing the product table schema.

**Never:** Do not create stock movement rows during restore. Do not bypass repository/use-case boundaries from widgets. Do not show raw database or exception details in the UI. Do not include APK artifact folders in the source commit.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| View archived list | One or more products have `isArchived = true` | Products screen offers an Archived Products entry; archived screen lists archived rows ordered by name with quantity, price, and archived status context | If loading fails, show retryable friendly error |
| Empty archived list | No archived products exist | Archived screen shows an empty state explaining archived products will appear there | N/A |
| Restore archived product | User confirms restore for an archived product | Row flips active, archived list removes it, active Products list can show it again, snackbar says product restored | N/A |
| Restore missing or already active target | Product id is missing or not archived when restore runs | User stays on archived screen and sees a generic retryable failure message | Translate to typed failure; no diagnostics |
| Restore persistence failure | DAO/clock/write failure occurs | Product remains archived and UI unlocks for retry | Show friendly failure only |

</frozen-after-approval>

## Code Map

- `tindatrack/lib/core/database/daos/products_dao.dart` -- existing product persistence boundary with archive and active watch queries; add archived watch and restore write.
- `tindatrack/lib/features/products/domain/repositories/products_repository.dart` -- product feature contract; add restore and archived watch methods.
- `tindatrack/lib/features/products/data/repositories/drift_products_repository.dart` -- translates DAO rows/failures into domain `Result`; mirror archive behavior for restore.
- `tindatrack/lib/features/products/domain/usecases/archive_product.dart` -- pattern for a tiny use-case boundary; add a restore peer.
- `tindatrack/lib/features/products/presentation/providers/product_providers.dart` -- compose use cases and streams; add archived products and restore providers.
- `tindatrack/lib/app/router/app_routes.dart` and `tindatrack/lib/app/router/app_router.dart` -- Products branch route definitions; add archived child route.
- `tindatrack/lib/features/products/presentation/screens/product_list_screen.dart` -- active product root; add clear access to archived products without disrupting search/filter/FAB.
- `tindatrack/lib/features/products/presentation/screens/archived_products_screen.dart` -- new archived list and restore confirmation UI.
- `tindatrack/test/features/products/**` -- existing DAO/repository/screen patterns for archive behavior and navigation.

## Tasks & Acceptance

**Execution:**
- [x] `tindatrack/lib/core/database/daos/products_dao.dart` -- add `watchArchivedProducts()` and `restoreProduct()` -- persistence support without schema changes.
- [x] `tindatrack/lib/features/products/domain/repositories/products_repository.dart`, `.../data/repositories/drift_products_repository.dart`, and new `.../domain/usecases/restore_product.dart` -- expose restore/list behavior through existing domain boundaries.
- [x] `tindatrack/lib/features/products/presentation/providers/product_providers.dart` -- add `archivedProductsProvider` and `restoreProductProvider` -- keep widgets provider-driven.
- [x] `tindatrack/lib/app/router/app_routes.dart` and `tindatrack/lib/app/router/app_router.dart` -- add `ProductRoute.archivedProducts` child route -- preserve Products branch navigation.
- [x] `tindatrack/lib/features/products/presentation/screens/product_list_screen.dart` -- add an app bar or top action to open archived products -- make the feature discoverable.
- [x] `tindatrack/lib/features/products/presentation/screens/archived_products_screen.dart` -- implement list, empty, loading, error, restore confirmation, disabled pending state, and snackbars -- complete user flow.
- [x] Product DAO/repository/provider/screen tests -- cover archived listing, restore success/failures, navigation entry, empty/error states, and active list re-emission.

**Acceptance Criteria:**
- Given an archived product exists, when the user opens Archived Products from Products, then the product appears without edit/stock actions.
- Given the user confirms restore, when restore succeeds, then the product disappears from Archived Products and appears in the active Products list.
- Given restore fails, when the operation completes, then the product remains archived and the user sees a friendly retryable message.
- Given no archived products exist, when the user opens Archived Products, then a clear empty state is shown.

## Verification

**Commands:**
- `flutter test test/features/products test/core/database/daos/products_dao_test.dart` -- product unit/widget flows pass.
- `dart analyze` -- no analyzer issues.
- `flutter build apk --debug` -- Android build succeeds after route/native-free changes.

## Suggested Review Order

**Entry Point**

- Products exposes the archived workflow without disturbing search/filter/FAB.
  [`product_list_screen.dart:58`](../../tindatrack/lib/features/products/presentation/screens/product_list_screen.dart#L58)

- Products branch owns the archived child route with normal nested navigation.
  [`app_router.dart:81`](../../tindatrack/lib/app/router/app_router.dart#L81)

**Restore Flow**

- Archived screen handles list, empty, error, confirmation, and pending restore UI.
  [`archived_products_screen.dart:17`](../../tindatrack/lib/features/products/presentation/screens/archived_products_screen.dart#L17)

- Restore confirmation preserves stock/history and uses friendly user copy.
  [`archived_products_screen.dart:73`](../../tindatrack/lib/features/products/presentation/screens/archived_products_screen.dart#L73)

- Restore result updates visible streams and keeps failures retryable.
  [`archived_products_screen.dart:94`](../../tindatrack/lib/features/products/presentation/screens/archived_products_screen.dart#L94)

**Domain And Persistence**

- DAO restores archived rows without schema changes or stock movement writes.
  [`products_dao.dart:89`](../../tindatrack/lib/core/database/daos/products_dao.dart#L89)

- Repository maps restore success and typed failures through Result boundaries.
  [`drift_products_repository.dart:56`](../../tindatrack/lib/features/products/data/repositories/drift_products_repository.dart#L56)

- Providers expose restore use case and archived stream to UI only.
  [`product_providers.dart:37`](../../tindatrack/lib/features/products/presentation/providers/product_providers.dart#L37)

**Tests**

- DAO/repository tests cover restore persistence and archived stream emission.
  [`drift_products_repository_archive_test.dart:128`](../../tindatrack/test/features/products/data/repositories/drift_products_repository_archive_test.dart#L128)

- Archived screen tests cover empty, restore, failure, pending, and no active actions.
  [`archived_products_screen_test.dart:20`](../../tindatrack/test/features/products/presentation/screens/archived_products_screen_test.dart#L20)

- Product list test covers discoverability from the Products app bar.
  [`product_list_screen_test.dart:112`](../../tindatrack/test/features/products/presentation/screens/product_list_screen_test.dart#L112)