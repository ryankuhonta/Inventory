import 'package:flutter/material.dart';
import 'package:tindatrack/core/ui/app_spacing.dart';

/// Minimal landing destination after local initialization succeeds.
class DashboardScreen extends StatelessWidget {
  /// Creates the placeholder Dashboard screen.
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(
      screenKey: Key('dashboard-screen'),
      title: 'Dashboard',
      message: 'Offline inventory tracker',
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
