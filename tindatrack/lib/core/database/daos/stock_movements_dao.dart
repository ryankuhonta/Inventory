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

  /// Counts every stock movement row.
  Future<int> countAllMovements() async {
    final count = countAll();
    final query = selectOnly(stockMovements)..addColumns([count]);
    return query.map((row) => row.read(count)!).getSingle();
  }

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

  /// Lists distinct recent non-empty notes for one persisted movement [type].
  Future<List<String>> listRecentNotes({required String type, int limit = 8}) {
    final safeLimit = limit <= 0 ? 0 : limit;
    return customSelect(
      '''
      SELECT suggestion
      FROM (
        SELECT
          TRIM(note) AS suggestion,
          created_at AS latest_created_at,
          id AS latest_id,
          ROW_NUMBER() OVER (
            PARTITION BY LOWER(TRIM(note))
            ORDER BY created_at DESC, id DESC
          ) AS note_rank
        FROM stock_movements
        WHERE type = ? AND note IS NOT NULL AND TRIM(note) <> ''
      )
      WHERE note_rank = 1
      ORDER BY latest_created_at DESC, latest_id DESC
      LIMIT ?
      ''',
      variables: [Variable<String>(type), Variable<int>(safeLimit)],
      readsFrom: {stockMovements},
    ).map((row) => row.read<String>('suggestion')).get();
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
