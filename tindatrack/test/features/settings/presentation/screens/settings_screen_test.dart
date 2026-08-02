import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/app/router/app_router.dart';
import 'package:tindatrack/app/router/app_routes.dart';
import 'package:tindatrack/app/theme/app_theme.dart';
import 'package:tindatrack/features/settings/presentation/screens/settings_screen.dart';

void main() {
  testWidgets('renders title and all MVP settings sections', (tester) async {
    await _pumpSettings(tester);

    expect(find.byKey(const Key('settings-screen')), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.byKey(const Key('settings-currency-section')), findsOneWidget);
    expect(
      find.byKey(const Key('settings-backup-export-section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settings-app-version-section')),
      findsOneWidget,
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
    expect(find.text('Coming soon'), findsOneWidget);
    expect(
      find.text(
        'For now, inventory data stays on this device. '
        'No account or internet connection is needed to view this '
        'placeholder. Backup and export will be added in a future update.',
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
      MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
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

Future<void> _pumpSettings(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: const SettingsScreen(),
    ),
  );
  await tester.pumpAndSettle();
}
