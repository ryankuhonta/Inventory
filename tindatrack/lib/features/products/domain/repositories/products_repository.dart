import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/domain/entities/create_product_input.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/entities/product_list_query.dart';

/// Product catalog operations available to presentation code.
abstract interface class ProductRepository {
  /// Persists a new active product.
  Future<Result<Product>> createProduct(CreateProductInput input);

  /// Watches active products matching [query], ordered by name.
  Stream<List<Product>> watchActiveProducts(ProductListQuery query);
}
