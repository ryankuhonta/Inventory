import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:tindatrack/core/database/daos/products_dao.dart';
import 'package:tindatrack/core/database/daos/stock_movements_dao.dart';
import 'package:tindatrack/core/database/generated_migrations.dart'
    as migrations;
import 'package:tindatrack/core/database/tables/products_table.dart';
import 'package:tindatrack/core/database/tables/stock_movements_table.dart';
import 'package:tindatrack/features/settings/domain/entities/full_restore_preview.dart';

part 'app_database.g.dart';

/// Local SQLite database entry point.
@DriftDatabase(
  tables: [Products, StockMovements],
  daos: [ProductsDao, StockMovementsDao],
)
class AppDatabase extends _$AppDatabase {
  /// Creates the production database, or uses [executor] for isolated tests.
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'tindatrack'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: migrations.stepByStep(
      from1To2: (migrator, schema) async {
        await migrator.createTable(schema.products);
        await migrator.createIndex(schema.productsActiveNameIdx);
      },
      from2To3: (migrator, schema) async {
        await migrator.createTable(schema.stockMovements);
        await migrator.createIndex(schema.stockMovementsProductCreatedAtIdx);
        await migrator.createIndex(schema.stockMovementsCreatedAtIdx);
      },
    ),
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Restores a validated full backup into an empty database atomically.
  Future<void> restoreFullBackup(FullRestorePreview preview) {
    if (!preview.canRestore) {
      throw StateError('Full restore preview has blocking errors.');
    }

    return transaction(() async {
      final existingProducts = await (select(products)..limit(1)).get();
      final existingMovements = await (select(stockMovements)..limit(1)).get();
      if (existingProducts.isNotEmpty || existingMovements.isNotEmpty) {
        throw StateError('Full restore requires an empty database.');
      }

      final productIds = preview.products.map((product) => product.id).toSet();
      final missingProductIds = preview.movements
          .map((movement) => movement.productId)
          .where((productId) => !productIds.contains(productId))
          .toSet();
      if (missingProductIds.isNotEmpty) {
        throw StateError('Full restore movement references a missing product.');
      }

      for (final product in preview.products) {
        await into(products).insert(
          ProductsCompanion.insert(
            id: product.id,
            name: product.name,
            category: Value(product.category),
            unit: product.unit,
            sellingPrice: product.sellingPrice,
            quantity: product.quantity,
            lowStockThreshold: product.lowStockThreshold,
            barcode: Value(product.barcode),
            isArchived: Value(product.isArchived),
            createdAt: product.createdAt.toUtc(),
            updatedAt: product.updatedAt.toUtc(),
          ),
        );
      }

      for (final movement in preview.movements) {
        await into(stockMovements).insert(
          StockMovementsCompanion.insert(
            id: movement.id,
            productId: movement.productId,
            type: movement.type.persistedValue,
            quantity: movement.quantity,
            previousQuantity: movement.previousQuantity,
            newQuantity: movement.newQuantity,
            reason: Value(movement.reason?.persistedValue),
            note: Value(movement.note),
            productNameSnapshot: movement.productNameSnapshot,
            unitSnapshot: movement.unitSnapshot,
            createdAt: movement.createdAt.toUtc(),
          ),
        );
      }
    });
  }

  /// Opens the underlying SQLite connection and verifies it can answer queries.
  Future<void> ensureReady() async {
    await customSelect('SELECT 1').getSingle();
  }
}
