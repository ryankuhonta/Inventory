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

    expect(find.byKey(const ValueKey('product-row-product-1')), findsOneWidget);
    expect(find.text('Rice'), findsOneWidget);
    expect(find.text('Staples'), findsOneWidget);
    expect(find.text('4 pcs'), findsOneWidget);
    expect(find.bySemanticsLabel('Rice, Staples, 4 pcs'), findsOneWidget);
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

  testWidgets('shows Low Stock in the row and merged semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProductListItem(
            product: _product(category: 'Staples', quantity: 2, threshold: 2),
          ),
        ),
      ),
    );

    expect(find.text('2 pcs'), findsOneWidget);
    expect(find.text('Low Stock'), findsOneWidget);
    expect(find.text('Out of Stock'), findsNothing);
    expect(
      find.bySemanticsLabel('Rice, Staples, 2 pcs, Low Stock'),
      findsOneWidget,
    );
  });

  testWidgets('zero stock shows only Out of Stock in row semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProductListItem(product: _product(quantity: 0, threshold: 5)),
        ),
      ),
    );

    expect(find.text('0 pcs'), findsOneWidget);
    expect(find.text('Out of Stock'), findsOneWidget);
    expect(find.text('Low Stock'), findsNothing);
    expect(find.bySemanticsLabel('Rice, 0 pcs, Out of Stock'), findsOneWidget);
  });

  testWidgets('normal stock renders no warning label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: ProductListItem(product: _product())),
      ),
    );

    expect(find.text('Low Stock'), findsNothing);
    expect(find.text('Out of Stock'), findsNothing);
  });

  testWidgets('edit callback is announced and operable from the row', (
    tester,
  ) async {
    var edits = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ProductListItem(
            product: _product(),
            onEdit: () => edits++,
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Rice, 4 pcs, Edit product'), findsOneWidget);
    await tester.tap(find.byType(ListTile));
    expect(edits, 1);
  });

  testWidgets('long quantity and status remain safe at enlarged text sizes', (
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
          body: ProductListItem(
            product: _product(unit: unit, quantity: 1),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('1 $unit'), findsOneWidget);
    expect(find.text('Low Stock'), findsOneWidget);
    expect(find.bySemanticsLabel('Rice, 1 $unit, Low Stock'), findsOneWidget);
  });
}

Product _product({
  String? category,
  String unit = 'pcs',
  int quantity = 4,
  int threshold = 1,
}) {
  return Product(
    id: 'product-1',
    name: 'Rice',
    category: category,
    unit: unit,
    sellingPrice: 50,
    quantity: quantity,
    lowStockThreshold: threshold,
    barcode: null,
    isArchived: false,
    createdAt: DateTime.utc(2026, 6, 30),
    updatedAt: DateTime.utc(2026, 6, 30),
  );
}
