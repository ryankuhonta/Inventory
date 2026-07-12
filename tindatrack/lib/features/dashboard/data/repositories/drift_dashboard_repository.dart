import 'package:drift/drift.dart';
import 'package:tindatrack/core/database/app_database.dart';
import 'package:tindatrack/features/dashboard/domain/entities/dashboard_low_stock_preview_item.dart';
import 'package:tindatrack/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:tindatrack/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:tindatrack/features/products/domain/entities/product_stock_status.dart';

/// Drift-backed read model for Dashboard data.
final class DriftDashboardRepository implements DashboardRepository {
  /// Creates a dashboard repository attached to the app database.
  const DriftDashboardRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<List<DashboardLowStockPreviewItem>> watchLowStockPreview({
    int limit = dashboardLowStockPreviewLimit,
  }) {
    return _database
        .customSelect(
          '''
          SELECT id, name, quantity, unit
          FROM products
          WHERE is_archived = 0
            AND quantity <= low_stock_threshold
          ORDER BY
            CASE WHEN quantity = 0 THEN 0 ELSE 1 END ASC,
            name COLLATE NOCASE ASC
          LIMIT ?
          ''',
          variables: [Variable<int>(limit)],
          readsFrom: {_database.products},
        )
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => DashboardLowStockPreviewItem(
                  id: row.read<String>('id'),
                  name: row.read<String>('name'),
                  quantity: row.read<int>('quantity'),
                  unit: row.read<String>('unit'),
                  status: row.read<int>('quantity') == 0
                      ? ProductStockStatus.outOfStock
                      : ProductStockStatus.lowStock,
                ),
              )
              .toList(growable: false),
        );
  }

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
