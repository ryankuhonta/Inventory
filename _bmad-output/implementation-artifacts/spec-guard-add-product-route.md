---
title: 'Guard Add Product Route'
type: 'bugfix'
created: '2026-08-03'
status: 'done'
route: 'one-shot'
---

# Guard Add Product Route

## Intent

**Problem:** Rapid repeated taps on the Products screen Add Product actions could enqueue duplicate Add Product routes, forcing the user to back out multiple times.

**Approach:** Add a local navigation-in-flight guard in `ProductListScreen` that is set before opening Add Product and reset after navigation completes or fails. Cover both the floating action button and the empty-state action with focused regression tests.

## Suggested Review Order

- [`../../tindatrack/lib/features/products/presentation/screens/product_list_screen.dart`](../../tindatrack/lib/features/products/presentation/screens/product_list_screen.dart) -- Check the Add Product route guard and reset behavior.
- [`../../tindatrack/test/features/products/presentation/screens/product_list_screen_test.dart`](../../tindatrack/test/features/products/presentation/screens/product_list_screen_test.dart) -- Confirm rapid FAB and empty-state action taps only create one route.
- [`deferred-work.md`](deferred-work.md) -- Confirm closed deferred items no longer appear as active work.