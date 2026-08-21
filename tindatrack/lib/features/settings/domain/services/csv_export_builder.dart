import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/settings/domain/entities/csv_export_bundle.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';

/// Builds readable CSV exports for local inventory data.
final class CsvExportBuilder {
  /// Creates a CSV export builder.
  const CsvExportBuilder();

  /// Builds Products and Stock History CSV files for [exportedAt].
  CsvExportBundle build({
    required List<Product> products,
    required List<StockMovement> movements,
    required DateTime exportedAt,
  }) {
    final timestamp = _fileTimestamp(exportedAt);
    return CsvExportBundle(
      productsFileName: 'tindatrack-products-$timestamp.csv',
      productsCsv: _productsCsv(products),
      stockHistoryFileName: 'tindatrack-stock-history-$timestamp.csv',
      stockHistoryCsv: _stockHistoryCsv(movements),
    );
  }

  String _productsCsv(List<Product> products) {
    return _csv([
      [
        'Product ID',
        'Product Name',
        'Category',
        'Unit',
        'Selling Price',
        'Current Quantity',
        'Low Stock Threshold',
        'Barcode',
        'Status',
        'Created At',
        'Updated At',
      ],
      for (final product in products)
        [
          product.id,
          product.name,
          product.category ?? '',
          product.unit,
          product.sellingPrice.toStringAsFixed(2),
          product.quantity.toString(),
          product.lowStockThreshold.toString(),
          product.barcode ?? '',
          _productStatus(product),
          _displayDateTime(product.createdAt),
          _displayDateTime(product.updatedAt),
        ],
    ]);
  }

  String _productStatus(Product product) {
    return product.isArchived ? 'Archived' : 'Active';
  }

  String _stockHistoryCsv(List<StockMovement> movements) {
    return _csv([
      [
        'Movement ID',
        'Product ID',
        'Date',
        'Type',
        'Reason',
        'Product Name Snapshot',
        'Quantity',
        'Previous Quantity',
        'New Quantity',
        'Unit Snapshot',
        'Note',
      ],
      for (final movement in movements)
        [
          movement.id,
          movement.productId,
          _displayDateTime(movement.createdAt),
          _movementTypeLabel(movement.type),
          _stockOutReasonLabel(movement.reason),
          movement.productNameSnapshot,
          movement.quantity.toString(),
          movement.previousQuantity.toString(),
          movement.newQuantity.toString(),
          movement.unitSnapshot,
          movement.note ?? '',
        ],
    ]);
  }

  String _csv(List<List<String>> rows) {
    return '${rows.map((row) => row.map(_escapeCell).join(',')).join('\n')}\n';
  }

  String _escapeCell(String value) {
    final needsQuotes =
        value.contains(',') || value.contains('"') || value.contains('\n');
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }

  String _movementTypeLabel(StockMovementType type) {
    return switch (type) {
      StockMovementType.stockIn => 'Stock In',
      StockMovementType.stockOut => 'Stock Out',
    };
  }

  String _stockOutReasonLabel(StockOutReason? reason) {
    return switch (reason) {
      StockOutReason.sold => 'Sold',
      StockOutReason.damaged => 'Damaged',
      StockOutReason.lost => 'Lost',
      StockOutReason.personalUse => 'Personal Use',
      StockOutReason.correction => 'Correction',
      null => '',
    };
  }

  String _displayDateTime(DateTime value) {
    final utc = value.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')} '
        '${utc.hour.toString().padLeft(2, '0')}:'
        '${utc.minute.toString().padLeft(2, '0')}:'
        '${utc.second.toString().padLeft(2, '0')} UTC';
  }

  String _fileTimestamp(DateTime value) {
    final utc = value.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}'
        '${utc.month.toString().padLeft(2, '0')}'
        '${utc.day.toString().padLeft(2, '0')}-'
        '${utc.hour.toString().padLeft(2, '0')}'
        '${utc.minute.toString().padLeft(2, '0')}';
  }
}
