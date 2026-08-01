import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/database/app_database.dart' as db;
import 'package:tindatrack/core/database/daos/products_dao.dart';
import 'package:tindatrack/core/database/daos/stock_movements_dao.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/core/id/id_generator.dart';
import 'package:tindatrack/core/time/clock.dart';
import 'package:tindatrack/features/stock/data/repositories/drift_stock_repository.dart';
import 'package:tindatrack/features/stock/domain/entities/create_stock_movement_input.dart';
import 'package:tindatrack/features/stock/domain/entities/record_stock_in_input.dart';
import 'package:tindatrack/features/stock/domain/entities/record_stock_out_input.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';
import 'package:tindatrack/features/stock/domain/failures/stock_failure.dart';

void main() {
  late db.AppDatabase database;
  late ProductsDao productsDao;
  late DriftStockRepository repository;
  late _SequenceIdGenerator ids;
  final instant = DateTime.utc(2026, 7, 1, 4, 30);

  setUp(() async {
    database = db.AppDatabase(NativeDatabase.memory());
    productsDao = ProductsDao(database);
    await productsDao.insertProduct(_product());
    ids = _SequenceIdGenerator();
    repository = DriftStockRepository(
      productsDao: productsDao,
      stockMovementsDao: StockMovementsDao(database),
      idGenerator: ids,
      clock: _FixedClock(instant),
    );
  });

  tearDown(() => database.close());

  test(
    'recordStockIn updates product quantity and writes movement history',
    () async {
      final result = await repository.recordStockIn(
        const RecordStockInInput(
          productId: 'product-1',
          quantity: 3,
          note: ' delivery ',
        ),
      );

      expect(result, isA<Success<StockMovement>>());
      final movement = (result as Success<StockMovement>).value;
      final product = await productsDao.getProductById('product-1');
      final rows = await StockMovementsDao(database).listMovements();

      expect(product?.quantity, 8);
      expect(rows, hasLength(1));
      expect(movement.id, 'movement-1');
      expect(movement.type, StockMovementType.stockIn);
      expect(movement.quantity, 3);
      expect(movement.previousQuantity, 5);
      expect(movement.newQuantity, 8);
      expect(movement.reason, isNull);
      expect(movement.note, 'delivery');
      expect(movement.productNameSnapshot, 'Rice');
      expect(movement.unitSnapshot, 'kg');
      expect(movement.createdAt, instant);
      expect(ids.calls, 1);
    },
  );

  test(
    'recordStockIn snapshots product name and unit from product row',
    () async {
      await productsDao.insertProduct(
        _product(id: 'product-2', name: 'Coke 1L', unit: 'bottle'),
      );

      final result = await repository.recordStockIn(
        const RecordStockInInput(productId: 'product-2', quantity: 4),
      );

      final movement = (result as Success<StockMovement>).value;
      expect(movement.productNameSnapshot, 'Coke 1L');
      expect(movement.unitSnapshot, 'bottle');
      expect(movement.previousQuantity, 5);
      expect(movement.newQuantity, 9);
    },
  );

  test(
    'invalid stock-in quantity does not mutate product or history',
    () async {
      for (final quantity in [0, -1]) {
        final result = await repository.recordStockIn(
          RecordStockInInput(productId: 'product-1', quantity: quantity),
        );

        expect(result, isA<FailureResult<StockMovement>>());
        expect(
          (result as FailureResult<StockMovement>).failure,
          isA<StockMovementValidationFailure>()
              .having(
                (failure) => failure.field,
                'field',
                StockMovementField.quantity,
              )
              .having(
                (failure) => failure.issue,
                'issue',
                StockMovementValidationIssue.notPositive,
              ),
        );
        expect((await productsDao.getProductById('product-1'))?.quantity, 5);
        expect(await StockMovementsDao(database).listMovements(), isEmpty);
        expect(ids.calls, 0);
      }
    },
  );

  test('missing product does not mutate product or history', () async {
    final result = await repository.recordStockIn(
      const RecordStockInInput(productId: 'missing-product', quantity: 1),
    );

    expect(result, isA<FailureResult<StockMovement>>());
    expect(
      (result as FailureResult<StockMovement>).failure,
      isA<StockProductNotFoundFailure>(),
    );
    expect((await productsDao.getProductById('product-1'))?.quantity, 5);
    expect(await productsDao.getProductById('missing-product'), isNull);
    expect(await StockMovementsDao(database).listMovements(), isEmpty);
    expect(ids.calls, 0);
  });

  test('archived product does not mutate product or history', () async {
    await productsDao.archiveProduct(id: 'product-1', updatedAt: instant);

    final result = await repository.recordStockIn(
      const RecordStockInInput(productId: 'product-1', quantity: 1),
    );

    expect(result, isA<FailureResult<StockMovement>>());
    expect(
      (result as FailureResult<StockMovement>).failure,
      isA<StockArchivedProductFailure>(),
    );
    final product = await productsDao.getProductById('product-1');
    expect(product?.quantity, 5);
    expect(product?.isArchived, isTrue);
    expect(await StockMovementsDao(database).listMovements(), isEmpty);
    expect(ids.calls, 0);
  });

  test(
    'product quantity update failure does not save Stock In history',
    () async {
      final failingProductsDao = _NullUpdateProductsDao(database);
      final failingRepository = DriftStockRepository(
        productsDao: failingProductsDao,
        stockMovementsDao: StockMovementsDao(database),
        idGenerator: ids,
        clock: _FixedClock(instant),
      );

      final result = await failingRepository.recordStockIn(
        const RecordStockInInput(productId: 'product-1', quantity: 3),
      );

      expect(result, isA<FailureResult<StockMovement>>());
      expect(
        (result as FailureResult<StockMovement>).failure,
        isA<PersistenceFailure>(),
      );
      expect((await productsDao.getProductById('product-1'))?.quantity, 5);
      expect(await StockMovementsDao(database).listMovements(), isEmpty);
      expect(ids.calls, 1);
    },
  );

  test('movement insert failure rolls back product quantity update', () async {
    final failingRepository = DriftStockRepository(
      productsDao: productsDao,
      stockMovementsDao: _FailingInsertStockMovementsDao(database),
      idGenerator: ids,
      clock: _FixedClock(instant),
    );

    final result = await failingRepository.recordStockIn(
      const RecordStockInInput(productId: 'product-1', quantity: 3),
    );

    expect(result, isA<FailureResult<StockMovement>>());
    expect(
      (result as FailureResult<StockMovement>).failure,
      isA<PersistenceFailure>(),
    );
    expect((await productsDao.getProductById('product-1'))?.quantity, 5);
    expect(await StockMovementsDao(database).listMovements(), isEmpty);
  });

  test(
    'recordStockOut decreases product quantity and writes movement history',
    () async {
      final result = await repository.recordStockOut(
        const RecordStockOutInput(
          productId: 'product-1',
          quantity: 3,
          note: ' sold today ',
        ),
      );

      expect(result, isA<Success<StockMovement>>());
      final movement = (result as Success<StockMovement>).value;
      final product = await productsDao.getProductById('product-1');
      final rows = await StockMovementsDao(database).listMovements();

      expect(product?.quantity, 2);
      expect(rows, hasLength(1));
      expect(movement.id, 'movement-1');
      expect(movement.type, StockMovementType.stockOut);
      expect(movement.quantity, 3);
      expect(movement.previousQuantity, 5);
      expect(movement.newQuantity, 2);
      expect(movement.reason, StockOutReason.sold);
      expect(movement.note, 'sold today');
      expect(movement.productNameSnapshot, 'Rice');
      expect(movement.unitSnapshot, 'kg');
      expect(movement.createdAt, instant);
      expect(ids.calls, 1);
    },
  );

  test('recordStockOut preserves explicit reason and snapshots', () async {
    await productsDao.insertProduct(
      _product(id: 'product-2', name: 'Coke 1L', unit: 'bottle'),
    );

    final result = await repository.recordStockOut(
      const RecordStockOutInput(
        productId: 'product-2',
        quantity: 4,
        reason: StockOutReason.damaged,
      ),
    );

    final movement = (result as Success<StockMovement>).value;
    expect(movement.reason, StockOutReason.damaged);
    expect(movement.productNameSnapshot, 'Coke 1L');
    expect(movement.unitSnapshot, 'bottle');
    expect(movement.previousQuantity, 5);
    expect(movement.newQuantity, 1);
  });

  test(
    'invalid stock-out quantity does not mutate product or history',
    () async {
      for (final quantity in [0, -1]) {
        final result = await repository.recordStockOut(
          RecordStockOutInput(productId: 'product-1', quantity: quantity),
        );

        expect(result, isA<FailureResult<StockMovement>>());
        expect(
          (result as FailureResult<StockMovement>).failure,
          isA<StockMovementValidationFailure>()
              .having(
                (failure) => failure.field,
                'field',
                StockMovementField.quantity,
              )
              .having(
                (failure) => failure.issue,
                'issue',
                StockMovementValidationIssue.notPositive,
              ),
        );
        expect((await productsDao.getProductById('product-1'))?.quantity, 5);
        expect(await StockMovementsDao(database).listMovements(), isEmpty);
        expect(ids.calls, 0);
      }
    },
  );

  test('insufficient stock does not mutate product or history', () async {
    final result = await repository.recordStockOut(
      const RecordStockOutInput(productId: 'product-1', quantity: 6),
    );

    expect(result, isA<FailureResult<StockMovement>>());
    expect(
      (result as FailureResult<StockMovement>).failure,
      isA<StockInsufficientQuantityFailure>()
          .having((failure) => failure.availableQuantity, 'available', 5)
          .having((failure) => failure.requestedQuantity, 'requested', 6),
    );
    expect((await productsDao.getProductById('product-1'))?.quantity, 5);
    expect(await StockMovementsDao(database).listMovements(), isEmpty);
    expect(ids.calls, 0);
  });

  test(
    'missing product stock out does not mutate product or history',
    () async {
      final result = await repository.recordStockOut(
        const RecordStockOutInput(productId: 'missing-product', quantity: 1),
      );

      expect(result, isA<FailureResult<StockMovement>>());
      expect(
        (result as FailureResult<StockMovement>).failure,
        isA<StockProductNotFoundFailure>(),
      );
      expect((await productsDao.getProductById('product-1'))?.quantity, 5);
      expect(await productsDao.getProductById('missing-product'), isNull);
      expect(await StockMovementsDao(database).listMovements(), isEmpty);
      expect(ids.calls, 0);
    },
  );

  test(
    'archived product stock out does not mutate product or history',
    () async {
      await productsDao.archiveProduct(id: 'product-1', updatedAt: instant);

      final result = await repository.recordStockOut(
        const RecordStockOutInput(productId: 'product-1', quantity: 1),
      );

      expect(result, isA<FailureResult<StockMovement>>());
      expect(
        (result as FailureResult<StockMovement>).failure,
        isA<StockArchivedProductFailure>(),
      );
      final product = await productsDao.getProductById('product-1');
      expect(product?.quantity, 5);
      expect(product?.isArchived, isTrue);
      expect(await StockMovementsDao(database).listMovements(), isEmpty);
      expect(ids.calls, 0);
    },
  );

  test(
    'product quantity update failure does not save Stock Out history',
    () async {
      final failingProductsDao = _NullUpdateProductsDao(database);
      final failingRepository = DriftStockRepository(
        productsDao: failingProductsDao,
        stockMovementsDao: StockMovementsDao(database),
        idGenerator: ids,
        clock: _FixedClock(instant),
      );

      final result = await failingRepository.recordStockOut(
        const RecordStockOutInput(productId: 'product-1', quantity: 3),
      );

      expect(result, isA<FailureResult<StockMovement>>());
      expect(
        (result as FailureResult<StockMovement>).failure,
        isA<PersistenceFailure>(),
      );
      expect((await productsDao.getProductById('product-1'))?.quantity, 5);
      expect(await StockMovementsDao(database).listMovements(), isEmpty);
      expect(ids.calls, 1);
    },
  );

  test(
    'stock-out movement insert failure rolls back quantity update',
    () async {
      final failingRepository = DriftStockRepository(
        productsDao: productsDao,
        stockMovementsDao: _FailingInsertStockMovementsDao(database),
        idGenerator: ids,
        clock: _FixedClock(instant),
      );

      final result = await failingRepository.recordStockOut(
        const RecordStockOutInput(productId: 'product-1', quantity: 3),
      );

      expect(result, isA<FailureResult<StockMovement>>());
      expect(
        (result as FailureResult<StockMovement>).failure,
        isA<PersistenceFailure>(),
      );
      expect((await productsDao.getProductById('product-1'))?.quantity, 5);
      expect(await StockMovementsDao(database).listMovements(), isEmpty);
    },
  );
  test('record uses one injected ID and one UTC instant', () async {
    final result = await repository.recordMovementRow(_input());

    expect(result, isA<Success<StockMovement>>());
    final movement = (result as Success<StockMovement>).value;
    expect(movement.id, 'movement-1');
    expect(movement.createdAt, instant);
    expect(movement.type, StockMovementType.stockIn);
    expect(ids.calls, 1);
  });

  test('stock out defaults omitted reason to sold', () async {
    final result = await repository.recordMovementRow(
      _input(type: StockMovementType.stockOut),
    );

    final movement = (result as Success<StockMovement>).value;
    expect(movement.reason, StockOutReason.sold);
  });

  test(
    'stock in ignores stock out reason and normalizes blank notes',
    () async {
      final result = await repository.recordMovementRow(
        _input(reason: StockOutReason.damaged, note: '   '),
      );

      final movement = (result as Success<StockMovement>).value;
      expect(movement.reason, isNull);
      expect(movement.note, isNull);
    },
  );

  test('snapshots survive later product rename and archive', () async {
    await repository.recordMovementRow(_input());
    await productsDao.updateProductDetails(
      id: 'product-1',
      name: 'Renamed Rice',
      category: null,
      unit: 'sack',
      sellingPrice: 20,
      lowStockThreshold: 1,
      barcode: null,
      updatedAt: instant.add(const Duration(minutes: 1)),
    );
    await productsDao.archiveProduct(
      id: 'product-1',
      updatedAt: instant.add(const Duration(minutes: 2)),
    );

    final result = await repository.listMovementHistory(productId: 'product-1');

    final movement = (result as Success<List<StockMovement>>).value.single;
    expect(movement.productNameSnapshot, 'Rice');
    expect(movement.unitSnapshot, 'kg');
    expect((await productsDao.getProductById('product-1'))?.isArchived, isTrue);
  });

  test('list and watch return domain entities newest first', () async {
    await repository.recordMovementRow(_input(note: 'older'));
    repository = DriftStockRepository(
      productsDao: productsDao,
      stockMovementsDao: StockMovementsDao(database),
      idGenerator: ids,
      clock: _FixedClock(instant.add(const Duration(minutes: 1))),
    );
    await repository.recordMovementRow(_input(note: 'newer'));

    final listed = await repository.listMovementHistory();
    final watched = await repository.watchMovementHistory().first;

    expect(
      (listed as Success<List<StockMovement>>).value.map((item) => item.note),
      ['newer', 'older'],
    );
    expect(watched.map((item) => item.note), ['newer', 'older']);
  });

  test(
    'listRecentNotes returns distinct recent notes by movement type',
    () async {
      await repository.recordMovementRow(
        _input(note: ' restock '),
      );
      repository = DriftStockRepository(
        productsDao: productsDao,
        stockMovementsDao: StockMovementsDao(database),
        idGenerator: ids,
        clock: _FixedClock(instant.add(const Duration(minutes: 1))),
      );
      await repository.recordMovementRow(
        _input(type: StockMovementType.stockOut, note: ' consumed '),
      );
      repository = DriftStockRepository(
        productsDao: productsDao,
        stockMovementsDao: StockMovementsDao(database),
        idGenerator: ids,
        clock: _FixedClock(instant.add(const Duration(minutes: 2))),
      );
      await repository.recordMovementRow(
        _input(note: 'Delivery'),
      );
      repository = DriftStockRepository(
        productsDao: productsDao,
        stockMovementsDao: StockMovementsDao(database),
        idGenerator: ids,
        clock: _FixedClock(instant.add(const Duration(minutes: 3))),
      );
      await repository.recordMovementRow(
        _input(note: ' delivery '),
      );
      await repository.recordMovementRow(
        _input(note: '   '),
      );

      final stockInNotes = await repository.listRecentNotes(
        type: StockMovementType.stockIn,
      );
      final limitedStockInNotes = await repository.listRecentNotes(
        type: StockMovementType.stockIn,
        limit: 1,
      );
      final negativeLimitNotes = await repository.listRecentNotes(
        type: StockMovementType.stockIn,
        limit: -1,
      );
      final stockOutNotes = await repository.listRecentNotes(
        type: StockMovementType.stockOut,
      );

      expect((stockInNotes as Success<List<String>>).value, [
        'delivery',
        'restock',
      ]);
      expect((limitedStockInNotes as Success<List<String>>).value, [
        'delivery',
      ]);
      expect((negativeLimitNotes as Success<List<String>>).value, isEmpty);
      expect((stockOutNotes as Success<List<String>>).value, ['consumed']);
    },
  );

  test('list and watch filter movement history by product ID', () async {
    await productsDao.insertProduct(_product(id: 'product-2', name: 'Sugar'));
    await repository.recordMovementRow(_input(note: 'rice'));
    await repository.recordMovementRow(
      _input(
        productId: 'product-2',
        note: 'sugar',
        productNameSnapshot: 'Sugar',
      ),
    );

    final listed = await repository.listMovementHistory(productId: 'product-1');
    final watched = await repository
        .watchMovementHistory(productId: 'product-1')
        .first;

    expect(
      (listed as Success<List<StockMovement>>).value.map((item) => item.note),
      ['rice'],
    );
    expect(watched.map((item) => item.note), ['rice']);
  });

  test(
    'invalid quantities return typed validation failures',
    () async {
      final cases =
          <
            ({
              CreateStockMovementInput input,
              StockMovementField field,
              StockMovementValidationIssue issue,
            })
          >[
            (
              input: _input(quantity: 0),
              field: StockMovementField.quantity,
              issue: StockMovementValidationIssue.notPositive,
            ),
            (
              input: _input(previousQuantity: -1),
              field: StockMovementField.previousQuantity,
              issue: StockMovementValidationIssue.negative,
            ),
            (
              input: _input(newQuantity: -1),
              field: StockMovementField.newQuantity,
              issue: StockMovementValidationIssue.negative,
            ),
          ];

      for (final testCase in cases) {
        final result = await repository.recordMovementRow(testCase.input);

        expect(result, isA<FailureResult<StockMovement>>());
        expect(
          (result as FailureResult<StockMovement>).failure,
          isA<StockMovementValidationFailure>()
              .having((failure) => failure.field, 'field', testCase.field)
              .having((failure) => failure.issue, 'issue', testCase.issue),
        );
      }
      expect(ids.calls, 0);
    },
  );

  test(
    'invalid persisted movement type maps list failures to persistence',
    () async {
      final invalidRepository = DriftStockRepository(
        productsDao: productsDao,
        stockMovementsDao: _InvalidTypeStockMovementsDao(database),
        idGenerator: ids,
        clock: _FixedClock(instant),
      );

      final result = await invalidRepository.listMovementHistory(
        productId: 'product-1',
      );

      expect(result, isA<FailureResult<List<StockMovement>>>());
      expect(
        (result as FailureResult<List<StockMovement>>).failure,
        isA<PersistenceFailure>(),
      );
    },
  );

  test('persistence failures map to typed persistence failure', () async {
    await StockMovementsDao(database).insertMovement(
      db.StockMovementsCompanion.insert(
        id: 'duplicate-id',
        productId: 'product-1',
        type: StockMovementType.stockIn.persistedValue,
        quantity: 1,
        previousQuantity: 1,
        newQuantity: 2,
        productNameSnapshot: 'Rice',
        unitSnapshot: 'kg',
        createdAt: instant,
      ),
    );
    final duplicateRepository = DriftStockRepository(
      productsDao: productsDao,
      stockMovementsDao: StockMovementsDao(database),
      idGenerator: const _FixedIdGenerator('duplicate-id'),
      clock: _FixedClock(instant),
    );

    final result = await duplicateRepository.recordMovementRow(_input());

    expect(result, isA<FailureResult<StockMovement>>());
    expect(
      (result as FailureResult<StockMovement>).failure,
      isA<PersistenceFailure>(),
    );
  });
}

