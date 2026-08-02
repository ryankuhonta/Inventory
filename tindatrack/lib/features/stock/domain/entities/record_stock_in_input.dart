/// User-supplied values for recording added stock.
///
/// Product snapshots, IDs, timestamps, and quantity deltas are resolved by the
/// repository from the current product row and injected infrastructure.
final class RecordStockInInput {
  /// Creates a Stock In request.
  const RecordStockInInput({
    required this.productId,
    required this.quantity,
    this.note,
  });

  /// Product identity to receive stock.
  final String productId;

  /// Positive quantity to add.
  final int quantity;

  /// Optional note before repository normalization.
  final String? note;
}
