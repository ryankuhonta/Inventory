import 'package:flutter/material.dart';

/// Presentation-only actions for one active product row.
class ProductRowActions extends StatelessWidget {
  /// Creates the actions for an active product row.
  const ProductRowActions({
    required this.productId,
    required this.productName,
    required this.onStockIn,
    required this.onStockOut,
    required this.onEdit,
    super.key,
  });

  /// Stable identity used to key this product's row actions.
  final String productId;

  /// Visible product name used in accessible action copy.
  final String productName;

  /// Opens Stock In, or disables the mounted action while navigation is
  /// guarded.
  final VoidCallback? onStockIn;

  /// Opens Stock Out, or disables the mounted action while navigation is
  /// guarded.
  final VoidCallback? onStockOut;

  /// Opens Edit Product, or disables the mounted action while navigation is
  /// guarded.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          key: ValueKey('product-stock-in-action-$productId'),
          label: 'Stock In $productName',
          icon: Icons.add_box_outlined,
          onPressed: onStockIn,
        ),
        _ActionButton(
          key: ValueKey('product-stock-out-action-$productId'),
          label: 'Stock Out $productName',
          icon: Icons.indeterminate_check_box_outlined,
          onPressed: onStockOut,
        ),
        _ActionButton(
          key: ValueKey('product-edit-action-$productId'),
          label: 'Edit $productName',
          icon: Icons.edit_outlined,
          onPressed: onEdit,
        ),
      ],
    );
  }
}

final class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      enabled: onPressed != null,
      onTap: onPressed,
      excludeSemantics: true,
      child: IconButton(
        tooltip: label,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}
