import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/database/app_database.dart' as db;
import 'package:tindatrack/core/database/daos/products_dao.dart';
import 'package:tindatrack/core/id/id_generator.dart';
import 'package:tindatrack/core/time/clock.dart';
import 'package:tindatrack/features/products/data/repositories/drift_products_repository.dart';
import 'package:tindatrack/features/products/domain/entities/product_list_query.dart';

void main() {
  late db.AppDatabase database;
  late ProductsDao dao;
  late DriftProductsRepository repository;

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    dao = ProductsDao(database);
    repository = DriftProductsRepository(
      dao: dao,
      idGenerator: const _UnusedIdGenerator(),
      clock: const _UnusedClock(),
    );
  });

  tearDown(() => database.close());

  test('maps domain query to DAO criteria and immutable entities', () async {
    await dao.insertProduct(
      db.ProductsCompanion.insert(
        id: '1',
        name: 'Rice',
        category: const Value('Staples'),
        unit: 'kg',
        sellingPrice: 60,
        quantity: 1,
        lowStockThreshold: 2,
        createdAt: DateTime.utc(2026, 7),
        updatedAt: DateTime.utc(2026, 7),
      ),
    );
    await dao.insertProduct(
      db.ProductsCompanion.insert(
        id: '2',
        name: 'Rice full',
        unit: 'kg',
        sellingPrice: 60,
        quantity: 3,
        lowStockThreshold: 2,
        createdAt: DateTime.utc(2026, 7),
        updatedAt: DateTime.utc(2026, 7),
      ),
    );

    final products = await repository
        .watchActiveProducts(
          ProductListQuery(
            searchText: ' rice ',
            stockFilter: ProductStockFilter.lowStock,
          ),
        )
        .first;

    expect(products, hasLength(1));
    expect(products.single.name, 'Rice');
    expect(products.single.category, 'Staples');
    expect(products.single.quantity, 1);
  });
}

final class _UnusedIdGenerator implements IdGenerator {
  const _UnusedIdGenerator();

  @override
  String generate() => throw UnimplementedError();
}

final class _UnusedClock implements Clock {
  const _UnusedClock();

  @override
  DateTime now() => throw UnimplementedError();
}
