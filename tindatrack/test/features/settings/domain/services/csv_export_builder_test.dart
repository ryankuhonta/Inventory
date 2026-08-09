import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/settings/domain/services/csv_export_builder.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';

void main() {
  test('builds product CSV with archived status and escaped values', () {
    final bundle = const CsvExportBuilder().build(
      products: [
        Product(
          id: 'p1',
          name: 'Milo, 24g',
          category: 'Drinks "Hot"',
          unit: 'pcs',
          sellingPrice: 12,
          quantity: 20,
          lowStockThreshold: 5,
          barcode: '4801234567890',
          isArchived: false,
          createdAt: DateTime.utc(2026, 8, 9, 1, 2, 3),
          updatedAt: DateTime.utc(2026, 8, 9, 4, 5, 6),
        ),
        Product(
          id: 'p2',
          name: 'Old Soap',
          category: null,
          unit: 'pcs',
          sellingPrice: 18.5,
          quantity: 0,
          lowStockThreshold: 3,
          barcode: null,
          isArchived: true,
          createdAt: DateTime.utc(2026, 7, 20, 9),
          updatedAt: DateTime.utc(2026, 8, 1, 14, 30),
        ),
      ],
      movements: const [],
      exportedAt: DateTime.utc(2026, 8, 9, 10, 15),
    );

    final expectedMiloRow = [
      '"Milo, 24g","Drinks ""Hot""",pcs,12.00,20,5,',
      '4801234567890,Active,2026-08-09 01:02:03 UTC,',
      '2026-08-09 04:05:06 UTC',
    ].join();

    expect(bundle.productsFileName, 'tindatrack-products-20260809-1015.csv');
    expect(bundle.productsCsv, contains(expectedMiloRow));
    expect(
      bundle.productsCsv,
      contains('Old Soap,,pcs,18.50,0,3,,Archived'),
    );
  });

  test('builds stock history CSV from movement snapshots', () {
    final bundle = const CsvExportBuilder().build(
      products: const [],
      movements: [
        StockMovement(
          id: 'm1',
          productId: 'p1',
          type: StockMovementType.stockOut,
          quantity: 2,
          previousQuantity: 10,
          newQuantity: 8,
          reason: StockOutReason.sold,
          note: 'Sold, morning\nrush',
          productNameSnapshot: 'Coffee',
          unitSnapshot: 'sachet',
          createdAt: DateTime.utc(2026, 8, 9, 6, 30),
        ),
      ],
      exportedAt: DateTime.utc(2026, 8, 9, 10, 15),
    );

    final expectedMovementRow = [
      '2026-08-09 06:30:00 UTC,Stock Out,Coffee,2,10,8,sachet,',
      '"Sold, morning\nrush"',
    ].join();

    expect(
      bundle.stockHistoryFileName,
      'tindatrack-stock-history-20260809-1015.csv',
    );
    expect(bundle.stockHistoryCsv, contains(expectedMovementRow));
  });
}
