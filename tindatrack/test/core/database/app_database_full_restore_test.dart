import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/database/app_database.dart';
import 'package:tindatrack/features/settings/domain/entities/full_restore_preview.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('restoreFullBackup preserves product and movement fields', () async {
    final preview = _preview();

    await database.restoreFullBackup(preview);

    final products = await database.select(database.products).get();
    final movements = await database.select(database.stockMovements).get();

    expect(products, hasLength(1));
    expect(products.single.id, 'product-1');
    expect(products.single.name, 'Rice');
    expect(products.single.category, 'Staples');
    expect(products.single.unit, 'kg');
    expect(products.single.sellingPrice, 55.5);
    expect(products.single.quantity, 9);
    expect(products.single.lowStockThreshold, 3);
    expect(products.single.barcode, '480001');
    expect(products.single.isArchived, isTrue);
    expect(products.single.createdAt.toUtc(), DateTime.utc(2026, 8, 1, 1));
    expect(products.single.updatedAt.toUtc(), DateTime.utc(2026, 8, 2, 2));

    expect(movements, hasLength(1));
    expect(movements.single.id, 'movement-1');
    expect(movements.single.productId, 'product-1');
    expect(movements.single.type, StockMovementType.stockOut.persistedValue);
    expect(movements.single.quantity, 3);
    expect(movements.single.previousQuantity, 12);
    expect(movements.single.newQuantity, 9);
    expect(movements.single.reason, StockOutReason.sold.persistedValue);
    expect(movements.single.note, 'morning sale');
    expect(movements.single.productNameSnapshot, 'Rice');
    expect(movements.single.unitSnapshot, 'kg');
    expect(movements.single.createdAt.toUtc(), DateTime.utc(2026, 8, 3, 3));
  });

  test('restoreFullBackup requires an empty database', () async {
    await database.restoreFullBackup(_preview());

    await expectLater(
      database.restoreFullBackup(_preview(productId: 'product-2')),
      throwsStateError,
    );
  });

  test(
    'restoreFullBackup rejects movement references before writing',
    () async {
      final preview = _preview(movementProductId: 'missing-product');

      await expectLater(database.restoreFullBackup(preview), throwsStateError);

      expect(await database.select(database.products).get(), isEmpty);
      expect(await database.select(database.stockMovements).get(), isEmpty);
    },
  );
  test(
    'restoreFullBackup rolls back products when an insert fails',
    () async {
      final preview = _previewWithDuplicateBarcode();

      await expectLater(database.restoreFullBackup(preview), throwsA(anything));

      expect(await database.select(database.products).get(), isEmpty);
      expect(await database.select(database.stockMovements).get(), isEmpty);
    },
  );
}

FullRestorePreview _previewWithDuplicateBarcode() {
  final first = _preview().products.single;
  return FullRestorePreview(
    products: [
      first,
      FullRestoreProductRow(
        sourceRowNumber: 3,
        id: 'product-2',
        name: 'Soap',
        unit: 'pcs',
        sellingPrice: 18,
        quantity: 2,
        lowStockThreshold: 1,
        barcode: first.barcode,
        isArchived: false,
        createdAt: DateTime.utc(2026, 8, 4),
        updatedAt: DateTime.utc(2026, 8, 4),
      ),
    ],
    movements: const [],
    errors: const [],
  );
}

FullRestorePreview _preview({
  String productId = 'product-1',
  String movementProductId = 'product-1',
}) {
  return FullRestorePreview(
    products: [
      FullRestoreProductRow(
        sourceRowNumber: 2,
        id: productId,
        name: 'Rice',
        category: 'Staples',
        unit: 'kg',
        sellingPrice: 55.5,
        quantity: 9,
        lowStockThreshold: 3,
        barcode: '480001',
        isArchived: true,
        createdAt: DateTime.utc(2026, 8, 1, 1),
        updatedAt: DateTime.utc(2026, 8, 2, 2),
      ),
    ],
    movements: [
      FullRestoreMovementRow(
        sourceRowNumber: 2,
        id: 'movement-1',
        productId: movementProductId,
        type: StockMovementType.stockOut,
        quantity: 3,
        previousQuantity: 12,
        newQuantity: 9,
        reason: StockOutReason.sold,
        note: 'morning sale',
        productNameSnapshot: 'Rice',
        unitSnapshot: 'kg',
        createdAt: DateTime.utc(2026, 8, 3, 3),
      ),
    ],
    errors: const [],
  );
}
