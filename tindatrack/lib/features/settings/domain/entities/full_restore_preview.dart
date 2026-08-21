import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';

/// Cross-file validation result for a full local backup restore.
final class FullRestorePreview {
  /// Creates a full restore preview.
  const FullRestorePreview({
    required this.products,
    required this.movements,
    required this.errors,
  });

  /// Valid product rows parsed from the selected Products CSV.
  final List<FullRestoreProductRow> products;

  /// Valid movement rows parsed from the selected Stock History CSV.
  final List<FullRestoreMovementRow> movements;

  /// Blocking validation errors from either selected CSV file.
  final List<FullRestoreError> errors;

  /// Number of valid product rows.
  int get productCount => products.length;

  /// Number of valid active product rows.
  int get activeProductCount => products.where((row) => !row.isArchived).length;

  /// Number of valid archived product rows.
  int get archivedProductCount =>
      products.where((row) => row.isArchived).length;

  /// Number of valid stock movement rows.
  int get movementCount => movements.length;

  /// Whether this preview can be restored later by the persistence layer.
  bool get canRestore => products.isNotEmpty && errors.isEmpty;
}

/// One normalized product row from a restorable Products CSV.
final class FullRestoreProductRow {
  /// Creates a full-restore product row.
  const FullRestoreProductRow({
    required this.sourceRowNumber,
    required this.id,
    required this.name,
    required this.unit,
    required this.sellingPrice,
    required this.quantity,
    required this.lowStockThreshold,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.barcode,
  });

  /// One-based CSV row number including the header row.
  final int sourceRowNumber;

  /// Product ID from the backup file.
  final String id;

  /// Product display name.
  final String name;

  /// Optional category.
  final String? category;

  /// Unit of measure.
  final String unit;

  /// Selling price.
  final double sellingPrice;

  /// Current quantity.
  final int quantity;

  /// Low-stock threshold.
  final int lowStockThreshold;

  /// Optional normalized barcode.
  final String? barcode;

  /// Whether the restored row is archived.
  final bool isArchived;

  /// Original creation timestamp from the backup.
  final DateTime createdAt;

  /// Original latest-update timestamp from the backup.
  final DateTime updatedAt;
}

/// One normalized movement row from a restorable Stock History CSV.
final class FullRestoreMovementRow {
  /// Creates a full-restore stock movement row.
  const FullRestoreMovementRow({
    required this.sourceRowNumber,
    required this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.previousQuantity,
    required this.newQuantity,
    required this.productNameSnapshot,
    required this.unitSnapshot,
    required this.createdAt,
    this.reason,
    this.note,
  });

  /// One-based CSV row number including the header row.
  final int sourceRowNumber;

  /// Movement ID from the backup file.
  final String id;

  /// Product ID referenced by this movement.
  final String productId;

  /// Direction of the movement.
  final StockMovementType type;

  /// Positive quantity moved.
  final int quantity;

  /// Quantity before movement.
  final int previousQuantity;

  /// Quantity after movement.
  final int newQuantity;

  /// Optional stock-out reason.
  final StockOutReason? reason;

  /// Optional note.
  final String? note;

  /// Product name copied at movement creation time.
  final String productNameSnapshot;

  /// Product unit copied at movement creation time.
  final String unitSnapshot;

  /// Original movement timestamp from the backup.
  final DateTime createdAt;
}

/// Blocking full-restore preview error.
final class FullRestoreError {
  /// Creates a full-restore preview error.
  const FullRestoreError({
    required this.fileName,
    required this.rowNumber,
    required this.message,
  });

  /// User-facing source file label.
  final String fileName;

  /// One-based CSV row number. Use 0 for file-level errors.
  final int rowNumber;

  /// Safe user-facing error text.
  final String message;
}
