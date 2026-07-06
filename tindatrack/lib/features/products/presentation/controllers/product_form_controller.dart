import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/domain/entities/create_product_input.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/entities/update_product_input.dart';
import 'package:tindatrack/features/products/domain/failures/product_failure.dart';
import 'package:tindatrack/features/products/domain/validation/product_validator.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';

/// Raw values shared by Add and Edit Product detail fields.
final class ProductDetailsFormValues {
  /// Creates a raw editable-details submission.
  const ProductDetailsFormValues({
    required this.name,
    required this.category,
    required this.unit,
    required this.sellingPrice,
    required this.lowStockThreshold,
    required this.barcode,
  });

  /// Raw product name.
  final String name;

  /// Raw optional category.
  final String category;

  /// Raw unit.
  final String unit;

  /// Raw optional selling price.
  final String sellingPrice;

  /// Raw low-stock threshold.
  final String lowStockThreshold;

  /// Raw optional manual barcode.
  final String barcode;
}

/// Raw values collected by the Add Product form.
final class ProductFormValues {
  /// Creates a raw form submission.
  const ProductFormValues({
    required this.name,
    required this.category,
    required this.unit,
    required this.sellingPrice,
    required this.quantity,
    required this.lowStockThreshold,
  });

  /// Raw product name.
  final String name;

  /// Raw optional category.
  final String category;

  /// Raw unit.
  final String unit;

  /// Raw optional selling price.
  final String sellingPrice;

  /// Raw starting quantity.
  final String quantity;

  /// Raw low-stock threshold.
  final String lowStockThreshold;
}

/// Presentation-safe Add Product submission state.
final class ProductFormState {
  /// Creates product form state.
  const ProductFormState({
    this.isSaving = false,
    this.wasSaved = false,
    this.fieldErrors = const <ProductField, String>{},
    this.message,
  });

  /// Whether one save is currently pending.
  final bool isSaving;

  /// Whether the latest submission completed successfully.
  final bool wasSaved;

  /// Field-associated safe validation copy.
  final Map<ProductField, String> fieldErrors;

  /// Safe form-level recovery copy.
  final String? message;

  /// First invalid field in visual form order.
  ProductField? get firstInvalidField {
    return fieldErrors.isEmpty ? null : fieldErrors.keys.first;
  }

  /// Returns safe inline copy for [field].
  String? errorFor(ProductField field) => fieldErrors[field];
}

/// Owns Add Product parsing and asynchronous submission state.
final class ProductFormController extends Notifier<ProductFormState> {
  @override
  ProductFormState build() => const ProductFormState();

