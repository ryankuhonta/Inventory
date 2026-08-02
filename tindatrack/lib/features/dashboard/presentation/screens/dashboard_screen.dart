import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tindatrack/app/router/app_routes.dart';
import 'package:tindatrack/app/theme/app_colors.dart';
import 'package:tindatrack/core/ui/app_dimensions.dart';
import 'package:tindatrack/core/ui/app_spacing.dart';
import 'package:tindatrack/core/widgets/app_empty_state.dart';
import 'package:tindatrack/core/widgets/app_error_view.dart';
import 'package:tindatrack/core/widgets/app_loading_view.dart';
import 'package:tindatrack/features/dashboard/domain/entities/dashboard_low_stock_preview_item.dart';
import 'package:tindatrack/features/dashboard/domain/entities/dashboard_recent_activity_item.dart';
import 'package:tindatrack/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:tindatrack/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:tindatrack/features/products/domain/entities/product_list_query.dart';
import 'package:tindatrack/features/products/presentation/controllers/product_list_controller.dart';
import 'package:tindatrack/features/products/presentation/widgets/stock_badge.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';

/// Inventory snapshot shown on the Dashboard branch.
class DashboardScreen extends ConsumerWidget {
  /// Creates the Dashboard screen.
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final recentActivity = ref.watch(dashboardRecentActivityPreviewProvider);

    return Scaffold(
      key: const Key('dashboard-screen'),
      body: SafeArea(
        child: summary.when(
          data: (value) =>
              _shouldShowFirstProductEmptyState(
                value,
                recentActivity,
              )
              ? const _DashboardEmptyState()
              : _DashboardContent(
                  summary: value,
                  recentActivity: recentActivity,
                ),
          error: (_, _) => AppErrorView(
            key: const Key('dashboard-error-state'),
            title: 'Dashboard unavailable',
            message: "We couldn't load your dashboard. Please try again.",
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(dashboardSummaryProvider),
          ),
          loading: () => const AppLoadingView(
            key: Key('dashboard-loading-state'),
            title: 'Inventory Today',
            semanticsLabel: 'Loading dashboard summary',
          ),
        ),
      ),
    );
  }
}

bool _isEmptySummary(DashboardSummary summary) {
  return summary.totalActiveProducts == 0 &&
      summary.lowStockProducts == 0 &&
      summary.stockChangesToday == 0;
}

bool _shouldShowFirstProductEmptyState(
  DashboardSummary summary,
  AsyncValue<List<DashboardRecentActivityItem>> recentActivity,
) {
  if (!_isEmptySummary(summary)) return false;

  return recentActivity.maybeWhen(
    data: (items) => items.isEmpty,
    orElse: () => false,
  );
}

final class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({
    required this.summary,
    required this.recentActivity,
  });

  final DashboardSummary summary;
  final AsyncValue<List<DashboardRecentActivityItem>> recentActivity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStockPreview = ref.watch(dashboardLowStockPreviewProvider);
    final spacing = AppSpacing.of(context);
    final theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.all(spacing.md),
      children: [
        Text(
          'Inventory Today',
          style: theme.textTheme.headlineMedium,
        ),
        SizedBox(height: spacing.md),
        _SummaryCard(
          key: const Key('dashboard-summary-total-products'),
          label: 'Total Products',
          value: summary.totalActiveProducts,
          icon: Icons.inventory_2_outlined,
        ),
        SizedBox(height: spacing.sm),
        _SummaryCard(
          key: const Key('dashboard-summary-low-stock'),
          label: 'Low Stock',
          value: summary.lowStockProducts,
          icon: summary.lowStockProducts > 0
              ? Icons.warning_amber_outlined
              : Icons.check_circle_outline,
          isWarning: summary.lowStockProducts > 0,
        ),
        SizedBox(height: spacing.sm),
        _SummaryCard(
          key: const Key('dashboard-summary-stock-changes-today'),
          label: 'Stock Changes Today',
          value: summary.stockChangesToday,
          icon: Icons.swap_vert,
        ),
        SizedBox(height: spacing.lg),
        _LowStockPreviewSection(
          preview: lowStockPreview,
          onRetry: () => ref.invalidate(dashboardLowStockPreviewProvider),
          onViewLowStock: () => _openLowStockProducts(context, ref),
        ),
        SizedBox(height: spacing.lg),
        _RecentActivitySection(
          preview: recentActivity,
          onRetry: () => ref.invalidate(dashboardRecentActivityPreviewProvider),
          onViewHistory: () => context.go(AppRoute.history.path),
        ),
      ],
    );
  }
}

