import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/failures/product_failure.dart';
import 'package:tindatrack/features/products/presentation/controllers/product_form_controller.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';

/// Owns one Edit Product submission lifecycle.
final class EditProductController extends Notifier<ProductFormState> {
  /// Creates a controller for [productId].
  EditProductController(this.productId);

  /// Stable product identity supplied by the route.
  final String productId;

  @override
  ProductFormState build() => const ProductFormState();

  /// Archives this product at most once while no save is pending.
  Future<bool> archive() async {
    if (state.isSaving || state.isArchiving || state.isUnavailable) {
      return false;
    }

    state = ProductFormState(
      isArchiving: true,
      fieldErrors: state.fieldErrors,
    );
    try {
      final result = await ref.read(archiveProductProvider)(productId);
      if (!ref.mounted) return false;
      return switch (result) {
        Success<void>() => _completeArchiveSuccess(),
        FailureResult<void>(:final failure) => _completeArchiveFailure(failure),
      };
    } on Object {
      if (!ref.mounted) return false;
      state = ProductFormState(
        fieldErrors: state.fieldErrors,
        message: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  /// Parses editable details and submits at most one update.
  Future<bool> submit(ProductDetailsFormValues values) async {
    if (state.isSaving || state.isArchiving || state.isUnavailable) {
      return false;
    }

    final parsed = parseProductDetails(values);
    if (parsed.errors.isNotEmpty) {
      state = ProductFormState(fieldErrors: parsed.errors);
      return false;
    }

    state = const ProductFormState(isSaving: true);
    try {
      final result = await ref.read(updateProductProvider)(
        productId,
        parsed.input!,
      );
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

  bool _completeArchiveSuccess() {
    state = const ProductFormState();
    return true;
  }

  bool _completeArchiveFailure(AppFailure failure) {
    final isUnavailable =
        failure is ProductNotFoundFailure || failure is ArchivedProductFailure;
    final message = switch (failure) {
      ProductNotFoundFailure() ||
      ArchivedProductFailure() => 'This product is no longer available.',
      PersistenceFailure() =>
        "We couldn't archive this product. Please try again.",
      _ => 'Something went wrong. Please try again.',
    };
    state = ProductFormState(
      isUnavailable: isUnavailable,
      fieldErrors: state.fieldErrors,
      message: message,
    );
    return false;
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
      ProductNotFoundFailure() ||
      ArchivedProductFailure() => 'This product is no longer available.',
      PersistenceFailure() =>
        "We couldn't update this product. Please try again.",
      _ => 'Something went wrong. Please try again.',
    };
    state = ProductFormState(
      isUnavailable:
          failure is ProductNotFoundFailure ||
          failure is ArchivedProductFailure,
      message: message,
    );
    return false;
  }
}

/// Auto-disposed edit state keyed by stable product ID.
final NotifierProviderFamily<EditProductController, ProductFormState, String>
editProductControllerProvider = NotifierProvider.autoDispose
    .family<EditProductController, ProductFormState, String>(
      EditProductController.new,
    );
