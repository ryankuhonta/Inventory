import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Persistent shell for the four primary application sections.
class AppShell extends StatelessWidget {
  /// Creates the primary application shell.
  const AppShell({required this.navigationShell, super.key});

  /// Router-owned stateful branch shell.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final activeBranchCanPop =
        navigationShell
            .route
            .branches[navigationShell.currentIndex]
            .navigatorKey
            .currentState
            ?.canPop() ??
        false;

    return PopScope(
      canPop: activeBranchCanPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }

        if (navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
          return;
        }

        final shouldExit = await _confirmExit(context);
        if (shouldExit && context.mounted) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Products',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmExit(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Exit TindaTrack?'),
          content: const Text('Are you sure you want to close the app?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
