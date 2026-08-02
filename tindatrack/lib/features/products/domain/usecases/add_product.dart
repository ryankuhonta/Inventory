import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/domain/entities/create_product_input.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/repositories/products_repository.dart';
import 'package:tindatrack/features/products/domain/validation/product_validator.dart';

/// Validates, normalizes, and persists a new product.
final class AddProduct {
  /// Creates the use case over the canonical product repository.
  const AddProduct(this._repository);

  final ProductRepository _repository;

  /// Runs product creation through the validated repository boundary.
  Future<Result<Product>> call(CreateProductInput input) {
    const validator = ProductValidator();
    final normalized = validator.normalize(input);
    final failure = validator.validate(normalized);
    if (failure != null) {
      return Future<Result<Product>>.value(
        FailureResult<Product>(failure),
      );
    }
    return _repository.createProduct(normalized);
  }
}
