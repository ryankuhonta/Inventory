import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tindatrack/app/navigation/product_child_back_handler.dart';
import 'package:tindatrack/app/router/app_routes.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/core/ui/app_spacing.dart';
import 'package:tindatrack/core/widgets/app_error_view.dart';
import 'package:tindatrack/core/widgets/app_loading_view.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/failures/product_failure.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';
import 'package:tindatrack/features/stock/presentation/controllers/stock_out_controller.dart';
import 'package:tindatrack/features/stock/presentation/providers/stock_providers.dart';
import 'package:tindatrack/features/stock/presentation/widgets/stock_note_autocomplete_field.dart';

const _maxStockOutQuantityLength = 9;

/// Records removed stock for one active product.
final class StockOutScreen extends ConsumerWidget {
  /// Creates the Stock Out screen for [productId].
  const StockOutScreen({required this.productId, super.key});

  /// Stable product identity from the route.
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productByIdProvider(productId));
    return switch (product) {
      AsyncData<Result<Product>>(value: Success<Product>(:final value)) =>
        _StockOutForm(product: value),
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
        key: const Key('stock-out-screen'),
        appBar: AppBar(title: const Text('Stock Out')),
        body: const AppLoadingView(
          title: 'Stock Out',
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
      key: const Key('stock-out-screen'),
      appBar: AppBar(title: const Text('Stock Out')),
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

final class _StockOutForm extends ConsumerStatefulWidget {
  const _StockOutForm({required this.product});

  final Product product;

  @override
  ConsumerState<_StockOutForm> createState() => _StockOutFormState();
}

final class _StockOutFormState extends ConsumerState<_StockOutForm> {
  late final TextEditingController _quantityController;
  late final TextEditingController _noteController;
  final _quantityFocus = FocusNode();
  final _noteFocus = FocusNode();
  late final ProductChildBackHandler _backHandler;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController();
    _noteController = TextEditingController();
    _backHandler = _handleHardwareBack;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      productChildBackRegistry.handler = _backHandler;
    });
  }

  @override
  void dispose() {
    productChildBackRegistry.unregister(_backHandler);
    _quantityController.dispose();
    _noteController.dispose();
    _quantityFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = stockOutControllerProvider(widget.product.id);
    final state = ref.watch(provider);
    final spacing = AppSpacing.of(context);
    final fieldsEnabled = !state.isSaving && !state.isUnavailable;
    final noteSuggestions = switch (ref.watch(
      stockNoteSuggestionsProvider(StockMovementType.stockOut),
    )) {
      AsyncData<List<String>>(:final value) => value,
      _ => const <String>[],
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_handleBack(isSaving: state.isSaving));
      },
      child: Scaffold(
        key: const Key('stock-out-screen'),
        appBar: AppBar(title: const Text('Stock Out')),
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
                    key: const Key('stock-out-current-quantity'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                SizedBox(height: spacing.lg),
                if (state.message case final message?)
                  _FormMessage(message: message),
                TextFormField(
                  key: const Key('stock-out-quantity-field'),
                  controller: _quantityController,
                  focusNode: _quantityFocus,
                  enabled: fieldsEnabled,
                  decoration: InputDecoration(
                    labelText: 'Quantity to remove',
                    errorText: state.errorFor(StockOutField.quantity),
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(
                      _maxStockOutQuantityLength,
                    ),
                  ],
                  onFieldSubmitted: (_) => _noteFocus.requestFocus(),
                ),
                SizedBox(height: spacing.md),
                StockNoteAutocompleteField(
                  fieldKey: const Key('stock-out-note-field'),
                  controller: _noteController,
                  focusNode: _noteFocus,
                  enabled: fieldsEnabled,
                  suggestions: noteSuggestions,
                  onSubmitted: _submit,
                ),
                SizedBox(height: spacing.lg),
                FilledButton(
                  key: const Key('record-stock-out-button'),
                  onPressed: fieldsEnabled ? _submit : null,
                  child: state.isSaving
                      ? const _SavingLabel()
                      : const Text('Record Stock Out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleHardwareBack() async {
    final state = ref.read(stockOutControllerProvider(widget.product.id));
    await _handleBack(isSaving: state.isSaving);
  }

  Future<void> _handleBack({required bool isSaving}) async {
    if (isSaving) return;
    FocusScope.of(context).unfocus();
    if (!_hasDraftInput) {
      _returnToProducts();
      return;
    }

    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel stock out?'),
        content: const Text(
          'This stock out has not been recorded. Discard it and go back?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (!mounted || discard != true) return;
    _returnToProducts();
  }

  bool get _hasDraftInput =>
      _quantityController.text.trim().isNotEmpty ||
      _noteController.text.trim().isNotEmpty;

  void _returnToProducts() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.goNamed(AppRoute.products.name);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final movement = await ref
        .read(stockOutControllerProvider(widget.product.id).notifier)
        .submit(
          StockOutFormValues(
            quantity: _quantityController.text,
            note: _noteController.text,
          ),
          availableQuantity: widget.product.quantity,
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
    final state = ref.read(stockOutControllerProvider(widget.product.id));
    final focus = switch (state.firstInvalidField) {
      StockOutField.quantity => _quantityFocus,
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
  return 'Removed ${movement.quantity} ${product.unit} from ${product.name}. '
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
      label: 'Saving stock out',
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
