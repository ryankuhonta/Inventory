import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tindatrack/app/router/app_routes.dart';
import 'package:tindatrack/app/theme/app_theme.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';
import 'package:tindatrack/features/products/presentation/screens/product_list_screen.dart';
import 'package:tindatrack/features/products/presentation/widgets/product_list_item.dart';

void main() {
  testWidgets('shows a lightweight accessible loading state', (tester) async {
    final stream = StreamController<List<Product>>.broadcast();
    addTearDown(stream.close);
    await _pumpProducts(tester, () => stream.stream);

    expect(find.byKey(const Key('products-loading-state')), findsOneWidget);
    expect(find.bySemanticsLabel('Loading products'), findsOneWidget);
    expect(find.byKey(const Key('add-product-action')), findsOneWidget);
  });

  testWidgets('empty state and FAB both open Add Product', (tester) async {
    await _pumpProducts(tester, () => Stream.value(const <Product>[]));

    expect(find.text('No products yet'), findsOneWidget);
    expect(
      find.text('Add your first product to start tracking stock.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Add Product'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('add-product-test-screen')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-product-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('add-product-test-screen')), findsOneWidget);
  });

  testWidgets('Add Product reopens after save returns with goNamed products', (
    tester,
  ) async {
    var openings = 0;
    await _pumpProducts(
      tester,
      () => Stream.value(const <Product>[]),
      addProductBuilder: (context, _) {
        openings++;
        return Scaffold(
          key: const Key('add-product-test-screen'),
          appBar: AppBar(title: const Text('Add Product')),
          body: FilledButton(
            key: const Key('save-product-test-action'),
            onPressed: () => context.goNamed(AppRoute.products.name),
            child: const Text('Save'),
          ),
        );
      },
    );

    await tester.tap(find.byKey(const Key('add-product-action')));
    await tester.pumpAndSettle();
    expect(openings, 1);
    expect(find.byKey(const Key('add-product-test-screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('save-product-test-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('add-product-test-screen')), findsNothing);

    await tester.tap(find.byKey(const Key('add-product-action')));
    await tester.pumpAndSettle();

    expect(openings, 2);
    expect(find.byKey(const Key('add-product-test-screen')), findsOneWidget);
  });

  testWidgets('rapid FAB taps open one Add Product route', (tester) async {
    await _pumpProducts(tester, () => Stream.value(const <Product>[]));

    await tester.tap(find.byKey(const Key('add-product-action')));
    await tester.tap(find.byKey(const Key('add-product-action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add-product-test-screen')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('No products yet'), findsOneWidget);
    expect(find.byKey(const Key('add-product-test-screen')), findsNothing);
  });

  testWidgets('rapid empty-state action taps open one Add Product route', (
    tester,
  ) async {
    await _pumpProducts(tester, () => Stream.value(const <Product>[]));

    final action = find.widgetWithText(FilledButton, 'Add Product');
    await tester.tap(action);
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add-product-test-screen')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('No products yet'), findsOneWidget);
    expect(find.byKey(const Key('add-product-test-screen')), findsNothing);
  });
  testWidgets('safe error state retries without exposing diagnostics', (
    tester,
  ) async {
    var attempts = 0;
    await _pumpProducts(tester, () {
      attempts++;
      if (attempts == 1) {
        return Stream<List<Product>>.error(
          StateError('RAW_SQLITE_STREAM_ERROR'),
        );
      }
      return Stream.value(const <Product>[]);
    });

    expect(find.text('Products unavailable'), findsOneWidget);
    expect(
      find.text("We couldn't load your products. Please try again."),
      findsOneWidget,
    );
    expect(find.textContaining('RAW_SQLITE_STREAM_ERROR'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text('No products yet'), findsOneWidget);
  });

  testWidgets('populated state renders builder-backed read-only rows', (
    tester,
  ) async {
    await _pumpProducts(
      tester,
      () => Stream.value([
        _product('1', 'Rice', category: 'Staples', quantity: 4),
        _product('2', 'Soap', quantity: 9),
      ]),
    );
    await tester.pump();

    expect(find.byKey(const Key('products-list')), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byKey(const ValueKey('product-row-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('product-row-2')), findsOneWidget);
    expect(find.text('Rice'), findsOneWidget);
    expect(find.text('Staples'), findsOneWidget);
    expect(find.text('4 pcs'), findsOneWidget);
    expect(find.text('Soap'), findsOneWidget);
    expect(find.text('9 pcs'), findsOneWidget);
  });

  testWidgets('screen rebuilds when the product stream emits an update', (
    tester,
  ) async {
    final stream = StreamController<List<Product>>.broadcast();
    addTearDown(stream.close);
    await _pumpProducts(tester, () => stream.stream);

    stream.add(const <Product>[]);
    await tester.pump();
    expect(find.text('No products yet'), findsOneWidget);

    stream.add([_product('1', 'Rice', quantity: 4)]);
    await tester.pump();

    expect(find.byKey(const ValueKey('product-row-1')), findsOneWidget);
    expect(find.text('Rice'), findsOneWidget);
  });

  testWidgets(
    'row Stock In and Stock Out open existing flows with product id',
    (
      tester,
    ) async {
      await _pumpProducts(
        tester,
        () => Stream.value([
          _product('1', 'Rice', quantity: 4),
          _product('2', 'Soap'),
        ]),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('product-stock-in-action-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('stock-in-test-screen')), findsOneWidget);
      expect(find.text('Stock In product 1'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('product-stock-out-action-2')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('stock-out-test-screen')), findsOneWidget);
      expect(find.text('Stock Out product 2'), findsOneWidget);
    },
  );

  testWidgets('rapid Edit taps across rows open one Edit Product route', (
    tester,
  ) async {
    await _pumpProducts(
      tester,
      () => Stream.value([
        _product('1', 'Rice', quantity: 4),
        _product('2', 'Soap', quantity: 9),
      ]),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('product-edit-action-1')));
    await tester.tap(find.byKey(const ValueKey('product-edit-action-2')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edit-product-test-screen')), findsOneWidget);
    expect(find.text('Edit product 1'), findsOneWidget);
    expect(find.text('Edit product 2'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('products-list')), findsOneWidget);
    expect(find.byKey(const Key('edit-product-test-screen')), findsNothing);
  });

  testWidgets('Edit route failure clears the in-flight guard', (tester) async {
    await _pumpProducts(
      tester,
      () => Stream.value([_product('1', 'Rice', quantity: 4)]),
      includeEditRoute: false,
    );
    await tester.pump();

    final action = find.byKey(const ValueKey('product-edit-action-1'));

    Future<Object?> collectFailure() async {
      Object? failure;
      await runZonedGuarded(
        () async {
          await tester.tap(action);
          await tester.pump();
        },
        (error, _) {
          failure = error;
        },
      );
      return failure;
    }

    expect(await collectFailure(), isAssertionError);
    expect(await collectFailure(), isAssertionError);
  });

  testWidgets('active list exposes no row actions for archived products', (
    tester,
  ) async {
    final storedProducts = [
      _product('1', 'Active Rice', quantity: 4),
      _product('archived', 'Archived Rice', isArchived: true),
    ];

    await _pumpProducts(
      tester,
      () => Stream.value(
        storedProducts.where((product) => !product.isArchived).toList(),
      ),
    );
    await tester.pump();

    expect(storedProducts.any((product) => product.isArchived), isTrue);
    expect(find.text('Active Rice'), findsOneWidget);
    expect(find.text('Archived Rice'), findsNothing);
    expect(
      find.byKey(const ValueKey('product-stock-in-action-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('product-stock-out-action-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('product-stock-in-action-archived')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('product-stock-out-action-archived')),
      findsNothing,
    );
  });
  testWidgets('mixed rows show independent mutually exclusive statuses', (
    tester,
  ) async {
    await _pumpProducts(
      tester,
      () => Stream.value([
        _product('1', 'Rice', quantity: 5, threshold: 2),
        _product('2', 'Soap', quantity: 2, threshold: 2),
        _product('3', 'Soda', threshold: 5),
      ]),
    );
    await tester.pump();

    final rice = find.byKey(const ValueKey('product-row-1'));
    final soap = find.byKey(const ValueKey('product-row-2'));
    final soda = find.byKey(const ValueKey('product-row-3'));
    expect(
      find.descendant(of: rice, matching: find.text('Low Stock')),
      findsNothing,
    );
    expect(
      find.descendant(of: rice, matching: find.text('Out of Stock')),
      findsNothing,
    );
    expect(
      find.descendant(of: soap, matching: find.text('Low Stock')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: soap, matching: find.text('Out of Stock')),
      findsNothing,
    );
    expect(
      find.descendant(of: soda, matching: find.text('Out of Stock')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: soda, matching: find.text('Low Stock')),
      findsNothing,
    );
  });

  testWidgets('current stream data updates status without restart', (
    tester,
  ) async {
    final stream = StreamController<List<Product>>.broadcast();
    addTearDown(stream.close);
    await _pumpProducts(tester, () => stream.stream);

    stream.add([_product('1', 'Rice', quantity: 4, threshold: 2)]);
    await tester.pump();
    var row = find.byKey(const ValueKey('product-row-1'));
    expect(
      find.descendant(of: row, matching: find.text('Low Stock')),
      findsNothing,
    );
    expect(
      find.descendant(of: row, matching: find.text('Out of Stock')),
      findsNothing,
    );

    stream.add([_product('1', 'Rice', quantity: 2, threshold: 2)]);
    await tester.pump();
    row = find.byKey(const ValueKey('product-row-1'));
    expect(
      find.descendant(of: row, matching: find.text('Low Stock')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Rice, 2 pcs, Price: \u20B110.00, Low Stock'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Edit Rice'), findsOneWidget);

    stream.add([_product('1', 'Rice', threshold: 2)]);
    await tester.pump();
    await tester.pump();
    row = find.byKey(const ValueKey('product-row-1'));
    expect(
      find.descendant(of: row, matching: find.text('Low Stock')),
      findsNothing,
    );
    expect(
      find.descendant(of: row, matching: find.text('Out of Stock')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Rice, 0 pcs, Price: \u20B110.00, Out of Stock'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Edit Rice'), findsOneWidget);
  });

  testWidgets('3,000 products are built lazily and later rows can appear', (
    tester,
  ) async {
    final products = List<Product>.generate(
      3000,
      (index) => _product('$index', 'Product $index', quantity: index),
      growable: false,
    );
    await _pumpProducts(tester, () => Stream.value(products));
    await tester.pump();

    expect(find.byType(ProductListItem).evaluate().length, lessThan(3000));
    expect(find.byKey(const ValueKey('product-row-2999')), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('product-row-50')),
      500,
      scrollable: find.descendant(
        of: find.byKey(const Key('products-list')),
        matching: find.byType(Scrollable),
      ),
    );

    expect(find.byKey(const ValueKey('product-row-50')), findsOneWidget);
  });

  testWidgets('fits a small phone with enlarged text and accessible labels', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pumpProducts(
      tester,
      () => Stream.value([
        _product(
          '1',
          'A readable product with a longer name',
          category: 'Staples',
          quantity: 4,
        ),
      ]),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.bySemanticsLabel(
        'A readable product with a longer name, Staples, 4 pcs, '
        'Price: \u20B110.00',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Stock In A readable product with a longer name'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Stock Out A readable product with a longer name'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Edit A readable product with a longer name'),
      findsOneWidget,
    );

    for (final key in [
      const ValueKey('product-stock-in-action-1'),
      const ValueKey('product-stock-out-action-1'),
      const ValueKey('product-edit-action-1'),
    ]) {
      final action = find.byKey(key);
      expect(action, findsOneWidget);
      final actionSize = tester.getSize(action);
      expect(actionSize.width, greaterThanOrEqualTo(48));
      expect(actionSize.height, greaterThanOrEqualTo(48));
      final actionRect = tester.getRect(action);
      expect(actionRect.left, greaterThanOrEqualTo(0));
      expect(actionRect.right, lessThanOrEqualTo(360));
      await tester.tap(action);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
    expect(
      find.bySemanticsLabel(
        'A readable product with a longer name, Staples, 4 pcs, '
        'Price: \u20B110.00',
      ),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const Key('add-product-action'))).height,
      greaterThanOrEqualTo(48),
    );
    final semantics = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });
}

Future<void> _pumpProducts(
  WidgetTester tester,
  Stream<List<Product>> Function() products, {
  bool includeEditRoute = true,
  Widget Function(BuildContext, GoRouterState)? addProductBuilder,
}) async {
  final router = GoRouter(
    initialLocation: AppRoute.products.path,
    routes: [
      GoRoute(
        path: AppRoute.products.path,
        name: AppRoute.products.name,
        builder: (_, _) => const ProductListScreen(),
        routes: [
          GoRoute(
            path: ProductRoute.addProduct.segment,
            name: ProductRoute.addProduct.name,
            builder:
                addProductBuilder ??
                (_, _) {
                  return Scaffold(
                    key: const Key('add-product-test-screen'),
                    appBar: AppBar(title: const Text('Add Product')),
                  );
                },
          ),
          if (includeEditRoute)
            GoRoute(
              path: ProductRoute.editProduct.segment,
              name: ProductRoute.editProduct.name,
              builder: (_, state) {
                final productId = state.pathParameters['productId']!;
                return Scaffold(
                  key: const Key('edit-product-test-screen'),
                  appBar: AppBar(title: const Text('Edit Product')),
                  body: Text('Edit product $productId'),
                );
              },
            ),
          GoRoute(
            path: ProductRoute.stockIn.segment,
            name: ProductRoute.stockIn.name,
            builder: (_, state) {
              final productId = state.pathParameters['productId']!;
              return Scaffold(
                key: const Key('stock-in-test-screen'),
                appBar: AppBar(title: const Text('Stock In')),
                body: Text('Stock In product $productId'),
              );
            },
          ),
          GoRoute(
            path: ProductRoute.stockOut.segment,
            name: ProductRoute.stockOut.name,
            builder: (_, state) {
              final productId = state.pathParameters['productId']!;
              return Scaffold(
                key: const Key('stock-out-test-screen'),
                appBar: AppBar(title: const Text('Stock Out')),
                body: Text('Stock Out product $productId'),
              );
            },
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeProductsProvider.overrideWith((ref) => products()),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
}

Product _product(
  String id,
  String name, {
  String? category,
  int quantity = 0,
  int threshold = 0,
  bool isArchived = false,
}) {
  return Product(
    id: id,
    name: name,
    category: category,
    unit: 'pcs',
    sellingPrice: 10,
    quantity: quantity,
    lowStockThreshold: threshold,
    barcode: null,
    isArchived: isArchived,
    createdAt: DateTime.utc(2026, 6, 30),
    updatedAt: DateTime.utc(2026, 6, 30),
  );
}
