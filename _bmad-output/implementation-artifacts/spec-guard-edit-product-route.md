---
title: 'Guard Edit Product Route Opening'
type: 'bugfix'
created: '2026-08-05'
status: 'done'
route: 'one-shot'
---

# Guard Edit Product Route Opening

## Intent

**Problem:** Rapid repeated Edit taps could start more than one Edit Product navigation, and a thrown route push could leave the row navigation guard stuck.

**Approach:** Add a route-wide in-flight guard around product row route pushes, clear it in `finally`, and cover both cross-row rapid Edit taps and route failure recovery.

## Suggested Review Order

**Navigation Guard**

- Start with the route-wide in-flight guard and `finally` reset behavior.
  [`product_list_screen.dart:265`](../../tindatrack/lib/features/products/presentation/screens/product_list_screen.dart#L265)

- Confirm the guard wraps `pushNamed` before any route can stack.
  [`product_list_screen.dart:305`](../../tindatrack/lib/features/products/presentation/screens/product_list_screen.dart#L305)

**Regression Coverage**

- Verify cross-row rapid Edit taps settle on one edit route.
  [`product_list_screen_test.dart:179`](../../tindatrack/test/features/products/presentation/screens/product_list_screen_test.dart#L179)

- Verify navigation failure allows a later Edit attempt.
  [`product_list_screen_test.dart:206`](../../tindatrack/test/features/products/presentation/screens/product_list_screen_test.dart#L206)

- Check the test router can intentionally omit the Edit route.
  [`product_list_screen_test.dart:455`](../../tindatrack/test/features/products/presentation/screens/product_list_screen_test.dart#L455)

**Tracking**

- Confirm the deferred navigation item is closed, not still active.
  [`deferred-work.md:26`](deferred-work.md#L26)
