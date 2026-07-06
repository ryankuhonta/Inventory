import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/domain/entities/create_product_input.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/entities/product_list_query.dart';
import 'package:tindatrack/features/products/domain/entities/update_product_input.dart';
import 'package:tindatrack/features/products/domain/failures/product_failure.dart';
import 'package:tindatrack/features/products/domain/repositories/products_repository.dart';
import 'package:tindatrack/features/products/domain/usecases/update_product.dart';
import 'package:tindatrack/features/products/presentation/controllers/edit_product_controller.dart';
import 'package:tindatrack/features/products/presentation/controllers/product_form_controller.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';

void main() {
  test('valid details update the stable product ID', () async {
    final repository = _ControlledRepository();
    final harness = _Harness(repository);
    addTearDown(harness.dispose);

    final saved = await harness.controller.submit(_validValues());

    expect(saved, isTrue);
    expect(repository.updateCalls, 1);
    expect(repository.lastId, 'product-1');
    expect(repository.lastUpdate?.name, 'Rice');
    expect(repository.lastUpdate?.category, isNull);
    expect(repository.lastUpdate?.barcode, ' 123 ');
    expect(harness.state.wasSaved, isTrue);
  });

  test('invalid values stay inline without persistence', () async {
    final repository = _ControlledRepository();
    final harness = _Harness(repository);
    addTearDown(harness.dispose);

    final saved = await harness.controller.submit(
      const ProductDetailsFormValues(
        name: ' ',
        category: '',
        unit: ' ',
        sellingPrice: '-1',
        lowStockThreshold: '1000000',
        barcode: '',
      ),
    );

    expect(saved, isFalse);
    expect(repository.updateCalls, 0);
    expect(harness.state.firstInvalidField, ProductField.name);
    expect(harness.state.errorFor(ProductField.name), 'Enter a product name.');
    expect(harness.state.errorFor(ProductField.unit), 'Enter a unit.');
    expect(
      harness.state.errorFor(ProductField.sellingPrice),
      'Selling price cannot be below 0.',
    );
    expect(
      harness.state.errorFor(ProductField.lowStockThreshold),
      'Enter 999999 or less.',
    );
  });

  test('duplicate barcode is friendly and does not leak diagnostics', () async {
    final repository = _ControlledRepository(
      onUpdate: (_, _) async => const FailureResult<Product>(
        DuplicateBarcodeFailure(debugMessage: 'SQLITE_PRIVATE'),
      ),
    );
    final harness = _Harness(repository);
    addTearDown(harness.dispose);

    expect(await harness.controller.submit(_validValues()), isFalse);
    expect(
      harness.state.message,
      'Barcode already used by another product.',
    );
    expect(harness.state.message, isNot(contains('SQLITE_PRIVATE')));
  });

  test('persistence failure uses friendly retryable copy', () async {
    final repository = _ControlledRepository(
      onUpdate: (_, _) async => const FailureResult<Product>(
        PersistenceFailure(debugMessage: 'SQLITE_PRIVATE'),
      ),
    );
    final harness = _Harness(repository);
    addTearDown(harness.dispose);

    expect(await harness.controller.submit(_validValues()), isFalse);
    expect(
      harness.state.message,
      "We couldn't update this product. Please try again.",
    );
    expect(harness.state.message, isNot(contains('SQLITE_PRIVATE')));
  });

  test('unexpected update exception uses safe fallback copy', () async {
    final repository = _ControlledRepository(
      onUpdate: (_, _) => throw StateError('PRIVATE_EXCEPTION'),
    );
    final harness = _Harness(repository);
    addTearDown(harness.dispose);

    expect(await harness.controller.submit(_validValues()), isFalse);
    expect(
      harness.state.message,
      'Something went wrong. Please try again.',
    );
    expect(harness.state.message, isNot(contains('PRIVATE_EXCEPTION')));
  });

  test('unavailable update target rejects every later mutation', () async {
    final repository = _ControlledRepository(
      onUpdate: (_, _) async => const FailureResult<Product>(
        ProductNotFoundFailure(),
      ),
    );
    final harness = _Harness(repository);
    addTearDown(harness.dispose);

    expect(await harness.controller.submit(_validValues()), isFalse);
    expect(harness.state.isUnavailable, isTrue);
    expect(await harness.controller.submit(_validValues()), isFalse);
    expect(await harness.controller.archive(), isFalse);
    expect(repository.updateCalls, 1);
  });

  test(
    'pending save blocks duplicate submissions and disposal writes',
    () async {
      final pending = Completer<Result<Product>>();
      final repository = _ControlledRepository(
        onUpdate: (_, _) => pending.future,
      );
      final harness = _Harness(repository);

      final first = harness.controller.submit(_validValues());
      final second = await harness.controller.submit(_validValues());
      expect(second, isFalse);
      expect(repository.updateCalls, 1);
      expect(harness.state.isSaving, isTrue);

      harness.dispose();
      pending.complete(Success<Product>(_product()));
      expect(await first, isFalse);
    },
  );
}

ProductDetailsFormValues _validValues() {
  return const ProductDetailsFormValues(
    name: ' Rice ',
    category: ' ',
    unit: ' pcs ',
    sellingPrice: '',
    lowStockThreshold: '2',
    barcode: ' 123 ',
  );
}

final class _Harness {
  _Harness(ProductRepository repository)
    : container = ProviderContainer.test(
        overrides: [
          updateProductProvider.overrideWithValue(UpdateProduct(repository)),
        ],
      ) {
    subscription = container.listen(
      editProductControllerProvider('product-1'),
      (_, _) {},
      fireImmediately: true,
    );
  }

  final ProviderContainer container;
  late final ProviderSubscription<ProductFormState> subscription;

  EditProductController get controller {
    return container.read(
      editProductControllerProvider('product-1').notifier,
    );
  }

  ProductFormState get state {
    return container.read(editProductControllerProvider('product-1'));
  }

  void dispose() {
    subscription.close();
    container.dispose();
  }
}

final class _ControlledRepository implements ProductRepository {
  _ControlledRepository({this.onUpdate});

  @override
  Future<Result<void>> archiveProduct(String id) async {
    throw UnimplementedError();
  }

  final Future<Result<Product>> Function(
    String id,
    UpdateProductInput input,
  )?
  onUpdate;
  int updateCalls = 0;
  String? lastId;
  UpdateProductInput? lastUpdate;

  @override
  Future<Result<Product>> createProduct(CreateProductInput input) async {
    return Success<Product>(_product());
  }

  @override
  Future<Result<Product>> getProduct(String id) async {
    return Success<Product>(_product());
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
        Future<Result<Product>>.value(Success<Product>(_product()));
  }

  @override
  Stream<List<Product>> watchActiveProducts(ProductListQuery query) {
    return Stream.value(const <Product>[]);
  }
}

Product _product() {
  return Product(
    id: 'product-1',
    name: 'Rice',
    category: null,
    unit: 'pcs',
    sellingPrice: 50,
    quantity: 8,
    lowStockThreshold: 2,
    barcode: null,
    isArchived: false,
    createdAt: DateTime.utc(2026, 7),
    updatedAt: DateTime.utc(2026, 7),
  );
}
