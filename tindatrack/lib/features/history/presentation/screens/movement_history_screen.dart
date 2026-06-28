import 'package:flutter/material.dart';
import 'package:tindatrack/core/ui/app_spacing.dart';

/// Placeholder root for the History branch.
class MovementHistoryScreen extends StatelessWidget {
  /// Creates the History placeholder.
  const MovementHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(
      screenKey: Key('history-screen'),
      title: 'History',
      message: 'Inventory history is coming in a later story.',
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({
    required this.screenKey,
    required this.title,
    required this.message,
  });

  final Key screenKey;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      key: screenKey,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(spacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: spacing.sm),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
