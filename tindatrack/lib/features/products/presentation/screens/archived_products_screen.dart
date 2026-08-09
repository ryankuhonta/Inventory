import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tindatrack/app/router/app_routes.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/core/formatters/currency_formatter.dart';
import 'package:tindatrack/core/ui/app_spacing.dart';
import 'package:tindatrack/core/widgets/app_empty_state.dart';
import 'package:tindatrack/core/widgets/app_error_view.dart';
import 'package:tindatrack/core/widgets/app_loading_view.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';

/// Lists archived products and lets users restore them to active catalog.
class ArchivedProductsScreen extends ConsumerStatefulWidget {
  /// Creates the archived products screen.
  const ArchivedProductsScreen({super.key});

  @override
  ConsumerState<ArchivedProductsScreen> createState() =>
      _ArchivedProductsScreenState();
}

final class _ArchivedProductsScreenState
    extends ConsumerState<ArchivedProductsScreen> {
  String? _restoringProductId;

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(archivedProductsProvider);

    return Scaffold(
      key: const Key('archived-products-screen'),
      appBar: AppBar(title: const Text('Archived Products')),
      body: SafeArea(
        child: switch (products) {
          AsyncData<List<Product>>(:final value) when value.isEmpty =>
            AppEmptyState(
              key: const Key('archived-products-empty-state'),
              title: 'No archived products',
              message:
                  'Archived products will appear here after you archive them.',
              icon: Icons.archive_outlined,
              actionLabel: 'Back to Products',
              onAction: () => context.goNamed(AppRoute.products.name),
            ),
          AsyncData<List<Product>>(:final value) => _ArchivedProductList(
            products: value,
            restoringProductId: _restoringProductId,
            onRestore: (product) => unawaited(_confirmRestore(product)),
          ),
          AsyncError<List<Product>>() => AppErrorView(
            key: const Key('archived-products-error-state'),
            title: 'Archived products unavailable',
            message: "We couldn't load archived products. Please try again.",
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(archivedProductsProvider),
          ),
          _ => const AppLoadingView(
            key: Key('archived-products-loading-state'),
            title: 'Archived Products',
            semanticsLabel: 'Loading archived products',
          ),
        },
      ),
    );
  }

  Future<void> _confirmRestore(Product product) async {
    if (_restoringProductId != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore product?'),
        content: Text(
          'Restore ${product.name} to your active Products list? Its stock '
          'quantity and history will stay the same.',
        ),
        actions: [
          TextButton(
            key: const Key('cancel-restore-product-button'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-restore-product-button'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _restore(product.id);
  }

  Future<void> _restore(String productId) async {
    setState(() {
      _restoringProductId = productId;
    });

    final result = await ref.read(restoreProductProvider)(productId);
    if (!mounted) return;

    setState(() {
      _restoringProductId = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Success<void>():
        ref
          ..invalidate(activeProductsProvider)
          ..invalidate(archivedProductsProvider);
        messenger.showSnackBar(
          const SnackBar(content: Text('Product restored.')),
        );
      case FailureResult<void>():
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              "We couldn't restore this product. Please try again.",
            ),
          ),
        );
    }
  }
}

final class _ArchivedProductList extends StatelessWidget {
  const _ArchivedProductList({
    required this.products,
    required this.restoringProductId,
    required this.onRestore,
  });

  final List<Product> products;
  final String? restoringProductId;
  final ValueChanged<Product> onRestore;

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);

    return ListView.separated(
      key: const Key('archived-products-list'),
      padding: EdgeInsets.fromLTRB(
        spacing.md,
        spacing.sm,
        spacing.md,
        spacing.xl,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final isRestoring = restoringProductId == product.id;
        return _ArchivedProductListItem(
          key: ValueKey('archived-product-row-${product.id}'),
          product: product,
          isRestoring: isRestoring,
          restoreDisabled: restoringProductId != null,
          onRestore: () => onRestore(product),
        );
      },
      separatorBuilder: (_, _) => const Divider(height: 1),
    );
  }
}

final class _ArchivedProductListItem extends StatelessWidget {
  const _ArchivedProductListItem({
    required this.product,
    required this.isRestoring,
    required this.restoreDisabled,
    required this.onRestore,
    super.key,
  });

  final Product product;
  final bool isRestoring;
  final bool restoreDisabled;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    const currencyFormatter = CurrencyFormatter.php();
    final quantity = '${product.quantity} ${product.unit}';
    final price = 'Price: ${currencyFormatter.format(product.sellingPrice)}';
    final metadata = product.category ?? product.unit;

    return ListTile(
      title: Text(
        product.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metadata, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(
            quantity,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(price, maxLines: 1, overflow: TextOverflow.ellipsis),
          const Text('Archived'),
        ],
      ),
      trailing: OutlinedButton.icon(
        key: ValueKey('restore-product-action-${product.id}'),
        onPressed: restoreDisabled ? null : onRestore,
        icon: isRestoring
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.unarchive_outlined),
        label: Text(isRestoring ? 'Restoring...' : 'Restore'),
      ),
    );
  }
}
