import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/stock/domain/entities/create_stock_movement_input.dart';
import 'package:tindatrack/features/stock/domain/entities/record_stock_in_input.dart';
import 'package:tindatrack/features/stock/domain/entities/record_stock_out_input.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';

/// Stock movement operations available to application and presentation code.
abstract interface class StockRepository {
  /// Persists one stock movement audit row only.
  ///
  /// Product quantity mutation is deliberately outside Story 3.1.
  Future<Result<StockMovement>> recordMovementRow(
    CreateStockMovementInput input,
  );

  /// Atomically increases product quantity and records one Stock In movement.
  Future<Result<StockMovement>> recordStockIn(RecordStockInInput input);

  /// Atomically decreases product quantity and records one Stock Out movement.
  Future<Result<StockMovement>> recordStockOut(RecordStockOutInput input);

  /// Lists movement history newest first.
  Future<Result<List<StockMovement>>> listMovementHistory({String? productId});

  /// Lists distinct recent non-empty notes for one stock movement type.
  Future<Result<List<String>>> listRecentNotes({
    required StockMovementType type,
    int limit = 8,
  });

  /// Watches movement history newest first.
  Stream<List<StockMovement>> watchMovementHistory({String? productId});
}
