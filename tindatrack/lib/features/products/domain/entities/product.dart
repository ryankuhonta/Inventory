/// Immutable product catalog entity exposed outside the data layer.
final class Product {
  /// Creates a persisted product entity.
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.sellingPrice,
    required this.quantity,
    required this.lowStockThreshold,
    required this.barcode,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Persisted ULID.
  final String id;

  /// Product display name.
  final String name;

  /// Optional product category.
  final String? category;

  /// Unit of measure.
  final String unit;

  /// Selling price.
  final double sellingPrice;

  /// Current on-hand quantity.
  final int quantity;

  /// Quantity at or below which stock is low.
  final int lowStockThreshold;

  /// Optional normalized barcode.
  final String? barcode;

  /// Whether the product is hidden from active catalog queries.
  final bool isArchived;

  /// UTC creation instant.
  final DateTime createdAt;

  /// UTC latest-update instant.
  final DateTime updatedAt;
}