final class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    this.isWarning = false,
    super.key,
  });

  final String label;
  final int value;
  final IconData icon;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = isWarning ? AppColors.warning : colorScheme.primary;
    final background = isWarning
        ? AppColors.warningSurface
        : colorScheme.surface;

    return Card(
      color: background,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 96),
        child: Padding(
          padding: EdgeInsets.all(spacing.md),
          child: Row(
            children: [
              Container(
                width: AppDimensions.minimumTapTarget,
                height: AppDimensions.minimumTapTarget,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.componentRadius,
                  ),
                ),
                child: Icon(icon, color: accent),
              ),
              SizedBox(width: spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: spacing.xs),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (isWarning) ...[
                      SizedBox(height: spacing.xs),
                      Text(
                        'Needs attention',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _LowStockPreviewSection extends StatelessWidget {
  const _LowStockPreviewSection({
    required this.preview,
    required this.onRetry,
    required this.onViewLowStock,
  });

  final AsyncValue<List<DashboardLowStockPreviewItem>> preview;
  final VoidCallback onRetry;
  final VoidCallback onViewLowStock;

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    final theme = Theme.of(context);

    return KeyedSubtree(
      key: const Key('dashboard-low-stock-preview-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Needs Restocking', style: theme.textTheme.titleLarge),
          SizedBox(height: spacing.xs),
          TextButton(
            key: const Key('dashboard-view-low-stock-action'),
            onPressed: onViewLowStock,
            child: const Text('View Low Stock'),
          ),
          SizedBox(height: spacing.sm),
          preview.when(
            data: (items) => items.isEmpty
                ? const _LowStockPreviewEmpty()
                : Column(
                    children: [
                      for (final item in items) ...[
                        _LowStockPreviewItem(item: item),
                        if (item != items.last) SizedBox(height: spacing.sm),
                      ],
                    ],
                  ),
            error: (_, _) => _LowStockPreviewError(onRetry: onRetry),
            loading: () => const _LowStockPreviewLoading(),
          ),
        ],
      ),
    );
  }
}

final class _LowStockPreviewItem extends StatelessWidget {
  const _LowStockPreviewItem({required this.item});

  final DashboardLowStockPreviewItem item;

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    final theme = Theme.of(context);
    final quantity = '${item.quantity} ${item.unit}';

    return Semantics(
      excludeSemantics: true,
      label: '${item.name}, $quantity, ${item.status.label}',
      child: DecoratedBox(
        key: Key('dashboard-low-stock-preview-item-${item.id}'),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(AppDimensions.componentRadius),
        ),
        child: Padding(
          padding: EdgeInsets.all(spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: spacing.xs),
              Text(
                quantity,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: spacing.sm),
              StockBadge(status: item.status),
            ],
          ),
        ),
      ),
    );
  }
}

final class _LowStockPreviewEmpty extends StatelessWidget {
  const _LowStockPreviewEmpty();

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    final theme = Theme.of(context);

    return Container(
      key: const Key('dashboard-low-stock-preview-empty'),
      width: double.infinity,
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppDimensions.componentRadius),
      ),
      child: Text(
        'No products need restocking right now.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

final class _LowStockPreviewLoading extends StatelessWidget {
  const _LowStockPreviewLoading();

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);

    return Padding(
      key: const Key('dashboard-low-stock-preview-loading'),
      padding: EdgeInsets.symmetric(vertical: spacing.sm),
      child: const LinearProgressIndicator(
        semanticsLabel: 'Loading products that need restocking',
      ),
    );
  }
}

final class _LowStockPreviewError extends StatelessWidget {
  const _LowStockPreviewError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    final theme = Theme.of(context);

    return Container(
      key: const Key('dashboard-low-stock-preview-error'),
      width: double.infinity,
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        border: Border.all(color: theme.colorScheme.error),
        borderRadius: BorderRadius.circular(AppDimensions.componentRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "We couldn't load products that need restocking.",
            style: theme.textTheme.bodyMedium,
          ),
          SizedBox(height: spacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

final class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({
    required this.preview,
    required this.onRetry,
    required this.onViewHistory,
  });

  final AsyncValue<List<DashboardRecentActivityItem>> preview;
  final VoidCallback onRetry;
  final VoidCallback onViewHistory;

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    final theme = Theme.of(context);

    return KeyedSubtree(
      key: const Key('dashboard-recent-activity-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent Activity',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              TextButton(
                key: const Key('dashboard-view-history-action'),
                onPressed: onViewHistory,
                child: const Text('View History'),
              ),
            ],
          ),
          SizedBox(height: spacing.sm),
          preview.when(
            data: (items) => items.isEmpty
                ? const _RecentActivityEmpty()
                : Column(
                    children: [
                      for (final item in items) ...[
                        _RecentActivityItem(
                          item: item,
                          onTap: onViewHistory,
                        ),
                        if (item != items.last) SizedBox(height: spacing.sm),
                      ],
                    ],
                  ),
            error: (_, _) => _RecentActivityError(onRetry: onRetry),
            loading: () => const _RecentActivityLoading(),
          ),
        ],
      ),
    );
  }
}

