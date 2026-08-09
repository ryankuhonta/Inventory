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
import 'package:tindatrack/features/products/domain/usecases/archive_product.dart';
import 'package:tindatrack/features/products/domain/usecases/update_product.dart';
import 'package:tindatrack/features/products/presentation/controllers/edit_product_controller.dart';
import 'package:tindatrack/features/products/presentation/controllers/product_form_controller.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';

void main() {
  test('successful archive uses stable ID and clears busy state', () async {
    final repository = _ControlledRepository();
    final harness = _Harness(repository);
    addTearDown(harness.dispose);

    final archived = await harness.controller.archive();

    expect(archived, isTrue);
    expect(repository.archiveCalls, 1);
    expect(repository.lastArchivedId, 'product-1');
    expect(harness.state.isArchiving, isFalse);
  });

  for (final entry in <(AppFailure, String, bool)>[
    (
      const ProductNotFoundFailure(),
      'This product is no longer available.',
      true,
    ),
    (
      const ArchivedProductFailure(),
      'This product is no longer available.',
      true,
    ),
    (
      const PersistenceFailure(debugMessage: 'SQLITE_PRIVATE'),
      "We couldn't archive this product. Please try again.",
      false,
    ),
  ]) {
    test('${entry.$1.runtimeType} uses safe mutation state', () async {
      final repository = _ControlledRepository(
        onArchive: (_) async => FailureResult<void>(entry.$1),
      );
      final harness = _Harness(repository);
      addTearDown(harness.dispose);

      expect(await harness.controller.archive(), isFalse);
      expect(harness.state.message, entry.$2);
      expect(harness.state.message, isNot(contains('SQLITE_PRIVATE')));
      expect(harness.state.isArchiving, isFalse);
      expect(harness.state.isUnavailable, entry.$3);

      expect(await harness.controller.archive(), isFalse);
      expect(repository.archiveCalls, entry.$3 ? 1 : 2);
      if (entry.$3) {
        expect(await harness.controller.submit(_validValues()), isFalse);
        expect(repository.updateCalls, 0);
      }
    });
  }

  test(
    'archive failure preserves existing inline validation feedback',
    () async {
      final repository = _ControlledRepository(
        onArchive: (_) async => const FailureResult<void>(PersistenceFailure()),
      );
      final harness = _Harness(repository);
      addTearDown(harness.dispose);

      expect(await harness.controller.submit(_invalidValues()), isFalse);
      expect(
        harness.state.errorFor(ProductField.name),
        'Enter a product name.',
      );

      expect(await harness.controller.archive(), isFalse);
      expect(
        harness.state.errorFor(ProductField.name),
        'Enter a product name.',
      );
    },
  );

  test('unexpected archive exception uses safe fallback copy', () async {
    final repository = _ControlledRepository(
      onArchive: (_) => throw StateError('PRIVATE_EXCEPTION'),
    );
    final harness = _Harness(repository);
    addTearDown(harness.dispose);

    expect(await harness.controller.archive(), isFalse);
    expect(
      harness.state.message,
      'Something went wrong. Please try again.',
    );
    expect(harness.state.message, isNot(contains('PRIVATE_EXCEPTION')));
  });

  test(
    'pending archive blocks archive and save, then ignores disposal',
    () async {
      final pending = Completer<Result<void>>();
      final repository = _ControlledRepository(
        onArchive: (_) => pending.future,
      );
      final harness = _Harness(repository);

      final first = harness.controller.archive();
      expect(harness.state.isArchiving, isTrue);
      expect(await harness.controller.archive(), isFalse);
      expect(await harness.controller.submit(_validValues()), isFalse);
      expect(repository.archiveCalls, 1);
      expect(repository.updateCalls, 0);

      harness.dispose();
      pending.complete(const Success<void>(null));
      expect(await first, isFalse);
    },
  );

  test('pending save blocks archive submission', () async {
    final pending = Completer<Result<Product>>();
    final repository = _ControlledRepository(
      onUpdate: (_, _) => pending.future,
    );
    final harness = _Harness(repository);
    addTearDown(harness.dispose);

    final save = harness.controller.submit(_validValues());
    expect(harness.state.isSaving, isTrue);
    expect(await harness.controller.archive(), isFalse);
    expect(repository.archiveCalls, 0);

    pending.complete(Success<Product>(_product()));
    expect(await save, isTrue);
  });
}

ProductDetailsFormValues _invalidValues() {
  return const ProductDetailsFormValues(
    name: ' ',
    category: '',
    unit: 'pcs',
    sellingPrice: '50',
    lowStockThreshold: '2',
    barcode: '',
  );
}

ProductDetailsFormValues _validValues() {
  return const ProductDetailsFormValues(
    name: 'Rice',
    category: '',
    unit: 'pcs',
    sellingPrice: '50',
    lowStockThreshold: '2',
    barcode: '',
  );
}

final class _Harness {
  _Harness(ProductRepository repository)
    : container = ProviderContainer.test(
        overrides: [
          archiveProductProvider.overrideWithValue(ArchiveProduct(repository)),
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
  _ControlledRepository({this.onArchive, this.onUpdate});

  final Future<Result<void>> Function(String id)? onArchive;
  final Future<Result<Product>> Function(
    String id,
    UpdateProductInput input,
  )?
  onUpdate;
  int archiveCalls = 0;
  int updateCalls = 0;
  String? lastArchivedId;

  @override
  Future<Result<void>> archiveProduct(String id) {
    archiveCalls++;
    lastArchivedId = id;
    return onArchive?.call(id) ??
        Future<Result<void>>.value(const Success<void>(null));
  }

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
    return onUpdate?.call(id, input) ??
        Future<Result<Product>>.value(Success<Product>(_product()));
  }

  @override
  Stream<List<Product>> watchActiveProducts(ProductListQuery query) {
    return const Stream<List<Product>>.empty();
  }

  @override
  Future<Result<void>> restoreProduct(String id) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Product>> watchArchivedProducts() {
    throw UnimplementedError();
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
