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
import 'package:tindatrack/features/products/domain/entities/create_product_input.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/failures/product_failure.dart';

void main() {
  late db.AppDatabase database;
  late ProductsDao dao;
  late DriftProductsRepository repository;
  late _SequenceIdGenerator ids;
  final instant = DateTime.utc(2026, 6, 28, 4, 30);

  setUp(() {
    database = db.AppDatabase(NativeDatabase.memory());
    dao = ProductsDao(database);
    ids = _SequenceIdGenerator();
    repository = DriftProductsRepository(
      dao: dao,
      idGenerator: ids,
      clock: _FixedClock(instant),
    );
  });

  tearDown(() => database.close());

  test('create uses one injected ID and one UTC instant', () async {
    final result = await repository.createProduct(_input(name: 'Rice'));

    expect(result, isA<Success<Product>>());
    final product = (result as Success<Product>).value;
    expect(product.id, 'fixed-1');
    expect(product.createdAt, instant);
    expect(product.updatedAt, product.createdAt);
    expect(product.isArchived, isFalse);
    expect(ids.calls, 1);
  });

  test(
    'blank barcodes normalize to null and multiple nulls are allowed',
    () async {
      final first = await repository.createProduct(
        _input(name: 'Rice', barcode: '   '),
      );
      final second = await repository.createProduct(
        _input(name: 'Sugar', barcode: ''),
      );

      expect(first, isA<Success<Product>>());
      expect(second, isA<Success<Product>>());
      expect((first as Success<Product>).value.barcode, isNull);
      expect((second as Success<Product>).value.barcode, isNull);
    },
  );

  test('trimmed duplicate barcode returns typed failure', () async {
    await repository.createProduct(_input(name: 'Rice', barcode: ' 123 '));

    final duplicate = await repository.createProduct(
      _input(name: 'Sugar', barcode: '123'),
    );

    expect(duplicate, isA<FailureResult<Product>>());
    expect(
      (duplicate as FailureResult<Product>).failure,
      isA<DuplicateBarcodeFailure>(),
    );
  });

  test('archived rows still reserve their barcode', () async {
    await dao.insertProduct(
      db.ProductsCompanion.insert(
        id: 'archived',
        name: 'Archived',
        unit: 'piece',
        sellingPrice: 1,
        quantity: 0,
        lowStockThreshold: 0,
        barcode: const Value('reserved'),
        isArchived: const Value(true),
        createdAt: instant,
        updatedAt: instant,
      ),
    );

    final duplicate = await repository.createProduct(
      _input(name: 'New', barcode: 'reserved'),
    );

    expect(
      (duplicate as FailureResult<Product>).failure,
      isA<DuplicateBarcodeFailure>(),
    );
  });

  test('watch returns active domain entities sorted by name', () async {
    await repository.createProduct(_input(name: 'Zinc'));
    await dao.insertProduct(
      db.ProductsCompanion.insert(
        id: 'archived',
        name: 'Hidden',
        unit: 'piece',
        sellingPrice: 1,
        quantity: 0,
        lowStockThreshold: 0,
        isArchived: const Value(true),
        createdAt: instant,
        updatedAt: instant,
      ),
    );
    await repository.createProduct(_input(name: 'Apple'));

    final products = await repository.watchActiveProducts().first;

    expect(products, everyElement(isA<Product>()));
    expect(products.map((product) => product.name), ['Apple', 'Zinc']);
  });

  test('non-barcode SQLite constraints map to PersistenceFailure', () async {
    final result = await repository.createProduct(
      _input(name: 'Rice', sellingPrice: -1),
    );

    expect(result, isA<FailureResult<Product>>());
    expect(
      (result as FailureResult<Product>).failure,
      isA<PersistenceFailure>(),
    );
  });
}

CreateProductInput _input({
  required String name,
  String? barcode,
  double sellingPrice = 10,
}) {
  return CreateProductInput(
    name: name,
    unit: 'piece',
    sellingPrice: sellingPrice,
    quantity: 1,
    lowStockThreshold: 0,
    barcode: barcode,
  );
}

final class _SequenceIdGenerator implements IdGenerator {
  int calls = 0;

  @override
  String generate() => 'fixed-${++calls}';
}

final class _FixedClock implements Clock {
  const _FixedClock(this.instant);

  final DateTime instant;

  @override
  DateTime now() => instant;
}