db.ProductsCompanion _product({
  String id = 'product-1',
  String name = 'Rice',
  String unit = 'kg',
}) {
  final instant = DateTime.utc(2026, 7);
  return db.ProductsCompanion.insert(
    id: id,
    name: name,
    unit: unit,
    sellingPrice: 10,
    quantity: 5,
    lowStockThreshold: 1,
    createdAt: instant,
    updatedAt: instant,
  );
}

CreateStockMovementInput _input({
  String productId = 'product-1',
  StockMovementType type = StockMovementType.stockIn,
  int quantity = 2,
  int? previousQuantity,
  int? newQuantity,
  StockOutReason? reason,
  String? note = 'Restock',
  String productNameSnapshot = 'Rice',
}) {
  return CreateStockMovementInput(
    productId: productId,
    type: type,
    quantity: quantity,
    previousQuantity: previousQuantity ?? 3,
    newQuantity: newQuantity ?? (type == StockMovementType.stockIn ? 5 : 1),
    reason: reason,
    note: note,
    productNameSnapshot: productNameSnapshot,
    unitSnapshot: 'kg',
  );
}

final class _NullUpdateProductsDao extends ProductsDao {
  _NullUpdateProductsDao(super.attachedDatabase);

  @override
  Future<db.Product?> updateActiveProductQuantity({
    required String id,
    required int quantity,
    required DateTime updatedAt,
  }) async {
    return null;
  }
}

