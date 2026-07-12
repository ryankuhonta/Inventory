import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/app/theme/app_theme.dart';
import 'package:tindatrack/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:tindatrack/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:tindatrack/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:tindatrack/features/dashboard/presentation/screens/dashboard_screen.dart';

void main() {
  testWidgets('renders inventory summary cards from provider data', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      repository: _DashboardRepository(
        stream: Stream.value(
          const DashboardSummary(
            totalActiveProducts: 12,
            lowStockProducts: 3,
            stockChangesToday: 5,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('dashboard-screen')), findsOneWidget);
    expect(find.text('Inventory Today'), findsOneWidget);
    expect(
      find.byKey(const Key('dashboard-summary-total-products')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('dashboard-summary-low-stock')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('dashboard-summary-stock-changes-today')),
      findsOneWidget,
    );
    expect(find.text('Total Products'), findsOneWidget);
    expect(find.text('Low Stock'), findsOneWidget);
    expect(find.text('Stock Changes Today'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('shows neutral low-stock card when no products need attention', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      repository: _DashboardRepository(
        stream: Stream.value(
          const DashboardSummary(
            totalActiveProducts: 4,
            lowStockProducts: 0,
            stockChangesToday: 2,
          ),
        ),
      ),
    );

    final lowStockCard = find.byKey(const Key('dashboard-summary-low-stock'));
    expect(lowStockCard, findsOneWidget);
    expect(
      find.descendant(
        of: lowStockCard,
        matching: find.byIcon(Icons.check_circle_outline),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: lowStockCard,
        matching: find.byIcon(Icons.warning_amber_outlined),
      ),
      findsNothing,
    );
    expect(find.text('Needs attention'), findsNothing);
  });

  testWidgets(
    'shows cards when today has stock changes but no active products',
    (
      tester,
    ) async {
      await _pumpDashboard(
        tester,
        repository: _DashboardRepository(
          stream: Stream.value(
            const DashboardSummary(
              totalActiveProducts: 0,
              lowStockProducts: 0,
              stockChangesToday: 2,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('dashboard-empty-state')), findsNothing);
      expect(
        find.byKey(const Key('dashboard-summary-stock-changes-today')),
        findsOneWidget,
      );
      expect(find.text('2'), findsOneWidget);
    },
  );

  testWidgets('shows a lightweight loading state on a small screen', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpDashboard(
      tester,
      repository: const _DashboardRepository(stream: Stream.empty()),
      settle: false,
    );
    await tester.pump();

    expect(find.byKey(const Key('dashboard-loading-state')), findsOneWidget);
    expect(find.text('Inventory Today'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows friendly error copy without raw diagnostics', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      repository: _DashboardRepository(
        stream: Stream<DashboardSummary>.error(
          Exception('PRIVATE_SQL_FAILURE'),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('dashboard-error-state')), findsOneWidget);
    expect(
      find.text("We couldn't load your dashboard. Please try again."),
      findsOneWidget,
    );
    expect(find.textContaining('PRIVATE_SQL_FAILURE'), findsNothing);
  });

  testWidgets('shows first-product guidance when no products exist', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      repository: _DashboardRepository(
        stream: Stream.value(
          const DashboardSummary(
            totalActiveProducts: 0,
            lowStockProducts: 0,
            stockChangesToday: 0,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('dashboard-empty-state')), findsOneWidget);
    expect(find.text('No products yet'), findsOneWidget);
    expect(find.text('Add your first product'), findsOneWidget);
    expect(find.textContaining('login'), findsNothing);
    expect(find.textContaining('cloud'), findsNothing);
  });
}

Future<void> _pumpDashboard(
  WidgetTester tester, {
  required DashboardRepository repository,
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const DashboardScreen(),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

final class _DashboardRepository implements DashboardRepository {
  const _DashboardRepository({required this.stream});

  final Stream<DashboardSummary> stream;

  @override
  Stream<DashboardSummary> watchSummary({required DateTime localNow}) => stream;
}
