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
import 'package:tindatrack/features/products/domain/failures/product_failure.dart';
import 'package:tindatrack/features/products/domain/repositories/products_repository.dart';
import 'package:tindatrack/features/products/domain/usecases/get_product.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';
import 'package:tindatrack/features/stock/domain/entities/create_stock_movement_input.dart';
import 'package:tindatrack/features/stock/domain/entities/record_stock_in_input.dart';
import 'package:tindatrack/features/stock/domain/entities/record_stock_out_input.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';
import 'package:tindatrack/features/stock/domain/repositories/stock_repository.dart';
import 'package:tindatrack/features/stock/presentation/providers/stock_providers.dart';
import 'package:tindatrack/features/stock/presentation/screens/stock_in_screen.dart';

void main() {
  testWidgets('shows product details and stock-in fields', (tester) async {
    await _pumpStockIn(tester, productRepository: _ProductRepository());

    expect(find.text('Stock In'), findsOneWidget);
    expect(find.text('Rice'), findsOneWidget);
    expect(find.text('Current quantity: 5 pcs'), findsOneWidget);
    expect(find.byKey(const Key('stock-in-quantity-field')), findsOneWidget);
    expect(find.byKey(const Key('stock-in-note-field')), findsOneWidget);
    expect(find.text('Record Stock In'), findsOneWidget);
    final quantityField = find.byKey(const Key('stock-in-quantity-field'));
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: quantityField,
              matching: find.byType(EditableText),
            ),
          )
          .keyboardType,
      TextInputType.number,
    );
  });

  testWidgets('invalid quantity shows inline validation and does not save', (
    tester,
  ) async {
    final stockRepository = _StockRepository();
    await _pumpStockIn(
      tester,
      productRepository: _ProductRepository(),
      stockRepository: stockRepository,
    );

    await tester.enterText(
      find.byKey(const Key('stock-in-quantity-field')),
      '0',
    );
    await tester.tap(find.byKey(const Key('record-stock-in-button')));
    await tester.pumpAndSettle();

    expect(stockRepository.stockInCalls, 0);
    expect(find.text('Enter a quantity greater than 0.'), findsOneWidget);
  });

  testWidgets(
    'pending save disables duplicate submission and back navigation',
    (tester) async {
      final pending = Completer<Result<StockMovement>>();
      final stockRepository = _StockRepository(
        onStockIn: (_) => pending.future,
      );
      await _pumpStockIn(
        tester,
        productRepository: _ProductRepository(),
        stockRepository: stockRepository,
      );

      await tester.enterText(
        find.byKey(const Key('stock-in-quantity-field')),
        '3',
      );
      await tester.tap(find.byKey(const Key('record-stock-in-button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('record-stock-in-button')));
      await tester.pageBack();
      await tester.pump();

      expect(stockRepository.stockInCalls, 1);
      expect(find.byKey(const Key('stock-in-screen')), findsOneWidget);
      expect(find.text('Saving...'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('record-stock-in-button')),
            )
            .onPressed,
        isNull,
      );

      pending.complete(Success<StockMovement>(_movement(newQuantity: 8)));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('success records stock, shows new count feedback, and returns', (
    tester,
  ) async {
    final stockRepository = _StockRepository();
    await _pumpStockIn(
      tester,
      productRepository: _ProductRepository(),
      stockRepository: stockRepository,
    );

    await tester.enterText(
      find.byKey(const Key('stock-in-quantity-field')),
      '3',
    );
    await tester.enterText(
      find.byKey(const Key('stock-in-note-field')),
      ' delivery ',
    );
    await tester.tap(find.byKey(const Key('record-stock-in-button')));
    await tester.pumpAndSettle();

    expect(stockRepository.lastInput?.quantity, 3);
    expect(stockRepository.lastInput?.note, ' delivery ');
    expect(find.byKey(const Key('products-return-screen')), findsOneWidget);
    expect(find.text('Added 3 pcs to Rice. New stock: 8 pcs.'), findsOneWidget);
  });

  testWidgets('typed failure shows friendly copy without diagnostics', (
    tester,
  ) async {
    await _pumpStockIn(
      tester,
      productRepository: _ProductRepository(),
      stockRepository: _StockRepository(
        onStockIn: (_) async => const FailureResult<StockMovement>(
          PersistenceFailure(debugMessage: 'PRIVATE_DATABASE'),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('stock-in-quantity-field')),
      '3',
    );
    await tester.tap(find.byKey(const Key('record-stock-in-button')));
    await tester.pumpAndSettle();

    expect(
      find.text("We couldn't record stock in. Please try again."),
      findsOneWidget,
    );
    expect(find.textContaining('PRIVATE_DATABASE'), findsNothing);
  });

  testWidgets('missing product shows friendly unavailable state', (
    tester,
  ) async {
    await _pumpStockIn(
      tester,
      productRepository: _ProductRepository(
        onGet: (_) async => const FailureResult<Product>(
          ProductNotFoundFailure(debugMessage: 'PRIVATE_PRODUCT'),
        ),
      ),
    );

    expect(find.text('Product unavailable'), findsOneWidget);
    expect(find.textContaining('PRIVATE_PRODUCT'), findsNothing);
    expect(find.byKey(const Key('record-stock-in-button')), findsNothing);
  });

  testWidgets('fits a small phone with enlarged text', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pumpStockIn(tester, productRepository: _ProductRepository());
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('record-stock-in-button')));
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const Key('record-stock-in-button'))).height,
      greaterThanOrEqualTo(48),
    );
  });
}