final class _FailingInsertStockMovementsDao extends StockMovementsDao {
  _FailingInsertStockMovementsDao(super.attachedDatabase);

  @override
  Future<db.StockMovement> insertMovement(db.StockMovementsCompanion movement) {
    throw Exception('forced movement insert failure');
  }
}

final class _InvalidTypeStockMovementsDao extends StockMovementsDao {
  _InvalidTypeStockMovementsDao(super.attachedDatabase);

  @override
  Future<List<db.StockMovement>> listMovements([
    StockMovementHistoryQuery query = const StockMovementHistoryQuery(),
  ]) async {
    return [
      db.StockMovement(
        id: 'bad-type',
        productId: query.productId ?? 'product-1',
        type: 'unexpected',
        quantity: 1,
        previousQuantity: 1,
        newQuantity: 2,
        productNameSnapshot: 'Rice',
        unitSnapshot: 'kg',
        createdAt: DateTime.utc(2026, 7, 1, 4, 30),
      ),
    ];
  }
}

final class _SequenceIdGenerator implements IdGenerator {
  int calls = 0;

  @override
  String generate() => 'movement-${++calls}';
}

final class _FixedClock implements Clock {
  const _FixedClock(this.instant);

  final DateTime instant;

  @override
  DateTime now() => instant;
}

final class _FixedIdGenerator implements IdGenerator {
  const _FixedIdGenerator(this.value);

  final String value;

  @override
  String generate() => value;
}
