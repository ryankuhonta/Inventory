import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/app/app.dart';
import 'package:tindatrack/app/bootstrap.dart';
import 'package:tindatrack/app/providers.dart';
import 'package:tindatrack/core/database/app_database.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';
import 'package:tindatrack/features/dashboard/domain/entities/dashboard_low_stock_preview_item.dart';
import 'package:tindatrack/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:tindatrack/features/dashboard/presentation/providers/dashboard_providers.dart';

void main() {
  testWidgets('Retry recovers when reading databaseProvider throws', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootstrapProvider.overrideWith(
            (ref) async => const FailureResult<void>(PersistenceFailure()),
          ),
          databaseProvider.overrideWith(
            (ref) => throw StateError('synchronous provider read'),
          ),
        ],
        child: const MainApp(),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(_retryButton(tester).onPressed, isNotNull);
  });

  testWidgets('Retry recovers from a Dart Error returned by close', (
    tester,
  ) async {
    final database = _TestDatabase();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootstrapProvider.overrideWith(
            (ref) async => const FailureResult<void>(PersistenceFailure()),
          ),
          databaseProvider.overrideWithValue(database),
          databaseCloserProvider.overrideWithValue(
            (_) => Future<void>.error(StateError('close error')),
          ),
        ],
        child: const MainApp(),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(_retryButton(tester).onPressed, isNotNull);
    await database.close();
  });

  testWidgets('Retry recovers from a controlled close timeout', (tester) async {
    final database = _TestDatabase();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootstrapProvider.overrideWith(
            (ref) async => const FailureResult<void>(PersistenceFailure()),
          ),
          databaseProvider.overrideWithValue(database),
          databaseCloserProvider.overrideWithValue(
            (_) => Future<void>.error(TimeoutException('controlled timeout')),
          ),
        ],
        child: const MainApp(),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(_retryButton(tester).onPressed, isNotNull);
    await database.close();
  });

  testWidgets('successful Retry invalidates state and recovers', (
    tester,
  ) async {
    final databases = <_TestDatabase>[];
    var bootstrapCalls = 0;
    var closeCalls = 0;
    addTearDown(() async {
      for (final database in databases.skip(1)) {
        await database.close();
      }
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith((ref) {
            final database = _TestDatabase();
            databases.add(database);
            return database;
          }),
          databaseCloserProvider.overrideWithValue((database) async {
            closeCalls++;
            await database.close();
          }),
          bootstrapProvider.overrideWith((ref) async {
            bootstrapCalls++;
            ref.watch(databaseProvider);
            if (bootstrapCalls == 1) {
              return const FailureResult<void>(PersistenceFailure());
            }
            return const Success<void>(null);
          }),
          dashboardSummaryProvider.overrideWith((ref) {
            return Stream.value(
              const DashboardSummary(
                totalActiveProducts: 1,
                lowStockProducts: 0,
                stockChangesToday: 0,
              ),
            );
          }),
          dashboardLowStockPreviewProvider.overrideWith(
            (ref) => _emptyLowStockPreviewStream(),
          ),
        ],
        child: const MainApp(),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard-screen')), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(bootstrapCalls, 2);
    expect(databases, hasLength(2));
    expect(closeCalls, 1);
  });
  testWidgets('pending Retry close is safe when the widget is disposed', (
    tester,
  ) async {
    final closeCompleter = Completer<void>();
    final database = _TestDatabase();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootstrapProvider.overrideWith(
            (ref) async => const FailureResult<void>(PersistenceFailure()),
          ),
          databaseProvider.overrideWithValue(database),
          databaseCloserProvider.overrideWithValue(
            (_) => closeCompleter.future,
          ),
        ],
        child: const MainApp(),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Retry'));
    await tester.pumpWidget(const SizedBox.shrink());
    closeCompleter.complete();
    await tester.pump();

    expect(tester.takeException(), isNull);
    await database.close();
  });
}

FilledButton _retryButton(WidgetTester tester) {
  return tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Retry'),
  );
}

final class _TestDatabase extends AppDatabase {
  _TestDatabase() : super(NativeDatabase.memory());
}

Stream<List<DashboardLowStockPreviewItem>> _emptyLowStockPreviewStream() {
  return Stream.value(const <DashboardLowStockPreviewItem>[]);
}
