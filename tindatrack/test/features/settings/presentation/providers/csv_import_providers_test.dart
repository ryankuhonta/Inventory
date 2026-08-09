// CSV fixtures are easier to read as adjacent string literals.
// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/settings/domain/entities/csv_import_preview.dart';
import 'package:tindatrack/features/settings/domain/services/csv_import_parser.dart';
import 'package:tindatrack/features/settings/presentation/providers/csv_import_providers.dart';

void main() {
  test('pickAndPreview returns null success when picker is canceled', () async {
    final controller = CsvImportController(
      pickCsv: () async => null,
      parser: const CsvImportParser(),
      findExistingBarcodes: (_) async => const Success<Set<String>>({}),
      importRows: (_) async => const Success<void>(null),
    );

    final result = await controller.pickAndPreview();

    expect(result, isA<Success<CsvImportPreview?>>());
    expect((result as Success<CsvImportPreview?>).value, isNull);
  });

  test('preview reports existing barcode without importing', () async {
    var importCalls = 0;
    final controller = CsvImportController(
      pickCsv: () async => _csv(),
      parser: const CsvImportParser(),
      findExistingBarcodes: (barcodes) async => Success<Set<String>>(
        barcodes.intersection({'123'}),
      ),
      importRows: (_) async {
        importCalls++;
        return const Success<void>(null);
      },
    );

    final result = await controller.pickAndPreview();

    final preview = (result as Success<CsvImportPreview?>).value!;
    expect(preview.canImport, isFalse);
    expect(preview.errors.single.message, contains('already exists'));
    expect(importCalls, 0);
  });

  test('importProducts passes preview rows to import callback', () async {
    var importCalls = 0;
    var archived = false;
    final controller = CsvImportController(
      pickCsv: () async => _csv(status: 'Archived'),
      parser: const CsvImportParser(),
      findExistingBarcodes: (_) async => const Success<Set<String>>({}),
      importRows: (rows) async {
        importCalls++;
        archived = rows.single.isArchived;
        return const Success<void>(null);
      },
    );
    final preview =
        (await controller.preview(_csv(status: 'Archived'))
                as Success<CsvImportPreview>)
            .value;

    final result = await controller.importProducts(preview);

    expect(result, isA<Success<CsvImportSummary>>());
    expect(importCalls, 1);
    expect(archived, isTrue);
  });

  test('importProducts rejects previews with blocking errors', () async {
    var importCalls = 0;
    final controller = CsvImportController(
      pickCsv: () async => null,
      parser: const CsvImportParser(),
      findExistingBarcodes: (_) async => const Success<Set<String>>({}),
      importRows: (_) async {
        importCalls++;
        return const Success<void>(null);
      },
    );
    const preview = CsvImportPreview(
      rows: [],
      errors: [CsvImportError(rowNumber: 1, message: 'bad')],
    );

    final result = await controller.importProducts(preview);

    expect(result, isA<FailureResult<CsvImportSummary>>());
    expect(importCalls, 0);
  });
  test('preview supports more than one barcode lookup chunk', () async {
    final seen = <Set<String>>[];
    final controller = CsvImportController(
      pickCsv: () async => null,
      parser: const CsvImportParser(),
      findExistingBarcodes: (barcodes) async {
        seen.add(barcodes);
        return const Success<Set<String>>({});
      },
      importRows: (_) async => const Success<void>(null),
    );
    final buffer = StringBuffer()
      ..writeln(
        'Product Name,Category,Unit,Selling Price,Current Quantity,'
        'Low Stock Threshold,Barcode,Status,Created At,Updated At',
      );
    for (var index = 0; index < 520; index++) {
      buffer.writeln('Product $index,,pcs,1,1,0,code-$index,Active,,');
    }

    final result = await controller.preview(buffer.toString());

    expect(result, isA<Success<CsvImportPreview>>());
    expect(seen.single.length, 520);
  });
}

String _csv({String barcode = '123', String status = 'Active'}) {
  return 'Product Name,Category,Unit,Selling Price,Current Quantity,'
      'Low Stock Threshold,Barcode,Status,Created At,Updated At\n'
      'Rice,Staples,kg,55.50,12,3,$barcode,$status,,\n';
}
