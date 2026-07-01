import 'package:flutter/material.dart';
import 'package:tindatrack/core/ui/app_spacing.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/entities/product_stock_status.dart';
import 'package:tindatrack/features/products/presentation/widgets/stock_badge.dart';

/// Read-only presentation for one active product.
class ProductListItem extends StatelessWidget {
  /// Creates a product row from a domain value.
  const ProductListItem({required this.product, super.key});

  /// Product displayed by this row.
  final Product product;

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    final quantity = '${product.quantity} ${product.unit}';
    final metadata = product.category ?? product.unit;
    final status = product.stockStatus;
    final statusLabel = switch (status) {
      ProductStockStatus.inStock => null,
      ProductStockStatus.lowStock => 'Low Stock',
      ProductStockStatus.outOfStock => 'Out of Stock',
    };
    final semanticsLabel = [
      product.name,
      if (product.category != null) metadata,
      quantity,
      ?statusLabel,
    ].join(', ');

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: semanticsLabel,
      child: ListTile(
        title: Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metadata,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              quantity,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (status != ProductStockStatus.inStock)
              Padding(
                padding: EdgeInsets.only(top: spacing.xs),
                child: StockBadge(status: status),
              ),
          ],
        ),
      ),
    );
  }
}
