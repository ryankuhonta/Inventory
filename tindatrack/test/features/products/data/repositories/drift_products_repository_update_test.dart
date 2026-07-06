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
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/entities/update_product_input.dart';
import 'package:tindatrack/features/products/domain/failures/product_failure.dart';

void main() {
  late db.AppDatabase database;
  late ProductsDao dao;
  late _CountingIdGenerator ids;
  late DriftProductsRepository repository;
  final createdAt = DateTime.utc(2026, 7);
  final updatedAt = DateTime.utc(2026, 7, 2, 3);

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    dao = ProductsDao(database);
    ids = _CountingIdGenerator();
    repository = DriftProductsRepository(
      dao: dao,
      idGenerator: ids,
      clock: _FixedClock(updatedAt),
    );
  });

  tearDown(() => database.close());

  test('partial update preserves stock and persistence identity', () async {
    await _insert(
      dao,
      id: 'product-1',
      quantity: 9,
      barcode: 'old',
      createdAt: createdAt,
    );

    final result = await repository.updateProduct(
      'product-1',
      _update(barcode: 'new'),
    );

    final product = (result as Success<Product>).value;
    expect(product.name, 'Updated Rice');
    expect(product.category, 'Staples');
    expect(product.unit, 'kg');
    expect(product.sellingPrice, 75);
    expect(product.lowStockThreshold, 4);
    expect(product.barcode, 'new');
    expect(product.quantity, 9);
    expect(product.id, 'product-1');
    expect(product.createdAt, createdAt);
    expect(product.updatedAt, updatedAt);
    expect(product.isArchived, isFalse);
    expect(ids.calls, 0);
  });

  test(
    'blank barcode becomes null and unchanged self-barcode succeeds',
    () async {
      await _insert(
        dao,
        id: 'product-1',
        quantity: 3,
        barcode: 'same',
        createdAt: createdAt,
      );

      final same = await repository.updateProduct(
        'product-1',
        _update(barcode: ' same '),
      );
      expect((same as Success<Product>).value.barcode, 'same');

      final blank = await repository.updateProduct(
        'product-1',
        _update(barcode: '   '),
      );
      expect((blank as Success<Product>).value.barcode, isNull);
    },
  );

  for (final archived in [false, true]) {
    test(
      'duplicate ${archived ? 'archived' : 'active'} barcode is typed',
      () async {
        await _insert(
          dao,
          id: 'product-1',
          quantity: 3,
          createdAt: createdAt,
        );
        await _insert(
          dao,
          id: 'other',
          quantity: 1,
          barcode: 'reserved',
          archived: archived,
          createdAt: createdAt,
        );

        final result = await repository.updateProduct(
          'product-1',
          _update(barcode: 'reserved'),
        );

        expect(
          (result as FailureResult<Product>).failure,
          isA<DuplicateBarcodeFailure>(),
        );
      },
    );
  }

  test('missing and archived targets are rejected without mutation', () async {
    final missing = await repository.updateProduct('missing', _update());
    expect(
      (missing as FailureResult<Product>).failure,
      isA<ProductNotFoundFailure>(),
    );

    await _insert(
      dao,
      id: 'archived',
      quantity: 2,
      archived: true,
      createdAt: createdAt,
    );
    final archived = await repository.updateProduct('archived', _update());
    expect(
      (archived as FailureResult<Product>).failure,
      isA<ArchivedProductFailure>(),
    );
    final row = await dao.getProductById('archived');
    expect(row?.name, 'Rice');
    expect(row?.quantity, 2);
  });

  test('active watch re-emits updated metadata and threshold', () async {
    await _insert(
      dao,
      id: 'product-1',
      quantity: 3,
      createdAt: createdAt,
    );
    final emissions = StreamIterator(repository.watchActiveProducts());
    addTearDown(emissions.cancel);
    expect(await emissions.moveNext(), isTrue);
    expect(emissions.current.single.name, 'Rice');

    await repository.updateProduct('product-1', _update());

    expect(await emissions.moveNext(), isTrue);
    expect(emissions.current.single.name, 'Updated Rice');
    expect(emissions.current.single.lowStockThreshold, 4);
  });

  test(
    'clock exceptions become persistence failures without mutation',
    () async {
      await _insert(
        dao,
        id: 'product-1',
        quantity: 3,
        createdAt: createdAt,
      );
      final failingRepository = DriftProductsRepository(
        dao: dao,
        idGenerator: ids,
        clock: const _ThrowingClock(),
      );

      final result = await failingRepository.updateProduct(
        'product-1',
        _update(),
      );

      expect(
        (result as FailureResult<Product>).failure,
        isA<PersistenceFailure>(),
      );
      final row = await dao.getProductById('product-1');
      expect(row?.name, 'Rice');
      expect(row?.updatedAt.toUtc(), createdAt);
    },
  );
}

UpdateProductInput _update({String? barcode}) {
  return UpdateProductInput(
    name: 'Updated Rice',
    category: 'Staples',
    unit: 'kg',
    sellingPrice: 75,
    lowStockThreshold: 4,
    barcode: barcode,
  );
}

Future<void> _insert(
  ProductsDao dao, {
  required String id,
  required int quantity,
  required DateTime createdAt,
  String? barcode,
  bool archived = false,
}) {
  return dao.insertProduct(
    db.ProductsCompanion.insert(
      id: id,
      name: 'Rice',
      unit: 'pcs',
      sellingPrice: 50,
      quantity: quantity,
      lowStockThreshold: 2,
      barcode: Value(barcode),
      isArchived: Value(archived),
      createdAt: createdAt,
      updatedAt: createdAt,
    ),
  );
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
  DateTime now() => throw Exception('clock unavailable');
}
