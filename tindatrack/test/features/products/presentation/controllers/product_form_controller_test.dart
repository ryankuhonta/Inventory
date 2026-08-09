import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/domain/entities/create_product_input.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/entities/product_list_query.dart';
import 'package:tindatrack/features/products/domain/failures/product_failure.dart';
import 'package:tindatrack/features/products/domain/repositories/products_repository.dart';
import 'package:tindatrack/features/products/domain/usecases/add_product.dart';
import 'package:tindatrack/features/products/presentation/controllers/product_form_controller.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';

void main() {
  test('invalid raw values expose field errors without persistence', () async {
    final repository = _ControlledRepository();
    final harness = _ControllerHarness(repository);
    addTearDown(harness.dispose);

    final saved = await harness.controller.submit(
      const ProductFormValues(
        name: ' ',
        category: '',
        unit: ' ',
        sellingPrice: '-1',
        quantity: 'not-an-int',
        lowStockThreshold: '1000000',
        barcode: '',
      ),
    );

    expect(saved, isFalse);
    expect(repository.calls, 0);
    expect(harness.state.firstInvalidField, ProductField.name);
    expect(harness.state.errorFor(ProductField.name), 'Enter a product name.');
    expect(harness.state.errorFor(ProductField.unit), 'Enter a unit.');
    expect(
      harness.state.errorFor(ProductField.sellingPrice),
      'Selling price cannot be below 0.',
    );
    expect(
      harness.state.errorFor(ProductField.quantity),
      'Enter a valid starting quantity.',
    );
    expect(
      harness.state.errorFor(ProductField.lowStockThreshold),
      'Enter 999999 or less.',
    );
  });

  test('blank price maps to zero and a successful save is signaled', () async {
    final repository = _ControlledRepository();
    final harness = _ControllerHarness(repository);
    addTearDown(harness.dispose);

    final saved = await harness.controller.submit(_validValues());

    expect(saved, isTrue);
    expect(repository.calls, 1);
    expect(repository.lastInput?.name, 'Rice');
    expect(repository.lastInput?.category, isNull);
    expect(repository.lastInput?.unit, 'pcs');
    expect(repository.lastInput?.sellingPrice, 0);
    expect(repository.lastInput?.barcode, ' 12345 ');
    expect(harness.state.wasSaved, isTrue);
    expect(harness.state.isSaving, isFalse);
  });

  test('a pending save ignores rapid duplicate submissions', () async {
    final pending = Completer<Result<Product>>();
    final repository = _ControlledRepository(
      onCreate: (_) => pending.future,
    );
    final harness = _ControllerHarness(repository);
    addTearDown(harness.dispose);

    final first = harness.controller.submit(_validValues());
    final second = await harness.controller.submit(_validValues());

    expect(second, isFalse);
    expect(repository.calls, 1);
    expect(harness.state.isSaving, isTrue);

    pending.complete(Success<Product>(_product()));
    expect(await first, isTrue);
    expect(harness.state.wasSaved, isTrue);
  });

  test('typed persistence failures become safe retryable state', () async {
    final repository = _ControlledRepository(
      onCreate: (_) async => const FailureResult<Product>(
        PersistenceFailure(debugMessage: 'SQLITE_PRIVATE'),
      ),
    );
    final harness = _ControllerHarness(repository);
    addTearDown(harness.dispose);

    final saved = await harness.controller.submit(_validValues());

    expect(saved, isFalse);
    expect(harness.state.isSaving, isFalse);
    expect(
      harness.state.message,
      "We couldn't save this product. Please try again.",
    );
    expect(harness.state.message, isNot(contains('SQLITE_PRIVATE')));
  });

  for (final error in <Object>[
    Exception('private exception'),
    StateError('private Dart Error'),
  ]) {
    test('${error.runtimeType} becomes generic safe retryable state', () async {
      final repository = _ControlledRepository(
        onCreate: (_) => Future<Result<Product>>.error(error),
      );
      final harness = _ControllerHarness(repository);
      addTearDown(harness.dispose);

      final saved = await harness.controller.submit(_validValues());

      expect(saved, isFalse);
      expect(harness.state.isSaving, isFalse);
      expect(harness.state.message, 'Something went wrong. Please try again.');
      expect(harness.state.message, isNot(contains('private')));
    });
  }

  test('completion after provider disposal performs no state write', () async {
    final pending = Completer<Result<Product>>();
    final repository = _ControlledRepository(
      onCreate: (_) => pending.future,
    );
    final harness = _ControllerHarness(repository);

    final save = harness.controller.submit(_validValues());
    harness.dispose();
    pending.complete(Success<Product>(_product()));

    expect(await save, isFalse);
  });
}

ProductFormValues _validValues() {
  return const ProductFormValues(
    name: ' Rice ',
    category: ' ',
    unit: ' pcs ',
    sellingPrice: '',
    quantity: '0',
    lowStockThreshold: '0',
    barcode: ' 12345 ',
  );
}

final class _ControllerHarness {
  _ControllerHarness(ProductRepository repository)
    : container = ProviderContainer.test(
        overrides: [
          addProductProvider.overrideWithValue(AddProduct(repository)),
        ],
      ) {
    subscription = container.listen(
      productFormControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
  }

  final ProviderContainer container;
  late final ProviderSubscription<ProductFormState> subscription;

  ProductFormController get controller {
    return container.read(productFormControllerProvider.notifier);
  }

  ProductFormState get state => container.read(productFormControllerProvider);

  void dispose() {
    subscription.close();
    container.dispose();
  }
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
        Future<Result<Product>>.value(Success<Product>(_product()));
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
    id: 'fixed',
    name: 'Rice',
    category: null,
    unit: 'pcs',
    sellingPrice: 0,
    quantity: 0,
    lowStockThreshold: 0,
    barcode: null,
    isArchived: false,
    createdAt: DateTime.utc(2026, 6, 29),
    updatedAt: DateTime.utc(2026, 6, 29),
  );
}
