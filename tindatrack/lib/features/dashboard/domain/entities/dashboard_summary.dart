/// Read-only inventory totals shown by the Dashboard.
final class DashboardSummary {
  /// Creates dashboard summary counts.
  const DashboardSummary({
    required this.totalActiveProducts,
    required this.lowStockProducts,
    required this.stockChangesToday,
  });

  /// Number of non-archived products.
  final int totalActiveProducts;

  /// Number of active products needing attention, including out-of-stock rows.
  final int lowStockProducts;

  /// Number of stock movement rows in the current local day.
  final int stockChangesToday;
}
