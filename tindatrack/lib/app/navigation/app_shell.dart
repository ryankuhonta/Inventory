import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tindatrack/app/router/app_routes.dart';

/// Persistent shell for the four primary application sections.
class AppShell extends StatefulWidget {
  /// Creates the primary application shell.
  const AppShell({required this.navigationShell, super.key});

  /// Router-owned stateful branch shell.
  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _exitDialogOpen = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
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
              icon: Icon(Icons.info_outline),
              selectedIcon: Icon(Icons.info),
              label: 'App Info',
            ),
          ],
        ),
      ),
    );
  }

  void _handleBack() {
    final router = GoRouter.of(context);
    final path = router.routeInformationProvider.value.uri.path;

    if (path.startsWith('${AppRoute.products.path}/')) {
      if (router.canPop()) {
        router.pop();
        return;
      }
      router.go(AppRoute.products.path);
      return;
    }

    if (path != AppRoute.dashboard.path) {
      router.go(AppRoute.dashboard.path);
      return;
    }

    unawaited(_confirmExit());
  }

  Future<void> _confirmExit() async {
    if (_exitDialogOpen || !mounted) return;

    _exitDialogOpen = true;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Exit TindaTrack?'),
          content: const Text('Are you sure you want to close the app?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
    _exitDialogOpen = false;

    if ((shouldExit ?? false) && mounted) {
      await SystemNavigator.pop();
    }
  }
}
