import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tindatrack/app/router/app_routes.dart';
import 'package:tindatrack/core/ui/app_spacing.dart';
import 'package:tindatrack/core/widgets/app_empty_state.dart';
import 'package:tindatrack/core/widgets/app_error_view.dart';
import 'package:tindatrack/core/widgets/app_loading_view.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/entities/product_list_query.dart';
import 'package:tindatrack/features/products/presentation/controllers/product_list_controller.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';
import 'package:tindatrack/features/products/presentation/widgets/product_list_item.dart';

const _maxProductSearchLength = 1000;

/// Reactive root for the active Products catalog.
class ProductListScreen extends ConsumerStatefulWidget {
  /// Creates the Products screen.
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

final class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  bool _openingAddProduct = false;

  @override
  void initState() {
    super.initState();
    final query = ref.read(productListControllerProvider);
    _searchController = TextEditingController(text: query.searchText);
    _searchFocusNode = FocusNode();
    ref.listenManual<ProductListQuery>(
      productListControllerProvider,
      _synchronizeVisibleSearch,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(activeProductsProvider);
    final query = ref.watch(productListControllerProvider);
    final spacing = AppSpacing.of(context);

    return Scaffold(
      key: const Key('products-screen'),
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add-product-action'),
        onPressed: () => unawaited(_openAddProduct(context)),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                spacing.md,
                spacing.sm,
                spacing.md,
                spacing.xs,
              ),
              child: TextField(
                key: const Key('product-search-field'),
                controller: _searchController,
                focusNode: _searchFocusNode,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(_maxProductSearchLength),
                ],
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Search products',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          key: const Key('clear-product-search'),
                          tooltip: 'Clear product search',
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.clear),
                        ),
                ),
                onChanged: (value) {
                  setState(() {});
                  ref
                      .read(productListControllerProvider.notifier)
                      .searchTextChanged(value);
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                spacing.md,
                spacing.xs,
                spacing.md,
                spacing.sm,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: spacing.sm,
                  runSpacing: spacing.xs,
                  children: [
                    _filterChip(
                      label: 'All',
                      filter: ProductStockFilter.all,
                      selectedFilter: query.stockFilter,
                    ),
                    _filterChip(
                      label: 'Low Stock',
                      filter: ProductStockFilter.lowStock,
                      selectedFilter: query.stockFilter,
                    ),
                    _filterChip(
                      label: 'Out of Stock',
                      filter: ProductStockFilter.outOfStock,
                      selectedFilter: query.stockFilter,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: _buildResults(products, query)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(
    AsyncValue<List<Product>> products,
    ProductListQuery query,
  ) {
    return switch (products) {
      AsyncData<List<Product>>(:final value)
          when value.isEmpty && query.isDefault =>
        AppEmptyState(
          key: const Key('products-empty-state'),
          title: 'No products yet',
          message: 'Add your first product to start tracking stock.',
          icon: Icons.inventory_2_outlined,
          actionLabel: 'Add Product',
          onAction: () => unawaited(_openAddProduct(context)),
        ),
      AsyncData<List<Product>>(:final value) when value.isEmpty =>
        AppEmptyState(
          key: const Key('products-no-match-state'),
          title: 'No matching products',
          message: 'Try another search or reset the filters.',
          icon: Icons.search_off,
          actionLabel: 'Reset',
          onAction: _resetQuery,
        ),
      AsyncData<List<Product>>(:final value) => _ProductList(products: value),
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
    };
  }

  ChoiceChip _filterChip({
    required String label,
    required ProductStockFilter filter,
    required ProductStockFilter selectedFilter,
  }) {
    return ChoiceChip(
      key: ValueKey('product-filter-${filter.name}'),
      label: Text(label),
      selected: selectedFilter == filter,
      showCheckmark: true,
      onSelected: (selected) {
        if (!selected) return;
        ref
            .read(productListControllerProvider.notifier)
            .stockFilterChanged(filter);
      },
    );
  }

  void _synchronizeVisibleSearch(
    ProductListQuery? previous,
    ProductListQuery next,
  ) {
    if (previous?.searchText == next.searchText) return;

    final visibleQuery = ProductListQuery(
      searchText: _searchController.text,
    );
    if (visibleQuery.searchText == next.searchText) return;

    final text = next.searchText;
    setState(() {
      _searchController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
    ref.read(productListControllerProvider.notifier).clearSearch();
  }

  void _resetQuery() {
    _searchController.clear();
    setState(() {});
    ref.read(productListControllerProvider.notifier).reset();
  }

  Future<void> _openAddProduct(BuildContext context) async {
    if (_openingAddProduct) return;

    setState(() {
      _openingAddProduct = true;
    });

    try {
      await context.pushNamed(ProductRoute.addProduct.name);
    } finally {
      if (mounted) {
        setState(() {
          _openingAddProduct = false;
        });
      }
    }
  }
}

final class _ProductList extends StatefulWidget {
  const _ProductList({required this.products});

  final List<Product> products;

  @override
  State<_ProductList> createState() => _ProductListState();
}

final class _ProductListState extends State<_ProductList> {
  String? _openingProductRouteName;

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
      itemCount: widget.products.length,
      itemBuilder: (context, index) {
        final product = widget.products[index];
        return ProductListItem(
          key: ValueKey('product-row-${product.id}'),
          product: product,
          onStockIn: () => unawaited(
            _openProductRoute(context, ProductRoute.stockIn, product.id),
          ),
          onStockOut: () => unawaited(
            _openProductRoute(context, ProductRoute.stockOut, product.id),
          ),
          onEdit: () => unawaited(
            _openProductRoute(context, ProductRoute.editProduct, product.id),
          ),
        );
      },
      separatorBuilder: (_, _) => const Divider(height: 1),
    );
  }

  Future<void> _openProductRoute(
    BuildContext context,
    ProductRoute route,
    String productId,
  ) async {
    final routeName = route.name;
    if (_openingProductRouteName == routeName) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _openingProductRouteName = routeName;
    });

    try {
      await context.pushNamed(
        route.name,
        pathParameters: <String, String>{'productId': productId},
      );
    } finally {
      if (mounted && _openingProductRouteName == routeName) {
        setState(() {
          _openingProductRouteName = null;
        });
      }
    }
  }
}
