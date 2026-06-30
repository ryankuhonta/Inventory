/// User-supplied values required to create a product.
///
/// IDs, timestamps, and archive state are owned by the repository.
final class CreateProductInput {
  /// Creates product input without persistence-generated fields.
  const CreateProductInput({
    required this.name,
    required this.unit,
    required this.sellingPrice,
    required this.quantity,
    required this.lowStockThreshold,
    this.category,
    this.barcode,
  });

  /// Product display name.
  final String name;

  /// Optional product category.
  final String? category;

  /// Unit of measure.
  final String unit;

  /// Initial selling price.
  final double sellingPrice;

  /// Initial on-hand quantity.
  final int quantity;

  /// Initial low-stock threshold.
  final int lowStockThreshold;

  /// Optional barcode before repository normalization.
  final String? barcode;
}
