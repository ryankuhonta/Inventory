import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tindatrack/features/products/domain/entities/product_list_query.dart';

/// Owns the applied product-list query and text debounce lifecycle.
final class ProductListController extends Notifier<ProductListQuery> {
  static const _searchDebounce = Duration(milliseconds: 300);

  Timer? _pendingSearch;

  @override
  ProductListQuery build() {
    ref.onDispose(_cancelPendingSearch);
    return const ProductListQuery.defaultQuery();
  }

  /// Applies nonblank [text] after 300 ms, replacing pending text.
  void searchTextChanged(String text) {
    _cancelPendingSearch();
    final normalized = text.trim();
    if (normalized.isEmpty) {
      _setQuery(state.copyWith(searchText: ''));
      return;
    }

    _pendingSearch = Timer(_searchDebounce, () {
      if (!ref.mounted) return;
      _setQuery(
        ProductListQuery(
          searchText: normalized,
          stockFilter: state.stockFilter,
        ),
      );
    });
  }

  /// Applies [filter] immediately without cancelling pending text.
  void stockFilterChanged(ProductStockFilter filter) {
    _setQuery(state.copyWith(stockFilter: filter));
  }

  /// Clears applied and pending search while preserving the stock filter.
  void clearSearch() {
    _cancelPendingSearch();
    _setQuery(state.copyWith(searchText: ''));
  }

  /// Restores empty search and All immediately.
  void reset() {
    _cancelPendingSearch();
    _setQuery(const ProductListQuery.defaultQuery());
  }

  void _cancelPendingSearch() {
    _pendingSearch?.cancel();
    _pendingSearch = null;
  }

  void _setQuery(ProductListQuery query) {
    if (query != state) state = query;
  }
}

/// App-session product-list query state.
final productListControllerProvider =
    NotifierProvider<ProductListController, ProductListQuery>(
      ProductListController.new,
    );
