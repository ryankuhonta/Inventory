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
  testWidgets(
    'clear preserves selected filter and app-session query survives remount',
    (tester) async {
      final container = ProviderContainer.test(
        overrides: [
          activeProductsProvider.overrideWith(
            (ref) => Stream<List<Product>>.value(const <Product>[]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await _pumpScreen(tester, container);
      await tester.enterText(
        find.byKey(const Key('product-search-field')),
        'rice',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Low Stock'));
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('product-search-field')),
        'pending',
      );
      await tester.tap(find.byKey(const Key('clear-product-search')));
      await tester.pump();

      expect(
        container.read(productListControllerProvider),
        ProductListQuery(stockFilter: ProductStockFilter.lowStock),
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('product-search-field')))
            .controller!
            .text,
        isEmpty,
      );
      final selectedChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Low Stock'),
      );
      expect(selectedChip.selected, isTrue);
      expect(selectedChip.showCheckmark, isTrue);

      await tester.pump(const Duration(milliseconds: 300));
      expect(
        container.read(productListControllerProvider),
        ProductListQuery(stockFilter: ProductStockFilter.lowStock),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpScreen(tester, container);

      expect(
        tester
            .widget<ChoiceChip>(
              find.widgetWithText(ChoiceChip, 'Low Stock'),
            )
            .selected,
        isTrue,
      );
      expect(find.text('No matching products'), findsOneWidget);
    },
  );

  testWidgets('limits visible and applied search text to 1,000 characters', (
    tester,
  ) async {
    final container = ProviderContainer.test(
      overrides: [
        activeProductsProvider.overrideWith(
          (ref) => Stream<List<Product>>.value(const <Product>[]),
        ),
      ],
    );
    addTearDown(container.dispose);
    await _pumpScreen(tester, container);

    await tester.enterText(
      find.byKey(const Key('product-search-field')),
      List<String>.filled(1001, 'x').join(),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final visibleText = tester
        .widget<TextField>(find.byKey(const Key('product-search-field')))
        .controller!
        .text;
    expect(visibleText, hasLength(1000));
    expect(
      container.read(productListControllerProvider).searchText,
      hasLength(1000),
    );
  });

  testWidgets('pending applied search synchronizes after screen remount', (
    tester,
  ) async {
    final container = ProviderContainer.test(
      overrides: [
        activeProductsProvider.overrideWith(
          (ref) => Stream<List<Product>>.value(const <Product>[]),
        ),
      ],
    );
    addTearDown(container.dispose);
    await _pumpScreen(tester, container);

    await tester.enterText(
      find.byKey(const Key('product-search-field')),
      'rice',
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpScreen(tester, container);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    final visibleText = tester
        .widget<TextField>(find.byKey(const Key('product-search-field')))
        .controller!
        .text;
    expect(visibleText, 'rice');
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: const ProductListScreen(),
      ),
    ),
  );
  await tester.pump();
}
