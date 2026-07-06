import 'package:tindatrack/core/errors/app_failure.dart';

/// A normalized non-null barcode already belongs to another product.
final class DuplicateBarcodeFailure extends AppFailure {
  /// Creates a typed duplicate-barcode failure.
  const DuplicateBarcodeFailure({super.debugMessage});
}

/// No product exists for the requested persistence identity.
final class ProductNotFoundFailure extends AppFailure {
  /// Creates a typed missing-product failure.
  const ProductNotFoundFailure({super.debugMessage});
}

/// The requested product is archived and cannot be edited.
final class ArchivedProductFailure extends AppFailure {
  /// Creates a typed archived-product failure.
  const ArchivedProductFailure({super.debugMessage});
}

/// Product form field associated with a validation failure.
enum ProductField {
  /// Product display name.
  name,

  /// Unit of measure.
  unit,

  /// Selling price.
  sellingPrice,

  /// Initial quantity.
  quantity,

  /// Low-stock threshold.
  lowStockThreshold,
}

/// Stable reason for rejecting a product input field.
enum ProductValidationIssue {
  /// A required value is blank.
  required,

  /// A number is not finite or cannot be represented safely.
  invalidNumber,

  /// A numeric value is below zero.
  negative,

  /// A quantity exceeds the configured practical maximum.
  tooLarge,
}

/// Product input failed domain validation before persistence.
final class ProductValidationFailure extends AppFailure {
  /// Creates a field-specific product validation failure.
  const ProductValidationFailure({
    required this.field,
    required this.issue,
    super.debugMessage,
  });

  /// First invalid field in canonical validation order.
  final ProductField field;

  /// Stable reason the field was rejected.
  final ProductValidationIssue issue;
}
