import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/repositories/products_repository.dart';

/// Loads one product by its stable persistence identity.
final class GetProduct {
  /// Creates the lookup use case over the canonical repository.
  const GetProduct(this._repository);

  final ProductRepository _repository;

  /// Loads the product or returns a typed failure.
  Future<Result<Product>> call(String productId) {
    return _repository.getProduct(productId);
  }
}
