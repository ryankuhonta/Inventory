import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tindatrack/app/router/app_router.dart';
import 'package:tindatrack/app/router/app_routes.dart';
import 'package:tindatrack/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:tindatrack/features/dashboard/presentation/providers/dashboard_providers.dart';

const _forbiddenReleaseRouteTerms = [
  'login',
  'account',
  'cloud',
  'sync',
  'pos',
  'supplier',
  'accounting',
  'profit',
  'barcode',
  'scanner',
  'staff',
  'branch',
  'remote',
  'api',
];

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

  test('release route registry exposes only MVP routes', () {
    final router = createAppRouter();
    addTearDown(router.dispose);

    expect(AppRoute.values, hasLength(4));
    expect(ProductRoute.values, hasLength(4));

    final registeredRoutes = _releaseRoutesFrom(router);

    expect(
      registeredRoutes.map((route) => route.name),
      [
        'dashboard',
        'products',
        'addProduct',
        'editProduct',
        'stockIn',
        'stockOut',
        'history',
        'settings',
      ],
    );
    expect(
      registeredRoutes.map((route) => route.path),
      [
        '/dashboard',
        '/products',
        '/products/add',
        '/products/:productId/edit',
        '/products/:productId/stock-in',
        '/products/:productId/stock-out',
        '/history',
        '/settings',
      ],
    );

    for (final route in registeredRoutes) {
      final routeCopy = '${route.name ?? ''} ${route.path}'.toLowerCase();
      for (final forbidden in _forbiddenReleaseRouteTerms) {
        expect(
          routeCopy,
          isNot(contains(forbidden)),
          reason: 'Release route ${route.name} should not expose $forbidden.',
        );
      }
    }

    for (final route in AppRoute.values) {
      expect(router.namedLocation(route.name), route.path);
    }
    expect(
      router.namedLocation(ProductRoute.addProduct.name),
      ProductRoute.addProduct.path,
    );
    for (final route in [
      ProductRoute.editProduct,
      ProductRoute.stockIn,
      ProductRoute.stockOut,
    ]) {
      expect(
        router.namedLocation(
          route.name,
          pathParameters: const <String, String>{'productId': 'product 1'},
        ),
        route.path.replaceFirst(':productId', 'product%201'),
      );
    }
  });
  test('declares Add Product as a secondary Products route', () {
    expect(ProductRoute.addProduct.name, 'addProduct');
    expect(ProductRoute.addProduct.path, '/products/add');
    expect(ProductRoute.addProduct.segment, 'add');
    expect(AppRoute.values, hasLength(4));
  });

  test('declares Edit Product with a stable ID path parameter', () {
    expect(ProductRoute.editProduct.name, 'editProduct');
    expect(ProductRoute.editProduct.path, '/products/:productId/edit');
    expect(ProductRoute.editProduct.segment, ':productId/edit');
  });

  test('declares Stock In with a stable ID path parameter', () {
    expect(ProductRoute.stockIn.name, 'stockIn');
    expect(ProductRoute.stockIn.path, '/products/:productId/stock-in');
    expect(ProductRoute.stockIn.segment, ':productId/stock-in');
  });

  test('declares Stock Out with a stable ID path parameter', () {
    expect(ProductRoute.stockOut.name, 'stockOut');
    expect(ProductRoute.stockOut.path, '/products/:productId/stock-out');
    expect(ProductRoute.stockOut.segment, ':productId/stock-out');
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
    for (final route in [
      ProductRoute.editProduct,
      ProductRoute.stockIn,
      ProductRoute.stockOut,
    ]) {
      expect(
        router.namedLocation(
          route.name,
          pathParameters: const <String, String>{'productId': 'product 1'},
        ),
        route.path.replaceFirst(':productId', 'product%201'),
      );
    }
  });

  testWidgets('maps Stock In product ID under the Products branch', (
    tester,
  ) async {
    String? receivedId;
    final router = createAppRouter(
      initialLocation: '/products/product-1/stock-in',
      productsBuilder: (_, _) => const Scaffold(key: Key('products-screen')),
      stockInBuilder: (_, state) {
        receivedId = state.pathParameters['productId'];
        return const Scaffold(key: Key('stock-in-test-screen'));
      },
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_RouterTestApp(router: router));
    await tester.pumpAndSettle();

    expect(receivedId, 'product-1');
    expect(find.byKey(const Key('stock-in-test-screen')), findsOneWidget);
    expect(
      router.namedLocation(
        ProductRoute.stockIn.name,
        pathParameters: const <String, String>{'productId': 'product 1'},
      ),
      '/products/product%201/stock-in',
    );
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
  });
  testWidgets('maps Stock Out product ID under the Products branch', (
    tester,
  ) async {
    String? receivedId;
    final router = createAppRouter(
      initialLocation: '/products/product-1/stock-out',
      productsBuilder: (_, _) => const Scaffold(key: Key('products-screen')),
      stockOutBuilder: (_, state) {
        receivedId = state.pathParameters['productId'];
        return const Scaffold(key: Key('stock-out-test-screen'));
      },
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_RouterTestApp(router: router));
    await tester.pumpAndSettle();

    expect(receivedId, 'product-1');
    expect(find.byKey(const Key('stock-out-test-screen')), findsOneWidget);
    expect(
      router.namedLocation(
        ProductRoute.stockOut.name,
        pathParameters: const <String, String>{'productId': 'product 1'},
      ),
      '/products/product%201/stock-out',
    );
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
  });
  testWidgets('maps Edit Product ID under the Products branch', (tester) async {
    String? receivedId;
    final router = createAppRouter(
      initialLocation: '/products/product-1/edit',
      productsBuilder: (_, _) => const Scaffold(key: Key('products-screen')),
      editProductBuilder: (_, state) {
        receivedId = state.pathParameters['productId'];
        return const Scaffold(key: Key('edit-product-test-screen'));
      },
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_RouterTestApp(router: router));
    await tester.pumpAndSettle();

    expect(receivedId, 'product-1');
    expect(find.byKey(const Key('edit-product-test-screen')), findsOneWidget);
    expect(
      router.namedLocation(
        ProductRoute.editProduct.name,
        pathParameters: const <String, String>{'productId': 'product 1'},
      ),
      '/products/product%201/edit',
    );
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
  });

  testWidgets('maps each direct root location to its matching branch', (
    tester,
  ) async {
    for (final (index, route) in AppRoute.values.indexed) {
      final router = _createRootMappingRouter(initialLocation: route.path);
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

  testWidgets('Stock In back navigation returns to Products', (
    tester,
  ) async {
    final router = createAppRouter(
      initialLocation: AppRoute.products.path,
      productsBuilder: (_, _) {
        return const Scaffold(key: Key('products-route-test-screen'));
      },
      stockInBuilder: (_, state) {
        return Scaffold(
          key: const Key('stock-in-route-test-screen'),
          body: Text(state.pathParameters['productId']!),
        );
      },
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_RouterTestApp(router: router));
    await tester.pumpAndSettle();

    unawaited(
      router.pushNamed(
        ProductRoute.stockIn.name,
        pathParameters: const <String, String>{'productId': 'product-1'},
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('stock-in-route-test-screen')),
      findsOneWidget,
    );

    router.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('products-route-test-screen')), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/products');
  });
  testWidgets('Stock Out back navigation returns to Products', (
    tester,
  ) async {
    final router = createAppRouter(
      initialLocation: AppRoute.products.path,
      productsBuilder: (_, _) {
        return const Scaffold(key: Key('products-route-test-screen'));
      },
      stockOutBuilder: (_, state) {
        return Scaffold(
          key: const Key('stock-out-route-test-screen'),
          body: Text(state.pathParameters['productId']!),
        );
      },
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_RouterTestApp(router: router));
    await tester.pumpAndSettle();

    unawaited(
      router.pushNamed(
        ProductRoute.stockOut.name,
        pathParameters: const <String, String>{'productId': 'product-1'},
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('stock-out-route-test-screen')),
      findsOneWidget,
    );

    router.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('products-route-test-screen')), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/products');
  });
  testWidgets('Edit Product back navigation returns to Products', (
    tester,
  ) async {
    final router = createAppRouter(
      initialLocation: AppRoute.products.path,
      productsBuilder: (_, _) {
        return const Scaffold(key: Key('products-route-test-screen'));
      },
      editProductBuilder: (_, state) {
        return Scaffold(
          key: const Key('edit-product-route-test-screen'),
          body: Text(state.pathParameters['productId']!),
        );
      },
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_RouterTestApp(router: router));
    await tester.pumpAndSettle();

    unawaited(
      router.pushNamed(
        ProductRoute.editProduct.name,
        pathParameters: const <String, String>{'productId': 'product-1'},
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('edit-product-route-test-screen')),
      findsOneWidget,
    );

    router.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('products-route-test-screen')), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/products');
  });
}

