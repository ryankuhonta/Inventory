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
      dao: StockMovementsDao(database),
      idGenerator: ids,
      clock: _FixedClock(instant),
    );
  });

  tearDown(() => database.close());

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

  test('snapshots survive later product metadata changes', () async {
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

    final result = await repository.listMovementHistory(productId: 'product-1');

    final movement = (result as Success<List<StockMovement>>).value.single;
    expect(movement.productNameSnapshot, 'Rice');
    expect(movement.unitSnapshot, 'kg');
  });

  test('list and watch return domain entities newest first', () async {
    await repository.recordMovementRow(_input(note: 'older'));
    repository = DriftStockRepository(
      dao: StockMovementsDao(database),
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
        dao: _InvalidTypeStockMovementsDao(database),
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
      dao: StockMovementsDao(database),
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

db.ProductsCompanion _product({String id = 'product-1', String name = 'Rice'}) {
  final instant = DateTime.utc(2026, 7);
  return db.ProductsCompanion.insert(
    id: id,
    name: name,
    unit: 'kg',
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
