import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';
import 'package:tindatrack/features/stock/presentation/providers/stock_providers.dart';

/// Live inventory movement history for the History tab.
final StreamProvider<List<StockMovement>> movementHistoryProvider =
    StreamProvider<List<StockMovement>>(
      (ref) => ref.watch(stockRepositoryProvider).watchMovementHistory(),
    );
