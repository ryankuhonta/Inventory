import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tindatrack/app/router/app_routes.dart';
import 'package:tindatrack/core/ui/app_spacing.dart';
import 'package:tindatrack/features/products/domain/failures/product_failure.dart';
import 'package:tindatrack/features/products/presentation/controllers/product_form_controller.dart';

/// Form screen for creating one locally persisted product.
final class AddProductScreen extends ConsumerStatefulWidget {
  /// Creates the Add Product screen.
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

final class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _unitController = TextEditingController(text: 'pcs');
  final _sellingPriceController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  final _thresholdController = TextEditingController(text: '0');
  final _barcodeController = TextEditingController();

  final _nameFocus = FocusNode();
  final _categoryFocus = FocusNode();
  final _unitFocus = FocusNode();
  final _sellingPriceFocus = FocusNode();
  final _quantityFocus = FocusNode();
  final _thresholdFocus = FocusNode();
  final _barcodeFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    _sellingPriceController.dispose();
    _quantityController.dispose();
    _thresholdController.dispose();
    _barcodeController.dispose();
    _nameFocus.dispose();
    _categoryFocus.dispose();
    _unitFocus.dispose();
    _sellingPriceFocus.dispose();
    _quantityFocus.dispose();
    _thresholdFocus.dispose();
    _barcodeFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productFormControllerProvider);
    final spacing = AppSpacing.of(context);
    final fieldsEnabled = !state.isSaving;

    return PopScope(
      canPop: !state.isSaving,
      child: Scaffold(
        key: const Key('add-product-screen'),
        appBar: AppBar(title: const Text('Add Product')),
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
                    key: const Key('product-name-field'),
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
                    key: const Key('category-field'),
                    controller: _categoryController,
                    focusNode: _categoryFocus,
                    label: 'Category (optional)',
                    enabled: fieldsEnabled,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _unitFocus.requestFocus(),
                  ),
                  SizedBox(height: spacing.md),
                  _field(
                    key: const Key('unit-field'),
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
                    key: const Key('selling-price-field'),
                    controller: _sellingPriceController,
                    focusNode: _sellingPriceFocus,
                    label: 'Selling price (PHP, optional)',
                    enabled: fieldsEnabled,
                    error: state.errorFor(ProductField.sellingPrice),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _quantityFocus.requestFocus(),
                  ),
                  SizedBox(height: spacing.md),
                  _field(
                    key: const Key('starting-quantity-field'),
                    controller: _quantityController,
                    focusNode: _quantityFocus,
                    label: 'Starting quantity',
                    enabled: fieldsEnabled,
                    error: state.errorFor(ProductField.quantity),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _thresholdFocus.requestFocus(),
                  ),
                  SizedBox(height: spacing.md),
                  _field(
                    key: const Key('low-stock-threshold-field'),
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
                    key: const Key('barcode-field'),
                    controller: _barcodeController,
                    focusNode: _barcodeFocus,
                    label: 'Barcode (optional)',
                    enabled: fieldsEnabled,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                  SizedBox(height: spacing.lg),
                  FilledButton(
                    key: const Key('save-product-button'),
                    onPressed: state.isSaving ? null : _submit,
                    child: state.isSaving
                        ? const _SavingLabel()
                        : const Text('Save Product'),
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
        .read(productFormControllerProvider.notifier)
        .submit(
          ProductFormValues(
            name: _nameController.text,
            category: _categoryController.text,
            unit: _unitController.text,
            sellingPrice: _sellingPriceController.text,
            quantity: _quantityController.text,
            lowStockThreshold: _thresholdController.text,
            barcode: _barcodeController.text,
          ),
        );
    if (!mounted) return;

    if (saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product saved.')),
      );
      context.goNamed(AppRoute.products.name);
      return;
    }
    await _focusFirstInvalid();
  }

  Future<void> _focusFirstInvalid() async {
    final field = ref.read(productFormControllerProvider).firstInvalidField;
    final focus = switch (field) {
      ProductField.name => _nameFocus,
      ProductField.unit => _unitFocus,
      ProductField.sellingPrice => _sellingPriceFocus,
      ProductField.quantity => _quantityFocus,
      ProductField.lowStockThreshold => _thresholdFocus,
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
