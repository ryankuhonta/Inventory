import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/features/stock/domain/entities/create_stock_movement_input.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';

void main() {
  test('movement type maps to exact persisted values', () {
    expect(StockMovementType.stockIn.persistedValue, 'stock_in');
    expect(StockMovementType.stockOut.persistedValue, 'stock_out');
    expect(
      StockMovementType.fromPersistedValue('stock_in'),
      StockMovementType.stockIn,
    );
    expect(
      StockMovementType.fromPersistedValue('stock_out'),
      StockMovementType.stockOut,
    );
    expect(
      () => StockMovementType.fromPersistedValue('adjustment'),
      throwsArgumentError,
    );
  });

  test('stock out reasons map to exact persisted values', () {
    expect(StockOutReason.sold.persistedValue, 'sold');
    expect(StockOutReason.damaged.persistedValue, 'damaged');
    expect(StockOutReason.lost.persistedValue, 'lost');
    expect(StockOutReason.personalUse.persistedValue, 'personal_use');
    expect(StockOutReason.correction.persistedValue, 'correction');
    expect(StockOutReason.defaultReason, StockOutReason.sold);
    expect(
      StockOutReason.fromPersistedValue('personal_use'),
      StockOutReason.personalUse,
    );
    expect(
      () => StockOutReason.fromPersistedValue('expired'),
      throwsArgumentError,
    );
  });

  test('create movement input carries metadata without generated fields', () {
    const input = CreateStockMovementInput(
      productId: 'product-1',
      type: StockMovementType.stockOut,
      quantity: 1,
      previousQuantity: 3,
      newQuantity: 2,
      productNameSnapshot: 'Rice',
      unitSnapshot: 'kg',
    );

    expect(input.reason, isNull);
    expect(input.productNameSnapshot, 'Rice');
    expect(input.unitSnapshot, 'kg');
  });
}
