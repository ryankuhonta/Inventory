import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/app/bootstrap.dart';
import 'package:tindatrack/app/providers.dart';
import 'package:tindatrack/core/database/app_database.dart';
import 'package:tindatrack/core/errors/app_failure.dart';
import 'package:tindatrack/core/errors/result.dart';

void main() {
  test('bootstrap awaits a real database readiness operation', () async {
    final readiness = Completer<void>();
    final database = _TrackingDatabase(readiness.future);
    final container = ProviderContainer.test(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(database.close);

    var completed = false;
    final resultFuture = container.read(bootstrapProvider.future);
    unawaited(resultFuture.then((_) => completed = true));

    expect(database.readinessChecks, 1);
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);

    readiness.complete();
    final result = await resultFuture;

    expect(result, isA<Success<void>>());
    expect(completed, isTrue);
  });

  test('bootstrap maps database exceptions to a persistence failure', () async {
    const rawError = 'SQLITE_CANTOPEN /private/inventory.sqlite';
    final database = _FailingDatabase(rawError);
    final container = ProviderContainer.test(
      overrides: [databaseProvider.overrideWithValue(database)],
    );
    addTearDown(database.close);

    final result = await container.read(bootstrapProvider.future);

    expect(result, isA<FailureResult<void>>());
    final failure = (result as FailureResult<void>).failure;
    expect(failure, isA<PersistenceFailure>());
    expect(failure.debugMessage, contains(rawError));
  });

  test(
    'bootstrap does not hide programming errors as persistence failures',
    () {
      final database = _ErrorDatabase();
      final container = ProviderContainer.test(
        overrides: [databaseProvider.overrideWithValue(database)],
      );
      addTearDown(database.close);

      expect(
        container.read(bootstrapProvider.future),
        throwsA(isA<AssertionError>()),
      );
    },
  );
}

final class _TrackingDatabase extends AppDatabase {
  _TrackingDatabase(this.readiness) : super(NativeDatabase.memory());

  final Future<void> readiness;

  int readinessChecks = 0;

  @override
  Future<void> ensureReady() async {
    readinessChecks++;
    await readiness;
  }
}

final class _FailingDatabase extends AppDatabase {
  _FailingDatabase(this.message) : super(NativeDatabase.memory());

  final String message;

  @override
  Future<void> ensureReady() => Future<void>.error(Exception(message));
}

final class _ErrorDatabase extends AppDatabase {
  _ErrorDatabase() : super(NativeDatabase.memory());

  @override
  Future<void> ensureReady() => Future<void>.error(AssertionError('bug'));
}
