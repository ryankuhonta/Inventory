import 'package:flutter/material.dart';
import 'package:tindatrack/app/theme/app_colors.dart';
import 'package:tindatrack/core/ui/app_dimensions.dart';
import 'package:tindatrack/core/ui/app_spacing.dart';
import 'package:tindatrack/features/products/domain/entities/product_stock_status.dart';

/// Presentation copy shared by visible badges and merged row semantics.
extension ProductStockStatusPresentation on ProductStockStatus {
  /// User-facing label, or null when normal stock needs no warning.
  String? get label => switch (this) {
    ProductStockStatus.inStock => null,
    ProductStockStatus.lowStock => 'Low Stock',
    ProductStockStatus.outOfStock => 'Out of Stock',
  };
}

/// Compact, non-interactive warning for a derived product stock state.
class StockBadge extends StatelessWidget {
  /// Creates a badge for [status], or no visual for normal stock.
  const StockBadge({required this.status, super.key});

  /// Current derived product status.
  final ProductStockStatus status;

  @override
  Widget build(BuildContext context) {
    final label = status.label;
    final presentation = switch (status) {
      ProductStockStatus.inStock => null,
      ProductStockStatus.lowStock => const (
        foreground: AppColors.warning,
        background: AppColors.warningSurface,
      ),
      ProductStockStatus.outOfStock => const (
        foreground: AppColors.danger,
        background: AppColors.dangerSurface,
      ),
    };
    if (presentation == null || label == null) return const SizedBox.shrink();

    final spacing = AppSpacing.of(context);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        key: const Key('stock-status-badge'),
        decoration: BoxDecoration(
          color: presentation.background,
          borderRadius: BorderRadius.circular(AppDimensions.statusPillRadius),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.sm,
            vertical: spacing.xs,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: presentation.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
