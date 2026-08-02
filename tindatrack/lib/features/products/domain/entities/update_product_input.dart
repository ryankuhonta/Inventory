/// User-supplied product details that may change after creation.
///
/// Stock quantity and persistence-owned fields are intentionally excluded.
final class UpdateProductInput {
  /// Creates an edit-only product input.
  const UpdateProductInput({
    required this.name,
    required this.unit,
    required this.sellingPrice,
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

  /// Selling price.
  final double sellingPrice;

  /// Quantity at or below which stock is low.
  final int lowStockThreshold;

  /// Optional barcode before repository normalization.
  final String? barcode;
}
