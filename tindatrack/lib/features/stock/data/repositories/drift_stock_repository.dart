// Named dependency parameters keep repository composition explicit.
// ignore_for_file: prefer_initializing_formals

import 'package:drift/drift.dart';
import 'package:tindatrack/core/database/app_database.dart' as db;
import 'package:tindatrack/core/database/daos/products_dao.dart';
import 'package:tindatrack/core/database/daos/stock_movements_dao.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/core/id/id_generator.dart';
import 'package:tindatrack/core/time/clock.dart';
import 'package:tindatrack/features/stock/domain/entities/create_stock_movement_input.dart';
import 'package:tindatrack/features/stock/domain/entities/record_stock_in_input.dart';
import 'package:tindatrack/features/stock/domain/entities/record_stock_out_input.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart'
    as domain;
import 'package:tindatrack/features/stock/domain/failures/stock_failure.dart';
import 'package:tindatrack/features/stock/domain/repositories/stock_repository.dart';

/// Drift-backed implementation of stock movement history persistence.
final class DriftStockRepository implements StockRepository {
  /// Creates a repository with deterministic persistence dependencies.
  const DriftStockRepository({
    required ProductsDao productsDao,
    required StockMovementsDao stockMovementsDao,
    required IdGenerator idGenerator,
    required Clock clock,
  }) : _productsDao = productsDao,
       _stockMovementsDao = stockMovementsDao,
       _idGenerator = idGenerator,
       _clock = clock;

  final ProductsDao _productsDao;
  final StockMovementsDao _stockMovementsDao;
  final IdGenerator _idGenerator;
  final Clock _clock;

  @override
  Future<Result<List<domain.StockMovement>>> listMovementHistory({
    String? productId,
  }) async {
    try {
      final rows = await _stockMovementsDao.listMovements(
        StockMovementHistoryQuery(productId: productId),
      );
      return Success<List<domain.StockMovement>>(
        rows.map(_toDomain).toList(growable: false),
      );
    } on Object catch (error) {
      return FailureResult<List<domain.StockMovement>>(
        PersistenceFailure(debugMessage: error.toString()),
      );
    }
  }

  @override
  Future<Result<domain.StockMovement>> recordMovementRow(
    CreateStockMovementInput input,
  ) async {
    final validation = _validateMovementQuantities(input);
    if (validation != null) {
      return FailureResult<domain.StockMovement>(validation);
    }

    final id = _idGenerator.generate();
    final now = _clock.now().toUtc();
    final reason = _reasonFor(input);

    try {
      final row = await _stockMovementsDao.insertMovement(
        db.StockMovementsCompanion.insert(
          id: id,
          productId: input.productId,
          type: input.type.persistedValue,
          quantity: input.quantity,
          previousQuantity: input.previousQuantity,
          newQuantity: input.newQuantity,
          reason: Value(reason?.persistedValue),
          note: Value(_normalizeNote(input.note)),
          productNameSnapshot: input.productNameSnapshot,
          unitSnapshot: input.unitSnapshot,
          createdAt: now,
        ),
      );
      return Success<domain.StockMovement>(_toDomain(row));
    } on Exception catch (error) {
      return FailureResult<domain.StockMovement>(
        PersistenceFailure(debugMessage: error.toString()),
      );
    }
  }

  @override
  Future<Result<domain.StockMovement>> recordStockIn(
    RecordStockInInput input,
  ) async {
    if (input.quantity <= 0) {
      return const FailureResult<domain.StockMovement>(
        StockMovementValidationFailure(
          field: StockMovementField.quantity,
          issue: StockMovementValidationIssue.notPositive,
        ),
      );
    }

    try {
      return await _productsDao.attachedDatabase
          .transaction<Result<domain.StockMovement>>(() async {
            final product = await _productsDao.getProductById(input.productId);
            if (product == null) {
              return const FailureResult<domain.StockMovement>(
                StockProductNotFoundFailure(),
              );
            }
            if (product.isArchived) {
              return const FailureResult<domain.StockMovement>(
                StockArchivedProductFailure(),
              );
            }

            final previousQuantity = product.quantity;
            final newQuantity = previousQuantity + input.quantity;
            final id = _idGenerator.generate();
            final now = _clock.now().toUtc();
            final updatedProduct = await _productsDao
                .updateActiveProductQuantity(
                  id: product.id,
                  quantity: newQuantity,
                  updatedAt: now,
                );
            if (updatedProduct == null) {
              final currentProduct = await _productsDao.getProductById(
                product.id,
              );
              if (currentProduct == null) {
                return const FailureResult<domain.StockMovement>(
                  StockProductNotFoundFailure(),
                );
              }
              if (currentProduct.isArchived) {
                return const FailureResult<domain.StockMovement>(
                  StockArchivedProductFailure(),
                );
              }
              throw StateError('Active product disappeared during Stock In');
            }

            final row = await _stockMovementsDao.insertMovement(
              db.StockMovementsCompanion.insert(
                id: id,
                productId: product.id,
                type: domain.StockMovementType.stockIn.persistedValue,
                quantity: input.quantity,
                previousQuantity: previousQuantity,
                newQuantity: newQuantity,
                note: Value(_normalizeNote(input.note)),
                productNameSnapshot: product.name,
                unitSnapshot: product.unit,
                createdAt: now,
              ),
            );

            return Success<domain.StockMovement>(_toDomain(row));
          });
    } on Object catch (error) {
      return FailureResult<domain.StockMovement>(
        PersistenceFailure(debugMessage: error.toString()),
      );
    }
  }

