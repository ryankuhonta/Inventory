import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Local SQLite database entry point.
///
/// Schema version 1 intentionally contains no feature tables. Product and
/// stock schemas are introduced by their owning stories.
@DriftDatabase()
class AppDatabase extends _$AppDatabase {
  /// Creates the production database, or uses [executor] for isolated tests.
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'tindatrack'));

  @override
  int get schemaVersion => 1;

  /// Opens the underlying SQLite connection and verifies it can answer queries.
  Future<void> ensureReady() async {
    await customSelect('SELECT 1').getSingle();
  }
}
