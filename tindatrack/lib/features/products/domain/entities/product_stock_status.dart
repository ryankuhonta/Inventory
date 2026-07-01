import 'package:tindatrack/features/products/domain/entities/product.dart';

/// Mutually exclusive inventory attention state derived from current stock.
enum ProductStockStatus {
  /// Quantity is above the configured low-stock threshold.
  inStock,

  /// Quantity is positive and at or below the configured threshold.
  lowStock,

  /// Quantity is zero and takes precedence over low stock.
  outOfStock,
}

/// Derived stock status for an immutable product snapshot.
extension ProductStockStatusExtension on Product {
  /// Classifies current quantity without storing a separate status flag.
  ProductStockStatus get stockStatus {
    if (quantity == 0) return ProductStockStatus.outOfStock;
    if (quantity <= lowStockThreshold) return ProductStockStatus.lowStock;
    return ProductStockStatus.inStock;
  }
}
