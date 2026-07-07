import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/database/app_database.dart';
import 'package:tindatrack/core/database/daos/products_dao.dart';
import 'package:tindatrack/core/database/daos/stock_movements_dao.dart';
import 'package:tindatrack/core/database/tables/stock_movements_table.dart';

void main() {
  late AppDatabase database;
  late StockMovementsDao dao;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await ProductsDao(database).insertProduct(_product());
    dao = StockMovementsDao(database);
  });

  tearDown(() => database.close());

  test('inserts movement rows and queries newest first', () async {
    await dao.insertMovement(_movement('older', DateTime.utc(2026, 7, 1, 8)));
    await dao.insertMovement(_movement('newer', DateTime.utc(2026, 7, 1, 9)));

    final rows = await dao.listMovements();

    expect(rows.map((row) => row.id), ['newer', 'older']);
  });

  test(
    'filters product-scoped history without exposing domain behavior',
    () async {
      await ProductsDao(database).insertProduct(_product(id: 'product-2'));
      await dao.insertMovement(_movement('first', DateTime.utc(2026, 7, 1, 8)));
      await dao.insertMovement(
        _movement('other', DateTime.utc(2026, 7, 1, 9), productId: 'product-2'),
      );

      final rows = await dao
          .watchMovements(
            const StockMovementHistoryQuery(productId: 'product-1'),
          )
          .first;

      expect(rows.map((row) => row.id), ['first']);
    },
  );
}

ProductsCompanion _product({String id = 'product-1'}) {
  final instant = DateTime.utc(2026, 7);
  return ProductsCompanion.insert(
    id: id,
    name: 'Rice',
    unit: 'kg',
    sellingPrice: 10,
    quantity: 5,
    lowStockThreshold: 1,
    createdAt: instant,
    updatedAt: instant,
  );
}

StockMovementsCompanion _movement(
  String id,
  DateTime createdAt, {
  String productId = 'product-1',
}) {
  return StockMovementsCompanion.insert(
    id: id,
    productId: productId,
    type: stockMovementTypeStockIn,
    quantity: 2,
    previousQuantity: 3,
    newQuantity: 5,
    note: const Value('Restock'),
    productNameSnapshot: 'Rice',
    unitSnapshot: 'kg',
    createdAt: createdAt,
  );
}
