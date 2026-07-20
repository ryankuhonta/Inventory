import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tindatrack/app/router/app_routes.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/core/ui/app_spacing.dart';
import 'package:tindatrack/core/widgets/app_error_view.dart';
import 'package:tindatrack/core/widgets/app_loading_view.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/failures/product_failure.dart';
import 'package:tindatrack/features/products/presentation/controllers/edit_product_controller.dart';
import 'package:tindatrack/features/products/presentation/controllers/product_form_controller.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';

/// Loads and edits one active product by stable route identity.
final class EditProductScreen extends ConsumerWidget {
  /// Creates the Edit Product screen for [productId].
  const EditProductScreen({required this.productId, super.key});

  /// Stable product identity from the route.
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productByIdProvider(productId));
    return switch (product) {
      AsyncData<Result<Product>>(
        value: Success<Product>(:final value),
      ) =>
        _EditProductForm(product: value),
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
        key: const Key('edit-product-screen'),
        appBar: AppBar(title: const Text('Edit Product')),
        body: const AppLoadingView(
          title: 'Edit Product',
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
      key: const Key('edit-product-screen'),
      appBar: AppBar(title: const Text('Edit Product')),
      body: AppErrorView(
        title: 'Product unavailable',
        message: isGone
            ? 'This product is no longer available to edit.'
            : "We couldn't load this product. Please try again.",
        actionLabel: 'Retry',
        onAction: onRetry,
      ),
    );
  }
}

final class _EditProductForm extends ConsumerStatefulWidget {
  const _EditProductForm({required this.product});

  final Product product;

  @override
  ConsumerState<_EditProductForm> createState() => _EditProductFormState();
}

