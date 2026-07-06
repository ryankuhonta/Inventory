import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/database/app_database.dart' as db;
import 'package:tindatrack/core/database/daos/products_dao.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/core/id/id_generator.dart';
import 'package:tindatrack/core/time/clock.dart';
import 'package:tindatrack/features/products/data/repositories/drift_products_repository.dart';
import 'package:tindatrack/features/products/domain/failures/product_failure.dart';

void main() {
  late db.AppDatabase database;
  late ProductsDao dao;
  late _CountingIdGenerator ids;
  late DriftProductsRepository repository;
  final createdAt = DateTime.utc(2026, 7);
  final clockValue = DateTime.parse('2026-07-06T16:30:00+08:00');

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    dao = ProductsDao(database);
    ids = _CountingIdGenerator();
    repository = DriftProductsRepository(
      dao: dao,
      idGenerator: ids,
      clock: _FixedClock(clockValue),
    );
  });

  tearDown(() => database.close());

  test('soft archive changes only archive state and UTC update time', () async {
    await _insert(dao, createdAt: createdAt);

    final result = await repository.archiveProduct('product-1');

    expect(result, isA<Success<void>>());
    final row = await dao.getProductById('product-1');
    expect(row, isNotNull);
    expect(row?.isArchived, isTrue);
    expect(row?.updatedAt.toUtc(), clockValue.toUtc());
    expect(row?.id, 'product-1');
    expect(row?.name, 'Rice');
    expect(row?.category, 'Staples');
    expect(row?.unit, 'kg');
    expect(row?.sellingPrice, 75);
    expect(row?.quantity, 9);
    expect(row?.lowStockThreshold, 4);
    expect(row?.barcode, 'reserved');
    expect(row?.createdAt.toUtc(), createdAt);
    expect(ids.calls, 0);
  });

  test('active watch re-emits without the archived row', () async {
    await _insert(dao, createdAt: createdAt);
    final emissions = StreamIterator(repository.watchActiveProducts());
    addTearDown(emissions.cancel);
    expect(
      await emissions.moveNext().timeout(const Duration(seconds: 1)),
      isTrue,
    );
    expect(emissions.current.single.id, 'product-1');

    await repository.archiveProduct('product-1');

    expect(
      await emissions.moveNext().timeout(const Duration(seconds: 1)),
      isTrue,
    );
    expect(emissions.current, isEmpty);
  });

  test('missing and already archived targets return typed failures', () async {
    final missing = await repository.archiveProduct('missing');
    expect(
      (missing as FailureResult<void>).failure,
      isA<ProductNotFoundFailure>(),
    );

    await _insert(dao, createdAt: createdAt, archived: true);
    final archived = await repository.archiveProduct('product-1');
    expect(
      (archived as FailureResult<void>).failure,
      isA<ArchivedProductFailure>(),
    );
    final row = await dao.getProductById('product-1');
    expect(row?.updatedAt.toUtc(), createdAt);
  });

  test('clock failure is contained without changing the row', () async {
    await _insert(dao, createdAt: createdAt);
    final failingRepository = DriftProductsRepository(
      dao: dao,
      idGenerator: ids,
      clock: const _ThrowingClock(),
    );

    final result = await failingRepository.archiveProduct('product-1');

    expect(
      (result as FailureResult<void>).failure,
      isA<PersistenceFailure>(),
    );
    final row = await dao.getProductById('product-1');
    expect(row?.isArchived, isFalse);
    expect(row?.updatedAt.toUtc(), createdAt);
  });

  test('DAO failure is translated without changing the row', () async {
    final throwingDao = _ThrowingProductsDao(database);
    await _insert(throwingDao, createdAt: createdAt);
    final failingRepository = DriftProductsRepository(
      dao: throwingDao,
      idGenerator: ids,
      clock: _FixedClock(clockValue),
    );

    final result = await failingRepository.archiveProduct('product-1');

    expect(
      (result as FailureResult<void>).failure,
      isA<PersistenceFailure>(),
    );
    final row = await throwingDao.getProductById('product-1');
    expect(row?.isArchived, isFalse);
  });
}

Future<void> _insert(
  ProductsDao dao, {
  required DateTime createdAt,
  bool archived = false,
}) {
  return dao.insertProduct(
    db.ProductsCompanion.insert(
      id: 'product-1',
      name: 'Rice',
      category: const Value('Staples'),
      unit: 'kg',
      sellingPrice: 75,
      quantity: 9,
      lowStockThreshold: 4,
      barcode: const Value('reserved'),
      isArchived: Value(archived),
      createdAt: createdAt,
      updatedAt: createdAt,
    ),
  );
}

final class _ThrowingProductsDao extends ProductsDao {
  _ThrowingProductsDao(super.attachedDatabase);

  @override
  Future<bool> archiveProduct({
    required String id,
    required DateTime updatedAt,
  }) {
    throw StateError('write failed');
  }
}

final class _CountingIdGenerator implements IdGenerator {
  int calls = 0;

  @override
  String generate() {
    calls++;
    return 'unexpected';
  }
}

final class _FixedClock implements Clock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

final class _ThrowingClock implements Clock {
  const _ThrowingClock();

  @override
  DateTime now() => throw StateError('clock unavailable');
}
