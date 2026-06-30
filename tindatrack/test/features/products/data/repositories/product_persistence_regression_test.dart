import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/database/app_database.dart' as db;
import 'package:tindatrack/core/database/daos/products_dao.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/core/id/id_generator.dart';
import 'package:tindatrack/core/time/clock.dart';
import 'package:tindatrack/features/products/data/repositories/drift_products_repository.dart';
import 'package:tindatrack/features/products/domain/entities/create_product_input.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';

void main() {
  test('created product survives a file-backed close and reopen', () async {
    final directory = await Directory.systemTemp.createTemp(
      'tindatrack-product-persistence-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}inventory.db');
    final instant = DateTime.utc(2026, 6, 28);

    final firstDatabase = db.AppDatabase(NativeDatabase(file));
    final firstRepository = _repository(firstDatabase, instant);
    final created = await firstRepository.createProduct(_input('Persisted'));
    expect(created, isA<Success<Product>>());
    await firstDatabase.close();

    final reopenedDatabase = db.AppDatabase(NativeDatabase(file));
    addTearDown(reopenedDatabase.close);
    final reopenedRepository = _repository(reopenedDatabase, instant);

    final products = await reopenedRepository.watchActiveProducts().first;
    expect(products.map((product) => product.name), ['Persisted']);
    expect(products.single.createdAt, instant);
  });

  test('active product watch emits after a database insert', () async {
    final database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = _repository(database, DateTime.utc(2026, 6, 28));
    final iterator = StreamIterator(repository.watchActiveProducts());
    addTearDown(iterator.cancel);

    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current, isEmpty);

    await repository.createProduct(_input('Reactive'));

    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current.map((product) => product.name), ['Reactive']);
  });

  for (final invalid in [
    (price: -0.01, quantity: 0, threshold: 0),
    (price: 0.0, quantity: -1, threshold: 0),
    (price: 0.0, quantity: 0, threshold: -1),
  ]) {
    test('database rejects negative values: $invalid', () async {
      final database = db.AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final dao = ProductsDao(database);
      final instant = DateTime.utc(2026, 6, 28);

      await expectLater(
        dao.insertProduct(
          db.ProductsCompanion.insert(
            id: 'negative-${invalid.hashCode}',
            name: 'Invalid',
            unit: 'piece',
            sellingPrice: invalid.price,
            quantity: invalid.quantity,
            lowStockThreshold: invalid.threshold,
            barcode: const Value(null),
            createdAt: instant,
            updatedAt: instant,
          ),
        ),
        throwsA(isA<SqliteException>()),
      );
    });
  }
}

DriftProductsRepository _repository(
  db.AppDatabase database,
  DateTime instant,
) {
  return DriftProductsRepository(
    dao: ProductsDao(database),
    idGenerator: const _FixedIdGenerator(),
    clock: _FixedClock(instant),
  );
}

CreateProductInput _input(String name) {
  return CreateProductInput(
    name: name,
    unit: 'piece',
    sellingPrice: 1,
    quantity: 0,
    lowStockThreshold: 0,
  );
}

final class _FixedIdGenerator implements IdGenerator {
  const _FixedIdGenerator();

  @override
  String generate() => '01JPRODUCTPERSISTENCE000000';
}

final class _FixedClock implements Clock {
  const _FixedClock(this.instant);

  final DateTime instant;

  @override
  DateTime now() => instant;
}
