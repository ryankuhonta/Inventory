// CSV fixtures are easier to read as adjacent string literals.
// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/settings/domain/entities/full_restore_preview.dart';
import 'package:tindatrack/features/settings/domain/services/full_restore_parser.dart';
import 'package:tindatrack/features/settings/presentation/providers/full_restore_providers.dart';

void main() {
  test(
    'pickAndPreview returns null success when either picker is canceled',
    () async {
      final controller = FullRestoreController(
        pickCsvs: () async => null,
        parser: const FullRestoreParser(),
        isTargetEmpty: () async => const Success<bool>(true),
        applyRestore: (_) async => const Success<void>(null),
      );

      final result = await controller.pickAndPreview();

      expect(result, isA<Success<FullRestorePreview?>>());
      expect((result as Success<FullRestorePreview?>).value, isNull);
    },
  );

  test('preview reports parser errors without applying restore', () async {
    var applyCalls = 0;
    final controller = FullRestoreController(
      pickCsvs: () async => FullRestoreCsvSelection(
        productsCsv: _legacyProductsCsv(),
        stockHistoryCsv: _stockHistoryCsv(),
      ),
      parser: const FullRestoreParser(),
      isTargetEmpty: () async => const Success<bool>(true),
      applyRestore: (_) async {
        applyCalls++;
        return const Success<void>(null);
      },
    );

    final result = await controller.pickAndPreview();

    final preview = (result as Success<FullRestorePreview?>).value!;
    expect(preview.canRestore, isFalse);
    expect(
      preview.errors.map((error) => error.message).join(' '),
      contains('restorable'),
    );
    expect(applyCalls, 0);
  });

  test('preview blocks restore when target database is not empty', () async {
    final controller = FullRestoreController(
      pickCsvs: () async => null,
      parser: const FullRestoreParser(),
      isTargetEmpty: () async => const Success<bool>(false),
      applyRestore: (_) async => const Success<void>(null),
    );

    final result = await controller.preview(
      productsCsv: _productsCsv(),
      stockHistoryCsv: _stockHistoryCsv(),
    );

    final preview = (result as Success<FullRestorePreview>).value;
    expect(preview.productCount, 1);
    expect(preview.movementCount, 1);
    expect(preview.canRestore, isFalse);
    expect(
      preview.errors.single.message,
      contains('empty TindaTrack database'),
    );
  });

  test('restore returns summary for a valid preview', () async {
    var applyCalls = 0;
    final controller = FullRestoreController(
      pickCsvs: () async => null,
      parser: const FullRestoreParser(),
      isTargetEmpty: () async => const Success<bool>(true),
      applyRestore: (_) async {
        applyCalls++;
        return const Success<void>(null);
      },
    );
    final preview =
        (await controller.preview(
                  productsCsv: _productsCsv(),
                  stockHistoryCsv: _stockHistoryCsv(),
                )
                as Success<FullRestorePreview>)
            .value;

    final result = await controller.restore(preview);

    final summary = (result as Success<FullRestoreSummary>).value;
    expect(applyCalls, 1);
    expect(summary.productCount, 1);
    expect(summary.activeProductCount, 1);
    expect(summary.archivedProductCount, 0);
    expect(summary.movementCount, 1);
  });

  test('restore rechecks empty target at confirm time', () async {
    final controller = FullRestoreController(
      pickCsvs: () async => null,
      parser: const FullRestoreParser(),
      isTargetEmpty: () async => const Success<bool>(false),
      applyRestore: (_) async => const Success<void>(null),
    );
    final parsed = const FullRestoreParser().parse(
      productsCsv: _productsCsv(),
      stockHistoryCsv: _stockHistoryCsv(),
    );

    final result = await controller.restore(parsed);

    expect(result, isA<FailureResult<FullRestoreSummary>>());
    final failure = (result as FailureResult<FullRestoreSummary>).failure;
    expect(failure, isA<FullRestoreTargetNotEmptyFailure>());
  });
  test('restore surfaces apply failure without changing summary', () async {
    final controller = FullRestoreController(
      pickCsvs: () async => null,
      parser: const FullRestoreParser(),
      isTargetEmpty: () async => const Success<bool>(true),
      applyRestore: (_) async => const FailureResult<void>(
        PersistenceFailure(debugMessage: 'boom'),
      ),
    );
    final preview =
        (await controller.preview(
                  productsCsv: _productsCsv(),
                  stockHistoryCsv: _stockHistoryCsv(),
                )
                as Success<FullRestorePreview>)
            .value;

    final result = await controller.restore(preview);

    expect(result, isA<FailureResult<FullRestoreSummary>>());
  });
}

String _productsCsv() {
  return 'Product ID,Product Name,Category,Unit,Selling Price,'
      'Current Quantity,Low Stock Threshold,Barcode,Status,Created At,'
      'Updated At\n'
      'product-1,Rice,Staples,kg,55.50,9,3,480001,Active,'
      '2026-08-01 01:00:00 UTC,2026-08-02 02:00:00 UTC\n';
}

String _legacyProductsCsv() {
  return 'Product Name,Category,Unit,Selling Price,Current Quantity,'
      'Low Stock Threshold,Barcode,Status,Created At,Updated At\n'
      'Rice,Staples,kg,55.50,9,3,480001,Active,,\n';
}

String _stockHistoryCsv() {
  return 'Movement ID,Product ID,Date,Type,Reason,Product Name Snapshot,'
      'Quantity,Previous Quantity,New Quantity,Unit Snapshot,Note\n'
      'movement-1,product-1,2026-08-03 03:00:00 UTC,Stock Out,Sold,'
      'Rice,3,12,9,kg,morning sale\n';
}
