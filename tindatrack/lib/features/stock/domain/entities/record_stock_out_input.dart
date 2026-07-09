import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';

/// User-supplied values for recording removed stock.
///
/// Product snapshots, IDs, timestamps, and quantity deltas are resolved by the
/// repository from the current product row and injected infrastructure.
final class RecordStockOutInput {
  /// Creates a Stock Out request.
  const RecordStockOutInput({
    required this.productId,
    required this.quantity,
    this.reason,
    this.note,
  });

  /// Product identity to remove stock from.
  final String productId;

  /// Positive quantity to remove.
  final int quantity;

  /// Optional Stock Out reason before repository defaulting.
  final StockOutReason? reason;

  /// Optional note before repository normalization.
  final String? note;
}
