import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/database/app_database.dart';

import '../../generated_migrations/schema.dart';

void main() {
  test('fresh schema v3 matches the generated schema snapshot', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.ensureReady();
    await database.validateDatabaseSchema();
  });

  test('real empty schema v1 migrates to equivalent schema v3', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final connection = await verifier.startAt(1);
    final database = AppDatabase(connection);
    addTearDown(database.close);

    await verifier.migrateAndValidate(database, 3);
  });

  test(
    'real schema v2 migrates to equivalent schema v3 '
    'and preserves product rows',
    () async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final schema = await verifier.schemaAt(2);
      addTearDown(schema.close);

      schema.rawDatabase.execute(
        'INSERT INTO products '
        '(id, name, category, unit, selling_price, quantity, '
        'low_stock_threshold, barcode, is_archived, created_at, updated_at) '
        "VALUES ('product-1', 'Rice', 'Staples', 'kg', 10.5, 7, 2, "
        'NULL, 0, 1782864000000, 1782864000000)',
      );

      final database = AppDatabase(schema.newConnection());
      addTearDown(database.close);

      await verifier.migrateAndValidate(database, 3);

      final product = await database
          .customSelect("SELECT * FROM products WHERE id = 'product-1'")
          .getSingle();
      expect(product.read<String>('name'), 'Rice');
      expect(product.readNullable<String>('category'), 'Staples');
      expect(product.read<String>('unit'), 'kg');
      expect(product.read<double>('selling_price'), 10.5);
      expect(product.read<int>('quantity'), 7);
      expect(product.read<int>('low_stock_threshold'), 2);
      expect(product.read<int>('is_archived'), 0);
    },
  );
}
