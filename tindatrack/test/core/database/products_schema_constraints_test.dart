import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/database/app_database.dart';

void main() {
  test(
    'products columns expose exact SQL types, nullability, and defaults',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await database.ensureReady();

      final rows = await database
          .customSelect(
            'PRAGMA table_info(products)',
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

      expect(columns['id'], (
        type: 'TEXT',
        notNull: 1,
        defaultValue: null,
        primaryKey: 1,
      ));
      expect(columns['name']?.notNull, 1);
      expect(columns['category']?.notNull, 0);
      expect(columns['unit']?.notNull, 1);
      expect(columns['selling_price']?.type, 'REAL');
      expect(columns['quantity']?.type, 'INTEGER');
      expect(columns['low_stock_threshold']?.type, 'INTEGER');
      expect(columns['barcode']?.notNull, 0);
      expect(columns['is_archived']?.defaultValue, '0');
      expect(columns['created_at']?.type, 'INTEGER');
      expect(columns['updated_at']?.type, 'INTEGER');
      expect(columns, isNot(contains('cost_price')));
    },
  );

  test(
    'barcode has one SQLite-owned unique index and null remains nullable',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      await database.ensureReady();

      final indexes = await database
          .customSelect(
            'PRAGMA index_list(products)',
          )
          .get();
      var barcodeUniqueIndexes = 0;
      for (final index in indexes) {
        if (index.read<int>('unique') != 1) continue;
        final name = index.read<String>('name');
        final indexedColumns = await database
            .customSelect(
              'PRAGMA index_info("$name")',
            )
            .get();
        final columnNames = indexedColumns
            .map((row) => row.read<String>('name'))
            .toList();
        if (columnNames.length == 1 && columnNames.single == 'barcode') {
          barcodeUniqueIndexes++;
        }
      }

      expect(barcodeUniqueIndexes, 1);
    },
  );
}
