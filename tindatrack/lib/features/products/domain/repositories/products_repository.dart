import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/domain/entities/create_product_input.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/entities/product_list_query.dart';
import 'package:tindatrack/features/products/domain/entities/update_product_input.dart';

/// Product catalog operations available to presentation code.
abstract interface class ProductRepository {
  /// Soft-archives one active product without deleting its persisted row.
  Future<Result<void>> archiveProduct(String id);

  /// Persists a new active product.
  Future<Result<Product>> createProduct(CreateProductInput input);

  /// Loads one active product by stable ID or returns a typed unavailable
  /// failure.
  Future<Result<Product>> getProduct(String id);

  /// Restores one archived product to the active catalog.
  Future<Result<void>> restoreProduct(String id);

  /// Updates editable metadata without changing stock quantity.
  Future<Result<Product>> updateProduct(String id, UpdateProductInput input);

  /// Watches active products matching [query], ordered by name.
  Stream<List<Product>> watchActiveProducts(ProductListQuery query);

  /// Watches archived products ordered by name.
  Stream<List<Product>> watchArchivedProducts();
}
