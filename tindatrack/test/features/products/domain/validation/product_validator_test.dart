import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/features/products/domain/entities/create_product_input.dart';
import 'package:tindatrack/features/products/domain/failures/product_failure.dart';
import 'package:tindatrack/features/products/domain/validation/product_validator.dart';

void main() {
  const validator = ProductValidator();

  test('normalizes text without changing numeric or barcode values', () {
    const input = CreateProductInput(
      name: '  Rice  ',
      category: '   ',
      unit: '  kg ',
      sellingPrice: 60,
      quantity: 4,
      lowStockThreshold: 2,
      barcode: ' raw ',
    );

    final normalized = validator.normalize(input);

    expect(normalized.name, 'Rice');
    expect(normalized.category, isNull);
    expect(normalized.unit, 'kg');
    expect(normalized.sellingPrice, 60);
    expect(normalized.quantity, 4);
    expect(normalized.lowStockThreshold, 2);
    expect(normalized.barcode, ' raw ');
  });

  test('preserves a trimmed nonblank category', () {
    final normalized = validator.normalize(
      _input(category: '  Staples  '),
    );

    expect(normalized.category, 'Staples');
  });

  test('zero values and the configured maximum are valid', () {
    expect(validator.validate(_input()), isNull);
    expect(
      validator.validate(
        _input(
          quantity: maxProductQuantity,
          lowStockThreshold: maxProductQuantity,
        ),
      ),
      isNull,
    );
  });

  for (final (label, input, field, issue) in [
    (
      'blank name',
      _input(name: '   '),
      ProductField.name,
      ProductValidationIssue.required,
    ),
    (
      'blank unit',
      _input(unit: '   '),
      ProductField.unit,
      ProductValidationIssue.required,
    ),
    (
      'negative selling price',
      _input(sellingPrice: -0.01),
      ProductField.sellingPrice,
      ProductValidationIssue.negative,
    ),
    (
      'non-finite selling price',
      _input(sellingPrice: double.nan),
      ProductField.sellingPrice,
      ProductValidationIssue.invalidNumber,
    ),
    (
      'negative quantity',
      _input(quantity: -1),
      ProductField.quantity,
      ProductValidationIssue.negative,
    ),
    (
      'quantity above maximum',
      _input(quantity: maxProductQuantity + 1),
      ProductField.quantity,
      ProductValidationIssue.tooLarge,
    ),
    (
      'negative threshold',
      _input(lowStockThreshold: -1),
      ProductField.lowStockThreshold,
      ProductValidationIssue.negative,
    ),
    (
      'threshold above maximum',
      _input(lowStockThreshold: maxProductQuantity + 1),
      ProductField.lowStockThreshold,
      ProductValidationIssue.tooLarge,
    ),
  ]) {
    test('$label returns a field-specific failure', () {
      final failure = validator.validate(input);

      expect(failure, isA<ProductValidationFailure>());
      expect(failure?.field, field);
      expect(failure?.issue, issue);
    });
  }
}

CreateProductInput _input({
  String name = 'Rice',
  String? category,
  String unit = 'pcs',
  double sellingPrice = 0,
  int quantity = 0,
  int lowStockThreshold = 0,
}) {
  return CreateProductInput(
    name: name,
    category: category,
    unit: unit,
    sellingPrice: sellingPrice,
    quantity: quantity,
    lowStockThreshold: lowStockThreshold,
  );
}
