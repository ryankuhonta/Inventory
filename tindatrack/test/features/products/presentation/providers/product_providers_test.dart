import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/domain/entities/create_product_input.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/entities/product_list_query.dart';
import 'package:tindatrack/features/products/domain/repositories/products_repository.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';

void main() {
  test('archive provider delegates through the canonical repository', () async {
    final repository = _StreamingProductRepository(
      const Stream<List<Product>>.empty(),
    );
    final container = ProviderContainer.test(
      overrides: [
        productRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(archiveProductProvider)('product-7');

    expect(result, isA<Success<void>>());
    expect(repository.archivedId, 'product-7');
  });

  test('active products provider exposes repository stream updates', () async {
    final stream = StreamController<List<Product>>();
    final repository = _StreamingProductRepository(stream.stream);
    final container = ProviderContainer.test(
      overrides: [
        productRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(stream.close);
    addTearDown(container.dispose);

    final subscription = container.listen(activeProductsProvider, (_, _) {});
    addTearDown(subscription.close);

    stream.add([_product('1', 'Rice')]);
    expect(await container.read(activeProductsProvider.future), [
      isA<Product>().having((product) => product.name, 'name', 'Rice'),
    ]);

    stream.add([_product('2', 'Soap')]);
    await pumpEventQueue();

    expect(
      container.read(activeProductsProvider).value,
      [isA<Product>().having((product) => product.name, 'name', 'Soap')],
    );
  });

  test('active products provider contains repository stream errors', () async {
    final stream = StreamController<List<Product>>();
    final container = ProviderContainer.test(
      overrides: [
        productRepositoryProvider.overrideWithValue(
          _StreamingProductRepository(stream.stream),
        ),
      ],
    );
    addTearDown(stream.close);
    addTearDown(container.dispose);

    final subscription = container.listen(activeProductsProvider, (_, _) {});
    addTearDown(subscription.close);
    stream.addError(StateError('RAW_STREAM_ERROR'));
    await pumpEventQueue();

    expect(
      container.read(activeProductsProvider),
      isA<AsyncError<List<Product>>>(),
    );
  });

  test(
    'disposing the provider container cancels the stream subscription',
    () async {
      var wasCancelled = false;
      final stream = StreamController<List<Product>>(
        onCancel: () => wasCancelled = true,
      );
      ProviderContainer.test(
          overrides: [
            productRepositoryProvider.overrideWithValue(
              _StreamingProductRepository(stream.stream),
            ),
          ],
        )
        ..listen(activeProductsProvider, (_, _) {})
        ..dispose();
      await pumpEventQueue();

      expect(wasCancelled, isTrue);
      await stream.close();
    },
  );
}

final class _StreamingProductRepository implements ProductRepository {
  _StreamingProductRepository(this.products);

  final Stream<List<Product>> products;
  String? archivedId;

  @override
  Future<Result<void>> archiveProduct(String id) async {
    archivedId = id;
    return const Success<void>(null);
  }

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
    return products;
  }
}

Product _product(String id, String name) {
  return Product(
    id: id,
    name: name,
    category: null,
    unit: 'pcs',
    sellingPrice: 10,
    quantity: 1,
    lowStockThreshold: 0,
    barcode: null,
    isArchived: false,
    createdAt: DateTime.utc(2026, 6, 30),
    updatedAt: DateTime.utc(2026, 6, 30),
  );
}
