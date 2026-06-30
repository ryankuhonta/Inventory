import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tindatrack/app/router/app_routes.dart';
import 'package:tindatrack/core/ui/app_spacing.dart';
import 'package:tindatrack/core/widgets/app_empty_state.dart';
import 'package:tindatrack/core/widgets/app_error_view.dart';
import 'package:tindatrack/core/widgets/app_loading_view.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';
import 'package:tindatrack/features/products/presentation/widgets/product_list_item.dart';

/// Reactive root for the active Products catalog.
class ProductListScreen extends ConsumerWidget {
  /// Creates the Products screen.
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(activeProductsProvider);

    return Scaffold(
      key: const Key('products-screen'),
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-product-action'),
        onPressed: () => _openAddProduct(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: SafeArea(
        child: switch (products) {
          AsyncData<List<Product>>(:final value) when value.isEmpty =>
            AppEmptyState(
              key: const Key('products-empty-state'),
              title: 'No products yet',
              message: 'Add your first product to start tracking stock.',
              icon: Icons.inventory_2_outlined,
              actionLabel: 'Add Product',
              onAction: () => _openAddProduct(context),
            ),
          AsyncData<List<Product>>(:final value) => _ProductList(
            products: value,
          ),
          AsyncError<List<Product>>() => AppErrorView(
            key: const Key('products-error-state'),
            title: 'Products unavailable',
            message: "We couldn't load your products. Please try again.",
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(activeProductsProvider),
          ),
          _ => const AppLoadingView(
            key: Key('products-loading-state'),
            title: 'Products',
            semanticsLabel: 'Loading products',
          ),
        },
      ),
    );
  }

  void _openAddProduct(BuildContext context) {
    unawaited(context.pushNamed(ProductRoute.addProduct.name));
  }
}

final class _ProductList extends StatelessWidget {
  const _ProductList({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);

    return ListView.separated(
      key: const Key('products-list'),
      padding: EdgeInsets.fromLTRB(
        spacing.md,
        spacing.sm,
        spacing.md,
        spacing.xl * 3,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductListItem(
          key: ValueKey('product-row-${product.id}'),
          product: product,
        );
      },
      separatorBuilder: (_, _) => const Divider(height: 1),
    );
  }
}
