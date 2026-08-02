import 'package:tindatrack/features/products/domain/entities/create_product_input.dart';
import 'package:tindatrack/features/products/domain/entities/update_product_input.dart';
import 'package:tindatrack/features/products/domain/failures/product_failure.dart';

/// Practical upper bound for product quantities and thresholds.
const maxProductQuantity = 999999;

/// Normalizes and validates product creation input without framework coupling.
final class ProductValidator {
  /// Creates the stateless product validator.
  const ProductValidator();

  /// Trims required text and converts a blank category to `null`.
  CreateProductInput normalize(CreateProductInput input) {
    final category = input.category?.trim();
    return CreateProductInput(
      name: input.name.trim(),
      category: category == null || category.isEmpty ? null : category,
      unit: input.unit.trim(),
      sellingPrice: input.sellingPrice,
      quantity: input.quantity,
      lowStockThreshold: input.lowStockThreshold,
      barcode: input.barcode,
    );
  }

  /// Applies the canonical product normalization to editable details.
  UpdateProductInput normalizeUpdate(UpdateProductInput input) {
    final normalized = normalize(
      CreateProductInput(
        name: input.name,
        category: input.category,
        unit: input.unit,
        sellingPrice: input.sellingPrice,
        quantity: 0,
        lowStockThreshold: input.lowStockThreshold,
        barcode: input.barcode,
      ),
    );
    return UpdateProductInput(
      name: normalized.name,
      category: normalized.category,
      unit: normalized.unit,
      sellingPrice: normalized.sellingPrice,
      lowStockThreshold: normalized.lowStockThreshold,
      barcode: normalized.barcode,
    );
  }

  /// Reuses canonical detail validation with a neutral valid quantity.
  ProductValidationFailure? validateUpdate(UpdateProductInput input) {
    return validate(
      CreateProductInput(
        name: input.name,
        category: input.category,
        unit: input.unit,
        sellingPrice: input.sellingPrice,
        quantity: 0,
        lowStockThreshold: input.lowStockThreshold,
        barcode: input.barcode,
      ),
    );
  }

  /// Returns the first validation failure in visual form order.
  ProductValidationFailure? validate(CreateProductInput input) {
    if (input.name.trim().isEmpty) {
      return const ProductValidationFailure(
        field: ProductField.name,
        issue: ProductValidationIssue.required,
      );
    }
    if (input.unit.trim().isEmpty) {
      return const ProductValidationFailure(
        field: ProductField.unit,
        issue: ProductValidationIssue.required,
      );
    }
    if (!input.sellingPrice.isFinite) {
      return const ProductValidationFailure(
        field: ProductField.sellingPrice,
        issue: ProductValidationIssue.invalidNumber,
      );
    }
    if (input.sellingPrice < 0) {
      return const ProductValidationFailure(
        field: ProductField.sellingPrice,
        issue: ProductValidationIssue.negative,
      );
    }
    if (input.quantity < 0) {
      return const ProductValidationFailure(
        field: ProductField.quantity,
        issue: ProductValidationIssue.negative,
      );
    }
    if (input.quantity > maxProductQuantity) {
      return const ProductValidationFailure(
        field: ProductField.quantity,
        issue: ProductValidationIssue.tooLarge,
      );
    }
    if (input.lowStockThreshold < 0) {
      return const ProductValidationFailure(
        field: ProductField.lowStockThreshold,
        issue: ProductValidationIssue.negative,
      );
    }
    if (input.lowStockThreshold > maxProductQuantity) {
      return const ProductValidationFailure(
        field: ProductField.lowStockThreshold,
        issue: ProductValidationIssue.tooLarge,
      );
    }
    return null;
  }
}
