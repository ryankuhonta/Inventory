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
import 'package:tindatrack/features/products/domain/usecases/update_product.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';
import 'package:tindatrack/features/products/presentation/screens/edit_product_screen.dart';

void main() {
  testWidgets('prefills editable details and keeps quantity read-only', (
    tester,
  ) async {
    await _pumpEdit(tester, _Repository());

    expect(find.text('Edit Product'), findsOneWidget);
    expect(_text(tester, 'edit-product-name-field'), 'Rice');
    expect(_text(tester, 'edit-category-field'), 'Staples');
    expect(_text(tester, 'edit-unit-field'), 'pcs');
    expect(_text(tester, 'edit-selling-price-field'), '50.0');
    expect(find.text('Selling price (PHP, optional)'), findsOneWidget);
    expect(_text(tester, 'edit-low-stock-threshold-field'), '2');
    expect(_text(tester, 'edit-barcode-field'), '123');
    expect(find.text('Current quantity: 8 pcs'), findsOneWidget);
    expect(
      find.text('Use Stock In or Stock Out to change quantity.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('starting-quantity-field')), findsNothing);
    expect(find.textContaining('Cost price'), findsNothing);
    expect(find.text('Archive'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Current quantity 8 pcs. Read only.'),
      findsOneWidget,
    );
  });

  testWidgets('valid save updates once, shows feedback, and returns', (
    tester,
  ) async {
    final repository = _Repository();
    await _pumpEdit(tester, repository);

    await tester.enterText(
      find.byKey(const Key('edit-product-name-field')),
      ' Updated Rice ',
    );
    await tester.tap(find.byKey(const Key('save-product-changes-button')));
    await tester.pumpAndSettle();

    expect(repository.updateCalls, 1);
    expect(repository.lastId, 'product-1');
    expect(repository.lastUpdate?.name, 'Updated Rice');
    expect(repository.lastUpdate?.lowStockThreshold, 2);
    expect(find.byKey(const Key('products-return-screen')), findsOneWidget);
    expect(find.text('Product updated.'), findsOneWidget);
  });

  testWidgets('pending save disables form and blocks back navigation', (
    tester,
  ) async {
    final pending = Completer<Result<Product>>();
    final repository = _Repository(onUpdate: (_, _) => pending.future);
    await _pumpEdit(tester, repository);

    await tester.tap(find.byKey(const Key('save-product-changes-button')));
    await tester.pump();
    await tester.pageBack();
    await tester.pump();

    expect(find.byKey(const Key('edit-product-screen')), findsOneWidget);
    expect(find.text('Saving...'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('save-product-changes-button')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('edit-product-name-field')),
          )
          .enabled,
      isFalse,
    );

    pending.complete(Success<Product>(_product()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('products-return-screen')), findsOneWidget);
  });

  testWidgets('missing product shows friendly unavailable state', (
    tester,
  ) async {
    await _pumpEdit(
      tester,
      _Repository(
        onGet: (_) async => const FailureResult<Product>(
          ProductNotFoundFailure(debugMessage: 'PRIVATE'),
        ),
      ),
    );

    expect(find.text('Product unavailable'), findsOneWidget);
    expect(find.textContaining('PRIVATE'), findsNothing);
    expect(find.byKey(const Key('save-product-changes-button')), findsNothing);
  });

  testWidgets('shows accessible loading while product lookup is pending', (
    tester,
  ) async {
    final pending = Completer<Result<Product>>();
    await _pumpEdit(
      tester,
      _Repository(onGet: (_) => pending.future),
      settle: false,
    );

    expect(
      find.bySemanticsLabel('Loading product details'),
      findsOneWidget,
    );

    pending.complete(Success<Product>(_product()));
    await tester.pumpAndSettle();
  });

  testWidgets('generic load failure retries without exposing diagnostics', (
    tester,
  ) async {
    var calls = 0;
    await _pumpEdit(
      tester,
      _Repository(
        onGet: (_) async {
          calls++;
          if (calls == 1) {
            return const FailureResult<Product>(
              PersistenceFailure(debugMessage: 'PRIVATE_DATABASE'),
            );
          }
          return Success<Product>(_product());
        },
      ),
    );

    expect(
      find.text("We couldn't load this product. Please try again."),
      findsOneWidget,
    );
    expect(find.textContaining('PRIVATE_DATABASE'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(find.byKey(const Key('edit-product-name-field')), findsOneWidget);
  });

  testWidgets('invalid save exposes inline semantics and focuses first field', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final repository = _Repository();
    await _pumpEdit(tester, repository);

    await tester.enterText(
      find.byKey(const Key('edit-product-name-field')),
      ' ',
    );
    await tester.tap(find.byKey(const Key('save-product-changes-button')));
    await tester.pumpAndSettle();

    expect(repository.updateCalls, 0);
    expect(find.text('Enter a product name.'), findsOneWidget);
    final nameField = find.byKey(const Key('edit-product-name-field'));
    expect(
      find.bySemanticsLabel('Enter a product name.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<EditableText>(
            find.descendant(of: nameField, matching: find.byType(EditableText)),
          )
          .focusNode
          .hasFocus,
      isTrue,
    );
    semantics.dispose();
  });

  testWidgets('fits a small phone with enlarged text', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pumpEdit(tester, _Repository());
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('save-product-changes-button')),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester
          .getSize(find.byKey(const Key('save-product-changes-button')))
          .height,
      greaterThanOrEqualTo(48),
    );
  });
}

