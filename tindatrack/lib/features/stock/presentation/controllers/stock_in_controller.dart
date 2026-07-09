import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/products/domain/validation/product_validator.dart';
import 'package:tindatrack/features/stock/domain/entities/record_stock_in_input.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';
import 'package:tindatrack/features/stock/domain/failures/stock_failure.dart';
import 'package:tindatrack/features/stock/presentation/providers/stock_providers.dart';

/// Stock In form field identities used for inline validation.
enum StockInField {
  /// Quantity to add.
  quantity,
}

/// Raw values submitted by the Stock In form.
final class StockInFormValues {
  /// Creates a Stock In form submission.
  const StockInFormValues({required this.quantity, required this.note});

  /// Raw quantity text.
  final String quantity;

  /// Raw optional note text.
  final String note;
}

/// Presentation-safe Stock In submission state.
final class StockInState {
  /// Creates Stock In state.
  const StockInState({
    this.isSaving = false,
    this.isUnavailable = false,
    this.fieldErrors = const <StockInField, String>{},
    this.message,
  });

  /// Whether one save is currently pending.
  final bool isSaving;

  /// Whether the target product can no longer receive stock changes.
  final bool isUnavailable;

  /// Field-associated safe validation copy.
  final Map<StockInField, String> fieldErrors;

  /// Safe form-level recovery copy.
  final String? message;

  /// First invalid field in visual order.
  StockInField? get firstInvalidField {
    return fieldErrors.isEmpty ? null : fieldErrors.keys.first;
  }

  /// Returns safe inline copy for [field].
  String? errorFor(StockInField field) => fieldErrors[field];
}

/// Owns one Stock In submission lifecycle for a product.
final class StockInController extends Notifier<StockInState> {
  /// Creates a controller keyed by [productId].
  StockInController(this.productId);

  /// Product receiving stock.
  final String productId;

  @override
  StockInState build() => const StockInState();

  /// Parses and records Stock In at most once while saving.
  Future<StockMovement?> submit(StockInFormValues values) async {
    if (state.isSaving || state.isUnavailable) return null;

    final parsed = _parse(values);
    if (parsed.errors.isNotEmpty) {
      state = StockInState(fieldErrors: parsed.errors);
      return null;
    }

    state = const StockInState(isSaving: true);
    try {
      final result = await ref
          .read(stockRepositoryProvider)
          .recordStockIn(
            RecordStockInInput(
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
      state = const StockInState(
        message: 'Something went wrong. Please try again.',
      );
      return null;
    }
  }

  StockMovement _completeSuccess(StockMovement movement) {
    state = const StockInState();
    return movement;
  }

  StockMovement? _completeFailure(AppFailure failure) {
    if (failure case StockMovementValidationFailure()) {
      state = StockInState(
        fieldErrors: <StockInField, String>{
          StockInField.quantity: _validationMessage(failure),
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
      PersistenceFailure() => "We couldn't record stock in. Please try again.",
      _ => 'Something went wrong. Please try again.',
    };
    state = StockInState(isUnavailable: isUnavailable, message: message);
    return null;
  }
}

final class _ParsedStockInForm {
  const _ParsedStockInForm({required this.quantity, required this.errors});

  final int? quantity;
  final Map<StockInField, String> errors;
}

_ParsedStockInForm _parse(StockInFormValues values) {
  final rawQuantity = values.quantity.trim();
  final quantity = int.tryParse(rawQuantity);
  if (quantity == null) {
    return const _ParsedStockInForm(
      quantity: null,
      errors: <StockInField, String>{
        StockInField.quantity: 'Enter a valid quantity.',
      },
    );
  }
  if (quantity <= 0) {
    return const _ParsedStockInForm(
      quantity: null,
      errors: <StockInField, String>{
        StockInField.quantity: 'Enter a quantity greater than 0.',
      },
    );
  }
  if (quantity > maxProductQuantity) {
    return const _ParsedStockInForm(
      quantity: null,
      errors: <StockInField, String>{
        StockInField.quantity: 'Enter $maxProductQuantity or less.',
      },
    );
  }
  return _ParsedStockInForm(
    quantity: quantity,
    errors: const <StockInField, String>{},
  );
}

String _validationMessage(StockMovementValidationFailure failure) {
  return switch ((failure.field, failure.issue)) {
    (StockMovementField.quantity, StockMovementValidationIssue.notPositive) =>
      'Enter a quantity greater than 0.',
    _ => 'Enter a valid quantity.',
  };
}

/// Auto-disposed Stock In state keyed by stable product ID.
final NotifierProviderFamily<StockInController, StockInState, String>
stockInControllerProvider = NotifierProvider.autoDispose
    .family<StockInController, StockInState, String>(StockInController.new);
