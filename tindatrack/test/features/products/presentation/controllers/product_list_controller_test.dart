import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/features/products/domain/entities/product_list_query.dart';
import 'package:tindatrack/features/products/presentation/controllers/product_list_controller.dart';

void main() {
  testWidgets('applies only the latest text after exactly 300 ms', (
    tester,
  ) async {
    final container = ProviderContainer.test();
    addTearDown(container.dispose);
    final subscription = container.listen(
      productListControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    container
        .read(productListControllerProvider.notifier)
        .searchTextChanged('r');
    await tester.pump(const Duration(milliseconds: 200));
    container
        .read(productListControllerProvider.notifier)
        .searchTextChanged('rice');
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

  testWidgets('filter is immediate and pending text keeps current filter', (
    tester,
  ) async {
    final container = ProviderContainer.test();
    addTearDown(container.dispose);

    container
        .read(productListControllerProvider.notifier)
        .searchTextChanged('rice');
    await tester.pump(const Duration(milliseconds: 100));
    container
        .read(productListControllerProvider.notifier)
        .stockFilterChanged(ProductStockFilter.lowStock);

    expect(
      container.read(productListControllerProvider),
      ProductListQuery(stockFilter: ProductStockFilter.lowStock),
    );

    await tester.pump(const Duration(milliseconds: 200));

    expect(
      container.read(productListControllerProvider),
      ProductListQuery(
        searchText: 'rice',
        stockFilter: ProductStockFilter.lowStock,
      ),
    );
  });

  testWidgets('blank clear and reset cancel pending text immediately', (
    tester,
  ) async {
    final container = ProviderContainer.test();
    addTearDown(container.dispose);
    final controller = container.read(productListControllerProvider.notifier)
      ..stockFilterChanged(ProductStockFilter.outOfStock)
      ..searchTextChanged('pending')
      ..searchTextChanged('   ');

    expect(
      container.read(productListControllerProvider),
      ProductListQuery(stockFilter: ProductStockFilter.outOfStock),
    );

    await tester.pump(const Duration(milliseconds: 300));
    expect(
      container.read(productListControllerProvider),
      ProductListQuery(stockFilter: ProductStockFilter.outOfStock),
    );

    controller
      ..searchTextChanged('another')
      ..reset();
    expect(
      container.read(productListControllerProvider),
      const ProductListQuery.defaultQuery(),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      container.read(productListControllerProvider),
      const ProductListQuery.defaultQuery(),
    );
  });

  testWidgets('container disposal cancels pending debounce work', (
    tester,
  ) async {
    final container = ProviderContainer.test();
    container
        .read(productListControllerProvider.notifier)
        .searchTextChanged('rice');

    container.dispose();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
  });
}
