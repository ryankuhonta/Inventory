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

  testWidgets('back with unsaved product edits asks before discarding', (
    tester,
  ) async {
    await _pumpEdit(tester, _Repository());

    await tester.enterText(
      find.byKey(const Key('edit-product-name-field')),
      'Updated Rice',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
    expect(
      find.text(
        'Your product changes have not been saved. Discard them and go back?',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('edit-product-screen')), findsOneWidget);
    expect(_text(tester, 'edit-product-name-field'), 'Updated Rice');

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('products-return-screen')), findsOneWidget);
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

  testWidgets('scan barcode fills Edit Product and counts as unsaved edit', (
    tester,
  ) async {
    final repository = _Repository();
    await _pumpEdit(tester, repository, scanResult: '012345678905');

    await tester.ensureVisible(
      find.byKey(const Key('edit-scan-barcode-action')),
    );
    await tester.tap(find.byKey(const Key('edit-scan-barcode-action')));
    await tester.pumpAndSettle();

    expect(_text(tester, 'edit-barcode-field'), '012345678905');

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('save-product-changes-button')));
    await tester.pumpAndSettle();

    expect(repository.updateCalls, 1);
    expect(repository.lastUpdate?.barcode, '012345678905');
  });

  testWidgets('cancelled Edit Product barcode scan preserves current value', (
    tester,
  ) async {
    await _pumpEdit(tester, _Repository());

    await tester.ensureVisible(
      find.byKey(const Key('edit-scan-barcode-action')),
    );
    await tester.tap(find.byKey(const Key('edit-scan-barcode-action')));
    await tester.pumpAndSettle();

    expect(_text(tester, 'edit-barcode-field'), '123');
    expect(
      find.text('Barcode scanning is unavailable. You can type it.'),
      findsNothing,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsNothing);
    expect(find.byKey(const Key('products-return-screen')), findsOneWidget);
  });

  testWidgets('Edit Product scanner failure preserves current value', (
    tester,
  ) async {
    await _pumpEdit(tester, _Repository(), scanResult: false);

    await tester.ensureVisible(
      find.byKey(const Key('edit-scan-barcode-action')),
    );
    await tester.tap(find.byKey(const Key('edit-scan-barcode-action')));
    await tester.pumpAndSettle();

    expect(_text(tester, 'edit-barcode-field'), '123');
    expect(
      find.text('Barcode scanning is unavailable. You can type it.'),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsNothing);
    expect(find.byKey(const Key('products-return-screen')), findsOneWidget);
  });

  testWidgets('rapid Edit Product scan taps open one scanner route', (
    tester,
  ) async {
    final scanResult = Completer<Object?>();
    var scannerBuilds = 0;
    await _pumpEdit(
      tester,
      _Repository(),
      scanResultCompleter: scanResult,
      onScanRouteBuilt: () => scannerBuilds++,
    );

    final action = find.byKey(const Key('edit-scan-barcode-action'));
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.tap(action);
    await tester.pump();

    expect(scannerBuilds, 1);

    scanResult.complete('012345678905');
    await tester.pumpAndSettle();

    expect(_text(tester, 'edit-barcode-field'), '012345678905');
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
  Object? scanResult,
  Completer<Object?>? scanResultCompleter,
  VoidCallback? onScanRouteBuilt,
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
          GoRoute(
            path: 'scan-barcode',
            name: ProductRoute.scanBarcode.name,
            builder: (_, _) => _BarcodeScannerStub(
              result: scanResult,
              resultCompleter: scanResultCompleter,
              onBuilt: onScanRouteBuilt,
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

final class _BarcodeScannerStub extends StatefulWidget {
  const _BarcodeScannerStub({
    required this.result,
    required this.resultCompleter,
    required this.onBuilt,
  });

  final Object? result;
  final Completer<Object?>? resultCompleter;
  final VoidCallback? onBuilt;

  @override
  State<_BarcodeScannerStub> createState() => _BarcodeScannerStubState();
}

final class _BarcodeScannerStubState extends State<_BarcodeScannerStub> {
  @override
  void initState() {
    super.initState();
    widget.onBuilt?.call();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = widget.resultCompleter == null
          ? widget.result
          : await widget.resultCompleter!.future;
      if (mounted) Navigator.of(context).pop(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(key: Key('barcode-scanner-test-screen'));
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
