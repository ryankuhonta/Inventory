import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/domain/entities/create_product_input.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/entities/product_list_query.dart';
import 'package:tindatrack/features/products/domain/failures/product_failure.dart';
import 'package:tindatrack/features/products/domain/repositories/products_repository.dart';
import 'package:tindatrack/features/products/domain/usecases/add_product.dart';

void main() {
  late _RecordingProductRepository repository;
  late AddProduct addProduct;

  setUp(() {
    repository = _RecordingProductRepository();
    addProduct = AddProduct(repository);
  });

  test('normalizes valid input before delegating to the repository', () async {
    final result = await addProduct(
      const CreateProductInput(
        name: '  Rice ',
        category: '   ',
        unit: ' kg  ',
        sellingPrice: 60,
        quantity: 2,
        lowStockThreshold: 1,
      ),
    );

    expect(result, isA<Success<Product>>());
    expect(repository.calls, 1);
    expect(repository.lastInput?.name, 'Rice');
    expect(repository.lastInput?.category, isNull);
    expect(repository.lastInput?.unit, 'kg');
  });

  test('does not call the repository for invalid input', () async {
    final result = await addProduct(
      const CreateProductInput(
        name: ' ',
        unit: 'pcs',
        sellingPrice: 0,
        quantity: 0,
        lowStockThreshold: 0,
      ),
    );

    expect(result, isA<FailureResult<Product>>());
    final failure = (result as FailureResult<Product>).failure;
    expect(failure, isA<ProductValidationFailure>());
    expect((failure as ProductValidationFailure).field, ProductField.name);
    expect(repository.calls, 0);
  });

  test('passes typed repository failures through unchanged', () async {
    const failure = PersistenceFailure(debugMessage: 'private diagnostics');
    repository.result = const FailureResult<Product>(failure);

    final result = await addProduct(_input());

    expect(result, isA<FailureResult<Product>>());
    expect((result as FailureResult<Product>).failure, same(failure));
  });
}

CreateProductInput _input() {
  return const CreateProductInput(
    name: 'Rice',
    unit: 'pcs',
    sellingPrice: 10,
    quantity: 1,
    lowStockThreshold: 0,
  );
}

final class _RecordingProductRepository implements ProductRepository {
  @override
  Future<Result<void>> archiveProduct(String id) async {
    throw UnimplementedError();
  }

  Result<Product> result = Success<Product>(_product());
  int calls = 0;
  CreateProductInput? lastInput;

  @override
  Future<Result<Product>> createProduct(CreateProductInput input) async {
    calls++;
    lastInput = input;
    return result;
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
}

Product _product() {
  return Product(
    id: 'fixed',
    name: 'Rice',
    category: null,
    unit: 'pcs',
    sellingPrice: 10,
    quantity: 1,
    lowStockThreshold: 0,
    barcode: null,
    isArchived: false,
    createdAt: DateTime.utc(2026, 6, 29),
    updatedAt: DateTime.utc(2026, 6, 29),
  );
}
