# Blind Hunter Review Prompt

Use the bmad-review-adversarial-general skill. Review only the unified diff below. You have no project context or repository access. Return Markdown findings; each finding needs a concise title, severity, file/line evidence, and impact. Return an explicit 'No findings' if applicable.

## Diff

~~~diff
diff --git a/_bmad-output/implementation-artifacts/sprint-status.yaml b/_bmad-output/implementation-artifacts/sprint-status.yaml
index bda8da8..5f016a7 100644
--- a/_bmad-output/implementation-artifacts/sprint-status.yaml
+++ b/_bmad-output/implementation-artifacts/sprint-status.yaml
@@ -1,5 +1,5 @@
 # generated: 2026-06-01
-# last_updated: 2026-06-20
+# last_updated: 2026-06-27
 # project: Inventory
 # project_key: NOKEY
 # tracking_system: file-system
@@ -35,7 +35,7 @@
 # - Dev moves story to 'review', then runs code-review (fresh context, different LLM recommended)
 
 generated: 2026-06-01
-last_updated: 2026-06-20
+last_updated: 2026-06-27
 project: Inventory
 project_key: NOKEY
 tracking_system: file-system
@@ -45,9 +45,9 @@ development_status:
   epic-1: in-progress
   1-1-set-up-initial-project-from-flutter-empty-starter-template: done
   1-2-establish-app-architecture-and-local-core-services: done
-  1-3-provide-offline-app-launch-and-splash-initialization: backlog
-  1-4-add-main-navigation-shell: backlog
-  1-5-apply-mvp-theme-and-base-ui-states: backlog
+  1-3-provide-offline-app-launch-and-splash-initialization: done
+  1-4-add-main-navigation-shell: done
+  1-5-apply-mvp-theme-and-base-ui-states: review
   epic-1-retrospective: optional
 
   epic-2: backlog
diff --git a/tindatrack/lib/app/app.dart b/tindatrack/lib/app/app.dart
index 6c91bde..8bb8130 100644
--- a/tindatrack/lib/app/app.dart
+++ b/tindatrack/lib/app/app.dart
@@ -1,26 +1,129 @@
 import 'package:flutter/material.dart';
+import 'package:flutter_riverpod/flutter_riverpod.dart';
+import 'package:tindatrack/app/bootstrap.dart';
+import 'package:tindatrack/app/providers.dart';
+import 'package:tindatrack/app/router/app_router.dart';
+import 'package:tindatrack/app/theme/app_theme.dart';
+import 'package:tindatrack/core/errors/app_failure.dart';
+import 'package:tindatrack/core/errors/failure_message_mapper.dart';
+import 'package:tindatrack/core/errors/result.dart';
+import 'package:tindatrack/core/widgets/app_error_view.dart';
+import 'package:tindatrack/core/widgets/app_loading_view.dart';
 
 /// Root widget for the TindaTrack application.
