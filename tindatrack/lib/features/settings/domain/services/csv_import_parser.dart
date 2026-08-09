import 'package:tindatrack/features/products/domain/entities/create_product_input.dart';
import 'package:tindatrack/features/products/domain/failures/product_failure.dart';
import 'package:tindatrack/features/products/domain/validation/product_validator.dart';
import 'package:tindatrack/features/settings/domain/entities/csv_import_preview.dart';

const _headers = [
  'Product Name',
  'Category',
  'Unit',
  'Selling Price',
  'Current Quantity',
  'Low Stock Threshold',
  'Barcode',
  'Status',
  'Created At',
  'Updated At',
];

/// Parses and validates Products CSV text exported by TindaTrack.
final class CsvImportParser {
  /// Creates a CSV import parser.
  const CsvImportParser({ProductValidator? validator})
    : _validator = validator ?? const ProductValidator();

  final ProductValidator _validator;

  /// Returns a preview with valid rows plus blocking errors.
  CsvImportPreview parseProductsCsv(String csv) {
    final parsedCsv = _parseCsv(csv);
    final table = parsedCsv.rows;
    if (parsedCsv.errors.isNotEmpty) {
      return CsvImportPreview(rows: const [], errors: parsedCsv.errors);
    }
    if (table.isEmpty ||
        table.every((row) => row.every((cell) => cell.isEmpty))) {
      return const CsvImportPreview(
        rows: [],
        errors: [CsvImportError(rowNumber: 0, message: 'CSV file is empty.')],
      );
    }

    final header = table.first;
    if (!_hasExpectedHeader(header)) {
      return const CsvImportPreview(
        rows: [],
        errors: [
          CsvImportError(
            rowNumber: 1,
            message: 'This is not a TindaTrack Products CSV file.',
          ),
        ],
      );
    }

    final rows = <CsvImportProductRow>[];
    final errors = <CsvImportError>[];
    final barcodeRows = <String, List<int>>{};

    for (var index = 1; index < table.length; index++) {
      final sourceRowNumber = index + 1;
      final cells = table[index];
      if (cells.every((cell) => cell.trim().isEmpty)) continue;
      if (cells.length != _headers.length) {
        errors.add(
          CsvImportError(
            rowNumber: sourceRowNumber,
            message:
                'Expected ${_headers.length} columns but found '
                '${cells.length}.',
          ),
        );
        continue;
      }

      final row = _parseProductRow(cells, sourceRowNumber, errors);
      if (row == null) continue;
      rows.add(row);
      final barcode = row.barcode;
      if (barcode != null) {
        barcodeRows.putIfAbsent(barcode, () => <int>[]).add(sourceRowNumber);
      }
    }

    for (final entry in barcodeRows.entries) {
      if (entry.value.length < 2) continue;
      for (final rowNumber in entry.value) {
        errors.add(
          CsvImportError(
            rowNumber: rowNumber,
            message: 'Barcode ${entry.key} appears more than once in this CSV.',
          ),
        );
      }
    }

    if (rows.isEmpty && errors.isEmpty) {
      errors.add(
        const CsvImportError(
          rowNumber: 0,
          message: 'CSV file has no product rows to import.',
        ),
      );
    }

    return CsvImportPreview(rows: rows, errors: errors);
  }