final class _EditProductFormState extends ConsumerState<_EditProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _unitController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _thresholdController;
  late final TextEditingController _barcodeController;

  final _nameFocus = FocusNode();
  final _categoryFocus = FocusNode();
  final _unitFocus = FocusNode();
  final _sellingPriceFocus = FocusNode();
  final _thresholdFocus = FocusNode();
  final _barcodeFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product.name);
    _categoryController = TextEditingController(text: product.category ?? '');
    _unitController = TextEditingController(text: product.unit);
    _sellingPriceController = TextEditingController(
      text: product.sellingPrice.toString(),
    );
    _thresholdController = TextEditingController(
      text: product.lowStockThreshold.toString(),
    );
    _barcodeController = TextEditingController(text: product.barcode ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    _sellingPriceController.dispose();
    _thresholdController.dispose();
    _barcodeController.dispose();
    _nameFocus.dispose();
    _categoryFocus.dispose();
    _unitFocus.dispose();
    _sellingPriceFocus.dispose();
    _thresholdFocus.dispose();
    _barcodeFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = editProductControllerProvider(widget.product.id);
    final state = ref.watch(provider);
    final spacing = AppSpacing.of(context);
    final busy = state.isSaving || state.isArchiving;
    final interactionsDisabled = busy || state.isUnavailable;
    final fieldsEnabled = !interactionsDisabled;

    return PopScope(
      canPop: !busy,
      child: Scaffold(
        key: const Key('edit-product-screen'),
        appBar: AppBar(title: const Text('Edit Product')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.message case final message?)
                    _FormMessage(message: message),
                  _field(
                    key: const Key('edit-product-name-field'),
                    controller: _nameController,
                    focusNode: _nameFocus,
                    label: 'Product name',
                    enabled: fieldsEnabled,
                    error: state.errorFor(ProductField.name),
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _categoryFocus.requestFocus(),
                  ),
                  SizedBox(height: spacing.md),
                  _field(
                    key: const Key('edit-category-field'),
                    controller: _categoryController,
                    focusNode: _categoryFocus,
                    label: 'Category (optional)',
                    enabled: fieldsEnabled,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _unitFocus.requestFocus(),
                  ),
                  SizedBox(height: spacing.md),
                  _field(
                    key: const Key('edit-unit-field'),
                    controller: _unitController,
                    focusNode: _unitFocus,
                    label: 'Unit',
                    enabled: fieldsEnabled,
                    error: state.errorFor(ProductField.unit),
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _sellingPriceFocus.requestFocus(),
                  ),
                  SizedBox(height: spacing.md),
                  _field(
                    key: const Key('edit-selling-price-field'),
                    controller: _sellingPriceController,
                    focusNode: _sellingPriceFocus,
                    label: 'Selling price (PHP, optional)',
                    enabled: fieldsEnabled,
                    error: state.errorFor(ProductField.sellingPrice),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _thresholdFocus.requestFocus(),
                  ),
                  SizedBox(height: spacing.md),
                  _field(
                    key: const Key('edit-low-stock-threshold-field'),
                    controller: _thresholdController,
                    focusNode: _thresholdFocus,
                    label: 'Low-stock threshold',
                    enabled: fieldsEnabled,
                    error: state.errorFor(ProductField.lowStockThreshold),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _barcodeFocus.requestFocus(),
                  ),
                  SizedBox(height: spacing.md),
                  _field(
                    key: const Key('edit-barcode-field'),
                    controller: _barcodeController,
                    focusNode: _barcodeFocus,
                    label: 'Barcode (optional)',
                    enabled: fieldsEnabled,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                  SizedBox(height: spacing.md),
                  Semantics(
                    container: true,
                    excludeSemantics: true,
                    label:
                        'Current quantity ${widget.product.quantity} '
                        '${widget.product.unit}. Read only.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current quantity: ${widget.product.quantity} '
                          '${widget.product.unit}',
                          key: const Key('edit-current-quantity'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Text(
                          'Use Stock In or Stock Out to change quantity.',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: spacing.lg),
                  FilledButton(
                    key: const Key('save-product-changes-button'),
                    onPressed: interactionsDisabled ? null : _submit,
                    child: state.isSaving
                        ? const _SavingLabel()
                        : const Text('Save Changes'),
                  ),
                  SizedBox(height: spacing.md),
                  OutlinedButton.icon(
                    key: const Key('archive-product-button'),
                    onPressed: interactionsDisabled ? null : _confirmArchive,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.archive_outlined),
                    label: state.isArchiving
                        ? const _ArchivingLabel()
                        : const Text('Archive'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextFormField _field({
    required Key key,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required bool enabled,
    String? error,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      decoration: InputDecoration(labelText: label, errorText: error),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final saved = await ref
        .read(editProductControllerProvider(widget.product.id).notifier)
        .submit(
          ProductDetailsFormValues(
            name: _nameController.text,
            category: _categoryController.text,
            unit: _unitController.text,
            sellingPrice: _sellingPriceController.text,
            lowStockThreshold: _thresholdController.text,
            barcode: _barcodeController.text,
          ),
        );
    if (!mounted) return;

    if (saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated.')),
      );
      context.goNamed(AppRoute.products.name);
      return;
    }
    await _focusFirstInvalid();
  }

  Future<void> _confirmArchive() async {
    FocusScope.of(context).unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        semanticLabel: 'Archive product confirmation',
        scrollable: true,
        title: const Text('Archive product?'),
        content: Text(
          'Archive ${widget.product.name}?\n\n'
          'This product will be hidden from your active list. '
          'Its inventory history will still be available.',
        ),
        actions: [
          TextButton(
            key: const Key('cancel-archive-button'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('confirm-archive-button'),
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final archived = await ref
        .read(editProductControllerProvider(widget.product.id).notifier)
        .archive();
    if (!mounted || !archived) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product archived.')),
    );
    context.goNamed(AppRoute.products.name);
  }

  Future<void> _focusFirstInvalid() async {
    final state = ref.read(
      editProductControllerProvider(widget.product.id),
    );
    final focus = switch (state.firstInvalidField) {
      ProductField.name => _nameFocus,
      ProductField.unit => _unitFocus,
      ProductField.sellingPrice => _sellingPriceFocus,
      ProductField.lowStockThreshold => _thresholdFocus,
      ProductField.quantity || null => null,
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
      label: 'Saving product',
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

final class _ArchivingLabel extends StatelessWidget {
  const _ArchivingLabel();

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    return Semantics(
      label: 'Archiving product',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: spacing.sm),
          const Text('Archiving...'),
        ],
      ),
    );
  }
}