Future<void> _pumpStockIn(
  WidgetTester tester, {
  required _ProductRepository productRepository,
  _StockRepository? stockRepository,
}) async {
  final router = GoRouter(
    initialLocation: '/products/product-1/stock-in',
    routes: [
      GoRoute(
        path: '/products',
        name: AppRoute.products.name,
        builder: (_, _) => const Scaffold(key: Key('products-return-screen')),
        routes: [
          GoRoute(
            path: ':productId/stock-in',
            name: ProductRoute.stockIn.name,
            builder: (_, state) => StockInScreen(
              productId: state.pathParameters['productId']!,
            ),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        getProductProvider.overrideWithValue(GetProduct(productRepository)),
        if (stockRepository != null)
          stockRepositoryProvider.overrideWithValue(stockRepository),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _ProductRepository implements ProductRepository {
  _ProductRepository({this.onGet});

  final Future<Result<Product>> Function(String id)? onGet;

  @override
  Future<Result<void>> archiveProduct(String id) => throw UnimplementedError();

  @override
  Future<Result<Product>> createProduct(CreateProductInput input) =>
      throw UnimplementedError();

  @override
  Future<Result<Product>> getProduct(String id) {
    return onGet?.call(id) ?? Future.value(Success<Product>(_product()));
  }

  @override
  Future<Result<Product>> updateProduct(String id, UpdateProductInput input) =>
      throw UnimplementedError();

  @override
  Stream<List<Product>> watchActiveProducts(ProductListQuery query) =>
      const Stream.empty();
}

final class _StockRepository implements StockRepository {
  _StockRepository({this.onStockIn});

  final Future<Result<StockMovement>> Function(RecordStockInInput input)?
  onStockIn;
  int stockInCalls = 0;
  RecordStockInInput? lastInput;

  @override
  Future<Result<StockMovement>> recordStockIn(RecordStockInInput input) {
    stockInCalls++;
    lastInput = input;
    return onStockIn?.call(input) ??
        Future.value(Success<StockMovement>(_movement(newQuantity: 8)));
  }

  @override
  Future<Result<StockMovement>> recordMovementRow(
    CreateStockMovementInput input,
  ) => throw UnimplementedError();

  @override
  Future<Result<StockMovement>> recordStockOut(RecordStockOutInput input) =>
      throw UnimplementedError();

  @override
  Future<Result<List<StockMovement>>> listMovementHistory({
    String? productId,
  }) => throw UnimplementedError();

  @override
  Stream<List<StockMovement>> watchMovementHistory({String? productId}) =>
      const Stream.empty();
}

Product _product() {
  return Product(
    id: 'product-1',
    name: 'Rice',
    category: 'Staples',
    unit: 'pcs',
    sellingPrice: 50,
    quantity: 5,
    lowStockThreshold: 2,
    barcode: null,
    isArchived: false,
    createdAt: DateTime.utc(2026, 7),
    updatedAt: DateTime.utc(2026, 7),
  );
}

StockMovement _movement({required int newQuantity}) {
  return StockMovement(
    id: 'movement-1',
    productId: 'product-1',
    type: StockMovementType.stockIn,
    quantity: 3,
    previousQuantity: 5,
    newQuantity: newQuantity,
    reason: null,
    note: 'delivery',
    productNameSnapshot: 'Rice',
    unitSnapshot: 'pcs',
    createdAt: DateTime.utc(2026, 7, 9),
  );
}
