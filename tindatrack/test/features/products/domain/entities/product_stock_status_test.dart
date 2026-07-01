import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/entities/product_stock_status.dart';

void main() {
  group('Product stock status', () {
    test('zero quantity overrides a zero threshold as out of stock', () {
      expect(
        _product(quantity: 0, threshold: 0).stockStatus,
        ProductStockStatus.outOfStock,
      );
    });

    test('zero quantity overrides a positive threshold as out of stock', () {
      expect(
        _product(quantity: 0, threshold: 5).stockStatus,
        ProductStockStatus.outOfStock,
      );
    });

    test('positive quantity equal to threshold is low stock', () {
      expect(
        _product(quantity: 3, threshold: 3).stockStatus,
        ProductStockStatus.lowStock,
      );
    });

    test('positive quantity below threshold is low stock', () {
      expect(
        _product(quantity: 2, threshold: 3).stockStatus,
        ProductStockStatus.lowStock,
      );
    });

    test('quantity above threshold is in stock', () {
      expect(
        _product(quantity: 4, threshold: 3).stockStatus,
        ProductStockStatus.inStock,
      );
    });

    test('positive quantity with zero threshold is in stock', () {
      expect(
        _product(quantity: 1, threshold: 0).stockStatus,
        ProductStockStatus.inStock,
      );
    });
  });
}

Product _product({required int quantity, required int threshold}) {
  return Product(
    id: 'product-1',
    name: 'Rice',
    category: null,
    unit: 'pcs',
    sellingPrice: 50,
    quantity: quantity,
    lowStockThreshold: threshold,
    barcode: null,
    isArchived: false,
    createdAt: DateTime.utc(2026, 7),
    updatedAt: DateTime.utc(2026, 7),
  );
}
