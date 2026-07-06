import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/domain/repositories/products_repository.dart';

/// Soft-archives one active product by stable persistence identity.
final class ArchiveProduct {
  /// Creates the archive use case over the canonical repository.
  const ArchiveProduct(this._repository);

  final ProductRepository _repository;

  /// Archives the product without deleting it or changing stock.
  Future<Result<void>> call(String productId) {
    return _repository.archiveProduct(productId);
  }
}