  CsvImportProductRow? _parseProductRow(
    List<String> cells,
    int sourceRowNumber,
    List<CsvImportError> errors,
  ) {
    final name = cells[0].trim();
    final category = _blankToNull(cells[1]);
    final unit = cells[2].trim();
    final sellingPrice = double.tryParse(cells[3].trim());
    final quantity = int.tryParse(cells[4].trim());
    final lowStockThreshold = int.tryParse(cells[5].trim());
    final barcode = _blankToNull(cells[6]);
    final status = cells[7].trim().toLowerCase();

    var hasError = false;
    if (sellingPrice == null) {
      hasError = true;
      errors.add(
        CsvImportError(
          rowNumber: sourceRowNumber,
          message: 'Selling Price must be a valid number.',
        ),
      );
    }
    if (quantity == null) {
      hasError = true;
      errors.add(
        CsvImportError(
          rowNumber: sourceRowNumber,
          message: 'Current Quantity must be a whole number.',
        ),
      );
    }
    if (lowStockThreshold == null) {
      hasError = true;
      errors.add(
        CsvImportError(
          rowNumber: sourceRowNumber,
          message: 'Low Stock Threshold must be a whole number.',
        ),
      );
    }

    final bool isArchived;
    if (status == 'active') {
      isArchived = false;
    } else if (status == 'archived') {
      isArchived = true;
    } else {
      hasError = true;
      errors.add(
        CsvImportError(
          rowNumber: sourceRowNumber,
          message: 'Status must be Active or Archived.',
        ),
      );
      isArchived = false;
    }

    if (hasError) return null;

    final input = CreateProductInput(
      name: name,
      category: category,
      unit: unit,
      sellingPrice: sellingPrice!,
      quantity: quantity!,
      lowStockThreshold: lowStockThreshold!,
      barcode: barcode,
    );
    final validation = _validator.validate(input);
    if (validation != null) {
      errors.add(
        CsvImportError(
          rowNumber: sourceRowNumber,
          message: _validationMessage(validation),
        ),
      );
      return null;
    }
    final normalized = _validator.normalize(input);

    return CsvImportProductRow(
      sourceRowNumber: sourceRowNumber,
      name: normalized.name,
      category: normalized.category,
      unit: normalized.unit,
      sellingPrice: normalized.sellingPrice,
      quantity: normalized.quantity,
      lowStockThreshold: normalized.lowStockThreshold,
      barcode: _blankToNull(normalized.barcode),
      isArchived: isArchived,
    );
  }

  bool _hasExpectedHeader(List<String> header) {
    if (header.length != _headers.length) return false;
    for (var index = 0; index < _headers.length; index++) {
      if (header[index].trim() != _headers[index]) return false;
    }
    return true;
  }

  String? _blankToNull(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  String _validationMessage(ProductValidationFailure failure) {
    final field = switch (failure.field) {
      ProductField.name => 'Product Name',
      ProductField.unit => 'Unit',
      ProductField.sellingPrice => 'Selling Price',
      ProductField.quantity => 'Current Quantity',
      ProductField.lowStockThreshold => 'Low Stock Threshold',
    };
    final issue = switch (failure.issue) {
      ProductValidationIssue.required => 'is required',
      ProductValidationIssue.invalidNumber => 'must be a valid number',
      ProductValidationIssue.negative => 'cannot be negative',
      ProductValidationIssue.tooLarge => 'is too large',
    };
    return '$field $issue.';
  }

  _CsvParseResult _parseCsv(String csv) {
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    final errors = <CsvImportError>[];
    var inQuotes = false;
    var rowNumber = 1;

    for (var index = 0; index < csv.length; index++) {
      final char = csv[index];
      if (inQuotes) {
        if (char == '"') {
          final hasEscapedQuote =
              index + 1 < csv.length && csv[index + 1] == '"';
          if (hasEscapedQuote) {
            cell.write('"');
            index++;
          } else {
            inQuotes = false;
          }
        } else {
          cell.write(char);
        }
        continue;
      }

      if (char == '"' && cell.isEmpty) {
        inQuotes = true;
      } else if (char == ',') {
        if (inQuotes) {
          errors.add(
            CsvImportError(
              rowNumber: rowNumber,
              message: 'CSV has an unclosed quoted field.',
            ),
          );
        }

        row.add(cell.toString());
        cell.clear();
      } else if (char == '\n') {
        if (inQuotes) {
          errors.add(
            CsvImportError(
              rowNumber: rowNumber,
              message: 'CSV has an unclosed quoted field.',
            ),
          );
        }

        row.add(cell.toString());
        cell.clear();
        rows.add(row);
        row = <String>[];
        rowNumber++;
      } else if (char == '\r') {
        continue;
      } else {
        cell.write(char);
      }
    }

    if (inQuotes) {
      errors.add(
        CsvImportError(
          rowNumber: rowNumber,
          message: 'CSV has an unclosed quoted field.',
        ),
      );
    }

    row.add(cell.toString());
    if (row.length > 1 || row.single.isNotEmpty || csv.endsWith(',')) {
      rows.add(row);
    }
    return _CsvParseResult(rows: rows, errors: errors);
  }
}

final class _CsvParseResult {
  const _CsvParseResult({required this.rows, required this.errors});

  final List<List<String>> rows;
  final List<CsvImportError> errors;
}
