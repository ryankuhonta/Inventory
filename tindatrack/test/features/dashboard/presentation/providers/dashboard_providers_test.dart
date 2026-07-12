import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/app/providers.dart';
import 'package:tindatrack/core/database/app_database.dart';
import 'package:tindatrack/core/database/daos/products_dao.dart';
import 'package:tindatrack/core/database/daos/stock_movements_dao.dart';
import 'package:tindatrack/core/time/clock.dart';
import 'package:tindatrack/features/dashboard/presentation/providers/dashboard_providers.dart';

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
    final container = ProviderContainer.test(
      overrides: [
        databaseProvider.overrideWithValue(database),
        clockProvider.overrideWithValue(clock),
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

    clock.instant = DateTime(2026, 7, 12, 0, 0, 0, 10);
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final afterMidnight = await container.read(dashboardSummaryProvider.future);
    expect(afterMidnight.stockChangesToday, 1);
  });
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
