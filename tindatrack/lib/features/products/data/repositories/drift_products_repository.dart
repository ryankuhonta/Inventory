// Named dependency parameters keep repository composition explicit.
// ignore_for_file: prefer_initializing_formals

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:tindatrack/core/database/app_database.dart' as db;
import 'package:tindatrack/core/database/daos/products_dao.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/core/id/id_generator.dart';
import 'package:tindatrack/core/time/clock.dart';
import 'package:tindatrack/features/products/domain/entities/create_product_input.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart'
    as domain;
import 'package:tindatrack/features/products/domain/failures/product_failure.dart';
import 'package:tindatrack/features/products/domain/repositories/products_repository.dart';

const _sqliteConstraintUnique = 2067;

/// Drift-backed implementation of the product catalog repository.
final class DriftProductsRepository implements ProductRepository {
  /// Creates a repository with deterministic persistence dependencies.
  const DriftProductsRepository({
    required ProductsDao dao,
    required IdGenerator idGenerator,
    required Clock clock,
  }) : _dao = dao,
       _idGenerator = idGenerator,
       _clock = clock;

  final ProductsDao _dao;
  final IdGenerator _idGenerator;
  final Clock _clock;

  @override
  Future<Result<domain.Product>> createProduct(
    CreateProductInput input,
  ) async {
    final id = _idGenerator.generate();
    final now = _clock.now().toUtc();
    final barcode = _normalizeBarcode(input.barcode);

    try {
      final row = await _dao.insertProduct(
        db.ProductsCompanion.insert(
          id: id,
          name: input.name,
          category: Value(input.category),
          unit: input.unit,
          sellingPrice: input.sellingPrice,
          quantity: input.quantity,
          lowStockThreshold: input.lowStockThreshold,
          barcode: Value(barcode),
          createdAt: now,
          updatedAt: now,
        ),
      );
      return Success<domain.Product>(_toDomain(row));
    } on SqliteException catch (error) {
      if (_isDuplicateBarcode(error)) {
        return FailureResult<domain.Product>(
          DuplicateBarcodeFailure(debugMessage: error.toString()),
        );
      }
      return FailureResult<domain.Product>(
        PersistenceFailure(debugMessage: error.toString()),
      );
    } on Exception catch (error) {
      return FailureResult<domain.Product>(
        PersistenceFailure(debugMessage: error.toString()),
      );
    }
  }

  @override
  Stream<List<domain.Product>> watchActiveProducts() {
    return _dao.watchActiveProducts().map(
      (rows) => rows.map(_toDomain).toList(growable: false),
    );
  }

  String? _normalizeBarcode(String? barcode) {
    final normalized = barcode?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  bool _isDuplicateBarcode(SqliteException error) {
    return error.extendedResultCode == _sqliteConstraintUnique &&
        error.message.contains('products.barcode');
  }

  domain.Product _toDomain(db.Product row) {
    return domain.Product(
      id: row.id,
      name: row.name,
      category: row.category,
      unit: row.unit,
      sellingPrice: row.sellingPrice,
      quantity: row.quantity,
      lowStockThreshold: row.lowStockThreshold,
      barcode: row.barcode,
      isArchived: row.isArchived,
      createdAt: row.createdAt.toUtc(),
      updatedAt: row.updatedAt.toUtc(),
    );
  }
}
