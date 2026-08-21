// CSV fixtures are easier to read as adjacent string literals.
// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/features/settings/domain/services/csv_import_parser.dart';

void main() {
  const parser = CsvImportParser();

  test('previews valid exported products with active and archived counts', () {
    final preview = parser.parseProductsCsv(
      'Product Name,Category,Unit,Selling Price,Current Quantity,'
      'Low Stock Threshold,Barcode,Status,Created At,Updated At\n'
      'Rice,Staples,kg,55.50,12,3,123,Active,'
      '2026-08-09 01:00:00 UTC,2026-08-09 01:00:00 UTC\n'
      'Old Soap,,pcs,18.00,0,2,,Archived,'
      '2026-08-09 01:00:00 UTC,2026-08-09 01:00:00 UTC\n',
    );

    expect(preview.errors, isEmpty);
    expect(preview.rowCount, 2);
    expect(preview.activeCount, 1);
    expect(preview.archivedCount, 1);
    expect(preview.rows.first.name, 'Rice');
    expect(preview.rows.last.category, isNull);
    expect(preview.canImport, isTrue);
  });

  test('accepts restorable products export with product id column', () {
    final preview = parser.parseProductsCsv(
      'Product ID,Product Name,Category,Unit,Selling Price,Current Quantity,'
      'Low Stock Threshold,Barcode,Status,Created At,Updated At\n'
      'original-product-id,Rice,Staples,kg,55.50,12,3,123,Active,'
      '2026-08-09 01:00:00 UTC,2026-08-09 01:00:00 UTC\n',
    );

    expect(preview.errors, isEmpty);
    expect(preview.rows.single.name, 'Rice');
    expect(preview.rows.single.barcode, '123');
    expect(preview.canImport, isTrue);
  });

  test('parses quoted commas and escaped quotes', () {
    final preview = parser.parseProductsCsv(
      'Product Name,Category,Unit,Selling Price,Current Quantity,'
      'Low Stock Threshold,Barcode,Status,Created At,Updated At\n'
      '"Milo, 24g","Drinks ""Hot""",pcs,12.00,20,5,480,Active,,\n',
    );

    expect(preview.errors, isEmpty);
    expect(preview.rows.single.name, 'Milo, 24g');
    expect(preview.rows.single.category, 'Drinks "Hot"');
  });

  test('rejects stock history or files with wrong headers', () {
    final preview = parser.parseProductsCsv(
      'Date,Type,Quantity\n2026,Stock In,1\n',
    );

    expect(preview.canImport, isFalse);
    expect(preview.errors.single.rowNumber, 1);
    expect(preview.errors.single.message, contains('Products CSV'));
  });

  test('reports row validation errors and duplicate CSV barcodes', () {
    final preview = parser.parseProductsCsv(
      'Product Name,Category,Unit,Selling Price,Current Quantity,'
      'Low Stock Threshold,Barcode,Status,Created At,Updated At\n'
      ',,pcs,10,1,0,111,Active,,\n'
      'Sugar,,pcs,abc,1,0,222,Active,,\n'
      'Coffee,,pcs,5,-1,0,333,Active,,\n'
      'Soap,,pcs,5,1,0,444,Hidden,,\n'
      'Milk,,pcs,5,1,0,555,Active,,\n'
      'Milo,,pcs,5,1,0,555,Archived,,\n',
    );

    expect(preview.canImport, isFalse);
    expect(
      preview.errors.map((error) => error.rowNumber),
      containsAll([2, 3, 4, 5, 6, 7]),
    );
    expect(
      preview.errors.map((error) => error.message).join(' '),
      contains('appears more than once'),
    );
  });
  test('reports unclosed quoted fields as blocking parse errors', () {
    final preview = parser.parseProductsCsv(
      'Product Name,Category,Unit,Selling Price,Current Quantity,'
      'Low Stock Threshold,Barcode,Status,Created At,Updated At\n'
      '"Rice,Staples,kg,55.50,12,3,123,Active,,\n',
    );

    expect(preview.canImport, isFalse);
    expect(preview.errors.single.message, contains('unclosed quoted field'));
  });
}
