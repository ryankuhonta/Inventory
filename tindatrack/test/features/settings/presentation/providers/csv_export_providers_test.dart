import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/settings/domain/entities/csv_export_bundle.dart';
import 'package:tindatrack/features/settings/domain/services/csv_export_builder.dart';
import 'package:tindatrack/features/settings/presentation/providers/csv_export_providers.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';

void main() {
  test('exportCsv builds and shares both CSV files', () async {
    CsvExportBundle? shared;
    final controller = CsvExportController(
      readProducts: () async => Success<List<Product>>([
        _product('p1', 'Rice'),
      ]),
      readMovements: () async => Success<List<StockMovement>>([
        _movement('m1'),
      ]),
      builder: const CsvExportBuilder(),
      shareBundle: (bundle) async {
        shared = bundle;
      },
      saveBundle: (_) async {},
      exportedAt: () => DateTime.utc(2026, 8, 9, 10, 15),
    );

    final result = await controller.exportCsv();

    expect(result, isA<Success<CsvExportSummary>>());
    expect(shared?.productsFileName, 'tindatrack-products-20260809-1015.csv');
    expect(
      shared?.stockHistoryFileName,
      'tindatrack-stock-history-20260809-1015.csv',
    );
    expect(shared?.productsCsv, contains('Rice'));
    expect(shared?.stockHistoryCsv, contains('Stock In'));
  });

  test('saveCsvToDownloads uses the save handoff', () async {
    CsvExportBundle? saved;
    var shareCalls = 0;
    final controller = CsvExportController(
      readProducts: () async => const Success<List<Product>>([]),
      readMovements: () async => const Success<List<StockMovement>>([]),
      builder: const CsvExportBuilder(),
      shareBundle: (_) async {
        shareCalls++;
      },
      saveBundle: (bundle) async {
        saved = bundle;
      },
      exportedAt: () => DateTime.utc(2026, 8, 9, 10, 15),
    );

    final result = await controller.saveCsvToDownloads();

    expect(result, isA<Success<CsvExportSummary>>());
    expect(shareCalls, 0);
    expect(saved?.productsFileName, 'tindatrack-products-20260809-1015.csv');
  });
  test(
    'exportCsv returns failure without sharing when product read fails',
    () async {
      var shareCalls = 0;
      final controller = CsvExportController(
        readProducts: () async => const FailureResult<List<Product>>(
          PersistenceFailure(debugMessage: 'raw db error'),
        ),
        readMovements: () async => const Success<List<StockMovement>>([]),
        builder: const CsvExportBuilder(),
        shareBundle: (_) async {
          shareCalls++;
        },
        saveBundle: (_) async {},
        exportedAt: () => DateTime.utc(2026, 8, 9, 10, 15),
      );

      final result = await controller.exportCsv();

      expect(result, isA<FailureResult<CsvExportSummary>>());
      expect(shareCalls, 0);
    },
  );

  test('exportCsv wraps share failures as unexpected failures', () async {
    final controller = CsvExportController(
      readProducts: () async => const Success<List<Product>>([]),
      readMovements: () async => const Success<List<StockMovement>>([]),
      builder: const CsvExportBuilder(),
      shareBundle: (_) async => throw StateError('share failed'),
      saveBundle: (_) async {},
      exportedAt: () => DateTime.utc(2026, 8, 9, 10, 15),
    );

    final result = await controller.exportCsv();

    expect(result, isA<FailureResult<CsvExportSummary>>());
    final failure = (result as FailureResult<CsvExportSummary>).failure;
    expect(failure, isA<UnexpectedFailure>());
  });
}

Product _product(String id, String name) {
  return Product(
    id: id,
    name: name,
    category: null,
    unit: 'pcs',
    sellingPrice: 10,
    quantity: 5,
    lowStockThreshold: 2,
    barcode: null,
    isArchived: false,
    createdAt: DateTime.utc(2026, 8, 9),
    updatedAt: DateTime.utc(2026, 8, 9),
  );
}

StockMovement _movement(String id) {
  return StockMovement(
    id: id,
    productId: 'p1',
    type: StockMovementType.stockIn,
    quantity: 3,
    previousQuantity: 2,
    newQuantity: 5,
    reason: null,
    note: null,
    productNameSnapshot: 'Rice',
    unitSnapshot: 'pcs',
    createdAt: DateTime.utc(2026, 8, 9),
  );
}
