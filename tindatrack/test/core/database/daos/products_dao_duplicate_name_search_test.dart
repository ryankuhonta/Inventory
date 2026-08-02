import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/database/app_database.dart';
import 'package:tindatrack/core/database/daos/products_dao.dart';

void main() {
  test('search preserves distinct products with duplicate names', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final dao = ProductsDao(database);
    final instant = DateTime.utc(2026, 7);

    for (final id in ['1', '2']) {
      await dao.insertProduct(
        ProductsCompanion.insert(
          id: id,
          name: 'Rice',
          category: const Value(null),
          unit: 'kg',
          sellingPrice: 60,
          quantity: 1,
          lowStockThreshold: 2,
          createdAt: instant,
          updatedAt: instant,
        ),
      );
    }

    final rows = await dao
        .watchActiveProducts(
          const ProductsQueryParameters(searchText: 'rice'),
        )
        .first;

    expect(rows.map((row) => row.id), unorderedEquals(['1', '2']));
    expect(rows.map((row) => row.name), ['Rice', 'Rice']);
  });
}
