import 'package:tindatrack/core/errors/app_failure.dart';

/// Stock movement input field associated with a validation failure.
enum StockMovementField {
  /// Quantity moved.
  quantity,

  /// Quantity before the movement.
  previousQuantity,

  /// Quantity after the movement.
  newQuantity,
}

/// Stable reason for rejecting a stock movement input field.
enum StockMovementValidationIssue {
  /// A quantity must be greater than zero.
  notPositive,

  /// A quantity must not be negative.
  negative,
}

/// Stock movement input failed domain validation before persistence.
final class StockMovementValidationFailure extends AppFailure {
  /// Creates a field-specific stock validation failure.
  const StockMovementValidationFailure({
    required this.field,
    required this.issue,
    super.debugMessage,
  });

  /// First invalid field in canonical validation order.
  final StockMovementField field;

  /// Stable reason the field was rejected.
  final StockMovementValidationIssue issue;
}

/// No product exists for the requested stock operation.
final class StockProductNotFoundFailure extends AppFailure {
  /// Creates a typed missing-product stock failure.
  const StockProductNotFoundFailure({super.debugMessage});
}

/// The requested product is archived and cannot receive stock changes.
final class StockArchivedProductFailure extends AppFailure {
  /// Creates a typed archived-product stock failure.
  const StockArchivedProductFailure({super.debugMessage});
}

/// Requested Stock Out quantity exceeds the available product quantity.
final class StockInsufficientQuantityFailure extends AppFailure {
  /// Creates a typed insufficient-stock failure.
  const StockInsufficientQuantityFailure({
    required this.availableQuantity,
    required this.requestedQuantity,
    super.debugMessage,
  });

  /// Product quantity available before the rejected Stock Out attempt.
  final int availableQuantity;

  /// User-requested quantity that exceeded available stock.
  final int requestedQuantity;
}
