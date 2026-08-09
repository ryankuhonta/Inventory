import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/domain/repositories/products_repository.dart';

/// Restores one archived product by stable persistence identity.
final class RestoreProduct {
  /// Creates the restore use case over the canonical repository.
  const RestoreProduct(this._repository);

  final ProductRepository _repository;

  /// Restores the product without changing stock or history.
  Future<Result<void>> call(String productId) {
    return _repository.restoreProduct(productId);
  }
}
