import 'package:flutter/material.dart';

/// Presentation-only actions for one active product row.
///
/// Epic 2 intentionally exposes Edit only. Future stock actions can extend this
/// boundary when their real flows are implemented.
class ProductRowActions extends StatelessWidget {
  /// Creates the actions for an active product row.
  const ProductRowActions({
    required this.productId,
    required this.productName,
    required this.onEdit,
    super.key,
  });

  /// Stable identity used to key this product's Edit action.
  final String productId;

  /// Visible product name used in accessible Edit copy.
  final String productName;

  /// Opens Edit Product, or disables the mounted action while navigation is
  /// guarded.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final editLabel = 'Edit $productName';

    return Semantics(
      label: editLabel,
      button: true,
      enabled: onEdit != null,
      onTap: onEdit,
      excludeSemantics: true,
      child: IconButton(
        key: ValueKey('product-edit-action-$productId'),
        tooltip: editLabel,
        onPressed: onEdit,
        icon: const Icon(Icons.edit_outlined),
      ),
    );
  }
}