GoRouter _createRootMappingRouter({required String initialLocation}) {
  return createAppRouter(
    initialLocation: initialLocation,
    dashboardBuilder: (_, _) {
      return const Scaffold(key: Key('dashboard-screen'));
    },
    productsBuilder: (_, _) {
      return const Scaffold(key: Key('products-screen'));
    },
    historyBuilder: (_, _) {
      return const Scaffold(key: Key('history-screen'));
    },
    settingsBuilder: (_, _) {
      return const Scaffold(key: Key('settings-screen'));
    },
  );
}

Finder _navigationLabel(String label) {
  return find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
}

typedef _ReleaseRouteRecord = ({String? name, String path});

List<_ReleaseRouteRecord> _releaseRoutesFrom(GoRouter router) {
  final records = <_ReleaseRouteRecord>[];
  _collectReleaseRoutes(router.configuration.routes, records);
  return records;
}

void _collectReleaseRoutes(
  List<RouteBase> routes,
  List<_ReleaseRouteRecord> records, [
  String parentPath = '',
]) {
  for (final route in routes) {
    if (route is GoRoute) {
      final path = _joinRoutePath(parentPath, route.path);
      records.add((name: route.name, path: path));
      _collectReleaseRoutes(route.routes, records, path);
    } else if (route is StatefulShellRoute) {
      for (final branch in route.branches) {
        _collectReleaseRoutes(branch.routes, records, parentPath);
      }
    }
  }
}

String _joinRoutePath(String parentPath, String routePath) {
  if (routePath.startsWith('/')) {
    return routePath;
  }
  if (parentPath.isEmpty || parentPath == '/') {
    return '/$routePath';
  }
  return '$parentPath/$routePath';
}

final class _RouterTestApp extends StatelessWidget {
  const _RouterTestApp({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        dashboardSummaryProvider.overrideWith((ref) {
          return Stream.value(
            const DashboardSummary(
              totalActiveProducts: 1,
              lowStockProducts: 0,
              stockChangesToday: 0,
            ),
          );
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
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
