import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/entities/update_product_input.dart';
import 'package:tindatrack/features/products/domain/repositories/products_repository.dart';
import 'package:tindatrack/features/products/domain/validation/product_validator.dart';

/// Validates, normalizes, and persists editable product details.
final class UpdateProduct {
  /// Creates the update use case over the canonical repository.
  const UpdateProduct(this._repository);

  final ProductRepository _repository;

  /// Updates metadata without exposing stock quantity to the write boundary.
  Future<Result<Product>> call(
    String productId,
    UpdateProductInput input,
  ) {
    const validator = ProductValidator();
    final normalized = validator.normalizeUpdate(input);
    final failure = validator.validateUpdate(normalized);
    if (failure != null) {
      return Future<Result<Product>>.value(
        FailureResult<Product>(failure),
      );
    }
    return _repository.updateProduct(productId, normalized);
  }
}
