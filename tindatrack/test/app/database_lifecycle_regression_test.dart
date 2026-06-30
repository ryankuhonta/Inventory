import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/app/providers.dart';
import 'package:tindatrack/core/database/app_database.dart';

void main() {
  test('concurrent close callers share one in-flight attempt', () async {
    final closeCompleter = Completer<void>();
    final database = _ControlledCloseDatabase([closeCompleter.future]);
    addTearDown(database.disposeExecutor);

    final first = closeManagedDatabase(database);
    final second = closeManagedDatabase(database);

    expect(database.closeCalls, 1);
    expect(identical(first, second), isTrue);

    closeCompleter.complete();
    await Future.wait([first, second]);
  });

  test('rejected Exception close is evicted so a later call retries', () async {
    final firstClose = Completer<void>();
    final database = _ControlledCloseDatabase([
      firstClose.future,
      Future<void>.value(),
    ]);
    addTearDown(database.disposeExecutor);

    final failedAttempt = closeManagedDatabase(database);
    firstClose.completeError(Exception('first close failed'));
    await expectLater(failedAttempt, throwsA(isA<Exception>()));
    await closeManagedDatabase(database);

    expect(database.closeCalls, 2);
  });

  test(
    'rejected Dart Error close is evicted so a later call retries',
    () async {
      final firstClose = Completer<void>();
      final database = _ControlledCloseDatabase([
        firstClose.future,
        Future<void>.value(),
      ]);
      addTearDown(database.disposeExecutor);

      final failedAttempt = closeManagedDatabase(database);
      firstClose.completeError(StateError('first close failed'));
      await expectLater(failedAttempt, throwsA(isA<StateError>()));
      await closeManagedDatabase(database);

      expect(database.closeCalls, 2);
    },
  );

  test(
    'synchronous close failure is evicted so a later call retries',
    () async {
      final database = _SynchronousFailingCloseDatabase();
      addTearDown(database.disposeExecutor);

      await expectLater(
        closeManagedDatabase(database),
        throwsA(isA<StateError>()),
      );
      await closeManagedDatabase(database);

      expect(database.closeCalls, 2);
    },
  );

  test('production timeout never starts an overlapping close', () async {
    final hangingClose = Completer<void>();
    final database = _ControlledCloseDatabase([hangingClose.future]);
    addTearDown(database.disposeExecutor);

    await expectLater(
      closeManagedDatabase(database, timeout: Duration.zero),
      throwsA(isA<TimeoutException>()),
    );
    await expectLater(
      closeManagedDatabase(database, timeout: Duration.zero),
      throwsA(isA<TimeoutException>()),
    );

    expect(database.closeCalls, 1);

    hangingClose.complete();
    await closeManagedDatabase(database);
    expect(database.closeCalls, 1);
  });

  test('provider disposal contains synchronous close failures', () async {
    final database = _SynchronousFailingCloseDatabase();
    addTearDown(database.disposeExecutor);
    final uncaught = <Object>[];

    await runZonedGuarded(
      () async {
        ProviderContainer.test(
            overrides: [
              databaseProvider.overrideWith(
                (ref) => createManagedDatabase(ref, () => database),
              ),
            ],
          )
          ..read(databaseProvider)
          ..dispose();
        await Future<void>.value();
      },
      (error, _) => uncaught.add(error),
    );

    expect(database.closeCalls, 1);
    expect(uncaught, isEmpty);
  });
  test('provider disposal contains asynchronous close failures', () async {
    final database = _AsyncFailingCloseDatabase();
    addTearDown(database.disposeExecutor);
    final uncaught = <Object>[];

    await runZonedGuarded(
      () async {
        ProviderContainer.test(
            overrides: [
              databaseProvider.overrideWith(
                (ref) => createManagedDatabase(ref, () => database),
              ),
            ],
          )
          ..read(databaseProvider)
          ..dispose();
        await Future<void>.value();
      },
      (error, _) => uncaught.add(error),
    );

    expect(database.closeCalls, 1);
    expect(uncaught, isEmpty);
  });
}

final class _ControlledCloseDatabase extends AppDatabase {
  _ControlledCloseDatabase(this._outcomes) : super(NativeDatabase.memory());

  final List<Future<void>> _outcomes;
  int closeCalls = 0;

  @override
  Future<void> close() {
    final outcome = _outcomes[closeCalls];
    closeCalls++;
    return outcome;
  }

  Future<void> disposeExecutor() => super.close();
}

final class _SynchronousFailingCloseDatabase extends AppDatabase {
  _SynchronousFailingCloseDatabase() : super(NativeDatabase.memory());

  int closeCalls = 0;

  @override
  Future<void> close() {
    closeCalls++;
    if (closeCalls == 1) {
      throw StateError('synchronous close failure');
    }
    return Future<void>.value();
  }

  Future<void> disposeExecutor() => super.close();
}

final class _AsyncFailingCloseDatabase extends AppDatabase {
  _AsyncFailingCloseDatabase() : super(NativeDatabase.memory());

  int closeCalls = 0;

  @override
  Future<void> close() {
    closeCalls++;
    return Future<void>.sync(
      () => throw Exception('dispose close failed'),
    );
  }

  Future<void> disposeExecutor() => super.close();
}
