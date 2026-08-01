import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tindatrack/app/router/app_router.dart';
import 'package:tindatrack/app/router/app_routes.dart';
import 'package:tindatrack/app/theme/app_theme.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/domain/entities/create_product_input.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/entities/product_list_query.dart';
import 'package:tindatrack/features/products/domain/failures/product_failure.dart';
import 'package:tindatrack/features/products/domain/repositories/products_repository.dart';
import 'package:tindatrack/features/products/domain/usecases/add_product.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';
import 'package:tindatrack/features/products/presentation/screens/add_product_screen.dart';

void main() {
  testWidgets('renders exact fields, defaults, and exclusions', (tester) async {
    final repository = _ControlledRepository();
    await _pumpForm(tester, repository);

    expect(find.text('Add Product'), findsOneWidget);
    expect(find.byKey(const Key('product-name-field')), findsOneWidget);
    expect(find.byKey(const Key('category-field')), findsOneWidget);
    expect(find.byKey(const Key('unit-field')), findsOneWidget);
    expect(find.byKey(const Key('selling-price-field')), findsOneWidget);
    expect(find.text('Selling price (PHP, optional)'), findsOneWidget);
    expect(find.byKey(const Key('starting-quantity-field')), findsOneWidget);
    expect(
      find.byKey(const Key('low-stock-threshold-field')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('barcode-field')), findsOneWidget);
    expect(find.text('Barcode (optional)'), findsOneWidget);
    expect(_field(tester, 'unit-field').controller?.text, 'pcs');
    expect(_field(tester, 'selling-price-field').controller?.text, '');
    expect(_field(tester, 'starting-quantity-field').controller?.text, '0');
    expect(_field(tester, 'low-stock-threshold-field').controller?.text, '0');
    expect(_field(tester, 'barcode-field').controller?.text, '');
    expect(
      _editable(tester, 'selling-price-field').keyboardType,
      const TextInputType.numberWithOptions(decimal: true),
    );
    expect(
      _editable(tester, 'starting-quantity-field').keyboardType,
      TextInputType.number,
    );
    expect(find.textContaining('Cost price'), findsNothing);
    expect(find.textContaining('Stock In'), findsNothing);
    expect(find.textContaining('Stock Out'), findsNothing);
  });

  testWidgets('invalid submit shows inline errors and focuses first field', (
    tester,
  ) async {
    final repository = _ControlledRepository();
    await _pumpForm(tester, repository);

    await tester.enterText(
      find.byKey(const Key('product-name-field')),
      '   ',
    );
    await tester.enterText(find.byKey(const Key('unit-field')), ' ');
    await tester.enterText(find.byKey(const Key('selling-price-field')), '-1');
    await tester.ensureVisible(find.byKey(const Key('save-product-button')));
    await tester.tap(find.byKey(const Key('save-product-button')));
    await tester.pump();

    expect(find.text('Enter a product name.'), findsOneWidget);
    expect(find.text('Enter a unit.'), findsOneWidget);
    expect(find.text('Selling price cannot be below 0.'), findsOneWidget);
    expect(repository.calls, 0);
    expect(tester.testTextInput.isVisible, isTrue);
    expect(
      _editable(tester, 'product-name-field').focusNode.hasFocus,
      isTrue,
    );
  });

  testWidgets('valid save persists once, shows feedback, and returns', (
    tester,
  ) async {
    final repository = _ControlledRepository();
    await _pumpForm(tester, repository);

    await tester.enterText(
      find.byKey(const Key('product-name-field')),
      ' Rice ',
    );
    await tester.enterText(find.byKey(const Key('category-field')), ' ');
    await tester.ensureVisible(find.byKey(const Key('save-product-button')));
    await tester.tap(find.byKey(const Key('save-product-button')));
    await tester.pumpAndSettle();

    expect(repository.calls, 1);
    expect(repository.lastInput?.name, 'Rice');
    expect(repository.lastInput?.category, isNull);
    expect(repository.lastInput?.unit, 'pcs');
    expect(repository.lastInput?.sellingPrice, 0);
    expect(find.byKey(const Key('products-return-screen')), findsOneWidget);
    expect(find.text('Product saved.'), findsOneWidget);
  });

  testWidgets('pending and failed save protects input and enables retry', (
    tester,
  ) async {
    final pending = Completer<Result<Product>>();
    final repository = _ControlledRepository(onCreate: (_) => pending.future);
    await _pumpForm(tester, repository);

    await tester.enterText(
      find.byKey(const Key('product-name-field')),
      'Rice',
    );
    await tester.ensureVisible(find.byKey(const Key('save-product-button')));
    await tester.tap(find.byKey(const Key('save-product-button')));
    await tester.ensureVisible(find.byKey(const Key('save-product-button')));
    await tester.tap(find.byKey(const Key('save-product-button')));
    await tester.pump();

    expect(repository.calls, 1);
    expect(find.text('Saving...'), findsOneWidget);
    expect(_field(tester, 'product-name-field').enabled, isFalse);
    expect(_field(tester, 'category-field').enabled, isFalse);
    expect(_field(tester, 'unit-field').enabled, isFalse);
    expect(_field(tester, 'selling-price-field').enabled, isFalse);
    expect(_field(tester, 'starting-quantity-field').enabled, isFalse);
    expect(_field(tester, 'low-stock-threshold-field').enabled, isFalse);
    expect(_field(tester, 'barcode-field').enabled, isFalse);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('save-product-button')),
          )
          .onPressed,
      isNull,
    );

    pending.complete(
      const FailureResult<Product>(
        PersistenceFailure(debugMessage: 'SQLITE_PRIVATE'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text("We couldn't save this product. Please try again."),
      findsOneWidget,
    );
    expect(find.textContaining('SQLITE_PRIVATE'), findsNothing);
    expect(_field(tester, 'product-name-field').controller?.text, 'Rice');
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('save-product-button')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('pending save blocks back navigation until completion', (
    tester,
  ) async {
    final pending = Completer<Result<Product>>();
    final repository = _ControlledRepository(onCreate: (_) => pending.future);
    await _pumpForm(tester, repository);

    await tester.enterText(
      find.byKey(const Key('product-name-field')),
      'Rice',
    );
    await tester.ensureVisible(find.byKey(const Key('save-product-button')));
    await tester.tap(find.byKey(const Key('save-product-button')));
    await tester.pump();
    await tester.pageBack();
    await tester.pump();

    expect(find.byKey(const Key('add-product-screen')), findsOneWidget);
    expect(repository.calls, 1);

    pending.complete(Success<Product>(_product(repository.lastInput!)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('products-return-screen')), findsOneWidget);
    expect(find.text('Product saved.'), findsOneWidget);
  });

  testWidgets('successful save returns to Products after switching branches', (
    tester,
  ) async {
    final pending = Completer<Result<Product>>();
    final repository = _ControlledRepository(onCreate: (_) => pending.future);
    final router = createAppRouter(
      initialLocation: ProductRoute.addProduct.path,
      dashboardBuilder: (_, _) =>
          const Scaffold(key: Key('dashboard-test-screen')),
      productsBuilder: (_, _) =>
          const Scaffold(key: Key('products-return-screen')),
      addProductBuilder: (_, _) => const AddProductScreen(),
      historyBuilder: (_, _) => const Scaffold(key: Key('history-test-screen')),
      settingsBuilder: (_, _) =>
          const Scaffold(key: Key('settings-test-screen')),
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addProductProvider.overrideWithValue(AddProduct(repository)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('product-name-field')),
      'Rice',
    );
    await tester.ensureVisible(find.byKey(const Key('save-product-button')));
    await tester.ensureVisible(find.byKey(const Key('save-product-button')));
    await tester.tap(find.byKey(const Key('save-product-button')));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.dashboard_outlined));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard-test-screen')), findsOneWidget);

    pending.complete(Success<Product>(_product(repository.lastInput!)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('products-return-screen')), findsOneWidget);
    expect(find.text('Product saved.'), findsOneWidget);
  });

  testWidgets('invalid and oversized numeric input stays inline', (
    tester,
  ) async {
    final repository = _ControlledRepository();
    await _pumpForm(tester, repository);

    await tester.enterText(
      find.byKey(const Key('product-name-field')),
      'Rice',
    );
    await tester.enterText(
      find.byKey(const Key('selling-price-field')),
      'NaN',
    );
    await tester.enterText(
      find.byKey(const Key('starting-quantity-field')),
      '1.5',
    );
    await tester.enterText(
      find.byKey(const Key('low-stock-threshold-field')),
      '1000000',
    );
    await tester.ensureVisible(find.byKey(const Key('save-product-button')));
    await tester.ensureVisible(find.byKey(const Key('save-product-button')));
    await tester.tap(find.byKey(const Key('save-product-button')));
    await tester.pump();

    expect(find.text('Enter a valid selling price.'), findsOneWidget);
    expect(find.text('Enter a valid starting quantity.'), findsOneWidget);
    expect(find.text('Enter 999999 or less.'), findsOneWidget);
    expect(repository.calls, 0);
    expect(
      _editable(tester, 'selling-price-field').focusNode.hasFocus,
      isTrue,
    );
  });

  testWidgets('unexpected failures never expose diagnostics', (tester) async {
    final repository = _ControlledRepository(
      onCreate: (_) => Future<Result<Product>>.error(
        StateError('RAW_DART_ERROR'),
      ),
    );
    await _pumpForm(tester, repository);

    await tester.enterText(
      find.byKey(const Key('product-name-field')),
      'Rice',
    );
    await tester.ensureVisible(find.byKey(const Key('save-product-button')));
    await tester.ensureVisible(find.byKey(const Key('save-product-button')));
    await tester.tap(find.byKey(const Key('save-product-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('RAW_DART_ERROR'), findsNothing);
  });

  testWidgets('manual barcode is submitted and duplicate copy is safe', (
    tester,
  ) async {
    final repository = _ControlledRepository(
      onCreate: (_) async => const FailureResult<Product>(
        DuplicateBarcodeFailure(debugMessage: 'UNIQUE products.barcode'),
      ),
    );
    await _pumpForm(tester, repository);

    await tester.enterText(
      find.byKey(const Key('product-name-field')),
      'Rice',
    );
    await tester.enterText(find.byKey(const Key('barcode-field')), ' 12345 ');
    await tester.ensureVisible(find.byKey(const Key('save-product-button')));
    await tester.ensureVisible(find.byKey(const Key('save-product-button')));
    await tester.tap(find.byKey(const Key('save-product-button')));
    await tester.pumpAndSettle();

    expect(repository.calls, 1);
    expect(repository.lastInput?.barcode, ' 12345 ');
    expect(
      find.text('Barcode already used by another product.'),
      findsOneWidget,
    );
    expect(find.textContaining('UNIQUE'), findsNothing);
    expect(_field(tester, 'barcode-field').controller?.text, ' 12345 ');
  });
  testWidgets('fits a small phone with enlarged text and accessible controls', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pumpForm(tester, _ControlledRepository());

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('product-name-field')),
      ' ',
    );
    await tester.enterText(find.byKey(const Key('unit-field')), ' ');
    await tester.ensureVisible(find.byKey(const Key('save-product-button')));
    await tester.ensureVisible(find.byKey(const Key('save-product-button')));
    await tester.tap(find.byKey(const Key('save-product-button')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Enter a product name.'), findsOneWidget);
    expect(find.text('Enter a unit.'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('save-product-button'))).height,
      greaterThanOrEqualTo(48),
    );

    final semantics = tester.ensureSemantics();
    final nameSemantics = tester.getSemantics(
      find.byKey(const Key('product-name-field')),
    );
    expect(nameSemantics.label, contains('Product name'));
    expect(
      find.bySemanticsLabel('Enter a product name.'),
      findsOneWidget,
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });
}

TextFormField _field(WidgetTester tester, String key) {
  return tester.widget<TextFormField>(find.byKey(Key(key)));
}

EditableText _editable(WidgetTester tester, String key) {
  return tester.widget<EditableText>(
    find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(EditableText),
    ),
  );
}

