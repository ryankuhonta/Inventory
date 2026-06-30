import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/app/theme/app_theme.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/presentation/widgets/product_list_item.dart';

void main() {
  testWidgets('shows category, quantity, stable key, and combined semantics', (
    tester,
  ) async {
    final product = _product(category: 'Staples');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProductListItem(
            key: const ValueKey('product-row-product-1'),
            product: product,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('product-row-product-1')),
      findsOneWidget,
    );
    expect(find.text('Rice'), findsOneWidget);
    expect(find.text('Staples'), findsOneWidget);
    expect(find.text('4 pcs'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Rice, Staples, 4 pcs'),
      findsOneWidget,
    );
    expect(tester.widget<ListTile>(find.byType(ListTile)).onTap, isNull);
  });

  testWidgets('uses unit as metadata when category is absent', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: ProductListItem(product: _product())),
      ),
    );

    expect(find.text('pcs'), findsOneWidget);
    expect(find.text('4 pcs'), findsOneWidget);
    expect(find.bySemanticsLabel('Rice, 4 pcs'), findsOneWidget);
  });

  testWidgets('long quantity text remains safe at enlarged text sizes', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    const unit = 'extra-long-packaging-unit-that-must-not-crowd-the-row';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProductListItem(product: _product(unit: unit)),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('4 $unit'), findsOneWidget);
    expect(find.bySemanticsLabel('Rice, 4 $unit'), findsOneWidget);
  });
}

Product _product({String? category, String unit = 'pcs'}) {
  return Product(
    id: 'product-1',
    name: 'Rice',
    category: category,
    unit: unit,
    sellingPrice: 50,
    quantity: 4,
    lowStockThreshold: 1,
    barcode: null,
    isArchived: false,
    createdAt: DateTime.utc(2026, 6, 30),
    updatedAt: DateTime.utc(2026, 6, 30),
  );
}
