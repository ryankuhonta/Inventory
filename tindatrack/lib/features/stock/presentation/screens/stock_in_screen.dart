import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/core/ui/app_spacing.dart';
import 'package:tindatrack/core/widgets/app_error_view.dart';
import 'package:tindatrack/core/widgets/app_loading_view.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/failures/product_failure.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';
import 'package:tindatrack/features/stock/presentation/controllers/stock_in_controller.dart';
import 'package:tindatrack/features/stock/presentation/providers/stock_providers.dart';
import 'package:tindatrack/features/stock/presentation/widgets/stock_note_autocomplete_field.dart';

const _maxStockInQuantityLength = 9;

/// Records added stock for one active product.
final class StockInScreen extends ConsumerWidget {
  /// Creates the Stock In screen for [productId].
  const StockInScreen({required this.productId, super.key});

  /// Stable product identity from the route.
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productByIdProvider(productId));
    return switch (product) {
      AsyncData<Result<Product>>(value: Success<Product>(:final value)) =>
        _StockInForm(product: value),
      AsyncData<Result<Product>>(
        value: FailureResult<Product>(:final failure),
      ) =>
        _UnavailableProduct(
          failure: failure,
          onRetry: () => ref.invalidate(productByIdProvider(productId)),
        ),
      AsyncError<Result<Product>>() => _UnavailableProduct(
        onRetry: () => ref.invalidate(productByIdProvider(productId)),
      ),
      _ => Scaffold(
        key: const Key('stock-in-screen'),
        appBar: AppBar(title: const Text('Stock In')),
        body: const AppLoadingView(
          title: 'Stock In',
          semanticsLabel: 'Loading product details',
        ),
      ),
    };
  }
}

final class _UnavailableProduct extends StatelessWidget {
  const _UnavailableProduct({required this.onRetry, this.failure});

  final VoidCallback onRetry;
  final Object? failure;

  @override
  Widget build(BuildContext context) {
    final isGone =
        failure is ProductNotFoundFailure || failure is ArchivedProductFailure;
    return Scaffold(
      key: const Key('stock-in-screen'),
      appBar: AppBar(title: const Text('Stock In')),
      body: AppErrorView(
        title: 'Product unavailable',
        message: isGone
            ? 'This product is no longer available for stock changes.'
            : "We couldn't load this product. Please try again.",
        actionLabel: 'Retry',
        onAction: onRetry,
      ),
    );
  }
}

final class _StockInForm extends ConsumerStatefulWidget {
  const _StockInForm({required this.product});

  final Product product;

  @override
  ConsumerState<_StockInForm> createState() => _StockInFormState();
}

final class _StockInFormState extends ConsumerState<_StockInForm> {
  late final TextEditingController _quantityController;
  late final TextEditingController _noteController;
  final _quantityFocus = FocusNode();
  final _noteFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    _quantityFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = stockInControllerProvider(widget.product.id);
    final state = ref.watch(provider);
    final spacing = AppSpacing.of(context);
    final fieldsEnabled = !state.isSaving && !state.isUnavailable;
    final noteSuggestions = switch (ref.watch(
      stockNoteSuggestionsProvider(StockMovementType.stockIn),
    )) {
      AsyncData<List<String>>(:final value) => value,
      _ => const <String>[],
    };

    return PopScope(
      canPop: !state.isSaving,
      child: Scaffold(
        key: const Key('stock-in-screen'),
        appBar: AppBar(title: const Text('Stock In')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.product.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: spacing.xs),
                Semantics(
                  label:
                      'Current quantity ${widget.product.quantity} '
                      '${widget.product.unit}',
                  excludeSemantics: true,
                  child: Text(
                    'Current quantity: ${widget.product.quantity} '
                    '${widget.product.unit}',
                    key: const Key('stock-in-current-quantity'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                SizedBox(height: spacing.lg),
                if (state.message case final message?)
                  _FormMessage(message: message),
                TextFormField(
                  key: const Key('stock-in-quantity-field'),
                  controller: _quantityController,
                  focusNode: _quantityFocus,
                  enabled: fieldsEnabled,
                  decoration: InputDecoration(
                    labelText: 'Quantity to add',
                    errorText: state.errorFor(StockInField.quantity),
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                      _maxStockInQuantityLength,
                    ),
                  ],
                  onFieldSubmitted: (_) => _noteFocus.requestFocus(),
                ),
                SizedBox(height: spacing.md),
                StockNoteAutocompleteField(
                  fieldKey: const Key('stock-in-note-field'),
                  controller: _noteController,
                  focusNode: _noteFocus,
                  enabled: fieldsEnabled,
                  suggestions: noteSuggestions,
                  onSubmitted: _submit,
                ),
                SizedBox(height: spacing.lg),
                FilledButton(
                  key: const Key('record-stock-in-button'),
                  onPressed: fieldsEnabled ? _submit : null,
                  child: state.isSaving
                      ? const _SavingLabel()
                      : const Text('Record Stock In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final movement = await ref
        .read(stockInControllerProvider(widget.product.id).notifier)
        .submit(
          StockInFormValues(
            quantity: _quantityController.text,
            note: _noteController.text,
          ),
        );
    if (!mounted) return;
    if (movement == null) {
      await _focusFirstInvalid();
      return;
    }

    _refreshProductData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_successMessage(widget.product, movement))),
    );
    context.pop();
  }

  void _refreshProductData() {
    ref
      ..invalidate(productByIdProvider(widget.product.id))
      ..invalidate(activeProductsProvider);
  }

  Future<void> _focusFirstInvalid() async {
    final state = ref.read(stockInControllerProvider(widget.product.id));
    final focus = switch (state.firstInvalidField) {
      StockInField.quantity => _quantityFocus,
      null => null,
    };
    focus?.requestFocus();
    final fieldContext = focus?.context;
    if (fieldContext != null) {
      await Scrollable.ensureVisible(
        fieldContext,
        alignment: 0.2,
        duration: const Duration(milliseconds: 150),
      );
    }
  }
}

String _successMessage(Product product, StockMovement movement) {
  return 'Added ${movement.quantity} ${product.unit} to ${product.name}. '
      'New stock: ${movement.newQuantity} ${product.unit}.';
}

final class _FormMessage extends StatelessWidget {
  const _FormMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: EdgeInsets.only(bottom: spacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(width: spacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

final class _SavingLabel extends StatelessWidget {
  const _SavingLabel();

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    return Semantics(
      label: 'Saving stock in',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: spacing.sm),
          const Text('Saving...'),
        ],
      ),
    );
  }
}
