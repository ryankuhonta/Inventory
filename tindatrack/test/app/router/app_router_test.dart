import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tindatrack/app/router/app_router.dart';
import 'package:tindatrack/app/router/app_routes.dart';

void main() {
  test('declares only the four authorized root routes', () {
    expect(
      AppRoute.values.map((route) => (route.name, route.path)),
      [
        ('dashboard', '/dashboard'),
        ('products', '/products'),
        ('history', '/history'),
        ('settings', '/settings'),
      ],
    );
  });

  testWidgets('maps each direct root location to its matching branch', (
    tester,
  ) async {
    for (final (index, route) in AppRoute.values.indexed) {
      final router = createAppRouter(initialLocation: route.path);
      addTearDown(router.dispose);

      await tester.pumpWidget(_RouterTestApp(router: router));
      await tester.pumpAndSettle();

      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        index,
      );
      expect(router.routeInformationProvider.value.uri.path, route.path);
      expect(router.namedLocation(route.name), route.path);
      expect(find.byKey(Key('${route.name}-screen')), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('preserves branch state when switching away and back', (
    tester,
  ) async {
    final router = createAppRouter(
      dashboardBuilder: (_, _) => const _StatefulBranchScreen('Dashboard'),
      productsBuilder: (_, _) => const _StatefulBranchScreen('Products'),
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_RouterTestApp(router: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('Dashboard-increment')));
    await tester.pump();
    expect(find.text('Dashboard count: 1'), findsOneWidget);

    await tester.tap(_navigationLabel('Products'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('Products-increment')));
    await tester.pump();
    expect(find.text('Products count: 1'), findsOneWidget);

    await tester.tap(_navigationLabel('Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard count: 1'), findsOneWidget);
    expect(find.text('Products count: 1'), findsNothing);
  });
}

Finder _navigationLabel(String label) {
  return find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
}

final class _RouterTestApp extends StatelessWidget {
  const _RouterTestApp({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: router);
  }
}

final class _StatefulBranchScreen extends StatefulWidget {
  const _StatefulBranchScreen(this.label);

  final String label;

  @override
  State<_StatefulBranchScreen> createState() => _StatefulBranchScreenState();
}

final class _StatefulBranchScreenState extends State<_StatefulBranchScreen> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${widget.label} count: $count'),
            FilledButton(
              key: Key('${widget.label}-increment'),
              onPressed: () => setState(() => count++),
              child: const Text('Increment'),
            ),
          ],
        ),
      ),
    );
  }
}
