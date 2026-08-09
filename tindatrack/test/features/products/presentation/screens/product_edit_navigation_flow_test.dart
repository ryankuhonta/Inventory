import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/app/navigation/app_back_button_dispatcher.dart';
import 'package:tindatrack/app/router/app_router.dart';
import 'package:tindatrack/app/router/app_routes.dart';
import 'package:tindatrack/app/theme/app_theme.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/domain/entities/create_product_input.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/entities/product_list_query.dart';
import 'package:tindatrack/features/products/domain/entities/update_product_input.dart';
import 'package:tindatrack/features/products/domain/repositories/products_repository.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';

void main() {
  testWidgets(
    'explicit Edit action opens the real route with product identity',
    (
      tester,
    ) async {
      final repository = _Repository();
      addTearDown(repository.dispose);
      String? openedProductId;
      String? openedRoutePath;
      final router = createAppRouter(
        initialLocation: AppRoute.products.path,
        dashboardBuilder: (_, _) => const Scaffold(),
        historyBuilder: (_, _) => const Scaffold(),
        settingsBuilder: (_, _) => const Scaffold(),
        editProductBuilder: (_, state) {
          openedProductId = state.pathParameters['productId'];
          openedRoutePath = state.uri.path;
          return Scaffold(
            key: const Key('edit-product-test-screen'),
            appBar: AppBar(title: const Text('Edit Product')),
          );
        },
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routeInformationProvider: router.routeInformationProvider,
            routeInformationParser: router.routeInformationParser,
            routerDelegate: router.routerDelegate,
            backButtonDispatcher: AppBackButtonDispatcher(
              router: router,
              navigatorKey: appRootNavigatorKey,
              productsNavigatorKey: appProductsNavigatorKey,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(
        find.byKey(const Key('product-search-field')),
        'rice',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));

      const actionKey = ValueKey('product-edit-action-product-1');
      final action = find.byKey(actionKey);
      expect(action, findsOneWidget);

      await tester.tap(action);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('edit-product-test-screen')), findsOneWidget);
      expect(find.text('Edit Product'), findsOneWidget);
      expect(openedProductId, 'product-1');
      expect(
        openedRoutePath,
        '/products/product-1/edit',
      );

      router.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('products-screen')), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('product-search-field')))
            .controller
            ?.text,
        'rice',
      );
      expect(find.byKey(actionKey), findsOneWidget);
    },
  );

  testWidgets(
    'hardware back from barcode edit asks before leaving product child route',
    (tester) async {
      final repository = _Repository();
      addTearDown(repository.dispose);
      final router = createAppRouter(
        initialLocation: AppRoute.products.path,
        dashboardBuilder: (_, _) => const Scaffold(
          key: Key('dashboard-test-screen'),
        ),
        historyBuilder: (_, _) => const Scaffold(),
        settingsBuilder: (_, _) => const Scaffold(),
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routeInformationProvider: router.routeInformationProvider,
            routeInformationParser: router.routeInformationParser,
            routerDelegate: router.routerDelegate,
            backButtonDispatcher: AppBackButtonDispatcher(
              router: router,
              navigatorKey: appRootNavigatorKey,
              productsNavigatorKey: appProductsNavigatorKey,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      router.goNamed(
        ProductRoute.editProduct.name,
        pathParameters: <String, String>{'productId': 'product-1'},
      );
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/products/product-1/edit',
      );
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/products/product-1/edit',
      );
      await tester.enterText(
        find.byKey(const Key('edit-barcode-field')),
        '4801234567890',
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(
        router.routeInformationProvider.value.uri.path,
        '/products/product-1/edit',
      );
      expect(find.text('Discard changes?'), findsOneWidget);
      expect(find.byKey(const Key('dashboard-test-screen')), findsNothing);

      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();

      expect(
        router.routeInformationProvider.value.uri.path,
        '/products/product-1/edit',
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('edit-barcode-field')))
            .controller
            ?.text,
        '4801234567890',
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/products');
      expect(find.byKey(const Key('products-screen')), findsOneWidget);
    },
  );
  testWidgets(
    'successful edit returns with row actions enabled '
    'and root back policy intact',
    (tester) async {
      final repository = _Repository();
      addTearDown(repository.dispose);
      final router = createAppRouter(
        initialLocation: AppRoute.products.path,
        dashboardBuilder: (_, _) => const Scaffold(
          key: Key('dashboard-test-screen'),
        ),
        historyBuilder: (_, _) => const Scaffold(),
        settingsBuilder: (_, _) => const Scaffold(),
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routeInformationProvider: router.routeInformationProvider,
            routeInformationParser: router.routeInformationParser,
            routerDelegate: router.routerDelegate,
            backButtonDispatcher: AppBackButtonDispatcher(
              router: router,
              navigatorKey: appRootNavigatorKey,
              productsNavigatorKey: appProductsNavigatorKey,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      const editActionKey = ValueKey('product-edit-action-product-1');
      await tester.tap(find.byKey(editActionKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(
        find.byKey(const Key('edit-product-name-field')),
        'Updated Rice',
      );
      await tester.ensureVisible(
        find.byKey(const Key('save-product-changes-button')),
      );
      await tester.tap(find.byKey(const Key('save-product-changes-button')));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/products');
      expect(find.byKey(const Key('products-screen')), findsOneWidget);
      expect(find.text('Product updated.'), findsOneWidget);
      expect(_rowAction(tester, editActionKey).onPressed, isNotNull);
      expect(
        _rowAction(
          tester,
          const ValueKey('product-stock-in-action-product-1'),
        ).onPressed,
        isNotNull,
      );
      expect(
        _rowAction(
          tester,
          const ValueKey('product-stock-out-action-product-1'),
        ).onPressed,
        isNotNull,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/dashboard');
      expect(find.byKey(const Key('dashboard-test-screen')), findsOneWidget);
    },
  );
}

final class _Repository implements ProductRepository {
  Product product = _product();
  final _products = StreamController<List<Product>>.broadcast();

  void dispose() {
    unawaited(_products.close());
  }

  @override
  Future<Result<void>> archiveProduct(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<Product>> createProduct(CreateProductInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Product>> getProduct(String id) async {
    return Success<Product>(product);
  }

  @override
  Future<Result<Product>> updateProduct(
    String id,
    UpdateProductInput input,
  ) async {
    product = _product(name: input.name);
    _products.add(<Product>[product]);
    return Success<Product>(product);
  }

  @override
  Stream<List<Product>> watchActiveProducts(ProductListQuery query) async* {
    yield <Product>[product];
    yield* _products.stream;
  }

  @override
  Future<Result<void>> restoreProduct(String id) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Product>> watchArchivedProducts() {
    throw UnimplementedError();
  }
}

IconButton _rowAction(WidgetTester tester, ValueKey<String> key) {
  return tester.widget<IconButton>(
    find.descendant(
      of: find.byKey(key),
      matching: find.byType(IconButton),
    ),
  );
}

Product _product({String name = 'Rice'}) {
  return Product(
    id: 'product-1',
    name: name,
    category: null,
    unit: 'pcs',
    sellingPrice: 50,
    quantity: 8,
    lowStockThreshold: 2,
    barcode: null,
    isArchived: false,
    createdAt: DateTime.utc(2026, 7),
    updatedAt: DateTime.utc(2026, 7),
  );
}
