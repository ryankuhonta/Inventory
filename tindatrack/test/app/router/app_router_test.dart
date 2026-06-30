import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tindatrack/app/router/app_router.dart';
import 'package:tindatrack/app/router/app_routes.dart';

void main() {
  test('declares only the four authorized root routes', () {
    expect(
      AppRoute.values.map((route) => (route.name, route.path)),
      [
        ('dashboard', '/dashboard'),
        ('products', '/products'),
        ('history', '/history'),
        ('settings', '/settings'),
      ],
    );
  });

  test('declares Add Product as a secondary Products route', () {
    expect(ProductRoute.addProduct.name, 'addProduct');
    expect(ProductRoute.addProduct.path, '/products/add');
    expect(ProductRoute.addProduct.segment, 'add');
    expect(AppRoute.values, hasLength(4));
  });

  testWidgets('maps Add Product under the Products branch', (tester) async {
    final router = createAppRouter(
      initialLocation: ProductRoute.addProduct.path,
      productsBuilder: (_, _) {
        return const Scaffold(key: Key('products-screen'));
      },
      addProductBuilder: (_, _) {
        return const Scaffold(key: Key('add-product-test-screen'));
      },
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_RouterTestApp(router: router));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add-product-test-screen')), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(
      router.namedLocation(ProductRoute.addProduct.name),
      ProductRoute.addProduct.path,
    );
  });
  testWidgets('maps each direct root location to its matching branch', (
    tester,
  ) async {
    for (final (index, route) in AppRoute.values.indexed) {
      final router = createAppRouter(
        initialLocation: route.path,
        productsBuilder: (_, _) {
          return const Scaffold(key: Key('products-screen'));
        },
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(_RouterTestApp(router: router));
      await tester.pumpAndSettle();

      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        index,
      );
      expect(router.routeInformationProvider.value.uri.path, route.path);
      expect(router.namedLocation(route.name), route.path);
      expect(find.byKey(Key('${route.name}-screen')), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('preserves branch state when switching away and back', (
    tester,
  ) async {
    final router = createAppRouter(
      dashboardBuilder: (_, _) => const _StatefulBranchScreen('Dashboard'),
      productsBuilder: (_, _) => const _StatefulBranchScreen('Products'),
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_RouterTestApp(router: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('Dashboard-increment')));
    await tester.pump();
    expect(find.text('Dashboard count: 1'), findsOneWidget);

    await tester.tap(_navigationLabel('Products'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('Products-increment')));
    await tester.pump();
    expect(find.text('Products count: 1'), findsOneWidget);

    await tester.tap(_navigationLabel('Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard count: 1'), findsOneWidget);
    expect(find.text('Products count: 1'), findsNothing);
  });

  testWidgets('Add Product back navigation returns to Products', (
    tester,
  ) async {
    final router = createAppRouter(
      initialLocation: AppRoute.products.path,
      productsBuilder: (_, _) {
        return const Scaffold(key: Key('products-route-test-screen'));
      },
      addProductBuilder: (_, _) {
        return const Scaffold(key: Key('add-product-route-test-screen'));
      },
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_RouterTestApp(router: router));
    await tester.pumpAndSettle();

    unawaited(router.pushNamed(ProductRoute.addProduct.name));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('add-product-route-test-screen')),
      findsOneWidget,
    );

    router.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('products-route-test-screen')), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/products');
  });
}

Finder _navigationLabel(String label) {
  return find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
}

final class _RouterTestApp extends StatelessWidget {
  const _RouterTestApp({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: router);
  }
}

final class _StatefulBranchScreen extends StatefulWidget {
  const _StatefulBranchScreen(this.label);

  final String label;

  @override
  State<_StatefulBranchScreen> createState() => _StatefulBranchScreenState();
}

final class _StatefulBranchScreenState extends State<_StatefulBranchScreen> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${widget.label} count: $count'),
            FilledButton(
              key: Key('${widget.label}-increment'),
              onPressed: () => setState(() => count++),
              child: const Text('Increment'),
            ),
          ],
        ),
      ),
    );
  }
}