-class MainApp extends StatelessWidget {
+class MainApp extends ConsumerWidget {
   /// Creates the root TindaTrack application widget.
   const MainApp({super.key});
 
   @override
-  Widget build(BuildContext context) {
-    return const MaterialApp(
+  Widget build(BuildContext context, WidgetRef ref) {
+    final router = ref.watch(appRouterProvider);
+
+    return MaterialApp.router(
       debugShowCheckedModeBanner: false,
       title: 'TindaTrack',
-      home: Scaffold(
-        body: Center(
-          child: Column(
-            mainAxisSize: MainAxisSize.min,
-            children: [
-              Text('TindaTrack'),
-              SizedBox(height: 8),
-              Text('Offline inventory tracker'),
-            ],
-          ),
+      theme: AppTheme.light,
+      routerConfig: router,
+      builder: (context, child) {
+        return _LaunchGate(child: child ?? const SizedBox.shrink());
+      },
+    );
+  }
+}
+
+final class _LaunchGate extends ConsumerStatefulWidget {
+  const _LaunchGate({required this.child});
+
+  final Widget child;
+
+  @override
+  ConsumerState<_LaunchGate> createState() => _LaunchGateState();
+}
+
+final class _LaunchGateState extends ConsumerState<_LaunchGate> {
+  var _isRetrying = false;
+
+  @override
+  Widget build(BuildContext context) {
+    final bootstrap = ref.watch(bootstrapProvider);
+    ref.listen(bootstrapProvider, (_, next) {
+      if (_isRetrying && !next.isLoading && mounted) {
+        setState(() => _isRetrying = false);
+      }
+    });
+
+    return bootstrap.when(
+      skipLoadingOnRefresh: false,
+      loading: _SplashScreen.new,
+      error: (_, _) => _InitializationFailure(
+        failure: const UnexpectedFailure(),
+        onRetry: _retry,
+        isRetryEnabled: !_isRetrying,
+      ),
+      data: (result) => switch (result) {
+        Success<void>() => widget.child,
+        FailureResult<void>(:final failure) => _InitializationFailure(
+          failure: failure,
+          onRetry: _retry,
+          isRetryEnabled: !_isRetrying,
         ),
+      },
+    );
+  }
+
+  Future<void> _retry() async {
+    if (_isRetrying) return;
+
+    setState(() => _isRetrying = true);
+    final database = ref.read(databaseProvider);
+    try {
+      await closeManagedDatabase(database);
+    } on Exception {
+      if (mounted) setState(() => _isRetrying = false);
+      return;
+    }
+    if (!mounted) return;
+
+    ref
+      ..invalidate(databaseProvider)
+      ..invalidate(bootstrapProvider);
+  }
+}
+
+final class _SplashScreen extends StatelessWidget {
+  const _SplashScreen();
+
+  @override
+  Widget build(BuildContext context) {
+    return const Scaffold(
+      body: AppLoadingView(
+        title: 'TindaTrack',
+        message: 'Offline inventory tracker',
+        semanticsLabel: 'TindaTrack is loading',
+      ),
+    );
+  }
+}
+
+final class _InitializationFailure extends StatelessWidget {
+  const _InitializationFailure({
+    required this.failure,
+    required this.onRetry,
+    required this.isRetryEnabled,
+  });
+
+  final AppFailure failure;
+  final VoidCallback onRetry;
+  final bool isRetryEnabled;
+
+  @override
+  Widget build(BuildContext context) {
+    return Scaffold(
+      body: AppErrorView(
+        message: const FailureMessageMapper().toMessage(failure),
+        actionLabel: 'Retry',
+        onAction: onRetry,
+        isActionEnabled: isRetryEnabled,
       ),
     );
   }
diff --git a/tindatrack/test/widget_test.dart b/tindatrack/test/widget_test.dart
index c73baf5..bb6ca47 100644
--- a/tindatrack/test/widget_test.dart
+++ b/tindatrack/test/widget_test.dart
@@ -1,12 +1,451 @@
-import 'package:flutter_riverpod/flutter_riverpod.dart';
-import 'package:flutter_test/flutter_test.dart';
-import 'package:tindatrack/app/app.dart';
-
-void main() {
-  testWidgets('renders the offline starter screen', (tester) async {
-    await tester.pumpWidget(const ProviderScope(child: MainApp()));
-
-    expect(find.text('TindaTrack'), findsOneWidget);
-    expect(find.text('Offline inventory tracker'), findsOneWidget);
-  });
-}
+import 'dart:async';
+import 'package:drift/native.dart';
+import 'package:flutter/material.dart';
+import 'package:flutter_riverpod/flutter_riverpod.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:go_router/go_router.dart';
+import 'package:tindatrack/app/app.dart';
+import 'package:tindatrack/app/bootstrap.dart';
+import 'package:tindatrack/app/providers.dart';
+import 'package:tindatrack/app/router/app_router.dart';
+import 'package:tindatrack/app/router/app_routes.dart';
+import 'package:tindatrack/app/theme/app_colors.dart';
+import 'package:tindatrack/core/database/app_database.dart';
+import 'package:tindatrack/core/errors/app_failure.dart';
+import 'package:tindatrack/core/errors/result.dart';
+import 'package:tindatrack/core/widgets/app_error_view.dart';
+import 'package:tindatrack/core/widgets/app_loading_view.dart';
+
+void main() {
+  testWidgets('shows the lightweight splash while bootstrap is pending', (
+    tester,
+  ) async {
+    final pending = Completer<Result<void>>();
+
+    await tester.pumpWidget(
+      ProviderScope(
+        overrides: [
+          bootstrapProvider.overrideWith((ref) => pending.future),
+        ],
+        child: const MainApp(),
+      ),
+    );
+
+    expect(find.text('TindaTrack'), findsOneWidget);
+    expect(find.text('Offline inventory tracker'), findsOneWidget);
+    expect(find.byType(CircularProgressIndicator), findsOneWidget);
+    expect(find.text('Dashboard'), findsNothing);
+    expect(find.byType(NavigationBar), findsNothing);
+  });
+
+  testWidgets('shows the minimal Dashboard after bootstrap succeeds', (
+    tester,
+  ) async {
+    await tester.pumpWidget(
+      ProviderScope(
+        overrides: [
+          bootstrapProvider.overrideWith(
+            (ref) async => const Success<void>(null),
+          ),
+        ],
+        child: const MainApp(),
+      ),
+    );
+    await tester.pump();
+
+    expect(find.byKey(const Key('dashboard-screen')), findsOneWidget);
+    expect(find.text('Offline inventory tracker'), findsOneWidget);
+    expect(find.byType(CircularProgressIndicator), findsNothing);
+    expect(find.byType(NavigationBar), findsOneWidget);
+    expect(
+      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
+      0,
+    );
+  });
+
+  testWidgets('shows safe recovery copy without raw technical details', (
+    tester,
+  ) async {
+    const rawError = 'SQLITE_CANTOPEN /private/inventory.sqlite';
+
+    await tester.pumpWidget(
+      ProviderScope(
+        overrides: [
+          bootstrapProvider.overrideWith(
+            (ref) async => const FailureResult<void>(
+              PersistenceFailure(debugMessage: rawError),
+            ),
+          ),
+        ],
+        child: const MainApp(),
+      ),
+    );
+    await tester.pump();
+
+    expect(
+      find.text("We couldn't access your saved data. Please try again."),
+      findsOneWidget,
+    );
+    expect(find.text('Retry'), findsOneWidget);
+    expect(find.textContaining(rawError), findsNothing);
+    expect(find.byType(NavigationBar), findsNothing);
+    for (final route in AppRoute.values) {
+      expect(find.byKey(Key('${route.name}-screen')), findsNothing);
+    }
+  });
+
+  testWidgets('retry reruns bootstrap and can recover to Dashboard', (
+    tester,
+  ) async {
+    var attempts = 0;
+    final retryCompleter = Completer<Result<void>>();
+
+    await tester.pumpWidget(
+      ProviderScope(
+        overrides: [
+          databaseProvider.overrideWith((ref) {
+            return createManagedDatabase(ref, _ReadyDatabase.new);
+          }),
+          bootstrapProvider.overrideWith((ref) {
+            attempts++;
+            if (attempts == 1) {
+              return Future.value(
+                const FailureResult<void>(PersistenceFailure()),
+              );
+            }
+            return retryCompleter.future;
+          }),
+        ],
+        child: const MainApp(),
+      ),
+    );
+    await tester.pump();
+
+    expect(find.text('Retry'), findsOneWidget);
+
+    await tester.tap(find.text('Retry'));
+    await tester.pump();
+    await tester.pump();
+
+    expect(attempts, 2);
+    expect(find.byType(CircularProgressIndicator), findsOneWidget);
+
+    retryCompleter.complete(const Success<void>(null));
+    await tester.pump();
+
+    expect(find.byKey(const Key('dashboard-screen')), findsOneWidget);
+  });
+
+  testWidgets('a failed retry enables Retry again', (tester) async {
+    var attempts = 0;
+
+    await tester.pumpWidget(
+      ProviderScope(
+        overrides: [
+          databaseProvider.overrideWith((ref) {
+            return createManagedDatabase(ref, _ReadyDatabase.new);
+          }),
+          bootstrapProvider.overrideWith((ref) async {
+            attempts++;
+            return const FailureResult<void>(PersistenceFailure());
+          }),
+        ],
+        child: const MainApp(),
+      ),
+    );
+    await tester.pump();
+
+    await tester.tap(find.text('Retry'));
+    await tester.pumpAndSettle();
+
+    expect(attempts, 2);
+    final retryButton = tester.widget<FilledButton>(
+      find.widgetWithText(FilledButton, 'Retry'),
+    );
+    expect(retryButton.onPressed, isNotNull);
+  });
+
+  testWidgets('retry creates a fresh database after an open failure', (
+    tester,
+  ) async {
+    var databaseCreations = 0;
+    final closeCompleter = Completer<void>();
+    late _FailingDatabase failedDatabase;
+
+    await tester.pumpWidget(
+      ProviderScope(
+        overrides: [
+          databaseProvider.overrideWith((ref) {
+            databaseCreations++;
+            return createManagedDatabase(
+              ref,
+              databaseCreations == 1
+                  ? () => failedDatabase = _FailingDatabase(closeCompleter)
+                  : _ReadyDatabase.new,
+            );
+          }),
+        ],
+        child: const MainApp(),
+      ),
+    );
+    await tester.pumpAndSettle();
+
+    expect(find.text('Retry'), findsOneWidget);
+
+    await tester.tap(find.text('Retry'));
+    await tester.tap(find.text('Retry'));
+    await tester.pump();
+
+    expect(databaseCreations, 1);
+    expect(failedDatabase.closeCalls, 1);
+    expect(find.byType(FilledButton), findsOneWidget);
+
+    closeCompleter.complete();
+    await tester.pumpAndSettle();
+
+    expect(failedDatabase.closeCompleted, isTrue);
+    expect(databaseCreations, 2);
+    expect(find.byKey(const Key('dashboard-screen')), findsOneWidget);
+  });
+
+  testWidgets('tab changes do not rerun bootstrap or recreate dependencies', (
+    tester,
+  ) async {
+    var bootstrapAttempts = 0;
+    var databaseCreations = 0;
+    var routerCreations = 0;
+    late _TrackingDatabase database;
+    late GoRouter router;
+
+    await tester.pumpWidget(
+      ProviderScope(
+        overrides: [
+          appRouterProvider.overrideWith((ref) {
+            routerCreations++;
+            router = createAppRouter();
+            ref.onDispose(router.dispose);
+            return router;
+          }),
+          databaseProvider.overrideWith((ref) {
+            databaseCreations++;
+            return createManagedDatabase(
+              ref,
+              () => database = _TrackingDatabase(),
+            );
+          }),
+          bootstrapProvider.overrideWith((ref) async {
+            bootstrapAttempts++;
+            await ref.read(databaseProvider).ensureReady();
+            return const Success<void>(null);
+          }),
+        ],
+        child: const MainApp(),
+      ),
+    );
+    await tester.pumpAndSettle();
+
+    for (final route in AppRoute.values.skip(1)) {
+      await tester.tap(_navigationLabel(route.label));
+      await tester.pumpAndSettle();
+    }
+    await tester.tap(_navigationLabel(AppRoute.settings.label));
+    await tester.pumpAndSettle();
+
+    expect(bootstrapAttempts, 1);
+    expect(databaseCreations, 1);
+    expect(routerCreations, 1);
+    expect(database.closeCalls, 0);
+    expect(router.routeInformationProvider.value.uri.path, '/settings');
+  });
+
+  testWidgets(
+    'Android Back keeps default root behavior and '
+    'app lifecycles stable',
+    (tester) async {
+      var bootstrapAttempts = 0;
+      var databaseCreations = 0;
+      var routerCreations = 0;
+      late _TrackingDatabase database;
+      late GoRouter router;
+
+      await tester.pumpWidget(
+        ProviderScope(
+          overrides: [
+            appRouterProvider.overrideWith((ref) {
+              routerCreations++;
+              router = createAppRouter();
+              ref.onDispose(router.dispose);
+              return router;
+            }),
+            databaseProvider.overrideWith((ref) {
+              databaseCreations++;
+              return createManagedDatabase(
+                ref,
+                () => database = _TrackingDatabase(),
+              );
+            }),
+            bootstrapProvider.overrideWith((ref) async {
+              bootstrapAttempts++;
+              await ref.read(databaseProvider).ensureReady();
+              return const Success<void>(null);
+            }),
+          ],
+          child: const MainApp(),
+        ),
+      );
+      await tester.pumpAndSettle();
+
+      await tester.tap(_navigationLabel(AppRoute.products.label));
+      await tester.pumpAndSettle();
+      final routerBeforeBack = router;
+
+      await tester.binding.handlePopRoute();
+      await tester.pumpAndSettle();
+
+      expect(router.routeInformationProvider.value.uri.path, '/products');
+      expect(identical(router, routerBeforeBack), isTrue);
+      expect(bootstrapAttempts, 1);
+      expect(databaseCreations, 1);
+      expect(routerCreations, 1);
+      expect(database.closeCalls, 0);
+    },
+  );
+  testWidgets('root theme reaches launch, failure, and shell descendants', (
+    tester,
+  ) async {
+    final pending = Completer<Result<void>>();
+    await tester.pumpWidget(
+      ProviderScope(
+        overrides: [bootstrapProvider.overrideWith((ref) => pending.future)],
+        child: const MainApp(),
+      ),
+    );
+
+    expect(find.byType(AppLoadingView), findsOneWidget);
+    var theme = Theme.of(tester.element(find.byType(AppLoadingView)));
+    expect(theme.useMaterial3, isTrue);
+    expect(theme.scaffoldBackgroundColor, AppColors.background);
+    expect(theme.colorScheme.primary, AppColors.primary);
+
+    await tester.pumpWidget(
+      ProviderScope(
+        key: UniqueKey(),
+        overrides: [
+          bootstrapProvider.overrideWith(
+            (ref) async => const FailureResult<void>(PersistenceFailure()),
+          ),
+        ],
+        child: const MainApp(),
+      ),
+    );
+    await tester.pump();
+
+    expect(find.byType(AppErrorView), findsOneWidget);
+    expect(find.byIcon(Icons.error_outline), findsOneWidget);
+    expect(
+      tester.getSize(find.widgetWithText(FilledButton, 'Retry')).height,
+      greaterThanOrEqualTo(48),
+    );
+
+    await tester.pumpWidget(
+      ProviderScope(
+        key: UniqueKey(),
+        overrides: [
+          bootstrapProvider.overrideWith(
+            (ref) async => const Success<void>(null),
+          ),
+        ],
+        child: const MainApp(),
+      ),
+    );
+    await tester.pumpAndSettle();
+
+    theme = Theme.of(tester.element(find.byKey(const Key('dashboard-screen'))));
+    expect(theme.colorScheme.onSurface, AppColors.textPrimary);
+    expect(find.byType(NavigationBar), findsOneWidget);
+    for (final route in AppRoute.values) {
+      final destination = find.widgetWithText(
+        NavigationDestination,
+        route.label,
+      );
+      expect(destination, findsOneWidget);
+      expect(tester.getSize(destination).height, greaterThanOrEqualTo(48));
+    }
+  });
+
+  testWidgets('themed branch roots fit a small phone with enlarged text', (
+    tester,
+  ) async {
+    tester.view
+      ..physicalSize = const Size(360, 640)
+      ..devicePixelRatio = 1;
+    addTearDown(tester.view.resetPhysicalSize);
+    addTearDown(tester.view.resetDevicePixelRatio);
+
+    await tester.pumpWidget(
+      MediaQuery(
+        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
+        child: ProviderScope(
+          overrides: [
+            bootstrapProvider.overrideWith(
+              (ref) async => const Success<void>(null),
+            ),
+          ],
+          child: const MainApp(),
+        ),
+      ),
+    );
+    await tester.pumpAndSettle();
+
+    for (final route in AppRoute.values) {
+      await tester.tap(_navigationLabel(route.label));
+      await tester.pumpAndSettle();
+      expect(find.byKey(Key('${route.name}-screen')), findsOneWidget);
+      expect(tester.takeException(), isNull);
+    }
+  });
+}
+
+Finder _navigationLabel(String label) {
+  return find.descendant(
+    of: find.byType(NavigationBar),
+    matching: find.text(label),
+  );
+}
+
+final class _FailingDatabase extends AppDatabase {
+  _FailingDatabase(this.closeGate) : super(NativeDatabase.memory());
+
+  final Completer<void> closeGate;
+  int closeCalls = 0;
+  bool closeCompleted = false;
+
+  @override
+  Future<void> ensureReady() {
+    return Future<void>.error(Exception('SQLITE_CANTOPEN technical detail'));
+  }
+
+  @override
+  Future<void> close() async {
+    closeCalls++;
+    await closeGate.future;
+    await super.close();
+    closeCompleted = true;
+  }
+}
+
+final class _ReadyDatabase extends AppDatabase {
+  _ReadyDatabase() : super(NativeDatabase.memory());
+}
+
+final class _TrackingDatabase extends AppDatabase {
+  _TrackingDatabase() : super(NativeDatabase.memory());
+
+  int closeCalls = 0;
+
+  @override
+  Future<void> close() {
+    closeCalls++;
+    return super.close();
+  }
+}
diff --git a/_bmad-output/implementation-artifacts/1-5-apply-mvp-theme-and-base-ui-states.md b/_bmad-output/implementation-artifacts/1-5-apply-mvp-theme-and-base-ui-states.md
new file mode 100644
index 0000000..7e16738
--- /dev/null
+++ b/_bmad-output/implementation-artifacts/1-5-apply-mvp-theme-and-base-ui-states.md
@@ -0,0 +1,401 @@
+---
+baseline_commit: eb878cb81f8039bdd0fe175a53716baf37de2ece
+---
+
+# Story 1.5: Apply MVP Theme And Base UI States
+
+Status: review
+
+<!-- Note: Validation is optional. Run validate-create-story for an independent readiness check before dev-story. -->
+
+## Story
+
+As a store owner or helper,
+I want the app to be readable and easy to tap,
+so that I can use it comfortably on a small Android phone.
+
+## Acceptance Criteria
+
+1. **Given** the root app theme is configured  
+   **When** the launch states, navigation shell, and four main placeholder screens render  
+   **Then** the single `MaterialApp.router` uses a light Flutter Material 3 theme built from the approved color, typography, spacing, radius, and tap-target tokens  
+   **And** the visual style is practical, readable, minimally elevated, and uncluttered.
+
+2. **Given** the approved design tokens are inspected  
+   **When** the theme and token files are reviewed  
+   **Then** they expose the exact colors `#F8FAF7`, `#FFFFFF`, `#EEF3EE`, `#172018`, `#5E6B60`, `#2E7D4F`, `#24643F`, `#B7791F`, `#FFF7E0`, `#B42318`, `#FDECEC`, and `#DDE5DD` with their documented semantic roles  
+   **And** typography uses system/Roboto-compatible `28/700`, `20/700`, `16/700`, `14/400`, and `12/600` styles, spacing uses `4/8/16/24/32`, and radii use `6/8/12`.
+
+3. **Given** a screen needs loading, empty, or error feedback  
+   **When** `AppLoadingView`, `AppEmptyState`, or `AppErrorView` is shown  
+   **Then** it presents a lightweight, reusable, centered state using plain Filipino-friendly English  
+   **And** empty/error states support a clear optional next-step action without owning navigation or business logic.
+
+4. **Given** an initialization or data failure is displayed  
+   **When** `AppErrorView` renders safe mapped copy  
+   **Then** it communicates error meaning with visible text and an icon or equivalent non-color cue  
+   **And** its API accepts no throwable, stack-trace, failure, or diagnostic-detail parameter; every failure call site maps its typed failure to safe display copy before constructing the view, with tests proving raw debug details are absent.
+
+5. **Given** common navigation and action controls render on an Android phone  
+   **When** accessibility checks run at normal and enlarged system text scales  
+   **Then** applicable tap targets meet the 48dp Android floor, controls retain useful semantic labels, and the tested state layouts do not overflow on a small portrait viewport  
+   **And** warnings or errors are never communicated by color alone.
+
+6. **Given** Story 1.5 implementation is complete  
+   **When** quality verification runs  
+   **Then** focused theme/state/accessibility tests, all 30 existing bootstrap/navigation/lifecycle regressions, strict formatting, Flutter analysis, and an Android debug build pass  
+   **And** no dependency, asset, route, permission, database schema, DAO, migration, generated database, or feature behavior is added.
+
+## Tasks / Subtasks
+
+- [x] Preserve the completed Story 1.4 baseline and bound Story 1.5 scope (AC: 1, 5, 6)
+  - [x] Treat all current uncommitted Stories 1.3 and 1.4 implementation/review changes as existing user work; do not reset, rewrite, stage, or claim them as Story 1.5 work.
+  - [x] Preserve `ProviderScope -> MaterialApp.router -> LaunchGate -> StatefulShellRoute/AppShell`, the four route roots, tab state, Android Back behavior, bootstrap retry, database lifecycle, app title, and disabled debug banner.
+  - [x] Add no packages, custom font files, images, routes, permissions, persistence changes, network code, feature controllers, repositories, or business behavior.
+  - [x] Do not implement dark mode, tablet optimization, final app branding/icons, product/dashboard/history/settings features, status badges, snackbars for future save flows, forms, or the final Story 5.5 accessibility audit.
+
+- [x] Add the approved app theme and token files (AC: 1, 2, 5)
+  - [x] Add `lib/app/theme/app_colors.dart` with all exact `DESIGN.md` colors and semantic names: background, surface, surface-muted, primary/secondary text, primary, primary-pressed, success, warning/warning-surface, danger/danger-surface, and border.
+  - [x] Add an immutable `AppSpacing` `ThemeExtension` under `lib/core/ui/app_spacing.dart` with `xs=4`, `sm=8`, `md=16`, `lg=24`, and `xl=32`, plus correct `copyWith`/`lerp`; register it in the app theme so core widgets and feature roots can consume spacing without importing `app/theme` or duplicating literals.
+  - [x] Add `lib/app/theme/app_typography.dart` using the platform system family (Roboto on Android) and map the approved display, title, section, body, and label sizes/weights into a `TextTheme`; do not add Google Fonts or disable system text scaling.
+  - [x] Add `lib/core/ui/app_dimensions.dart` for the `6/8/12` radii, documented `8dp` card/button/input radius, `999dp` pill override for later status chips, and `48dp` minimum tap target without duplicating spacing or color constants.
+  - [x] Add `lib/app/theme/app_theme.dart` exposing one light `ThemeData` with `useMaterial3: true`, approved typography, `MaterialTapTargetSize.padded`, off-white scaffold background, minimally elevated/bordered surfaces, 8dp button/input shapes, and component minimum sizes that preserve 48dp action targets.
+  - [x] Use `ColorScheme.fromSeed` only for unspecified roles, then explicitly map `primary=#2E7D4F`, `surface=#FFFFFF`, `surfaceContainer=#EEF3EE`, `onSurface=#172018`, `onSurfaceVariant=#5E6B60`, `error=#B42318`, `errorContainer=#FDECEC`, and `outline=#DDE5DD`; configure the pressed `FilledButton` state as `#24643F`.
+  - [x] Keep warning/success semantic tokens available through `AppColors`; do not force them into unrelated `ColorScheme` roles and do not treat token presence alone as proof of contrast compliance.
+  - [x] Do not render normal-sized warning text as `#B7791F` on `#FFF7E0`; use primary text for readable warning copy and reserve warning color for an icon/border/accent paired with a visible label.
+
+- [x] Integrate the theme into existing app presentation without changing behavior (AC: 1, 2, 5, 6)
+  - [x] Set the theme only on the existing root `MaterialApp.router` in `lib/app/app.dart`; do not add a nested app, recreate the router, or move bootstrap into routing.
+  - [x] Preserve the current launch-gate state machine and exact safe retry/database-close ordering while replacing only the private loading/error presentation with the shared state views.
+  - [x] Keep the Story 1.4 `NavigationBar` destinations, order, visible labels, `currentIndex`, and `goBranch` behavior unchanged; let the root theme style it and modify `app_shell.dart` only if a measured accessibility requirement cannot be met through `ThemeData`.
+  - [x] Apply the shared typography and spacing tokens to the skeletal Dashboard, Products, History, and Settings roots while preserving their keys, identities, neutral placeholder copy, and lack of feature actions/data.
+  - [x] Do not invent navigation container, indicator, icon, animation, or elevation tokens that the UX documents leave unspecified; retain consistent Material 3 defaults.
+
+- [x] Add reusable loading, empty, and error state views (AC: 3, 4, 5)
+  - [x] Add stateless, presentation-only `AppLoadingView`, `AppEmptyState`, and `AppErrorView` widgets under `lib/core/widgets/`; they must not import Riverpod, go_router, Drift, feature code, repositories, or failure implementations.
+  - [x] Keep the shared views embeddable content widgets rather than full `MaterialApp` instances or feature-owned navigation shells; callers remain responsible for the surrounding page/`Scaffold`.
+  - [x] `AppLoadingView` may accept safe title/message text and must use a small progress indicator with a useful loading semantic/live-region label.
+  - [x] `AppEmptyState` must require a clear title, allow optional explanatory text/icon, and expose an optional action label/callback pair for feature stories to wire later; action label and callback must be supplied together or neither, enforced by constructor assertions.
+  - [x] `AppErrorView` must accept only already-safe visible message text plus an optional action label/callback pair; do not accept or stringify `Object`, `Exception`, `Error`, stack trace, or database failure details.
+  - [x] Error presentation must include a visible icon and text in addition to danger color. Error action label and callback must be supplied together or neither; neither produces no button, incomplete pairs fail construction, and rendered actions retain at least a 48dp tap target.
+  - [x] Reuse the existing `FailureMessageMapper` before passing initialization copy into `AppErrorView`; do not duplicate failure mapping inside the widget.
+  - [x] Do not add speculative `button_loading`, `primary_button`, `confirm_dialog`, warning-banner, snackbar service, or feature-specific empty-state APIs in this story.
+
+- [x] Add focused theme, base-state, and accessibility tests (AC: 1-6)
+  - [x] Add mirrored tests under `test/app/theme/` that assert Material 3 is enabled, every exact token value is retained, the approved `TextTheme` roles have the required sizes/weights, scaffold/surface/error/outline mappings are correct, and button/input shapes and action minimum sizes use the documented values.
+  - [x] Add tests under `test/core/widgets/` for loading title/message/progress semantics, empty state with and without an action, error icon/text/action, callback invocation, and omission/disable behavior for incomplete optional actions.
+  - [x] Prove `AppErrorView` has no raw throwable input and visible initialization errors still come only from `FailureMessageMapper`; preserve the existing raw SQLite-detail suppression assertion.
+  - [x] Update `test/widget_test.dart` to verify the root app supplies the approved theme to splash, failure, Dashboard, and navigation descendants without weakening any of the 30 Story 1.3/1.4 regressions.
+  - [x] Use Flutter accessibility guideline checks or precise hit-test size assertions to verify navigation/retry/state actions meet Android's 48dp floor and retain labels; do not infer accessibility from icon size or color.
+  - [x] Test all three shared state views, including action variants, at exactly `360x640` logical pixels with `TextScaler.linear(2.0)` and fail on any framework overflow exception.
+  - [x] Run `textContrastGuideline` (or an equally explicit ratio assertion) for every foreground/background pairing actually rendered by Story 1.5, including primary actions, normal surface text, and error presentation.
+  - [x] Verify supplying neither action label nor callback renders no button, while either incomplete label/callback pair fails construction.
+  - [x] Verify the error state includes non-color cues and that all four main placeholder screens remain reachable with their canonical keys and route behavior unchanged.
+
+- [x] Run regression and Android verification (AC: 1-6)
+  - [x] Run `dart format --output=none --set-exit-if-changed .`.
+  - [x] Run `flutter analyze`.
+  - [x] Run `flutter test --reporter expanded`.
+  - [x] Run `flutter build apk --debug`.
+  - [x] If an Android target is available, manually verify the themed native launch -> TindaTrack loading state -> Dashboard shell, all four tabs, retry presentation, and readability on the configured phone viewport; otherwise record the live check as not run.
+  - [x] Record exact commands, effective versions, final test count, build result, device result, and UNC mirror use in the Dev Agent Record.
+
+## Dev Notes
+
+### Developer Context
+
+Stories 1.1-1.4 established the Android project, feature/core boundaries, local bootstrap/retry lifecycle, stable app-scoped router, and four stateful navigation branches. Story 1.5 closes Epic 1 by supplying the approved visual/accessibility foundation and reusable loading/empty/error presentation for later feature stories.
+
+The required composition remains:
+
+```text
+ProviderScope
+`-- MaterialApp.router(theme: AppTheme.light)
+    `-- builder: LaunchGate(routerChild)
+        |-- loading -> Scaffold + AppLoadingView
+        |-- failure -> Scaffold + AppErrorView(safe mapped copy, Retry)
+        `-- success -> StatefulShellRoute router child
+            `-- AppShell + themed NavigationBar
+                |-- Dashboard placeholder
+                |-- Products placeholder
+                |-- History placeholder
+                `-- Settings placeholder
+```
+
+Theme and state primitives must remain presentation-only. They must not read the database, bootstrap provider, router, or feature state.
+
+### Story Boundaries
+
+- **Story 1.5 owns:** exact visual tokens, root light Material 3 theme, base dimensions, shared loading/empty/error views, initial small-screen/accessibility tests, and token styling of current placeholders.
+- **Stories 2.3/2.4 own Products states:** real product list, no-products action, and no-search-results behavior.
+- **Stories 2.5 and later own inventory statuses:** Low Stock/Out of Stock badges and domain-specific warning behavior.
+- **Stories 3.4/3.5 own stock feedback:** form loading, validation, commit success, and blocked Stock Out states.
+- **Story 3.6 owns History empty state.**
+- **Story 4.2 owns Dashboard loading/content/empty/error behavior.**
+- **Story 5.1 owns Settings content and error behavior.**
+- **Story 5.5 owns final whole-app UX/accessibility consistency and polish.**
+
+The shared widgets added here are foundations for those stories, not permission to implement their feature behavior early.
+
+### Exact Approved Tokens
+
+| Category | Token | Value |
+| --- | --- | --- |
+| Color | background | `#F8FAF7` |
+| Color | surface | `#FFFFFF` |
+| Color | surfaceMuted | `#EEF3EE` |
+| Color | textPrimary | `#172018` |
+| Color | textSecondary | `#5E6B60` |
+| Color | primary / success | `#2E7D4F` |
+| Color | primaryPressed | `#24643F` |
+| Color | warning | `#B7791F` |
+| Color | warningSurface | `#FFF7E0` |
+| Color | danger | `#B42318` |
+| Color | dangerSurface | `#FDECEC` |
+| Color | border | `#DDE5DD` |
+| Typography | display | `28sp`, weight `700` |
+| Typography | title | `20sp`, weight `700` |
+| Typography | section | `16sp`, weight `700` |
+| Typography | body | `14sp`, weight `400` |
+| Typography | label | `12sp`, weight `600` |
+| Spacing | xs / sm / md / lg / xl | `4 / 8 / 16 / 24 / 32dp` via core `AppSpacing` theme extension |
+| Radius | small / medium / large | `6 / 8 / 12dp` |
+| Component | card / button / input radius | `8dp` |
+| Component | status-pill override | `999dp` |
+| Accessibility | minimum applicable tap target | `48dp` |
+
+Use the platform system font; Android supplies Roboto. Do not add a font dependency or asset. The UX mentions medium/semibold product-row names but defines no separate weight token; do not invent that token in Story 1.5.
+
+### Current Files To Update
+
+#### `tindatrack/lib/app/app.dart`
+
+- **Current state:** one `MaterialApp.router` reads the stable Riverpod router and uses a private launch gate. Private splash and initialization-failure widgets render loading and safe retry presentation.
+- **This story changes:** add `AppTheme.light`; compose private launch-state wrappers from `AppLoadingView` and `AppErrorView`.
+- **Must preserve:** title, debug-banner setting, router identity, launch-gate `AsyncValue` handling, programming-error behavior, safe mapper usage, duplicate-retry guard, serialized close-before-invalidate ordering, and router child on success.
+- **Must avoid:** moving retry/database logic into shared widgets, invalidating the router, nesting apps, or exposing raw errors.
+
+#### `tindatrack/lib/app/navigation/app_shell.dart`
+
+- **Current state:** owns the persistent `Scaffold`, router shell body, and exact four-destination `NavigationBar`.
+- **This story changes:** normally none; root component themes should provide appearance and tap-target behavior.
+- **Must preserve:** destination order/labels/icons, always-visible labels, `currentIndex`, and `goBranch(index, initialLocation: index == currentIndex)`.
+- **Must avoid:** local tab state, custom Back interception, future routes, badges, FABs, drawers, or speculative polish.
+
+#### Four branch placeholder screens
+
+- **Current state:** each is a skeletal keyed `Scaffold` with a centered identity and neutral placeholder copy.
+- **This story changes:** apply approved title/body styles, secondary text color, and token spacing/padding so current main screens visibly consume the theme.
+- **Must preserve:** keys, screen names, placeholder meaning, route ownership, and no data/actions.
+
+#### `tindatrack/test/widget_test.dart`
+
+- **Current state:** 30 passing tests across the repository after Story 1.4 review; widget tests protect splash, safe failure, retry, database rotation, navigation, provider identity, and Android Back behavior.
+- **This story changes:** add theme/state/accessibility assertions and adapt widget-type expectations if private launch presentation delegates to shared views.
+- **Must preserve:** every bootstrap, raw-detail suppression, retry, router, database, and Back assertion; tests continue using provider overrides and in-memory Drift.
+
+### Technical Requirements
+
+- Use the repository-resolved Flutter `3.44.0`, Dart `3.12.0`, Riverpod `3.3.2`, go_router `17.3.0`, Drift `2.34.0`, and drift_flutter `0.3.0`; do not change dependency constraints or lockfile.
+- Use `ThemeData(useMaterial3: true, ...)` or an equivalent Material 3 construction. Prefer `ColorScheme.fromSeed(...).copyWith(...)` so unspecified roles retain coherent accessible Material defaults.
+- Set `materialTapTargetSize: MaterialTapTargetSize.padded`; component themes may additionally set a 48dp minimum action height.
+- Use `ThemeData` component themes rather than repeating button/input/navigation styling in feature widgets.
+- Keep `AppColors` and `AppTypography` under `lib/app/theme`; keep the cross-feature `AppSpacing` theme extension, dimensions, and shared state widgets under `lib/core`.
+- Register `AppSpacing` in `ThemeData.extensions`; core widgets and feature roots read it through `Theme.of(context).extension<AppSpacing>()` and must not import `app/theme`.
+- Shared state widgets accept display data/callbacks only. They do not accept domain failures or own mapping, routing, provider reads, retries, or persistence.
+- Respect system text scaling. Do not clamp `MediaQuery.textScaler`, use viewport-derived font sizes, or set negative letter spacing.
+- Keep UI stateless/lightweight with no decorative animation, image, gradient, or expensive custom painting.
+- Never log or render raw database/exception details.
+
+### Architecture Compliance
+
+- `lib/app/theme`: application theme and exact design tokens.
+- `lib/core/ui`: cross-feature spacing extension and dimensions such as radii and tap-target constants.
+- `lib/core/widgets`: reusable presentation-only loading, empty, and error views.
+- `lib/app/app.dart`: root theme and bootstrap composition.
+- `lib/features/*/presentation/screens`: feature-owned roots consuming, but not defining, the theme.
+- `core` must not import `app` or `features`; therefore shared widgets must consume `Theme.of(context)` rather than importing `AppColors` or other `app/theme` files.
+- `app` may import `core`; features may import `core`, but cross-feature theme ownership remains in `app`.
+- No database/schema/code generation action is required.
+
+### Library And Framework Requirements
+
+| Package/API | Resolved version | Story 1.5 use |
+| --- | --- | --- |
+| Flutter Material | Flutter `3.44.0` | Material 3 `ThemeData`, `ColorScheme`, component themes, `NavigationBar`, state views |
+| Flutter test accessibility guidelines | Flutter `3.44.0` | Android tap-target, semantic-label, and optional contrast checks |
+| flutter_riverpod | `3.3.2` | Existing root/bootstrap/router lifecycle only; no new theme provider |
+| go_router | `17.3.0` | Existing shell only; no route changes |
+| drift / drift_flutter | `2.34.0` / `0.3.0` | Existing bootstrap only; no persistence changes |
+
+Do not add Google Fonts, another design system, state manager, router, animation library, localization package, connectivity package, or feature SDK.
+
+### File Structure Requirements
+
+Expected new or updated files are approximately:
+
+```text
+tindatrack/
+|-- lib/
+|   |-- app/
+|   |   |-- app.dart
+|   |   `-- theme/
+|   |       |-- app_colors.dart
+|   |       |-- app_theme.dart
+|   |       `-- app_typography.dart
+|   |-- core/
+|   |   |-- ui/
+|   |   |   |-- app_dimensions.dart
+|   |   |   `-- app_spacing.dart
+|   |   `-- widgets/
+|   |       |-- app_empty_state.dart
+|   |       |-- app_error_view.dart
+|   |       `-- app_loading_view.dart
+|   `-- features/
+|       |-- dashboard/presentation/screens/dashboard_screen.dart
+|       |-- products/presentation/screens/product_list_screen.dart
+|       |-- history/presentation/screens/movement_history_screen.dart
+|       `-- settings/presentation/screens/settings_screen.dart
+`-- test/
+    |-- app/theme/app_theme_test.dart
+    |-- core/widgets/app_state_views_test.dart
+    `-- widget_test.dart
+```
+
+This structure is guidance, not permission to create the full future architecture tree. Add only files with concrete Story 1.5 behavior.
+
+### Testing Requirements
+
+- Test public observable behavior and exact token values; avoid snapshots/goldens that are brittle across rendering environments.
+- Theme tests should assert `useMaterial3`, `ColorScheme`, scaffold background, text sizes/weights, spacing/radius constants, component shapes, and minimum sizes.
+- Shared-view tests should cover content, optional actions, callback behavior, semantics, and non-color error cues.
+- Use `tester.ensureSemantics()` and Flutter accessibility matchers where appropriate; dispose the semantics handle.
+- Test at least one 48dp action target and the four navigation destinations. Do not equate a 24dp icon with its larger interactive target.
+- Exercise every shared state view at exactly `360x640` logical pixels with `TextScaler.linear(2.0)`; production must not clamp user scaling.
+- Treat action label/callback as an invariant pair in both empty and error views; test both valid variants and constructor assertion failures for incomplete pairs.
+- Run explicit contrast guideline checks for all foreground/background combinations Story 1.5 actually renders. Warning tokens are not permission to use amber as normal-sized text on its pale warning surface.
+- Check framework exceptions after small-screen/large-text pumps so overflow errors fail the test deterministically.
+- Preserve the complete 30-test Story 1.4 baseline; final count must increase.
+- Windows Flutter tooling cannot run from the UNC workspace. Use a disposable `C:\tmp` mirror for format/analyze/test/build while keeping repository files authoritative.
+- Run a full Android debug build after tests. A live device check is conditional on target availability and must be recorded honestly.
+
+### Previous Story Intelligence
+
+- Story 1.4 created one stable Riverpod-owned `GoRouter`, `StatefulShellRoute.indexedStack`, exact four branch roots, and a router child wrapped by bootstrap through `MaterialApp.router.builder`.
+- Router and database creation counts remain stable across tab changes and Android Back; Story 1.5 styling must not introduce provider reads or rebuild lifecycle objects.
+- Launch failure text already comes from `FailureMessageMapper`; reuse it before `AppErrorView`.
+- Navigation labels and branch keys are covered by tests. Do not change them while styling.
+- Story 1.4 review added Android Back, complete failed-bootstrap shell isolation, and real provider-owned router-identity tests. Preserve all 30 passing tests.
+- Live API 36 verification previously confirmed native launch, TindaTrack splash, Dashboard shell, and all four tabs.
+- Existing deferred work remains out of scope: retry can be stranded by a hanging/failing close, rejected close futures remain cached, asynchronous disposal errors need handling, and transitive EOL SQLite compatibility packages need later review.
+
+### Git Intelligence Summary
+
+- Current branch: `codex/complete-stories-1-1-and-1-2`; HEAD: `eb878cb Complete Flutter foundation stories`.
+- Stories 1.3 and 1.4, their review fixes, story records, deferred-work entries, and sprint updates remain uncommitted.
+- A diff against HEAD includes multiple completed stories. Preserve the dirty worktree and separate Story 1.5 files/notes explicitly; do not reset, clean, checkout, stage, or overwrite existing work.
+- Recent committed implementation uses strict `very_good_analysis`, Riverpod overrides, in-memory Drift, mirrored Windows test/build execution, and Android debug verification.
+- The resolved dependency versions in the working tree are authoritative over older planning-document snapshots.
+
+### Latest Technical Information
+
+- Flutter `3.44.0` official guidance supports Material 3 component themes through `ThemeData`, generated coherent schemes through `ColorScheme.fromSeed`, and component-specific overrides. Use the repository SDK rather than upgrading.
+- Flutter's mobile default `MaterialTapTargetSize.padded` expands affected controls to a 48x48 target; set it explicitly and still verify actual controls because not every widget is governed identically.
+- Flutter's accessibility guideline API can test Android tap targets, semantic labels, and text contrast. Use deterministic focused checks and treat contrast tests as verification, not as a substitute for exact approved tokens.
+- System text scaling is automatic; layouts must provide room at enlarged scale rather than disabling or clamping it in production.
+
+Official references:
+
+- [Flutter ThemeData API](https://api.flutter.dev/flutter/material/ThemeData/ThemeData.html)
+- [Flutter MaterialTapTargetSize API](https://api.flutter.dev/flutter/material/MaterialTapTargetSize.html)
+- [Flutter accessibility design guidance](https://docs.flutter.dev/ui/accessibility/ui-design-and-styling)
+- [Flutter accessibility testing guidance](https://docs.flutter.dev/ui/accessibility/accessibility-testing)
+
+### Project Structure Notes
+
+- Architecture places theme/design tokens in `lib/app/theme`, shared dimensions in `lib/core/ui`, and reusable state widgets in `lib/core/widgets`.
+- `core` cannot depend on `app`; shared widgets should derive colors and typography from `Theme.of(context)`.
+- Exact visual tokens come from `DESIGN.md`; screen/state behavior comes from `EXPERIENCE.md`.
+- UX leaves navigation indicator colors/shapes, icon colors, animation, and elevation unspecified. Use Material 3 defaults instead of creating extra tokens.
+- No `project-context.md` exists; finalized planning artifacts, completed Story 1.4, current source, Git state, and current official Flutter docs are authoritative.
+
+### References
+
+- [Source: _bmad-output/planning-artifacts/epics.md#Story-15-Apply-MVP-Theme-And-Base-UI-States]
+- [Source: _bmad-output/planning-artifacts/epics.md#UX-Design-Requirements]
+- [Source: _bmad-output/planning-artifacts/architecture.md#Frontend-Architecture]
+- [Source: _bmad-output/planning-artifacts/architecture.md#Loading-State-Patterns]
+- [Source: _bmad-output/planning-artifacts/architecture.md#Project-Structure--Boundaries]
+- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Colors]
+- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Typography]
+- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Layout--Spacing]
+- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/DESIGN.md#Shapes]
+- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#State-Patterns]
+- [Source: _bmad-output/planning-artifacts/ux-designs/ux-Inventory-2026-05-28/EXPERIENCE.md#Accessibility-Floor]
+- [Source: _bmad-output/planning-artifacts/implementation-readiness-report-2026-06-01.md#UX-To-Architecture-Alignment]
+- [Source: _bmad-output/implementation-artifacts/1-4-add-main-navigation-shell.md#Previous-Story-Intelligence]
+
+## Story Completion Status
+
+- Story file created from finalized Epic 1 requirements and exact approved UX tokens.
+- PRD, addendum, epics, architecture, UX design/experience, implementation-readiness, previous-story, current-code, Git, parallel artifact analysis, and official Flutter guidance analyzed.
+- Scope is bounded to the light Material 3 theme, shared state views, current placeholder styling, and accessibility verification; all feature behavior and final polish remain deferred to their owning stories.
+- Status set to `ready-for-dev`.
+- Completion note: Ultimate context engine analysis completed - comprehensive developer guide created.
+
+## Dev Agent Record
+
+### Agent Model Used
+
+GPT-5 Codex
+
+### Implementation Plan
+
+- Protect the 30-test Story 1.4 baseline before changing presentation.
+- Add exact theme tokens and focused failing tests, then implement the minimum light Material 3 theme.
+- Add reusable presentation-only state views and integrate them at the existing launch gate.
+- Style only the four skeletal route roots, preserving router, navigation, retry, and database behavior.
+- Run focused accessibility checks, full regression, strict analysis/formatting, and Android debug build from the required Windows mirror.
+
+### Debug Log References
+
+- 2026-06-27 baseline: `flutter test --reporter expanded` passed 30/30 before Story 1.5 changes.
+- RED: focused theme/state tests failed because the token, theme, and shared-widget files did not exist; root integration test then failed because the old private launch presentation was still active.
+- GREEN: focused token/state tests passed; root integration and small-phone/large-text tests passed; full suite passed 44/44.
+- Final commands in `C:\tmp\inventory-story15-work`: `dart format --output=none --set-exit-if-changed .` (39 files, 0 changed), `flutter analyze` (no issues), `flutter test --reporter expanded` (44 passed), and `flutter build apk --debug` (success).
+- Effective tooling: Flutter 3.44.0 stable, Dart 3.12.0, DevTools 2.57.0. APK: `build\app\outputs\flutter-apk\app-debug.apk` in the mirror.
+- Device result: live Android check not run; `flutter devices` found only Windows, Chrome, and Edge. The APK build emitted a non-blocking Android SDK XML version warning.
+- UNC note: Windows Flutter tooling used the disposable `C:\tmp\inventory-story15-work` mirror; the WSL/UNC workspace remained authoritative and only Story 1.5-owned files were copied back.
+
+### Completion Notes List
+
+- Preserved the authoritative uncommitted Story 1.3/1.4 baseline and all router, branch-state, Android Back, retry, database-close, and provider-lifecycle behavior.
+- Added the exact approved colors, typography, spacing extension, radii/dimensions, light Material 3 root theme, 48dp action sizing, and pressed-primary styling without dependencies or assets.
+- Added reusable loading, empty, and safe error views with paired optional actions, loading semantics, non-color error cues, and large-text/small-screen resilience.
+- Applied shared theme typography and spacing to the existing launch states and four canonical skeletal branch roots without adding feature behavior.
+- Added exact-token, component-theme, action-invariant, contrast, semantics, tap-target, raw-detail suppression, root-theme, navigation reachability, and 360x640 at 2x text tests. Final suite: 44/44 passed.
+
+### File List
+
+- `_bmad-output/implementation-artifacts/1-5-apply-mvp-theme-and-base-ui-states.md`
+- `_bmad-output/implementation-artifacts/sprint-status.yaml`
+- `tindatrack/lib/app/app.dart`
+- `tindatrack/lib/app/theme/app_colors.dart`
+- `tindatrack/lib/app/theme/app_theme.dart`
+- `tindatrack/lib/app/theme/app_typography.dart`
+- `tindatrack/lib/core/ui/app_dimensions.dart`
+- `tindatrack/lib/core/ui/app_spacing.dart`
+- `tindatrack/lib/core/widgets/app_empty_state.dart`
+- `tindatrack/lib/core/widgets/app_error_view.dart`
+- `tindatrack/lib/core/widgets/app_loading_view.dart`
+- `tindatrack/lib/features/dashboard/presentation/screens/dashboard_screen.dart`
+- `tindatrack/lib/features/history/presentation/screens/movement_history_screen.dart`
+- `tindatrack/lib/features/products/presentation/screens/product_list_screen.dart`
+- `tindatrack/lib/features/settings/presentation/screens/settings_screen.dart`
+- `tindatrack/test/app/theme/app_theme_test.dart`
+- `tindatrack/test/core/widgets/app_state_views_test.dart`
+- `tindatrack/test/widget_test.dart`
+
+## Change Log
+
+- 2026-06-27: Implemented Story 1.5 light Material 3 theme, shared base states, themed placeholders, and focused accessibility/regression coverage; moved story to review.
\ No newline at end of file
diff --git a/tindatrack/lib/app/theme/app_colors.dart b/tindatrack/lib/app/theme/app_colors.dart
new file mode 100755
index 0000000..f472704
--- /dev/null
+++ b/tindatrack/lib/app/theme/app_colors.dart
@@ -0,0 +1,21 @@
+// Member names describe the small, class-documented presentation API.
+// ignore_for_file: public_member_api_docs
+
+import 'package:flutter/material.dart';
+
+/// Exact semantic colors approved for the MVP light theme.
+abstract final class AppColors {
+  static const background = Color(0xFFF8FAF7);
+  static const surface = Color(0xFFFFFFFF);
+  static const surfaceMuted = Color(0xFFEEF3EE);
+  static const textPrimary = Color(0xFF172018);
+  static const textSecondary = Color(0xFF5E6B60);
+  static const primary = Color(0xFF2E7D4F);
+  static const primaryPressed = Color(0xFF24643F);
+  static const success = Color(0xFF2E7D4F);
+  static const warning = Color(0xFFB7791F);
+  static const warningSurface = Color(0xFFFFF7E0);
+  static const danger = Color(0xFFB42318);
+  static const dangerSurface = Color(0xFFFDECEC);
+  static const border = Color(0xFFDDE5DD);
+}
diff --git a/tindatrack/lib/app/theme/app_theme.dart b/tindatrack/lib/app/theme/app_theme.dart
new file mode 100755
index 0000000..45c3c65
--- /dev/null
+++ b/tindatrack/lib/app/theme/app_theme.dart
@@ -0,0 +1,107 @@
+import 'package:flutter/material.dart';
+import 'package:tindatrack/app/theme/app_colors.dart';
+import 'package:tindatrack/app/theme/app_typography.dart';
+import 'package:tindatrack/core/ui/app_dimensions.dart';
+import 'package:tindatrack/core/ui/app_spacing.dart';
+
+/// Root application theme.
+abstract final class AppTheme {
+  /// Approved light Material 3 theme for the MVP.
+  static ThemeData get light {
+    final scheme =
+        ColorScheme.fromSeed(
+          seedColor: AppColors.primary,
+        ).copyWith(
+          primary: AppColors.primary,
+          surface: AppColors.surface,
+          surfaceContainer: AppColors.surfaceMuted,
+          onSurface: AppColors.textPrimary,
+          onSurfaceVariant: AppColors.textSecondary,
+          error: AppColors.danger,
+          errorContainer: AppColors.dangerSurface,
+          outline: AppColors.border,
+        );
+    const componentBorder = RoundedRectangleBorder(
+      borderRadius: BorderRadius.all(
+        Radius.circular(AppDimensions.componentRadius),
+      ),
+    );
+    const minimumActionSize = Size(
+      AppDimensions.minimumTapTarget,
+      AppDimensions.minimumTapTarget,
+    );
+
+    return ThemeData(
+      useMaterial3: true,
+      colorScheme: scheme,
+      scaffoldBackgroundColor: AppColors.background,
+      textTheme: AppTypography.textTheme.apply(
+        bodyColor: AppColors.textPrimary,
+        displayColor: AppColors.textPrimary,
+      ),
+      materialTapTargetSize: MaterialTapTargetSize.padded,
+      visualDensity: VisualDensity.standard,
+      extensions: const <ThemeExtension<dynamic>>[AppSpacing.standard],
+      cardTheme: const CardThemeData(
+        color: AppColors.surface,
+        elevation: 0,
+        margin: EdgeInsets.zero,
+        shape: RoundedRectangleBorder(
+          side: BorderSide(color: AppColors.border),
+          borderRadius: BorderRadius.all(
+            Radius.circular(AppDimensions.componentRadius),
+          ),
+        ),
+      ),
+      filledButtonTheme: FilledButtonThemeData(
+        style: ButtonStyle(
+          minimumSize: const WidgetStatePropertyAll(minimumActionSize),
+          shape: const WidgetStatePropertyAll(componentBorder),
+          textStyle: const WidgetStatePropertyAll(
+            TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
+          ),
+          backgroundColor: WidgetStateProperty.resolveWith((states) {
+            if (states.contains(WidgetState.pressed)) {
+              return AppColors.primaryPressed;
+            }
+            return AppColors.primary;
+          }),
+        ),
+      ),
+      outlinedButtonTheme: const OutlinedButtonThemeData(
+        style: ButtonStyle(
+          minimumSize: WidgetStatePropertyAll(minimumActionSize),
+          shape: WidgetStatePropertyAll(componentBorder),
+        ),
+      ),
+      textButtonTheme: const TextButtonThemeData(
+        style: ButtonStyle(
+          minimumSize: WidgetStatePropertyAll(minimumActionSize),
+          shape: WidgetStatePropertyAll(componentBorder),
+        ),
+      ),
+      iconButtonTheme: const IconButtonThemeData(
+        style: ButtonStyle(
+          minimumSize: WidgetStatePropertyAll(minimumActionSize),
+        ),
+      ),
+      inputDecorationTheme: const InputDecorationTheme(
+        filled: true,
+        fillColor: AppColors.surface,
+        constraints: BoxConstraints(minHeight: AppDimensions.minimumTapTarget),
+        border: OutlineInputBorder(
+          borderRadius: BorderRadius.all(
+            Radius.circular(AppDimensions.componentRadius),
+          ),
+          borderSide: BorderSide(color: AppColors.border),
+        ),
+        enabledBorder: OutlineInputBorder(
+          borderRadius: BorderRadius.all(
+            Radius.circular(AppDimensions.componentRadius),
+          ),
+          borderSide: BorderSide(color: AppColors.border),
+        ),
+      ),
+    );
+  }
+}
diff --git a/tindatrack/lib/app/theme/app_typography.dart b/tindatrack/lib/app/theme/app_typography.dart
new file mode 100755
index 0000000..738c1ff
--- /dev/null
+++ b/tindatrack/lib/app/theme/app_typography.dart
@@ -0,0 +1,15 @@
+// Member names describe the small, class-documented presentation API.
+// ignore_for_file: public_member_api_docs
+
+import 'package:flutter/material.dart';
+
+/// Approved system-font typography roles for the MVP.
+abstract final class AppTypography {
+  static const textTheme = TextTheme(
+    displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
+    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
+    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
+    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
+    labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
+  );
+}
diff --git a/tindatrack/lib/core/ui/app_dimensions.dart b/tindatrack/lib/core/ui/app_dimensions.dart
new file mode 100755
index 0000000..bc6fa9e
--- /dev/null
+++ b/tindatrack/lib/core/ui/app_dimensions.dart
@@ -0,0 +1,18 @@
+// Member names describe the small, class-documented presentation API.
+// ignore_for_file: public_member_api_docs
+
+/// Shared non-theme dimensions approved for the MVP UI.
+abstract final class AppDimensions {
+  static const radiusSmall = 6.0;
+  static const radiusMedium = 8.0;
+  static const radiusLarge = 12.0;
+
+  /// Standard card, button, and input corner radius.
+  static const double componentRadius = radiusMedium;
+
+  /// Reserved override for later status-chip stories.
+  static const statusPillRadius = 999.0;
+
+  /// Android accessibility floor for applicable controls.
+  static const minimumTapTarget = 48.0;
+}
diff --git a/tindatrack/lib/core/ui/app_spacing.dart b/tindatrack/lib/core/ui/app_spacing.dart
new file mode 100755
index 0000000..1f48060
--- /dev/null
+++ b/tindatrack/lib/core/ui/app_spacing.dart
@@ -0,0 +1,62 @@
+// Member names describe the small, class-documented presentation API.
+// ignore_for_file: public_member_api_docs
+
+import 'dart:ui' show lerpDouble;
+
+import 'package:flutter/material.dart';
+
+/// Theme-provided spacing scale shared across app and feature presentation.
+@immutable
+class AppSpacing extends ThemeExtension<AppSpacing> {
+  /// Creates a spacing scale.
+  const AppSpacing({
+    required this.xs,
+    required this.sm,
+    required this.md,
+    required this.lg,
+    required this.xl,
+  });
+
+  /// Approved MVP spacing scale.
+  static const standard = AppSpacing(xs: 4, sm: 8, md: 16, lg: 24, xl: 32);
+
+  final double xs;
+  final double sm;
+  final double md;
+  final double lg;
+  final double xl;
+
+  /// Reads spacing from the active theme, with approved values as fallback.
+  static AppSpacing of(BuildContext context) {
+    return Theme.of(context).extension<AppSpacing>() ?? standard;
+  }
+
+  @override
+  AppSpacing copyWith({
+    double? xs,
+    double? sm,
+    double? md,
+    double? lg,
+    double? xl,
+  }) {
+    return AppSpacing(
+      xs: xs ?? this.xs,
+      sm: sm ?? this.sm,
+      md: md ?? this.md,
+      lg: lg ?? this.lg,
+      xl: xl ?? this.xl,
+    );
+  }
+
+  @override
+  AppSpacing lerp(covariant AppSpacing? other, double t) {
+    if (other == null) return this;
+    return AppSpacing(
+      xs: lerpDouble(xs, other.xs, t)!,
+      sm: lerpDouble(sm, other.sm, t)!,
+      md: lerpDouble(md, other.md, t)!,
+      lg: lerpDouble(lg, other.lg, t)!,
+      xl: lerpDouble(xl, other.xl, t)!,
+    );
+  }
+}
diff --git a/tindatrack/lib/core/widgets/app_empty_state.dart b/tindatrack/lib/core/widgets/app_empty_state.dart
new file mode 100755
index 0000000..b6238e2
--- /dev/null
+++ b/tindatrack/lib/core/widgets/app_empty_state.dart
@@ -0,0 +1,70 @@
+// Member names describe the small, class-documented presentation API.
+// ignore_for_file: public_member_api_docs
+
+import 'package:flutter/material.dart';
+import 'package:tindatrack/core/ui/app_spacing.dart';
+
+/// Reusable presentation-only empty state.
+class AppEmptyState extends StatelessWidget {
+  const AppEmptyState({
+    required this.title,
+    this.message,
+    this.icon,
+    this.actionLabel,
+    this.onAction,
+    super.key,
+  }) : assert(
+         (actionLabel == null) == (onAction == null),
+         'actionLabel and onAction must be supplied together',
+       );
+
+  final String title;
+  final String? message;
+  final IconData? icon;
+  final String? actionLabel;
+  final VoidCallback? onAction;
+
+  @override
+  Widget build(BuildContext context) {
+    final spacing = AppSpacing.of(context);
+    final theme = Theme.of(context);
+
+    return Center(
+      child: SingleChildScrollView(
+        padding: EdgeInsets.all(spacing.lg),
+        child: Column(
+          mainAxisSize: MainAxisSize.min,
+          children: [
+            if (icon != null) ...[
+              Icon(
+                icon,
+                size: spacing.xl,
+                color: theme.colorScheme.onSurfaceVariant,
+              ),
+              SizedBox(height: spacing.md),
+            ],
+            Text(
+              title,
+              style: theme.textTheme.titleLarge,
+              textAlign: TextAlign.center,
+            ),
+            if (message != null) ...[
+              SizedBox(height: spacing.sm),
+              Text(
+                message!,
+                style: theme.textTheme.bodyMedium?.copyWith(
+                  color: theme.colorScheme.onSurfaceVariant,
+                ),
+                textAlign: TextAlign.center,
+              ),
+            ],
+            if (actionLabel != null) ...[
+              SizedBox(height: spacing.md),
+              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
+            ],
+          ],
+        ),
+      ),
+    );
+  }
+}
diff --git a/tindatrack/lib/core/widgets/app_error_view.dart b/tindatrack/lib/core/widgets/app_error_view.dart
new file mode 100755
index 0000000..f150f86
--- /dev/null
+++ b/tindatrack/lib/core/widgets/app_error_view.dart
@@ -0,0 +1,77 @@
+// Member names describe the small, class-documented presentation API.
+// ignore_for_file: public_member_api_docs
+
+import 'package:flutter/material.dart';
+import 'package:tindatrack/core/ui/app_spacing.dart';
+
+/// Reusable error presentation that accepts safe display copy only.
+class AppErrorView extends StatelessWidget {
+  const AppErrorView({
+    required this.message,
+    this.title = 'Something went wrong',
+    this.actionLabel,
+    this.onAction,
+    this.isActionEnabled = true,
+    super.key,
+  }) : assert(
+         (actionLabel == null) == (onAction == null),
+         'actionLabel and onAction must be supplied together',
+       );
+
+  final String title;
+  final String message;
+  final String? actionLabel;
+  final VoidCallback? onAction;
+  final bool isActionEnabled;
+
+  @override
+  Widget build(BuildContext context) {
+    final spacing = AppSpacing.of(context);
+    final theme = Theme.of(context);
+
+    return Center(
+      child: SingleChildScrollView(
+        padding: EdgeInsets.all(spacing.lg),
+        child: Container(
+          constraints: const BoxConstraints(maxWidth: 480),
+          padding: EdgeInsets.all(spacing.md),
+          decoration: BoxDecoration(
+            color: theme.colorScheme.errorContainer,
+            border: Border.all(color: theme.colorScheme.error),
+            borderRadius: BorderRadius.circular(spacing.sm),
+          ),
+          child: Column(
+            mainAxisSize: MainAxisSize.min,
+            children: [
+              Icon(
+                Icons.error_outline,
+                color: theme.colorScheme.error,
+                size: spacing.xl,
+                semanticLabel: 'Error',
+              ),
+              SizedBox(height: spacing.sm),
+              Text(
+                title,
+                style: theme.textTheme.titleMedium,
+                textAlign: TextAlign.center,
+              ),
+              SizedBox(height: spacing.sm),
+              Text(
+                message,
+                style: theme.textTheme.bodyMedium,
+                textAlign: TextAlign.center,
+              ),
+              if (actionLabel != null) ...[
+                SizedBox(height: spacing.md),
+                FilledButton(
+                  onPressed: isActionEnabled ? onAction : null,
+                  child: Text(actionLabel!),
+                ),
+              ],
+            ],
+          ),
+        ),
+      ),
+    );
+  }
+}
diff --git a/tindatrack/lib/core/widgets/app_loading_view.dart b/tindatrack/lib/core/widgets/app_loading_view.dart
new file mode 100755
index 0000000..3a659f9
--- /dev/null
+++ b/tindatrack/lib/core/widgets/app_loading_view.dart
@@ -0,0 +1,59 @@
+// Member names describe the small, class-documented presentation API.
+// ignore_for_file: public_member_api_docs
+
+import 'package:flutter/material.dart';
+import 'package:tindatrack/core/ui/app_spacing.dart';
+
+/// Lightweight centered loading presentation with accessible progress meaning.
+class AppLoadingView extends StatelessWidget {
+  const AppLoadingView({
+    this.title,
+    this.message,
+    this.semanticsLabel = 'Loading',
+    super.key,
+  });
+
+  final String? title;
+  final String? message;
+  final String semanticsLabel;
+
+  @override
+  Widget build(BuildContext context) {
+    final spacing = AppSpacing.of(context);
+    final theme = Theme.of(context);
+
+    return Center(
+      child: SingleChildScrollView(
+        padding: EdgeInsets.all(spacing.lg),
+        child: Column(
+          mainAxisSize: MainAxisSize.min,
+          children: [
+            if (title != null) ...[
+              Text(
+                title!,
+                style: theme.textTheme.titleLarge,
+                textAlign: TextAlign.center,
+              ),
+              SizedBox(height: spacing.sm),
+            ],
+            if (message != null) ...[
+              Text(
+                message!,
+                style: theme.textTheme.bodyMedium?.copyWith(
+                  color: theme.colorScheme.onSurfaceVariant,
+                ),
+                textAlign: TextAlign.center,
+              ),
+              SizedBox(height: spacing.md),
+            ],
+            Semantics(
+              label: semanticsLabel,
+              liveRegion: true,
+              child: const CircularProgressIndicator(),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}
diff --git a/tindatrack/lib/features/dashboard/presentation/screens/dashboard_screen.dart b/tindatrack/lib/features/dashboard/presentation/screens/dashboard_screen.dart
new file mode 100644
index 0000000..bfbe5a0
--- /dev/null
+++ b/tindatrack/lib/features/dashboard/presentation/screens/dashboard_screen.dart
@@ -0,0 +1,63 @@
+import 'package:flutter/material.dart';
+import 'package:tindatrack/core/ui/app_spacing.dart';
+
+/// Minimal landing destination after local initialization succeeds.
+class DashboardScreen extends StatelessWidget {
+  /// Creates the placeholder Dashboard screen.
+  const DashboardScreen({super.key});
+
+  @override
+  Widget build(BuildContext context) {
+    return const _PlaceholderScreen(
+      screenKey: Key('dashboard-screen'),
+      title: 'Dashboard',
+      message: 'Offline inventory tracker',
+    );
+  }
+}
+
+class _PlaceholderScreen extends StatelessWidget {
+  const _PlaceholderScreen({
+    required this.screenKey,
+    required this.title,
+    required this.message,
+  });
+
+  final Key screenKey;
+  final String title;
+  final String message;
+
+  @override
+  Widget build(BuildContext context) {
+    final spacing = AppSpacing.of(context);
+    final theme = Theme.of(context);
+    return Scaffold(
+      key: screenKey,
+      body: SafeArea(
+        child: Center(
+          child: SingleChildScrollView(
+            padding: EdgeInsets.all(spacing.lg),
+            child: Column(
+              mainAxisSize: MainAxisSize.min,
+              children: [
+                Text(
+                  title,
+                  style: theme.textTheme.titleLarge,
+                  textAlign: TextAlign.center,
+                ),
+                SizedBox(height: spacing.sm),
+                Text(
+                  message,
+                  style: theme.textTheme.bodyMedium?.copyWith(
+                    color: theme.colorScheme.onSurfaceVariant,
+                  ),
+                  textAlign: TextAlign.center,
+                ),
+              ],
+            ),
+          ),
+        ),
+      ),
+    );
+  }
+}
diff --git a/tindatrack/lib/features/history/presentation/screens/movement_history_screen.dart b/tindatrack/lib/features/history/presentation/screens/movement_history_screen.dart
new file mode 100644
index 0000000..f719686
--- /dev/null
+++ b/tindatrack/lib/features/history/presentation/screens/movement_history_screen.dart
@@ -0,0 +1,63 @@
+import 'package:flutter/material.dart';
+import 'package:tindatrack/core/ui/app_spacing.dart';
+
+/// Placeholder root for the History branch.
+class MovementHistoryScreen extends StatelessWidget {
+  /// Creates the History placeholder.
+  const MovementHistoryScreen({super.key});
+
+  @override
+  Widget build(BuildContext context) {
+    return const _PlaceholderScreen(
+      screenKey: Key('history-screen'),
+      title: 'History',
+      message: 'Inventory history is coming in a later story.',
+    );
+  }
+}
+
+class _PlaceholderScreen extends StatelessWidget {
+  const _PlaceholderScreen({
+    required this.screenKey,
+    required this.title,
+    required this.message,
+  });
+
+  final Key screenKey;
+  final String title;
+  final String message;
+
+  @override
+  Widget build(BuildContext context) {
+    final spacing = AppSpacing.of(context);
+    final theme = Theme.of(context);
+    return Scaffold(
+      key: screenKey,
+      body: SafeArea(
+        child: Center(
+          child: SingleChildScrollView(
+            padding: EdgeInsets.all(spacing.lg),
+            child: Column(
+              mainAxisSize: MainAxisSize.min,
+              children: [
+                Text(
+                  title,
+                  style: theme.textTheme.titleLarge,
+                  textAlign: TextAlign.center,
+                ),
+                SizedBox(height: spacing.sm),
+                Text(
+                  message,
+                  style: theme.textTheme.bodyMedium?.copyWith(
+                    color: theme.colorScheme.onSurfaceVariant,
+                  ),
+                  textAlign: TextAlign.center,
+                ),
+              ],
+            ),
+          ),
+        ),
+      ),
+    );
+  }
+}
diff --git a/tindatrack/lib/features/products/presentation/screens/product_list_screen.dart b/tindatrack/lib/features/products/presentation/screens/product_list_screen.dart
new file mode 100644
index 0000000..7a2428d
--- /dev/null
+++ b/tindatrack/lib/features/products/presentation/screens/product_list_screen.dart
@@ -0,0 +1,63 @@
+import 'package:flutter/material.dart';
+import 'package:tindatrack/core/ui/app_spacing.dart';
+
+/// Placeholder root for the Products branch.
+class ProductListScreen extends StatelessWidget {
+  /// Creates the Products placeholder.
+  const ProductListScreen({super.key});
+
+  @override
+  Widget build(BuildContext context) {
+    return const _PlaceholderScreen(
+      screenKey: Key('products-screen'),
+      title: 'Products',
+      message: 'Product tools are coming in a later story.',
+    );
+  }
+}
+
+class _PlaceholderScreen extends StatelessWidget {
+  const _PlaceholderScreen({
+    required this.screenKey,
+    required this.title,
+    required this.message,
+  });
+
+  final Key screenKey;
+  final String title;
+  final String message;
+
+  @override
+  Widget build(BuildContext context) {
+    final spacing = AppSpacing.of(context);
+    final theme = Theme.of(context);
+    return Scaffold(
+      key: screenKey,
+      body: SafeArea(
+        child: Center(
+          child: SingleChildScrollView(
+            padding: EdgeInsets.all(spacing.lg),
+            child: Column(
+              mainAxisSize: MainAxisSize.min,
+              children: [
+                Text(
+                  title,
+                  style: theme.textTheme.titleLarge,
+                  textAlign: TextAlign.center,
+                ),
+                SizedBox(height: spacing.sm),
+                Text(
+                  message,
+                  style: theme.textTheme.bodyMedium?.copyWith(
+                    color: theme.colorScheme.onSurfaceVariant,
+                  ),
+                  textAlign: TextAlign.center,
+                ),
+              ],
+            ),
+          ),
+        ),
+      ),
+    );
+  }
+}
diff --git a/tindatrack/lib/features/settings/presentation/screens/settings_screen.dart b/tindatrack/lib/features/settings/presentation/screens/settings_screen.dart
new file mode 100644
index 0000000..acd18b9
--- /dev/null
+++ b/tindatrack/lib/features/settings/presentation/screens/settings_screen.dart
@@ -0,0 +1,63 @@
+import 'package:flutter/material.dart';
+import 'package:tindatrack/core/ui/app_spacing.dart';
+
+/// Placeholder root for the Settings branch.
+class SettingsScreen extends StatelessWidget {
+  /// Creates the Settings placeholder.
+  const SettingsScreen({super.key});
+
+  @override
+  Widget build(BuildContext context) {
+    return const _PlaceholderScreen(
+      screenKey: Key('settings-screen'),
+      title: 'Settings',
+      message: 'Settings are coming in a later story.',
+    );
+  }
+}
+
+class _PlaceholderScreen extends StatelessWidget {
+  const _PlaceholderScreen({
+    required this.screenKey,
+    required this.title,
+    required this.message,
+  });
+
+  final Key screenKey;
+  final String title;
+  final String message;
+
+  @override
+  Widget build(BuildContext context) {
+    final spacing = AppSpacing.of(context);
+    final theme = Theme.of(context);
+    return Scaffold(
+      key: screenKey,
+      body: SafeArea(
+        child: Center(
+          child: SingleChildScrollView(
+            padding: EdgeInsets.all(spacing.lg),
+            child: Column(
+              mainAxisSize: MainAxisSize.min,
+              children: [
+                Text(
+                  title,
+                  style: theme.textTheme.titleLarge,
+                  textAlign: TextAlign.center,
+                ),
+                SizedBox(height: spacing.sm),
+                Text(
+                  message,
+                  style: theme.textTheme.bodyMedium?.copyWith(
+                    color: theme.colorScheme.onSurfaceVariant,
+                  ),
+                  textAlign: TextAlign.center,
+                ),
+              ],
+            ),
+          ),
+        ),
+      ),
+    );
+  }
+}
diff --git a/tindatrack/test/app/theme/app_theme_test.dart b/tindatrack/test/app/theme/app_theme_test.dart
new file mode 100755
index 0000000..be9d18d
--- /dev/null
+++ b/tindatrack/test/app/theme/app_theme_test.dart
@@ -0,0 +1,96 @@
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:tindatrack/app/theme/app_colors.dart';
+import 'package:tindatrack/app/theme/app_theme.dart';
+import 'package:tindatrack/app/theme/app_typography.dart';
+import 'package:tindatrack/core/ui/app_dimensions.dart';
+import 'package:tindatrack/core/ui/app_spacing.dart';
+
+void main() {
+  test('retains every approved color token', () {
+    expect(AppColors.background, const Color(0xFFF8FAF7));
+    expect(AppColors.surface, const Color(0xFFFFFFFF));
+    expect(AppColors.surfaceMuted, const Color(0xFFEEF3EE));
+    expect(AppColors.textPrimary, const Color(0xFF172018));
+    expect(AppColors.textSecondary, const Color(0xFF5E6B60));
+    expect(AppColors.primary, const Color(0xFF2E7D4F));
+    expect(AppColors.primaryPressed, const Color(0xFF24643F));
+    expect(AppColors.success, const Color(0xFF2E7D4F));
+    expect(AppColors.warning, const Color(0xFFB7791F));
+    expect(AppColors.warningSurface, const Color(0xFFFFF7E0));
+    expect(AppColors.danger, const Color(0xFFB42318));
+    expect(AppColors.dangerSurface, const Color(0xFFFDECEC));
+    expect(AppColors.border, const Color(0xFFDDE5DD));
+  });
+
+  test('retains approved spacing and dimensions', () {
+    const spacing = AppSpacing.standard;
+    expect(spacing.xs, 4);
+    expect(spacing.sm, 8);
+    expect(spacing.md, 16);
+    expect(spacing.lg, 24);
+    expect(spacing.xl, 32);
+    expect(spacing.copyWith(md: 20).md, 20);
+    expect(
+      spacing
+          .lerp(const AppSpacing(xs: 8, sm: 16, md: 24, lg: 32, xl: 40), 0.5)
+          .xs,
+      6,
+    );
+    expect(AppDimensions.radiusSmall, 6);
+    expect(AppDimensions.radiusMedium, 8);
+    expect(AppDimensions.radiusLarge, 12);
+    expect(AppDimensions.componentRadius, 8);
+    expect(AppDimensions.statusPillRadius, 999);
+    expect(AppDimensions.minimumTapTarget, 48);
+  });
+
+  test('configures exact typography and Material 3 semantic colors', () {
+    final theme = AppTheme.light;
+    expect(theme.useMaterial3, isTrue);
+    expect(theme.brightness, Brightness.light);
+    expect(theme.scaffoldBackgroundColor, AppColors.background);
+    expect(theme.colorScheme.primary, AppColors.primary);
+    expect(theme.colorScheme.surface, AppColors.surface);
+    expect(theme.colorScheme.surfaceContainer, AppColors.surfaceMuted);
+    expect(theme.colorScheme.onSurface, AppColors.textPrimary);
+    expect(theme.colorScheme.onSurfaceVariant, AppColors.textSecondary);
+    expect(theme.colorScheme.error, AppColors.danger);
+    expect(theme.colorScheme.errorContainer, AppColors.dangerSurface);
+    expect(theme.colorScheme.outline, AppColors.border);
+    expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
+    expect(theme.extension<AppSpacing>(), AppSpacing.standard);
+    const text = AppTypography.textTheme;
+    expect(text.displayLarge?.fontSize, 28);
+    expect(text.displayLarge?.fontWeight, FontWeight.w700);
+    expect(text.titleLarge?.fontSize, 20);
+    expect(text.titleLarge?.fontWeight, FontWeight.w700);
+    expect(text.titleMedium?.fontSize, 16);
+    expect(text.titleMedium?.fontWeight, FontWeight.w700);
+    expect(text.bodyMedium?.fontSize, 14);
+    expect(text.bodyMedium?.fontWeight, FontWeight.w400);
+    expect(text.labelLarge?.fontSize, 12);
+    expect(text.labelLarge?.fontWeight, FontWeight.w600);
+  });
+
+  test('configures component radii, minimum sizes, and pressed color', () {
+    final theme = AppTheme.light;
+    final filledStyle = theme.filledButtonTheme.style!;
+    expect(
+      filledStyle.minimumSize?.resolve(<WidgetState>{}),
+      const Size(48, 48),
+    );
+    expect(
+      filledStyle.backgroundColor?.resolve(<WidgetState>{WidgetState.pressed}),
+      AppColors.primaryPressed,
+    );
+    final buttonShape =
+        filledStyle.shape!.resolve(<WidgetState>{})! as RoundedRectangleBorder;
+    expect(buttonShape.borderRadius, BorderRadius.circular(8));
+    final inputBorder =
+        theme.inputDecorationTheme.border! as OutlineInputBorder;
+    expect(inputBorder.borderRadius, BorderRadius.circular(8));
+    final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
+    expect(cardShape.borderRadius, BorderRadius.circular(8));
+  });
+}
diff --git a/tindatrack/test/core/widgets/app_state_views_test.dart b/tindatrack/test/core/widgets/app_state_views_test.dart
new file mode 100755
index 0000000..a6a0756
--- /dev/null
+++ b/tindatrack/test/core/widgets/app_state_views_test.dart
@@ -0,0 +1,192 @@
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:tindatrack/app/theme/app_theme.dart';
+import 'package:tindatrack/core/widgets/app_empty_state.dart';
+import 'package:tindatrack/core/widgets/app_error_view.dart';
+import 'package:tindatrack/core/widgets/app_loading_view.dart';
+
+void main() {
+  testWidgets('loading view exposes title, message, progress, and semantics', (
+    tester,
+  ) async {
+    final semantics = tester.ensureSemantics();
+    await _pumpState(
+      tester,
+      const AppLoadingView(
+        title: 'TindaTrack',
+        message: 'Offline inventory tracker',
+        semanticsLabel: 'Loading inventory',
+      ),
+    );
+    expect(find.text('TindaTrack'), findsOneWidget);
+    expect(find.text('Offline inventory tracker'), findsOneWidget);
+    expect(find.byType(CircularProgressIndicator), findsOneWidget);
+    expect(find.bySemanticsLabel('Loading inventory'), findsOneWidget);
+    semantics.dispose();
+  });
+
+  testWidgets('empty state supports no action or a paired action', (
+    tester,
+  ) async {
+    await _pumpState(tester, const AppEmptyState(title: 'No items yet'));
+    expect(find.text('No items yet'), findsOneWidget);
+    expect(find.byType(FilledButton), findsNothing);
+    var calls = 0;
+    await _pumpState(
+      tester,
+      AppEmptyState(
+        title: 'No products yet',
+        message: 'Add your first product when you are ready.',
+        actionLabel: 'Add product',
+        onAction: () => calls++,
+      ),
+    );
+    await tester.tap(find.text('Add product'));
+    expect(calls, 1);
+    expect(
+      tester.getSize(find.byType(FilledButton)).height,
+      greaterThanOrEqualTo(48),
+    );
+  });
+
+  testWidgets(
+    'error state has visible non-color cues and a disableable action',
+    (tester) async {
+      await _pumpState(
+        tester,
+        const AppErrorView(message: 'Please try again.'),
+      );
+      expect(find.byType(FilledButton), findsNothing);
+
+      var calls = 0;
+      await _pumpState(
+        tester,
+        AppErrorView(
+          message: 'Please try again.',
+          actionLabel: 'Retry',
+          onAction: () => calls++,
+          isActionEnabled: false,
+        ),
+      );
+      expect(find.byIcon(Icons.error_outline), findsOneWidget);
+      expect(find.text('Something went wrong'), findsOneWidget);
+      expect(find.text('Please try again.'), findsOneWidget);
+      final disabled = tester.widget<FilledButton>(
+        find.widgetWithText(FilledButton, 'Retry'),
+      );
+      expect(disabled.onPressed, isNull);
+      await _pumpState(
+        tester,
+        AppErrorView(
+          message: 'Please try again.',
+          actionLabel: 'Retry',
+          onAction: () => calls++,
+        ),
+      );
+      await tester.tap(find.text('Retry'));
+      expect(calls, 1);
+      expect(
+        tester.getSize(find.byType(FilledButton)).height,
+        greaterThanOrEqualTo(48),
+      );
+    },
+  );
+
+  test('optional action label and callback are an invariant pair', () {
+    expect(
+      () => AppEmptyState(title: 'Empty', actionLabel: 'Act'),
+      throwsAssertionError,
+    );
+    expect(
+      () => AppEmptyState(title: 'Empty', onAction: () {}),
+      throwsAssertionError,
+    );
+    expect(
+      () => AppErrorView(message: 'Error', actionLabel: 'Retry'),
+      throwsAssertionError,
+    );
+    expect(
+      () => AppErrorView(message: 'Error', onAction: () {}),
+      throwsAssertionError,
+    );
+  });
+
+  testWidgets('state views pass contrast and Android tap-target guidelines', (
+    tester,
+  ) async {
+    final semantics = tester.ensureSemantics();
+    await _pumpState(
+      tester,
+      const AppLoadingView(title: 'Loading', message: 'Please wait.'),
+    );
+    await expectLater(tester, meetsGuideline(textContrastGuideline));
+
+    await _pumpState(
+      tester,
+      AppEmptyState(
+        title: 'No items yet',
+        message: 'Add one when you are ready.',
+        actionLabel: 'Add item',
+        onAction: () {},
+      ),
+    );
+    await expectLater(tester, meetsGuideline(textContrastGuideline));
+    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
+
+    await _pumpState(
+      tester,
+      AppErrorView(
+        message: 'Your saved data is unavailable.',
+        actionLabel: 'Retry',
+        onAction: () {},
+      ),
+    );
+    await expectLater(tester, meetsGuideline(textContrastGuideline));
+    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
+    semantics.dispose();
+  });
+
+  for (final state in <Widget>[
+    const AppLoadingView(title: 'Loading', message: 'Please wait.'),
+    AppEmptyState(
+      title: 'Nothing here yet',
+      message: 'You can add an item when you are ready.',
+      actionLabel: 'Add item',
+      onAction: () {},
+    ),
+    AppErrorView(
+      message: 'We could not load your saved information. Please try again.',
+      actionLabel: 'Retry',
+      onAction: () {},
+    ),
+  ]) {
+    testWidgets(
+      '${state.runtimeType} does not overflow at 360x640 and 2x text',
+      (tester) async {
+        tester.view
+          ..physicalSize = const Size(360, 640)
+          ..devicePixelRatio = 1;
+        addTearDown(tester.view.resetPhysicalSize);
+        addTearDown(tester.view.resetDevicePixelRatio);
+        await _pumpState(tester, state, textScaler: const TextScaler.linear(2));
+        expect(tester.takeException(), isNull);
+      },
+    );
+  }
+}
+
+Future<void> _pumpState(
+  WidgetTester tester,
+  Widget state, {
+  TextScaler textScaler = TextScaler.noScaling,
+}) {
+  return tester.pumpWidget(
+    MaterialApp(
+      theme: AppTheme.light,
+      home: MediaQuery(
+        data: MediaQueryData(textScaler: textScaler),
+        child: Scaffold(body: state),
+      ),
+    ),
+  );
+}
~~~
