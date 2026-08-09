/// In-memory CSV files generated for one export request.
final class CsvExportBundle {
  /// Creates a CSV export bundle.
  const CsvExportBundle({
    required this.productsFileName,
    required this.productsCsv,
    required this.stockHistoryFileName,
    required this.stockHistoryCsv,
  });

  /// File name for product rows.
  final String productsFileName;

  /// CSV text for product rows.
  final String productsCsv;

  /// File name for stock movement history rows.
  final String stockHistoryFileName;

  /// CSV text for stock movement history rows.
  final String stockHistoryCsv;
}

/// User-facing summary of a completed CSV export handoff.
final class CsvExportSummary {
  /// Creates a CSV export summary.
  const CsvExportSummary({
    required this.productsFileName,
    required this.stockHistoryFileName,
  });

  /// File name for product rows.
  final String productsFileName;

  /// File name for stock movement history rows.
  final String stockHistoryFileName;
}
