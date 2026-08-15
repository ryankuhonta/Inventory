// Named dependency parameters keep controller tests concise.
// ignore_for_file: prefer_initializing_formals

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tindatrack/app/providers.dart';
import 'package:tindatrack/core/database/app_database.dart' as db;
import 'package:tindatrack/core/database/daos/products_dao.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';
import 'package:tindatrack/features/settings/domain/entities/csv_import_preview.dart';
import 'package:tindatrack/features/settings/domain/services/csv_import_parser.dart';

/// Platform bridge for picking and reading one Products CSV file.
typedef PickProductsCsv = Future<String?> Function();

/// Reads reserved product barcodes from persistence.
typedef FindExistingProductBarcodes =
    Future<Result<Set<String>>> Function(
      Set<String> barcodes,
    );

/// Writes import rows to product persistence.
typedef ImportProductRows =
    Future<Result<void>> Function(
      List<CsvImportProductRow> rows,
    );

/// Builds Products CSV import previews.
final csvImportParserProvider = Provider<CsvImportParser>(
  (ref) => const CsvImportParser(),
);

/// Platform bridge for selecting a Products CSV file.
final pickProductsCsvProvider = Provider<PickProductsCsv>(
  (ref) => pickProductsCsv,
);

/// Finds existing active or archived product barcodes.
final findExistingProductBarcodesProvider =
    Provider<FindExistingProductBarcodes>(
      (ref) {
        final dao = ref.watch(productsDaoProvider);
        return (barcodes) => _findExistingProductBarcodes(dao, barcodes);
      },
    );

/// Inserts imported product rows atomically.
final importProductRowsProvider = Provider<ImportProductRows>((ref) {
  final dao = ref.watch(productsDaoProvider);
  final idGenerator = ref.watch(idGeneratorProvider);
  final clock = ref.watch(clockProvider);
  return (rows) => _importProductRows(
    dao: dao,
    idGenerator: idGenerator.generate,
    now: () => clock.now().toUtc(),
    rows: rows,
  );
});

/// Coordinates Products CSV import preview and apply actions.
final csvImportControllerProvider = Provider<CsvImportController>(
  (ref) => CsvImportController(
    pickCsv: ref.watch(pickProductsCsvProvider),
    parser: ref.watch(csvImportParserProvider),
    findExistingBarcodes: ref.watch(findExistingProductBarcodesProvider),
    importRows: ref.watch(importProductRowsProvider),
  ),
);

/// Handles Products CSV import for App Info.
final class CsvImportController {
  /// Creates a CSV import controller.
  const CsvImportController({
    required PickProductsCsv pickCsv,
    required CsvImportParser parser,
    required FindExistingProductBarcodes findExistingBarcodes,
    required ImportProductRows importRows,
  }) : _pickCsv = pickCsv,
       _parser = parser,
       _findExistingBarcodes = findExistingBarcodes,
       _importRows = importRows;

  final PickProductsCsv _pickCsv;
  final CsvImportParser _parser;
  final FindExistingProductBarcodes _findExistingBarcodes;
  final ImportProductRows _importRows;

  /// Picks a CSV and returns a preview, or `null` when the user cancels.
  Future<Result<CsvImportPreview?>> pickAndPreview() async {
    try {
      final csv = await _pickCsv();
      if (csv == null) return const Success<CsvImportPreview?>(null);
      return preview(csv);
    } on PlatformException catch (error) {
      return FailureResult<CsvImportPreview?>(
        UnexpectedFailure(debugMessage: error.toString()),
      );
    } on Object catch (error) {
      return FailureResult<CsvImportPreview?>(
        UnexpectedFailure(debugMessage: error.toString()),
      );
    }
  }

