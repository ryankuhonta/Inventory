import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/stock/domain/entities/create_stock_movement_input.dart';
import 'package:tindatrack/features/stock/domain/entities/record_stock_in_input.dart';
import 'package:tindatrack/features/stock/domain/entities/record_stock_out_input.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';
import 'package:tindatrack/features/stock/domain/repositories/stock_repository.dart';
import 'package:tindatrack/features/stock/presentation/controllers/stock_in_controller.dart';
import 'package:tindatrack/features/stock/presentation/providers/stock_providers.dart';

void main() {
  test('invalid quantity is rejected before repository call', () async {
    final repository = _StockRepository();
    final container = ProviderContainer.test(
      overrides: [stockRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final saved = await container
        .read(stockInControllerProvider('product-1').notifier)
        .submit(const StockInFormValues(quantity: '0', note: 'delivery'));

    final state = container.read(stockInControllerProvider('product-1'));
    expect(saved, isNull);
    expect(repository.stockInCalls, 0);
    expect(
      state.errorFor(StockInField.quantity),
      'Enter a quantity greater than 0.',
    );
  });

  test(
    'successful stock in returns movement and guards duplicate pending saves',
    () async {
      final completer = CompleterResult<StockMovement>();
      final repository = _StockRepository(onStockIn: (_) => completer.future);
      final container = ProviderContainer.test(
        overrides: [stockRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final first = container
          .read(stockInControllerProvider('product-1').notifier)
          .submit(const StockInFormValues(quantity: '3', note: ' delivery '));
      final second = await container
          .read(stockInControllerProvider('product-1').notifier)
          .submit(const StockInFormValues(quantity: '3', note: 'again'));

      expect(second, isNull);
      expect(repository.stockInCalls, 1);
      expect(repository.lastInput?.quantity, 3);
      expect(repository.lastInput?.note, ' delivery ');
      expect(
        container.read(stockInControllerProvider('product-1')).isSaving,
        isTrue,
      );

      completer.complete(Success<StockMovement>(_movement(newQuantity: 8)));
      final movement = await first;

      expect(movement?.newQuantity, 8);
      expect(
        container.read(stockInControllerProvider('product-1')).isSaving,
        isFalse,
      );
    },
  );

  test('typed failures map to friendly copy without debug text', () async {
    final repository = _StockRepository(
      onStockIn: (_) async => const FailureResult<StockMovement>(
        PersistenceFailure(debugMessage: 'PRIVATE_DATABASE'),
      ),
    );
    final container = ProviderContainer.test(
      overrides: [stockRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final saved = await container
        .read(stockInControllerProvider('product-1').notifier)
        .submit(const StockInFormValues(quantity: '3', note: ''));

    final state = container.read(stockInControllerProvider('product-1'));
    expect(saved, isNull);
    expect(state.message, "We couldn't record stock in. Please try again.");
    expect(state.message, isNot(contains('PRIVATE_DATABASE')));
  });
}

final class CompleterResult<T> {
  final _completer = Completer<Result<T>>();
  Future<Result<T>> get future => _completer.future;
  void complete(Result<T> result) => _completer.complete(result);
}

final class _StockRepository implements StockRepository {
  _StockRepository({this.onStockIn});

  final Future<Result<StockMovement>> Function(RecordStockInInput input)?
  onStockIn;
  int stockInCalls = 0;
  RecordStockInInput? lastInput;

  @override
  Future<Result<StockMovement>> recordStockIn(RecordStockInInput input) {
    stockInCalls++;
    lastInput = input;
    return onStockIn?.call(input) ??
        Future.value(Success<StockMovement>(_movement(newQuantity: 8)));
  }

  @override
  Future<Result<StockMovement>> recordMovementRow(
    CreateStockMovementInput input,
  ) => throw UnimplementedError();

  @override
  Future<Result<StockMovement>> recordStockOut(RecordStockOutInput input) =>
      throw UnimplementedError();

  @override
  Future<Result<List<StockMovement>>> listMovementHistory({
    String? productId,
  }) => throw UnimplementedError();

  @override
  Future<Result<List<String>>> listRecentNotes({
    required StockMovementType type,
    int limit = 8,
  }) async => const Success<List<String>>(<String>[]);
  @override
  Stream<List<StockMovement>> watchMovementHistory({String? productId}) =>
      const Stream.empty();
}

StockMovement _movement({required int newQuantity}) {
  return StockMovement(
    id: 'movement-1',
    productId: 'product-1',
    type: StockMovementType.stockIn,
    quantity: 3,
    previousQuantity: 5,
    newQuantity: newQuantity,
    reason: null,
    note: 'delivery',
    productNameSnapshot: 'Rice',
    unitSnapshot: 'pcs',
    createdAt: DateTime.utc(2026, 7, 9),
  );
}