final class _RecentActivityItem extends StatelessWidget {
  const _RecentActivityItem({required this.item, required this.onTap});

  final DashboardRecentActivityItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    final theme = Theme.of(context);
    final isStockIn = item.type == StockMovementType.stockIn;
    final label = isStockIn ? 'Stock In' : 'Stock Out';
    final signedQuantity = _signedActivityQuantity(item);
    final note = item.note?.trim();

    return Semantics(
      button: true,
      label:
          '$label, ${item.productNameSnapshot}, $signedQuantity, '
          '${_formatActivityDateTime(item.createdAt)}',
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(AppDimensions.componentRadius),
        ),
        child: InkWell(
          key: Key('dashboard-recent-activity-item-${item.id}'),
          borderRadius: BorderRadius.circular(AppDimensions.componentRadius),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.minimumTapTarget,
            ),
            child: Padding(
              padding: EdgeInsets.all(spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: theme.textTheme.labelLarge),
                            SizedBox(height: spacing.xs),
                            Text(
                              item.productNameSnapshot,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: spacing.md),
                      Flexible(
                        child: Text(
                          signedQuantity,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isStockIn
                                ? theme.colorScheme.primary
                                : theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.sm),
                  Text(
                    _formatActivityDateTime(item.createdAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (note != null && note.isNotEmpty) ...[
                    SizedBox(height: spacing.xs),
                    Text(
                      note,
                      key: Key('dashboard-recent-activity-note-${item.id}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _RecentActivityEmpty extends StatelessWidget {
  const _RecentActivityEmpty();

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    final theme = Theme.of(context);

    return Container(
      key: const Key('dashboard-recent-activity-empty'),
      width: double.infinity,
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppDimensions.componentRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No stock movement yet.', style: theme.textTheme.titleSmall),
          SizedBox(height: spacing.xs),
          Text(
            'Stock In and Stock Out records will appear here.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

final class _RecentActivityLoading extends StatelessWidget {
  const _RecentActivityLoading();

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);

    return Padding(
      key: const Key('dashboard-recent-activity-loading'),
      padding: EdgeInsets.symmetric(vertical: spacing.sm),
      child: const LinearProgressIndicator(
        semanticsLabel: 'Loading recent stock activity',
      ),
    );
  }
}

final class _RecentActivityError extends StatelessWidget {
  const _RecentActivityError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    final theme = Theme.of(context);

    return Container(
      key: const Key('dashboard-recent-activity-error'),
      width: double.infinity,
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        border: Border.all(color: theme.colorScheme.error),
        borderRadius: BorderRadius.circular(AppDimensions.componentRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "We couldn't load recent stock activity.",
            style: theme.textTheme.bodyMedium,
          ),
          SizedBox(height: spacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

String _signedActivityQuantity(DashboardRecentActivityItem item) {
  final sign = item.type == StockMovementType.stockIn ? '+' : '-';
  return '$sign${item.quantity} ${item.unitSnapshot}';
}

String _formatActivityDateTime(DateTime createdAt) {
  final local = createdAt.toLocal();
  final month = _monthNames[local.month - 1];
  final minute = local.minute.toString().padLeft(2, '0');
  return '$month ${local.day}, ${local.year} ${local.hour}:$minute';
}

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

final class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState();

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const Key('dashboard-empty-state'),
      child: AppEmptyState(
        title: 'No products yet',
        message: 'Add your first product to start seeing inventory totals.',
        icon: Icons.inventory_2_outlined,
        actionLabel: 'Add your first product',
        onAction: () => context.go(ProductRoute.addProduct.path),
      ),
    );
  }
}

void _openLowStockProducts(BuildContext context, WidgetRef ref) {
  ref
      .read(productListControllerProvider.notifier)
      .stockFilterChanged(ProductStockFilter.lowStock);
  context.go(AppRoute.products.path);
}
