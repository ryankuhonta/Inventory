import 'dart:async';

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
  testWidgets('row edit preserves the app-session product query', (
    tester,
  ) async {
    final repository = _Repository();
    addTearDown(repository.dispose);
    final router = createAppRouter(
      initialLocation: AppRoute.products.path,
      dashboardBuilder: (_, _) => const Scaffold(),
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
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('product-search-field')),
      'rice',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    final row = find.byKey(const ValueKey('product-row-product-1'));
    await tester.tap(row);
    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(find.text('Edit Product'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('products-screen')), findsOneWidget);

    await tester.tap(row);
    await tester.pumpAndSettle();
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
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('product-search-field')))
          .controller
          ?.text,
      'rice',
    );
    expect(find.text('Updated Rice'), findsOneWidget);
    expect(find.text('Product updated.'), findsOneWidget);
  });
}

final class _Repository implements ProductRepository {
  final _updates = StreamController<List<Product>>.broadcast();
  Product product = _product();

  Future<void> dispose() => _updates.close();

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
    _updates.add(<Product>[product]);
    return Success<Product>(product);
  }

  @override
  Stream<List<Product>> watchActiveProducts(ProductListQuery query) async* {
    yield <Product>[product];
    yield* _updates.stream;
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
