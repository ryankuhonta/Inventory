/// Parsed, validated product rows waiting to be imported from CSV.
final class CsvImportPreview {
  /// Creates an import preview.
  const CsvImportPreview({
    required this.rows,
    required this.errors,
  });

  /// Rows that passed row-level parsing and validation.
  final List<CsvImportProductRow> rows;

  /// Blocking preview errors. Import is allowed only when empty.
  final List<CsvImportError> errors;

  /// Number of valid rows in the CSV.
  int get rowCount => rows.length;

  /// Number of valid active rows.
  int get activeCount => rows.where((row) => !row.isArchived).length;

  /// Number of valid archived rows.
  int get archivedCount => rows.where((row) => row.isArchived).length;

  /// Whether this preview can be applied.
  bool get canImport => rows.isNotEmpty && errors.isEmpty;
}

/// One product row normalized from the Products CSV.
final class CsvImportProductRow {
  /// Creates a normalized product import row.
  const CsvImportProductRow({
    required this.sourceRowNumber,
    required this.name,
    required this.unit,
    required this.sellingPrice,
    required this.quantity,
    required this.lowStockThreshold,
    required this.isArchived,
    this.category,
    this.barcode,
  });

  /// One-based CSV row number including the header row.
  final int sourceRowNumber;

  /// Product display name.
  final String name;

  /// Optional category.
  final String? category;

  /// Unit of measure.
  final String unit;

  /// Selling price.
  final double sellingPrice;

  /// Current quantity to restore.
  final int quantity;

  /// Low-stock threshold.
  final int lowStockThreshold;

  /// Optional normalized barcode.
  final String? barcode;

  /// Whether the imported row should remain archived.
  final bool isArchived;
}

/// Blocking import preview error.
final class CsvImportError {
  /// Creates an import error.
  const CsvImportError({
    required this.rowNumber,
    required this.message,
  });

  /// One-based CSV row number. Use 0 for file-level errors.
  final int rowNumber;

  /// Safe user-facing error text.
  final String message;
}

/// Summary returned after applying a valid import.
final class CsvImportSummary {
  /// Creates an import summary.
  const CsvImportSummary({
    required this.importedCount,
    required this.activeCount,
    required this.archivedCount,
  });

  /// Total products imported.
  final int importedCount;

  /// Active products imported.
  final int activeCount;

  /// Archived products imported.
  final int archivedCount;
}