Future<void> _pumpForm(
  WidgetTester tester,
  ProductRepository repository,
) async {
  final router = GoRouter(
    initialLocation: '/products/add',
    routes: [
      GoRoute(
        path: '/products',
        name: AppRoute.products.name,
        builder: (_, _) {
          return const Scaffold(key: Key('products-return-screen'));
        },
        routes: [
          GoRoute(
            path: 'add',
            name: ProductRoute.addProduct.name,
            builder: (_, _) => const AddProductScreen(),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        addProductProvider.overrideWithValue(AddProduct(repository)),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _ControlledRepository implements ProductRepository {
  _ControlledRepository({this.onCreate});

  @override
  Future<Result<void>> archiveProduct(String id) async {
    throw UnimplementedError();
  }

  final Future<Result<Product>> Function(CreateProductInput input)? onCreate;
  int calls = 0;
  CreateProductInput? lastInput;

  @override
  Future<Result<Product>> createProduct(CreateProductInput input) {
    calls++;
    lastInput = input;
    return onCreate?.call(input) ??
        Future<Result<Product>>.value(Success<Product>(_product(input)));
  }

  @override
  Future<Result<Product>> getProduct(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Product>> updateProduct(String id, Object input) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Product>> watchActiveProducts(ProductListQuery query) {
    return Stream.value(const <Product>[]);
  }
}

Product _product(CreateProductInput input) {
  return Product(
    id: 'fixed',
    name: input.name,
    category: input.category,
    unit: input.unit,
    sellingPrice: input.sellingPrice,
    quantity: input.quantity,
    lowStockThreshold: input.lowStockThreshold,
    barcode: input.barcode,
    isArchived: false,
    createdAt: DateTime.utc(2026, 6, 29),
    updatedAt: DateTime.utc(2026, 6, 29),
  );
}
