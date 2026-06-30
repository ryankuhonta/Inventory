import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tindatrack/app/app.dart';
import 'package:tindatrack/app/bootstrap.dart';
import 'package:tindatrack/app/providers.dart';
import 'package:tindatrack/app/router/app_router.dart';
import 'package:tindatrack/app/router/app_routes.dart';
import 'package:tindatrack/app/theme/app_colors.dart';
import 'package:tindatrack/core/database/app_database.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/core/widgets/app_error_view.dart';
import 'package:tindatrack/core/widgets/app_loading_view.dart';
import 'package:tindatrack/features/products/presentation/providers/product_providers.dart';

void main() {
  testWidgets('shows the lightweight splash while bootstrap is pending', (
    tester,
  ) async {
    final pending = Completer<Result<void>>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootstrapProvider.overrideWith((ref) => pending.future),
        ],
        child: const MainApp(),
      ),
    );

    expect(find.text('TindaTrack'), findsOneWidget);
    expect(find.text('Offline inventory tracker'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('shows the minimal Dashboard after bootstrap succeeds', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootstrapProvider.overrideWith(
            (ref) async => const Success<void>(null),
          ),
        ],
        child: const MainApp(),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('dashboard-screen')), findsOneWidget);
    expect(find.text('Offline inventory tracker'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });

  testWidgets('shows safe recovery copy without raw technical details', (
    tester,
  ) async {
    const rawError = 'SQLITE_CANTOPEN /private/inventory.sqlite';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootstrapProvider.overrideWith(
            (ref) async => const FailureResult<void>(
              PersistenceFailure(debugMessage: rawError),
            ),
          ),
        ],
        child: const MainApp(),
      ),
    );
    await tester.pump();

    expect(
      find.text("We couldn't access your saved data. Please try again."),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining(rawError), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    for (final route in AppRoute.values) {
      expect(find.byKey(Key('${route.name}-screen')), findsNothing);
    }
  });

  testWidgets('retry reruns bootstrap and can recover to Dashboard', (
    tester,
  ) async {
    var attempts = 0;
    final retryCompleter = Completer<Result<void>>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith((ref) {
            return createManagedDatabase(ref, _ReadyDatabase.new);
          }),
          bootstrapProvider.overrideWith((ref) {
            attempts++;
            if (attempts == 1) {
              return Future.value(
                const FailureResult<void>(PersistenceFailure()),
              );
            }
            return retryCompleter.future;
          }),
        ],
        child: const MainApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(attempts, 2);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    retryCompleter.complete(const Success<void>(null));
    await tester.pump();

    expect(find.byKey(const Key('dashboard-screen')), findsOneWidget);
  });

  testWidgets('a failed retry enables Retry again', (tester) async {
    var attempts = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith((ref) {
            return createManagedDatabase(ref, _ReadyDatabase.new);
          }),
          bootstrapProvider.overrideWith((ref) async {
            attempts++;
            return const FailureResult<void>(PersistenceFailure());
          }),
        ],
        child: const MainApp(),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    final retryButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Retry'),
    );
    expect(retryButton.onPressed, isNotNull);
  });

  testWidgets('retry creates a fresh database after an open failure', (
    tester,
  ) async {
    var databaseCreations = 0;
    final closeCompleter = Completer<void>();
    late _FailingDatabase failedDatabase;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith((ref) {
            databaseCreations++;
            return createManagedDatabase(
              ref,
              databaseCreations == 1
                  ? () => failedDatabase = _FailingDatabase(closeCompleter)
                  : _ReadyDatabase.new,
            );
          }),
        ],
        child: const MainApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(databaseCreations, 1);
    expect(failedDatabase.closeCalls, 1);
    expect(find.byType(FilledButton), findsOneWidget);

    closeCompleter.complete();
    await tester.pumpAndSettle();

    expect(failedDatabase.closeCompleted, isTrue);
    expect(databaseCreations, 2);
    expect(find.byKey(const Key('dashboard-screen')), findsOneWidget);
  });

  testWidgets('tab changes do not rerun bootstrap or recreate dependencies', (
    tester,
  ) async {
    var bootstrapAttempts = 0;
    var databaseCreations = 0;
    var routerCreations = 0;
    late _TrackingDatabase database;
    late GoRouter router;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appRouterProvider.overrideWith((ref) {
            routerCreations++;
            router = createAppRouter();
            ref.onDispose(router.dispose);
            return router;
          }),
          databaseProvider.overrideWith((ref) {
            databaseCreations++;
            return createManagedDatabase(
              ref,
              () => database = _TrackingDatabase(),
            );
          }),
          bootstrapProvider.overrideWith((ref) async {
            bootstrapAttempts++;
            await ref.read(databaseProvider).ensureReady();
            return const Success<void>(null);
          }),
          activeProductsProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
        ],
        child: const MainApp(),
      ),
    );
    await tester.pumpAndSettle();

    for (final route in AppRoute.values.skip(1)) {
      await tester.tap(_navigationLabel(route.label));
      await tester.pumpAndSettle();
    }
    await tester.tap(_navigationLabel(AppRoute.settings.label));
    await tester.pumpAndSettle();

    expect(bootstrapAttempts, 1);
    expect(databaseCreations, 1);
    expect(routerCreations, 1);
    expect(database.closeCalls, 0);
    expect(router.routeInformationProvider.value.uri.path, '/settings');
  });

  testWidgets(
    'Android Back keeps default root behavior and '
    'app lifecycles stable',
    (tester) async {
      var bootstrapAttempts = 0;
      var databaseCreations = 0;
      var routerCreations = 0;
      late _TrackingDatabase database;
      late GoRouter router;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appRouterProvider.overrideWith((ref) {
              routerCreations++;
              router = createAppRouter();
              ref.onDispose(router.dispose);
              return router;
            }),
            databaseProvider.overrideWith((ref) {
              databaseCreations++;
              return createManagedDatabase(
                ref,
                () => database = _TrackingDatabase(),
              );
            }),
            bootstrapProvider.overrideWith((ref) async {
              bootstrapAttempts++;
              await ref.read(databaseProvider).ensureReady();
              return const Success<void>(null);
            }),
            activeProductsProvider.overrideWith(
              (ref) => Stream.value(const []),
            ),
          ],
          child: const MainApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(_navigationLabel(AppRoute.products.label));
      await tester.pumpAndSettle();
      final routerBeforeBack = router;

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/products');
      expect(identical(router, routerBeforeBack), isTrue);
      expect(bootstrapAttempts, 1);
      expect(databaseCreations, 1);
      expect(routerCreations, 1);
      expect(database.closeCalls, 0);
    },
  );
  testWidgets('root theme reaches launch, failure, and shell descendants', (
    tester,
  ) async {
    final pending = Completer<Result<void>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [bootstrapProvider.overrideWith((ref) => pending.future)],
        child: const MainApp(),
      ),
    );

    expect(find.byType(AppLoadingView), findsOneWidget);
    var theme = Theme.of(tester.element(find.byType(AppLoadingView)));
    expect(theme.useMaterial3, isTrue);
    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.colorScheme.primary, AppColors.primary);

    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          bootstrapProvider.overrideWith(
            (ref) async => const FailureResult<void>(PersistenceFailure()),
          ),
        ],
        child: const MainApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(AppErrorView), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(
      tester.getSize(find.widgetWithText(FilledButton, 'Retry')).height,
      greaterThanOrEqualTo(48),
    );

    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          bootstrapProvider.overrideWith(
            (ref) async => const Success<void>(null),
          ),
        ],
        child: const MainApp(),
      ),
    );
    await tester.pumpAndSettle();

    theme = Theme.of(tester.element(find.byKey(const Key('dashboard-screen'))));
    expect(theme.colorScheme.onSurface, AppColors.textPrimary);
    expect(find.byType(NavigationBar), findsOneWidget);
    for (final route in AppRoute.values) {
      final destination = find.widgetWithText(
        NavigationDestination,
        route.label,
      );
      expect(destination, findsOneWidget);
      expect(tester.getSize(destination).height, greaterThanOrEqualTo(48));
    }
    final semantics = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    semantics.dispose();
  });

  testWidgets('themed branch roots fit a small phone with enlarged text', (
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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootstrapProvider.overrideWith(
            (ref) async => const Success<void>(null),
          ),
          activeProductsProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
        ],
        child: const MainApp(),
      ),
    );
    await tester.pumpAndSettle();

    for (final route in AppRoute.values) {
      await tester.tap(_navigationLabel(route.label));
      await tester.pumpAndSettle();
      expect(find.byKey(Key('${route.name}-screen')), findsOneWidget);
      expect(
        MediaQuery.textScalerOf(
          tester.element(find.byKey(Key('${route.name}-screen'))),
        ).scale(14),
        28,
      );
      expect(tester.takeException(), isNull);
    }
  });
}

Finder _navigationLabel(String label) {
  return find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );
}

final class _FailingDatabase extends AppDatabase {
  _FailingDatabase(this.closeGate) : super(NativeDatabase.memory());

  final Completer<void> closeGate;
  int closeCalls = 0;
  bool closeCompleted = false;

  @override
  Future<void> ensureReady() {
    return Future<void>.error(Exception('SQLITE_CANTOPEN technical detail'));
  }

  @override
  Future<void> close() async {
    closeCalls++;
    await closeGate.future;
    await super.close();
    closeCompleted = true;
  }
}

final class _ReadyDatabase extends AppDatabase {
  _ReadyDatabase() : super(NativeDatabase.memory());
}

final class _TrackingDatabase extends AppDatabase {
  _TrackingDatabase() : super(NativeDatabase.memory());

  int closeCalls = 0;

  @override
  Future<void> close() {
    closeCalls++;
    return super.close();
  }
}
