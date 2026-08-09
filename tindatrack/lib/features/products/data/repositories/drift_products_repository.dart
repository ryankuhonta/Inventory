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
import 'package:tindatrack/features/products/domain/entities/product_list_query.dart';
import 'package:tindatrack/features/products/domain/entities/update_product_input.dart';
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

  @override
  Future<Result<void>> archiveProduct(String id) async {
    try {
      final updatedAt = _clock.now().toUtc();
      final archived = await _dao.archiveProduct(
        id: id,
        updatedAt: updatedAt,
      );
      if (archived) return const Success<void>(null);

      final row = await _dao.getProductById(id);
      if (row == null) {
        return const FailureResult<void>(ProductNotFoundFailure());
      }
      return const FailureResult<void>(ArchivedProductFailure());
    } on Object catch (error) {
      return FailureResult<void>(
        PersistenceFailure(debugMessage: error.toString()),
      );
    }
  }

  final ProductsDao _dao;
  final IdGenerator _idGenerator;
  final Clock _clock;

  @override
  Future<Result<void>> restoreProduct(String id) async {
    try {
      final updatedAt = _clock.now().toUtc();
      final restored = await _dao.restoreProduct(
        id: id,
        updatedAt: updatedAt,
      );
      if (restored) return const Success<void>(null);

      final row = await _dao.getProductById(id);
      if (row == null) {
        return const FailureResult<void>(ProductNotFoundFailure());
      }
      return const FailureResult<void>(ActiveProductFailure());
    } on Object catch (error) {
      return FailureResult<void>(
        PersistenceFailure(debugMessage: error.toString()),
      );
    }
  }

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
  Future<Result<domain.Product>> getProduct(String id) async {
    try {
      final row = await _dao.getProductById(id);
      if (row == null) {
        return const FailureResult<domain.Product>(
          ProductNotFoundFailure(),
        );
      }
      if (row.isArchived) {
        return const FailureResult<domain.Product>(
          ArchivedProductFailure(),
        );
      }
      return Success<domain.Product>(_toDomain(row));
    } on Exception catch (error) {
      return FailureResult<domain.Product>(
        PersistenceFailure(debugMessage: error.toString()),
      );
    }
  }

  @override
  Future<Result<domain.Product>> updateProduct(
    String id,
    UpdateProductInput input,
  ) async {
    final target = await getProduct(id);
    if (target case FailureResult<domain.Product>()) return target;

    final barcode = _normalizeBarcode(input.barcode);
    try {
      final now = _clock.now().toUtc();
      final row = await _dao.updateProductDetails(
        id: id,
        name: input.name,
        category: input.category,
        unit: input.unit,
        sellingPrice: input.sellingPrice,
        lowStockThreshold: input.lowStockThreshold,
        barcode: barcode,
        updatedAt: now,
      );
      if (row == null) return getProduct(id);
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
  Stream<List<domain.Product>> watchArchivedProducts() {
    return _dao.watchArchivedProducts().map(
      (rows) => rows.map(_toDomain).toList(growable: false),
    );
  }

  @override
  Stream<List<domain.Product>> watchActiveProducts([
    ProductListQuery query = const ProductListQuery.defaultQuery(),
  ]) {
    return _dao
        .watchActiveProducts(_toParameters(query))
        .map((rows) => rows.map(_toDomain).toList(growable: false));
  }

  ProductsQueryParameters _toParameters(ProductListQuery query) {
    return ProductsQueryParameters(
      searchText: query.searchText,
      stockFilter: switch (query.stockFilter) {
        ProductStockFilter.all => ProductsStockFilterParameter.all,
        ProductStockFilter.lowStock => ProductsStockFilterParameter.lowStock,
        ProductStockFilter.outOfStock =>
          ProductsStockFilterParameter.outOfStock,
      },
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
