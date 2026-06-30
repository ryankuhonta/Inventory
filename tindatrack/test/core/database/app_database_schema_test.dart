import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('fresh database exposes the exact Story 2.1 products schema', () async {
    await database.ensureReady();

    expect(database.schemaVersion, 2);

    final columns = await database
        .customSelect(
          'PRAGMA table_info(products)',
        )
        .get();
    expect(
      columns.map((row) => row.read<String>('name')).toList(),
      [
        'id',
        'name',
        'category',
        'unit',
        'selling_price',
        'quantity',
        'low_stock_threshold',
        'barcode',
        'is_archived',
        'created_at',
        'updated_at',
      ],
    );

    final sqlRow = await database
        .customSelect(
          'SELECT sql FROM sqlite_master '
          "WHERE type = 'table' AND name = 'products'",
        )
        .getSingle();
    final createSql = sqlRow.read<String>('sql').toLowerCase();

    expect(createSql, contains('primary key'));
    expect(createSql, contains('unique'));
    expect(createSql, contains('"selling_price" >= 0.0'));
    expect(createSql, contains('"quantity" >= 0'));
    expect(createSql, contains('"low_stock_threshold" >= 0'));
    expect(createSql, isNot(contains('cost_price')));
  });

  test(
    'products schema has active-name index '
    'without duplicate barcode index',
    () async {
      await database.ensureReady();

      final indexes = await database
          .customSelect(
            'PRAGMA index_list(products)',
          )
          .get();
      final namedIndexes = indexes
          .map((row) => row.read<String>('name'))
          .where((name) => !name.startsWith('sqlite_autoindex'))
          .toList();

      expect(namedIndexes, ['products_active_name_idx']);
    },
  );
}
