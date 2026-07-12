import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tindatrack/app/router/app_router.dart';
import 'package:tindatrack/app/router/app_routes.dart';
import 'package:tindatrack/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:tindatrack/features/dashboard/presentation/providers/dashboard_providers.dart';

void main() {
  testWidgets('shows and navigates the four canonical destinations', (
    tester,
  ) async {
    final router = _createShellTestRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(_RouterTestApp(router: router));
    await tester.pumpAndSettle();

    final navigationBar = find.byType(NavigationBar);
    expect(navigationBar, findsOneWidget);
    expect(
      tester.widget<NavigationBar>(navigationBar).labelBehavior,
      NavigationDestinationLabelBehavior.alwaysShow,
    );

    for (final route in AppRoute.values) {
      expect(_navigationLabel(route.label), findsOneWidget);
    }
    expect(
      tester
          .widget<NavigationBar>(navigationBar)
          .destinations
          .whereType<NavigationDestination>(),
      hasLength(4),
    );

    for (final (index, route) in AppRoute.values.indexed) {
      await tester.tap(_navigationLabel(route.label));
      await tester.pumpAndSettle();

      expect(
        tester.widget<NavigationBar>(navigationBar).selectedIndex,
        index,
      );
      expect(router.routeInformationProvider.value.uri.path, route.path);
      expect(find.byKey(Key('${route.name}-screen')), findsOneWidget);
      for (final inactiveRoute in AppRoute.values.where(
        (candidate) => candidate != route,
      )) {
        expect(
          find.byKey(Key('${inactiveRoute.name}-screen')),
          findsNothing,
        );
      }
    }
  });

  testWidgets('reselecting the active destination stays at its root', (
    tester,
  ) async {
    final router = _createShellTestRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(_RouterTestApp(router: router));
    await tester.pumpAndSettle();

    await tester.tap(_navigationLabel(AppRoute.dashboard.label));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.matches,
      hasLength(1),
    );
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoute.dashboard.path,
    );
    expect(find.byKey(const Key('dashboard-screen')), findsOneWidget);
  });
}

GoRouter _createShellTestRouter() {
  return createAppRouter(
    dashboardBuilder: (_, _) {
      return const Scaffold(key: Key('dashboard-screen'));
    },
    productsBuilder: (_, _) {
      return const Scaffold(key: Key('products-screen'));
    },
    historyBuilder: (_, _) {
      return const Scaffold(key: Key('history-screen'));
    },
    settingsBuilder: (_, _) {
      return const Scaffold(key: Key('settings-screen'));
    },
  );
}

Finder _navigationLabel(String label) {
  return find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
}

final class _RouterTestApp extends StatelessWidget {
  const _RouterTestApp({required this.router});

  final RouterConfig<Object> router;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        dashboardSummaryProvider.overrideWith((ref) {
          return Stream.value(
            const DashboardSummary(
              totalActiveProducts: 1,
              lowStockProducts: 0,
              stockChangesToday: 0,
            ),
          );
        }),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }
}
