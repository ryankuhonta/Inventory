import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/app/theme/app_theme.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/entities/product_list_query.dart';
import 'package:tindatrack/features/products/presentation/controllers/product_list_controller.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';
import 'package:tindatrack/features/products/presentation/screens/product_list_screen.dart';

void main() {
  testWidgets('controls and FAB persist while results are loading', (
    tester,
  ) async {
    final stream = StreamController<List<Product>>();
    addTearDown(stream.close);
    await _pumpScreen(tester, stream.stream);

    expect(find.byKey(const Key('product-search-field')), findsOneWidget);
    expect(find.text('Search products'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Low Stock'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Out of Stock'), findsOneWidget);
    expect(find.byKey(const Key('add-product-action')), findsOneWidget);
    expect(find.byKey(const Key('products-loading-state')), findsOneWidget);
  });

  testWidgets('visible text is immediate while applied text is debounced', (
    tester,
  ) async {
    final container = ProviderContainer.test();
    addTearDown(container.dispose);
    await _pumpScreen(
      tester,
      Stream<List<Product>>.value(const <Product>[]),
      container: container,
    );

    await tester.enterText(
      find.byKey(const Key('product-search-field')),
      'rice',
    );
    expect(find.text('rice'), findsOneWidget);
    expect(
      container.read(productListControllerProvider),
      const ProductListQuery.defaultQuery(),
    );

    await tester.pump(const Duration(milliseconds: 299));
    expect(
      container.read(productListControllerProvider),
      const ProductListQuery.defaultQuery(),
    );
    await tester.pump(const Duration(milliseconds: 1));
    expect(
      container.read(productListControllerProvider),
      ProductListQuery(searchText: 'rice'),
    );
  });

  testWidgets('non-default empty state resets to true catalog empty', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      Stream<List<Product>>.value(const <Product>[]),
    );
    expect(find.text('No products yet'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Low Stock'));
    await tester.pump();

    expect(find.text('No matching products'), findsOneWidget);
    expect(
      find.text('Try another search or reset the filters.'),
      findsOneWidget,
    );
    expect(
      find.text('Add your first product to start tracking stock.'),
      findsNothing,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pump();

    expect(find.text('No products yet'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'All'))
          .selected,
      isTrue,
    );
  });

  testWidgets('preselected Low Stock filter can return to All', (
    tester,
  ) async {
    final container = ProviderContainer.test();
    addTearDown(container.dispose);
    container
        .read(productListControllerProvider.notifier)
        .stockFilterChanged(ProductStockFilter.lowStock);

    await _pumpScreen(
      tester,
      Stream<List<Product>>.value(const <Product>[]),
      container: container,
    );

    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Low Stock'))
          .selected,
      isTrue,
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pump();

    expect(
      container.read(productListControllerProvider).stockFilter,
      ProductStockFilter.all,
    );
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'All'))
          .selected,
      isTrue,
    );
  });

  testWidgets('safe error keeps controls, retry, and FAB', (tester) async {
    await _pumpScreen(
      tester,
      Stream<List<Product>>.error(StateError('RAW_SQLITE_ERROR')),
    );
    await tester.pump();

    expect(find.text('Products unavailable'), findsOneWidget);
    expect(find.textContaining('RAW_SQLITE_ERROR'), findsNothing);
    expect(find.byKey(const Key('product-search-field')), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
    expect(find.byKey(const Key('add-product-action')), findsOneWidget);
  });

  testWidgets('controls fit 360x640 at 2x text with labeled tap targets', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pumpScreen(
      tester,
      Stream<List<Product>>.value(const <Product>[]),
    );

    expect(tester.takeException(), isNull);
    final semantics = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  Stream<List<Product>> products, {
  ProviderContainer? container,
}) async {
  final child = MaterialApp(
    theme: AppTheme.light,
    home: const ProductListScreen(),
  );
  await tester.pumpWidget(
    container == null
        ? ProviderScope(
            overrides: [
              activeProductsProvider.overrideWith((ref) => products),
            ],
            child: child,
          )
        : UncontrolledProviderScope(
            container: container,
            child: ProviderScope(
              overrides: [
                activeProductsProvider.overrideWith((ref) => products),
              ],
              child: child,
            ),
          ),
  );
  await tester.pump();
}
