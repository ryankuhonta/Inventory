import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tindatrack/app/router/app_routes.dart';
import 'package:tindatrack/app/theme/app_theme.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/domain/entities/create_product_input.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/entities/product_list_query.dart';
import 'package:tindatrack/features/products/domain/entities/update_product_input.dart';
import 'package:tindatrack/features/products/domain/repositories/products_repository.dart';
import 'package:tindatrack/features/products/domain/usecases/restore_product.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';
import 'package:tindatrack/features/products/presentation/screens/archived_products_screen.dart';

void main() {
  testWidgets('empty archived list explains where archived products appear', (
    tester,
  ) async {
    await _pumpArchived(
      tester,
      archivedProducts: Stream.value(const <Product>[]),
    );

    expect(
      find.byKey(const Key('archived-products-empty-state')),
      findsOneWidget,
    );
    expect(find.text('No archived products'), findsOneWidget);
    expect(
      find.text('Archived products will appear here after you archive them.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'archived rows render restore actions without active row actions',
    (
      tester,
    ) async {
      await _pumpArchived(
        tester,
        archivedProducts: Stream.value([_product('1', 'Old Rice')]),
      );

      expect(find.byKey(const Key('archived-products-list')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('archived-product-row-1')),
        findsOneWidget,
      );
      expect(find.text('Old Rice'), findsOneWidget);
      expect(find.text('Archived'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('restore-product-action-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('product-stock-in-action-1')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('product-stock-out-action-1')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('product-edit-action-1')), findsNothing);
    },
  );

  testWidgets('confirmed restore delegates and shows success feedback', (
    tester,
  ) async {
    final restore = _RestoreRepository();
    await _pumpArchived(
      tester,
      archivedProducts: Stream.value([_product('1', 'Old Rice')]),
      restore: restore,
    );

    await tester.tap(find.byKey(const ValueKey('restore-product-action-1')));
    await tester.pumpAndSettle();
    expect(find.text('Restore product?'), findsOneWidget);
    expect(find.textContaining('Restore Old Rice'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-restore-product-button')));
    await tester.pumpAndSettle();

    expect(restore.calls, ['1']);
    expect(find.text('Product restored.'), findsOneWidget);
  });

  testWidgets('restore failure stays recoverable without diagnostics', (
    tester,
  ) async {
    final restore = _RestoreRepository(
      result: const FailureResult<void>(
        PersistenceFailure(debugMessage: 'RAW_SQLITE_PRIVATE'),
      ),
    );
    await _pumpArchived(
      tester,
      archivedProducts: Stream.value([_product('1', 'Old Rice')]),
      restore: restore,
    );

    await tester.tap(find.byKey(const ValueKey('restore-product-action-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-restore-product-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('archived-products-screen')), findsOneWidget);
    expect(
      find.text("We couldn't restore this product. Please try again."),
      findsOneWidget,
    );
    expect(find.textContaining('RAW_SQLITE_PRIVATE'), findsNothing);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('restore-product-action-1')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('pending restore disables restore actions', (tester) async {
    final pending = Completer<Result<void>>();
    final restore = _RestoreRepository(onCall: (_) => pending.future);
    await _pumpArchived(
      tester,
      archivedProducts: Stream.value([
        _product('1', 'Old Rice'),
        _product('2', 'Old Soap'),
      ]),
      restore: restore,
    );

    await tester.tap(find.byKey(const ValueKey('restore-product-action-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-restore-product-button')));
    await tester.pump();

    expect(find.text('Restoring...'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('restore-product-action-1')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('restore-product-action-2')),
          )
          .onPressed,
      isNull,
    );

    pending.complete(const Success<void>(null));
    await tester.pumpAndSettle();
  });
}

Future<void> _pumpArchived(
  WidgetTester tester, {
  required Stream<List<Product>> archivedProducts,
  _RestoreRepository? restore,
}) async {
  final router = GoRouter(
    initialLocation: ProductRoute.archivedProducts.path,
    routes: [
      GoRoute(
        path: AppRoute.products.path,
        name: AppRoute.products.name,
        builder: (_, _) => const Scaffold(key: Key('products-test-screen')),
        routes: [
          GoRoute(
            path: ProductRoute.archivedProducts.segment,
            name: ProductRoute.archivedProducts.name,
            builder: (_, _) => const ArchivedProductsScreen(),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        archivedProductsProvider.overrideWith((ref) => archivedProducts),
        restoreProductProvider.overrideWithValue(
          RestoreProduct(restore ?? _RestoreRepository()),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pump();
}

Product _product(String id, String name) {
  return Product(
    id: id,
    name: name,
    category: 'Staples',
    unit: 'pcs',
    sellingPrice: 10,
    quantity: 4,
    lowStockThreshold: 2,
    barcode: null,
    isArchived: true,
    createdAt: DateTime.utc(2026, 6, 30),
    updatedAt: DateTime.utc(2026, 6, 30),
  );
}

final class _RestoreRepository implements ProductRepository {
  _RestoreRepository({
    this.result = const Success<void>(null),
    this.onCall,
  });

  final Result<void> result;
  final Future<Result<void>> Function(String id)? onCall;
  final List<String> calls = [];

  @override
  Future<Result<void>> restoreProduct(String id) async {
    calls.add(id);
    return onCall == null ? result : onCall!(id);
  }

  @override
  Future<Result<void>> archiveProduct(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Product>> createProduct(CreateProductInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Product>> getProduct(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Product>> updateProduct(String id, UpdateProductInput input) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Product>> watchActiveProducts(ProductListQuery query) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Product>> watchArchivedProducts() {
    throw UnimplementedError();
  }
}
