import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';

/// Compact read model for recent stock movement rows on the Dashboard.
final class DashboardRecentActivityItem {
  /// Creates a dashboard recent activity preview item.
  const DashboardRecentActivityItem({
    required this.id,
    required this.type,
    required this.quantity,
    required this.productNameSnapshot,
    required this.unitSnapshot,
    required this.createdAt,
    this.note,
  });

  /// Persisted movement identity.
  final String id;

  /// Direction of the stock change.
  final StockMovementType type;

  /// Positive quantity moved.
  final int quantity;

  /// Product name captured at movement creation time.
  final String productNameSnapshot;

  /// Unit captured at movement creation time.
  final String unitSnapshot;

  /// Optional compact note preview source.
  final String? note;

  /// UTC creation instant.
  final DateTime createdAt;
}