  /// Builds a preview from CSV text and existing database barcode state.
  Future<Result<CsvImportPreview>> preview(String csv) async {
    try {
      final parsed = _parser.parseProductsCsv(csv);
      final barcodes = parsed.rows
          .map((row) => row.barcode)
          .whereType<String>()
          .toSet();
      final existingResult = await _findExistingBarcodes(barcodes);
      switch (existingResult) {
        case Success<Set<String>>(:final value):
          if (value.isEmpty) return Success<CsvImportPreview>(parsed);
          return Success<CsvImportPreview>(
            CsvImportPreview(
              rows: parsed.rows,
              errors: [
                ...parsed.errors,
                for (final barcode in value)
                  CsvImportError(
                    rowNumber: _firstRowForBarcode(parsed, barcode),
                    message: 'Barcode $barcode already exists in TindaTrack.',
                  ),
              ],
            ),
          );
        case FailureResult<Set<String>>(:final failure):
          return FailureResult<CsvImportPreview>(failure);
      }
    } on Object catch (error) {
      return FailureResult<CsvImportPreview>(
        UnexpectedFailure(debugMessage: error.toString()),
      );
    }
  }

  /// Applies a valid preview to persistence.
  Future<Result<CsvImportSummary>> importProducts(
    CsvImportPreview preview,
  ) async {
    if (!preview.canImport) {
      return const FailureResult<CsvImportSummary>(
        UnexpectedFailure(debugMessage: 'Import preview has blocking errors.'),
      );
    }

    final result = await _importRows(preview.rows);
    switch (result) {
      case Success<void>():
        return Success<CsvImportSummary>(
          CsvImportSummary(
            importedCount: preview.rowCount,
            activeCount: preview.activeCount,
            archivedCount: preview.archivedCount,
          ),
        );
      case FailureResult<void>(:final failure):
        return FailureResult<CsvImportSummary>(failure);
    }
  }

  int _firstRowForBarcode(CsvImportPreview preview, String barcode) {
    return preview.rows
        .firstWhere((row) => row.barcode == barcode)
        .sourceRowNumber;
  }
}

Future<Result<Set<String>>> _findExistingProductBarcodes(
  ProductsDao dao,
  Set<String> barcodes,
) async {
  try {
    final existing = <String>{};
    final values = barcodes.toList(growable: false);
    for (
      var start = 0;
      start < values.length;
      start += _barcodeLookupChunkSize
    ) {
      final end = start + _barcodeLookupChunkSize;
      final chunk = values.sublist(
        start,
        end > values.length ? values.length : end,
      );
      existing.addAll(await dao.findExistingBarcodes(chunk.toSet()));
    }
    return Success<Set<String>>(existing);
  } on Object catch (error) {
    return FailureResult<Set<String>>(
      PersistenceFailure(debugMessage: error.toString()),
    );
  }
}

Future<Result<void>> _importProductRows({
  required ProductsDao dao,
  required String Function() idGenerator,
  required DateTime Function() now,
  required List<CsvImportProductRow> rows,
}) async {
  try {
    final importedAt = now();
    await dao.importProducts([
      for (final row in rows)
        db.ProductsCompanion.insert(
          id: idGenerator(),
          name: row.name,
          category: Value(row.category),
          unit: row.unit,
          sellingPrice: row.sellingPrice,
          quantity: row.quantity,
          lowStockThreshold: row.lowStockThreshold,
          barcode: Value(row.barcode),
          isArchived: Value(row.isArchived),
          createdAt: importedAt,
          updatedAt: importedAt,
        ),
    ]);
    return const Success<void>(null);
  } on Object catch (error) {
    return FailureResult<void>(
      PersistenceFailure(debugMessage: error.toString()),
    );
  }
}

const _barcodeLookupChunkSize = 500;

const _csvImportChannel = MethodChannel(
  'com.rkuhonta.tindatrack/csv_import',
);

/// Opens the Android document picker and reads one CSV file as text.
Future<String?> pickProductsCsv() {
  return _csvImportChannel.invokeMethod<String>('pickProductsCsv');
}
