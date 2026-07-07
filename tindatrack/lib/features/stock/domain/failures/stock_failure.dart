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
