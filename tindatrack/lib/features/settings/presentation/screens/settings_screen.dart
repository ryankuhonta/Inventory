import 'package:flutter/material.dart';
import 'package:tindatrack/core/ui/app_dimensions.dart';
import 'package:tindatrack/core/ui/app_spacing.dart';

/// Root screen for local-only app settings.
class SettingsScreen extends StatelessWidget {
  /// Creates the Settings screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      key: const Key('settings-screen'),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(spacing.md),
          children: [
            Text(
              'Settings',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: spacing.md),
            const _SettingsSection(
              key: Key('settings-currency-section'),
              icon: Icons.payments_outlined,
              title: 'Currency',
              value: 'PHP',
              description: 'Amounts are shown for Philippine Peso pricing.',
            ),
            SizedBox(height: spacing.md),
            const _SettingsSection(
              key: Key('settings-backup-export-section'),
              icon: Icons.file_upload_outlined,
              title: 'Backup / Export',
              value: 'Coming soon',
              description:
                  'A simple file option will be added in a future update.',
            ),
            SizedBox(height: spacing.md),
            const _SettingsSection(
              key: Key('settings-app-version-section'),
              icon: Icons.info_outline,
              title: 'App Version',
              value: 'MVP preview',
              description: 'Version details will be shown here before release.',
            ),
            SizedBox(height: spacing.md),
            const _SettingsSection(
              key: Key('settings-local-data-section'),
              icon: Icons.phone_android_outlined,
              title: 'Local Data',
              value: 'This device',
              description:
                  'Inventory data is stored on this device for the MVP.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;
  final String description;

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppDimensions.componentRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorScheme.primary),
            SizedBox(width: spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
