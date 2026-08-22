// Named dependency parameters keep controller tests concise.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tindatrack/app/providers.dart';
import 'package:tindatrack/core/database/app_database.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/settings/domain/entities/full_restore_preview.dart';
import 'package:tindatrack/features/settings/domain/services/full_restore_parser.dart';

/// Platform bridge for picking both CSV files needed by Full Restore.
typedef PickFullRestoreCsvs = Future<FullRestoreCsvSelection?> Function();

/// Checks whether the target database is empty enough for safe restore.
typedef IsFullRestoreTargetEmpty = Future<Result<bool>> Function();

/// Applies a valid full restore preview to persistence.
typedef ApplyFullRestore =
    Future<Result<void>> Function(
      FullRestorePreview preview,
    );

/// The two CSV file contents selected for Full Restore.
final class FullRestoreCsvSelection {
  /// Creates a selected Products + Stock History CSV pair.
  const FullRestoreCsvSelection({
    required this.productsCsv,
    required this.stockHistoryCsv,
  });

  /// Products CSV text.
  final String productsCsv;

  /// Stock History CSV text.
  final String stockHistoryCsv;
}

/// Restore was blocked because existing local data is present.
final class FullRestoreTargetNotEmptyFailure extends AppFailure {
  /// Creates an empty-target failure.
  const FullRestoreTargetNotEmptyFailure()
    : super(debugMessage: 'Full restore requires an empty database.');
}

/// Summary returned after a successful full restore.
final class FullRestoreSummary {
  /// Creates a full restore summary.
  const FullRestoreSummary({
    required this.productCount,
    required this.activeProductCount,
    required this.archivedProductCount,
    required this.movementCount,
  });

  /// Number of restored products.
  final int productCount;

  /// Number of restored active products.
  final int activeProductCount;

  /// Number of restored archived products.
  final int archivedProductCount;

  /// Number of restored stock movements.
  final int movementCount;
}

/// Builds full restore previews from CSV files.
final fullRestoreParserProvider = Provider<FullRestoreParser>(
  (ref) => const FullRestoreParser(),
);

/// Platform bridge for selecting Products and Stock History CSV files.
final pickFullRestoreCsvsProvider = Provider<PickFullRestoreCsvs>(
  (ref) => pickFullRestoreCsvs,
);

/// Checks whether the database has no products and no stock movements.
final isFullRestoreTargetEmptyProvider = Provider<IsFullRestoreTargetEmpty>(
  (ref) =>
      () => _isFullRestoreTargetEmpty(ref.watch(databaseProvider)),
);

/// Applies full restore in one database transaction.
final applyFullRestoreProvider = Provider<ApplyFullRestore>(
  (ref) =>
      (preview) => _applyFullRestore(ref.watch(databaseProvider), preview),
);

/// Coordinates Full Restore preview and apply actions for App Info.
final fullRestoreControllerProvider = Provider<FullRestoreController>(
  (ref) => FullRestoreController(
    pickCsvs: ref.watch(pickFullRestoreCsvsProvider),
    parser: ref.watch(fullRestoreParserProvider),
    isTargetEmpty: ref.watch(isFullRestoreTargetEmptyProvider),
    applyRestore: ref.watch(applyFullRestoreProvider),
  ),
);

/// Handles the Full Restore use case for App Info.
final class FullRestoreController {
  /// Creates a Full Restore controller.
  const FullRestoreController({
    required PickFullRestoreCsvs pickCsvs,
    required FullRestoreParser parser,
    required IsFullRestoreTargetEmpty isTargetEmpty,
    required ApplyFullRestore applyRestore,
  }) : _pickCsvs = pickCsvs,
       _parser = parser,
       _isTargetEmpty = isTargetEmpty,
       _applyRestore = applyRestore;

  final PickFullRestoreCsvs _pickCsvs;
  final FullRestoreParser _parser;
  final IsFullRestoreTargetEmpty _isTargetEmpty;
  final ApplyFullRestore _applyRestore;

