import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tindatrack/app/providers.dart';
import 'package:tindatrack/core/database/daos/stock_movements_dao.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';
import 'package:tindatrack/features/stock/data/repositories/drift_stock_repository.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';
import 'package:tindatrack/features/stock/domain/repositories/stock_repository.dart';

/// Persistence-only stock movement DAO composed from the app database.
final stockMovementsDaoProvider = Provider<StockMovementsDao>(
  (ref) => StockMovementsDao(ref.watch(databaseProvider)),
);

/// Canonical stock repository for movement history foundations.
final stockRepositoryProvider = Provider<StockRepository>(
  (ref) => DriftStockRepository(
    productsDao: ref.watch(productsDaoProvider),
    stockMovementsDao: ref.watch(stockMovementsDaoProvider),
    idGenerator: ref.watch(idGeneratorProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Recent same-context note suggestions for stock movement forms.
// ignore: specify_nonobvious_property_types
final stockNoteSuggestionsProvider = FutureProvider.autoDispose
    .family<List<String>, StockMovementType>((ref, type) async {
      final result = await ref
          .watch(stockRepositoryProvider)
          .listRecentNotes(type: type);
      return switch (result) {
        Success<List<String>>(:final value) => value,
        FailureResult<List<String>>() => const <String>[],
      };
    });
