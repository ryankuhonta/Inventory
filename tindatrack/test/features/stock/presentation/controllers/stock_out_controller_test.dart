import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/stock/domain/entities/create_stock_movement_input.dart';
import 'package:tindatrack/features/stock/domain/entities/record_stock_in_input.dart';
import 'package:tindatrack/features/stock/domain/entities/record_stock_out_input.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';
import 'package:tindatrack/features/stock/domain/failures/stock_failure.dart';
import 'package:tindatrack/features/stock/domain/repositories/stock_repository.dart';
import 'package:tindatrack/features/stock/presentation/controllers/stock_out_controller.dart';
import 'package:tindatrack/features/stock/presentation/providers/stock_providers.dart';

void main() {
  test('invalid quantity is rejected before repository call', () async {
    final repository = _StockRepository();
    final container = ProviderContainer.test(
      overrides: [stockRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final saved = await container
        .read(stockOutControllerProvider('product-1').notifier)
        .submit(
          const StockOutFormValues(quantity: '0', note: 'sold'),
          availableQuantity: 5,
        );

    final state = container.read(stockOutControllerProvider('product-1'));
    expect(saved, isNull);
    expect(repository.stockOutCalls, 0);
    expect(
      state.errorFor(StockOutField.quantity),
      'Enter a quantity greater than 0.',
    );
  });

  test('excessive quantity is rejected before repository call', () async {
    final repository = _StockRepository();
    final container = ProviderContainer.test(
      overrides: [stockRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final saved = await container
        .read(stockOutControllerProvider('product-1').notifier)
        .submit(
          const StockOutFormValues(quantity: '6', note: ''),
          availableQuantity: 5,
        );

    final state = container.read(stockOutControllerProvider('product-1'));
    expect(saved, isNull);
    expect(repository.stockOutCalls, 0);
    expect(
      state.errorFor(StockOutField.quantity),
      'Not enough stock available.',
    );
  });

  test(
    'successful stock out returns movement and guards duplicate pending saves',
    () async {
      final completer = CompleterResult<StockMovement>();
      final repository = _StockRepository(onStockOut: (_) => completer.future);
      final container = ProviderContainer.test(
        overrides: [stockRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final first = container
          .read(stockOutControllerProvider('product-1').notifier)
          .submit(
            const StockOutFormValues(quantity: '3', note: ' sold '),
            availableQuantity: 5,
          );
      final second = await container
          .read(stockOutControllerProvider('product-1').notifier)
          .submit(
            const StockOutFormValues(quantity: '3', note: 'again'),
            availableQuantity: 5,
          );

      expect(second, isNull);
      expect(repository.stockOutCalls, 1);
      expect(repository.lastInput?.quantity, 3);
      expect(repository.lastInput?.reason, isNull);
      expect(repository.lastInput?.note, ' sold ');
      expect(
        container.read(stockOutControllerProvider('product-1')).isSaving,
        isTrue,
      );

      completer.complete(Success<StockMovement>(_movement(newQuantity: 2)));
      final movement = await first;

      expect(movement?.newQuantity, 2);
      expect(movement?.reason, StockOutReason.sold);
      expect(
        container.read(stockOutControllerProvider('product-1')).isSaving,
        isFalse,
      );
    },
  );

  test(
    'repository insufficient failure maps to inline quantity copy',
    () async {
      final repository = _StockRepository(
        onStockOut: (_) async => const FailureResult<StockMovement>(
          StockInsufficientQuantityFailure(
            availableQuantity: 5,
            requestedQuantity: 6,
            debugMessage: 'PRIVATE_STOCK',
          ),
        ),
      );
      final container = ProviderContainer.test(
        overrides: [stockRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final saved = await container
          .read(stockOutControllerProvider('product-1').notifier)
          .submit(
            const StockOutFormValues(quantity: '6', note: ''),
          );

      final state = container.read(stockOutControllerProvider('product-1'));
      expect(saved, isNull);
      expect(repository.stockOutCalls, 1);
      expect(
        state.errorFor(StockOutField.quantity),
        'Not enough stock available.',
      );
      expect(
        state.errorFor(StockOutField.quantity),
        isNot(contains('PRIVATE')),
      );
    },
  );

  test('typed failures map to friendly copy without debug text', () async {
    final repository = _StockRepository(
      onStockOut: (_) async => const FailureResult<StockMovement>(
        PersistenceFailure(debugMessage: 'PRIVATE_DATABASE'),
      ),
    );
    final container = ProviderContainer.test(
      overrides: [stockRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final saved = await container
        .read(stockOutControllerProvider('product-1').notifier)
        .submit(
          const StockOutFormValues(quantity: '3', note: ''),
          availableQuantity: 5,
        );

    final state = container.read(stockOutControllerProvider('product-1'));
    expect(saved, isNull);
    expect(state.message, "We couldn't record stock out. Please try again.");
    expect(state.message, isNot(contains('PRIVATE_DATABASE')));
  });
}

final class CompleterResult<T> {
  final _completer = Completer<Result<T>>();
  Future<Result<T>> get future => _completer.future;
  void complete(Result<T> result) => _completer.complete(result);
}

final class _StockRepository implements StockRepository {
  _StockRepository({this.onStockOut});

  final Future<Result<StockMovement>> Function(RecordStockOutInput input)?
  onStockOut;
  int stockOutCalls = 0;
  RecordStockOutInput? lastInput;

  @override
  Future<Result<StockMovement>> recordStockOut(RecordStockOutInput input) {
    stockOutCalls++;
    lastInput = input;
    return onStockOut?.call(input) ??
        Future.value(Success<StockMovement>(_movement(newQuantity: 2)));
  }

  @override
  Future<Result<StockMovement>> recordMovementRow(
    CreateStockMovementInput input,
  ) => throw UnimplementedError();

  @override
  Future<Result<StockMovement>> recordStockIn(RecordStockInInput input) =>
      throw UnimplementedError();

  @override
  Future<Result<List<StockMovement>>> listMovementHistory({
    String? productId,
  }) => throw UnimplementedError();

  @override
  Stream<List<StockMovement>> watchMovementHistory({String? productId}) =>
      const Stream.empty();
}

StockMovement _movement({required int newQuantity}) {
  return StockMovement(
    id: 'movement-1',
    productId: 'product-1',
    type: StockMovementType.stockOut,
    quantity: 3,
    previousQuantity: 5,
    newQuantity: newQuantity,
    reason: StockOutReason.sold,
    note: 'sold',
    productNameSnapshot: 'Rice',
    unitSnapshot: 'pcs',
    createdAt: DateTime.utc(2026, 7, 10),
  );
}
