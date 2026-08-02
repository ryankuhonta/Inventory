import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/domain/entities/create_product_input.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/entities/product_list_query.dart';
import 'package:tindatrack/features/products/domain/repositories/products_repository.dart';
import 'package:tindatrack/features/products/presentation/controllers/product_list_controller.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';

void main() {
  test('forwards each effective applied query to one repository', () async {
    final repository = _RecordingRepository();
    final container = ProviderContainer.test(
      overrides: [
        productRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(activeProductsProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.pump();

    expect(repository.queries, [const ProductListQuery.defaultQuery()]);

    container
        .read(productListControllerProvider.notifier)
        .stockFilterChanged(ProductStockFilter.lowStock);
    await container.pump();

    expect(repository.queries, [
      const ProductListQuery.defaultQuery(),
      ProductListQuery(stockFilter: ProductStockFilter.lowStock),
    ]);

    container
        .read(productListControllerProvider.notifier)
        .stockFilterChanged(ProductStockFilter.lowStock);
    await container.pump();

    expect(repository.queries, hasLength(2));
  });

  test('stream errors stay AsyncError and retry keeps current query', () async {
    final repository = _RecordingRepository();
    final container = ProviderContainer.test(
      overrides: [
        productRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(activeProductsProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.pump();

    repository.emitError = true;
    container
        .read(productListControllerProvider.notifier)
        .stockFilterChanged(ProductStockFilter.outOfStock);
    await container.pump();
    await container.pump();

    expect(
      container.read(activeProductsProvider),
      isA<AsyncError<List<Product>>>(),
    );
    final attemptsBeforeRetry = repository.queries.length;

    container.invalidate(activeProductsProvider);
    await container.pump();

    expect(repository.queries, hasLength(attemptsBeforeRetry + 1));
    expect(
      repository.queries.last,
      ProductListQuery(stockFilter: ProductStockFilter.outOfStock),
    );
  });
}

final class _RecordingRepository implements ProductRepository {
  @override
  Future<Result<void>> archiveProduct(String id) async {
    throw UnimplementedError();
  }

  bool emitError = false;
  final List<ProductListQuery> queries = <ProductListQuery>[];

  @override
  Future<Result<Product>> createProduct(CreateProductInput input) {
    throw UnimplementedError();
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
    queries.add(query);
    if (emitError) {
      return Stream<List<Product>>.error(StateError('RAW_QUERY_ERROR'));
    }
    return Stream<List<Product>>.value(const <Product>[]);
  }
}
