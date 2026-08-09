import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/database/app_database.dart';
import 'package:tindatrack/core/database/daos/products_dao.dart';

void main() {
  late AppDatabase database;
  late ProductsDao dao;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    dao = ProductsDao(database);
  });

  tearDown(() => database.close());

  test('active query filters in SQL and orders by name ascending', () async {
    await dao.insertProduct(_product('3', 'Zinc', isArchived: false));
    await dao.insertProduct(_product('2', 'Hidden', isArchived: true));
    await dao.insertProduct(_product('1', 'Apple', isArchived: false));

    final rows = await dao.watchActiveProducts().first;

    expect(rows.map((row) => row.name), ['Apple', 'Zinc']);
    expect(rows.every((row) => !row.isArchived), isTrue);
  });

  test(
    'all-products export query includes archived rows ordered by name',
    () async {
      await dao.insertProduct(_product('3', 'Zinc', isArchived: false));
      await dao.insertProduct(_product('2', 'Hidden', isArchived: true));
      await dao.insertProduct(_product('1', 'Apple', isArchived: false));

      final rows = await dao.listAllProducts();

      expect(rows.map((row) => row.name), ['Apple', 'Hidden', 'Zinc']);
      expect(rows.map((row) => row.isArchived), [false, true, false]);
    },
  );

  test('archived query lists archived rows ordered by name', () async {
    await dao.insertProduct(_product('3', 'Zinc', isArchived: true));
    await dao.insertProduct(_product('2', 'Active', isArchived: false));
    await dao.insertProduct(_product('1', 'Apple', isArchived: true));

    final rows = await dao.watchArchivedProducts().first;

    expect(rows.map((row) => row.name), ['Apple', 'Zinc']);
    expect(rows.every((row) => row.isArchived), isTrue);
  });

  test('restore flips only archived target back to active', () async {
    final updatedAt = DateTime.utc(2026, 8, 10);
    await dao.insertProduct(_product('1', 'Rice', isArchived: true));
    await dao.insertProduct(_product('2', 'Soap', isArchived: false));

    final restored = await dao.restoreProduct(id: '1', updatedAt: updatedAt);
    final activeRestore = await dao.restoreProduct(
      id: '2',
      updatedAt: updatedAt,
    );

    expect(restored, isTrue);
    expect(activeRestore, isFalse);
    final row = await dao.getProductById('1');
    expect(row?.isArchived, isFalse);
    expect(row?.updatedAt.toUtc(), updatedAt);
  });
}

ProductsCompanion _product(
  String id,
  String name, {
  required bool isArchived,
}) {
  final instant = DateTime.utc(2026, 6, 28);
  return ProductsCompanion.insert(
    id: id,
    name: name,
    unit: 'piece',
    sellingPrice: 1,
    quantity: 0,
    lowStockThreshold: 0,
    isArchived: Value(isArchived),
    createdAt: instant,
    updatedAt: instant,
  );
}
