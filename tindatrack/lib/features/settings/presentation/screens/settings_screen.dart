import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/core/formatters/currency_formatter.dart';
import 'package:tindatrack/core/ui/app_dimensions.dart';
import 'package:tindatrack/core/ui/app_spacing.dart';
import 'package:tindatrack/features/settings/domain/entities/csv_export_bundle.dart';
import 'package:tindatrack/features/settings/presentation/providers/csv_export_providers.dart';

/// Root screen for local-only app information.
class SettingsScreen extends ConsumerStatefulWidget {
  /// Creates the App Info screen.
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final Future<String> _appVersion = _loadAppVersion();
  _ExportAction? _exportAction;

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    final theme = Theme.of(context);
    const currencyFormatter = CurrencyFormatter.php();

    return Scaffold(
      key: const Key('settings-screen'),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(spacing.md),
          children: [
            Text(
              'App Info',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: spacing.md),
            _SettingsSection(
              key: const Key('settings-currency-section'),
              icon: Icons.payments_outlined,
              title: 'Currency',
              value: currencyFormatter.currencyCode,
              description:
                  'Philippine Peso is the MVP currency for product prices.',
            ),
            SizedBox(height: spacing.md),
            _SettingsSection(
              key: const Key('settings-backup-export-section'),
              icon: Icons.file_upload_outlined,
              title: 'Backup / Export',
              value: 'CSV files',
              description:
                  'Create readable Products and Stock History CSV files from '
                  'this device. Active and archived products are included.',
              action: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    key: const Key('settings-save-export-action'),
                    onPressed: _exportAction == null
                        ? () => _exportData(_ExportAction.saveToDownloads)
                        : null,
                    icon: _exportAction == _ExportAction.saveToDownloads
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_outlined),
                    label: Text(
                      _exportAction == _ExportAction.saveToDownloads
                          ? 'Saving...'
                          : 'Save to Downloads',
                    ),
                  ),
                  SizedBox(height: spacing.xs),
                  OutlinedButton.icon(
                    key: const Key('settings-share-export-action'),
                    onPressed: _exportAction == null
                        ? () => _exportData(_ExportAction.share)
                        : null,
                    icon: _exportAction == _ExportAction.share
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.ios_share_outlined),
                    label: Text(
                      _exportAction == _ExportAction.share
                          ? 'Preparing...'
                          : 'Share CSV files',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.md),
            FutureBuilder<String>(
              future: _appVersion,
              builder: (context, snapshot) {
                final version = switch (snapshot.connectionState) {
                  ConnectionState.done => snapshot.data ?? 'Unavailable',
                  _ => 'Loading...',
                };

                return _SettingsSection(
                  key: const Key('settings-app-version-section'),
                  icon: Icons.info_outline,
                  title: 'App Version',
                  value: version,
                  description:
                      'Shown from the app package version for '
                      'support and testing.',
                );
              },
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

  Future<void> _exportData(_ExportAction action) async {
    setState(() {
      _exportAction = action;
    });

    final controller = ref.read(csvExportControllerProvider);
    final result = switch (action) {
      _ExportAction.saveToDownloads => await controller.saveCsvToDownloads(),
      _ExportAction.share => await controller.shareCsv(),
    };
    if (!mounted) return;

    setState(() {
      _exportAction = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case Success<CsvExportSummary>():
        messenger.showSnackBar(
          SnackBar(content: Text(_successMessage(action))),
        );
      case FailureResult<CsvExportSummary>():
        messenger.showSnackBar(
          const SnackBar(content: Text('Export failed. Please try again.')),
        );
    }
  }

  String _successMessage(_ExportAction action) {
    return switch (action) {
      _ExportAction.saveToDownloads =>
        'CSV files saved to Downloads/TindaTrack.',
      _ExportAction.share => 'CSV export ready.',
    };
  }
}

enum _ExportAction {
  saveToDownloads,
  share,
}

Future<String> _loadAppVersion() async {
  final pubspec = await rootBundle.loadString('pubspec.yaml');
  return versionFromPubspec(pubspec);
}

/// Extracts the top-level app version from pubspec contents.
@visibleForTesting
String versionFromPubspec(String pubspec) {
  final versionLine = pubspec
      .split('\n')
      .firstWhere(
        (line) => line.startsWith('version:'),
        orElse: () => '',
      );
  if (versionLine.isEmpty) {
    return 'Unavailable';
  }
  final rawVersion = versionLine
      .substring('version:'.length)
      .split('#')
      .first
      .trim();
  if (rawVersion.isEmpty) {
    return 'Unavailable';
  }

  final parts = rawVersion.split('+');
  if (parts.length == 2 && parts.first.isNotEmpty && parts.last.isNotEmpty) {
    return 'Version ${parts.first} (Build ${parts.last})';
  }

  return 'Version $rawVersion';
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;
  final String description;
  final Widget? action;

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
                  if (action != null) ...[
                    SizedBox(height: spacing.sm),
                    action!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
