import 'package:tindatrack/features/products/domain/entities/product_stock_status.dart';

/// Compact product snapshot shown in the dashboard restocking preview.
final class DashboardLowStockPreviewItem {
  /// Creates a read-only dashboard preview item.
  const DashboardLowStockPreviewItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.status,
  });

  /// Stable product id for keys and future navigation.
  final String id;

  /// Product display name.
  final String name;

  /// Current on-hand quantity.
  final int quantity;

  /// Unit of measure.
  final String unit;

  /// Derived stock status. Only low/out-of-stock rows should be previewed.
  final ProductStockStatus status;
}
