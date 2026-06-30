import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/database/app_database.dart';

import '../../generated_migrations/schema.dart';

void main() {
  test('fresh schema v2 matches the generated schema snapshot', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.ensureReady();
    await database.validateDatabaseSchema();
  });

  test('real empty schema v1 migrates to equivalent schema v2', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final connection = await verifier.startAt(1);
    final database = AppDatabase(connection);
    addTearDown(database.close);

    await verifier.migrateAndValidate(database, 2);
  });
}
