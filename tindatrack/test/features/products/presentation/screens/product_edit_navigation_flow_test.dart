import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
            routerConfig: router,
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
}

final class _Repository implements ProductRepository {
  Product product = _product();

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
    return Success<Product>(product);
  }

  @override
  Stream<List<Product>> watchActiveProducts(ProductListQuery query) {
    return Stream.value(<Product>[product]);
  }
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
