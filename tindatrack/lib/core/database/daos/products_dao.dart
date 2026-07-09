import 'package:drift/drift.dart';
import 'package:tindatrack/core/database/app_database.dart';
import 'package:tindatrack/core/database/tables/products_table.dart';

part 'products_dao.g.dart';

/// Persistence-only stock predicates for active product queries.
enum ProductsStockFilterParameter {
  /// Includes every active product.
  all,

  /// Includes positive quantities at or below their threshold.
  lowStock,

  /// Includes zero quantities.
  outOfStock,
}

/// Persistence-only parameters for the watched active product query.
final class ProductsQueryParameters {
  /// Creates SQLite query parameters.
  const ProductsQueryParameters({
    this.searchText = '',
    this.stockFilter = ProductsStockFilterParameter.all,
  });

  /// Trimmed text to match literally against name or category.
  final String searchText;

  /// Stock predicate to apply.
  final ProductsStockFilterParameter stockFilter;
}

/// Persistence-only access to product catalog rows.
@DriftAccessor(tables: [Products])
class ProductsDao extends DatabaseAccessor<AppDatabase>
    with _$ProductsDaoMixin {
  /// Creates a product DAO attached to [attachedDatabase].
  ProductsDao(super.attachedDatabase);

  /// Inserts one product and returns the persisted row.
  Future<Product> insertProduct(ProductsCompanion product) {
    return into(products).insertReturning(product);
  }

  /// Loads one product by stable ID, including archived rows.
  Future<Product?> getProductById(String id) {
    return (select(
      products,
    )..where((product) => product.id.equals(id))).getSingleOrNull();
  }

  /// Updates one active product quantity and returns the persisted row.
  Future<Product?> updateActiveProductQuantity({
    required String id,
    required int quantity,
    required DateTime updatedAt,
  }) async {
    final rows =
        await (update(products)..where(
              (product) =>
                  product.id.equals(id) & product.isArchived.equals(false),
            ))
            .writeReturning(
              ProductsCompanion(
                quantity: Value(quantity),
                updatedAt: Value(updatedAt),
              ),
            );
    return rows.isEmpty ? null : rows.single;
  }

  /// Marks one active product archived without replacing its row.
  Future<bool> archiveProduct({
    required String id,
    required DateTime updatedAt,
  }) async {
    final changed =
        await (update(products)..where(
              (product) =>
                  product.id.equals(id) & product.isArchived.equals(false),
            ))
            .write(
              ProductsCompanion(
                isArchived: const Value(true),
                updatedAt: Value(updatedAt),
              ),
            );
    return changed == 1;
  }

  /// Partially updates editable details for one active product.
  Future<Product?> updateProductDetails({
    required String id,
    required String name,
    required String? category,
    required String unit,
    required double sellingPrice,
    required int lowStockThreshold,
    required String? barcode,
    required DateTime updatedAt,
  }) async {
    final details = ProductsCompanion(
      name: Value(name),
      category: Value(category),
      unit: Value(unit),
      sellingPrice: Value(sellingPrice),
      lowStockThreshold: Value(lowStockThreshold),
      barcode: Value(barcode),
      updatedAt: Value(updatedAt),
    );
    final rows =
        await (update(products)..where(
              (product) =>
                  product.id.equals(id) & product.isArchived.equals(false),
            ))
            .writeReturning(details);
    return rows.isEmpty ? null : rows.single;
  }

  /// Watches active products filtered and ordered by SQLite.
  Stream<List<Product>> watchActiveProducts([
    ProductsQueryParameters parameters = const ProductsQueryParameters(),
  ]) {
    final searchText = parameters.searchText.trim();
    final query = select(products)
      ..where((product) {
        var predicate = product.isArchived.equals(false);

        if (searchText.contains('\u0000')) {
          // SQLite LIKE treats NUL as a terminator, which can broaden matches.
          predicate = predicate & const Constant(false);
        } else if (searchText.isNotEmpty) {
          final escapedSearch = _escapeLikeLiteral(searchText);
          final pattern = '%$escapedSearch%';
          final textMatches =
              product.name.like(pattern, escapeChar: r'\') |
              product.category.like(pattern, escapeChar: r'\');
          predicate = predicate & textMatches;
        }

        final stockMatches = switch (parameters.stockFilter) {
          ProductsStockFilterParameter.all => const Constant(true),
          ProductsStockFilterParameter.lowStock =>
            product.quantity.isBiggerThanValue(0) &
                product.quantity.isSmallerOrEqual(
                  product.lowStockThreshold,
                ),
          ProductsStockFilterParameter.outOfStock => product.quantity.equals(0),
        };

        return predicate & stockMatches;
      })
      ..orderBy([(product) => OrderingTerm.asc(product.name)]);
    return query.watch();
  }

  String _escapeLikeLiteral(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
  }
}
