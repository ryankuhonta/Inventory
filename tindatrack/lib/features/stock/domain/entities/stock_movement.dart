const _stockMovementTypeStockIn = 'stock_in';
const _stockMovementTypeStockOut = 'stock_out';
const _stockOutReasonSold = 'sold';
const _stockOutReasonDamaged = 'damaged';
const _stockOutReasonLost = 'lost';
const _stockOutReasonPersonalUse = 'personal_use';
const _stockOutReasonCorrection = 'correction';

/// Direction of an inventory movement persisted in local history.
enum StockMovementType {
  /// Stock quantity increased.
  stockIn(_stockMovementTypeStockIn),

  /// Stock quantity decreased.
  stockOut(_stockMovementTypeStockOut);

  const StockMovementType(this.persistedValue);

  /// SQLite value for this movement type.
  final String persistedValue;

  /// Parses a persisted SQLite value.
  static StockMovementType fromPersistedValue(String value) {
    return switch (value) {
      _stockMovementTypeStockIn => StockMovementType.stockIn,
      _stockMovementTypeStockOut => StockMovementType.stockOut,
      _ => throw ArgumentError.value(value, 'value', 'Unknown stock type'),
    };
  }
}

/// Supported reasons for Stock Out movements.
enum StockOutReason {
  /// Item was sold to a customer.
  sold(_stockOutReasonSold),

  /// Item was damaged and removed from saleable stock.
  damaged(_stockOutReasonDamaged),

  /// Item was lost.
  lost(_stockOutReasonLost),

  /// Item was used by the owner or household.
  personalUse(_stockOutReasonPersonalUse),

  /// Manual inventory correction.
  correction(_stockOutReasonCorrection);

  const StockOutReason(this.persistedValue);

  /// SQLite value for this reason.
  final String persistedValue;

  /// Default reason used by MVP flows without a selector.
  static const StockOutReason defaultReason = StockOutReason.sold;

  /// Parses a persisted SQLite value.
  static StockOutReason fromPersistedValue(String value) {
    return switch (value) {
      _stockOutReasonSold => StockOutReason.sold,
      _stockOutReasonDamaged => StockOutReason.damaged,
      _stockOutReasonLost => StockOutReason.lost,
      _stockOutReasonPersonalUse => StockOutReason.personalUse,
      _stockOutReasonCorrection => StockOutReason.correction,
      _ => throw ArgumentError.value(value, 'value', 'Unknown stock reason'),
    };
  }
}

/// Immutable stock movement entity exposed outside the data layer.
final class StockMovement {
  /// Creates a persisted stock movement entity.
  const StockMovement({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.previousQuantity,
    required this.newQuantity,
    required this.reason,
    required this.note,
    required this.productNameSnapshot,
    required this.unitSnapshot,
    required this.createdAt,
  });

  /// Persisted ULID.
  final String id;

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

  /// Stock Out reason, if applicable.
  final StockOutReason? reason;

  /// Optional note.
  final String? note;

  /// Product name copied at movement creation time.
  final String productNameSnapshot;

  /// Product unit copied at movement creation time.
  final String unitSnapshot;

  /// UTC creation instant.
  final DateTime createdAt;
}
