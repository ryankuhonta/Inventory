import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tindatrack/app/providers.dart';
import 'package:tindatrack/core/database/daos/stock_movements_dao.dart';
import 'package:tindatrack/features/stock/data/repositories/drift_stock_repository.dart';
import 'package:tindatrack/features/stock/domain/repositories/stock_repository.dart';

/// Persistence-only stock movement DAO composed from the app database.
final stockMovementsDaoProvider = Provider<StockMovementsDao>(
  (ref) => StockMovementsDao(ref.watch(databaseProvider)),
);

/// Canonical stock repository for movement history foundations.
final stockRepositoryProvider = Provider<StockRepository>(
  (ref) => DriftStockRepository(
    dao: ref.watch(stockMovementsDaoProvider),
    idGenerator: ref.watch(idGeneratorProvider),
    clock: ref.watch(clockProvider),
  ),
);
