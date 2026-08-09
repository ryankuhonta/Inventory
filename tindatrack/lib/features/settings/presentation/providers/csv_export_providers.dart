// Named dependency parameters keep controller tests concise.
// ignore_for_file: prefer_initializing_formals

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tindatrack/app/providers.dart';
import 'package:tindatrack/core/database/app_database.dart' as db;
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';
import 'package:tindatrack/features/settings/domain/entities/csv_export_bundle.dart';
import 'package:tindatrack/features/settings/domain/services/csv_export_builder.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';
import 'package:tindatrack/features/stock/presentation/providers/stock_providers.dart';

/// Hands a generated CSV bundle to the host platform.
typedef CsvExportBundleHandoff = Future<void> Function(CsvExportBundle bundle);

/// Builds CSV export text.
final csvExportBuilderProvider = Provider<CsvExportBuilder>(
  (ref) => const CsvExportBuilder(),
);

/// Platform bridge for sharing generated CSV files.
final shareCsvExportBundleProvider = Provider<CsvExportBundleHandoff>(
  (ref) => shareCsvExportBundle,
);

/// Platform bridge for saving generated CSV files to Downloads/TindaTrack.
final saveCsvExportBundleProvider = Provider<CsvExportBundleHandoff>(
  (ref) => saveCsvExportBundleToDownloads,
);

/// Coordinates Settings CSV export reads and file sharing.
final csvExportControllerProvider = Provider<CsvExportController>(
  (ref) => CsvExportController(
    readProducts: () => _listProductsForExport(ref),
    readMovements: () =>
        ref.watch(stockRepositoryProvider).listMovementHistory(),
    builder: ref.watch(csvExportBuilderProvider),
    shareBundle: ref.watch(shareCsvExportBundleProvider),
    saveBundle: ref.watch(saveCsvExportBundleProvider),
    exportedAt: () => ref.watch(clockProvider).now().toUtc(),
  ),
);

/// Handles the CSV export use case for App Info.
final class CsvExportController {
  /// Creates a CSV export controller.
  const CsvExportController({
    required Future<Result<List<Product>>> Function() readProducts,
    required Future<Result<List<StockMovement>>> Function() readMovements,
    required CsvExportBuilder builder,
    required CsvExportBundleHandoff shareBundle,
    required CsvExportBundleHandoff saveBundle,
    required DateTime Function() exportedAt,
  }) : _readProducts = readProducts,
       _readMovements = readMovements,
       _builder = builder,
       _shareBundle = shareBundle,
       _saveBundle = saveBundle,
       _exportedAt = exportedAt;

  final Future<Result<List<Product>>> Function() _readProducts;
  final Future<Result<List<StockMovement>>> Function() _readMovements;
  final CsvExportBuilder _builder;
  final CsvExportBundleHandoff _shareBundle;
  final CsvExportBundleHandoff _saveBundle;
  final DateTime Function() _exportedAt;

  /// Generates and shares the Products and Stock History CSV files.
  Future<Result<CsvExportSummary>> shareCsv() {
    return _exportCsv(_shareBundle);
  }

  /// Generates and saves the Products and Stock History CSV files.
  Future<Result<CsvExportSummary>> saveCsvToDownloads() {
    return _exportCsv(_saveBundle);
  }

  /// Generates and shares CSV files using the default export action.
  Future<Result<CsvExportSummary>> exportCsv() {
    return shareCsv();
  }

  Future<Result<CsvExportSummary>> _exportCsv(
    CsvExportBundleHandoff handoff,
  ) async {
    try {
      final productsResult = await _readProducts();
      final List<Product> products;
      switch (productsResult) {
        case Success<List<Product>>(:final value):
          products = value;
        case FailureResult<List<Product>>(:final failure):
          return FailureResult<CsvExportSummary>(failure);
      }

      final movementsResult = await _readMovements();
      final List<StockMovement> movements;
      switch (movementsResult) {
        case Success<List<StockMovement>>(:final value):
          movements = value;
        case FailureResult<List<StockMovement>>(:final failure):
          return FailureResult<CsvExportSummary>(failure);
      }

      final bundle = _builder.build(
        products: products,
        movements: movements,
        exportedAt: _exportedAt(),
      );
      await handoff(bundle);
      return Success<CsvExportSummary>(
        CsvExportSummary(
          productsFileName: bundle.productsFileName,
          stockHistoryFileName: bundle.stockHistoryFileName,
        ),
      );
    } on Object catch (error) {
      return FailureResult<CsvExportSummary>(
        UnexpectedFailure(debugMessage: error.toString()),
      );
    }
  }
}

Future<Result<List<Product>>> _listProductsForExport(Ref ref) async {
  try {
    final rows = await ref.watch(productsDaoProvider).listAllProducts();
    return Success<List<Product>>(
      rows.map(_productToDomain).toList(growable: false),
    );
  } on Object catch (error) {
    return FailureResult<List<Product>>(
      PersistenceFailure(debugMessage: error.toString()),
    );
  }
}

Product _productToDomain(db.Product row) {
  return Product(
    id: row.id,
    name: row.name,
    category: row.category,
    unit: row.unit,
    sellingPrice: row.sellingPrice,
    quantity: row.quantity,
    lowStockThreshold: row.lowStockThreshold,
    barcode: row.barcode,
    isArchived: row.isArchived,
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
  );
}

/// Writes CSV files to a temporary directory and opens the share sheet.
Future<void> shareCsvExportBundle(CsvExportBundle bundle) async {
  final directory = await getTemporaryDirectory();
  final productsFile = File('${directory.path}/${bundle.productsFileName}');
  final historyFile = File('${directory.path}/${bundle.stockHistoryFileName}');

  await productsFile.writeAsString(bundle.productsCsv);
  await historyFile.writeAsString(bundle.stockHistoryCsv);

  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile(productsFile.path, mimeType: 'text/csv'),
        XFile(historyFile.path, mimeType: 'text/csv'),
      ],
      subject: 'TindaTrack CSV Export',
      text: 'TindaTrack products and stock history CSV export.',
    ),
  );
}

const _csvExportDownloadsChannel = MethodChannel(
  'com.rkuhonta.tindatrack/csv_export',
);

/// Saves CSV files to Downloads/TindaTrack on Android.
Future<void> saveCsvExportBundleToDownloads(CsvExportBundle bundle) async {
  await _csvExportDownloadsChannel.invokeMethod<void>(
    'saveCsvExportToDownloads',
    <String, String>{
      'productsFileName': bundle.productsFileName,
      'productsCsv': bundle.productsCsv,
      'stockHistoryFileName': bundle.stockHistoryFileName,
      'stockHistoryCsv': bundle.stockHistoryCsv,
    },
  );
}
