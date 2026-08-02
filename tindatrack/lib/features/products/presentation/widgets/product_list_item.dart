import 'package:flutter/material.dart';
import 'package:tindatrack/core/formatters/currency_formatter.dart';
import 'package:tindatrack/core/ui/app_spacing.dart';
import 'package:tindatrack/features/products/domain/entities/product.dart';
import 'package:tindatrack/features/products/domain/entities/product_stock_status.dart';
import 'package:tindatrack/features/products/presentation/widgets/product_row_actions.dart';
import 'package:tindatrack/features/products/presentation/widgets/stock_badge.dart';

/// Read-only presentation for one active product.
class ProductListItem extends StatelessWidget {
  /// Creates a product row from a domain value.
  const ProductListItem({
    required this.product,
    this.onStockIn,
    this.onStockOut,
    this.onEdit,
    super.key,
  });

  /// Product displayed by this row.
  final Product product;

  /// Opens Stock In when supplied by the active list.
  final VoidCallback? onStockIn;

  /// Opens Stock Out when supplied by the active list.
  final VoidCallback? onStockOut;

  /// Opens Edit Product when supplied by the active list.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    const currencyFormatter = CurrencyFormatter.php();
    final quantity = '${product.quantity} ${product.unit}';
    final price = 'Price: ${currencyFormatter.format(product.sellingPrice)}';
    final metadata = product.category ?? product.unit;
    final status = product.stockStatus;
    final statusLabel = status.label;
    final semanticsLabel = [
      product.name,
      if (product.category != null) metadata,
      quantity,
      price,
      ?statusLabel,
    ].join(', ');

    return Row(
      children: [
        Expanded(
          child: Semantics(
            excludeSemantics: true,
            label: semanticsLabel,
            button: onEdit != null,
            onTap: onEdit,
            child: ListTile(
              onTap: onEdit,
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
                  Text(
                    price,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (status != ProductStockStatus.inStock)
                    Padding(
                      padding: EdgeInsets.only(top: spacing.xs),
                      child: StockBadge(status: status),
                    ),
                ],
              ),
            ),
          ),
        ),
        ProductRowActions(
          productId: product.id,
          productName: product.name,
          onStockIn: onStockIn,
          onStockOut: onStockOut,
          onEdit: onEdit,
        ),
      ],
    );
  }
}
