import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tindatrack/app/bootstrap.dart';
import 'package:tindatrack/app/providers.dart';
import 'package:tindatrack/app/router/app_router.dart';
import 'package:tindatrack/app/theme/app_theme.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/failure_message_mapper.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/core/widgets/app_error_view.dart';
import 'package:tindatrack/core/widgets/app_loading_view.dart';

/// Root widget for the TindaTrack application.
class MainApp extends ConsumerWidget {
  /// Creates the root TindaTrack application widget.
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'TindaTrack',
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) {
        return _LaunchGate(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

final class _LaunchGate extends ConsumerStatefulWidget {
  const _LaunchGate({required this.child});

  final Widget child;

  @override
  ConsumerState<_LaunchGate> createState() => _LaunchGateState();
}

final class _LaunchGateState extends ConsumerState<_LaunchGate> {
  var _isRetrying = false;

  @override
  Widget build(BuildContext context) {
    final bootstrap = ref.watch(bootstrapProvider);
    ref.listen(bootstrapProvider, (_, next) {
      if (_isRetrying && !next.isLoading && mounted) {
        setState(() => _isRetrying = false);
      }
    });

    return bootstrap.when(
      skipLoadingOnRefresh: false,
      loading: _SplashScreen.new,
      error: (_, _) => _InitializationFailure(
        failure: const UnexpectedFailure(),
        onRetry: _retry,
        isRetryEnabled: !_isRetrying,
      ),
      data: (result) => switch (result) {
        Success<void>() => widget.child,
        FailureResult<void>(:final failure) => _InitializationFailure(
          failure: failure,
          onRetry: _retry,
          isRetryEnabled: !_isRetrying,
        ),
      },
    );
  }

  Future<void> _retry() async {
    if (_isRetrying) return;

    setState(() => _isRetrying = true);
    try {
      final database = ref.read(databaseProvider);
      final closeDatabase = ref.read(databaseCloserProvider);
      await closeDatabase(database);
    } on Object {
      if (mounted) setState(() => _isRetrying = false);
      return;
    }
    if (!mounted) return;

    ref
      ..invalidate(databaseProvider)
      ..invalidate(bootstrapProvider);
  }
}

final class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AppLoadingView(
        title: 'TindaTrack',
        message: 'Offline inventory tracker',
        semanticsLabel: 'TindaTrack is loading',
      ),
    );
  }
}

final class _InitializationFailure extends StatelessWidget {
  const _InitializationFailure({
    required this.failure,
    required this.onRetry,
    required this.isRetryEnabled,
  });

  final AppFailure failure;
  final VoidCallback onRetry;
  final bool isRetryEnabled;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppErrorView(
        message: const FailureMessageMapper().toMessage(failure),
        actionLabel: 'Retry',
        onAction: onRetry,
        isActionEnabled: isRetryEnabled,
      ),
    );
  }
}
