import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tindatrack/core/database/app_database.dart';
import 'package:tindatrack/core/id/id_generator.dart';
import 'package:tindatrack/core/id/ulid_generator.dart';
import 'package:tindatrack/core/time/clock.dart';

/// Closes a database for lifecycle coordination.
typedef DatabaseCloser = Future<void> Function(AppDatabase database);

/// Applies a bounded wait to a database close operation.
typedef DatabaseCloseWaiter =
    Future<void> Function(Future<void> close, Duration timeout);

const _databaseCloseTimeout = Duration(seconds: 5);

/// Provides the local database lazily and closes it with its Riverpod scope.
final databaseProvider = Provider<AppDatabase>(
  (ref) => createManagedDatabase(ref, AppDatabase.new),
);

/// Provides the bounded database close operation used by launch Retry.
final databaseCloserProvider = Provider<DatabaseCloser>(
  (ref) => closeManagedDatabase,
);

/// Provides the project-wide identifier generator.
final idGeneratorProvider = Provider<IdGenerator>(
  (ref) => const UlidGenerator(),
);

/// Provides the project-wide UTC clock.
final clockProvider = Provider<Clock>(
  (ref) => const SystemClock(),
);

final _databaseClosures = Expando<_DatabaseCloseAttempt>();

final class _DatabaseCloseAttempt {
  _DatabaseCloseAttempt(this.close);

  final Future<void> close;
  Future<void>? wait;
}

/// Creates a database whose lifecycle is owned by [ref].
///
/// Keeping this small composition helper public lets tests inject an in-memory
/// database while exercising the same disposal behavior as production.
AppDatabase createManagedDatabase(
  Ref ref,
  AppDatabase Function() create,
) {
  final closeDatabase = ref.read(databaseCloserProvider);
  final database = create();
  ref.onDispose(() => _closeOnDispose(closeDatabase, database));
  return database;
}

/// Closes [database] once and shares an in-flight attempt with every caller.
///
/// Successful completion stays cached because a database is closed for good.
/// An underlying failure is evicted so a later call can retry. A caller timeout
/// releases only the bounded wait; the still-running close remains shared.
Future<void> closeManagedDatabase(
  AppDatabase database, {
  Duration timeout = _databaseCloseTimeout,
  DatabaseCloseWaiter waitFor = _waitForClose,
}) {
  final existing = _databaseClosures[database];
  if (existing != null) {
    return _waitForCloseAttempt(database, existing, timeout, waitFor);
  }

  late final Future<void> close;
  try {
    close = database.close();
  } on Object catch (error, stackTrace) {
    close = Future<void>.error(error, stackTrace);
  }

  final attempt = _DatabaseCloseAttempt(close);
  _databaseClosures[database] = attempt;
  unawaited(
    close.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {
        if (identical(_databaseClosures[database], attempt)) {
          _databaseClosures[database] = null;
        }
      },
    ),
  );

  return _waitForCloseAttempt(database, attempt, timeout, waitFor);
}

Future<void> _waitForCloseAttempt(
  AppDatabase database,
  _DatabaseCloseAttempt attempt,
  Duration timeout,
  DatabaseCloseWaiter waitFor,
) {
  final existing = attempt.wait;
  if (existing != null) return existing;

  late final Future<void> guarded;
  try {
    guarded = waitFor(attempt.close, timeout);
  } on Object catch (error, stackTrace) {
    guarded = Future<void>.error(error, stackTrace);
  }

  late final Future<void> tracked;
  tracked = guarded.then<void>(
    (_) {},
    onError: (Object error, StackTrace stackTrace) {
      if (identical(attempt.wait, tracked)) {
        attempt.wait = null;
      }
      if (error is! TimeoutException &&
          identical(_databaseClosures[database], attempt)) {
        _databaseClosures[database] = null;
      }
      Error.throwWithStackTrace(error, stackTrace);
    },
  );
  attempt.wait = tracked;
  return tracked;
}

Future<void> _waitForClose(Future<void> close, Duration timeout) {
  return close.timeout(timeout);
}

void _closeOnDispose(DatabaseCloser closeDatabase, AppDatabase database) {
  try {
    final close = closeDatabase(database);
    unawaited(
      close.then<void>(
        (_) {},
        onError: (Object _, StackTrace _) {},
      ),
    );
  } on Object {
    // Disposal cannot await. Synchronous and asynchronous close failures are
    // observed here so Riverpod teardown never emits an unhandled zone error.
  }
}
