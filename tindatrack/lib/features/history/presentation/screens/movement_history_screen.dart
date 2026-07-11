import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tindatrack/core/ui/app_dimensions.dart';
import 'package:tindatrack/core/ui/app_spacing.dart';
import 'package:tindatrack/core/widgets/app_empty_state.dart';
import 'package:tindatrack/core/widgets/app_error_view.dart';
import 'package:tindatrack/core/widgets/app_loading_view.dart';
import 'package:tindatrack/features/history/presentation/providers/movement_history_providers.dart';
import 'package:tindatrack/features/stock/domain/entities/stock_movement.dart';

/// Read-only inventory movement history for the History branch.
class MovementHistoryScreen extends StatelessWidget {
  /// Creates the History screen.
  const MovementHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!_hasProviderScope(context)) {
      return const _HistoryScaffold(body: _HistoryEmptyState());
    }

    return Consumer(
      builder: (context, ref, _) {
        final movements = ref.watch(movementHistoryProvider);
        return _HistoryScaffold(
          body: movements.when(
            data: (items) => items.isEmpty
                ? const _HistoryEmptyState()
                : _HistoryList(movements: items),
            error: (_, _) => AppErrorView(
              title: 'History unavailable',
              message: "We couldn't load history. Please try again.",
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(movementHistoryProvider),
            ),
            loading: () => const AppLoadingView(
              title: 'History',
              semanticsLabel: 'Loading movement history',
            ),
          ),
        );
      },
    );
  }
}

final class _HistoryScaffold extends StatelessWidget {
  const _HistoryScaffold({required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('history-screen'),
      appBar: AppBar(title: const Text('History')),
      body: SafeArea(child: body),
    );
  }
}

bool _hasProviderScope(BuildContext context) {
  try {
    ProviderScope.containerOf(context, listen: false);
    return true;
    // Riverpod reports a missing ProviderScope with StateError.
    // ignore: avoid_catching_errors
  } on StateError {
    return false;
  }
}

final class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return const KeyedSubtree(
      key: Key('history-empty-state'),
      child: AppEmptyState(
        title: 'Stock changes will appear here.',
        message: 'Stock In and Stock Out records will show in this list.',
        icon: Icons.history,
      ),
    );
  }
}

final class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.movements});

  final List<StockMovement> movements;

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    return ListView.separated(
      key: const Key('history-list'),
      padding: EdgeInsets.all(spacing.md),
      itemCount: movements.length,
      separatorBuilder: (_, _) => SizedBox(height: spacing.sm),
      itemBuilder: (context, index) {
        return _MovementRow(movement: movements[index]);
      },
    );
  }
}

final class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.movement});

  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    final theme = Theme.of(context);
    final isStockIn = movement.type == StockMovementType.stockIn;
    final label = isStockIn ? 'Stock In' : 'Stock Out';
    final signedQuantity = _signedQuantity(movement);
    final quantityTransition =
        '${movement.previousQuantity} -> ${movement.newQuantity} '
        '${movement.unitSnapshot}';

    return Card(
      key: Key('history-row-${movement.id}'),
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
                        movement.productNameSnapshot,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: spacing.md),
                Text(
                  signedQuantity,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isStockIn
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.end,
                ),
              ],
            ),
            SizedBox(height: spacing.sm),
            Wrap(
              spacing: spacing.md,
              runSpacing: spacing.xs,
              children: [
                _MetaText(text: quantityTransition),
                _MetaText(text: _formatMovementDateTime(movement.createdAt)),
              ],
            ),
            if (movement.note case final note? when note.isNotEmpty) ...[
              SizedBox(height: spacing.sm),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(spacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.componentRadius,
                  ),
                ),
                child: Text(note),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _MetaText extends StatelessWidget {
  const _MetaText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

String _signedQuantity(StockMovement movement) {
  final sign = movement.type == StockMovementType.stockIn ? '+' : '-';
  return '$sign${movement.quantity} ${movement.unitSnapshot}';
}

String _formatMovementDateTime(DateTime createdAt) {
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
