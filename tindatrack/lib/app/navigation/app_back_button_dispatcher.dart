import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tindatrack/app/navigation/product_child_back_handler.dart';
import 'package:tindatrack/app/router/app_routes.dart';

/// Handles Android system Back before the router can fall through to app exit.
class AppBackButtonDispatcher extends RootBackButtonDispatcher {
  /// Creates a back dispatcher for the app router.
  AppBackButtonDispatcher({
    required this.router,
    required this.navigatorKey,
    required this.productsNavigatorKey,
  });

  /// App-scoped router whose current location drives root back policy.
  final GoRouter router;

  /// Root navigator context used for exit confirmation.
  final GlobalKey<NavigatorState> navigatorKey;

  /// Navigator for the Products branch and its child flows.
  final GlobalKey<NavigatorState> productsNavigatorKey;

  bool _exitDialogOpen = false;

  @override
  Future<bool> didPopRoute() async {
    final childBackHandler = productChildBackRegistry.handler;
    if (childBackHandler != null) {
      unawaited(childBackHandler());
      return true;
    }

    final path = router.routeInformationProvider.value.uri.path;
    if (_isSecondaryRoute(path)) {
      await productsNavigatorKey.currentState?.maybePop();
      return true;
    }

    if (path != AppRoute.dashboard.path) {
      router.go(AppRoute.dashboard.path);
      return true;
    }

    unawaited(_confirmExitIfNeeded());
    return true;
  }

  bool _isSecondaryRoute(String path) {
    return path.startsWith('${AppRoute.products.path}/');
  }

  Future<void> _confirmExitIfNeeded() async {
    if (_exitDialogOpen) return;
    final context = navigatorKey.currentContext;
    if (context == null) return;

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

    if (shouldExit ?? false) {
      await SystemNavigator.pop();
    }
  }
}
