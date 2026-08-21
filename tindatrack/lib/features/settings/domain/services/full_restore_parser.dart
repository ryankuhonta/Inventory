import 'package:tindatrack/features/products/domain/entities/create_product_input.dart';
import 'package:tindatrack/features/products/domain/failures/product_failure.dart';
import 'package:tindatrack/features/products/domain/validation/product_validator.dart';
import 'package:tindatrack/features/settings/domain/entities/full_restore_preview.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';

const List<String> _productsHeaders = [
  'Product ID',
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

const List<String> _stockHistoryHeaders = [
  'Movement ID',
  'Product ID',
  'Date',
  'Type',
  'Reason',
  'Product Name Snapshot',
  'Quantity',
  'Previous Quantity',
  'New Quantity',
  'Unit Snapshot',
  'Note',
];

/// Builds a typed, blocking-error preview for full local backup restore.
final class FullRestoreParser {
  /// Creates a full restore parser.
  const FullRestoreParser({ProductValidator? validator})
    : _validator = validator ?? const ProductValidator();

  final ProductValidator _validator;

  /// Parses both CSV files and validates cross-file product references.
  FullRestorePreview parse({
    required String productsCsv,
    required String stockHistoryCsv,
  }) {
    final productResult = _parseProductsCsv(productsCsv);
    final productIds = productResult.rows.map((row) => row.id).toSet();
    final movementResult = _parseStockHistoryCsv(
      stockHistoryCsv,
      productIds: productIds,
    );

    return FullRestorePreview(
      products: productResult.rows,
      movements: movementResult.rows,
      errors: [...productResult.errors, ...movementResult.errors],
    );
  }

  _ProductsParseResult _parseProductsCsv(String csv) {
    final parsed = _parseCsv(csv, fileName: 'Products CSV');
    if (parsed.errors.isNotEmpty) {
      return _ProductsParseResult(rows: const [], errors: parsed.errors);
    }
    if (_isEmpty(parsed.rows)) {
      return const _ProductsParseResult(
        rows: [],
        errors: [
          FullRestoreError(
            fileName: 'Products CSV',
            rowNumber: 0,
            message: 'Products CSV file is empty.',
          ),
        ],
      );
    }
    if (!_hasHeader(parsed.rows.first, _productsHeaders)) {
      return const _ProductsParseResult(
        rows: [],
        errors: [
          FullRestoreError(
            fileName: 'Products CSV',
            rowNumber: 1,
            message: 'This is not a restorable TindaTrack Products CSV file.',
          ),
        ],
      );
    }

    final rows = <FullRestoreProductRow>[];
    final errors = <FullRestoreError>[];
    final idRows = <String, List<int>>{};
    final barcodeRows = <String, List<int>>{};

    for (var index = 1; index < parsed.rows.length; index++) {
      final rowNumber = index + 1;
      final cells = parsed.rows[index];
      if (cells.every((cell) => cell.trim().isEmpty)) continue;
      if (cells.length != _productsHeaders.length) {
        errors.add(
          FullRestoreError(
            fileName: 'Products CSV',
            rowNumber: rowNumber,
            message:
                'Expected ${_productsHeaders.length} columns but found '
                '${cells.length}.',
          ),
        );
        continue;
      }

      final row = _parseProductRow(cells, rowNumber, errors);
      if (row == null) continue;
      rows.add(row);
      idRows.putIfAbsent(row.id, () => <int>[]).add(rowNumber);
      final barcode = row.barcode;
      if (barcode != null) {
        barcodeRows.putIfAbsent(barcode, () => <int>[]).add(rowNumber);
      }
    }

    _addDuplicateErrors(
      rowsByValue: idRows,
      fileName: 'Products CSV',
      label: 'Product ID',
      errors: errors,
    );
    _addDuplicateErrors(
      rowsByValue: barcodeRows,
      fileName: 'Products CSV',
      label: 'Barcode',
      errors: errors,
    );
    if (rows.isEmpty && errors.isEmpty) {
      errors.add(
        const FullRestoreError(
          fileName: 'Products CSV',
          rowNumber: 0,
          message: 'Products CSV has no product rows to restore.',
        ),
      );
    }

    return _ProductsParseResult(rows: rows, errors: errors);
  }

  FullRestoreProductRow? _parseProductRow(
    List<String> cells,
    int rowNumber,
    List<FullRestoreError> errors,
  ) {
    final id = cells[0].trim();
    final name = cells[1].trim();
    final category = _blankToNull(cells[2]);
    final unit = cells[3].trim();
    final sellingPrice = double.tryParse(cells[4].trim());
    final quantity = int.tryParse(cells[5].trim());
    final lowStockThreshold = int.tryParse(cells[6].trim());
    final barcode = _blankToNull(cells[7]);
    final status = cells[8].trim().toLowerCase();
    final createdAt = _parseExportedUtcDate(cells[9]);
    final updatedAt = _parseExportedUtcDate(cells[10]);

    var hasError = false;
    if (id.isEmpty) {
      hasError = true;
      errors.add(_error('Products CSV', rowNumber, 'Product ID is required.'));
    }
    if (sellingPrice == null) {
      hasError = true;
      errors.add(
        _error(
          'Products CSV',
          rowNumber,
          'Selling Price must be a valid number.',
        ),
      );
    }
    if (quantity == null) {
      hasError = true;
      errors.add(
        _error(
          'Products CSV',
          rowNumber,
          'Current Quantity must be a whole number.',
        ),
      );
    }
    if (lowStockThreshold == null) {
      hasError = true;
      errors.add(
        _error(
          'Products CSV',
          rowNumber,
          'Low Stock Threshold must be a whole number.',
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
        _error('Products CSV', rowNumber, 'Status must be Active or Archived.'),
      );
      isArchived = false;
    }
    if (createdAt == null) {
      hasError = true;
      errors.add(
        _error(
          'Products CSV',
          rowNumber,
          'Created At must be a TindaTrack UTC timestamp.',
        ),
      );
    }
    if (updatedAt == null) {
      hasError = true;
      errors.add(
        _error(
          'Products CSV',
          rowNumber,
          'Updated At must be a TindaTrack UTC timestamp.',
        ),
      );
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
        _error('Products CSV', rowNumber, _validationMessage(validation)),
      );
      return null;
    }
    final normalized = _validator.normalize(input);

    return FullRestoreProductRow(
      sourceRowNumber: rowNumber,
      id: id,
      name: normalized.name,
      category: normalized.category,
      unit: normalized.unit,
      sellingPrice: normalized.sellingPrice,
      quantity: normalized.quantity,
      lowStockThreshold: normalized.lowStockThreshold,
      barcode: _blankToNull(normalized.barcode),
      isArchived: isArchived,
      createdAt: createdAt!,
      updatedAt: updatedAt!,
    );
  }

  _MovementsParseResult _parseStockHistoryCsv(
    String csv, {
    required Set<String> productIds,
  }) {
    final parsed = _parseCsv(csv, fileName: 'Stock History CSV');
    if (parsed.errors.isNotEmpty) {
      return _MovementsParseResult(rows: const [], errors: parsed.errors);
    }
    if (_isEmpty(parsed.rows)) {
      return const _MovementsParseResult(
        rows: [],
        errors: [
          FullRestoreError(
            fileName: 'Stock History CSV',
            rowNumber: 0,
            message: 'Stock History CSV file is empty.',
          ),
        ],
      );
    }
    if (!_hasHeader(parsed.rows.first, _stockHistoryHeaders)) {
      return const _MovementsParseResult(
        rows: [],
        errors: [
          FullRestoreError(
            fileName: 'Stock History CSV',
            rowNumber: 1,
            message:
                'This is not a restorable TindaTrack Stock History CSV file.',
          ),
        ],
      );
    }

    final rows = <FullRestoreMovementRow>[];
    final errors = <FullRestoreError>[];
    final idRows = <String, List<int>>{};

    for (var index = 1; index < parsed.rows.length; index++) {
      final rowNumber = index + 1;
      final cells = parsed.rows[index];
      if (cells.every((cell) => cell.trim().isEmpty)) continue;
      if (cells.length != _stockHistoryHeaders.length) {
        errors.add(
          FullRestoreError(
            fileName: 'Stock History CSV',
            rowNumber: rowNumber,
            message:
                'Expected ${_stockHistoryHeaders.length} columns but found '
                '${cells.length}.',
          ),
        );
        continue;
      }

      final row = _parseMovementRow(cells, rowNumber, productIds, errors);
      if (row == null) continue;
      rows.add(row);
      idRows.putIfAbsent(row.id, () => <int>[]).add(rowNumber);
    }

    _addDuplicateErrors(
      rowsByValue: idRows,
      fileName: 'Stock History CSV',
      label: 'Movement ID',
      errors: errors,
    );
    return _MovementsParseResult(rows: rows, errors: errors);
  }

  FullRestoreMovementRow? _parseMovementRow(
    List<String> cells,
    int rowNumber,
    Set<String> productIds,
    List<FullRestoreError> errors,
  ) {
    final id = cells[0].trim();
    final productId = cells[1].trim();
    final createdAt = _parseExportedUtcDate(cells[2]);
    final type = _parseMovementType(cells[3]);
    final reasonText = cells[4].trim();
    final reason = _parseStockOutReason(reasonText);
    final productNameSnapshot = cells[5].trim();
    final quantity = int.tryParse(cells[6].trim());
    final previousQuantity = int.tryParse(cells[7].trim());
    final newQuantity = int.tryParse(cells[8].trim());
    final unitSnapshot = cells[9].trim();
    final note = _blankToNull(cells[10]);

    var hasError = false;
    if (id.isEmpty) {
      hasError = true;
      errors.add(
        _error('Stock History CSV', rowNumber, 'Movement ID is required.'),
      );
    }
    if (productId.isEmpty) {
      hasError = true;
      errors.add(
        _error('Stock History CSV', rowNumber, 'Product ID is required.'),
      );
    } else if (!productIds.contains(productId)) {
      hasError = true;
      errors.add(
        _error(
          'Stock History CSV',
          rowNumber,
          'Product ID $productId was not found in the selected Products CSV.',
        ),
      );
    }
    if (createdAt == null) {
      hasError = true;
      errors.add(
        _error(
          'Stock History CSV',
          rowNumber,
          'Date must be a TindaTrack UTC timestamp.',
        ),
      );
    }
    if (type == null) {
      hasError = true;
      errors.add(
        _error(
          'Stock History CSV',
          rowNumber,
          'Type must be Stock In or Stock Out.',
        ),
      );
    }
    if (reasonText.isNotEmpty && reason == null) {
      hasError = true;
      errors.add(
        _error('Stock History CSV', rowNumber, 'Reason is not supported.'),
      );
    }
    if (type == StockMovementType.stockIn && reasonText.isNotEmpty) {
      hasError = true;
      errors.add(
        _error(
          'Stock History CSV',
          rowNumber,
          'Reason must be blank for Stock In.',
        ),
      );
    }
    if (type == StockMovementType.stockOut && reasonText.isEmpty) {
      hasError = true;
      errors.add(
        _error(
          'Stock History CSV',
          rowNumber,
          'Reason is required for Stock Out.',
        ),
      );
    }
    if (productNameSnapshot.isEmpty) {
      hasError = true;
      errors.add(
        _error(
          'Stock History CSV',
          rowNumber,
          'Product Name Snapshot is required.',
        ),
      );
    }
    if (quantity == null || quantity <= 0) {
      hasError = true;
      errors.add(
        _error(
          'Stock History CSV',
          rowNumber,
          'Quantity must be a positive whole number.',
        ),
      );
    }
    if (previousQuantity == null || previousQuantity < 0) {
      hasError = true;
      errors.add(
        _error(
          'Stock History CSV',
          rowNumber,
          'Previous Quantity cannot be negative.',
        ),
      );
    }
    if (newQuantity == null || newQuantity < 0) {
      hasError = true;
      errors.add(
        _error(
          'Stock History CSV',
          rowNumber,
          'New Quantity cannot be negative.',
        ),
      );
    }
    if (unitSnapshot.isEmpty) {
      hasError = true;
      errors.add(
        _error('Stock History CSV', rowNumber, 'Unit Snapshot is required.'),
      );
    }
    if (type != null &&
        quantity != null &&
        previousQuantity != null &&
        newQuantity != null &&
        !_matchesQuantityTrail(
          type: type,
          quantity: quantity,
          previousQuantity: previousQuantity,
          newQuantity: newQuantity,
        )) {
      hasError = true;
      errors.add(
        _error(
          'Stock History CSV',
          rowNumber,
          'Quantity trail does not match the movement type.',
        ),
      );
    }
    if (hasError) return null;

    return FullRestoreMovementRow(
      sourceRowNumber: rowNumber,
      id: id,
      productId: productId,
      type: type!,
      quantity: quantity!,
      previousQuantity: previousQuantity!,
      newQuantity: newQuantity!,
      reason: reason,
      note: note,
      productNameSnapshot: productNameSnapshot,
      unitSnapshot: unitSnapshot,
      createdAt: createdAt!,
    );
  }

  _CsvParseResult _parseCsv(String csv, {required String fileName}) {
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    final errors = <FullRestoreError>[];
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
        row.add(cell.toString());
        cell.clear();
      } else if (char == '\n') {
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
        FullRestoreError(
          fileName: fileName,
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

  bool _hasHeader(List<String> header, List<String> expected) {
    if (header.length != expected.length) return false;
    for (var index = 0; index < expected.length; index++) {
      if (header[index].trim() != expected[index]) return false;
    }
    return true;
  }

  bool _isEmpty(List<List<String>> rows) {
    return rows.isEmpty ||
        rows.every((row) => row.every((cell) => cell.isEmpty));
  }

  DateTime? _parseExportedUtcDate(String value) {
    final match = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2}) UTC$',
    ).firstMatch(value.trim());
    if (match == null) return null;
    final parsed = DateTime.utc(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6)!),
    );
    return _formatExportedUtcDate(parsed) == value.trim() ? parsed : null;
  }

  String _formatExportedUtcDate(DateTime value) {
    final utc = value.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')} '
        '${utc.hour.toString().padLeft(2, '0')}:'
        '${utc.minute.toString().padLeft(2, '0')}:'
        '${utc.second.toString().padLeft(2, '0')} UTC';
  }

  bool _matchesQuantityTrail({
    required StockMovementType type,
    required int quantity,
    required int previousQuantity,
    required int newQuantity,
  }) {
    return switch (type) {
      StockMovementType.stockIn => newQuantity == previousQuantity + quantity,
      StockMovementType.stockOut => newQuantity == previousQuantity - quantity,
    };
  }

  StockMovementType? _parseMovementType(String value) {
    return switch (value.trim().toLowerCase()) {
      'stock in' => StockMovementType.stockIn,
      'stock out' => StockMovementType.stockOut,
      _ => null,
    };
  }

  StockOutReason? _parseStockOutReason(String value) {
    return switch (value.trim().toLowerCase()) {
      '' => null,
      'sold' => StockOutReason.sold,
      'damaged' => StockOutReason.damaged,
      'lost' => StockOutReason.lost,
      'personal use' => StockOutReason.personalUse,
      'correction' => StockOutReason.correction,
      _ => null,
    };
  }

  String? _blankToNull(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  void _addDuplicateErrors({
    required Map<String, List<int>> rowsByValue,
    required String fileName,
    required String label,
    required List<FullRestoreError> errors,
  }) {
    for (final entry in rowsByValue.entries) {
      if (entry.value.length < 2) continue;
      for (final rowNumber in entry.value) {
        errors.add(
          FullRestoreError(
            fileName: fileName,
            rowNumber: rowNumber,
            message: '$label ${entry.key} appears more than once in this CSV.',
          ),
        );
      }
    }
  }

  FullRestoreError _error(String fileName, int rowNumber, String message) {
    return FullRestoreError(
      fileName: fileName,
      rowNumber: rowNumber,
      message: message,
    );
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
}

final class _ProductsParseResult {
  const _ProductsParseResult({required this.rows, required this.errors});

  final List<FullRestoreProductRow> rows;
  final List<FullRestoreError> errors;
}

final class _MovementsParseResult {
  const _MovementsParseResult({required this.rows, required this.errors});

  final List<FullRestoreMovementRow> rows;
  final List<FullRestoreError> errors;
}

final class _CsvParseResult {
  const _CsvParseResult({required this.rows, required this.errors});

  final List<List<String>> rows;
  final List<FullRestoreError> errors;
}
