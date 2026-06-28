// Member names describe the small, class-documented presentation API.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:tindatrack/core/ui/app_dimensions.dart';
import 'package:tindatrack/core/ui/app_spacing.dart';

/// Reusable error presentation that accepts safe display copy only.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    required this.message,
    this.title = 'Something went wrong',
    this.actionLabel,
    this.onAction,
    this.isActionEnabled = true,
    super.key,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction must be supplied together',
       );

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isActionEnabled;

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.lg),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: EdgeInsets.all(spacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            border: Border.all(color: theme.colorScheme.error),
            borderRadius: BorderRadius.circular(
              AppDimensions.componentRadius,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: theme.colorScheme.error,
                size: spacing.xl,
                semanticLabel: 'Error',
              ),
              SizedBox(height: spacing.sm),
              Text(
                title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing.sm),
              Text(
                message,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null) ...[
                SizedBox(height: spacing.md),
                FilledButton(
                  onPressed: isActionEnabled ? onAction : null,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
