import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/app/providers.dart';
import 'package:tindatrack/core/database/app_database.dart';
import 'package:tindatrack/core/database/daos/products_dao.dart';
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
}

final class _FixedClock implements Clock {
  const _FixedClock(this.instant);

  final DateTime instant;

  @override
  DateTime now() => instant;
}
