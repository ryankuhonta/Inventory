import 'package:drift/drift.dart';
import 'package:tindatrack/core/database/app_database.dart';
import 'package:tindatrack/core/database/tables/products_table.dart';

part 'products_dao.g.dart';

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

  /// Watches active products, with filtering and ordering performed by SQLite.
  Stream<List<Product>> watchActiveProducts() {
    final query = select(products)
      ..where((product) => product.isArchived.equals(false))
      ..orderBy([(product) => OrderingTerm.asc(product.name)]);
    return query.watch();
  }
}
