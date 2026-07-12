import 'package:drift/drift.dart';
import 'package:tindatrack/core/database/app_database.dart';
import 'package:tindatrack/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:tindatrack/features/dashboard/domain/repositories/dashboard_repository.dart';

/// Drift-backed read model for Dashboard summary counts.
final class DriftDashboardRepository implements DashboardRepository {
  /// Creates a dashboard repository attached to the app database.
  const DriftDashboardRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<DashboardSummary> watchSummary({required DateTime localNow}) {
    final localStart = DateTime(localNow.year, localNow.month, localNow.day);
    final localEnd = DateTime(localNow.year, localNow.month, localNow.day + 1);
    final startUtc = localStart.toUtc();
    final endUtc = localEnd.toUtc();

    return _database
        .customSelect(
          '''
          SELECT
            (SELECT COUNT(*) FROM products WHERE is_archived = 0)
              AS total_active_products,
            (
              SELECT COUNT(*)
              FROM products
              WHERE is_archived = 0
                AND quantity <= low_stock_threshold
            ) AS low_stock_products,
            (
              SELECT COUNT(*)
              FROM stock_movements
              WHERE created_at >= ?
                AND created_at < ?
            ) AS stock_changes_today
          ''',
          variables: [
            Variable<DateTime>(startUtc),
            Variable<DateTime>(endUtc),
          ],
          readsFrom: {_database.products, _database.stockMovements},
        )
        .watchSingle()
        .map(
          (row) => DashboardSummary(
            totalActiveProducts: row.read<int>('total_active_products'),
            lowStockProducts: row.read<int>('low_stock_products'),
            stockChangesToday: row.read<int>('stock_changes_today'),
          ),
        );
  }
}
