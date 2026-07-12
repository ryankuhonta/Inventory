import 'package:tindatrack/features/dashboard/domain/entities/dashboard_low_stock_preview_item.dart';
import 'package:tindatrack/features/dashboard/domain/entities/dashboard_summary.dart';

/// Maximum number of restocking preview rows shown on the Dashboard.
const dashboardLowStockPreviewLimit = 3;

/// Read-only dashboard data boundary.
abstract interface class DashboardRepository {
  /// Watches dashboard counts for the local day containing [localNow].
  Stream<DashboardSummary> watchSummary({
    required DateTime localNow,
  });

  /// Watches a compact list of active products that need restocking.
  Stream<List<DashboardLowStockPreviewItem>> watchLowStockPreview({
    int limit = dashboardLowStockPreviewLimit,
  });
}
