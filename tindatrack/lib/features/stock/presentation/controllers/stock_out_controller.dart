import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/domain/validation/product_validator.dart';
import 'package:tindatrack/features/stock/domain/entities/record_stock_out_input.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';
import 'package:tindatrack/features/stock/domain/failures/stock_failure.dart';
import 'package:tindatrack/features/stock/presentation/providers/stock_providers.dart';

/// Stock Out form field identities used for inline validation.
enum StockOutField {
  /// Quantity to remove.
  quantity,
}

/// Raw values submitted by the Stock Out form.
final class StockOutFormValues {
  /// Creates a Stock Out form submission.
  const StockOutFormValues({required this.quantity, required this.note});

  /// Raw quantity text.
  final String quantity;

  /// Raw optional note text.
  final String note;
}

/// Presentation-safe Stock Out submission state.
final class StockOutState {
  /// Creates Stock Out state.
  const StockOutState({
    this.isSaving = false,
    this.isUnavailable = false,
    this.fieldErrors = const <StockOutField, String>{},
    this.message,
  });

  /// Whether one save is currently pending.
  final bool isSaving;

  /// Whether the target product can no longer receive stock changes.
  final bool isUnavailable;

  /// Field-associated safe validation copy.
  final Map<StockOutField, String> fieldErrors;

  /// Safe form-level recovery copy.
  final String? message;

  /// First invalid field in visual order.
  StockOutField? get firstInvalidField {
    return fieldErrors.isEmpty ? null : fieldErrors.keys.first;
  }

  /// Returns safe inline copy for [field].
  String? errorFor(StockOutField field) => fieldErrors[field];
}

/// Owns one Stock Out submission lifecycle for a product.
final class StockOutController extends Notifier<StockOutState> {
  /// Creates a controller keyed by [productId].
  StockOutController(this.productId);

  /// Product losing stock.
  final String productId;

  @override
  StockOutState build() => const StockOutState();

  /// Parses and records Stock Out at most once while saving.
  Future<StockMovement?> submit(
    StockOutFormValues values, {
    int? availableQuantity,
  }) async {
    if (state.isSaving || state.isUnavailable) return null;

    final parsed = _parse(values, availableQuantity: availableQuantity);
    if (parsed.errors.isNotEmpty) {
      state = StockOutState(fieldErrors: parsed.errors);
      return null;
    }

    state = const StockOutState(isSaving: true);
    try {
      final result = await ref
          .read(stockRepositoryProvider)
          .recordStockOut(
            RecordStockOutInput(
              productId: productId,
              quantity: parsed.quantity!,
              note: values.note,
            ),
          );
      if (!ref.mounted) return null;
      return switch (result) {
        Success<StockMovement>(:final value) => _completeSuccess(value),
        FailureResult<StockMovement>(:final failure) => _completeFailure(
          failure,
        ),
      };
    } on Object {
      if (!ref.mounted) return null;
      state = const StockOutState(
        message: 'Something went wrong. Please try again.',
      );
      return null;
    }
  }

  StockMovement _completeSuccess(StockMovement movement) {
    state = const StockOutState();
    return movement;
  }

  StockMovement? _completeFailure(AppFailure failure) {
    if (failure case StockMovementValidationFailure()) {
      state = StockOutState(
        fieldErrors: <StockOutField, String>{
          StockOutField.quantity: _validationMessage(failure),
        },
      );
      return null;
    }
    if (failure case StockInsufficientQuantityFailure()) {
      state = const StockOutState(
        fieldErrors: <StockOutField, String>{
          StockOutField.quantity: _notEnoughStockMessage,
        },
      );
      return null;
    }

    final isUnavailable =
        failure is StockProductNotFoundFailure ||
        failure is StockArchivedProductFailure;
    final message = switch (failure) {
      StockProductNotFoundFailure() ||
      StockArchivedProductFailure() => 'This product is no longer available.',
      PersistenceFailure() => "We couldn't record stock out. Please try again.",
      _ => 'Something went wrong. Please try again.',
    };
    state = StockOutState(isUnavailable: isUnavailable, message: message);
    return null;
  }
}

const _notEnoughStockMessage = 'Not enough stock available.';

final class _ParsedStockOutForm {
  const _ParsedStockOutForm({required this.quantity, required this.errors});

  final int? quantity;
  final Map<StockOutField, String> errors;
}

_ParsedStockOutForm _parse(
  StockOutFormValues values, {
  int? availableQuantity,
}) {
  final rawQuantity = values.quantity.trim();
  final quantity = int.tryParse(rawQuantity);
  if (quantity == null) {
    return const _ParsedStockOutForm(
      quantity: null,
      errors: <StockOutField, String>{
        StockOutField.quantity: 'Enter a valid quantity.',
      },
    );
  }
  if (quantity <= 0) {
    return const _ParsedStockOutForm(
      quantity: null,
      errors: <StockOutField, String>{
        StockOutField.quantity: 'Enter a quantity greater than 0.',
      },
    );
  }
  if (quantity > maxProductQuantity) {
    return const _ParsedStockOutForm(
      quantity: null,
      errors: <StockOutField, String>{
        StockOutField.quantity: 'Enter $maxProductQuantity or less.',
      },
    );
  }
  if (availableQuantity != null && quantity > availableQuantity) {
    return const _ParsedStockOutForm(
      quantity: null,
      errors: <StockOutField, String>{
        StockOutField.quantity: _notEnoughStockMessage,
      },
    );
  }
  return _ParsedStockOutForm(
    quantity: quantity,
    errors: const <StockOutField, String>{},
  );
}

String _validationMessage(StockMovementValidationFailure failure) {
  return switch ((failure.field, failure.issue)) {
    (StockMovementField.quantity, StockMovementValidationIssue.notPositive) =>
      'Enter a quantity greater than 0.',
    _ => 'Enter a valid quantity.',
  };
}

/// Auto-disposed Stock Out state keyed by stable product ID.
final NotifierProviderFamily<StockOutController, StockOutState, String>
stockOutControllerProvider = NotifierProvider.autoDispose
    .family<StockOutController, StockOutState, String>(StockOutController.new);
