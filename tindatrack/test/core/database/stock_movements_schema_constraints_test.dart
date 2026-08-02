import 'package:drift/drift.dart' show Value, Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/database/app_database.dart';
import 'package:tindatrack/core/database/daos/products_dao.dart';
import 'package:tindatrack/core/database/daos/stock_movements_dao.dart';
import 'package:tindatrack/core/database/tables/stock_movements_table.dart';

void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await ProductsDao(database).insertProduct(_product());
  });

  tearDown(() => database.close());

  test('stock movements expose exact SQL columns and nullability', () async {
    final rows = await database
        .customSelect(
          'PRAGMA table_info(stock_movements)',
        )
        .get();
    final columns = {
      for (final row in rows)
        row.read<String>('name'): (
          type: row.read<String>('type'),
          notNull: row.read<int>('notnull'),
          defaultValue: row.readNullable<String>('dflt_value'),
          primaryKey: row.read<int>('pk'),
        ),
    };

    expect(columns.keys.toList(), [
      'id',
      'product_id',
      'type',
      'quantity',
      'previous_quantity',
      'new_quantity',
      'reason',
      'note',
      'product_name_snapshot',
      'unit_snapshot',
      'created_at',
    ]);
    expect(columns['id'], (
      type: 'TEXT',
      notNull: 1,
      defaultValue: null,
      primaryKey: 1,
    ));
    expect(columns['product_id']?.notNull, 1);
    expect(columns['type']?.notNull, 1);
    expect(columns['quantity']?.type, 'INTEGER');
    expect(columns['previous_quantity']?.type, 'INTEGER');
    expect(columns['new_quantity']?.type, 'INTEGER');
    expect(columns['reason']?.notNull, 0);
    expect(columns['note']?.notNull, 0);
    expect(columns['product_name_snapshot']?.notNull, 1);
    expect(columns['unit_snapshot']?.notNull, 1);
    expect(columns['created_at']?.type, 'INTEGER');
    expect(columns, isNot(contains('cost_price')));
  });

  test('history indexes support product-scoped newest-first queries', () async {
    final indexes = await database
        .customSelect(
          'PRAGMA index_list(stock_movements)',
        )
        .get();
    final indexNames = indexes.map((row) => row.read<String>('name')).toSet();

    expect(indexNames, contains('stock_movements_product_created_at_idx'));
    expect(indexNames, contains('stock_movements_created_at_idx'));
  });

  test('check constraints reject invalid persisted values', () async {
    await expectLater(
      insertRaw(database, type: 'adjustment'),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      insertRaw(database, reason: 'expired'),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      insertRaw(database, quantity: 0),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      insertRaw(database, previousQuantity: -1),
      throwsA(isA<SqliteException>()),
    );
    await expectLater(
      insertRaw(database, newQuantity: -1),
      throwsA(isA<SqliteException>()),
    );
  });

  test('foreign key enforcement rejects missing product references', () async {
    await expectLater(
      insertRaw(database, productId: 'missing-product'),
      throwsA(isA<SqliteException>()),
    );
  });

  test(
    'valid reason values persist and product reference does not cascade',
    () async {
      final dao = StockMovementsDao(database);

      for (final reason in stockOutReasons) {
        final row = await dao.insertMovement(
          _movement('movement-$reason', reason),
        );
        expect(row.reason, reason);
      }

      final foreignKeys = await database
          .customSelect(
            'PRAGMA foreign_key_list(stock_movements)',
          )
          .get();
      expect(foreignKeys.single.read<String>('table'), 'products');
      expect(foreignKeys.single.read<String>('from'), 'product_id');
      expect(foreignKeys.single.read<String>('to'), 'id');
      expect(foreignKeys.single.read<String>('on_delete'), 'NO ACTION');
    },
  );
}

Future<void> insertRaw(
  AppDatabase database, {
  String productId = 'product-1',
  String type = stockMovementTypeStockOut,
  String? reason = stockOutReasonSold,
  int quantity = 1,
  int previousQuantity = 2,
  int newQuantity = 1,
}) {
  return database.customInsert(
    'INSERT INTO stock_movements '
    '(id, product_id, type, quantity, previous_quantity, new_quantity, '
    'reason, product_name_snapshot, unit_snapshot, created_at) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    variables: [
      Variable.withString(
        'raw-$type-$reason-$quantity-$previousQuantity-$newQuantity',
      ),
      Variable.withString(productId),
      Variable.withString(type),
      Variable.withInt(quantity),
      Variable.withInt(previousQuantity),
      Variable.withInt(newQuantity),
      if (reason == null)
        const Variable<String>(null)
      else
        Variable.withString(reason),
      Variable.withString('Rice'),
      Variable.withString('kg'),
      Variable.withDateTime(DateTime.utc(2026, 7)),
    ],
  );
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

StockMovementsCompanion _movement(
  String id,
  String reason,
) {
  return StockMovementsCompanion.insert(
    id: id,
    productId: 'product-1',
    type: stockMovementTypeStockOut,
    quantity: 1,
    previousQuantity: 2,
    newQuantity: 1,
    reason: Value(reason),
    productNameSnapshot: 'Rice',
    unitSnapshot: 'kg',
    createdAt: DateTime.utc(2026, 7),
  );
}
