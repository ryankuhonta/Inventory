/// Mutually exclusive stock states available to the active product list.
enum ProductStockFilter {
  /// Includes every active product.
  all,

  /// Includes active products with positive quantity at or below threshold.
  lowStock,

  /// Includes active products with zero quantity.
  outOfStock,
}

/// Immutable, normalized criteria for the active product list.
final class ProductListQuery {
  /// Creates criteria with normalized search text.
  ProductListQuery({
    String searchText = '',
    this.stockFilter = ProductStockFilter.all,
  }) : searchText = _normalizeSearchText(searchText);

  /// Default active-catalog criteria.
  const ProductListQuery.defaultQuery()
    : searchText = '',
      stockFilter = ProductStockFilter.all;

  /// Trimmed, ASCII-lowercased text matched against name or category.
  final String searchText;

  /// Selected mutually exclusive stock filter.
  final ProductStockFilter stockFilter;

  /// Whether these criteria represent the unfiltered active catalog.
  bool get isDefault =>
      searchText.isEmpty && stockFilter == ProductStockFilter.all;

  /// Returns criteria with selected fields replaced and normalization retained.
  ProductListQuery copyWith({
    String? searchText,
    ProductStockFilter? stockFilter,
  }) {
    return ProductListQuery(
      searchText: searchText ?? this.searchText,
      stockFilter: stockFilter ?? this.stockFilter,
    );
  }

  @override
  // This value object is immutable because every field is final.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProductListQuery &&
            searchText == other.searchText &&
            stockFilter == other.stockFilter;
  }

  @override
  // This value object is immutable because every field is final.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hash(searchText, stockFilter);
}

String _normalizeSearchText(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';

  final codeUnits = List<int>.of(trimmed.codeUnits);
  var changed = false;
  for (var index = 0; index < codeUnits.length; index++) {
    final codeUnit = codeUnits[index];
    if (codeUnit >= 65 && codeUnit <= 90) {
      codeUnits[index] = codeUnit + 32;
      changed = true;
    }
  }

  return changed ? String.fromCharCodes(codeUnits) : trimmed;
}
