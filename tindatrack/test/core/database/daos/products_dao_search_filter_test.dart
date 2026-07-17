import 'dart:async';

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

  test('blank search keeps active rows ordered by name', () async {
    await _insert(dao, '3', 'Zinc', quantity: 3, threshold: 2);
    await _insert(dao, '2', 'Hidden', archived: true);
    await _insert(dao, '1', 'Apple');

    final rows = await dao
        .watchActiveProducts(
          const ProductsQueryParameters(searchText: '   '),
        )
        .first;

    expect(rows.map((row) => row.name), ['Apple', 'Zinc']);
  });

  test('search matches ASCII case-insensitive name or category', () async {
    await _insert(dao, '1', 'Brown RICE');
    await _insert(dao, '2', 'Soap', category: 'Rice Goods');
    await _insert(dao, '3', 'Salt');

    final rows = await dao
        .watchActiveProducts(
          const ProductsQueryParameters(searchText: 'rice'),
        )
        .first;

    expect(rows.map((row) => row.name), ['Brown RICE', 'Soap']);
  });

  test('LIKE metacharacters and escape character are literal', () async {
    await _insert(dao, '1', r'Back\slash');
    await _insert(dao, '2', 'Percent % bag');
    await _insert(dao, '3', 'Under_score');
    await _insert(dao, '4', 'Ordinary');

    Future<List<String>> names(String searchText) async {
      final rows = await dao
          .watchActiveProducts(
            ProductsQueryParameters(searchText: searchText),
          )
          .first;
      return rows.map((row) => row.name).toList();
    }

    expect(await names('%'), ['Percent % bag']);
    expect(await names('_'), ['Under_score']);
    expect(await names(r'\'), [r'Back\slash']);
  });

  test('NUL search text matches no rows', () async {
    await _insert(dao, '1', 'Rice');
    await _insert(dao, '2', 'Salt');

    final rows = await dao
        .watchActiveProducts(
          const ProductsQueryParameters(searchText: '\u0000rice'),
        )
        .first;

    expect(rows, isEmpty);
  });

  test('low-stock filter includes all products needing restocking', () async {
    await _insert(dao, '0', 'Zero');
    await _insert(dao, '1', 'Threshold zero positive', quantity: 1);
    await _insert(dao, '2', 'Threshold minus one', quantity: 1, threshold: 2);
    await _insert(dao, '3', 'Threshold', quantity: 2, threshold: 2);
    await _insert(dao, '4', 'Threshold plus one', quantity: 3, threshold: 2);

    final low = await dao
        .watchActiveProducts(
          const ProductsQueryParameters(
            stockFilter: ProductsStockFilterParameter.lowStock,
          ),
        )
        .first;
    final out = await dao
        .watchActiveProducts(
          const ProductsQueryParameters(
            stockFilter: ProductsStockFilterParameter.outOfStock,
          ),
        )
        .first;

    expect(
      low.map((row) => row.name),
      ['Threshold', 'Threshold minus one', 'Zero'],
    );
    expect(out.map((row) => row.name), ['Zero']);
  });

  test('search, stock, and active criteria compose with AND', () async {
    await _insert(
      dao,
      '1',
      'Rice low',
      quantity: 1,
      threshold: 2,
    );
    await _insert(
      dao,
      '2',
      'Rice full',
      quantity: 3,
      threshold: 2,
    );
    await _insert(
      dao,
      '3',
      'Other low',
      category: 'rice category',
      quantity: 2,
      threshold: 2,
    );
    await _insert(
      dao,
      '4',
      'Rice hidden',
      quantity: 1,
      threshold: 2,
      archived: true,
    );

    final rows = await dao
        .watchActiveProducts(
          const ProductsQueryParameters(
            searchText: 'rice',
            stockFilter: ProductsStockFilterParameter.lowStock,
          ),
        )
        .first;

    expect(rows.map((row) => row.name), ['Other low', 'Rice low']);
  });

  test('watched criteria re-emit after matching inserts', () async {
    final stream = dao.watchActiveProducts(
      const ProductsQueryParameters(
        searchText: 'rice',
        stockFilter: ProductsStockFilterParameter.lowStock,
      ),
    );
    final emissions = StreamIterator(stream);
    addTearDown(emissions.cancel);

    expect(await emissions.moveNext(), isTrue);
    expect(emissions.current, isEmpty);

    await _insert(
      dao,
      '1',
      'Rice',
      quantity: 1,
      threshold: 2,
    );

    expect(await emissions.moveNext(), isTrue);
    expect(emissions.current.map((row) => row.name), ['Rice']);
  });

  test('watched criteria re-emit after quantity and archive updates', () async {
    await _insert(
      dao,
      '1',
      'Rice',
      quantity: 3,
      threshold: 2,
    );
    final emissions = StreamIterator(
      dao.watchActiveProducts(
        const ProductsQueryParameters(
          searchText: 'rice',
          stockFilter: ProductsStockFilterParameter.lowStock,
        ),
      ),
    );
    addTearDown(emissions.cancel);

    expect(await emissions.moveNext(), isTrue);
    expect(emissions.current, isEmpty);

    await (database.update(database.products)
          ..where((product) => product.id.equals('1')))
        .write(const ProductsCompanion(quantity: Value(2)));

    expect(await emissions.moveNext(), isTrue);
    expect(emissions.current.map((row) => row.name), ['Rice']);

    await (database.update(
      database.products,
    )..where((product) => product.id.equals('1'))).write(
      const ProductsCompanion(
        isArchived: Value(true),
      ),
    );

    expect(await emissions.moveNext(), isTrue);
    expect(emissions.current, isEmpty);
  });
}

Future<void> _insert(
  ProductsDao dao,
  String id,
  String name, {
  String? category,
  int quantity = 0,
  int threshold = 0,
  bool archived = false,
}) {
  final instant = DateTime.utc(2026, 7);
  return dao.insertProduct(
    ProductsCompanion.insert(
      id: id,
      name: name,
      category: Value(category),
      unit: 'piece',
      sellingPrice: 1,
      quantity: quantity,
      lowStockThreshold: threshold,
      isArchived: Value(archived),
      createdAt: instant,
      updatedAt: instant,
    ),
  );
}
