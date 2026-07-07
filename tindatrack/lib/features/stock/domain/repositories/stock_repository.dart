import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/stock/domain/entities/create_stock_movement_input.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';

/// Stock movement operations available to application and presentation code.
abstract interface class StockRepository {
  /// Persists one stock movement audit row only.
  ///
  /// Product quantity mutation is deliberately outside Story 3.1.
  Future<Result<StockMovement>> recordMovementRow(
    CreateStockMovementInput input,
  );

  /// Lists movement history newest first.
  Future<Result<List<StockMovement>>> listMovementHistory({String? productId});

  /// Watches movement history newest first.
  Stream<List<StockMovement>> watchMovementHistory({String? productId});
}
