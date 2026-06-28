// Member names describe the small, class-documented presentation API.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:tindatrack/core/ui/app_spacing.dart';

/// Lightweight centered loading presentation with accessible progress meaning.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({
    this.title,
    this.message,
    this.semanticsLabel = 'Loading',
    super.key,
  });

  final String? title;
  final String? message;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing.sm),
            ],
            if (message != null) ...[
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing.md),
            ],
            Semantics(
              label: semanticsLabel,
              liveRegion: true,
              child: const CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}
