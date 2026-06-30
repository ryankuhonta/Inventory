import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/domain/entities/create_product_input.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/failures/product_failure.dart';
import 'package:tindatrack/features/products/domain/repositories/products_repository.dart';

void main() {
  test('Product is an immutable Drift-independent catalog entity', () {
    final createdAt = DateTime.utc(2026, 6, 28, 1);
    final updatedAt = DateTime.utc(2026, 6, 28, 2);
    final product = Product(
      id: '01JPRODUCT0000000000000000',
      name: 'Rice',
      category: 'Staples',
      unit: 'kg',
      sellingPrice: 60,
      quantity: 10,
      lowStockThreshold: 2,
      barcode: '123',
      isArchived: false,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    expect(product.id, '01JPRODUCT0000000000000000');
    expect(product.name, 'Rice');
    expect(product.category, 'Staples');
    expect(product.unit, 'kg');
    expect(product.sellingPrice, 60);
    expect(product.quantity, 10);
    expect(product.lowStockThreshold, 2);
    expect(product.barcode, '123');
    expect(product.isArchived, isFalse);
    expect(product.createdAt, createdAt);
    expect(product.updatedAt, updatedAt);
  });

  test('CreateProductInput contains no generated persistence fields', () {
    const input = CreateProductInput(
      name: 'Rice',
      unit: 'kg',
      sellingPrice: 60,
      quantity: 10,
      lowStockThreshold: 2,
    );

    expect(input.name, 'Rice');
    expect(input.category, isNull);
    expect(input.unit, 'kg');
    expect(input.sellingPrice, 60);
    expect(input.quantity, 10);
    expect(input.lowStockThreshold, 2);
    expect(input.barcode, isNull);
  });

  test('DuplicateBarcodeFailure is feature-owned and typed', () {
    const failure = DuplicateBarcodeFailure(debugMessage: 'duplicate');

    expect(failure, isA<AppFailure>());
    expect(failure.debugMessage, 'duplicate');
  });

  test(
    'repository contract uses the canonical Result and domain entities',
    () async {
      final repository = _FakeProductRepository();
      const input = CreateProductInput(
        name: 'Rice',
        unit: 'kg',
        sellingPrice: 60,
        quantity: 10,
        lowStockThreshold: 2,
      );

      expect(await repository.createProduct(input), isA<Result<Product>>());
      expect(repository.watchActiveProducts(), emits(isA<List<Product>>()));
    },
  );
}

final class _FakeProductRepository implements ProductRepository {
  @override
  Future<Result<Product>> createProduct(CreateProductInput input) async {
    return Success<Product>(
      Product(
        id: 'fixed-id',
        name: input.name,
        category: input.category,
        unit: input.unit,
        sellingPrice: input.sellingPrice,
        quantity: input.quantity,
        lowStockThreshold: input.lowStockThreshold,
        barcode: input.barcode,
        isArchived: false,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
  }

  @override
  Stream<List<Product>> watchActiveProducts() {
    return Stream.value(const <Product>[]);
  }
}
