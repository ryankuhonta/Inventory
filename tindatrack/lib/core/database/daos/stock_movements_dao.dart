import 'package:drift/drift.dart';
import 'package:tindatrack/core/database/app_database.dart';
import 'package:tindatrack/core/database/tables/stock_movements_table.dart';

part 'stock_movements_dao.g.dart';

/// Persistence-only filters for movement history queries.
final class StockMovementHistoryQuery {
  /// Creates movement history query parameters.
  const StockMovementHistoryQuery({this.productId});

  /// Optional product identity for product-scoped history.
  final String? productId;
}

/// Persistence-only access to stock movement audit rows.
@DriftAccessor(tables: [StockMovements])
class StockMovementsDao extends DatabaseAccessor<AppDatabase>
    with _$StockMovementsDaoMixin {
  /// Creates a stock movements DAO attached to [attachedDatabase].
  StockMovementsDao(super.attachedDatabase);

  /// Inserts one movement and returns the persisted row.
  Future<StockMovement> insertMovement(StockMovementsCompanion movement) {
    return into(stockMovements).insertReturning(movement);
  }

  /// Lists movement history newest first.
  Future<List<StockMovement>> listMovements([
    StockMovementHistoryQuery query = const StockMovementHistoryQuery(),
  ]) {
    return _historyQuery(query).get();
  }

  /// Watches movement history newest first.
  Stream<List<StockMovement>> watchMovements([
    StockMovementHistoryQuery query = const StockMovementHistoryQuery(),
  ]) {
    return _historyQuery(query).watch();
  }

  SimpleSelectStatement<$StockMovementsTable, StockMovement> _historyQuery(
    StockMovementHistoryQuery query,
  ) {
    final selectStatement = select(stockMovements);
    final productId = query.productId;
    if (productId != null) {
      selectStatement.where((movement) => movement.productId.equals(productId));
    }
    selectStatement.orderBy([
      (movement) => OrderingTerm.desc(movement.createdAt),
      (movement) => OrderingTerm.desc(movement.id),
    ]);
    return selectStatement;
  }
}
