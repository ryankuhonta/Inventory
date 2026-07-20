import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/app/providers.dart';
import 'package:tindatrack/core/database/app_database.dart';
import 'package:tindatrack/core/database/daos/products_dao.dart';
import 'package:tindatrack/core/database/daos/stock_movements_dao.dart';
import 'package:tindatrack/core/time/clock.dart';
import 'package:tindatrack/features/dashboard/domain/entities/dashboard_low_stock_preview_item.dart';
import 'package:tindatrack/features/dashboard/domain/entities/dashboard_recent_activity_item.dart';
import 'package:tindatrack/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:tindatrack/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:tindatrack/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';

void main() {
  test('dashboard summary provider uses app database and clock', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final productsDao = ProductsDao(database);
    await productsDao.insertProduct(
      ProductsCompanion.insert(
        id: 'product-1',
        name: 'Rice',
        unit: 'kg',
        sellingPrice: 10,
        quantity: 1,
        lowStockThreshold: 2,
        createdAt: DateTime.utc(2026, 7),
        updatedAt: DateTime.utc(2026, 7),
      ),
    );
    final container = ProviderContainer.test(
      overrides: [
        databaseProvider.overrideWithValue(database),
        clockProvider.overrideWithValue(_FixedClock(DateTime(2026, 7, 11, 9))),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await database.close();
    });

    final subscription = container.listen(
      dashboardSummaryProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final summary = await container.read(dashboardSummaryProvider.future);

    expect(summary.totalActiveProducts, 1);
    expect(summary.lowStockProducts, 1);
    expect(summary.stockChangesToday, 0);
  });

  test('dashboard low-stock preview provider uses app database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final productsDao = ProductsDao(database);
    await productsDao.insertProduct(
      ProductsCompanion.insert(
        id: 'low-1',
        name: 'Rice',
        unit: 'kg',
        sellingPrice: 10,
        quantity: 1,
        lowStockThreshold: 2,
        createdAt: DateTime.utc(2026, 7),
        updatedAt: DateTime.utc(2026, 7),
      ),
    );
    final container = ProviderContainer.test(
      overrides: [
        databaseProvider.overrideWithValue(database),
        clockProvider.overrideWithValue(_FixedClock(DateTime(2026, 7, 11, 9))),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await database.close();
    });

    final subscription = container.listen(
      dashboardLowStockPreviewProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final preview = await container.read(
      dashboardLowStockPreviewProvider.future,
    );

    expect(preview, hasLength(1));
    expect(preview.single.name, 'Rice');
    expect(preview.single.quantity, 1);
    expect(preview.single.unit, 'kg');
    expect(preview.single.status.name, 'lowStock');
  });

  test('recent activity preview provider delegates to repository', () async {
    final item = DashboardRecentActivityItem(
      id: 'movement-1',
      type: StockMovementType.stockIn,
      quantity: 3,
      productNameSnapshot: 'Rice',
      unitSnapshot: 'kg',
      createdAt: DateTime.utc(2026, 7, 11, 9),
    );
    final repository = _RecordingDashboardRepository(
      recentActivityStream: Stream.value([item]),
    );
    final container = ProviderContainer.test(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final subscription = container.listen(
      dashboardRecentActivityPreviewProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final preview = await container.read(
      dashboardRecentActivityPreviewProvider.future,
    );

    expect(preview, [item]);
    expect(repository.recentActivityCalls, 1);
    expect(repository.summaryCalls, 0);
    expect(repository.lowStockPreviewCalls, 0);
  });

  test('dashboard summary provider refreshes after local midnight', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final productsDao = ProductsDao(database);
    final stockMovementsDao = StockMovementsDao(database);
    await productsDao.insertProduct(
      ProductsCompanion.insert(
        id: 'product-1',
        name: 'Rice',
        unit: 'kg',
        sellingPrice: 10,
        quantity: 5,
        lowStockThreshold: 2,
        createdAt: DateTime.utc(2026, 7),
        updatedAt: DateTime.utc(2026, 7),
      ),
    );
    final localStart = DateTime(2026, 7, 11);
    await _insertMovement(
      stockMovementsDao,
      'today-1',
      localStart.add(const Duration(hours: 10)).toUtc(),
    );
    await _insertMovement(
      stockMovementsDao,
      'today-2',
      localStart.add(const Duration(hours: 18)).toUtc(),
    );
    await _insertMovement(
      stockMovementsDao,
      'tomorrow-1',
      DateTime(2026, 7, 12, 1).toUtc(),
    );
    final clock = _MutableClock(DateTime(2026, 7, 11, 23, 59, 59, 950));
    final refreshTimers = _ManualRefreshTimers();
    final container = ProviderContainer.test(
      overrides: [
        databaseProvider.overrideWithValue(database),
        clockProvider.overrideWithValue(clock),
        dashboardSummaryRefreshTimerProvider.overrideWithValue(
          refreshTimers.start,
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await database.close();
    });

    final subscription = container.listen(
      dashboardSummaryProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final beforeMidnight = await container.read(
      dashboardSummaryProvider.future,
    );
    expect(beforeMidnight.stockChangesToday, 2);

    expect(refreshTimers.lastDuration, const Duration(milliseconds: 50));

    clock.instant = DateTime(2026, 7, 12, 0, 0, 0, 10);
    refreshTimers.fireLast();

    final afterMidnight = await container.read(dashboardSummaryProvider.future);
    expect(afterMidnight.stockChangesToday, 1);
  });
}

final class _ManualRefreshTimers {
  final _timers = <_ManualTimer>[];

  Duration get lastDuration => _timers.last.duration;

  Timer start(Duration duration, void Function() callback) {
    final timer = _ManualTimer(duration, callback);
    _timers.add(timer);
    return timer;
  }

  void fireLast() => _timers.last.fire();
}

final class _ManualTimer implements Timer {
  _ManualTimer(this.duration, this._callback);

  final Duration duration;
  void Function()? _callback;
  var _isActive = true;
  var _tick = 0;

  void fire() {
    if (!_isActive) return;
    _isActive = false;
    _tick = 1;
    final callback = _callback;
    _callback = null;
    callback?.call();
  }

  @override
  void cancel() {
    _isActive = false;
    _callback = null;
  }

  @override
  bool get isActive => _isActive;

  @override
  int get tick => _tick;
}

final class _FixedClock implements Clock {
  const _FixedClock(this.instant);

  final DateTime instant;

  @override
  DateTime now() => instant;
}

final class _MutableClock implements Clock {
  _MutableClock(this.instant);

  DateTime instant;

  @override
  DateTime now() => instant;
}

Future<void> _insertMovement(
  StockMovementsDao dao,
  String id,
  DateTime createdAt,
) {
  return dao.insertMovement(
    StockMovementsCompanion.insert(
      id: id,
      productId: 'product-1',
      type: 'stock_in',
      quantity: 1,
      previousQuantity: 5,
      newQuantity: 6,
      productNameSnapshot: 'Rice',
      unitSnapshot: 'kg',
      createdAt: createdAt,
    ),
  );
}

final class _RecordingDashboardRepository implements DashboardRepository {
  _RecordingDashboardRepository({required this.recentActivityStream});

  final Stream<List<DashboardRecentActivityItem>> recentActivityStream;
  int summaryCalls = 0;
  int lowStockPreviewCalls = 0;
  int recentActivityCalls = 0;

  @override
  Stream<DashboardSummary> watchSummary({required DateTime localNow}) {
    summaryCalls++;
    return Stream.value(
      const DashboardSummary(
        totalActiveProducts: 0,
        lowStockProducts: 0,
        stockChangesToday: 0,
      ),
    );
  }

  @override
  Stream<List<DashboardLowStockPreviewItem>> watchLowStockPreview({
    int limit = dashboardLowStockPreviewLimit,
  }) {
    lowStockPreviewCalls++;
    return Stream.value(const []);
  }

  @override
  Stream<List<DashboardRecentActivityItem>> watchRecentActivityPreview({
    int limit = dashboardRecentActivityPreviewLimit,
  }) {
    recentActivityCalls++;
    return recentActivityStream;
  }
}
