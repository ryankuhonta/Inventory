import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindatrack/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('uses initial schema version 1', () {
    expect(database.schemaVersion, 1);
  });

  test('empty scaffold contains no feature-owned tables', () async {
    final rows = await database.customSelect(
      '''
SELECT name FROM sqlite_master
WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
ORDER BY name
''',
    ).get();
    final names = rows.map((row) => row.read<String>('name')).toSet();

    expect(names, isEmpty);
  });

  test('readiness probe opens and queries the database', () async {
    await expectLater(database.ensureReady(), completes);
  });
}
