// CSV fixtures are easier to read as adjacent string literals.
// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/app/router/app_router.dart';
import 'package:tindatrack/app/router/app_routes.dart';
import 'package:tindatrack/app/theme/app_theme.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/settings/domain/entities/csv_import_preview.dart';
import 'package:tindatrack/features/settings/domain/services/csv_export_builder.dart';
import 'package:tindatrack/features/settings/domain/services/csv_import_parser.dart';
import 'package:tindatrack/features/settings/presentation/providers/csv_export_providers.dart';
import 'package:tindatrack/features/settings/presentation/providers/csv_import_providers.dart';
import 'package:tindatrack/features/settings/presentation/screens/settings_screen.dart';

void main() {
  testWidgets('renders title and all MVP settings sections', (tester) async {
    await _pumpSettings(tester);

    expect(find.byKey(const Key('settings-screen')), findsOneWidget);
    expect(find.text('App Info'), findsOneWidget);
    expect(find.byKey(const Key('settings-currency-section')), findsOneWidget);
    expect(
      find.byKey(const Key('settings-backup-export-section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settings-app-version-section')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-local-data-section')),
      120,
    );
    expect(
      find.byKey(const Key('settings-local-data-section')),
      findsOneWidget,
    );
    expect(find.text('Currency'), findsOneWidget);
    expect(find.text('Backup / Export'), findsOneWidget);
    expect(find.text('App Version'), findsOneWidget);
    expect(find.text('Local Data'), findsOneWidget);
    expect(find.text('PHP'), findsOneWidget);
    expect(find.textContaining('Philippine Peso'), findsOneWidget);
    expect(find.text('CSV files'), findsOneWidget);
    expect(
      find.byKey(const Key('settings-save-export-action')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settings-share-export-action')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settings-import-products-action')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Create readable Products and Stock History CSV files from '
        'this device. Active and archived products are included.',
      ),
      findsOneWidget,
    );
    final pubspecVersion = _pubspecVersion();
    expect(find.text(_displayVersion(pubspecVersion)), findsOneWidget);
    expect(find.text('MVP preview'), findsNothing);
    expect(
      find.text('Inventory data is stored on this device for the MVP.'),
      findsOneWidget,
    );
  });

  testWidgets('Save to Downloads action shows saved location snackbar', (
    tester,
  ) async {
    var saveCalls = 0;
    var shareCalls = 0;
    await _pumpSettings(
      tester,
      controller: CsvExportController(
        readProducts: () async => const Success([]),
        readMovements: () async => const Success([]),
        builder: const CsvExportBuilder(),
        shareBundle: (_) async {
          shareCalls++;
        },
        saveBundle: (_) async {
          saveCalls++;
        },
        exportedAt: () => DateTime.utc(2026, 8, 9, 10, 15),
      ),
    );

    await tester.tap(find.byKey(const Key('settings-save-export-action')));
    await tester.pumpAndSettle();

    expect(saveCalls, 1);
    expect(shareCalls, 0);
    expect(
      find.text('CSV files saved to Downloads/TindaTrack.'),
      findsOneWidget,
    );
  });

  testWidgets('Share CSV files action shows share-ready snackbar', (
    tester,
  ) async {
    var saveCalls = 0;
    var shareCalls = 0;
    await _pumpSettings(
      tester,
      controller: CsvExportController(
        readProducts: () async => const Success([]),
        readMovements: () async => const Success([]),
        builder: const CsvExportBuilder(),
        shareBundle: (_) async {
          shareCalls++;
        },
        saveBundle: (_) async {
          saveCalls++;
        },
        exportedAt: () => DateTime.utc(2026, 8, 9, 10, 15),
      ),
    );

    await tester.tap(find.byKey(const Key('settings-share-export-action')));
    await tester.pumpAndSettle();

    expect(shareCalls, 1);
    expect(saveCalls, 0);
    expect(find.text('CSV export ready.'), findsOneWidget);
  });

  testWidgets('Import Products CSV shows a blocking preview for bad files', (
    tester,
  ) async {
    await _pumpSettings(
      tester,
      importController: CsvImportController(
        pickCsv: () async => 'Date,Type,Quantity\n2026,Stock In,1\n',
        parser: const CsvImportParser(),
        findExistingBarcodes: (_) async => const Success<Set<String>>({}),
        importRows: (_) async => const Success<void>(null),
      ),
    );

    await tester.tap(find.byKey(const Key('settings-import-products-action')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('settings-import-preview-dialog')),
      findsOneWidget,
    );
    expect(find.text('Import Preview'), findsOneWidget);
    expect(find.textContaining('TindaTrack Products CSV file'), findsOneWidget);
    final importButton = tester.widget<FilledButton>(
      find.byKey(const Key('settings-confirm-import-action')),
    );
    expect(importButton.onPressed, isNull);
  });

  testWidgets('Import Products CSV imports after a clean preview', (
    tester,
  ) async {
    final importedRows = <CsvImportProductRow>[];
    await _pumpSettings(
      tester,
      importController: CsvImportController(
        pickCsv: () async => _validProductsCsv(),
        parser: const CsvImportParser(),
        findExistingBarcodes: (_) async => const Success<Set<String>>({}),
        importRows: (rows) async {
          importedRows.addAll(rows);
          return const Success<void>(null);
        },
      ),
    );

    await tester.tap(find.byKey(const Key('settings-import-products-action')));
    await tester.pumpAndSettle();
    expect(
      find.text('2 products found: 1 active, 1 archived.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('settings-confirm-import-action')));
    await tester.pumpAndSettle();

    expect(importedRows.map((row) => row.name), ['Rice', 'Old Soap']);
    expect(importedRows.map((row) => row.isArchived), [false, true]);
    expect(find.text('Imported 2 products.'), findsOneWidget);
  });

  testWidgets('Import Products CSV cancel returns quietly', (tester) async {
    await _pumpSettings(
      tester,
      importController: CsvImportController(
        pickCsv: () async => null,
        parser: const CsvImportParser(),
        findExistingBarcodes: (_) async => const Success<Set<String>>({}),
        importRows: (_) async => const Success<void>(null),
      ),
    );

    await tester.tap(find.byKey(const Key('settings-import-products-action')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('settings-import-preview-dialog')),
      findsNothing,
    );
    expect(find.byType(SnackBar), findsNothing);
  });
  testWidgets('Export Data action shows friendly failure snackbar', (
    tester,
  ) async {
    await _pumpSettings(
      tester,
      controller: CsvExportController(
        readProducts: () async => const Success([]),
        readMovements: () async => const Success([]),
        builder: const CsvExportBuilder(),
        shareBundle: (_) async {},
        saveBundle: (_) async => throw StateError('raw save failure'),
        exportedAt: () => DateTime.utc(2026, 8, 9, 10, 15),
      ),
    );

    await tester.tap(find.byKey(const Key('settings-save-export-action')));
    await tester.pumpAndSettle();

    expect(find.text('Export failed. Please try again.'), findsOneWidget);
    expect(find.textContaining('raw save failure'), findsNothing);
  });

  test('extracts only the top-level pubspec version scalar', () {
    expect(
      versionFromPubspec(
        'name: app\n'
        '  version: nested\n'
        'version: 0.1.0+1 # release\n',
      ),
      'Version 0.1.0 (Build 1)',
    );
    expect(versionFromPubspec('version: 0.1.0\n'), 'Version 0.1.0');
    expect(versionFromPubspec('name: app\n'), 'Unavailable');
  });

  testWidgets('visible copy stays inside MVP scope', (tester) async {
    await _pumpSettings(tester);

    final visibleText = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data ?? widget.textSpan?.toPlainText() ?? '')
        .join(' ')
        .toLowerCase();

    for (final forbidden in [
      'login',
      'cloud sync',
      'account management',
      'supplier',
      'pos',
      'barcode scanner',
      'accounting',
      'active export',
      'backed up',
      'exported',
      'backup enabled',
      'cloud backup',
      'export available',
      'data is protected',
      'sync enabled',
      'remote api',
      'export complete',
    ]) {
      expect(visibleText, isNot(contains(forbidden)));
    }
  });

  testWidgets('populated settings fit a small phone with enlarged text', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pumpSettings(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-local-data-section')),
      120,
    );

    expect(
      find.byKey(const Key('settings-local-data-section')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings route opens from the existing app shell offline', (
    tester,
  ) async {
    final router = createAppRouter(
      initialLocation: AppRoute.settings.path,
      dashboardBuilder: (_, _) => const Scaffold(key: Key('dashboard-screen')),
      productsBuilder: (_, _) => const Scaffold(key: Key('products-screen')),
      historyBuilder: (_, _) => const Scaffold(key: Key('history-screen')),
      settingsBuilder: (_, _) => const SettingsScreen(),
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoute.settings.path,
    );
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byKey(const Key('settings-screen')), findsOneWidget);
    expect(find.byKey(const Key('settings-currency-section')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('settings-currency-section')),
        matching: find.byType(DropdownButton<Object>),
      ),
      findsNothing,
    );
  });
}

String _displayVersion(String rawVersion) {
  final parts = rawVersion.split('+');
  if (parts.length == 2 && parts.first.isNotEmpty && parts.last.isNotEmpty) {
    return 'Version ${parts.first} (Build ${parts.last})';
  }
  return 'Version $rawVersion';
}

String _pubspecVersion() {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  final versionLine = pubspec
      .split('\n')
      .firstWhere((line) => line.startsWith('version:'));
  return versionLine.split(':').last.trim();
}

Future<void> _pumpSettings(
  WidgetTester tester, {
  CsvExportController? controller,
  CsvImportController? importController,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (controller != null)
          csvExportControllerProvider.overrideWithValue(controller),
        if (importController != null)
          csvImportControllerProvider.overrideWithValue(importController),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const SettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _validProductsCsv() {
  return 'Product Name,Category,Unit,Selling Price,Current Quantity,'
      'Low Stock Threshold,Barcode,Status,Created At,Updated At\n'
      'Rice,Staples,kg,55.50,12,3,111,Active,,\n'
      'Old Soap,,pcs,18.00,0,2,,Archived,,\n';
}