String _text(WidgetTester tester, String key) {
  return tester.widget<TextFormField>(find.byKey(Key(key))).controller!.text;
}

Future<void> _pumpEdit(
  WidgetTester tester,
  _Repository repository, {
  bool settle = true,
}) async {
  final router = GoRouter(
    initialLocation: '/products/product-1/edit',
    routes: [
      GoRoute(
        path: '/products',
        name: AppRoute.products.name,
        builder: (_, _) => const Scaffold(key: Key('products-return-screen')),
        routes: [
          GoRoute(
            path: ':productId/edit',
            name: ProductRoute.editProduct.name,
            builder: (_, state) => EditProductScreen(
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
        getProductProvider.overrideWithValue(GetProduct(repository)),
        updateProductProvider.overrideWithValue(UpdateProduct(repository)),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

final class _Repository implements ProductRepository {
  _Repository({this.onGet, this.onUpdate});

  @override
  Future<Result<void>> archiveProduct(String id) async {
    throw UnimplementedError();
  }

  final Future<Result<Product>> Function(String id)? onGet;
  final Future<Result<Product>> Function(
    String id,
    UpdateProductInput input,
  )?
  onUpdate;
  int updateCalls = 0;
  String? lastId;
  UpdateProductInput? lastUpdate;

  @override
  Future<Result<Product>> createProduct(CreateProductInput input) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Product>> getProduct(String id) {
    return onGet?.call(id) ??
        Future<Result<Product>>.value(Success<Product>(_product()));
  }

  @override
  Future<Result<Product>> updateProduct(
    String id,
    UpdateProductInput input,
  ) {
    updateCalls++;
    lastId = id;
    lastUpdate = input;
    return onUpdate?.call(id, input) ??
        Future<Result<Product>>.value(
          Success<Product>(_product(name: input.name)),
        );
  }

  @override
  Stream<List<Product>> watchActiveProducts(ProductListQuery query) {
    return Stream.value(const <Product>[]);
  }
}

Product _product({String name = 'Rice'}) {
  return Product(
    id: 'product-1',
    name: name,
    category: 'Staples',
    unit: 'pcs',
    sellingPrice: 50,
    quantity: 8,
    lowStockThreshold: 2,
    barcode: '123',
    isArchived: false,
    createdAt: DateTime.utc(2026, 7),
    updatedAt: DateTime.utc(2026, 7),
  );
}
