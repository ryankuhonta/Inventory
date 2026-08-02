import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:tindatrack/core/database/daos/products_dao.dart';
import 'package:tindatrack/core/database/daos/stock_movements_dao.dart';
import 'package:tindatrack/core/database/generated_migrations.dart'
    as migrations;
import 'package:tindatrack/core/database/tables/products_table.dart';
import 'package:tindatrack/core/database/tables/stock_movements_table.dart';

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

  /// Opens the underlying SQLite connection and verifies it can answer queries.
  Future<void> ensureReady() async {
    await customSelect('SELECT 1').getSingle();
  }
}