  @override
  Future<Result<domain.StockMovement>> recordStockOut(
    RecordStockOutInput input,
  ) async {
    if (input.quantity <= 0) {
      return const FailureResult<domain.StockMovement>(
        StockMovementValidationFailure(
          field: StockMovementField.quantity,
          issue: StockMovementValidationIssue.notPositive,
        ),
      );
    }

    try {
      return await _productsDao.attachedDatabase
          .transaction<Result<domain.StockMovement>>(() async {
            final product = await _productsDao.getProductById(input.productId);
            if (product == null) {
              return const FailureResult<domain.StockMovement>(
                StockProductNotFoundFailure(),
              );
            }
            if (product.isArchived) {
              return const FailureResult<domain.StockMovement>(
                StockArchivedProductFailure(),
              );
            }
            if (input.quantity > product.quantity) {
              return FailureResult<domain.StockMovement>(
                StockInsufficientQuantityFailure(
                  availableQuantity: product.quantity,
                  requestedQuantity: input.quantity,
                ),
              );
            }

            final previousQuantity = product.quantity;
            final newQuantity = previousQuantity - input.quantity;
            final id = _idGenerator.generate();
            final now = _clock.now().toUtc();
            final reason = input.reason ?? domain.StockOutReason.defaultReason;
            final updatedProduct = await _productsDao
                .updateActiveProductQuantity(
                  id: product.id,
                  quantity: newQuantity,
                  updatedAt: now,
                );
            if (updatedProduct == null) {
              final currentProduct = await _productsDao.getProductById(
                product.id,
              );
              if (currentProduct == null) {
                return const FailureResult<domain.StockMovement>(
                  StockProductNotFoundFailure(),
                );
              }
              if (currentProduct.isArchived) {
                return const FailureResult<domain.StockMovement>(
                  StockArchivedProductFailure(),
                );
              }
              throw StateError('Active product disappeared during Stock Out');
            }

            final row = await _stockMovementsDao.insertMovement(
              db.StockMovementsCompanion.insert(
                id: id,
                productId: product.id,
                type: domain.StockMovementType.stockOut.persistedValue,
                quantity: input.quantity,
                previousQuantity: previousQuantity,
                newQuantity: newQuantity,
                reason: Value(reason.persistedValue),
                note: Value(_normalizeNote(input.note)),
                productNameSnapshot: product.name,
                unitSnapshot: product.unit,
                createdAt: now,
              ),
            );

            return Success<domain.StockMovement>(_toDomain(row));
          });
    } on Object catch (error) {
      return FailureResult<domain.StockMovement>(
        PersistenceFailure(debugMessage: error.toString()),
      );
    }
  }

  @override
  Stream<List<domain.StockMovement>> watchMovementHistory({
    String? productId,
  }) {
    return _stockMovementsDao
        .watchMovements(StockMovementHistoryQuery(productId: productId))
        .map((rows) => rows.map(_toDomain).toList(growable: false));
  }

  StockMovementValidationFailure? _validateMovementQuantities(
    CreateStockMovementInput input,
  ) {
    if (input.quantity <= 0) {
      return const StockMovementValidationFailure(
        field: StockMovementField.quantity,
        issue: StockMovementValidationIssue.notPositive,
      );
    }
    if (input.previousQuantity < 0) {
      return const StockMovementValidationFailure(
        field: StockMovementField.previousQuantity,
        issue: StockMovementValidationIssue.negative,
      );
    }
    if (input.newQuantity < 0) {
      return const StockMovementValidationFailure(
        field: StockMovementField.newQuantity,
        issue: StockMovementValidationIssue.negative,
      );
    }
    return null;
  }

  domain.StockOutReason? _reasonFor(CreateStockMovementInput input) {
    return switch (input.type) {
      domain.StockMovementType.stockIn => null,
      domain.StockMovementType.stockOut =>
        input.reason ?? domain.StockOutReason.defaultReason,
    };
  }

  String? _normalizeNote(String? note) {
    final normalized = note?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  domain.StockMovement _toDomain(db.StockMovement row) {
    return domain.StockMovement(
      id: row.id,
      productId: row.productId,
      type: domain.StockMovementType.fromPersistedValue(row.type),
      quantity: row.quantity,
      previousQuantity: row.previousQuantity,
      newQuantity: row.newQuantity,
      reason: row.reason == null
          ? null
          : domain.StockOutReason.fromPersistedValue(row.reason!),
      note: row.note,
      productNameSnapshot: row.productNameSnapshot,
      unitSnapshot: row.unitSnapshot,
      createdAt: row.createdAt.toUtc(),
    );
  }
}