  /// Validates raw values and submits at most one save operation.
  Future<bool> submit(ProductFormValues values) async {
    if (state.isSaving) return false;

    final parsed = _parse(values);
    if (parsed.errors.isNotEmpty) {
      state = ProductFormState(fieldErrors: parsed.errors);
      return false;
    }

    state = const ProductFormState(isSaving: true);
    try {
      final result = await ref.read(addProductProvider)(parsed.input!);
      if (!ref.mounted) return false;

      return switch (result) {
        Success<Product>() => _completeSuccess(),
        FailureResult<Product>(:final failure) => _completeFailure(failure),
      };
    } on Object {
      if (!ref.mounted) return false;
      state = const ProductFormState(
        message: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  bool _completeSuccess() {
    state = const ProductFormState(wasSaved: true);
    return true;
  }

  bool _completeFailure(AppFailure failure) {
    if (failure case ProductValidationFailure()) {
      state = ProductFormState(
        fieldErrors: <ProductField, String>{
          failure.field: productValidationMessage(failure),
        },
      );
      return false;
    }
    final message = switch (failure) {
      DuplicateBarcodeFailure() => 'Barcode already used by another product.',
      PersistenceFailure() =>
        "We couldn't save this product. Please try again.",
      _ => 'Something went wrong. Please try again.',
    };
    state = ProductFormState(message: message);
    return false;
  }
}

/// Auto-disposed state owner for the Add Product form.
final NotifierProvider<ProductFormController, ProductFormState>
productFormControllerProvider =
    NotifierProvider.autoDispose<ProductFormController, ProductFormState>(
      ProductFormController.new,
    );

/// Parsed editable details plus safe field errors.
final class ParsedProductDetails {
  /// Creates a shared Add/Edit parsing result.
  const ParsedProductDetails({required this.input, required this.errors});

  /// Parsed details when every shared field is valid.
  final UpdateProductInput? input;

  /// Safe field-associated parsing errors.
  final Map<ProductField, String> errors;
}

/// Parses the detail fields shared by Add and Edit Product.
ParsedProductDetails parseProductDetails(ProductDetailsFormValues values) {
  final errors = <ProductField, String>{};
  if (values.name.trim().isEmpty) {
    errors[ProductField.name] = 'Enter a product name.';
  }
  if (values.unit.trim().isEmpty) {
    errors[ProductField.unit] = 'Enter a unit.';
  }

  final rawPrice = values.sellingPrice.trim();
  final sellingPrice = rawPrice.isEmpty ? 0.0 : double.tryParse(rawPrice);
  if (sellingPrice == null || !sellingPrice.isFinite) {
    errors[ProductField.sellingPrice] = 'Enter a valid selling price.';
  } else if (sellingPrice < 0) {
    errors[ProductField.sellingPrice] = 'Selling price cannot be below 0.';
  }

  final threshold = int.tryParse(values.lowStockThreshold.trim());
  if (threshold == null) {
    errors[ProductField.lowStockThreshold] =
        'Enter a valid low-stock threshold.';
  } else if (threshold < 0) {
    errors[ProductField.lowStockThreshold] =
        'Low-stock threshold cannot be below 0.';
  } else if (threshold > maxProductQuantity) {
    errors[ProductField.lowStockThreshold] =
        'Enter $maxProductQuantity or less.';
  }

  if (errors.isNotEmpty) {
    return ParsedProductDetails(input: null, errors: errors);
  }
  return ParsedProductDetails(
    input: UpdateProductInput(
      name: values.name,
      category: values.category,
      unit: values.unit,
      sellingPrice: sellingPrice!,
      lowStockThreshold: threshold!,
      barcode: values.barcode,
    ),
    errors: const <ProductField, String>{},
  );
}

final class _ParsedForm {
  const _ParsedForm({required this.input, required this.errors});

  final CreateProductInput? input;
  final Map<ProductField, String> errors;
}

_ParsedForm _parse(ProductFormValues values) {
  final details = parseProductDetails(
    ProductDetailsFormValues(
      name: values.name,
      category: values.category,
      unit: values.unit,
      sellingPrice: values.sellingPrice,
      lowStockThreshold: values.lowStockThreshold,
      barcode: '',
    ),
  );
  final errors = Map<ProductField, String>.of(details.errors);
  final thresholdError = errors.remove(ProductField.lowStockThreshold);

  final quantity = int.tryParse(values.quantity.trim());
  if (quantity == null) {
    errors[ProductField.quantity] = 'Enter a valid starting quantity.';
  } else if (quantity < 0) {
    errors[ProductField.quantity] = 'Starting quantity cannot be below 0.';
  } else if (quantity > maxProductQuantity) {
    errors[ProductField.quantity] = 'Enter $maxProductQuantity or less.';
  }
  if (thresholdError != null) {
    errors[ProductField.lowStockThreshold] = thresholdError;
  }

  if (errors.isNotEmpty) {
    return _ParsedForm(input: null, errors: errors);
  }
  final input = details.input!;
  return _ParsedForm(
    input: CreateProductInput(
      name: input.name,
      category: input.category,
      unit: input.unit,
      sellingPrice: input.sellingPrice,
      quantity: quantity!,
      lowStockThreshold: input.lowStockThreshold,
    ),
    errors: const <ProductField, String>{},
  );
}

/// Maps domain validation to safe field-associated copy.
String productValidationMessage(ProductValidationFailure failure) {
  return switch ((failure.field, failure.issue)) {
    (ProductField.name, ProductValidationIssue.required) =>
      'Enter a product name.',
    (ProductField.unit, ProductValidationIssue.required) => 'Enter a unit.',
    (ProductField.sellingPrice, ProductValidationIssue.negative) =>
      'Selling price cannot be below 0.',
    (ProductField.sellingPrice, _) => 'Enter a valid selling price.',
    (ProductField.quantity, ProductValidationIssue.negative) =>
      'Starting quantity cannot be below 0.',
    (ProductField.quantity, ProductValidationIssue.tooLarge) =>
      'Enter $maxProductQuantity or less.',
    (ProductField.quantity, _) => 'Enter a valid starting quantity.',
    (ProductField.lowStockThreshold, ProductValidationIssue.negative) =>
      'Low-stock threshold cannot be below 0.',
    (ProductField.lowStockThreshold, ProductValidationIssue.tooLarge) =>
      'Enter $maxProductQuantity or less.',
    (ProductField.lowStockThreshold, _) => 'Enter a valid low-stock threshold.',
    _ => 'Enter a valid value.',
  };
}
