import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tindatrack/app/navigation/app_shell.dart';
import 'package:tindatrack/app/router/app_routes.dart';
import 'package:tindatrack/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:tindatrack/features/history/presentation/screens/movement_history_screen.dart';
import 'package:tindatrack/features/products/presentation/screens/product_list_screen.dart';
import 'package:tindatrack/features/settings/presentation/screens/settings_screen.dart';

/// Builder used to supply a branch root screen.
typedef AppRouteBuilder =
    Widget Function(
      BuildContext context,
      GoRouterState state,
    );

/// App-scoped router that remains stable across bootstrap and tab changes.
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = createAppRouter();
  ref.onDispose(router.dispose);
  return router;
});

/// Creates the four-branch application router.
GoRouter createAppRouter({
  String? initialLocation,
  AppRouteBuilder dashboardBuilder = _buildDashboard,
  AppRouteBuilder productsBuilder = _buildProducts,
  AppRouteBuilder historyBuilder = _buildHistory,
  AppRouteBuilder settingsBuilder = _buildSettings,
}) {
  final branchNavigatorKeys = List.generate(
    AppRoute.values.length,
    (index) => GlobalKey<NavigatorState>(
      debugLabel: '${AppRoute.values[index].name}BranchNavigator',
    ),
  );

  return GoRouter(
    initialLocation: initialLocation ?? AppRoute.dashboard.path,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          _branch(
            route: AppRoute.dashboard,
            navigatorKey: branchNavigatorKeys[0],
            builder: dashboardBuilder,
          ),
          _branch(
            route: AppRoute.products,
            navigatorKey: branchNavigatorKeys[1],
            builder: productsBuilder,
          ),
          _branch(
            route: AppRoute.history,
            navigatorKey: branchNavigatorKeys[2],
            builder: historyBuilder,
          ),
          _branch(
            route: AppRoute.settings,
            navigatorKey: branchNavigatorKeys[3],
            builder: settingsBuilder,
          ),
        ],
      ),
    ],
  );
}

StatefulShellBranch _branch({
  required AppRoute route,
  required GlobalKey<NavigatorState> navigatorKey,
  required AppRouteBuilder builder,
}) {
  return StatefulShellBranch(
    navigatorKey: navigatorKey,
    routes: [
      GoRoute(
        path: route.path,
        name: route.name,
        builder: builder,
      ),
    ],
  );
}

Widget _buildDashboard(BuildContext context, GoRouterState state) {
  return const DashboardScreen();
}

Widget _buildProducts(BuildContext context, GoRouterState state) {
  return const ProductListScreen();
}

Widget _buildHistory(BuildContext context, GoRouterState state) {
  return const MovementHistoryScreen();
}

Widget _buildSettings(BuildContext context, GoRouterState state) {
  return const SettingsScreen();
}
