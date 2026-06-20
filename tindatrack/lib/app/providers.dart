import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tindatrack/core/database/app_database.dart';
import 'package:tindatrack/core/id/id_generator.dart';
import 'package:tindatrack/core/id/ulid_generator.dart';
import 'package:tindatrack/core/time/clock.dart';

/// Provides the local database lazily and closes it with its Riverpod scope.
final databaseProvider = Provider<AppDatabase>(
  (ref) => createManagedDatabase(ref, AppDatabase.new),
);

/// Provides the project-wide identifier generator.
final idGeneratorProvider = Provider<IdGenerator>(
  (ref) => const UlidGenerator(),
);

/// Provides the project-wide UTC clock.
final clockProvider = Provider<Clock>(
  (ref) => const SystemClock(),
);

/// Creates a database whose lifecycle is owned by [ref].
///
/// Keeping this small composition helper public lets tests inject an in-memory
/// database while exercising the same disposal behavior as production.
AppDatabase createManagedDatabase(
  Ref ref,
  AppDatabase Function() create,
) {
  final database = create();
  ref.onDispose(() => unawaited(database.close()));
  return database;
}
