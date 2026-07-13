import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tindatrack/app/router/app_routes.dart';
import 'package:tindatrack/app/theme/app_theme.dart';
import 'package:tindatrack/features/dashboard/domain/entities/dashboard_low_stock_preview_item.dart';
import 'package:tindatrack/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:tindatrack/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:tindatrack/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:tindatrack/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:tindatrack/features/products/domain/entities/product_stock_status.dart';
import 'package:tindatrack/features/products/presentation/controllers/product_list_controller.dart';

void main() {
  testWidgets('renders inventory summary cards from provider data', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      repository: _DashboardRepository(
        summaryStream: Stream.value(
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
        summaryStream: Stream.value(
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
          summaryStream: Stream.value(
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

  testWidgets('renders low-stock preview rows below summary cards', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      repository: _DashboardRepository(
        summaryStream: Stream.value(
          const DashboardSummary(
            totalActiveProducts: 4,
            lowStockProducts: 2,
            stockChangesToday: 1,
          ),
        ),
        previewStream: Stream.value(const [
          DashboardLowStockPreviewItem(
            id: 'out-1',
            name: 'Sardines',
            quantity: 0,
            unit: 'cans',
            status: ProductStockStatus.outOfStock,
          ),
          DashboardLowStockPreviewItem(
            id: 'low-1',
            name: 'Rice',
            quantity: 2,
            unit: 'kg',
            status: ProductStockStatus.lowStock,
          ),
        ]),
      ),
    );

    expect(
      find.byKey(const Key('dashboard-low-stock-preview-section')),
      findsOneWidget,
    );
    expect(find.text('Needs Restocking'), findsOneWidget);
    expect(find.text('Sardines'), findsOneWidget);
    expect(find.text('0 cans'), findsOneWidget);
    expect(find.text('Rice'), findsOneWidget);
    expect(find.text('2 kg'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('dashboard-low-stock-preview-item-out-1')),
        matching: find.text('Out of Stock'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('dashboard-low-stock-preview-item-low-1')),
        matching: find.text('Low Stock'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('navigates to Products with Low Stock selected', (
    tester,
  ) async {
    await _pumpDashboardRouter(
      tester,
      repository: _DashboardRepository(
        summaryStream: Stream.value(
          const DashboardSummary(
            totalActiveProducts: 4,
            lowStockProducts: 2,
            stockChangesToday: 1,
          ),
        ),
        previewStream: Stream.value(const [
          DashboardLowStockPreviewItem(
            id: 'low-1',
            name: 'Rice',
            quantity: 2,
            unit: 'kg',
            status: ProductStockStatus.lowStock,
          ),
        ]),
      ),
    );

    await tester.tap(find.byKey(const Key('dashboard-view-low-stock-action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('products-route-test-screen')), findsOneWidget);
    expect(find.text('filter: lowStock'), findsOneWidget);
  });

  testWidgets('shows preview loading without hiding summary cards', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      repository: _DashboardRepository(
        summaryStream: Stream.value(
          const DashboardSummary(
            totalActiveProducts: 4,
            lowStockProducts: 2,
            stockChangesToday: 1,
          ),
        ),
        previewStream: const Stream<List<DashboardLowStockPreviewItem>>.empty(),
      ),
      settle: false,
    );
    await tester.pump();

    expect(
      find.byKey(const Key('dashboard-summary-total-products')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('dashboard-low-stock-preview-loading')),
      findsOneWidget,
    );
  });

  testWidgets('preview rows fit a small phone with enlarged text', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
      tester.platformDispatcher.clearTextScaleFactorTestValue,
    );

    await _pumpDashboard(
      tester,
      repository: _DashboardRepository(
        summaryStream: Stream.value(
          const DashboardSummary(
            totalActiveProducts: 4,
            lowStockProducts: 1,
            stockChangesToday: 1,
          ),
        ),
        previewStream: Stream.value(const [
          DashboardLowStockPreviewItem(
            id: 'long-1',
            name: 'Very Long Product Name For A Small Store Shelf',
            quantity: 123456,
            unit: 'large bundled cartons',
            status: ProductStockStatus.outOfStock,
          ),
        ]),
      ),
    );

    final previewItem = find.byKey(
      const Key('dashboard-low-stock-preview-item-long-1'),
    );
    await tester.scrollUntilVisible(previewItem, 120);

    expect(previewItem, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows calm copy when low-stock preview is empty', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      repository: _DashboardRepository(
        summaryStream: Stream.value(
          const DashboardSummary(
            totalActiveProducts: 4,
            lowStockProducts: 0,
            stockChangesToday: 2,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('dashboard-low-stock-preview-empty')),
      findsOneWidget,
    );
    expect(
      find.text('No products need restocking right now.'),
      findsOneWidget,
    );
    expect(find.text('Needs attention'), findsNothing);
  });

  testWidgets(
    'shows friendly low-stock preview error without raw diagnostics',
    (
      tester,
    ) async {
      await _pumpDashboard(
        tester,
        repository: _DashboardRepository(
          summaryStream: Stream.value(
            const DashboardSummary(
              totalActiveProducts: 4,
              lowStockProducts: 1,
              stockChangesToday: 2,
            ),
          ),
          previewStream: Stream<List<DashboardLowStockPreviewItem>>.error(
            Exception('PRIVATE_SQL_FAILURE'),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('dashboard-low-stock-preview-error')),
        findsOneWidget,
      );
      expect(
        find.text("We couldn't load products that need restocking."),
        findsOneWidget,
      );
      expect(find.textContaining('PRIVATE_SQL_FAILURE'), findsNothing);
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
      repository: const _DashboardRepository(summaryStream: Stream.empty()),
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
        summaryStream: Stream<DashboardSummary>.error(
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
        summaryStream: Stream.value(
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
    expect(
      find.byKey(const Key('dashboard-low-stock-preview-section')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('dashboard-view-low-stock-action')),
      findsNothing,
    );
    expect(find.textContaining('login'), findsNothing);
    expect(find.textContaining('cloud'), findsNothing);
  });
}

Future<void> _pumpDashboardRouter(
  WidgetTester tester, {
  required DashboardRepository repository,
}) async {
  final router = GoRouter(
    initialLocation: AppRoute.dashboard.path,
    routes: [
      GoRoute(
        path: AppRoute.dashboard.path,
        builder: (_, _) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoute.products.path,
        builder: (_, _) => Consumer(
          builder: (context, ref, child) {
            final query = ref.watch(productListControllerProvider);
            return Scaffold(
              key: const Key('products-route-test-screen'),
              body: Text('filter: ${query.stockFilter.name}'),
            );
          },
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
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
  const _DashboardRepository({
    required this.summaryStream,
    this.previewStream,
  });

  final Stream<DashboardSummary> summaryStream;
  final Stream<List<DashboardLowStockPreviewItem>>? previewStream;

  @override
  Stream<DashboardSummary> watchSummary({required DateTime localNow}) {
    return summaryStream;
  }

  @override
  Stream<List<DashboardLowStockPreviewItem>> watchLowStockPreview({
    int limit = dashboardLowStockPreviewLimit,
  }) {
    return previewStream ?? Stream.value(const []);
  }
}
