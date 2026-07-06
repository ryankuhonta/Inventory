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

void main() {
  late _RecordingRepository repository;
  late UpdateProduct updateProduct;

  setUp(() {
    repository = _RecordingRepository();
    updateProduct = UpdateProduct(repository);
  });

  test('normalizes editable details before updating by stable ID', () async {
    final result = await updateProduct(
      'product-1',
      const UpdateProductInput(
        name: '  Rice ',
        category: '   ',
        unit: ' kg ',
        sellingPrice: 50,
        lowStockThreshold: 2,
        barcode: ' 123 ',
      ),
    );

    expect(result, isA<Success<Product>>());
    expect(repository.updateCalls, 1);
    expect(repository.lastId, 'product-1');
    expect(repository.lastUpdate?.name, 'Rice');
    expect(repository.lastUpdate?.category, isNull);
    expect(repository.lastUpdate?.unit, 'kg');
    expect(repository.lastUpdate?.barcode, ' 123 ');
  });

  test('invalid details never reach the repository', () async {
    final result = await updateProduct(
      'product-1',
      const UpdateProductInput(
        name: ' ',
        unit: 'pcs',
        sellingPrice: 1,
        lowStockThreshold: 0,
      ),
    );

    expect(result, isA<FailureResult<Product>>());
    expect(
      (result as FailureResult<Product>).failure,
      isA<ProductValidationFailure>(),
    );
    expect(repository.updateCalls, 0);
  });

  test('passes typed repository failures through unchanged', () async {
    const failure = PersistenceFailure(debugMessage: 'private');
    repository.updateResult = const FailureResult<Product>(failure);

    final result = await updateProduct('product-1', _update());

    expect((result as FailureResult<Product>).failure, same(failure));
  });
}

UpdateProductInput _update() {
  return const UpdateProductInput(
    name: 'Rice',
    unit: 'pcs',
    sellingPrice: 50,
    lowStockThreshold: 2,
  );
}

final class _RecordingRepository implements ProductRepository {
  Result<Product> updateResult = Success<Product>(_product());
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
  ) async {
    updateCalls++;
    lastId = id;
    lastUpdate = input;
    return updateResult;
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
