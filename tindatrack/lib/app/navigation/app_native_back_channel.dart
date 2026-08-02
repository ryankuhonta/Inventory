import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tindatrack/app/router/app_routes.dart';

/// Handles Android-native Back events sent by MainActivity.
class AppNativeBackChannel {
  /// Creates a native back channel bound to the app router.
  AppNativeBackChannel({required this.router, required this.navigatorKey});

  static const _channel = MethodChannel('tindatrack/navigation');
  static const _systemBackMethod = 'systemBack';
  static const _finishAppMethod = 'finishApp';

  /// App-scoped router whose current location drives root back policy.
  final GoRouter router;

  /// Root navigator context used for exit confirmation.
  final GlobalKey<NavigatorState> navigatorKey;

  bool _exitDialogOpen = false;

  /// Starts listening for Android-native back events.
  void attach() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Stops listening for Android-native back events.
  void detach() {
    _channel.setMethodCallHandler(null);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method != _systemBackMethod) return;
    await handleBack();
  }

  /// Applies the TindaTrack root back behavior.
  Future<void> handleBack() async {
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

    await _confirmExitIfNeeded();
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
      unawaited(_channel.invokeMethod<void>(_finishAppMethod));
    }
  }
}
