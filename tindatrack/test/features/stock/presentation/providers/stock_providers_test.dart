import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/app/providers.dart';
import 'package:tindatrack/core/database/app_database.dart' hide StockMovement;
import 'package:tindatrack/core/database/daos/products_dao.dart';
import 'package:tindatrack/core/database/daos/stock_movements_dao.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/core/id/id_generator.dart';
import 'package:tindatrack/core/time/clock.dart';
import 'package:tindatrack/features/stock/domain/entities/create_stock_movement_input.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';
import 'package:tindatrack/features/stock/presentation/providers/stock_providers.dart';

void main() {
  test('provider-composed repository persists through app database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    await ProductsDao(database).insertProduct(_product());
    final container = ProviderContainer.test(
      overrides: [
        databaseProvider.overrideWithValue(database),
        idGeneratorProvider.overrideWithValue(const _FixedIdGenerator()),
        clockProvider.overrideWithValue(
          _FixedClock(DateTime.utc(2026, 7, 1, 6, 30)),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await database.close();
    });

    final result = await container
        .read(stockRepositoryProvider)
        .recordMovementRow(
          const CreateStockMovementInput(
            productId: 'product-1',
            type: StockMovementType.stockOut,
            quantity: 1,
            previousQuantity: 5,
            newQuantity: 4,
            productNameSnapshot: 'Rice',
            unitSnapshot: 'kg',
          ),
        );
    final rows = await StockMovementsDao(database).listMovements();

    expect(result, isA<Success<StockMovement>>());
    expect(rows.single.id, 'fixed-movement-id');
    expect(rows.single.reason, 'sold');
    expect(rows.single.createdAt.toUtc(), DateTime.utc(2026, 7, 1, 6, 30));
  });

  test('stock movement DAO provider uses the app database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer.test(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(() async {
      container.dispose();
      await database.close();
    });

    final dao = container.read(stockMovementsDaoProvider);

    expect(dao.attachedDatabase, same(database));
  });
}

ProductsCompanion _product() {
  final instant = DateTime.utc(2026, 7);
  return ProductsCompanion.insert(
    id: 'product-1',
    name: 'Rice',
    unit: 'kg',
    sellingPrice: 10,
    quantity: 5,
    lowStockThreshold: 1,
    createdAt: instant,
    updatedAt: instant,
  );
}

final class _FixedIdGenerator implements IdGenerator {
  const _FixedIdGenerator();

  @override
  String generate() => 'fixed-movement-id';
}

final class _FixedClock implements Clock {
  const _FixedClock(this.instant);

  final DateTime instant;

  @override
  DateTime now() => instant;
}
