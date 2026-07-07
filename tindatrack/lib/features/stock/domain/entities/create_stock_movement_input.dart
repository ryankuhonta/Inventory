import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';

/// User-supplied values required to create a stock movement row.
///
/// IDs and timestamps are owned by the repository. This input records audit
/// history only; product quantity mutation is owned by later stock stories.
final class CreateStockMovementInput {
  /// Creates stock movement input without persistence-generated fields.
  const CreateStockMovementInput({
    required this.productId,
    required this.type,
    required this.quantity,
    required this.previousQuantity,
    required this.newQuantity,
    required this.productNameSnapshot,
    required this.unitSnapshot,
    this.reason,
    this.note,
  });

  /// Product identity at movement time.
  final String productId;

  /// Direction of movement.
  final StockMovementType type;

  /// Positive quantity moved.
  final int quantity;

  /// Quantity before movement.
  final int previousQuantity;

  /// Quantity after movement.
  final int newQuantity;

  /// Optional Stock Out reason. Defaults to `sold` for Stock Out.
  final StockOutReason? reason;

  /// Optional note before repository normalization.
  final String? note;

  /// Product name copied at movement creation time.
  final String productNameSnapshot;

  /// Product unit copied at movement creation time.
  final String unitSnapshot;
}
