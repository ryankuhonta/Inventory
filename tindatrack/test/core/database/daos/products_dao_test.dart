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