  /// Picks both CSV files and returns a preview, or `null` when canceled.
  Future<Result<FullRestorePreview?>> pickAndPreview() async {
    try {
      final selection = await _pickCsvs();
      if (selection == null) return const Success<FullRestorePreview?>(null);
      return preview(
        productsCsv: selection.productsCsv,
        stockHistoryCsv: selection.stockHistoryCsv,
      );
    } on PlatformException catch (error) {
      return FailureResult<FullRestorePreview?>(
        UnexpectedFailure(debugMessage: error.toString()),
      );
    } on Object catch (error) {
      return FailureResult<FullRestorePreview?>(
        UnexpectedFailure(debugMessage: error.toString()),
      );
    }
  }

  /// Builds a preview from selected CSV text and current database state.
  Future<Result<FullRestorePreview>> preview({
    required String productsCsv,
    required String stockHistoryCsv,
  }) async {
    try {
      final parsed = _parser.parse(
        productsCsv: productsCsv,
        stockHistoryCsv: stockHistoryCsv,
      );
      final emptyResult = await _isTargetEmpty();
      switch (emptyResult) {
        case Success<bool>(:final value):
          if (value) return Success<FullRestorePreview>(parsed);
          return Success<FullRestorePreview>(
            FullRestorePreview(
              products: parsed.products,
              movements: parsed.movements,
              errors: [
                ...parsed.errors,
                const FullRestoreError(
                  fileName: 'App Data',
                  rowNumber: 0,
                  message:
                      'Full restore requires an empty TindaTrack database.',
                ),
              ],
            ),
          );
        case FailureResult<bool>(:final failure):
          return FailureResult<FullRestorePreview>(failure);
      }
    } on Object catch (error) {
      return FailureResult<FullRestorePreview>(
        UnexpectedFailure(debugMessage: error.toString()),
      );
    }
  }

  /// Applies a valid full restore preview to persistence.
  Future<Result<FullRestoreSummary>> restore(FullRestorePreview preview) async {
    if (!preview.canRestore) {
      return const FailureResult<FullRestoreSummary>(
        UnexpectedFailure(debugMessage: 'Full restore has blocking errors.'),
      );
    }

    final emptyResult = await _isTargetEmpty();
    switch (emptyResult) {
      case Success<bool>(:final value):
        if (!value) {
          return const FailureResult<FullRestoreSummary>(
            FullRestoreTargetNotEmptyFailure(),
          );
        }
      case FailureResult<bool>(:final failure):
        return FailureResult<FullRestoreSummary>(failure);
    }

    final result = await _applyRestore(preview);
    switch (result) {
      case Success<void>():
        return Success<FullRestoreSummary>(
          FullRestoreSummary(
            productCount: preview.productCount,
            activeProductCount: preview.activeProductCount,
            archivedProductCount: preview.archivedProductCount,
            movementCount: preview.movementCount,
          ),
        );
      case FailureResult<void>(:final failure):
        return FailureResult<FullRestoreSummary>(failure);
    }
  }
}

Future<Result<bool>> _isFullRestoreTargetEmpty(AppDatabase database) async {
  try {
    final products = await (database.select(database.products)..limit(1)).get();
    if (products.isNotEmpty) return const Success<bool>(false);
    final movements = await (database.select(
      database.stockMovements,
    )..limit(1)).get();
    return Success<bool>(movements.isEmpty);
  } on Object catch (error) {
    return FailureResult<bool>(
      PersistenceFailure(debugMessage: error.toString()),
    );
  }
}

Future<Result<void>> _applyFullRestore(
  AppDatabase database,
  FullRestorePreview preview,
) async {
  try {
    await database.restoreFullBackup(preview);
    return const Success<void>(null);
  } on Object catch (error) {
    return FailureResult<void>(
      PersistenceFailure(debugMessage: error.toString()),
    );
  }
}

const _csvImportChannel = MethodChannel(
  'com.rkuhonta.tindatrack/csv_import',
);

/// Opens two document picker steps and reads both CSV files as text.
Future<FullRestoreCsvSelection?> pickFullRestoreCsvs() async {
  final productsCsv = await _csvImportChannel.invokeMethod<String>(
    'pickProductsCsv',
  );
  if (productsCsv == null) return null;

  final stockHistoryCsv = await _csvImportChannel.invokeMethod<String>(
    'pickStockHistoryCsv',
  );
  if (stockHistoryCsv == null) return null;

  return FullRestoreCsvSelection(
    productsCsv: productsCsv,
    stockHistoryCsv: stockHistoryCsv,
  );
}
