import 'package:flutter/material.dart';
import 'package:tindatrack/app/theme/app_colors.dart';
import 'package:tindatrack/core/ui/app_dimensions.dart';
import 'package:tindatrack/core/ui/app_spacing.dart';
import 'package:tindatrack/features/products/domain/entities/product_stock_status.dart';

/// Compact, non-interactive warning for a derived product stock state.
class StockBadge extends StatelessWidget {
  /// Creates a badge for [status], or no visual for normal stock.
  const StockBadge({required this.status, super.key});

  /// Current derived product status.
  final ProductStockStatus status;

  @override
  Widget build(BuildContext context) {
    final presentation = switch (status) {
      ProductStockStatus.inStock => null,
      ProductStockStatus.lowStock => const (
        label: 'Low Stock',
        foreground: AppColors.warning,
        background: AppColors.warningSurface,
      ),
      ProductStockStatus.outOfStock => const (
        label: 'Out of Stock',
        foreground: AppColors.danger,
        background: AppColors.dangerSurface,
      ),
    };
    if (presentation == null) return const SizedBox.shrink();

    final spacing = AppSpacing.of(context);
    return Semantics(
      label: presentation.label,
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
            presentation.label,
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
